---
description: Scaffold a new enemy entirely from data (no new script), Bishop-style
argument-hint: <enemy-name> [chess piece / behavior notes]
---

Create a new enemy called **$ARGUMENTS** using only Resources (and, at most, a thin scene).
**Write zero new gameplay script** — this is the whole point of the editor-first ECS
architecture: an enemy is data (`EnemyDefinition` and the `.tres` it composes) and a puppet
view; the shared systems (`EnemyAISystem`, `MovementSystem`, `HealthSystem`, `ViewSyncSystem`)
do the rest. Follow the Bishop (commit `6831b6a`; today `content/enemies/bishop_zoner/` and the thin
scene `presentation/views/actors/bishop_enemy.tscn`) as the template.

The enemy is a folder under `content/` (zero `.gd` files there, the folder name is the id). There is
ONE actor view, `presentation/views/actors/actor_view_base.tscn` (the nodes, the clips, the
animation graph); an enemy needs no scene of its own: instance the base in a room and set its
`definition` (step 3). Do not copy an actor scene, and do not move files by hand: only
`tools/move_res.py` moves a file.

A piece is smaller than its cell (the owner's decision of 2026-10-12): its body picture may be no
larger than the box `content/feel/piece_sizes.tres` gives its kind, and the game stands it on that
kind's base line. Heights follow a real chess set (pawn lowest, king tallest).

Steps:

1. Decide identity from the request: how the piece moves, its unarmed attack shape, AI
   personality (role), health, weapon tags. Ask the human only if genuinely ambiguous;
   otherwise pick sensible values and state them. Art direction is the human's: reuse an
   existing sprite as a placeholder and say so.

2. Create the folder `content/enemies/<id>/` (`<id>` is the `EnemyDefinition.id`, snake_case)
   with these `.tres`. Copy the closest existing enemy's file and edit values; never duplicate a
   value in code. (A text copy of a `.tres` or `.tscn` also copies its header `uid="..."`, and two
   files must not share one: delete the `uid="..."` part of the copy's first line and run
   `tools/stamp_uids.gd`, which gives every uid-less file a fresh uid. Duplicating in the editor
   does this for you. Never re-save a file with a headless `ResourceSaver`: it drops uids.) A piece several enemies would share (a movement, attack or decision a pawn
   variant reuses) belongs in `content/enemies/_shared/{movement,attacks,decisions,visuals}/`
   instead, and the enemy's `enemy.tres` points at it; the Bishop and Knight keep their own pieces
   beside `enemy.tres`, named for the `EnemyDefinition` export they fill:
   - `movement.tres` (`MovementConfig`) — `allowed_directions` is the list of **offsets of
     one move**, the piece's own chess law (Pawn: four cardinal; Bishop: four diagonals; Knight:
     the eight L offsets). Plus `step_duration`, `move_recovery`, `preferred_distance`.
   - `unarmed_attack.tres` (`AttackPattern`) — `cell_offsets`, `uses_facing`, `clip_to_board`,
     `damage`, `telegraph_duration`, `recovery_duration`, `requires_attack_token`.
   - `decision.tres` (`DecisionConfig`) — scores, `aggro_radius`, `preferred_distance`,
     `flank_bonus`/`axis_change_bonus`, `role_policy`.
   - `visual.tres` (`VisualDefinition`) — `piece_type` (a row of `piece_sizes.tres`: pawn, knight,
     bishop, rook, queen, king, or a boss row), `body_texture` (this enemy's `body.png`),
     `anchor_offset` (a nudge, normally zero), `clip_speed_scales` (clip name to a multiple of the
     base tempo: `{idle: 1.25}` plays idle 25 % faster; unlisted clips play at 1.0), plus the
     telegraph and impact colors. The base scene reads it: the body appears on the base line with no
     scene edit, and the clips run at the stated speed. A piece several enemies share goes in
     `_shared/visuals/` (the black pawns share `pawn_compatibility.tres`).
   - `enemy.tres` (`EnemyDefinition`) — `id`, `display_name`, `piece_name`, `role`, `max_health`,
     and refs to the four above plus the shared `content/difficulty/standard.tres`. Optional:
     `default_weapon`, `allowed_weapon_tags`. `validate()` must return no warnings.
   - `body.png` — the enemy's picture, drawn at scale 1, no larger than its kind's box. A first
     pass may name an existing enemy's `body.png` in `visual.tres` (the black pawns share
     `content/enemies/pawn_recruit/body.png`), or the generator can paint a stand-in
     (`tools/generate_chess_sprites.gd` reads the size table and refuses a piece that does not fit):
     add a `GENERATED_SEEDS` row to `tools/seed_placeholders.gd` (kind `body`, id `<id>`), run the
     generator, the seed tool and the import pass, and commit `content/_placeholders.json`, so
     `tools/list_placeholders.gd` shows the owner it is still to draw. The owner swaps it by
     overwriting `body.png`; `ContentDb.validate_cross_refs()` fails if a picture is larger than
     the box.

3. The view. Usually nothing to create: in a room (or any scene) instance
   `presentation/views/actors/actor_view_base.tscn`, set its `definition` to
   `content/enemies/<id>/enemy.tres` and park it on a cell. If the piece should look or feel
   different in a way the data does not cover (a telegraph colour, no facing arrow, a different
   `weapon_held_scale`), make a THIN scene: in the editor, New Inherited Scene from
   `actor_view_base.tscn`, set the `definition` and those values, and save it as
   `presentation/views/actors/<id>_enemy.tscn`, as `bishop_enemy.tscn` does. A thin scene is under
   40 lines and owns no clip, graph or other sub-resource (`test_one_actor_view` fails otherwise); to
   change a clip or the graph, edit the base (that changes every actor). Keep the node names and
   paths (`MotionRoot/SpriteRoot/BodySprite`, `WeaponPivot`, `HealthPips`, `TelegraphAura`,
   `FacingArrow`, `AudioPlayer`). It needs no `EntityComponent` child nodes; add `AIComponent`,
   `WeaponComponent` or `HealthComponent` only for a per-instance override. Never add a script with
   gameplay in it and never `_draw()` the body.

4. Add tests (copy the Bishop block of `tests/run_tests.gd`):
   - if you made a thin scene, add `"res://presentation/views/actors/<id>_enemy.tscn": &"<id>"` to
     `expected_definitions` in `tests/run_tests.gd` (it then asserts the view has a definition,
     validates, owns sprites, telegraph and defeat clips, an audio player and a state graph) and to
     `ENEMY_SCENE_PATHS` in `tests/architecture/test_pieces_inside_cell.gd`. The in-cell test already
     puts EVERY enemy of `content/enemies/` on `actor_view_base.tscn` and measures it facing every
     way, armed and telegraphing, so the new enemy's body, pips, arrow, weapon and aura are checked
     inside the cell with no edit; look at `assets/_generated/previews/pieces_in_cells.png`
     (`tools/render_actor_preview.gd`) to see it;
   - add a data block asserting the movement offsets, the attack cells for a known origin
     and facing, and the decision role come from the `.tres` (assertion labels read as a
     spec). If the enemy has behavior worth proving, add a case to `tests/ecs_enemy_test.gd`
     that boots it in an `EcsWorld` and ticks by hand.
   `tests/architecture/test_content_has_no_gd.gd` already checks that every enemy folder holds an
   `enemy.tres` and the Book check in `run_tests.gd` loads every enemy folder, so a folder without
   one fails.

5. Run the editor import once (new class refs, new resources, and the `.import` of a new PNG),
   then run `/verify`. All green, and `stamp_uids.gd --check` CLEAN. `ContentDb` finds the new
   folder by its name with no registration; `tests/content/test_validate_all.gd` then fails if the
   folder name is not lowercase snake_case, if `enemy.tres`' `id` differs from the folder name, or
   if `validate()` reports anything (a `visual.tres` without a `piece_type` and a `body_texture`
   fails too). A Book page whose `piece_id` names a missing enemy fails
   `ContentDb.validate_cross_refs()`.

6. To play it: instance the actor scene (the base with `definition` set, or your thin scene) in a room scene under
   `content/rooms/<room id>/room.tscn` and park it on a cell. `EcsBoot` spawns an entity for every
   `ActorView` child of the room that has a `definition`, at the cell containing its parked
   position, and keeps the node as the puppet. Override `definition` on the instance for a
   variant. Exact placement is the human's editor call. A room edit changes
   `tests/baselines/dump_<room>.txt`: regenerate it with `tools/dump_world.gd --write-baselines`
   in the same commit and say what changed.

7. Optional: if the enemy should add a page to the Book of House Rules, author a `RuleEntry`
   `.tres` at `content/rules/<page id>/page.tres` whose `piece_id` equals the
   `EnemyDefinition.id` and add it to `content/rules/rule_book.tres`; the page unlocks the first
   time the player shares a zone with the piece.

8. Update `progress.md` + `task_plan.md`, commit (stage explicit paths, one logical change,
   include any new `.gd.uid` and every new image's `.import`; exclude the human's dirty files),
   push.

Note the placeholder art: reusing an existing sprite is fine for a first pass; flag that a
bespoke sprite is a later art-pass item for the human to approve (`tools/list_placeholders.gd`
lists it). Hand off the room placement and feel with the AGENTS.md format (Open / Tune / Goal /
Try / Tell me).
