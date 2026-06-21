# The Unbound Pawn - Enemy AI Implementation Roadmap

**Status:** Ready to execute
**Date:** 2026-06-21
**Source design:** `docs/design/enemy-behavior-bible.md`

## Objective

Turn the approved enemy behavior design into a reusable Godot 4 system while keeping a playable build after every milestone.

The implementation must preserve these rules:

- Every common enemy moves one cardinal cell at a time.
- Unarmed attack geometry communicates chess identity.
- Equipped weapons replace unarmed attacks.
- Telegraph cells lock before commitment.
- Common enemies coordinate through the encounter director.
- Bosses use authored maneuvers, not unrestricted common-enemy utility.

## Recommended Approach

Refactor incrementally around the working `FreeEnemy` prototype.

Two alternatives were rejected:

- Rewriting every enemy at once creates too much regression risk.
- Building each piece as a separate monolithic script duplicates targeting, equipment, timing, and fairness logic.

The selected approach extracts shared decision data first, preserves Pawn and Knight behavior, and adds one new combat role per milestone.

## Milestone 1 - Intent Foundation

**Goal:** Separate decisions from execution without changing current gameplay.

Create:

- `scripts/ai/enemy_context.gd`
- `scripts/ai/enemy_intent.gd`
- `scripts/ai/enemy_archetype.gd`
- `scripts/ai/attack_pattern.gd`
- `scripts/ai/patterns/pawn_pattern.gd`
- `scripts/ai/patterns/knight_pattern.gd`

Modify:

- `scripts/actors/free_enemy.gd`
- `scripts/actors/black_pawn.gd`
- `scripts/actors/knight_enemy.gd`
- `tests/run_tests.gd`

Implementation:

1. Capture an immutable context at the beginning of each decision.
2. Generate explicit attack, move, pickup, turn, and wait intents.
3. Score intents using deterministic weights.
4. Lock the selected intent before telegraphing.
5. Let `FreeEnemy` execute the intent through `OBSERVE`, `TELEGRAPH`, `COMMIT`, and `RECOVER`.
6. Move Pawn and Knight geometry into pattern resources.

Acceptance:

- The existing mixed encounter remains mechanically unchanged.
- Pawn and Knight attacks rotate correctly at room edges.
- Replaying the same context selects the same intent.
- Weapon attacks still replace chess attacks.
- Existing 36 checks remain green, with new intent tests added.

## Milestone 2 - Coordination and Fairness

**Goal:** Make groups readable and prevent impossible combinations.

Create:

- `scripts/combat/threat_map.gd`
- `scripts/combat/response_validator.gd`
- `scripts/debug/enemy_debug_overlay.gd`

Modify:

- `scripts/combat/encounter_director.gd`
- `scripts/world/prototype_board.gd`
- `scripts/actors/free_enemy.gd`
- `scripts/main.gd`
- `tests/run_tests.gd`

Implementation:

1. Register enemies with the director.
2. Track attack ownership, near/far roles, pickup reservations, and destination reservations.
3. Publish potential, telegraphed, and resolving threat cells.
4. Reject common attack combinations with no cardinal response cell.
5. Enforce minimum commitment spacing and token release at recovery.
6. Add a development overlay for state, intent, score, token owner, and reservations.

Acceptance:

- Two common enemies never commit on the same frame.
- Telegraph cells never retarget after appearing.
- Two enemies cannot reserve the same pickup or destination.
- The validator detects authored no-response states.
- The overlay explains every selected action.

## Milestone 3 - Pawn and Knight Personality Pass

**Goal:** Make the existing enemies feel intentionally different.

Modify:

- Pawn and Knight archetype resources
- Pawn and Knight pattern resources
- `scripts/actors/free_enemy.gd`
- `scripts/world/prototype_board.gd`
- `tests/run_tests.gd`

Implementation:

1. Add three-action memory and repetition penalties.
2. Give Pawn formation, pincer, and weapon-race preferences.
3. Give Knight axis variation, L-threat setup, and vulnerable landing recovery.
4. Add Recruit, Standard, and Elite timing presets.
5. Build the first four encounter recipes from the behavior bible.

Acceptance:

- Pawn reads as a local skirmisher.
- Knight reads as a flanker within two encounters.
- Neither repeats the same viable action more than twice.
- Armed behavior is visibly different before the second weapon attack.
- Each encounter is beatable without unexplained damage.

## Milestone 4 - Bishop Controller

**Goal:** Add the first ranged spatial-control enemy.

Create:

- `scripts/actors/bishop_enemy.gd`
- `scripts/ai/patterns/bishop_pattern.gd`
- Bishop archetype resource and encounter scene

Modify:

- Threat-map ray support
- Board telegraph rendering
- Response validator
- Tests

Implementation:

1. Generate diagonal rays that stop at solid obstacles.
2. Score lane length, route denial, preferred distance, and ally setup.
3. Render rays progressively from near to far.
4. Prevent controller combinations from removing every cardinal exit.
5. Add the Controller Introduction encounter.

Acceptance:

- Obstacles consistently shorten rays.
- Bishop retreats when crowded.
- The player can identify the threatened diagonal before commitment.
- Bishop and Pawn combinations always preserve a response.

## Milestone 5 - Rook Charger

**Goal:** Add terrain interaction and committed lane pressure.

Create:

- `scripts/actors/rook_enemy.gd`
- `scripts/ai/patterns/rook_pattern.gd`
- Rook archetype resource and encounter scene

Modify:

- `GridWorld` block interaction
- Director destination reservations
- Board charge telegraph
- Tests

Implementation:

1. Score row/column alignment and useful destructible targets.
2. Reserve the complete charge path and final cell.
3. Stop safely at newly blocked cells.
4. Add wall collision, block damage, and stun recovery.
5. Add Rook plus Pawn and Rook plus Knight encounter recipes.

Acceptance:

- Charge never turns after commitment.
- Dynamic blockers stop the Rook safely.
- Wall impact always creates a reliable punish window.
- Terrain changes remain deterministic after retry.

## Milestone 6 - Authored Boss Framework

**Goal:** Support Queen and King encounters without forcing boss logic into common AI.

Create:

- `scripts/boss/boss_controller.gd`
- `scripts/boss/boss_maneuver.gd`
- `scripts/boss/queen_controller.gd`
- `scripts/boss/king_controller.gd`
- Queen and King maneuver resources

Implementation:

1. Execute authored maneuver sequences with phase conditions.
2. Reuse common attack patterns and threat validation.
3. Add arena events, toy interactions, and rule-card announcements.
4. Give Queen pattern combinations and ally commands.
5. Give King one active global rule modifier at a time.
6. Author retry-safe phase transitions and defeat sequences.

Acceptance:

- Bosses teach, test, escalate, and perform a final exam.
- Queen combinations pass response validation.
- King rule changes are announced before affecting input.
- Checkpoint retry restores the exact phase and arena state.

## Verification Per Milestone

Run:

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tests/run_tests.gd

HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot \
  --headless --path . --quit-after 1200
```

For behavior milestones, also capture and inspect a real rendered encounter at 1280x720.

Required checks:

- Parser and headless runtime produce no errors.
- Automated behavior assertions pass.
- `git diff --check` passes.
- Telegraphs, facing, weapon state, and recovery are visually readable.
- Player defeat, room reset, and enemy defeat release every reservation.

## First Execution Batch

Start with Milestone 1 only.

The first batch should end when Pawn and Knight use explicit contexts and intents while the current room still plays the same. Do not add Bishop behavior in the same batch. This creates a clean review point before coordination becomes more sophisticated.

## Estimated Work Order

| Order | Milestone | Relative size | Playable result |
|---:|---|---:|---|
| 1 | Intent Foundation | Medium | Existing encounter on new AI core |
| 2 | Coordination and Fairness | Medium | Reliable mixed-enemy combat |
| 3 | Pawn/Knight Personality | Medium | First polished combat loop |
| 4 | Bishop Controller | Medium | First true zone-control encounter |
| 5 | Rook Charger | Medium-Large | Terrain-driven combat |
| 6 | Boss Framework | Large | Queen and King production foundation |

Queen and King content should begin only after Pawn, Knight, Bishop, and Rook pass their acceptance gates.
