---
description: Run the full Godot verification suite (tests + import + diff check)
---

Verify the project is green. Run from the project root. The Godot binary is at
`../Godot.app/Contents/MacOS/Godot`; always use `HOME=/tmp/unbound-pawn-godot`.

Run these and report a concise pass/fail table:

1. Logic suite:
   `HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd`
   — expect `TESTS COMPLETE: 0 failure(s)`.

2. Each runtime test (expect `PASS`):
   `tests/ecs_runtime_test.gd`, `tests/ecs_combat_test.gd`,
   `tests/ecs_enemy_test.gd`, `tests/room_encounter_runtime_test.gd`,
   `tests/encounter_hud_runtime_test.gd`
   — same invocation with `-s tests/<name>.gd`.

3. Editor import clean:
   `HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit`
   — no `ERROR`/`Parse` lines (ignore RID-leak / ObjectDB / CanvasLayer teardown noise).

4. Whitespace: `git diff --check`.

If a new `class_name` was just added and a test fails to parse it, run the editor
import (step 3) first to register the global class, then rerun the tests.

Report failures with the exact error line. Do not fix anything unless asked.
