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
