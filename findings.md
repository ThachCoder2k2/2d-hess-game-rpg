# Findings

## Repository

- Remote repository cloned successfully on June 19, 2026.
- Repository was empty.
- Bundled Godot executable is available at `../Godot.app/Contents/MacOS/Godot`.
- Installed version is Godot 4.6.3 stable.

## Approved Design

- 2D top-down pixel art inspired by Enter the Gungeon's readability and animation energy.
- 640x360 internal canvas.
- 32x32 logical tiles.
- Player moves one cardinal cell per input.
- Sword damages one adjacent facing cell.
- Vertical slice eventually includes Black Pawn AI, Knight AI, Place Block, and Knight Captain.

## Architecture

- `GridWorld` owns logical cells and reservations.
- Actors request moves; they do not infer collision from sprite overlap.
- Combat captures a target cell and resolves once on the impact frame.
- Presentation can change independently from cell logic.

## Playtest Feedback

- Current 0.18-second stepping feels right.
- Held directional movement should remain enabled.
- Sword response feels right.
- The player needs `Shift + direction` turning without movement.
- Basic attack range can remain one cell, while weapons and skills provide future range variation.
- Approved slice loadout: Wooden Sword plus Pencil Thrust.

## AI Research

- Into the Breach demonstrates that visible enemy intentions turn combat into response planning and can increase battle pace.
- Enter the Gungeon's developers handcrafted and individually playtested rooms, treating layout and environmental interaction as part of combat design.
- Utility AI is appropriate for scoring a small number of legal chess actions.
- A finite-state machine should execute the chosen action so timing and telegraphs remain deterministic.
- A room-level attack-token system is needed because independent enemy brains can accidentally create unfair simultaneous attacks.
- Enemies should react to the hero's committed or reserved cell, never buffered input.
- Machine learning and NavMesh pathfinding do not fit this deterministic grid game.

## Enemy Freedom Revision

- All common enemies move freely in four cardinal directions.
- Chess identity moves from locomotion into the unarmed attack pattern.
- An equipped weapon replaces the chess-shaped attack until dropped or changed.
- Encounters support both pre-armed enemies and weapons collected during combat.
- The first mixed encounter includes free-moving Pawns and a Knight.

## Enemy Behavior Research

- Enemy roles should force distinct player behaviors and target-priority decisions.
- Clear tells are essential in avoidance combat; stronger attacks need stronger tells.
- Group AI should regulate attack frequency, near/far pressure, and off-screen attacks.
- Regular enemies need reusable AI that works in varied rooms; bosses should be authored for a specific arena.
- Weapons can replace attack geometry while piece identity continues to shape positioning and pickup preference.
- Bosses should test learned mechanics through structured escalation rather than inflated health.

## Implementation Roadmap Audit

- `FreeEnemy` currently owns sensing, utility scoring, movement, equipment, telegraph timing, attack resolution, and damage response.
- Pawn and Knight already share enough behavior to support an incremental extraction into context, intent, pattern, and archetype data.
- `EncounterDirector` currently manages one attack owner but does not track commitment spacing, role groups, destination reservations, pickup reservations, or threat validation.
- `PrototypeBoard` already renders source-keyed telegraphs and can become the presentation consumer for a shared threat map.
- The current test suite is lightweight and deterministic, making it suitable for protecting behavior during the first refactor.
- Direction-specific action memory creates variation without making enemies abandon sustained pursuit.
- Movement recovery must be shorter than attack recovery; sharing one recovery value made enemies feel passive at room scale.
- Legal movement options must be captured regardless of whether the hero is moving, while only the target cell changes to the visible reservation.
- Debug intent paths must redraw while actors tween; drawing only when an intent changes leaves the path visually detached.
- Enemy-local labels are the simplest way to keep behavior text anchored through movement without duplicating world-to-screen tracking.
- Direction penalties alone create orbiting because they reward changing direction without measuring progress.
- A player standing on a weapon made that pickup unreachable while it remained the enemy's highest-priority goal.
- Stable pursuit needs reachable goals, path-distance progress, short goal commitment, and recent-cell loop detection together.
- No gameplay crash reproduced across two 60-second logic runs and a 20-second real-renderer run; the only native crash observed remains Godot's unsupported headless movie capture path.
- A damage event can occur during startup, reload, or teardown when the actor still exists but `get_tree()` is unavailable.
- Async damage timers must capture a validated tree before awaiting and re-check tree membership after resuming.
- The forced attack renderer test is the reliable regression path for attack-only crashes that normal idle captures may never reach.

## Editor-First Architecture

- The current `main.gd` constructs the room, hero, enemies, weapons, and blockers at runtime, so most composition is not editable before play.
- Current Pawn and Knight differences are split between subclass scripts and partially configurable Resources.
- Godot scene composition plus typed Resources fits the desired workflow better than a strict ECS framework.
- A compatibility adapter allows scene ownership to migrate before behavior responsibilities are extracted.
- The safest first batch is data-only: expose current values in `.tres` assets without changing runtime behavior.
- `FreeEnemy` can consume typed definitions through a compatibility layer while legacy Pawn/Knight visuals remain unchanged.
- Shared `.tres` assets should be treated as immutable at runtime; weapon factories return deep duplicates for per-instance safety.
- Validation methods on nested Resources catch missing movement, decision, attack, visual, and difficulty references before component extraction.
- A thin `EnemyActor` host can expose real component nodes now while delegating to `FreeEnemy` until each responsibility is safely extracted.
- Component adapters need explicit host injection; relying on broad Scene Tree searches would make them difficult to reuse and test.
- Resolving child references inside `_configure_components()` keeps scene instances testable before and after normal `_ready()` dispatch.
- Movement can be extracted safely by overriding only `EnemyActor` entry points while legacy Pawn/Knight continue using `GridActor` directly.
- During migration, the movement component mirrors cell, facing, and moving state onto the host because the legacy brain still consumes those fields.
- A timed Scene Tree test is necessary for tween ownership; immediate unit checks cannot prove completion, occupancy transfer, or reservation cleanup.
- Equipment validation must happen before `WeaponPickup.take()` or an incompatible item disappears even though it was rejected.
- Runtime weapon Resources must be duplicated per actor while the source `.tres` assets remain immutable.
- During migration, `EquipmentComponent` mirrors its weapon onto the host because legacy drawing and decision code still read `weapon` directly.

## Editor-First Full Game Planning

- The production direction is now editor-first rather than script-first: code should define reusable behaviors, while actual game content should be authored as Godot scenes, child nodes, Resources, AnimationPlayers, VFX, and SFX.
- The existing prototype history remains useful, but the long-range roadmap now needs a second track for full game production from Godot Editor.
- The best next implementation phase is an editor-first encounter system that moves the current hardcoded first room into a room scene with spawn point nodes and Inspector-configured enemy/pickup data.
- The planned full game phases are: editor foundation, encounter system, player combat core, enemy system, combat feedback, room/world structure, narrative layer, art direction pass, boss production, vertical slice, full short game, and polish/release.
- The immediate editor-first acceptance gate is preserving the current playable encounter while making enemy spawns, pickup spawns, blockers, room messages, and win conditions editable from Godot.

## AI Workflow Rules

- `AGENTS.md` now exists at the project root as the first-read guide for future AI sessions.
- It records the editor-first direction, current E2 priority, planning-file workflow, Godot-native implementation rules, combat readability rules, verification commands, and git boundaries.
- Keeping these rules in the repo should reduce future drift back into script-only work and make handoffs after context compaction safer.
- The workflow now explicitly separates AI-owned implementation from human-owned editor review: room layout, play feel, enemy threat feel, art/audio taste, narrative tone, and exported-build approval.
- Full game completion is tracked through gates from editor foundation through release polish, and every gate should end with an editor-reviewable playable scene or build.

## Editor-First Encounter System

- `RoomEncounter` can own blockers, pickup spawn markers, enemy spawn markers, room messages, and enemy signal wiring while `main.gd` remains the compatibility host for world, hero, board, director, HUD, restart, and result flow.
- `EnemySpawnPoint` and `PickupSpawnPoint` expose grid cell and data Resources in the Inspector, making the first encounter editable without changing scripts.
- The first room now exists as `scenes/rooms/first_encounter.tscn`, with the previous hardcoded blockers, two weapons, two Pawns, and one Knight represented as scene data.
- New scripts may not be available as global classes during headless script loading before editor import; cross-file references to brand-new scene classes should use dynamic `Node` calls or run editor import before strict type references.
- E2 is not finished until room win conditions and more main-scene/HUD composition are also editor-owned, but the first encounter content is now out of hardcoded setup.
- `RoomObjective` Resources now own start text, clear text, defeat text, and win-condition checks; this keeps narrative/objective tuning in the Inspector instead of `main.gd`.
- `RoomEncounter` emits `room_completed` after the objective succeeds, so the main scene only handles compatibility UI/result flow and no longer decides whether the room has been cleared.
- Directly inferring the type of a fresh script-loaded Resource can fail in headless tests before editor import; dynamic `Resource.call()` matches the current migration-safe pattern.
- E2 technical wiring is ready for human editor review: enemy spawns, pickups, blockers, objective text, defeat text, and win condition are all editable, but room feel still needs in-editor approval.

## Editor-Owned Main Scene Foundation

- `scenes/main.tscn` now exposes the main playable composition in the Godot editor: GridWorld, EncounterDirector, PrototypeBoard, PawnHero, FirstEncounter, and HUD are scene children.
- `main.gd` should act as a coordinator: resolve exported NodePath children, connect signals, call setup, and only instantiate scene fallbacks when tests create the script directly.
- `scenes/ui/hud.tscn` owns the HUD controls, while `GameHud` owns HUD formatting and presentation updates.
- Moving HUD into a `CanvasLayer` scene makes the editor tree clearer, but Godot headless `--quit-after` currently reports CanvasLayer teardown RID warnings even though the run exits successfully.
- Tests that need `_ready()` bindings must wait at least one frame; immediate `SceneTree._init` checks can only prove scene ownership, not ready-time binding.
- Enemy and pickup spawns can now be made editor-owned by assigning PackedScene templates on the spawn marker instead of branching on script classes.
- `black_pawn.tscn`, `knight_enemy.tscn`, and `weapon_pickup.tscn` are the current gameplay templates for the first encounter.
- `PawnHero` still has safe code defaults, but the playable `player.tscn` now owns Wooden Sword and Pencil Thrust as `.tres` attack Resources.
- `PrototypeBoard` remains procedurally drawn for speed, but its colors are now exported Inspector values so board theme tuning no longer requires code edits.
- Remaining editor ownership work is mostly presentation: replace `_draw()` placeholder actor/weapon/board visuals with child nodes, Sprite2D/AnimationPlayer, VFX scenes, and eventually audio nodes.
- Player, Black Pawn, Knight, base enemy, and weapon pickup presentation now route through scene-owned `Visual` child instances; gameplay scripts sync state into those nodes instead of drawing actor/pickup bodies directly.
- During editor-first migration, old scripts should call newly added scene/visual classes dynamically until a headless editor import has registered their global class names.
