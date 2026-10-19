# Room Authoring Guide

For the owner, working in the Godot editor. Rewritten in the M1a fix for the ECS runtime (the
earlier text described the node era: `enemy_scene` markers, `blocked_cells`) and updated in M1b
for the folders the files now live in (`content/rooms/<id>/room.tscn` and so on). It is the
deliverable of `TOOL.2` and also answers `TOOL.3` (section 7) and `TOOL.4` (section 6); the owner
approves those gates. The code it describes is in `docs/ARCHITECTURE.md`, "Authoring: scenes as
spawn data".

**The one idea.** A room scene is spawn data. Nothing in the scene decides anything. When the room
boots, `EcsBoot` (`authoring/ecs_boot.gd`) reads the scene once: parked enemy views become
entities, painted solid tiles become walls, markers become doors, gates and pickups. What the
editor shows is what spawns. No script owns room content.

## 1. The room scene

Rooms live in `content/rooms/<id>/room.tscn` (T1-T4, B1, H1; the folder name is the room's id and
`room.tscn` is its role file). `first_encounter` and the 72x40 kingdom are test fixtures now, in
`tests/fixtures/`. Each room is an instance of `authoring/room_encounter.tscn`. Select the root node
and the Inspector shows:

| Field | What it does |
|---|---|
| `zone_id` | The room's id. It must match its key in `content/world/world.tres`. Empty means "a standalone room outside the world graph" (`first_encounter`). |
| `board_size` | Cells the room spans (default 16 x 9). `EcsBoot` sizes the grid from it. |
| `room_message` | Text shown when the room starts, unless the objective has its own `start_message`. |
| `objective` | A `RoomObjective` `.tres`: start, clear and defeat texts and the win condition. |

The tree as it is today (`content/rooms/t3_first_pawn_clash/room.tscn`):

```text
T3_FirstPawnClash          room root: zone_id, board_size, room_message, objective
  RoomArt                  art only (everything below it is drawing, except TileMap)
    Frame
    TileMap                walls: any solid tile blocks movement and pathing
    GridLines
    SetDressing/...
  PawnRecruit              an enemy: an instance of presentation/views/actors/black_pawn.tscn
  Entry_West               ZoneEntryMarker: where the hero arrives
  Exit_To_T4               ZoneExitMarker: a door
```

`TOOL.2` pictured separate `Entries`, `Exits`, `Enemies` and `Pickups` folder nodes. They do not
exist. Markers, enemies and pickups are direct children of the room root, and `EcsBoot` only looks at
direct children. A marker moved under a folder node silently stops working.

## 2. What affects gameplay

| Node | Gameplay? | What the runtime reads |
|---|---|---|
| `RoomArt/TileMap` | Yes | Every painted cell whose tile has the custom data `solid = true` becomes a wall. The node must be at exactly this path. |
| Enemy instance (`ActorView` with a `definition`) | Yes | Its position becomes its start cell; `definition` is which piece it is. |
| `ZoneEntryMarker` | Yes | Its position is an arrival cell; `entry_id` names it. |
| `ZoneExitMarker` | Yes | Its position is a door cell. |
| `GateMarker` | Yes | Its cell is a wall until the hero pushes through it the right way. |
| `PlayerUnlockMarker` | Yes | Stepping on its cell unlocks a hero verb (for example the wooden sword). |
| `PickupSpawnPoint` | Yes | A weapon lying on its `grid_cell`. |
| `BlockerMarker` | No | Legacy. `EcsBoot` no longer reads it; paint a wall instead. |
| Everything else under `RoomArt` | No | Drawing only. Move it freely; it never changes gameplay. |

A cell is `floor((position - (64, 36)) / 32)`. Any point inside a cell works; its centre is
`(64 + 32x + 16, 36 + 32y + 16)`. For snapping while you drag, enable the editor's grid snap
(magnet icon): step `32 x 32`, offset `16 x 20`.

## 3. Placing things

**Enemies.** Instance an actor scene from `presentation/views/actors/` (`black_pawn.tscn`,
`knight_enemy.tscn`, `bishop_enemy.tscn`) as a direct child of the room and drag it onto a cell.
Override `definition` in the Inspector to change which piece it is (`content/enemies/<id>/enemy.tres`:
`pawn_recruit`, `pawn_armed`, `backstep_pawn`, `charging_pawn`, `black_pawn_captain`, `knight_tracker`,
`bishop_zoner`). To tune one instance, add a `HealthComponent`, `AIComponent` or `WeaponComponent`
child (from `authoring/entity_components/`); a component node on an instance beats the definition.

**The hero.** There is no hero marker. The hero appears on the `ZoneEntryMarker` the run arrived
through (matching `entry_id`; if none matches, the first entry marker in the room). A room with no
entry marker leaves the hero where it already stands: at the start of the game that is the
`PawnHero` node in `shell/game_root.tscn`, and if that is outside the board, cell (3, 7).

**Pickups.** Instance `authoring/markers/pickup_spawn_point.tscn`. It is a grid marker: set
`grid_cell` and the node snaps itself. Inspector: `weapon` (an `EnemyWeapon` `.tres` such as
`content/pickups/pencil_spear/pencil_spear.tres`), `pickup_scene` (the look; empty uses the default,
`presentation/views/weapon_pickup.tscn`), `active`.
**The node's name is its identity in the save file** (`zone_id/NodeName`): rename a pickup and the
game forgets it was taken.

**Unlocks and gates.** `authoring/markers/player_unlock_marker.tscn` (`unlock_id`, `message`) and
`authoring/markers/gate_marker.tscn` (`gate_id`, which must be unique across the whole game because
the save file keys on it; `opens_from`, the direction that opens it). A `GateMarker` with an empty
`gate_id` and a `ZoneExitMarker` with an empty `target_zone` show a warning icon in the Scene dock.

## 4. Doors and entries

A door is a `ZoneExitMarker`; an arrival cell is a `ZoneEntryMarker`. Neither has a prefab scene.
To add one, duplicate an existing `Exit_` or `Entry_` node (Ctrl+D) or use Add Child Node and pick
the class by name, then edit its fields.

| Field | Meaning |
|---|---|
| `ZoneExitMarker.target_zone` | A zone id from `content/world/world.tres`. |
| `ZoneExitMarker.target_entry` | The `entry_id` of a `ZoneEntryMarker` in the target room. A wrong id falls back to that room's first entry. |
| `ZoneExitMarker.requires_room_clear` | The door only works after every enemy in the room has fallen. For boss exits, not ordinary backtracking. |
| `ZoneExitMarker.locked_message` | The line the status bar says when the hero steps on the door while it is shut. Say what holds THIS room's door (a room without a captain must not blame one). Empty falls back to a generic line; `test_room_doors_reachable` fails a `requires_room_clear` door that leaves it empty. |
| `ZoneEntryMarker.entry_id` | The name a door elsewhere uses. Death also respawns the hero on the last entry used. |

Stepping onto a door cell fades out, swaps the room and rebuilds the world. The door cell must be
walkable: a door painted over by a solid tile cannot be reached. (T2's `Exit_To_T1` is in this state
today; see `findings.md`.)

**Adding a room.** (1) Make a new folder `content/rooms/<id>/` (the folder name is the id) and in it a
scene named `room.tscn` that inherits `authoring/room_encounter.tscn`; set `zone_id` (the same id) and
`board_size`. A room folder without a `room.tscn` fails `tests/architecture/test_content_has_no_gd.gd`.
(2) Add the scene to `zone_scene_by_id` in `content/world/world.tres`. (3) In the neighbouring room
add an exit to the new `zone_id`, and in the new room add the entry it names and an exit back.
(4) Open the game and walk through. If the room has a picture, it is `background.png` beside
`room.tscn` (T1 and T2 show theirs through `RoomArt/ProductionBackground`); the owner overwrites that
file to swap the art, and `tools/seed_placeholders.gd` records a generated stand-in so
`tools/list_placeholders.gd` can list it.

## 5. Running and reviewing a room

1. Save the room scene and press F5. The game boots the zone remembered in `user://saves/slot_0.cfg`
   (its checkpoint), or T1 on a first run. Walk to your room through the exits, or restart from T1 by deleting that
   file and `slot_0.cfg.bak` (editor menu Project > Open User Data Folder). Pressing R reloads the current zone.
2. If the first ten seconds feel messy, move fewer things at once and retest.
3. Run `/verify`. The room dump test (`tests/architecture/test_dump_baselines.gd`) compares every
   baseline room against `tests/baselines/dump_<room>.txt`. Changing a room on purpose turns it red
   with a line-level diff. Review the diff, then accept it:
   `godot --headless --path . -s tools/dump_world.gd -- --write-baselines`, and commit the new
   baselines in the same commit as the room change.

## 6. Painting walls (TOOL.4)

* **Which TileMap:** `RoomArt/TileMap`, a `TileMapLayer`, using `content/tilesets/kingdom/tileset.tres`
  (source image `assets/tiles/kingdom/atlas.svg`, 32 x 32 tiles).
* **Which tiles are solid:** the ones whose custom data layer `solid` is true. Select the TileSet
  resource to see the `solid` layer under Custom Data Layers; the per-tile checkbox is in the
  TileSet panel at the bottom of the editor (Paint tab, Custom Data).
* **Does the picture affect collision?** Yes, because they are the same data. Paint a solid tile and
  that cell is a wall; erase it and the cell opens. Art and collision cannot disagree.
* **Shared tile layer:** every room today instances the shared `content/tilesets/kingdom/tilemap.tscn`
  without painting of its own. Painting inside a room scene stores the cells in that room's scene as
  an override and leaves the shared file alone. To change every room at once, edit the shared file.
* **Do not hand-edit `tile_map_data`.** It is a binary blob. Use the editor's TileMap tools, or one
  of the `tools/paint_*.gd` scripts (they use `ResourceSaver`: run `tools/stamp_uids.gd` afterwards).
* **Do not cover exits and spawns.** Nothing warns you if you paint a solid tile over a door, an
  entry, a start cell, an enemy or a pickup. After painting, check each one is still on a floor cell
  and press play.
* **Readability:** keep the grid lines visible while painting (`RoomArt/GridLines`) so a wall and a
  floor cell never look alike.

## 7. Importing art and audio (TOOL.3)

* **Pixel art stays sharp.** The project default is nearest filtering
  (`rendering/textures/canvas_textures/default_texture_filter = 0`); the existing sprites import
  lossless with no mipmaps. Do not set linear filtering on a sprite.
* **Folders by purpose.**
  `assets/_generated/` (`chess/`, `tiles/`, `maps/`, `rooms/`, `piece_templates/`) is rebuilt by
  `tools/generate_*.gd` and is gitignored (run `tools/bootstrap_worktree.sh` on a fresh checkout);
  no scene may name it. A picture the game uses lives in `content/<kind>/<id>/` under a role name
  (`body.png`, `icon.png`, `background.png`) and is tracked; the owner overwrites it and nothing else
  changes. `assets/ui/actor_view/` holds the overlay pictures every actor shares.
  `assets/map_pieces/` is hand-drawn source art. `assets/concept-art/` is reference only, never
  production art. `assets/tiles/<kit>/` holds the tile atlases (one PNG per tile is the plan:
  `assets/tiles/<kit>/<tile_id>.png`, assembled by a tool later), `assets/sfx/` and `assets/music/` the
  sounds. `tools/list_placeholders.gd` prints which of these are still stand-ins.
* **Sidecars are part of the asset.** Commit each `.import` file with its asset and each `.uid` with
  its script.
* **Audio buses.** `default_bus_layout.tres` is Master with SFX, Music, UI and Voice sending to it.
  A player must name one of those buses; `tests/audio/test_audio_buses.gd` fails if it does not.
  Event sounds with no animation clip go through the `SfxManager` registry (recipe: `/new-sound`).
* **Generated art is not final.** Art direction is the owner's; agents hand art over for approval.

## 8. What not to edit

* `ecs/` and the systems: all decisions live there. Views and components hold no logic.
* `.uid` and `.import` files, and `tile_map_data` lines, by hand.
* Anything under `assets/_generated/` (chess, tiles, maps, rooms, piece_templates): regenerate it instead.
* Content values inside scripts: tuning lives in `.tres` files under `content/`, and the Resource is the truth.
* Moving or renaming a file in the editor's FileSystem dock: use `tools/move_res.py`, which keeps the
  sidecars and every `res://` path in step.
