#!/usr/bin/env python3
"""Move or rename project files WITH every reference to them (docs/game-base-plan.md 13.3, 13.7).

Why a script: workflow agents cannot drive Godot's FileSystem dock, and UIDs only protect
scene and resource references. About 40 res:// string literals in .gd files, project.godot,
.cfg and the tools' own constants are plain strings that a bare `git mv` silently breaks.

What a move does
  1. `git mv SRC DST`, plus the sidecars of a file (SRC.uid, SRC.import) so the uid and the
     import settings travel with it. Falls back to a plain rename for untracked/ignored paths.
  2. Rewrites every `res://` path string that points at SRC (or into the SRC folder) in
     *.gd *.tscn *.tres *.cfg *.md project.godot (plus *.import, *.gdshader, *.json, *.sh,
     *.yml and tests/baselines/*.txt, which also carry res:// strings).
  3. Appends `SRC<TAB>DST` to tools/move_res_log.tsv, so files that arrive later (the owner
     edited a scene during the migration) can be fixed up with --rewrite-only.
  4. Optionally (--import-pass) runs the Godot editor import pass.
Only the text of path strings changes; nothing else in a file is touched. uid:// references are
never rewritten (they do not depend on the path).

Usage (from the project root, or pass --root)
  tools/move_res.py resources/difficulty content/difficulty          move a folder
  tools/move_res.py scripts/ecs/ecs_boot.gd authoring/ecs_boot.gd    move a file (+ .uid, .import)
  tools/move_res.py --dry-run SRC DST       print every change, touch nothing
  tools/move_res.py --rewrite-only SRC DST  the move already happened (by hand or by a rebase):
                                            only rewrite references, and log the move
  tools/move_res.py --rewrite-only FILE...  replay the whole move log onto FILE... (a scene the
                                            owner edited on the old layout, after a rebase)
  tools/move_res.py --rename-action OLD NEW rename an InputMap action: its [input] entry in
                                            project.godot and every quoted "OLD" / &"OLD" literal
  tools/move_res.py --self-test             run the built-in test in a throwaway git repo

SRC and DST may be written `res://x/y` or `x/y`. DST must not exist. Folders are matched on
whole path segments: moving res://resources/difficulty leaves res://resources/difficulty_old
and res://resources/difficulty.tres alone.

Not touched on purpose: docs/archive/ (history keeps its old paths), .godot/, .git/, third-party
addons/, nested .claude/worktrees/, this script and its log. Prose that names paths WITHOUT the
res:// prefix (tables in design docs) is not rewritten; fix those by hand.
"""
from __future__ import annotations

import argparse
import fnmatch
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RES_PREFIX = "res://"
MOVE_LOG_RELATIVE_PATH = "tools/move_res_log.tsv"

# Files whose text can hold res:// path strings. Matched against the root-relative posix path.
REWRITE_GLOBS = [
    "*.gd", "*.tscn", "*.tres", "*.cfg", "*.md", "project.godot",
    "*.import", "*.gdshader", "*.json", "*.sh", "*.yml", "*.yaml",
    "tests/baselines/*.txt",
]
# Never rewritten (root-relative posix patterns; a trailing /** means "everything below").
NEVER_REWRITE_GLOBS = [
    ".git/**", ".godot/**", "addons/**", ".claude/worktrees/**", "docs/archive/**",
    "tools/move_res.py", MOVE_LOG_RELATIVE_PATH,
]
# A path match must end at a path-segment boundary: not followed by a name character, and not
# followed by ".name" (so a folder move leaves "<folder>.tres" alone).
SEGMENT_END = r"(?![A-Za-z0-9_\-])(?!\.[A-Za-z0-9_])"


class MoveError(Exception):
    """A refused or impossible move; message is shown to the user."""


# --------------------------------------------------------------------------- path helpers
def normalise_relative(path_text: str) -> str:
    """`res://a/b/`, `./a/b` and `a/b` all become `a/b` (posix, no trailing slash)."""
    text = path_text.strip()
    if text.startswith(RES_PREFIX):
        text = text[len(RES_PREFIX):]
    text = text.replace("\\", "/")
    while text.startswith("./"):
        text = text[2:]
    return text.rstrip("/")


def to_res_path(relative_path: str) -> str:
    return RES_PREFIX + relative_path


def matches_any_glob(relative_posix: str, patterns: list[str]) -> bool:
    for pattern in patterns:
        if pattern.endswith("/**"):
            folder = pattern[:-3]
            if relative_posix == folder or relative_posix.startswith(folder + "/"):
                return True
        elif fnmatch.fnmatch(relative_posix, pattern):
            return True
        elif "/" not in pattern and fnmatch.fnmatch(os.path.basename(relative_posix), pattern):
            return True
    return False


# --------------------------------------------------------------------------- git helpers
def run_git(root: Path, *arguments: str, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *arguments], cwd=root, capture_output=True, text=True, check=check)


def is_tracked(root: Path, relative_path: str) -> bool:
    return run_git(root, "ls-files", "--error-unmatch", "--", relative_path, check=False).returncode == 0


def in_git_repo(root: Path) -> bool:
    return run_git(root, "rev-parse", "--is-inside-work-tree", check=False).returncode == 0


def candidate_files(root: Path) -> list[str]:
    """Tracked plus untracked-not-ignored files (root-relative, posix), honouring .gitignore."""
    if in_git_repo(root):
        listed = run_git(root, "ls-files", "-z", "--cached", "--others", "--exclude-standard").stdout
        names = [name for name in listed.split("\0") if name]
        return sorted(set(name for name in names if (root / name).is_file()))
    found: list[str] = []
    for current, folder_names, file_names in os.walk(root):
        folder_names[:] = [name for name in folder_names if name not in (".git", ".godot")]
        for file_name in file_names:
            found.append(Path(current, file_name).relative_to(root).as_posix())
    return sorted(found)


def files_to_rewrite(root: Path, only: list[str] | None = None) -> list[str]:
    if only is not None:
        chosen: list[str] = []
        for name in only:
            relative_name = normalise_relative(name)
            if not (root / relative_name).is_file():
                # not root-relative: maybe relative to the current folder, or absolute
                try:
                    relative_name = Path(name).resolve().relative_to(root.resolve()).as_posix()
                except ValueError:
                    raise MoveError(f"'{name}' is not a file inside the project")
            chosen.append(relative_name)
        return sorted(name for name in chosen if (root / name).is_file() and not matches_any_glob(name, NEVER_REWRITE_GLOBS))
    return [
        name for name in candidate_files(root)
        if matches_any_glob(name, REWRITE_GLOBS) and not matches_any_glob(name, NEVER_REWRITE_GLOBS)
    ]


# --------------------------------------------------------------------------- the rewrite
def compile_move_pattern(old_relative: str) -> re.Pattern:
    return re.compile(re.escape(to_res_path(old_relative)) + SEGMENT_END)


def rewrite_text(text: str, moves: list[tuple[str, str]]) -> tuple[str, list[tuple[int, str, str]]]:
    """Apply moves (old_relative, new_relative) in order. Returns new text and (line, old, new) changes."""
    patterns = [(compile_move_pattern(old), to_res_path(new)) for old, new in moves]
    new_lines: list[str] = []
    changes: list[tuple[int, str, str]] = []
    # keepends so the file's own line endings survive byte for byte
    for line_number, line in enumerate(text.splitlines(keepends=True), start=1):
        rewritten = line
        for pattern, replacement in patterns:
            rewritten = pattern.sub(lambda _match, replacement=replacement: replacement, rewritten)
        if rewritten != line:
            changes.append((line_number, line.rstrip("\r\n"), rewritten.rstrip("\r\n")))
        new_lines.append(rewritten)
    return "".join(new_lines), changes


def rewrite_files(root: Path, moves: list[tuple[str, str]], files: list[str], dry_run: bool) -> int:
    """Rewrite references in files. Returns the number of changed lines."""
    total_changed_lines = 0
    changed_files = 0
    for relative_name in files:
        file_path = root / relative_name
        try:
            original = file_path.read_bytes().decode("utf-8")
        except UnicodeDecodeError:
            continue  # binary or exotic encoding: a path string cannot be in it as text we trust
        rewritten, changes = rewrite_text(original, moves)
        if not changes:
            continue
        changed_files += 1
        total_changed_lines += len(changes)
        for line_number, old_line, new_line in changes:
            print(f"  {relative_name}:{line_number}")
            print(f"    - {old_line.strip()}")
            print(f"    + {new_line.strip()}")
        if not dry_run:
            file_path.write_bytes(rewritten.encode("utf-8"))
    print(f"rewrite: {total_changed_lines} line(s) in {changed_files} file(s)" + (" (dry run, nothing written)" if dry_run else ""))
    return total_changed_lines


# --------------------------------------------------------------------------- the move
def sidecar_pairs(root: Path, source_relative: str, destination_relative: str) -> list[tuple[str, str]]:
    """(source sidecar, destination sidecar) for a FILE move; folders carry theirs inside."""
    pairs: list[tuple[str, str]] = []
    for suffix in (".uid", ".import"):
        if (root / (source_relative + suffix)).exists():
            pairs.append((source_relative + suffix, destination_relative + suffix))
    return pairs


def move_path(root: Path, source_relative: str, destination_relative: str, dry_run: bool) -> None:
    source_path = root / source_relative
    destination_path = root / destination_relative
    if dry_run:
        mover = "git mv" if is_tracked(root, source_relative) or source_path.is_dir() else "mv"
        print(f"  {mover} {source_relative} {destination_relative}")
        return
    destination_path.parent.mkdir(parents=True, exist_ok=True)
    # is_tracked also answers for a folder: true when any tracked file lives below it.
    tracked = in_git_repo(root) and is_tracked(root, source_relative)
    if tracked:
        result = run_git(root, "mv", "--", source_relative, destination_relative, check=False)
        if result.returncode != 0:
            raise MoveError(f"git mv {source_relative} {destination_relative} failed: {result.stderr.strip()}")
    else:
        shutil.move(str(source_path), str(destination_path))
    print(f"  moved {source_relative} -> {destination_relative}" + ("" if tracked else " (untracked: plain rename)"))


def validate_move(root: Path, source_relative: str, destination_relative: str, rewrite_only: bool) -> None:
    for name in (source_relative, destination_relative):
        if not name or name.startswith("/") or ".." in Path(name).parts:
            raise MoveError(f"refusing path '{name}' (must be inside the project)")
        if Path(name).parts[0] in (".git", ".godot", "addons"):
            raise MoveError(f"refusing to move '{name}': {Path(name).parts[0]}/ is not moved by this tool")
    if source_relative.endswith((".uid", ".import")):
        raise MoveError(f"move the asset itself, not its sidecar '{source_relative}'; sidecars travel with it")
    if destination_relative == source_relative:
        raise MoveError("source and destination are the same")
    if destination_relative.startswith(source_relative + "/"):
        raise MoveError("cannot move a folder into itself")
    if rewrite_only:
        if not (root / destination_relative).exists():
            raise MoveError(f"--rewrite-only expects the move to be done already, but '{destination_relative}' does not exist")
        return
    if not (root / source_relative).exists():
        raise MoveError(f"source '{source_relative}' does not exist")
    if (root / destination_relative).exists():
        raise MoveError(f"destination '{destination_relative}' already exists")


def read_move_log(root: Path, log_relative: str) -> list[tuple[str, str]]:
    log_path = root / log_relative
    if not log_path.is_file():
        return []
    moves: list[tuple[str, str]] = []
    for line in log_path.read_text(encoding="utf-8").splitlines():
        if line.strip() and not line.startswith("#") and "\t" in line:
            old, new = line.split("\t", 1)
            moves.append((normalise_relative(old), normalise_relative(new)))
    return moves


def append_move_log(root: Path, log_relative: str, source_relative: str, destination_relative: str) -> None:
    log_path = root / log_relative
    new_file = not log_path.exists()
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as log_file:
        if new_file:
            log_file.write("# tools/move_res.py move log: <old res path><TAB><new res path>, oldest first.\n")
            log_file.write("# Replay onto late files with: tools/move_res.py --rewrite-only FILE...\n")
        log_file.write(f"{source_relative}\t{destination_relative}\n")


def run_import_pass(root: Path) -> int:
    """Run `godot --headless --editor --quit` with a private HOME so sidecars and the uid cache refresh."""
    godot = os.environ.get("GODOT_BIN") or next(
        (str(candidate) for candidate in (
            root.parent / "Godot.app/Contents/MacOS/Godot",
            root.parents[3] / "Godot.app/Contents/MacOS/Godot" if len(root.parents) > 3 else Path("/nonexistent"),
        ) if candidate.exists()),
        shutil.which("godot") or "",
    )
    if not godot:
        print("import pass skipped: set GODOT_BIN=/path/to/Godot", file=sys.stderr)
        return 1
    environment = dict(os.environ, HOME=os.environ.get("MOVE_RES_HOME", f"/tmp/upg-move-res-{root.name}"))
    Path(environment["HOME"]).mkdir(parents=True, exist_ok=True)
    print(f"import pass: {godot}")
    result = subprocess.run([godot, "--headless", "--path", str(root), "--editor", "--quit"], env=environment, capture_output=True, text=True)
    problems = [
        line for line in (result.stdout + result.stderr).splitlines()
        if (line.startswith(("ERROR", "SCRIPT ERROR")) or "Parse Error" in line) and not any(noise in line for noise in ("RID", "ObjectDB", "CanvasLayer"))
    ]
    for line in problems[:10]:
        print(f"  {line}", file=sys.stderr)
    print(f"import pass: exit {result.returncode}, {len(problems)} error line(s)")
    return 0 if result.returncode == 0 and not problems else 1


# --------------------------------------------------------------------------- rename-action
def rename_action(root: Path, old_name: str, new_name: str, dry_run: bool) -> int:
    """Rename an InputMap action: the [input] key in project.godot and quoted literals elsewhere."""
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", old_name) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", new_name):
        raise MoveError("action names are identifiers: letters, digits and underscores")
    project_text = (root / "project.godot").read_text(encoding="utf-8")
    if not re.search(rf"(?m)^{re.escape(old_name)}=\{{", project_text):
        raise MoveError(f"project.godot has no [input] action '{old_name}'")
    if re.search(rf"(?m)^{re.escape(new_name)}=\{{", project_text):
        raise MoveError(f"project.godot already has an action '{new_name}'")
    key_pattern = re.compile(rf"(?m)^{re.escape(old_name)}=\{{")
    literal_pattern = re.compile(rf"""(?<=["']){re.escape(old_name)}(?=["'])""")
    total_changed_lines = 0
    changed_files = 0
    for relative_name in files_to_rewrite(root):
        if not (relative_name == "project.godot" or relative_name.endswith((".gd", ".tscn", ".tres", ".cfg"))):
            continue
        file_path = root / relative_name
        original = file_path.read_bytes().decode("utf-8")
        new_lines = []
        file_changes = 0
        for line_number, line in enumerate(original.splitlines(keepends=True), start=1):
            rewritten = literal_pattern.sub(new_name, line)
            if relative_name == "project.godot":
                rewritten = key_pattern.sub(f"{new_name}={{", rewritten)
            if rewritten != line:
                file_changes += 1
                print(f"  {relative_name}:{line_number}\n    - {line.strip()[:140]}\n    + {rewritten.strip()[:140]}")
            new_lines.append(rewritten)
        if file_changes:
            changed_files += 1
            total_changed_lines += file_changes
            if not dry_run:
                file_path.write_bytes("".join(new_lines).encode("utf-8"))
    print(f"rename-action {old_name} -> {new_name}: {total_changed_lines} line(s) in {changed_files} file(s)" + (" (dry run, nothing written)" if dry_run else ""))
    return total_changed_lines


# --------------------------------------------------------------------------- self-test
def self_test() -> int:
    """Build a throwaway git repo, move a folder and a file, and check every promise above."""
    failures: list[str] = []

    def expect(condition: bool, label: str) -> None:
        print(("PASS: " if condition else "FAIL: ") + label)
        if not condition:
            failures.append(label)

    with tempfile.TemporaryDirectory(prefix="move_res_selftest_") as temp_name:
        root = Path(temp_name)
        files = {
            "project.godot": 'config_version=5\nrun/main_scene="res://scenes/main.tscn"\n[input]\nskill_1={\n"deadzone": 0.5\n}\n',
            "scenes/main.tscn": '[gd_scene format=3]\n[ext_resource type="Resource" path="res://resources/difficulty/standard.tres" id="1"]\n[ext_resource type="Script" uid="uid://abc" path="res://scripts/a.gd" id="2"]\n',
            "resources/difficulty/standard.tres": '[gd_resource type="Resource" format=3]\n',
            "resources/difficulty/standard.tres.import": 'source_file="res://resources/difficulty/standard.tres"\n',
            "resources/difficulty.tres": "[gd_resource format=3]\n",
            "resources/difficulty_old/keep.tres": "[gd_resource format=3]\n",
            "scripts/a.gd": 'extends Node\nvar d = load("res://resources/difficulty/standard.tres")\nvar same_stem = "res://resources/difficulty.tres"\nvar near = "res://resources/difficulty_old/keep.tres"\nfunc f(): return Input.is_action_pressed("skill_1")\n',
            "scripts/a.gd.uid": "uid://abc\n",
            "scripts/b.gd": "extends Node\n",
            "docs/archive/old.md": "see res://resources/difficulty/standard.tres\n",
            "notes.md": "folder res://resources/difficulty. and `res://scripts/a.gd`\r\nsecond line\r\n",
        }
        for name, content in files.items():
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content.encode("utf-8"))
        run_git(root, "init", "-q", ".")
        run_git(root, "config", "user.email", "selftest@example.invalid")
        run_git(root, "config", "user.name", "selftest")
        run_git(root, "add", "-A")
        run_git(root, "commit", "-q", "-m", "baseline")

        # folder move
        move_args = ["--root", str(root), "resources/difficulty", "content/difficulty"]
        expect(main(["--dry-run", *move_args]) == 0 and (root / "resources/difficulty").exists(), "dry run changes nothing on disk")
        expect(main(move_args) == 0, "folder move succeeds")
        expect((root / "content/difficulty/standard.tres").exists() and not (root / "resources/difficulty").exists(), "folder moved with its contents")
        expect((root / "content/difficulty/standard.tres.import").exists(), "the .import sidecar travelled inside the folder")
        main_scene = (root / "scenes/main.tscn").read_text(encoding="utf-8")
        expect('path="res://content/difficulty/standard.tres"' in main_scene and "res://resources/difficulty/" not in main_scene, "scene path rewritten")
        expect('uid="uid://abc"' in main_scene, "uid:// references untouched")
        script_text = (root / "scripts/a.gd").read_text(encoding="utf-8")
        expect('load("res://content/difficulty/standard.tres")' in script_text, "gd string literal rewritten")
        expect('"res://resources/difficulty.tres"' in script_text, "a file named like the folder is left alone")
        expect('"res://resources/difficulty_old/keep.tres"' in script_text, "a sibling folder with the same prefix is left alone")
        expect('source_file="res://content/difficulty/standard.tres"' in (root / "content/difficulty/standard.tres.import").read_text(encoding="utf-8"), ".import source_file rewritten")
        expect("res://resources/difficulty/" in (root / "docs/archive/old.md").read_text(encoding="utf-8"), "docs/archive keeps its old paths")
        notes = (root / "notes.md").read_bytes().decode("utf-8")
        expect("res://content/difficulty. and" in notes and "\r\nsecond line\r\n" in notes, "sentence-final dot handled and CRLF preserved")
        expect((root / MOVE_LOG_RELATIVE_PATH).read_text(encoding="utf-8").strip().endswith("resources/difficulty\tcontent/difficulty"), "move recorded in the log")

        # file move with sidecars
        expect(main(["--root", str(root), "scripts/a.gd", "authoring/a.gd"]) == 0, "file move succeeds")
        expect((root / "authoring/a.gd").exists() and (root / "authoring/a.gd.uid").exists() and not (root / "scripts/a.gd.uid").exists(), "the .uid sidecar travelled with the file")
        expect('path="res://authoring/a.gd"' in (root / "scenes/main.tscn").read_text(encoding="utf-8"), "ext_resource path rewritten after file move")
        expect("res://authoring/a.gd`" in (root / "notes.md").read_text(encoding="utf-8"), "markdown mention rewritten")

        # --rewrite-only with SRC DST: the move was done by hand
        (root / "scripts").mkdir(exist_ok=True)
        (root / "scenes/late.tscn").write_text('[gd_scene format=3]\n[ext_resource type="Script" path="res://scripts/b.gd" id="1"]\n', encoding="utf-8")
        run_git(root, "mv", "scripts/b.gd", "authoring/b.gd")
        expect(main(["--root", str(root), "--rewrite-only", "scripts/b.gd", "authoring/b.gd"]) == 0, "--rewrite-only SRC DST succeeds")
        expect('path="res://authoring/b.gd"' in (root / "scenes/late.tscn").read_text(encoding="utf-8"), "--rewrite-only SRC DST rewrote the reference")

        # --rewrite-only FILE: replay the whole log onto a file that still has the old layout
        owner_file = root / "scenes/owner_edit.tscn"
        owner_file.write_text('[gd_scene format=3]\n[ext_resource type="Resource" path="res://resources/difficulty/standard.tres" id="1"]\n[ext_resource type="Script" path="res://scripts/a.gd" id="2"]\n[ext_resource type="Script" path="res://scripts/b.gd" id="3"]\n', encoding="utf-8")
        expect(main(["--root", str(root), "--rewrite-only", "scenes/owner_edit.tscn"]) == 0, "--rewrite-only FILE replays the log")
        owner_text = owner_file.read_text(encoding="utf-8")
        expect("res://content/difficulty/standard.tres" in owner_text and "res://authoring/a.gd" in owner_text and "res://authoring/b.gd" in owner_text, "log replay rewrote all three old paths")

        # refusals
        expect(main(["--root", str(root), "content/difficulty", "authoring/a.gd"]) != 0, "refuses an existing destination")
        expect(main(["--root", str(root), "nope", "elsewhere"]) != 0, "refuses a missing source")
        expect(main(["--root", str(root), "authoring/a.gd.uid", "authoring/x.uid"]) != 0, "refuses to move a sidecar alone")

        # rename-action
        expect(main(["--root", str(root), "--rename-action", "skill_1", "skill_slot_1"]) == 0, "rename-action succeeds")
        expect("skill_slot_1={" in (root / "project.godot").read_text(encoding="utf-8") and "skill_1={" not in (root / "project.godot").read_text(encoding="utf-8"), "project.godot input key renamed")
        expect('is_action_pressed("skill_slot_1")' in (root / "authoring/a.gd").read_text(encoding="utf-8"), "gd action literal renamed")

    print(f"SELF-TEST: {len(failures)} failure(s)")
    return 1 if failures else 0


# --------------------------------------------------------------------------- command line
def find_project_root(explicit_root: str | None) -> Path:
    if explicit_root:
        return Path(explicit_root).resolve()
    here = Path(__file__).resolve().parent.parent
    return here if (here / "project.godot").is_file() else Path.cwd().resolve()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*", help="SRC DST for a move; FILE... for --rewrite-only replay")
    parser.add_argument("--dry-run", action="store_true", help="print every change, write nothing")
    parser.add_argument("--rewrite-only", action="store_true", help="do not move anything; only rewrite references")
    parser.add_argument("--rename-action", nargs=2, metavar=("OLD", "NEW"), help="rename an InputMap action")
    parser.add_argument("--import-pass", action="store_true", help="run the Godot editor import pass afterwards (GODOT_BIN)")
    parser.add_argument("--no-log", action="store_true", help="do not record the move in the log")
    parser.add_argument("--log", default=MOVE_LOG_RELATIVE_PATH, help="move log, relative to the root")
    parser.add_argument("--root", help="project root (default: the folder above tools/)")
    parser.add_argument("--self-test", action="store_true", help="run the built-in test in a throwaway repo")
    arguments = parser.parse_args(argv)

    if arguments.self_test:
        return self_test()
    root = find_project_root(arguments.root)
    if not (root / "project.godot").is_file():
        print(f"error: no project.godot in {root}", file=sys.stderr)
        return 2
    try:
        if arguments.rename_action:
            rename_action(root, arguments.rename_action[0], arguments.rename_action[1], arguments.dry_run)
            return 0
        if arguments.rewrite_only and not _looks_like_move_pair(root, arguments.paths):
            moves = read_move_log(root, arguments.log)
            if not moves:
                raise MoveError(f"--rewrite-only FILE... needs a move log, but {arguments.log} is empty or missing")
            only = arguments.paths or None
            print(f"replaying {len(moves)} logged move(s) onto {len(only) if only else 'all'} file(s)")
            rewrite_files(root, moves, files_to_rewrite(root, only), arguments.dry_run)
            return 0
        if len(arguments.paths) != 2:
            parser.error("a move needs exactly SRC and DST")
        source_relative = normalise_relative(arguments.paths[0])
        destination_relative = normalise_relative(arguments.paths[1])
        validate_move(root, source_relative, destination_relative, arguments.rewrite_only)
        print(f"{'would move' if arguments.dry_run else 'moving'} {source_relative} -> {destination_relative}" + (" (references only)" if arguments.rewrite_only else ""))
        if not arguments.rewrite_only:
            # Decide the sidecars BEFORE the move: afterwards the source is gone.
            sidecars = sidecar_pairs(root, source_relative, destination_relative) if (root / source_relative).is_file() else []
            move_path(root, source_relative, destination_relative, arguments.dry_run)
            for source_sidecar, destination_sidecar in sidecars:
                move_path(root, source_sidecar, destination_sidecar, arguments.dry_run)
        # The universe is read AFTER the move so files inside the moved folder are rewritten at their new location.
        rewrite_files(root, [(source_relative, destination_relative)], files_to_rewrite(root), arguments.dry_run)
        if not arguments.dry_run and not arguments.no_log:
            append_move_log(root, arguments.log, source_relative, destination_relative)
        if arguments.import_pass and not arguments.dry_run:
            return run_import_pass(root)
        return 0
    except MoveError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


def _looks_like_move_pair(root: Path, paths: list[str]) -> bool:
    """--rewrite-only SRC DST: two paths where SRC is gone and DST exists. Anything else is a file list."""
    if len(paths) != 2:
        return False
    source_relative = normalise_relative(paths[0])
    destination_relative = normalise_relative(paths[1])
    return not (root / source_relative).exists() and (root / destination_relative).exists()


if __name__ == "__main__":
    sys.exit(main())
