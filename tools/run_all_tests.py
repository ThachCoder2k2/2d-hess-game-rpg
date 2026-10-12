#!/usr/bin/env python3
"""Run every test suite of The Unbound Pawn and gate on the result.

This is the single verification entry point (`/verify`, gate G1 of
docs/game-base-plan.md section 16.2). It cannot hang and it cannot pass
vacuously:

1. It runs the editor import pass first (`--headless --editor --quit`), so a new
   `class_name` is registered before any suite needs it, and fails on any
   SCRIPT ERROR, Parse Error or ERROR line it prints.
2. It discovers suites by convention, so a new lane adds a test without editing
   this file:
       tests/run_tests.gd
       tests/*_test.gd
       tests/**/test_*.gd
   Anything under tests/fixtures/ or tests/baselines/ is data, never a suite.
3. It runs each suite as its own Godot subprocess with a hard timeout (60 s) and
   fails the suite on a timeout, a non-zero exit, a SCRIPT ERROR or Parse Error
   anywhere in its output, a FAIL line, a missing verdict line, or no PASS line.
4. It checks the baseline-label manifest: every `PASS:` label recorded in
   tests/baseline_labels.txt must still print PASS in its suite, or be listed in
   tests/label_renames.txt as `old label -> new label` with the new label
   printing PASS. This replaces the unprovable claim "the tests are unchanged".
5. `--strict` promotes soft warnings to failures: `WARN:` lines from
   UnboundTest.soft_expect, engine ERROR lines inside a suite, and stale
   entries in label_renames.txt.

Environment:
    GODOT                  path of the Godot binary. Default: ../Godot.app/Contents/MacOS/Godot
                           next to the repository (also found from a git worktree,
                           by looking next to the main checkout), then `godot` on PATH.
    UNBOUND_GODOT_HOME     HOME for the Godot processes (user data, logs).
                           Default: /tmp/unbound-pawn-godot. Parallel lanes should
                           each use their own directory.

Exit status: 0 everything green, 1 at least one failure, 2 the runner itself
could not start (no Godot binary, bad arguments).
"""

from __future__ import annotations

import argparse
import os
import re
import signal
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path, PurePosixPath

REPO_ROOT = Path(__file__).resolve().parent.parent

GODOT_ENV_VAR = "GODOT"
HOME_ENV_VAR = "UNBOUND_GODOT_HOME"
DEFAULT_GODOT_HOME = "/tmp/unbound-pawn-godot"
GODOT_RELATIVE_TO_REPO = Path("..") / "Godot.app" / "Contents" / "MacOS" / "Godot"

SUITE_TIMEOUT_SECONDS = 60
IMPORT_TIMEOUT_SECONDS = 300

BASELINE_LABELS_FILE = REPO_ROOT / "tests" / "baseline_labels.txt"
LABEL_RENAMES_FILE = REPO_ROOT / "tests" / "label_renames.txt"

# Folders under tests/ that hold data for suites, never suites themselves.
NON_SUITE_DIRECTORIES = {"fixtures", "baselines"}

# Output that always means the suite is broken, whatever its exit code says.
SCRIPT_FAILURE_MARKERS = ("SCRIPT ERROR", "Parse Error")

# Engine teardown noise that every headless run prints. Not a failure.
ENGINE_NOISE = re.compile(r"still in use at exit|leaked at exit|instances leaked")

ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
PASS_LABEL = re.compile(r"^PASS: (.*)$")
FAIL_LINE = re.compile(r"^FAIL: (.*)$")
WARN_LINE = re.compile(r"^WARN: (.*)$")
ENGINE_ERROR_LINE = re.compile(r"^ERROR: (.*)$")
# "<HEADING>: PASS", "<HEADING>: FAIL (n)" and the older run_tests.gd summary.
PASS_VERDICT = re.compile(r"^(?:TESTS COMPLETE: 0 failure\(s\)|(?!PASS:|FAIL:|WARN:)\S[^:]*: PASS)$")
FAIL_VERDICT = re.compile(r"^(?:TESTS COMPLETE: [1-9]\d* failure\(s\)|(?!PASS:|FAIL:|WARN:)\S[^:]*: FAIL \(\d+\))$")

RENAME_SEPARATOR = " -> "
BASELINE_SEPARATOR = " | "
MAX_DETAIL_LINES = 8


@dataclass
class RunOutcome:
    """What one Godot subprocess did."""

    exit_code: int
    output: str
    seconds: float
    timed_out: bool
    timeout_seconds: int


@dataclass
class SuiteResult:
    """The verdict on one suite, or on the import pass."""

    name: str
    failures: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    detail_lines: list[str] = field(default_factory=list)
    pass_labels: set[str] = field(default_factory=set)
    pass_count: int = 0
    seconds: float = 0.0
    output: str = ""

    @property
    def failed(self) -> bool:
        return bool(self.failures)


def find_godot() -> Path | None:
    """GODOT, else ../Godot.app next to the repo or next to the main checkout, else PATH."""
    configured = os.environ.get(GODOT_ENV_VAR)
    if configured:
        return Path(configured)
    candidates = [(REPO_ROOT / GODOT_RELATIVE_TO_REPO).resolve()]
    try:
        common_dir = subprocess.run(
            ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
            cwd=REPO_ROOT, capture_output=True, text=True, timeout=15, check=True,
        ).stdout.strip()
        if common_dir:
            main_checkout = Path(common_dir).parent
            candidates.append((main_checkout / GODOT_RELATIVE_TO_REPO).resolve())
    except (OSError, subprocess.SubprocessError):
        pass
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    on_path = shutil.which("godot")
    return Path(on_path) if on_path else None


def run_godot(godot: Path, arguments: list[str], home: str, timeout_seconds: int) -> RunOutcome:
    """Run Godot in its own process group, merge stderr into stdout, kill on timeout."""
    environment = dict(os.environ, HOME=home)
    started = time.monotonic()
    process = subprocess.Popen(
        [str(godot), *arguments],
        cwd=REPO_ROOT,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    timed_out = False
    try:
        raw_output, _ = process.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        raw_output, _ = process.communicate()
    output = ANSI_ESCAPE.sub("", raw_output.decode("utf-8", errors="replace"))
    return RunOutcome(process.returncode, output, time.monotonic() - started, timed_out, timeout_seconds)


def describe_exit(outcome: RunOutcome) -> str:
    if outcome.exit_code < 0:
        return "killed by signal %d" % -outcome.exit_code
    return "exit code %d" % outcome.exit_code


def clean_lines(output: str) -> list[str]:
    return [line.rstrip("\r\n ").rstrip() for line in output.splitlines()]


def first_line_containing(lines: list[str], markers: tuple[str, ...]) -> str | None:
    for line in lines:
        if any(marker in line for marker in markers):
            return line.strip()
    return None


def engine_error_lines(lines: list[str]) -> list[str]:
    return [line for line in lines if ENGINE_ERROR_LINE.match(line) and not ENGINE_NOISE.search(line)]


def evaluate_import(outcome: RunOutcome) -> SuiteResult:
    """The import pass must print no SCRIPT ERROR, Parse Error or ERROR (gate G2)."""
    result = SuiteResult("editor import pass", seconds=outcome.seconds, output=outcome.output)
    lines = clean_lines(outcome.output)
    if outcome.timed_out:
        result.failures.append("timed out after %d s" % outcome.timeout_seconds)
    elif outcome.exit_code != 0:
        result.failures.append(describe_exit(outcome))
    script_failure = first_line_containing(lines, SCRIPT_FAILURE_MARKERS)
    if script_failure:
        result.failures.append("script failure in the import output: %s" % script_failure)
    engine_errors = engine_error_lines(lines)
    if engine_errors:
        result.failures.append("%d ERROR line(s) in the import output, first: %s" % (len(engine_errors), engine_errors[0]))
    if result.failed:
        result.detail_lines = [line for line in lines if "ERROR" in line or "Parse" in line][:MAX_DETAIL_LINES]
        result.detail_lines.append(
            "on a fresh clone or worktree the usual cause is missing generated art: run "
            "tools/bootstrap_worktree.sh (or the tools/generate_*.gd scripts), then retry"
        )
    return result


def evaluate_suite(name: str, outcome: RunOutcome, strict: bool) -> SuiteResult:
    result = SuiteResult(name, seconds=outcome.seconds, output=outcome.output)
    lines = clean_lines(outcome.output)

    fail_lines: list[str] = []
    has_pass_verdict = False
    has_fail_verdict = False
    for line in lines:
        pass_match = PASS_LABEL.match(line)
        if pass_match:
            result.pass_labels.add(pass_match.group(1))
            result.pass_count += 1
            continue
        fail_match = FAIL_LINE.match(line)
        if fail_match:
            fail_lines.append(line)
            continue
        warn_match = WARN_LINE.match(line)
        if warn_match:
            result.warnings.append("WARN: %s" % warn_match.group(1))
            continue
        if PASS_VERDICT.match(line):
            has_pass_verdict = True
        elif FAIL_VERDICT.match(line):
            has_fail_verdict = True

    if outcome.timed_out:
        result.failures.append("timed out after %d s (hung or too slow)" % outcome.timeout_seconds)
    elif outcome.exit_code != 0:
        result.failures.append(describe_exit(outcome))
    script_failure = first_line_containing(lines, SCRIPT_FAILURE_MARKERS)
    if script_failure:
        result.failures.append("script failure in the output: %s" % script_failure)
    if fail_lines:
        result.failures.append("%d FAIL line(s)" % len(fail_lines))
    if has_fail_verdict:
        result.failures.append("the suite's own verdict line says FAIL")
    if not has_pass_verdict and not outcome.timed_out and not has_fail_verdict:
        result.failures.append("no verdict line (the suite never reached finish() or its summary)")
    if result.pass_count == 0:
        result.failures.append("no PASS line was printed, so nothing was checked")

    engine_errors = engine_error_lines(lines)
    if engine_errors:
        result.warnings.append("%d engine ERROR line(s), first: %s" % (len(engine_errors), engine_errors[0]))
    if strict and result.warnings:
        result.failures.append("%d warning(s) under --strict" % len(result.warnings))

    if result.failed:
        interesting = list(fail_lines)
        if script_failure:
            interesting.append(script_failure)
        interesting.extend(result.warnings if strict else [])
        if not interesting:
            interesting = [line for line in lines if line.strip()][-MAX_DETAIL_LINES:]
        result.detail_lines = interesting[:MAX_DETAIL_LINES]
    return result


def discover_suites() -> list[str]:
    """Suite paths relative to the repo, run_tests.gd first, the rest sorted."""
    tests_root = REPO_ROOT / "tests"
    found: set[Path] = set()
    legacy_suite = tests_root / "run_tests.gd"
    if legacy_suite.is_file():
        found.add(legacy_suite)
    found.update(tests_root.glob("*_test.gd"))
    found.update(tests_root.glob("**/test_*.gd"))
    suites = []
    for path in found:
        relative = PurePosixPath(path.relative_to(REPO_ROOT).as_posix())
        parts_below_tests = relative.parts[1:-1]
        if any(part in NON_SUITE_DIRECTORIES or part.startswith(".") for part in parts_below_tests):
            continue
        suites.append(str(relative))
    suites.sort(key=lambda suite: (suite != "tests/run_tests.gd", suite))
    return suites


def read_manifest_lines(path: Path) -> list[str]:
    if not path.is_file():
        return []
    lines = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if line and not line.lstrip().startswith("#"):
            lines.append(line)
    return lines


def load_baseline() -> list[tuple[str, str]]:
    """(suite path, label) pairs from tests/baseline_labels.txt: `suite | label`."""
    entries = []
    for line in read_manifest_lines(BASELINE_LABELS_FILE):
        suite, separator, label = line.partition(BASELINE_SEPARATOR)
        if separator and suite and label:
            entries.append((suite.strip(), label))
    return entries


def load_renames(known_labels: set[str]) -> tuple[dict[str, str], list[str]]:
    """old label -> new label from tests/label_renames.txt, plus unusable lines.

    Labels may themselves contain ' -> ', so the split point is the first one whose
    left side is a baseline label."""
    renames: dict[str, str] = {}
    unusable: list[str] = []
    for line in read_manifest_lines(LABEL_RENAMES_FILE):
        parts = line.split(RENAME_SEPARATOR)
        chosen = None
        for split_at in range(1, len(parts)):
            old_label = RENAME_SEPARATOR.join(parts[:split_at])
            new_label = RENAME_SEPARATOR.join(parts[split_at:])
            if old_label in known_labels and new_label.strip():
                chosen = (old_label, new_label)
                break
        if chosen:
            renames[chosen[0]] = chosen[1]
        else:
            unusable.append(line)
    return renames, unusable


def resolve_suite(recorded_suite: str, discovered: list[str]) -> str | None:
    """The discovered suite that now holds a recorded suite: the same path, else the
    same file name elsewhere under tests/ (a folder move), else none."""
    if recorded_suite in discovered:
        return recorded_suite
    same_name = [suite for suite in discovered if PurePosixPath(suite).name == PurePosixPath(recorded_suite).name]
    return same_name[0] if len(same_name) == 1 else None


@dataclass
class BaselineReport:
    total: int = 0
    passing: int = 0
    renamed: int = 0
    missing: list[str] = field(default_factory=list)
    stale_rename_lines: list[str] = field(default_factory=list)
    skipped_unselected: int = 0


def check_baseline(discovered: list[str], results: dict[str, SuiteResult], filtered: bool) -> BaselineReport:
    report = BaselineReport()
    baseline = load_baseline()
    renames, report.stale_rename_lines = load_renames({label for _, label in baseline})
    for recorded_suite, label in baseline:
        suite = resolve_suite(recorded_suite, discovered)
        if suite is not None and suite not in results:
            if filtered:
                report.skipped_unselected += 1
                continue
        report.total += 1
        if suite is None:
            report.missing.append("%s | %s  (suite not found)" % (recorded_suite, label))
            continue
        printed = results[suite].pass_labels
        if label in printed:
            report.passing += 1
        elif label in renames and renames[label] in printed:
            report.passing += 1
            report.renamed += 1
        else:
            report.missing.append("%s | %s" % (recorded_suite, label))
    return report


def print_header(title: str) -> None:
    print("\n== %s %s" % (title, "=" * max(3, 74 - len(title))))


def format_row(status: str, name: str, passes: str, warns: str, seconds: float) -> str:
    return "  %-5s %-58s %5s %5s %6.1fs" % (status, name, passes, warns, seconds)


def print_failure_details(result: SuiteResult) -> None:
    for reason in result.failures:
        print("        - %s" % reason)
    for line in result.detail_lines:
        print("          %s" % line[:200])


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run the import pass, then every test suite, and gate on the result.",
        epilog="See the module docstring (head of this file) for discovery rules and environment variables.",
    )
    parser.add_argument("--strict", action="store_true", help="promote soft warnings (WARN lines, engine ERROR lines, stale renames) to failures")
    parser.add_argument("--only", action="append", default=[], metavar="TEXT", help="run only suites whose path contains TEXT (repeatable); baseline labels of other suites are not checked")
    parser.add_argument("--skip-import", action="store_true", help="skip the editor import pass (quick local loops only; gates never skip it)")
    parser.add_argument("--list", action="store_true", help="list the discovered suites and exit")
    parser.add_argument("--verbose", "-v", action="store_true", help="print the full output of every suite")
    parser.add_argument("--suite-timeout", type=int, default=SUITE_TIMEOUT_SECONDS, metavar="SECONDS", help="per-suite timeout (default %(default)s)")
    arguments = parser.parse_args()

    discovered = discover_suites()
    if arguments.list:
        print("\n".join(discovered))
        return 0
    selected = [suite for suite in discovered if not arguments.only or any(text in suite for text in arguments.only)]
    if not discovered or not selected:
        print("run_all_tests: no suites found%s" % (" matching %s" % arguments.only if arguments.only else ""), file=sys.stderr)
        return 1

    godot = find_godot()
    if godot is None or not godot.is_file():
        print(
            "run_all_tests: cannot find the Godot binary (looked at %s). Set GODOT=/path/to/Godot." % (godot or "nothing"),
            file=sys.stderr,
        )
        return 2
    home = os.environ.get(HOME_ENV_VAR, DEFAULT_GODOT_HOME)
    os.makedirs(home, exist_ok=True)
    suite_timeout = arguments.suite_timeout

    print("run_all_tests: %s | HOME=%s | %d suite(s)%s" % (godot, home, len(selected), " | strict" if arguments.strict else ""))
    failed_names: list[str] = []
    warning_total = 0

    if not arguments.skip_import:
        print_header("Import pass")
        outcome = run_godot(godot, ["--headless", "--path", str(REPO_ROOT), "--editor", "--quit"], home, IMPORT_TIMEOUT_SECONDS)
        import_result = evaluate_import(outcome)
        print(format_row("FAIL" if import_result.failed else "ok", import_result.name, "", "", import_result.seconds))
        if import_result.failed:
            print_failure_details(import_result)
            failed_names.append(import_result.name)

    print_header("Suites")
    print("  %-5s %-58s %5s %5s %7s" % ("", "suite", "PASS", "WARN", "time"))
    results: dict[str, SuiteResult] = {}
    for suite in selected:
        outcome = run_godot(godot, ["--headless", "--path", str(REPO_ROOT), "-s", suite], home, suite_timeout)
        result = evaluate_suite(suite, outcome, arguments.strict)
        results[suite] = result
        warning_total += len(result.warnings)
        print(format_row("FAIL" if result.failed else "ok", suite, str(result.pass_count), str(len(result.warnings)), result.seconds))
        if result.failed:
            failed_names.append(suite)
            print_failure_details(result)
        elif result.warnings:
            for warning in result.warnings[:MAX_DETAIL_LINES]:
                print("        ~ %s" % warning[:200])
        if arguments.verbose:
            print(result.output)

    print_header("Baseline labels")
    baseline = check_baseline(discovered, results, filtered=bool(arguments.only))
    baseline_failed = False
    if not BASELINE_LABELS_FILE.is_file() or (baseline.total == 0 and not arguments.only):
        print("  FAIL  tests/baseline_labels.txt is missing or empty, so nothing proves the old checks still run")
        baseline_failed = True
    else:
        print(
            "  %d recorded, %d still print PASS (%d through label_renames.txt), %d missing%s"
            % (baseline.total, baseline.passing, baseline.renamed, len(baseline.missing),
               ", %d skipped (suite not selected)" % baseline.skipped_unselected if baseline.skipped_unselected else "")
        )
        if baseline.missing:
            baseline_failed = True
            for entry in baseline.missing[:15]:
                print("        - missing: %s" % entry[:200])
            if len(baseline.missing) > 15:
                print("        ... and %d more" % (len(baseline.missing) - 15))
            print("        a retargeted check must print the same label, or be listed in tests/label_renames.txt as 'old label -> new label'")
    if baseline.stale_rename_lines:
        message = "label_renames.txt has %d line(s) that name no baseline label or no replacement: %s" % (
            len(baseline.stale_rename_lines), "; ".join(line[:80] for line in baseline.stale_rename_lines[:3]))
        warning_total += 1
        if arguments.strict:
            baseline_failed = True
            print("  FAIL  %s" % message)
        else:
            print("  warn  %s" % message)
    if baseline_failed:
        failed_names.append("baseline labels")

    print_header("Result")
    suites_failed = [name for name in failed_names if name in results]
    print(
        "  %d suite(s) run, %d failed, %d warning(s)%s"
        % (len(results), len(suites_failed), warning_total, " (strict)" if arguments.strict else "")
    )
    if failed_names:
        print("  RED: %s" % ", ".join(failed_names))
        return 1
    print("  GREEN")
    return 0


if __name__ == "__main__":
    sys.exit(main())
