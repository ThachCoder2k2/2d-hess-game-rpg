---
description: Run the full Godot verification (the strict test runner, which includes the import pass, plus the diff check)
---

Verify the project is green. Run from the project root. `/verify` is exactly two
commands; do not re-implement their steps by hand.

1. The strict runner (import pass, every suite, baseline labels):

   `python3 tools/run_all_tests.py --strict`

   What it does, in order:
   - **Import pass** (`--headless --editor --quit`). Registers new `class_name`s and
     must print no `ERROR`, `SCRIPT ERROR` or `Parse Error`.
   - **Every suite**, each as its own Godot process with a 60 s timeout:
     `tests/run_tests.gd`, `tests/*_test.gd` (the ecs, room, encounter-HUD and
     `zone_travel_runtime_test` suites) and `tests/**/test_*.gd` (new suites are
     found by name, so nothing here needs editing when one is added).
   - **Baseline labels.** Every `PASS:` label in `tests/baseline_labels.txt` must
     still print PASS, or be renamed in `tests/label_renames.txt`.
   - `--strict` also fails on soft warnings (`WARN:` lines, engine `ERROR` lines in
     a suite, stale renames).

   Expect the last lines to be `0 failed` and `GREEN`.

   Environment: `GODOT` is the Godot binary (default `../Godot.app/Contents/MacOS/Godot`
   next to the repository, also found from a git worktree). `UNBOUND_GODOT_HOME` is
   the isolated `HOME` for Godot (default `/tmp/unbound-pawn-godot`); parallel lanes
   should each set their own. A fresh clone or worktree needs its generated art first
   (`tools/bootstrap_worktree.sh`, or the `tools/generate_*.gd` scripts).

2. Whitespace: `git diff --check`.

Report a concise pass/fail table: the import pass, each suite (with its PASS and WARN
counts), the baseline-label line, and the diff check. A failing suite prints the
exact `FAIL:` or `SCRIPT ERROR` line; quote it. For a quick loop while iterating,
`python3 tools/run_all_tests.py --only <part of a suite path> --skip-import` runs
a subset, but only the full strict run counts as verified.

Do not fix anything unless asked. Never edit `tests/baseline_labels.txt` to turn the
runner green: a vanished label means a check disappeared.
