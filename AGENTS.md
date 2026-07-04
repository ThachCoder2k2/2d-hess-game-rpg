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

## Collaboration Model

AI assistants should do the repeatable implementation work and prepare editor-ready structures. The human owner should make taste, feel, layout, and final approval decisions inside Godot Editor.

AI owns:
- Scripts, Resources, scene scaffolds, tests, migration bridges, verification, commits, and technical documentation.
- Creating first-pass `.tscn` files that open correctly in Godot and expose useful Inspector fields.
- Keeping the project playable after every milestone.
- Updating planning files and explaining what changed.

Human owner owns:
- Final play-feel approval: movement speed, attack timing, telegraph readability, damage feel, and room difficulty.
- Final editor layout approval: room shape, enemy placement, pickup placement, blockers, props, and camera framing.
- Final art/audio taste: sprites, palette, animation style, sound choices, music mood, and UI personality.
- Story tone approval: child voice, fourth-wall moments, dialogue wording, and ending emotion.

Ask the human owner before:
- Replacing the art direction.
- Changing core controls.
- Changing the intended 2-hour scope.
- Removing an existing mechanic.
- Making a destructive migration that cannot be easily compared against the current playable slice.

Do not ask before:
- Adding tests.
- Creating editor-friendly wrappers around existing runtime behavior.
- Moving hardcoded values into exported fields or Resources while preserving defaults.
- Fixing crashes, parser errors, import errors, or regressions.
- Updating planning and workflow docs.

## Human Editor Work Checklist

Some work should intentionally happen inside Godot Editor. When a phase reaches one of these points, the AI should stop and hand the project to the human owner for review or tuning.

Room and encounter review:
- Open the room `.tscn`.
- Move enemy spawn points until the first 10 seconds feel readable.
- Move weapon pickups so they create interesting risk, not random clutter.
- Check blockers and paths for unfair traps.
- Play the room at least three times: cautious, aggressive, and intentionally sloppy.

Player feel review:
- Tune exported step duration, repeat delay, attack recovery, skill cooldown, and invulnerability.
- Confirm `Shift + direction`, `Space`, and `Q` still feel natural.
- Decide whether the pawn should feel heavier, sharper, or more frantic.

Enemy feel review:
- Watch each enemy alone, then in a group.
- Confirm attack tells are visible before damage.
- Confirm the Knight feels like a real threat without feeling unfair.
- Approve each new enemy type before it is used in many rooms.

Art/audio review:
- Replace placeholder sprites/sounds only when the gameplay object is stable.
- Check readability at 640x360 before judging beauty.
- Prefer strong silhouettes and readable colors over decorative detail.
- Approve each art batch in-engine, not only from asset previews.

Narrative review:
- Read dialogue in context while moving through the room.
- Keep child-imagination lines short enough to read during play.
- Approve fourth-wall moments before expanding them into later rooms.

Release review:
- Play exported builds, not only editor runs.
- Check keyboard/controller settings.
- Check audio volume on headphones and speakers.
- Watch for save/checkpoint bugs across app restarts.

When asking for editor work, give the human owner:
- The scene path to open.
- The exact properties or nodes to tune.
- The desired feel target.
- A short checklist for what to report back.

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

## Phase-Gate Workflow

Every major phase should follow this loop:

1. Re-read `AGENTS.md`, `task_plan.md`, and recent `progress.md`.
2. Define the smallest playable milestone for the phase.
3. Build editor-visible scenes/resources first, with scripts only where behavior is needed.
4. Preserve compatibility with the current playable slice.
5. Add or update automated tests for behavior and scene wiring.
6. Run Godot headless tests, editor import, runtime launch, and `git diff --check`.
7. Commit and push the technical milestone.
8. Hand off any editor tuning checklist to the human owner.
9. Record human feedback in `findings.md` or `progress.md`.
10. Iterate until the phase acceptance gate is met.

Do not start a broad new phase while the current phase has a broken playable slice.

## Editor-First Implementation Rules

- Prefer `.tscn` scenes for entities, rooms, HUD, markers, and reusable effects.
- Prefer typed `.tres` Resources for configurable data: enemy definitions, movement, attacks, decisions, weapons, difficulty, room objectives, and dialogue.
- Prefer exported variables for values designers should tune in Inspector.
- Prefer child-node components when behavior belongs to an entity but should remain visible/editable in the scene tree.
- Keep runtime factories as bridges only when converting old scripted systems.
- Do not introduce a strict ECS framework. Use Godot-native scenes, nodes, Resources, and signals.
- Shared Resource assets should be treated as immutable at runtime; duplicate per-instance mutable weapon or profile data.

## Full Game Completion Workflow

Use these gates to complete the whole game. Each gate must end with a playable build or scene set that can be reviewed in editor.

Gate 1: Editor foundation
- Main game scene opens cleanly.
- Player, enemy base, pickup, HUD, board, and room encounter are real scenes.
- No critical content remains trapped only in `main.gd`.

Gate 2: First playable encounter
- Current first room is authored as `first_encounter.tscn`.
- Enemies, pickups, blockers, objective text, and win condition are editable.
- The human owner approves room feel in Godot Editor.

Gate 3: Tutorial flow
- A small tutorial teaches move, turn, sword, telegraph dodge, thrust, pickup denial, and reset.
- The tutorial uses editor-placed triggers and short text.
- The human owner confirms it teaches without feeling slow.

Gate 4: Enemy family
- Pawn, Knight, Bishop, Rook, Queen, and King have Resources and scenes.
- Each enemy has a readable attack identity and editor-tunable timing.
- Each enemy is tested in a simple room before being mixed with others.

Gate 5: Weapons and skills
- Six to ten weapons/skills exist as Resources or scenes.
- Each has clear attack geometry, timing, cooldown/recovery, and feedback.
- The human owner chooses which ones are kept for the 2-hour game.

Gate 6: World structure
- The short game has 5-7 room groups.
- Rooms connect through doors/exits or a simple world map.
- Checkpoints and restart behavior are reliable.

Gate 7: Bosses
- Knight, Bishop, Rook, Queen, and King boss scenes exist.
- Boss phases are authored through scene nodes, Resources, or AnimationPlayers.
- Each boss tests a mechanic the player has already learned.

Gate 8: Narrative pass
- Child imagination framing is present from start to ending.
- Fourth-wall/player-help moments are placed as authored events.
- Dialogue is short, readable, and approved in context.

Gate 9: Art and audio pass
- Placeholder shapes are replaced where it matters most.
- Sprites, UI, VFX, SFX, and music support readability.
- Every attack, hit, pickup, death, room clear, and low-health state has feedback.

Gate 10: Vertical slice build
- A 10-15 minute demo can be exported.
- It includes tutorial, one normal room, one weapon room, one boss, story framing, and restart/win/lose flow.
- The human owner can send it to another player for feedback.

Gate 11: Full short game content lock
- All rooms, bosses, weapons, skills, and narrative beats are implemented.
- No new core mechanics are added after this gate unless a playtest reveals a blocking issue.
- Bugs and tuning take priority over new ideas.

Gate 12: Release polish
- Save/checkpoint, settings, controller support, audio mix, builds, store assets, trailer capture, and QA are complete.
- Exported builds are tested from a clean folder.
- The project is ready for Itch.io or Steam page preparation.

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

## Handoff Format For Human Editor Work

When editor work is needed, respond with this shape:

```text
Open: <scene path>
Tune: <node/property list>
Goal: <desired gameplay/art/story feel>
Try: <short playtest checklist>
Tell me: <specific feedback needed>
```

Keep the handoff short enough that the human owner can act on it immediately.

## Git Rules

- Do not revert user changes.
- Keep commits scoped to the task.
- Commit and push completed milestones.
- Leave unrelated untracked/generated files alone unless the task explicitly owns them.

## Next Recommended Work

Start E2 by creating editor-visible room/spawn scenes and migrating the current first encounter into them while keeping `main.gd` as a compatibility host.
