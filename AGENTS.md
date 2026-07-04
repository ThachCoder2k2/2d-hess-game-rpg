# AI Workflow Rules - The Unbound Pawn

This file is the operating guide for AI assistants working on this Godot project. Read it before planning or editing.

## Project Direction

- Build editor-first, not script-first.
- Scripts should provide reusable behavior. Game content should live in Godot scenes, child nodes, Resources, AnimationPlayers, VFX scenes, SFX players, and Inspector fields.
- Avoid adding more hardcoded room content to `scripts/main.gd` unless it is a temporary migration bridge.
- Preserve the current playable slice after every change.

## Current Priority

The next major phase is **E2. Editor-first encounter system**.

Primary goal:
- Move the first encounter from hardcoded runtime setup into editable Godot room/spawn scenes.

Target files/scenes:
- `scenes/rooms/first_encounter.tscn`
- `scenes/world/room_encounter.tscn`
- `scenes/markers/enemy_spawn_point.tscn`
- `scenes/markers/pickup_spawn_point.tscn`
- `scripts/world/room_encounter.gd`
- `scripts/world/enemy_spawn_point.gd`
- `scripts/world/pickup_spawn_point.gd`

Acceptance gate:
- Enemy type/definition, starting cell, optional weapon, pickup weapon, room message, blockers, and win condition must be editable from Godot Inspector.
- Existing gameplay, HUD, debug view, restart flow, and tests must still pass.

## Planning Files

Use the persistent planning files as project memory:

- `task_plan.md` tracks phases, statuses, decisions, and errors.
- `findings.md` stores technical discoveries and design conclusions.
- `progress.md` logs completed work and verification results.

Rules:
- Read `task_plan.md` before starting any multi-step work.
- Update `progress.md` after meaningful changes.
- Update `findings.md` when discovering a durable design/technical fact.
- Update phase status in `task_plan.md` when a phase starts or completes.
- Log errors in `task_plan.md` instead of silently retrying the same failed approach.

## Editor-First Implementation Rules

- Prefer `.tscn` scenes for entities, rooms, HUD, markers, and reusable effects.
- Prefer typed `.tres` Resources for configurable data: enemy definitions, movement, attacks, decisions, weapons, difficulty, room objectives, and dialogue.
- Prefer exported variables for values designers should tune in Inspector.
- Prefer child-node components when behavior belongs to an entity but should remain visible/editable in the scene tree.
- Keep runtime factories as bridges only when converting old scripted systems.
- Do not introduce a strict ECS framework. Use Godot-native scenes, nodes, Resources, and signals.
- Shared Resource assets should be treated as immutable at runtime; duplicate per-instance mutable weapon or profile data.

## Code Rules

- Keep gameplay logic cell-based through `GridWorld`.
- Actors should use grid registration, movement reservations, and explicit cell occupancy rather than sprite overlap.
- Enemy attacks must telegraph before resolving.
- One room-level attack token should prevent unfair simultaneous enemy strikes.
- Enemy AI should read the hero's current or visibly reserved destination cell, not buffered input.
- Weapon attacks replace the enemy's chess-shaped attack while equipped.
- Existing legacy Pawn/Knight paths must keep working until fully migrated to editor-first components.

## Visual And Feedback Rules

- Combat readability is more important than decoration.
- Telegraphs must clearly show where and when an enemy will attack.
- Hits should have clear feedback: flash, shake, impact color, sound later.
- Pickups should remain easy to notice on the board.
- Debug overlays must remain optional and toggled with `F3`.
- Placeholder visuals may be code-drawn, but new production content should move toward sprites, AnimationPlayers, and effect scenes.

## Testing And Verification

Run relevant tests after every behavior change:

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/run_tests.gd
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/attack_runtime_test.gd
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/component_movement_runtime_test.gd
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/component_equipment_runtime_test.gd
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/component_knight_movement_runtime_test.gd
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/encounter_hud_runtime_test.gd
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 1200
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --editor --path . --quit
git diff --check
```

The macOS certificate warning from Godot headless runs has been harmless so far.

## Git Rules

- Do not revert user changes.
- Keep commits scoped to the task.
- Commit and push completed milestones.
- Leave unrelated untracked/generated files alone unless the task explicitly owns them.

## Next Recommended Work

Start E2 by creating editor-visible room/spawn scenes and migrating the current first encounter into them while keeping `main.gd` as a compatibility host.
