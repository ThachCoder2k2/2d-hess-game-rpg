# M1b migration notes

What moved where during M1b ("Folder migration", `docs/game-base-plan.md` section 15), and every place where the
plan's table (section 13.6) met something it did not expect and a call had to be made. Written by the agents doing
the moves; the owner can overrule any line here with one more `tools/move_res.py` move.

How to read this file: paths are written from the project root and never with the `res://` prefix on purpose,
because `tools/move_res.py` rewrites every `res://` string it finds in a `.md` file and this file describes
moves that already happened. The exact move list, oldest first, is `tools/move_res_log.tsv` (a file that
moved twice shows up as two lines; replaying the log with `--rewrite-only` follows the chain).

## Step 2: the code

Rule for the whole step: only `tools/move_res.py` moves a file (git mv, sidecars, `res://` rewrite). No script was
split or rewritten, no `class_name` was renamed, no scene changed except the `path=` text of an `ext_resource`
line (its `uid=` is untouched). `scripts/main.gd` stays one file; its split is M3b. The strict runner was run
after every commit and the deterministic dumps stayed equal: where a dump changed it was only the script path
string it prints for a moved script (same lines, same order), updated by the same `move_res.py` call in the same
commit.

All 51 non-test, non-tool scripts moved, so `scripts/` no longer exists. Scenes that belong to a moved script moved
with it (the marker prefabs, the room root, the HUD and Book, the pickup views, the SfxManager, the board and the
game scene).

### Where each thing went

| Was | Now |
|---|---|
| `scripts/data/{enemy_definition,visual_definition,movement_config,decision_config}.gd` | `schema/entity/` |
| `scripts/data/{room_objective,world_graph,rule_book,rule_entry}.gd` | `schema/world/` |
| `scripts/data/difficulty_profile.gd` | `schema/feel/` |
| `scripts/combat/{attack_profile,enemy_weapon}.gd`, `scripts/ai/attack_pattern.gd` | `schema/attacks/` |
| `scripts/ai/enemy_intent.gd` | `schema/entity/enemy_intent.gd` |
| `scripts/ecs/{ecs_world,ecs_grid,ecs_system}.gd` | `ecs/core/` |
| `scripts/ecs/ecs_components.gd` | `ecs/components/ecs_components.gd` (frozen) |
| `scripts/ecs/systems/player_input_system.gd` | `ecs/systems/input/` |
| `scripts/ecs/systems/enemy_ai_system.gd` | `ecs/systems/decide/` |
| `scripts/ecs/systems/movement_system.gd` | `ecs/systems/move/` |
| `scripts/ecs/systems/combat_system.gd` | `ecs/systems/act/` |
| `scripts/ecs/systems/health_system.gd` | `ecs/systems/resolve/` |
| `scripts/ecs/systems/view_sync_system.gd` | `ecs/systems/view/` |
| `scripts/ecs/{ecs_boot,ecs_actor_factory}.gd` | `authoring/` |
| `scripts/ecs/components/*` (the `*_component.gd` nodes and `entity_component.gd`) | `authoring/entity_components/`, names unchanged |
| `scripts/world/*_marker.gd`, `grid_marker.gd`, `pickup_spawn_point.gd` + `objects/markers/*.tscn` | `authoring/markers/` |
| `scripts/world/room_encounter.gd` + `objects/world/room_encounter.tscn` | `authoring/room_encounter.gd` / `.tscn` |
| `scripts/ecs/actor_view.gd` | `presentation/views/actor_view.gd` |
| `scripts/world/weapon_pickup.gd` + `objects/world/weapon_pickup.tscn`, `scripts/visuals/pickup_visual.gd` + `objects/visuals/weapon_pickup_visual.tscn` | `presentation/views/` |
| `scripts/ui/hud.gd` + `scenes/ui/hud.tscn` | `presentation/ui/hud/` |
| `scripts/ui/rule_book_ui.gd` + `scenes/ui/rule_book.tscn` | `presentation/ui/codex/` |
| `scripts/audio/sfx_manager.gd` + `objects/audio/sfx_manager.tscn` | `presentation/audio/` |
| `scripts/world/camera_rig.gd` | `presentation/camera/camera_rig.gd` |
| `scripts/world/prototype_board.gd` + `objects/world/prototype_board.tscn`, `scripts/world/grid_lines_overlay.gd` | `presentation/board/` |
| `scripts/world/world_state.gd` | `shell/save/world_state.gd` |
| `scripts/main.gd` + `scenes/main.tscn` | `shell/game_root.gd` / `shell/game_root.tscn` |

`project.godot` follows: `run/main_scene` is `shell/game_root.tscn`, the `SfxManager` autoload is
`presentation/audio/sfx_manager.tscn` and the `WorldState` autoload is `shell/save/world_state.gd`.

### Decisions where the plan's table needed a call

| Case | Plan says | What was done | Why |
|---|---|---|---|
| `DifficultyProfile` | the schema tree lists it on a shared line, `feel/ audio/` | `schema/feel/difficulty_profile.gd` | it is tuning of how hard the game feels; `schema/audio/` is for `SoundBank` and `MusicCues` |
| `EnemyIntent` | `scripts/ai/*` goes to `schema/*` | `schema/entity/enemy_intent.gd` (its sibling `AttackPattern` goes to `schema/attacks/`), name unchanged | it is a plain `RefCounted`, not a Resource, so `schema/` is not a perfect fit; but `EnemyAISystem` builds it, the board's F3 overlay draws it and `game_root.gd` passes it along in an event, so it is shared across three layers and `schema` (engine-only, every layer may read it) is the only layer all of them may name. It sits beside `DecisionConfig`, the scores that produce an intent. First placed in `ecs/systems/decide/`, then moved here (two commits) when the dependency report showed that placement adds a presentation to ecs/systems edge the frozen table would not allow |
| `RuleEntry`, `RuleBook` | `RulePage` lives in `schema/world/` | `schema/world/rule_entry.gd`, `schema/world/rule_book.gd`, names unchanged | the rename to `RulePage` is M7c; a rename now would break serialized references |
| `CombatSystem` | `act/SkillSystem (+ effect handlers; CombatSystem runs beside it until the M7b parity cutover)` | `ecs/systems/act/combat_system.gd` | the plan names the phase; `SkillSystem` does not exist yet (M7a) |
| Phase folders without a schedule | `ecs/schedule/<phase>.gd`, a `PHASE` const per system, `test_schedule_complete` | only the folders exist; the tick order is still the list in `game_root.gd` and `tools/world_dumper.gd` | schedule files, the `PHASE` const and the completeness test are M3a. Moving a file must not be mistaken for ordering it |
| `WorldState` | `shell/save/save_service.gd` + `ecs/core/world_flags.gd` in M3b | `shell/save/world_state.gd`, unchanged, autoload name `WorldState` | M3b rewrites it; until then it only has to live in the shell. The bridge tests and `game_root.gd` find the autoload by that name |
| `scripts/main.gd`, `scenes/main.tscn` | `shell/game_root.gd` / `.tscn`, body untouched, split in M3b; `main_scene = shell/app_root.tscn` | `shell/game_root.*`, `run/main_scene` points at `shell/game_root.tscn` | `app_root` (flow, transition, pause) does not exist until M3b/M4. The root node is still named `Main` so node lookups by name keep working |
| Marker file names | markers end in `_marker.gd` (13.3) | `pickup_spawn_point.gd` keeps its name, as do all the others | a rename is a churn commit with no behaviour; apply the suffix rule when a marker is next touched |
| HUD and Book | `presentation/ui/` with `hud/` (one scene per widget) and `codex/` (Book) | `presentation/ui/hud/hud.{gd,tscn}`, `presentation/ui/codex/rule_book_ui.gd` + `rule_book.tscn` | splitting the HUD into widget scenes is M4; the folders are ready for it |
| `weapon_pickup`, `pickup_visual` | "pickup view" in `presentation/views/` | both scripts and both prefabs in `presentation/views/` | `WeaponPickup` says in its header that it is a view of an entity, not an entity |
| `grid_lines_overlay.gd` | not named in 13.6 | `presentation/board/` | decorative `_draw()` overlay, same layer rule as `PrototypeBoard` |

### Test and tool changes the moves needed

* `tests/audio/test_audio_buses.gd` scanned only `scenes/` and `objects/` for audio players; every scene is
  leaving those folders, so it would have gone blind. It now lists every `.tscn` under the project
  (`TestPaths.project_directory()`, replacing `scenes_directory()`, `objects_directory()` and the unused
  `scripts_directory()`); its minimum counts are unchanged. `TestPaths.actors_directory()` and
  `rooms_directory()` still point at `objects/actors` and `scenes/rooms`: the content step moves them.
* `tests/architecture/test_dependency_edges.gd` lost its `LEGACY_LAYER_RULES` table (a layer is now the top
  folder) and gained one check: a script outside the layer folders fails the suite. The edge report is
  identical to the one printed on the step-1 tree (28 lines, only the headline text differs), so no layer
  changed by moving. `ENFORCING` is still false; the allowed-edge table is frozen at OG0.
* Comments that said `main.gd`, `scripts/main.gd` or `scenes/main.tscn` now say `game_root.gd`,
  `shell/game_root.gd`, `shell/game_root.tscn` (21 lines in 12 files; comment text only).
* Baseline labels: none needed renaming; `tests/label_renames.txt` is still empty.

### Gotcha for old checkouts

The first editor import pass after a commit that changes an AUTOLOAD path (`SfxManager`, `WorldState`) printed
`Failed to create an autoload` for the old path (stale editor state under `.godot/`); the second pass was clean
with no change in between. A commit that only moves the main scene, or any other file, did not do this. A fresh
clone or a freshly bootstrapped worktree has no such state; the final check of this step is on a fresh clone.

### Not done in step 2 (later steps)

* Content and fixtures: `objects/actors/*` (the four actor scenes), `objects/world/*tilemap*.tscn`,
  `scenes/rooms/*`, `scenes/zones/the_kingdom.tscn`, all of `resources/*`, the 12 tracked sprites in
  `assets/sprites/generated/`, `tools/seed_placeholders.gd` and `content/_placeholders.json`.
* `CLAUDE.md` and the prose docs. They still describe the old layout: `CLAUDE.md` (its folder map and
  `scripts/ecs/...` recipes, amendments A-1..A-9 of `docs/game-base-plan.md` 2.4), `AGENTS.md`, `README.md`,
  `docs/ARCHITECTURE.md`, `docs/coding-standards.md`, `docs/OWNER_GUIDE.md` and `.claude/commands/*.md`.
  `progress.md`, `task_plan.md` and `findings.md` are logs and keep their old paths as history.
* `ecs/events/`, `ecs/schedule/`, `schema/skills|progression|story|audio` do not exist yet: nothing lives there
  until M3a and later milestones.

## Step 3: the content

Same rules as step 2: only `tools/move_res.py` moved a file (git mv, sidecars, `res://` rewrite, the move
appended to `tools/move_res_log.tsv`), one folder or coherent group per commit, the strict runner after every
commit, no gameplay change, no scene edited except the `path=` text of `ext_resource` lines (their `uid=` is
untouched), no `ResourceSaver` re-save. The six dump baselines changed in 101 lines in total; a line-by-line
check against the step-2 baselines (same line count, equal after replacing every `res://` path token) shows every
change is only a path string a moved file prints. Image moves also rewrote their `.import` sidecars (the import
pass refreshed the imported-cache path); the uids did not change.

`resources/`, `objects/` and `scenes/` no longer exist, and neither do `assets/sprites/` and `assets/art/`.

### Where each thing went

| Was | Now |
|---|---|
| `resources/difficulty/standard.tres` | `content/difficulty/standard.tres` |
| `resources/rules/<id>.tres` (5 pages) | `content/rules/<id>/page.tres` |
| `resources/rules/rule_book.tres` | `content/rules/rule_book.tres` |
| `resources/enemies/<id>.tres` (7) | `content/enemies/<id>/enemy.tres` |
| `resources/{movement,attacks,decisions,visuals}/pawn_*` shared by several pawns | `content/enemies/_shared/{movement,attacks,decisions,visuals}/`, names kept |
| the knight's and the bishop's own movement, decision, attack, visual | `content/enemies/<id>/{movement,decision,unarmed_attack,visual}.tres` (the names of the `EnemyDefinition` exports they fill) |
| `pawn_charging.tres`, `pawn_backstep.tres` | `content/enemies/charging_pawn/movement.tres`, `content/enemies/backstep_pawn/movement.tres` |
| `resources/attacks/{wooden_sword,pencil_thrust}.tres` | `content/skills/<id>/<id>.tres` |
| `resources/weapons/{pencil_spear,ruler_blade}.tres` | `content/pickups/<id>/<id>.tres` |
| `resources/tiles/kingdom_tileset.tres`, `objects/world/kingdom_tilemap.tscn`, `assets/tiles/kingdom_tiles.svg` | `content/tilesets/kingdom/{tileset.tres,tilemap.tscn}`, `assets/tiles/kingdom/atlas.svg` |
| `resources/tiles/playground_tileset.tres`, `objects/world/playground_tilemap.tscn`, `assets/tiles/playground_tiles.svg` | `content/tilesets/playground/{tileset.tres,tilemap.tscn}`, `assets/tiles/playground/atlas.svg` |
| `scenes/rooms/<id>.tscn` (the six Stage 1 rooms) | `content/rooms/<id>/room.tscn` |
| `resources/world/world_graph.tres` | `content/world/world.tres` |
| `objects/actors/*.tscn` (5 scenes, not collapsed) | `presentation/views/actors/` |
| `scenes/rooms/first_encounter.tscn`, `resources/objectives/first_encounter_clear_all.tres` | `tests/fixtures/first_encounter.tscn`, `tests/fixtures/first_encounter/objective.tres` |
| `scenes/zones/the_kingdom.tscn`, `objects/world/kingdom_world_tilemap.tscn`, `resources/tiles/playground_world_tileset.tres`, `assets/tiles/playground_world_tiles.svg` | `tests/fixtures/the_kingdom.tscn`, `tests/fixtures/the_kingdom/{tilemap.tscn,tileset.tres,tiles.svg}` |
| `assets/art/pieces/{bed,bed_height}.png` | `assets/map_pieces/` |

The 12 tracked sprites of `assets/sprites/generated/`:

| Was | Now | Why there |
|---|---|---|
| `hero_pawn_unarmed.png` | `content/player/body.png` | what the player's view draws |
| `hero_pawn.png` | `content/player/icon.png` | the project icon (`config/icon` follows) |
| `black_pawn.png` | `content/enemies/pawn_recruit/body.png` | the base pawn; the four variants and both pawn scenes share it |
| `black_knight.png` | `content/enemies/knight_tracker/body.png` | the knight; the bishop's scene still draws it too (no art of its own yet) |
| `toy_sword.png` | `content/skills/wooden_sword/icon.png` | the sword's picture; the actor views use it as the default weapon sprite |
| `pencil_spear.png`, `ruler_blade.png` | `content/pickups/<id>/icon.png` | the weapons' pictures |
| `toy_weapon_pickup.png` | `content/pickups/toy_weapon/pickup.png` | the generic pickup sprite every weapon pickup shows |
| `facing_arrow.png`, `health_pip_full.png`, `health_pip_empty.png`, `warning_aura.png` | `assets/ui/actor_view/` | the overlay of every actor view; no one content item owns them |

### Decisions where the plan's table needed a call

| Case | Plan says | What was done | Why |
|---|---|---|---|
| Per-enemy sub-resources | "`content/enemies/<id>/`, shared ones in `_shared/`", "regrouped in M2" | the unique ones sit in the enemy's folder named for the `EnemyDefinition` export they fill (`movement.tres`, `decision.tres`, `unarmed_attack.tres`, `visual.tres`); the shared pawn ones keep their names under `_shared/<type>/` | a role name says what to open; the shared ones will be many (rook, queen, king movement) so they get a type folder |
| Player attack profiles | the plan turns Sword and Pencil into `content/skills/<id>/skill.tres` in M7a/M7b | `content/skills/<id>/<id>.tres`, file names kept | they are the data those skills grow from, `run_tests.gd` checks the name, and `skill.tres` is added beside them later. The class is still `AttackProfile` |
| Floor weapons | `content/pickups/<id>/pickup.tres` | `content/pickups/<id>/<id>.tres` plus `icon.png` | an `EnemyWeapon` is not the plan's pickup class; the folder is the id and a later milestone adds the role file |
| `content/audio/` | `sound_bank.tres`, `music_cues.tres` | not created | those files do not exist yet (the `SfxManager` registry is Inspector exports on its scene); the raw `.wav` files stay in `assets/sfx` and `assets/music` as in the tree |
| Tile kits | `content/tilesets/<district>/tileset.tres`, `assets/tiles/<district>/atlas.png` | `kingdom` (every Stage 1 room) and `playground` (the owner's first tile set, unused) as district folders; atlases keep their `.svg` and are named `atlas.svg`; the painted floor scene is `tilemap.tscn` beside the tile set | the kit keeps the name the code and generators use; `chess_rug` would be one `move_res.py` call when the art arrives. The owner's single-tile PNG direction fits: a tool assembles the atlas from `assets/tiles/<district>/<tile>.png` later and nothing here blocks it |
| `kingdom` zone in the graph | `the_kingdom.tscn` is a fixture, "excluded from `ContentDb`" | `content/world/world.tres` still lists the `kingdom` zone, now naming `tests/fixtures/the_kingdom.tscn`, so the H1 exit (`target_zone = kingdom`) and the bridge tests still work | the plan drops it from the graph when M5 ports the world-graph assertions; `test_content_references` lists the one reference as a documented exception |
| Fixture layout | `tests/fixtures/the_kingdom.tscn` flat | the scene is flat and its parts are in a folder of the same name (`tests/fixtures/the_kingdom/`) | one convention for both fixtures |
| Actor scenes | `presentation/views/` now, collapse in M2 | `presentation/views/actors/` | the interim subfolder keeps five 353-line copies apart from the real views, and M2 deletes one folder |
| `assets/art/pieces/` | "its planned home outside any ignored folder" (the plan names none) | `assets/map_pieces/` | tracked, flat, one file per thing, away from `assets/_generated/` (gitignored) and `assets/_source/` (`.gdignore`). The owner can overrule with one move |
| `rule_book.tres` | not named | `content/rules/rule_book.tres`, a file beside the id folders | folder names are ids; a file is not one, so a registry that lists folders skips it |

### Test and tool changes the moves needed

* `tests/support/paths.gd`: `room_scene()` builds `content/rooms/<id>/room.tscn`, `rooms_directory()` is
  `content/rooms` (its caller lists recursively), `actors_directory()` is `presentation/views/actors`,
  `enemy_definitions_directory()` is `content/enemies`, `kingdom_scene()` is the fixture, and `first_encounter_scene()`
  is new. The two format-string paths had to be edited by hand: `move_res.py` rewrites whole paths, not folder layouts.
* `tests/run_tests.gd`: the Book check listed the `.tres` files of one flat enemy folder; it now lists the enemy
  folders (skipping `_shared`) and loads each `enemy.tres`, and one label was added that asserts at least seven
  definitions are found. The Pencil Spear check looks for `pickups/pencil_spear/icon.png` instead of
  `pencil_spear.png`; its label is unchanged.
* The harness fixture that proves a stale scene path fails used the removed `scenes/` folder as its fake path; it uses
  `content/a_scene_that_was_moved.tscn` now (same check, same label).
* Comments and prose that named a moved folder without the `res://` prefix (the tilemap tools, `zone_exit_marker.gd`,
  `README.md`, `THIRD_PARTY_NOTICES.md`, `tools/README.md`, `.gitignore`, the three room-generator docs) were fixed by
  hand. Not touched: `docs/OWNER_GUIDE.md`, `docs/ARCHITECTURE.md`, `docs/coding-standards.md`, `AGENTS.md`,
  `README.md`'s folder list, `.claude/commands/*` (the docs step), and the history files.
* Guards now enforcing: `test_sidecars_tracked` (96 `.gd`, 35 imported assets, 0 missing, 0 orphans),
  `test_dependency_edges` (everything except an explicit `UNDECIDED_EDGES` list, below),
  and three new ones: `test_content_has_no_gd` (zero `.gd`, at least 40 files, folder = id), `test_fixtures_present`
  (ledger requirement 116) and `test_content_references` (the `content` row of 13.1). `test_no_old_res_paths` is the
  M1b grep acceptance as a test. All were mutation-checked with a temporary violating file.

### Edges and references still undecided (report-only, printed on every run)

Each is an exact entry in `UNDECIDED_EDGES` of `tests/architecture/test_dependency_edges.gd` or `UNDECIDED_REFERENCES`
of `tests/architecture/test_content_references.gd`, with the question for the owner next to it. An entry nothing uses
any more fails the suite, so a fixed one has to be deleted. `allowed_edges.txt` is not frozen: that is the owner's.

| Edge | Question |
|---|---|
| `authoring/ecs_boot.gd`, `entity_component.gd` -> `ActorView` (presentation) | allow authoring -> presentation/views for `ActorView`, or give the contract a base class in schema |
| `authoring/markers/pickup_spawn_point.gd` -> `WeaponPickup` | allow it, or let the marker name a `PackedScene` export |
| `presentation/board/prototype_board.gd` -> `EcsComponents`, `EcsWorld` | feed the overlay from the `HudSnapshot` and events (M3a/M3b), or allow this one reader |
| the six rooms -> `presentation/board/grid_lines_overlay.gd` | allow `presentation/board/` for room overlays, or let the game root add the overlay (M3b) |

Documented exceptions (decided): `view_sync_system.gd -> ActorView` (plan 13.1) and `content/world/world.tres` ->
`tests/fixtures/the_kingdom.tscn` (until M5).

### Not done in step 3

* `CLAUDE.md` amendments and the prose docs (listed in step 2 and above) still describe the old layout.
* `tools/seed_placeholders.gd`, `content/_placeholders.json` and `content/README.md`: the T1/T2 backgrounds are still
  named by uid and path from `assets/_generated/rooms/`; seeding them into `content/rooms/<id>/background.png` is the
  placeholder step.
* `ContentDb`, `actor_view_base.tscn` and the thin inherited actor scenes are M2; `content/audio/`, `content/feel/`,
  `content/progression/` and the other plan folders appear with the milestones that need them.
* `task_plan.md` M1b row: the integrator adds it once the four steps are merged, as in steps 1 and 2.
