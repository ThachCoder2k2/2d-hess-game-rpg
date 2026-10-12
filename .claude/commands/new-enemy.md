---
description: Scaffold a new enemy entirely from data (no new script), Bishop-style
argument-hint: <enemy-name> [chess piece / behavior notes]
---

Create a new enemy called **$ARGUMENTS** using only Resources plus an `ActorView` scene.
**Write zero new gameplay script** — this is the whole point of the editor-first ECS
architecture: an enemy is data (`EnemyDefinition` and the `.tres` it composes) and a puppet
view; the shared systems (`EnemyAISystem`, `MovementSystem`, `HealthSystem`, `ViewSyncSystem`)
do the rest. Follow the Bishop (commit `6831b6a`, `resources/enemies/bishop_zoner.tres`,
`objects/actors/bishop_enemy.tscn`) as the template.

This recipe describes today's folders. Milestone M2 of `docs/game-base-plan.md` rewrites it
for the `content/` layout; do not move files to match that layout yourself.

Steps:

1. Decide identity from the request: how the piece moves, its unarmed attack shape, AI
   personality (role), health, weapon tags. Ask the human only if genuinely ambiguous;
   otherwise pick sensible values and state them. Art direction is the human's: reuse an
   existing sprite as a placeholder and say so.

2. Create these `.tres` (copy the closest existing file and edit values; never duplicate a
   value in code):
   - `resources/movement/<name>.tres` (`MovementConfig`) — `allowed_directions` is the list
     of **offsets of one move**, the piece's own chess law (Pawn: four cardinal; Bishop: four
     diagonals; Knight: the eight L offsets). Plus `step_duration`, `move_recovery`,
     `preferred_distance`.
   - `resources/attacks/<name>.tres` (`AttackPattern`) — `cell_offsets`, `uses_facing`,
     `clip_to_board`, `damage`, `telegraph_duration`, `recovery_duration`,
     `requires_attack_token`.
   - `resources/decisions/<name>.tres` (`DecisionConfig`) — scores, `aggro_radius`,
     `preferred_distance`, `flank_bonus`/`axis_change_bonus`, `role_policy`.
   - `resources/visuals/<name>_compatibility.tres` (`VisualDefinition`) — telegraph and impact
     colors, `weapon_anchor`, hurt/defeat clip names. (It no longer points at a visual scene;
     the sprites live in the actor scene.)
   - `resources/enemies/<name>.tres` (`EnemyDefinition`) — `id`, `display_name`,
     `piece_name`, `role`, `max_health`, and refs to the four above plus the shared
     `resources/difficulty/standard.tres`. Optional: `default_weapon`, `allowed_weapon_tags`.
     `validate()` must return no warnings.

3. Create `objects/actors/<name>_enemy.tscn` — copy `objects/actors/bishop_enemy.tscn`,
   point the `definition` ext_resource at your `<name>.tres`, and swap the `BodySprite`
   texture (plus `telegraph_modulate` and clip values if the piece should feel different).
   Keep the root as an `ActorView` (`scripts/ecs/actor_view.gd`) with its `MotionRoot/
   SpriteRoot` sprites, `TelegraphAura`, `AnimationPlayer`, `AnimationTree` state graph and
   `AudioPlayer`. It needs no `EntityComponent` child nodes; add `AIComponent`,
   `WeaponComponent` or `HealthComponent` only for a per-instance override. Never add a script
   with gameplay in it and never `_draw()` the body.

4. Add tests to `tests/run_tests.gd` (copy the Bishop block):
   - add `"res://presentation/views/actors/<name>_enemy.tscn": &"<id>"` to `expected_definitions` (it
     then asserts the view has a definition, validates, owns sprites, telegraph and defeat
     clips, an audio player and a state graph);
   - add a data block asserting the movement offsets, the attack cells for a known origin
     and facing, and the decision role come from the `.tres` (assertion labels read as a
     spec). If the enemy has behavior worth proving, add a case to `tests/ecs_enemy_test.gd`
     that boots it in an `EcsWorld` and ticks by hand.

5. Run the editor import once (new class refs and new resources), then run `/verify`. All
   green.

6. To play it: instance the new `.tscn` directly in a room scene under `scenes/rooms/` and
   park it on a cell. `EcsBoot` spawns an entity for every `ActorView` child of the room that
   has a `definition`, at the cell containing its parked position, and keeps the node as the
   puppet. Override `definition` on the instance for a variant. Exact placement is the human's
   editor call.

7. Optional: if the enemy should add a page to the Book of House Rules, author a `RuleEntry`
   `.tres` whose `piece_id` equals the `EnemyDefinition.id` and add it to
   `resources/rules/rule_book.tres`; the page unlocks the first time the player shares a zone
   with the piece.

8. Update `progress.md` + `task_plan.md`, commit (stage explicit paths, one logical change,
   include any new `.gd.uid`; exclude the human's dirty files), push.

Note the placeholder art: reusing an existing sprite is fine for a first pass; flag that a
bespoke sprite is a later art-pass item for the human to approve. Hand off the room placement
and feel with the AGENTS.md format (Open / Tune / Goal / Try / Tell me).
