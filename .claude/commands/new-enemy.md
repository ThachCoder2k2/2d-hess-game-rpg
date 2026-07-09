---
description: Scaffold a new enemy entirely from data (no new script), Bishop-style
argument-hint: <enemy-name> [chess piece / behavior notes]
---

Create a new enemy called **$ARGUMENTS** using only Resources + a scene wiring the
generic `EnemyActor`. **Write zero new gameplay script** — this is the whole point of
the editor-first architecture. Follow the Bishop (commit `6831b6a`) as the template.

Steps:

1. Decide identity from the request: movement directions, unarmed attack shape,
   AI personality (role), health, weapon tags. Ask the human only if genuinely
   ambiguous; otherwise pick sensible values and state them.

2. Create these `.tres` (copy the closest existing file and edit values):
   - `resources/movement/<name>.tres` (`MovementConfig`) — `allowed_directions`, timing.
   - `resources/attacks/<name>.tres` (`AttackPattern`) — `cell_offsets`, `uses_facing`,
     `clip_to_board`, telegraph/recovery.
   - `resources/decisions/<name>.tres` (`DecisionConfig`) — scores, `preferred_distance`,
     `flank_bonus`/`axis_change_bonus`, `role_policy`.
   - `resources/visuals/<name>_compatibility.tres` (`VisualDefinition`) — point
     `visual_scene` at an existing visual as placeholder art; distinct telegraph color.
   - `resources/enemies/<name>.tres` (`EnemyDefinition`) — `id`, `display_name`,
     `piece_name`, `role`, `max_health`, and refs to the four above + shared
     `resources/difficulty/standard.tres`.

3. Create `objects/actors/<name>_enemy.tscn` — copy `objects/actors/bishop_enemy.tscn`,
   change the definition ext_resource to your `<name>.tres` and the Visual to your
   chosen visual scene. Root stays `EnemyActor`; keep the 4 components + Visual +
   `[editable path="Visual"]`.

4. Add a test block to `tests/run_tests.gd` (copy the Bishop block): assert it uses
   `enemy_actor.gd` (no per-enemy script), moves/attacks per its data, and carries a
   pure `DecisionConfig`.

5. Run the editor import once (new class refs), then run `/verify`. All green.

6. To play it: tell the human to set an `EnemySpawnPoint.enemy_scene` in a room to the
   new `.tscn` (room placement is their editor call).

7. Update `progress.md` + `task_plan.md`, commit (stage explicit paths, exclude the
   human's dirty files), push.

Note the placeholder art: reusing an existing visual is fine for a first pass; flag
that a bespoke sprite is a later art-pass item for the human to approve.
