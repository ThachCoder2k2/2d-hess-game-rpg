---
description: Run the full Godot verification (the tools' self-tests, the strict test runner with its import pass, and the diff check)
---

Verify the project is green. Run from the project root. `/verify` is exactly four
steps; do not re-implement their steps by hand.

1. The tools' own self-tests (seconds, no Godot needed). They prove the gate itself
   still gates: the runner really fails on a hang, a SCRIPT ERROR, a FAIL line, a
   missing verdict or a vanished baseline label, and the move tool still rewrites
   references. Run both; a red self-test means the next step's GREEN cannot be trusted.

   `python3 tools/run_all_tests.py --self-test`
   `python3 tools/move_res.py --self-test`

   Expect `SELF-TEST: 0 failure(s)` from each (the `error:` lines `move_res.py` prints on the
   way are refusals it is testing on purpose).

2. The strict runner (import pass, every suite, baseline labels):

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

   Expect the last lines to be `0 failed` and `GREEN`. The suites include the architecture
   guards of `tests/architecture/` (the layer rule, `content/` holds no `.gd`, sidecars, no old
   paths, zero path-only `ext_resource` lines) and the deterministic room dumps, so a moved
   or edited file that breaks the layout fails here by name.

   Environment: `GODOT` is the Godot binary (default `../Godot.app/Contents/MacOS/Godot`
   next to the repository, also found from a git worktree). `UNBOUND_GODOT_HOME` is
   the isolated `HOME` for Godot (default `/tmp/unbound-pawn-godot`); parallel lanes
   should each set their own. A fresh clone or worktree runs `tools/bootstrap_worktree.sh`
   first (it builds the class registry and the generated art, then imports).

3. Whitespace: `git diff --check`.

4. UIDs: `"$GODOT" --headless --path . -s tools/stamp_uids.gd -- --check` must print
   `STAMP UIDS: CLEAN` (no path-only reference, no stale uid). If it does not, run the stamper
   without `--check` and commit the result alone.

Report a concise pass/fail table: the two self-tests, the import pass, each suite (with its PASS and WARN
counts), the baseline-label line, the diff check and the uid check. A failing suite prints the
exact `FAIL:` or `SCRIPT ERROR` line; quote it. For a quick loop while iterating,
`python3 tools/run_all_tests.py --only <part of a suite path> --skip-import` runs
a subset, but only the full strict run counts as verified.

Do not fix anything unless asked. Never edit `tests/baseline_labels.txt` to turn the
runner green: a vanished label means a check disappeared.
