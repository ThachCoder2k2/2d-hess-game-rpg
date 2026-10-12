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

An enemy is a folder under `content/enemies/<id>/` (zero `.gd` files there, the folder name is the id,
lowercase snake_case). The smallest enemy is **one file**, `enemy.tres`, that points at pieces in
`content/enemies/_shared/` (a re-skin of a pawn with other health, speed or weapon); a new picture adds
`visual.tres` and `body.png` (three files, plus the `.import` sidecar the editor writes). There is ONE
actor view, `presentation/views/actors/actor_view_base.tscn` (the nodes, the clips, the animation
graph); an enemy needs no scene of its own: instance the base in a room and set its `definition`
(step 3). Do not copy an actor scene, and do not move files by hand: only `tools/move_res.py` moves a
file.

A piece is smaller than its cell (the owner's decision of 2026-10-12): its body picture may be no
larger than the box `content/feel/piece_sizes.tres` gives its kind, and the game stands it on that
kind's base line. Heights follow a real chess set (pawn lowest, king tallest).

Shell used below (project root; the path has a space, so quote it; from a git worktree the binary is
`../../../../Godot.app/Contents/MacOS/Godot`):

```bash
G="../Godot.app/Contents/MacOS/Godot"
export HOME=/tmp/unbound-pawn-godot        # a private HOME: Godot writes its user:// data and editor settings there
```

Steps:

1. Decide identity from the request: how the piece moves, its unarmed attack shape, AI
   personality (role), health, weapon tags. Ask the human only if genuinely ambiguous;
   otherwise pick sensible values and state them. Art direction is the human's: reuse an
   existing sprite as a placeholder and say so.

2. Create the folder `content/enemies/<id>/` (`<id>` is the `EnemyDefinition.id`, snake_case)
   with these files. Copy the closest existing enemy's file and edit values; never duplicate a
   value in code. A piece several enemies would share (a movement, attack or decision a pawn
   variant reuses) belongs in `content/enemies/_shared/{movement,attacks,decisions,visuals}/`
   instead, and the enemy's `enemy.tres` points at it; the Bishop and Knight keep their own pieces
   beside `enemy.tres`, named for the `EnemyDefinition` export they fill:
   - `enemy.tres` (`EnemyDefinition`) — `id`, `display_name`, `piece_name`, `role`, `max_health`
     (default 2, between 1 and 100), and refs to the four below plus the shared
     `content/difficulty/standard.tres`. Optional: `default_weapon`, `allowed_weapon_tags`.
     `validate()` must return no warnings. The smallest useful enemy is this file alone, pointing at
     `_shared/` (see the worked example below).
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
     base tempo: `{idle: 1.25}` plays idle 25 % faster; unlisted clips play at 1.0). It holds only what the
     game reads (the telegraph tint is `telegraph_modulate` on the actor view, the hand is `weapon_anchor`
     on the actor view). The base scene reads it: the body appears on the base line with no
     scene edit, and the clips run at the stated speed. A piece several enemies share goes in
     `_shared/visuals/` (the black pawns share `pawn_compatibility.tres`).
   - `body.png` — the enemy's picture, drawn at scale 1 on the 32 x 32 canvas of `docs/assets` (base rim on
     row 30, two empty rows under it) with the drawn pixels inside its kind's box (pawn 18 x 22,
     knight, bishop, rook 20 x 24, queen 22 x 26, king 22 x 28; transparent padding is free). The canvas lands
     exactly on the cell, so no scene needs a position. A smaller picture that fits the box also runs, its
     bottom edge on the base line. A first pass may name an existing enemy's `body.png` in `visual.tres` (the black pawns share
     `content/enemies/pawn_recruit/body.png`), or the generator can paint a stand-in
     (`tools/generate_chess_sprites.gd` reads the size table and refuses a piece that does not fit):
     add a `GENERATED_SEEDS` row to `tools/seed_placeholders.gd` (kind `body`, id `<id>`), or, for a copy of a
     picture that already exists, an `ADOPTED_PLACEHOLDERS` row with the file's path; run
     `"$G" --headless --path . -s tools/seed_placeholders.gd` and commit `content/_placeholders.json`, so
     `tools/list_placeholders.gd` shows the owner it is still to draw. The owner swaps it by overwriting
     `body.png`; `ContentDb.validate_cross_refs()` fails (and names the picture, its size and the box) if a
     picture is larger than the box.

   **The uid dance (do it in this order, once, after the files exist).** A text copy of a `.tres` also
   copies its header `uid="..."`, and two files must not share one (duplicating a file in the editor's
   FileSystem dock gives the copy a fresh uid for you; a text copy does not): delete the ` uid="..."` part of
   the copy's first line, and in a reference to a file you just made (`visual.tres`, `body.png`) leave the
   `[ext_resource ...]` line **path-only** (no `uid=`). Then:

   ```bash
   "$G" --headless --path . --editor --quit                   # 1. import: gives body.png its .import and uid
   "$G" --headless --path . -s tools/stamp_uids.gd            # 2. gives every uid-less header a uid and fills the path-only lines
   "$G" --headless --path . --editor --quit                   # 3. import again, so the new uids are registered
   "$G" --headless --path . -s tools/stamp_uids.gd -- --check # 4. must print CLEAN
   ```

   Skip step 3 and a scene that names the new file prints `ext_resource, invalid UID ... using text path
   instead`; the game still loads it, the warning goes away after the import. Never re-save a file with a
   headless `ResourceSaver`: it drops uids.

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
     puts EVERY enemy of `content/enemies/` on `actor_view_base.tscn`, and every actor a room scene places
     as the room placed it (a scale or a turn on the instance fails by room and name), and measures each
     facing every way, armed, telegraphing and shoved by a hit, so the new enemy's body, pips, arrow, weapon and aura are checked
     inside the cell with no edit, and a failure names the enemy (`test_pawn on actor_view_base.tscn ...`).
     `assets/_generated/previews/pieces_in_cells.png` (`tools/render_actor_preview.gd`, drawn by
     `tools/bootstrap_worktree.sh`) shows the hero and the three thin scenes (black pawn, knight, bishop);
     an enemy that only has a `definition` is checked by the test but is not a row of that picture (once a room
     places it, it is a row of `pieces_placed_in_rooms.png`);
   - add a data block asserting the movement offsets, the attack cells for a known origin
     and facing, and the decision role come from the `.tres` (assertion labels read as a
     spec). If the enemy has behavior worth proving, add a case to `tests/ecs_enemy_test.gd`
     that boots it in an `EcsWorld` and ticks by hand.
   `tests/architecture/test_content_has_no_gd.gd` already checks that every enemy folder holds an
   `enemy.tres` and the Book check in `run_tests.gd` loads every enemy folder, so a folder without
   one fails.

5. Run the import pass and the stamper as above, then `/verify`. All green, and `stamp_uids.gd --check`
   CLEAN. `ContentDb` finds the new folder by its name with no registration; `tests/content/test_validate_all.gd`
   then fails if the folder name is not lowercase snake_case, if `enemy.tres`' `id` differs from the folder
   name, or if `validate()` reports anything (a `visual.tres` without a `piece_type` and a `body_texture`
   fails too). A Book page whose `piece_id` names a missing enemy fails `ContentDb.validate_cross_refs()`.
   To run just that suite: `"$G" --headless --path . -s tests/content/test_validate_all.gd` (look for
   `enemies/<id> loads`, `passes its own validate()` and `TEST VALIDATE ALL: PASS`).

6. To see it spawn without committing a room, put a throwaway scene in the project root (not in `content/`),
   instance the base in it, set `definition`, and boot it with the dump tool:
   `"$G" --headless --path . -s tools/dump_world.gd -- --room=res://scratch_room.tscn --ticks=2`. The dump
   lists the entity (`entity 3 enemy:Pawn cell=(7,3) health=5/5`) and the body texture the view got. Delete the scene
   afterwards: a room folder under `content/rooms/` that the world graph does not name fails
   `test_validate_all` ("no zone of content/world/world.tres leads here"), and a scene under `content/` that names
   `presentation/board/` fails `test_content_references`.
   To place it for real, instance the actor scene (the base with `definition` set, or your thin scene) in
   `content/rooms/<room id>/room.tscn` and park it on a cell. `EcsBoot` spawns an entity for every `ActorView`
   child of the room that has a `definition`, at the cell containing its parked position, and keeps the node
   as the puppet. Override `definition` on the instance for a variant. Exact placement is the human's
   editor call. A room edit changes `tests/baselines/dump_<room>.txt` (`test_dump_baselines` fails until you
   regenerate it with `"$G" --headless --path . -s tools/dump_world.gd -- --write-baselines`, in the same commit,
   saying what changed), and a test that counts a room's pawns can fail too: adding a pawn to T3 fails
   `tests/bridge/test_bridge_travel.gd` ("T3 holds its single living pawn"). There is no `dev_sandbox` room yet
   (it arrives with M6), so a real room is the only place to play it.

7. Optional: if the enemy should add a page to the Book of House Rules, author a `RuleEntry`
   `.tres` at `content/rules/<page id>/page.tres` whose `piece_id` equals the
   `EnemyDefinition.id` and add it to `content/rules/rule_book.tres`; the page unlocks the first
   time the player shares a zone with the piece.

8. Update `progress.md` + `task_plan.md`, commit (stage explicit paths, one logical change,
   include any new `.gd.uid` and every new image's `.import`; exclude the human's dirty files),
   push.

## Walked once for real (2026-10-13, M2 step 3)

On a scratch clone of the M2 branch (bootstrap, then the steps above), nothing committed, all of it deleted
afterwards. The enemy was `test_pawn`, 5 health, reusing the shared pawn pieces:

| What I did | What happened |
|---|---|
| Copied `pawn_recruit/enemy.tres` to `test_pawn/enemy.tres`; removed the header uid; set `id = &"test_pawn"`, `display_name`, `max_health = 5` | one file; `max_health` is a line to add (the default 2 is not written in the source file) |
| `tools/stamp_uids.gd` | "headers without uid: 1 stamped" |
| `tests/content/test_validate_all.gd` | `content/enemies holds at least 7 entries (found 8)`, four `enemies/test_pawn ...` lines PASS, `TEST VALIDATE ALL: PASS` |
| Instanced `actor_view_base.tscn` in a scratch room scene, set `definition` to the file, dumped it | `entity 3 enemy:Pawn cell=(7,3) health=5/5`; the same room with the real pawn showed `health=2/2` |
| Edited the stamped uid into a scene before any import | `invalid UID ... using text path instead` until the import pass ran; after it, no warning |
| Put the instance in the real T3 room | the strict runner went red on exactly two suites: `test_dump_baselines` (t3's dump changed) and `test_bridge_travel` ("T3 holds its single living pawn") |
| Made `content/rooms/scratch_test_pawn/room.tscn` instead | four suites red: not in `world.tres`, names `presentation/board/` (so: scratch scene in the project root, not under `content/`) |
| Gave it its own `visual.tres` and `body.png` (a copy of the pawn's; 3 files) and ran import, stamp, import, check | one stamp pass filled 2 header uids and 2 path-only lines (the picture's uid and the new visual's); `stamp_uids --check` CLEAN; the dump shows `BodySprite -> res://content/enemies/test_pawn/body.png`; the strict runner GREEN (35 suites, 235 of 235 labels) |
| Replaced `body.png` with a 26 x 32 picture | `test_validate_all` red with "its body picture is 26 x 32 px but a pawn may be drawn at most 18 x 22 px, or on the 32 x 32 canvas of the art spec with its drawn pixels inside that box"; `test_pieces_inside_cell` red with 17 FAIL lines naming `test_pawn` (the narrowest margin is -2.00 px) |
| Added an `ADOPTED_PLACEHOLDERS` row and ran `seed_placeholders.gd` | `_placeholders.json` 26 to 27 entries; `list_placeholders.gd` showed `content/enemies/test_pawn/body.png` |
| Overwrote the picture with a 12 x 16 one (the owner's swap) | "27 recorded, 26 still to replace, 1 replaced by you"; both suites green again |
| Deleted `content/enemies/test_pawn/`, restored the seed file and manifest, import pass | strict runner GREEN, working tree clean |

Counted for the owner (`docs/OWNER_GUIDE.md` section 5): a re-skin that reuses `_shared` is **1 file**
(`enemy.tres`) plus the room edit that places it; with a picture of its own it is **3 files** (`enemy.tres`,
`visual.tres`, `body.png`; the editor adds `body.png.import`), plus the room edit, and one
`_placeholders.json` row if the owner should see it on the to-draw list. The name row in a `.po` file arrives
with M4.

Note the placeholder art: reusing an existing sprite is fine for a first pass; flag that a
bespoke sprite is a later art-pass item for the human to approve (`tools/list_placeholders.gd`
lists it). Hand off the room placement and feel with the AGENTS.md format (Open / Tune / Goal /
Try / Tell me).
