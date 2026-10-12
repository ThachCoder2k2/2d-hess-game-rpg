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
6. `--self-test` checks points 1 to 5 themselves: it feeds the verdict functions
   canned outcomes (a hang, a SCRIPT ERROR, a FAIL line, no verdict line, a vanished
   label...) and a fake Godot script, so a later edit cannot quietly weaken the gate.
   It needs no Godot and no project; `/verify` runs it first.

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
import tempfile
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


# --------------------------------------------------------------------------- self-test
def self_test() -> int:
    """Pin the properties that make this runner a gate, without starting Godot.

    The judging functions (evaluate_suite, evaluate_import, discover_suites,
    check_baseline, run_godot) are fed canned outcomes, a throwaway tests/ tree and a
    fake Godot shell script. A later edit that weakens one of them, for example by
    letting a SCRIPT ERROR through or accepting a suite with no verdict, turns a check
    here red. /verify runs this before the suites (`--self-test`)."""
    global REPO_ROOT, BASELINE_LABELS_FILE, LABEL_RENAMES_FILE
    failures: list[str] = []

    def expect(condition: bool, label: str) -> None:
        print(("PASS: " if condition else "FAIL: ") + label)
        if not condition:
            failures.append(label)

    def canned(output: str, exit_code: int = 0, timed_out: bool = False) -> RunOutcome:
        return RunOutcome(exit_code, output, 0.1, timed_out, 60)

    def judged(output: str, strict: bool = False, **outcome_fields) -> SuiteResult:
        return evaluate_suite("tests/example_test.gd", canned(output, **outcome_fields), strict)

    clean = "PASS: first check\nPASS: second check\nEXAMPLE TEST: PASS\n"

    # --- evaluate_suite: what makes a suite red ---
    result = judged(clean)
    expect(not result.failed and result.pass_count == 2 and result.pass_labels == {"first check", "second check"}, "a clean suite passes and its PASS labels are collected")
    expect(judged(clean, exit_code=-9, timed_out=True).failed, "a timeout (hang) fails the suite")
    expect(judged(clean, exit_code=1).failed, "a non-zero exit code fails the suite even when it printed a PASS verdict")
    expect(judged(clean + "SCRIPT ERROR: Invalid call. Nonexistent function.\n").failed, "a SCRIPT ERROR after the verdict fails the suite")
    expect(judged("SCRIPT ERROR: Parse Error: Identifier not declared\nPASS: a\nEXAMPLE TEST: PASS\n").failed, "a Parse Error fails the suite")
    expect(judged("PASS: a\nParse Error: something\nEXAMPLE TEST: PASS\n").failed, "a bare Parse Error line fails the suite")
    expect(judged("PASS: a\nFAIL: b\nEXAMPLE TEST: PASS\n").failed, "a FAIL line fails the suite even next to a PASS verdict")
    expect(judged("PASS: a\nEXAMPLE TEST: FAIL (1)\n").failed, "a FAIL verdict fails the suite even with exit code 0")
    expect(not judged("PASS: a\nTESTS COMPLETE: 0 failure(s)\n").failed, "the older run_tests.gd summary line counts as a PASS verdict")
    expect(judged("PASS: a\nTESTS COMPLETE: 3 failure(s)\n").failed, "the older summary line with failures fails the suite")
    expect(judged("PASS: a\nPASS: b\n").failed, "a suite that never prints a verdict line fails")
    expect(judged("EXAMPLE TEST: PASS\n").failed, "a suite that prints no PASS label fails (nothing was checked)")
    expect(judged("").failed, "a suite that prints nothing fails")
    expect(judged("PASS: a\n  PASS: indented\nsee PASS: inline\nEXAMPLE TEST: PASS\n").pass_count == 1, "only a line that starts with 'PASS: ' counts as a PASS label")
    soft = "PASS: a\nWARN: soft check\nEXAMPLE TEST: PASS\n"
    expect(not judged(soft).failed and len(judged(soft).warnings) == 1, "a WARN line is a warning, not a failure, without --strict")
    expect(judged(soft, strict=True).failed, "a WARN line fails the suite under --strict")
    engine_error = "PASS: a\nERROR: Failed to load resource\nEXAMPLE TEST: PASS\n"
    expect(not judged(engine_error).failed and len(judged(engine_error).warnings) == 1, "an engine ERROR line is a warning without --strict")
    expect(judged(engine_error, strict=True).failed, "an engine ERROR line fails the suite under --strict")
    expect(not judged("PASS: a\nERROR: 3 resources still in use at exit\nEXAMPLE TEST: PASS\n", strict=True).failed, "engine teardown noise is ignored even under --strict")

    # --- evaluate_import: gate G2 ---
    expect(not evaluate_import(canned("Godot Engine v4.6.3\n")).failed, "a quiet import pass is green")
    expect(evaluate_import(canned("SCRIPT ERROR: Parse Error: x\n")).failed, "a SCRIPT ERROR in the import pass fails it")
    expect(evaluate_import(canned("ERROR: Failed loading resource\n")).failed, "an engine ERROR in the import pass fails it")
    expect(evaluate_import(canned("", exit_code=-9, timed_out=True)).failed, "a hung import pass fails")
    expect(evaluate_import(canned("", exit_code=2)).failed, "a non-zero exit in the import pass fails")
    expect(not evaluate_import(canned("ERROR: 2 resources still in use at exit\n")).failed, "teardown noise does not fail the import pass")

    # --- run_godot: exit code, merged stderr, colour stripping, and the hang kill ---
    with tempfile.TemporaryDirectory(prefix="run_all_tests_selftest_") as temp_name:
        temp_root = Path(temp_name)
        fast_godot = temp_root / "fast_godot.sh"
        fast_godot.write_text("#!/bin/sh\nprintf '\\033[1mPASS: coloured\\033[0m\\n'\necho 'FAIL: on stderr' >&2\nexit 3\n", encoding="utf-8")
        fast_godot.chmod(0o755)
        fast = run_godot(fast_godot, [], temp_name, 20)
        expect(fast.exit_code == 3 and not fast.timed_out, "run_godot reports the exit code of the process")
        expect("PASS: coloured" in fast.output and "FAIL: on stderr" in fast.output, "run_godot merges stderr into the output and strips colour codes")

        hang_godot = temp_root / "hang_godot.sh"
        child_pid_file = temp_root / "child.pid"
        hang_godot.write_text("#!/bin/sh\nsleep 20 &\necho $! > \"$SELFTEST_CHILD_PID_FILE\"\nwait\n", encoding="utf-8")
        hang_godot.chmod(0o755)
        previous_pid_file = os.environ.get("SELFTEST_CHILD_PID_FILE")
        os.environ["SELFTEST_CHILD_PID_FILE"] = str(child_pid_file)
        try:
            hung = run_godot(hang_godot, [], temp_name, 2)
        finally:
            if previous_pid_file is None:
                del os.environ["SELFTEST_CHILD_PID_FILE"]
            else:
                os.environ["SELFTEST_CHILD_PID_FILE"] = previous_pid_file
        expect(hung.timed_out and hung.seconds < 10, "run_godot gives up on a hung process promptly after the timeout (a child that keeps the pipe open must not stall it)")
        child_gone = False
        if child_pid_file.is_file():
            child_pid = int(child_pid_file.read_text(encoding="utf-8").strip())
            for _attempt in range(30):
                try:
                    os.kill(child_pid, 0)
                except ProcessLookupError:
                    child_gone = True
                    break
                time.sleep(0.1)
        expect(child_gone, "the whole process group is killed on a timeout, so no child process is left behind")
        expect(evaluate_suite("tests/hang_test.gd", hung, True).failed, "a suite killed by the timeout is judged red")

        # --- discover_suites and check_baseline against a throwaway tests/ tree ---
        for relative in (
            "tests/run_tests.gd", "tests/b_test.gd", "tests/a_test.gd", "tests/sub/test_z.gd", "tests/sub/test_y.gd",
            "tests/fixtures/test_fixture.gd", "tests/baselines/test_data.gd", "tests/.hidden/test_hidden.gd",
            "tests/support/helper.gd", "tests/bridge_support.gd", "tests/notes.txt",
        ):
            (temp_root / relative).parent.mkdir(parents=True, exist_ok=True)
            (temp_root / relative).write_text("", encoding="utf-8")
        (temp_root / "tests" / "baseline_labels.txt").write_text(
            "# a comment line is ignored\n"
            "tests/a_test.gd | alpha one\n"
            "tests/a_test.gd | alpha gone\n"
            "tests/old_folder/test_y.gd | gamma moved\n"
            "tests/ghost_test.gd | never run\n"
            "tests/b_test.gd | beta old name\n"
            "tests/b_test.gd | beta other\n"
            "tests/b_test.gd | arrow a -> b\n",
            encoding="utf-8")
        (temp_root / "tests" / "label_renames.txt").write_text(
            "beta old name -> beta new name\n"
            "beta other -> printed nowhere\n"
            "arrow a -> b -> arrow ok\n"
            "no such label -> something\n",
            encoding="utf-8")
        saved_paths = (REPO_ROOT, BASELINE_LABELS_FILE, LABEL_RENAMES_FILE)
        REPO_ROOT = temp_root
        BASELINE_LABELS_FILE = temp_root / "tests" / "baseline_labels.txt"
        LABEL_RENAMES_FILE = temp_root / "tests" / "label_renames.txt"
        try:
            discovered = discover_suites()
            expect(
                discovered == ["tests/run_tests.gd", "tests/a_test.gd", "tests/b_test.gd", "tests/sub/test_y.gd", "tests/sub/test_z.gd"],
                "discovery finds run_tests.gd first, then *_test.gd and test_*.gd, and skips fixtures, baselines, hidden folders and helpers")

            def printed(*labels: str) -> SuiteResult:
                return SuiteResult("example", pass_labels=set(labels))

            results = {
                "tests/run_tests.gd": printed(),
                "tests/a_test.gd": printed("alpha one"),
                "tests/b_test.gd": printed("beta new name", "arrow ok"),
                "tests/sub/test_y.gd": printed("gamma moved"),
                "tests/sub/test_z.gd": printed(),
            }
            report = check_baseline(discovered, results, filtered=False)
            expect(report.total == 7 and report.passing == 4 and report.renamed == 2, "the baseline check counts present labels, moved suites and renamed labels as passing")
            expect(
                sorted(report.missing) == sorted([
                    "tests/a_test.gd | alpha gone",
                    "tests/ghost_test.gd | never run  (suite not found)",
                    "tests/b_test.gd | beta other",
                ]),
                "a vanished label, a vanished suite and a rename to a label nobody prints are all reported missing")
            expect(report.stale_rename_lines == ["no such label -> something"], "a rename line that names no baseline label is reported stale")
            filtered_report = check_baseline(discovered, {"tests/a_test.gd": printed("alpha one")}, filtered=True)
            expect(filtered_report.skipped_unselected == 4 and filtered_report.total == 3 and len(filtered_report.missing) == 2, "with --only, labels of unselected suites are skipped but a vanished suite is still missing")
        finally:
            REPO_ROOT, BASELINE_LABELS_FILE, LABEL_RENAMES_FILE = saved_paths

    print("SELF-TEST: %d failure(s)" % len(failures))
    return 1 if failures else 0


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
    parser.add_argument("--self-test", action="store_true", help="test this runner's own verdict logic with canned outcomes and a fake Godot (no project, no Godot needed), then exit")
    arguments = parser.parse_args()

    if arguments.self_test:
        return self_test()

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
