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

Amended 2026-10-12: the locomotion rule below was **superseded**; the attack and weapon
rules still hold. Source of truth: `docs/game-base-plan.md` D-08 (the files win over the
June note).

- June 2026 revision, now superseded for locomotion: "All common enemies move freely in
  four cardinal directions. Chess identity moves from locomotion into the unarmed attack
  pattern."
- As built (checked against the files 2026-10-12): every piece moves by its **own chess
  law**, one move per `step_duration`, and the move set is data. `MovementConfig.
  allowed_directions` lists the offsets of one move: the Pawn family the four cardinal
  cells (the script default; `pawn_charging.tres` uses two-cell cardinal offsets), the
  Bishop one diagonal cell (`resources/movement/bishop_diagonal.tres`), the Knight the
  eight L offsets, landing on a free cell (`resources/movement/knight_standard.tres`).
  Rook, Queen and King movement files arrive with their milestones.
- Still an open owner question (`docs/where-we-are.md` decision 7, plan O-8): chess-law
  moves or one cardinal step for all. The default taken is chess-law, and flipping it is
  an edit to the `movement` `.tres` files only.
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
- The playable Pawn and Knight scene templates now use `EnemyActor` with component children and assigned `EnemyDefinition` Resources; their old subclass scripts are no longer the room-spawn path.
- Runtime UI should label enemies from definition data (`display_name`, `id`, or role) instead of checking for `BlackPawn`/`KnightEnemy` classes, because scene variants can share one generic script.
- Knight flanker positioning logic can live on `EnemyActor` by reading the archetype role, preserving the threat behavior without a Knight-specific gameplay script.
- `HealthComponent` now owns `EnemyActor` damage, hurt feedback values, attack-token cleanup, grid unregistering, defeat signal emission, and queue-free timing.
- `objects/components/health_component.tscn` owns an `AnimationPlayer` with `hurt` and `defeat` animations targeting the actor root, so hit/defeat timing can be tuned in the editor.
- `FreeEnemy.take_damage()` remains as a legacy fallback for direct subclass tests until those compatibility classes are retired.

## Editor-Owned Room Art

- A room can be technically editable while still looking script-generated if its visible battlefield is drawn only by a runtime overlay.
- `first_encounter.tscn` now needs to be judged by its actual scene tree: `RoomArt/TileMap`, `RoomArt/GridLines`, `RoomArt/Boundary`, `RoomArt/SetDressing`, gameplay markers, spawn marker previews, and pickup previews should be visible before pressing Play.
- `PrototypeBoard` is better treated as a combat overlay for danger cells, hit flashes, and debug paths. When a room owns visible art, `main.tscn` should disable the board base layer so the authored room surface is what the player and editor see.
- Spawn marker preview children solve the editor readability problem for enemies and pickups, but they must hide at runtime so the real gameplay instances remain the only active actors/items.
- The next art migration should replace remaining `Polygon2D` set dressing with proper pixel sprites while keeping the same editor-owned room structure.
- Gameplay-affecting editor objects need to be marker nodes, not parallel visual art plus hidden arrays. `HeroStart`, `Blocker_*`, pickup markers, and enemy markers now expose draggable/snap-to-grid `grid_cell` fields that runtime setup reads.
- Blocker collision now comes from `BlockerMarker` nodes when present; `RoomEncounter.blocked_cells` remains only as a fallback for older rooms.
- `docs/design/room-authoring-guide.md` is the human-facing guide for editing the first encounter without touching scripts.
- The first encounter floor is now `RoomArt/TileMap`, a `TileMapLayer` backed by `resources/tiles/playground_tileset.tres` and `assets/tiles/playground_tiles.svg`. This keeps terrain editing in Godot's TileMap tools instead of a large list of Polygon2D tile nodes.

## Scene/Object Folder Ownership

- Keeping every editable template under `scenes/` made the project feel like it had too many playable scenes, even though many files were actor, component, marker, visual, or helper prefabs.
- The cleaner Godot workflow is `scenes/` for entry scenes, authored rooms, and UI, with reusable `.tscn` object templates under `objects/`.
- Enemies, pickups, markers, components, visuals, the combat director, the board overlay, and the TileMap floor template remain editor-owned `.tscn` files; they are now treated as objects instead of main scenes.
- This split preserves the current editor-first workflow while making it easier for the human owner to find the room scene and modify gameplay objects deliberately.

## Sprite-Based Visual Objects

- The old visual scripts made objects feel empty in the editor because actor and pickup bodies were painted through `_draw()` at runtime.
- Hero, Pawn, Knight, and weapon pickup visuals are now actual `Sprite2D` nodes backed by PNG assets, so opening object visual scenes in Godot shows real editable sprites.
- Animation belongs in each visual scene's `AnimationPlayer`; scripts should only choose state, texture, modulate, facing, and visibility.
- The first generated sprites are placeholder-quality production scaffolds, not final art. They are good enough to prove the editor workflow and can be replaced later without rewriting gameplay logic.
- Main-scene marker positions can be edited independently, but enemy and pickup spawn markers must keep their `PackedScene` template references so runtime uses sprite object scenes instead of fallback constructors.

## Richer Visual Animations

- Locomotion belongs in its own `step` AnimationPlayer clip, chosen by the sync scripts, not in a procedural bob. `piece_visual.gd` plays `step` while `is_moving` and falls back to `idle` when a visual lacks the clip, so a missing clip degrades quietly instead of freezing on a stale animation.
- Animation layers must not fight: `MotionRoot.position` is the procedural recoil/bump offset written every sync frame, while `MotionRoot/SpriteRoot` is the AnimationPlayer's home for bob, hop, squash, lunge, and shake. Keeping recoil on `MotionRoot` and clips on `SpriteRoot` lets both run without stomping each other.
- When adding a scale track above a child sprite that is already scaled (pickup `SpriteRoot` over a `0.42` `PickupSprite`), animate the parent around `1.0`; keying it to the child's absolute scale compounds and shrinks the object.
- `load_steps` in a `.tscn`/`.tres` header is a load-progress hint, not a correctness requirement in Godot 4.6; the editor recomputes it on save and even drops it, so hand-adding sub-resources without updating `load_steps` still imports correctly.
- `[editable path="Visual"]` on an actor prefab turns on Editable Children for the instanced visual, exposing its `Sprite2D`/`AnimationPlayer` subtree in the actor's scene dock without duplicating nodes, which improves editor readability of what each prefab actually shows.

## Editor-First Refactor

- The expandability blockers were not the data model (enemies/movement/decisions/attacks/weapons were already typed `.tres`) but three script-only leftovers: attack geometry lived in `AttackPattern` subclasses, visual textures were chosen by id-string branches, and short piece names were guessed from the display name. Turning each into a Resource field or offset list removes the need to touch GDScript when adding content.
- A single base `AttackPattern` with `cell_offsets` + `uses_facing` (facing-relative `(forward, right)` pairs) + `clip_to_board` reproduces both the pawn diagonal and the knight L exactly, so pattern subclasses were pure ceremony. Facing-relative offsets rotate correctly via `origin + facing*off.x + side*off.y` where `side = (-facing.y, facing.x)`.
- Code fallbacks that re-declare Resource values (`_ensure_attack_profiles` stats, `main.gd`'s HUD label formatting) are a maintenance trap: they duplicate the source of truth and only exist for bare-script tests. Replacing them with `load(".tres")` fallbacks or routing through the editor-owned scene keeps one source of truth while still surviving tests.
- Tests that read a coordinator's mirror of scene state (e.g. `game.get("encounter_label")`) lock duplication in place. Pointing the test at the owning scene node (`hud.get_node("EncounterLabel")`) let `main.gd` drop the mirror entirely.
- Retiring `BlackPawn`/`KnightEnemy` only required migrating test call sites to instantiate the scene variants (`black_pawn.tscn`/`knight_enemy.tscn` on the generic `EnemyActor`), because those variants already carried the definition + components. `TrainingDummy` was fully unreferenced.
- Godot errors "Trying to assign invalid previously freed instance" when a `for x: TypedNode in dict` loop assigns a freed object key to the typed loop var — the assignment fails before any `is_instance_valid` guard runs. Iterate `dict.keys()` untyped and validate inside the loop. This surfaced only once scene-variant enemies (with their own teardown timing) replaced bare-script test enemies.
- Enemy AI behavior is already editor-tunable through `DecisionConfig`/archetype `.tres` scoring weights; the remaining `FreeEnemy` decision code is plumbing, not content. Relocating it into `EnemyBrainComponent` would be structural churn with behavior risk and no new editor capability, so it was deferred rather than done reflexively.

## AI Editor Surface

- The AI *component* (`EnemyBrainComponent`) and the AI *data* (`DecisionConfig`) were disconnected: the component was a hollow node with no Inspector fields, so it read like "the AI" in the editor but exposed nothing, while the actual knobs sat on a `.tres` reached via `EnemyDefinition.decision`. Giving the component an optional `DecisionConfig` export makes the AI node the thing a designer clicks, and still allows a shared definition profile as the default.
- `DecisionConfig` and `EnemyArchetype` were near-duplicates (same 8 score fields) with a per-enemy copy step, and the split was inconsistent (some scores read through the archetype, `recent_cell_penalty`/`path_step_bonus` read straight off the config). Collapsing to a single `DecisionConfig` that the scoring reads directly removed a class, the copy, and the inconsistency. Shared `DecisionConfig` is safe because scoring only reads it (no runtime writes; the old `archetype.role = definition.role` write was eliminated by authoring `role_policy` in the `.tres`).
- The only genuinely code-locked AI behavior was role positioning: a hardcoded `role=="flanker"` branch adding fixed +30/+12 bonuses. Turning those into `flank_bonus`/`axis_change_bonus` fields (0 for a skirmisher) moved the whole positioning personality into data and let the `EnemyActor` override be deleted — new chess pieces are now pure `.tres`.
- Deterministic AI unit tests (identical `EnemyContext` → identical intent type/destination) are the right guard for this kind of scoring refactor: they prove the new data path produces byte-identical decisions, which a timed sim alone cannot.

## Data Pipeline Validation and Component Audit

- The Bishop proved the refactor's goal: a full new enemy (unique movement, attack geometry, and AI personality) shipped as five `.tres` files plus one scene wiring the generic `EnemyActor`, with zero new GDScript. `MovementConfig.allowed_directions` gives diagonal locomotion, an absolute-offset `AttackPattern` with `clip_to_board` gives diagonal beams, and a `DecisionConfig` with `flank_bonus` gives sniper positioning — all data.
- Placeholder art is a legitimate scaffold: pointing a new `VisualDefinition.visual_scene` at an existing visual (knight) lets a new enemy be built and tested before its sprite exists; the art pass swaps the scene later without touching gameplay.
- Component audit method that works: grep every component's public methods for callers. `AttackComponent` and `EnemyDebugComponent` had zero callers — they were scaffolds created during the base-scene phase whose responsibilities were never moved out of `FreeEnemy`, so they sat as inert nodes on every enemy. A component with no called methods is dead weight even if it "binds to the host" in tests.
- Keep the component set honest: after removal, every enemy component does real work (movement, AI data, health, equipment). `EnemyBrainComponent` is worth keeping even though its accessor methods were dead, because its `decision` export is the editor AI surface — the value was the exported data, not the code.
- The four room markers each re-implemented identical grid-snap authoring (~30 lines apiece). A `@tool` base (`GridMarker`) with a `_ready_marker()` hook absorbs the shared exports, `_process` snapping, and cell/position math; subclasses keep only their data + `_draw`. Editor-tool base classes work fine as long as each subclass re-declares `@tool` (it does not inherit). Per-subclass export defaults that differ from the base (hero start's `(3,7)`) are set on the prefab `.tscn`, not re-declared, avoiding export shadowing.

## Mechanic Audit

- An 1800-frame headless run of the live encounter produced zero script errors/warnings (only the known headless-capture RID leaks and CanvasLayer teardown notes). The combat mechanics (grid occupancy, movement reservations, the shared attack token, telegraph/resolve, invulnerability) are logically sound and now well-covered.
- The core dodge mechanic (Into-the-Breach style) is verified: `_resolve_attack` damages only if `target.current_cell in locked_attack_cells`, so stepping out of the telegraphed cells before the strike lands avoids all damage and the token is still released. Locked in with a test.
- Latent correctness gap found by inspection and fixed: `GridWorld.register_actor` checked `occupied_cells` but not `reservations`. An actor spawned onto a cell another actor was mid-move into would be silently overwritten by that actor's `finish_move` (two actors, one cell). It cannot trigger today because all spawns happen at room setup before any reservations exist, but registration now rejects reserved cells too. Movement flow already guarded the reverse (you cannot reserve/step onto an occupied or reserved cell).

## Canonical Actor Structure

- Actor presentation lives on the actor: Sprite2D children + a sibling `AnimationPlayer`, driven by typed `@onready` refs in the actor script. Wrapper "Visual" scenes synced by polling (`visual.call("sync_from_x", self)`) trade typed access for indirection and hide the sprite tree from the scene dock — flattened away for player + enemies (phase 70). Pickups still use a small `Visual` child; that's fine at their complexity.
- Keep two transform layers when code and animations both move sprites: procedural offsets on `MotionRoot`, animation tracks on `SpriteRoot`. One node for both = the tween/AnimationPlayer overwrite each other.
- Sprite choices belong to data: `EnemyWeapon.texture` / `AttackProfile.texture` in the `.tres` beat id/name string lookups in code — a new weapon needs zero script changes to look right.

## ECS Doctrine (post-flip)

- The runtime is entities (ids) + component data + systems; the ONLY node-touching system is ViewSyncSystem. If a change needs a new decision, it goes in a system; new state goes in a component class (pure data); new content goes in `.tres` + a view scene. `docs/ecs-conversion-plan.md` is the map.
- Scenes remain the authoring surface: parked ActorViews are spawn markers + puppets, so drag-to-place, Inspector overrides (the armed pawn = black_pawn view + pawn_armed.tres), and painted solid walls all survived the conversion intact.
- Presentation bridges consume the event queue, never poke the simulation; the simulation never calls presentation. Events carry everything the bridge needs (the intent_changed event carries the whole EnemyIntent so F3 debug works without the board reading AI internals).
- SceneTree-script tests: `_ready` does not run during `_init` — full-scene boots need `call_deferred` + `await process_frame` (re-learned twice now; it presents as Nil lookups or a hang when a failed assert skips `quit()`).

- .tscn text surgery rules learned twice: (1) a SubResource must be DEFINED above any block that references it — the parser is single-pass; (2) never batch-edit scenes while the Godot editor is open — it resaves buffers (adding uid/unique_id attrs, reordering blocks, dropping default-valued properties like AnimationTree.active), which both invalidates text anchors and can clobber disk edits. Close the editor first.

- A one-shot boot pose is graph-owned, not code-owned: retarget the StateMachine's `Start` edge at the new state and give that state an AtEnd transition home. The view is instantiated once, so the clip plays exactly once at boot with zero script involvement — no ViewSync edge, no new condition, no input lock. Asserting only "the clip exists" is not enough; also assert the `Start` edge points at it, or a clip nothing enters passes CI.
- Rotating a whole actor sprite works because `SpriteRoot`'s origin sits at the pawn's feet — a −90° rotation lays the piece on the ground with its base still on the cell. Rotation lives on `SpriteRoot` like every other animation track (`MotionRoot` is ViewSync's every-tick territory), so `Animation_reset` needs a rotation track too or the editor leaves the pawn face-down after preview.

## World Painting

- Decorative solids must be painted over rock ONLY. The kingdom's curtain wall, keep ring, library ring and moat never overwrite an open cell, so no amount of wall-drawing can sever the world; road crossings become gatehouses for free. Painting walls first and carving doors after would need every doorway kept in sync with every road by hand.
- Monotony in a generated map has two independent sources: one floor tile for all open cells, and one wall tile for all closed cells. Fixing only the floors leaves the map looking identical, because most of a 72×40 board is rock. District-skinned rock (bounded by a depth from open ground) plus a hash-picked variant mix fixes the second half.
- Generated variation must be deterministic (`_cell_hash` = coordinate scramble, not `randi()`). The tilemap is a committed `.tscn` — a random build makes every regeneration a diff and makes a bug unreproducible.

## Piece Sprite Generation

- The piece art is a generator, not a folder of hand-painted PNGs: `tools/generate_chess_sprites.gd` holds the shape tables, and the PNGs are its output. Editing a silhouette means editing a radius in the row table and re-running — a rule change (say, a new special-power band) can never drift between the art and the design.
- Three rules carry the whole cartoon read, and all three are cheap to break by accident: (1) shading is three FLAT bands, so any interpolation or fourth stop instantly reads as 3D render, not pixel art; (2) the outline dilates OUTWARD into one block of padding, so it never eats the silhouette — this is why frames are `width + 2` and not `width`; (3) a piece's foot sits on the CELL CENTRE, so `anchor_row = height - 3` is the row ViewSync must align, not the frame's bottom.
- A piece's head must never be its widest part and the neck must pinch, or the silhouette reads as a baby. The knight is the deliberate exception — its head is the widest thing on the board — and it only survives that because its shape is not authored at all.
- TRACE, DO NOT GUESS. Four hand-authored knight silhouettes were rejected in a row, each one worse than the last, because each was typed from memory of a reference image. What shipped is `tools/trace_knight_glyph.py`: render U+265E from Apple Symbols at 900pt, crop to bbox, scale uniformly to the sprite's row count, take each row's leftmost and rightmost filled block. Min/max per row spans straight across interior holes, so no hole-filling and no scipy is needed. Font choice matters — Apple Symbols cuts a clean single-eared head, Arial Unicode adds mane strands, Times New Roman has no glyph and renders tofu. When a shape is a real, well-known object, measure one; iterating on remembered proportions is a loop, not a process.
- A traced span table sets its own width. The knight's traced neck is 14 blocks in x 6..19, which forced the pedestal from width 22 to 24 — the lathe's `centre = width / 2.0` has to reach the head, or the neck floats over a narrower base.
- Material bands are palette swaps on lathe rows, never drawn decals. A collar, a gold belt or the double-step's red band is one row entry — so a new enemy variant is a row table, no new art asset and no new script.
- GDScript typing gotcha hit here: indexing an untyped `Array` yields Variant, so `var x := arr[i] + 1` fails to parse with "Cannot infer the type". Extract through an explicitly typed local (`var start: int = arr[i]`) before doing float math on it.

## Test And Tooling Facts (M1a, 2026-10-12)

- The audio bus layout was broken until M1a: bus 0 was defined as `SFX` with no `Master`, so at runtime
  `get_bus_index(&"SFX")` was -1 and every actor `AudioPlayer` and the `SfxManager` pool silently played on
  Master. `tests/audio/test_audio_buses.gd` now fails if any audio player names a bus that does not exist.
- A script error in the `_init()` of a `SceneTree` suite leaves the Godot process running forever, and a
  `Parse Error` still exits 0. Only a watchdog plus the runner's `SCRIPT ERROR` / `Parse Error` scan and its
  "verdict line required" rule catch both. Suites extending `UnboundTest` get the watchdog for free.
- GDScript does not call a base class `_init()` once the subclass defines its own, so `UnboundTest` arms its
  watchdog from `_initialize()`; a suite must not define `_initialize()` itself.
- The headless `--editor --quit` import does not parse-check a script that no suite loads, so a broken
  `class_name` script in an untested file prints nothing (checked: a planted type error and a stale preload
  path both passed the import pass silently). `tests/architecture/test_all_scripts_load.gd` now `load()`s
  every `.gd` outside `tests/fixtures/`, so such a script fails the run before M1b moves anything.
- A real-renderer boot works in the agent sandbox (`--quit-after 180`, Metal on Apple silicon, about 7 s) but
  the game opens fullscreen, so each run flashes the owner's screen. Exact command: `tools/README.md`.
- `main.gd` today: the Book of House Rules blocks keys but does not pause the world; a zone trip that ends
  under an open Book turns control back on while the Book stays visible (fix with the M4 pause work); the
  health carry is a snapshot taken when the trip starts, so a hit during the fade-out is lost; the zone node is
  named after the room (`T2_FallenSwordTile`), not `CurrentZone`. All pinned by `tests/bridge/`.
- Content defects found by the bridge suites (not fixed in M1a): T2's `Exit_To_T1` at cell (0,5) sits on a
  solid wall tile, so the hero cannot walk back to T1 (ledger req 110 "backtracking works" is only true through
  `_travel_to`); T4's `PencilSpearPickup` at (7,6) is on a solid cell, so a pawn cannot walk to the spear.
- Dependency edges the plan's 13.1 starting table does not allow today (report only): `EcsBoot`,
  `EntityComponent` and `PickupSpawnPoint` name `ActorView` / `WeaponPickup`, and `PrototypeBoard` reads
  `EcsWorld` and `EcsComponents`. Decide what to freeze in `tests/architecture/allowed_edges.txt` before M1b
  turns the guard on.
- Folder moves must go through `tools/move_res.py`, after `tools/stamp_uids.gd`: a bare `git mv` of
  `resources/enemies` turns three suites red; with stamped uids a bare move of scene-referenced resources stays
  green, which is why M1b stamps first. Never use `ResourceSaver` to "fix" uids: it adds none and drops the
  header uid of `scenes/main.tscn`.

## Uid And Generated-Art Facts (M1b step 1, 2026-10-12)

- The tree is stamped: every scene and resource header has a `uid=` and every `ext_resource` line names its
  target by uid as well as path. `test_no_path_only_ext_resource` is ENFORCING, so a scene saved without uids
  fails the suite. `tools/stamp_uids.gd --check` is the same measurement from the command line.
- `ResourceSaver.save()` on an existing `.tscn`/`.tres` drops the header uid and every `ext_resource` uid
  (measured on `kingdom_tilemap.tscn`, which seven room scenes name by uid) and writes a new random node
  `unique_id`. Stamping afterwards would invent a different header uid, so tools that save scenes go through
  `tools/save_keeping_uids.gd` (restores the old header uid with `ResourceSaver.set_uid()`, then runs the
  stamper last). `FLAG_CHANGE_PATH` does not set `resource_path` in 4.6; use `take_over_path()`.
- All generator output lives under `assets/_generated/` (gitignored): `chess/ tiles/ maps/ rooms/
  piece_templates/`. The 12 PNGs directly in `assets/sprites/generated/` and `assets/art/pieces/` are tracked
  source art and no tool writes them.
- Godot 4.6.3 gives a freshly imported file a uid derived from the project name and its path (deleting
  `.godot/` and `assets/_generated/` and re-bootstrapping twice gave identical uids; a fresh clone matches the
  uids stamped in the T1/T2 room scenes). Moving generated output, or renaming the project, changes those uids:
  re-point the two scene lines (`stamp_uids.gd --check` lists the mismatch as `STALE`). An unmatched uid is only
  a warning (`ext_resource, invalid UID ... using text path instead`), never an error.
- Cosmetic, not fixed: the bootstrap warm-up import pass prints that same warning for the two room PNGs on a
  fresh clone, because the art does not exist yet; the pass after the generators is clean.

## Code Layout Facts (M1b step 2, 2026-10-12)

- The code lives in `schema/`, `ecs/`, `authoring/`, `presentation/`, `shell/` (plan 13.2); `scripts/` does not
  exist. A script's layer is its top folder, and `test_dependency_edges.gd` fails on a `.gd` outside them.
  `docs/migration-notes.md` has the old-to-new table and every place the plan's table needed a judgement call;
  `tools/move_res_log.tsv` is the exact move list.
- `EnemyIntent` (a `RefCounted`) is in `schema/entity/` on purpose: the system builds it, the board draws it and
  the bridge forwards it in an event, so `schema` is the only layer all three may name. Putting it in
  `ecs/systems/decide/` added a new presentation to ecs/systems edge to the dependency report.
- Phase folders (`ecs/systems/<phase>/`) exist, but the tick order is still the list in `game_root.gd` and
  `tools/world_dumper.gd`; `ecs/schedule/`, the `PHASE` const and `ecs/events/` are M3a. `main.tscn` is now
  `shell/game_root.tscn` (root node still named `Main`) and `project.godot` starts it directly; `app_root` is
  M3b/M4. `WorldState` is `shell/save/world_state.gd` until M3b rewrites it as `SaveService`.
- `move_res.py` moves a folder or a file, not a regrouping: when one old folder fans out to several new ones
  (`scripts/data` to `schema/{entity,world,feel}`, `scripts/ecs/systems` to six phases) call it once per file in
  the same commit. It does not touch prose paths (docs, comments); grep for the old names afterwards.
- After a commit that changes an AUTOLOAD path, the first editor import pass on an old checkout prints
  `Failed to create an autoload` for the old path (stale editor state under `.godot/`) and the strict runner
  goes red on that pass; run the import pass once more and it is clean. Moving the main scene or any other file
  does not do this, and a fresh clone never does.
- Scans that must see every scene or script wherever it lives use `TestPaths.project_directory()` with the
  recursive listing, not `scenes/` or `objects/` (the audio-bus test used to, and would have gone blind).

## Content Layout Facts (M1b step 3, 2026-10-12)

- Content lives in `content/` (zero `.gd`, test-enforced): `enemies/<id>/enemy.tres` with `_shared/{movement,attacks,
  decisions,visuals}/` for pieces several enemies use, `rooms/<id>/room.tscn`, `rules/<id>/page.tres` plus
  `rules/rule_book.tres`, `skills/<id>/` and `pickups/<id>/` (the AttackProfile and EnemyWeapon data under their own
  names until the plan's `skill.tres` / `pickup.tres` exist), `player/{body,icon}.png`, `difficulty/`, `world/world.tres`,
  `tilesets/<kit>/{tileset.tres,tilemap.tscn}`. A leading underscore folder is not an id. `docs/migration-notes.md`
  has the tables and the calls.
- Art follows the owner's one-file-per-thing direction: the atlases are `assets/tiles/<kit>/atlas.svg` (single tile
  PNGs and a tool that assembles them are later), shared actor overlay art is `assets/ui/actor_view/`, the hand-drawn
  bedroom pieces are `assets/map_pieces/<piece>.png` + `<piece>_height.png`. Nothing hand-made is in a gitignored or
  `.gdignore` folder.
- The kingdom (72x40) and `first_encounter` are fixtures, not content: `tests/fixtures/<name>.tscn` with a folder of
  the same name for its parts. The world graph still lists the `kingdom` zone (the H1 exit targets it) and names the
  fixture scene, which is the one documented content-to-tests reference; M5 removes it.
- Actor view scenes are interim copies in `presentation/views/actors/` until M2 collapses them. The bishop's scene
  draws the knight's `body.png` (it has no art of its own).
- Dump baselines print the path of every resource an entity holds (`EnemyDefinition@<path>`, texture paths, `scene:`),
  so a content move changes baseline lines. `move_res.py` rewrites them; the proof that nothing else changed is
  "same line count, equal after replacing every `res://` token" (a plain `git diff` of the baselines is not enough).
- `move_res.py` rewrites whole paths only: a format string such as `".../%s.tscn"` or a directory listing that depended
  on a flat layout (`TestPaths.rooms_directory()`, the Book check in `run_tests.gd`) has to be edited by hand, and
  `TestPaths.enemy_definitions_directory()` went stale unnoticed for one commit for exactly that reason. A test that
  lists a folder forces the whole folder into one commit.
- `.import` sidecars of moved images change content (the imported-cache path is a hash of the source path); commit
  them with the move. The `uid=` inside does not change, which is what keeps scenes resolving.
- `UNDECIDED_EDGES` / `UNDECIDED_REFERENCES` are the owner's open questions, in code, with a stale-entry check so
  a fixed edge forces the line out. Add an entry only with the owner's say-so.

## Placeholder and Documentation Facts (M1b step 4, 2026-10-12)

- A placeholder is a FILE whose sha256 still equals the one recorded in `content/_placeholders.json` when
  `tools/seed_placeholders.gd` seeded it. The owner overwrites the file (same name, same role) and the flag clears by
  itself; a flag kept anywhere else would go stale. The seed tool never overwrites a file and never re-records an
  already-listed one, and a file that exists but is in neither of its two lists (`GENERATED_SEEDS`,
  `ADOPTED_PLACEHOLDERS`) is treated as the owner's. A new stand-in (a copied `body.png`, a generated sound) adds its
  row to one of those lists, or `test_placeholders_manifest` stays red only for the rows already there: it checks that
  every row is recorded, every listed file exists and a tracked scene never names `assets/_generated/`.
- Hand-drawn or owner-made art is not a placeholder: `assets/map_pieces/` and `assets/tiles/playground/` are left out of the
  list on purpose. Prose and tuning numbers are not covered (no file to hash).
- `assets/_generated/` is now consumed by nothing in the game: the T1 and T2 backgrounds were its last two users and are
  tracked copies in `content/rooms/<id>/background.png` (their own `.import` and uid). It is only the source the seed
  tool copies from for a new room. A strict runner on a clone with the folder deleted is green. This also removes the
  old fragility where a scene named a generated PNG by a uid derived from its path.
- A text copy of a `.tres` or `.tscn` copies its header `uid="..."`, and two files must not share one: delete the
  `uid="..."` of the copy and run `tools/stamp_uids.gd` (the editor's Duplicate does it for you). `/new-enemy` says so.
- The `CLAUDE.md` rules that name a thing that does not exist yet say which milestone builds it (`HudSnapshot` and
  `world.commands`, `ecs/schedule/`, `content/audio/sound_bank.tres`, `/new-skill`, `/new-room`, `/new-beat`). Until M3a the
  system order is the list in `shell/game_root.gd`, mirrored in `tools/world_dumper.gd`: a new system is added to both.
- `docs/design/*`, the production checklists and the older plans still name the old folders in prose; they are planning
  documents, not rewritten (`docs/migration-notes.md` has the old-to-new tables). `test_no_old_res_paths` only reads
  `res://`-prefixed paths, so a prose path in a doc is the author's to keep current.
- The owner's one-file-per-thing direction (2026-10-12) fits the tree without building anything: single tiles go in
  `assets/tiles/<district>/<tile_id>.png` (the atlas is `assets/tiles/<district>/atlas.*` until a tool assembles one) and
  animation frames in `content/<kind>/<id>/anim/<clip>/<NN>.png`. The assembly tools are later work.

## Content Registry and Player Definition Facts (M2 step 1, 2026-10-13)

- `ContentDb` is the only code that should load `content/` by id. It is a static class (`shell/content/`), because an
  autoload does not exist while a suite's `_init()` runs (it is added to the tree after `_init()` returns), and
  `test_content_db_in_init` asserts that premise so a Godot upgrade cannot make it vacuous.
- A static method cannot be called `get` in GDScript: it would override `Object.get`. The lookup is `ContentDb.fetch`.
- The id of a thing is its folder name; an `id` property inside the resource must equal it (`validate()` checks), and a
  Book page's `piece_id` or a door's `target_zone` must name an id that exists (`validate_cross_refs()` checks). The
  `kingdom` zone is the one world entry with no room folder (a test fixture the graph keeps until M5):
  `ContentDb.FIXTURE_ZONE_IDS`.
- A `.tres` omits every property equal to the script default, so a hand-written `player.tres` that lists all values is
  rewritten shorter the first time the editor saves it. The values are the same; the class defaults equal the
  pre-M2 hero, which is also why a view with no definition plays unchanged.
- The player scene carries no `EntityComponent` node on purpose: a node on the instance always beats the definition, so
  a leftover `HealthComponent` with default values would silently shadow `player.tres`. A node there now means "this
  scene overrides the file".
- Adding or removing an `EntityComponent` node under a view changes only the `[nodes]` section of the dump; the
  `[entities at boot]` section depends on the baked values alone, which is what makes it the proof that a bake
  refactor changed nothing.
- Fixture trees for a validator test belong under `user://`, written at run time: `tests/fixtures/` is scanned by the
  stamper and by `test_no_path_only_ext_resource`, and a deliberately broken `.tres` there would fail both.

## Actor View and In-Cell Facts (M2 step 2, 2026-10-13)

- `AnimationPlayer.speed_scale` is ignored once an `AnimationTree` drives the clips. Per-clip speed is a `TimeScale` node
  inside the state (a small blend tree: Animation, TimeScale, output) and the parameter `parameters/<state>/TimeScale/
  scale`; measured 0.52 s for a 1.0 s clip at scale 2 and 2.01 s at 0.5, and the `at_end` transition back to idle still
  fires at the scaled end.
- A state machine's `Start` edge may wait for an `advance_condition`: with two Start edges and one condition true, it
  takes that one; with both false it stays in Start. That is how one graph serves the hero (boots asleep into `wake`)
  and everyone else (boots awake into `idle`). Driving a fresh tree with `AnimationTree.advance()` from `_init()` is not a
  faithful test (an `at_end` edge fires on the first call); tests wait real frames.
- A suite or tool that runs `_init()`-time code has no running tree: a sprite is not "visible in the tree" and has no
  global transform until a frame has passed. `ActorStage.boot` documents that its callers await one frame first. Autoloads
  are null there too: a scratch script that reads `WorldState` in `_init()` dies and the process then hangs.
- `Texture2D.get_image()` works headless (the dummy renderer keeps the picture), so the cell probe reads opaque pixels
  without a renderer; `Image.get_used_rect()` is the drawn box of a picture, which is why a transparent border in the
  owner's PNG does not count as drawing. The size table's box limits the whole PNG; the probe measures what is opaque.
- Pivot arithmetic: a body that stands 14 px below the cell centre swings its bottom corners outside the cell when a
  clip rotates `SpriteRoot` about the centre. A rotating clip must turn about the body's middle (position keys
  x = r sin a, y = r - r cos a for a pivot r px below the centre); the wake clip is authored for the 20 px hero (r = 4).
- A held weapon is the one thing that cannot be both readable and inside a 32 px cell at its icon size (24 x 56 to
  28 x 64): it is drawn at 0.16 scale. Reach is shown by the board overlay, not by the length of the picture.
- The generated chess family was drawn at two world pixels per block (pawn 36 x 40, knight 52 x 64: taller than the
  cell). At one pixel per block the pawns fit; the knight (26 x 32) could not, and a half-scale (13 x 16) would be lower
  than the pawn, which the chess ladder forbids. Retracing the same glyph on fewer rows is the generator's own sanctioned
  way to change the knight; the old arrays are kept in its comment.
- A placeholder swap needs the manifest rule "provably still the old stand-in": `PlaceholderManifest.seed_decision`
  replaces a listed file only while its sha256 equals the recorded one, so the owner's art is never overwritten.
- `tests/architecture/test_pieces_inside_cell.gd` leaves the held weapon out of clips other than the hero's attack: a hurt
  clip squashes the whole actor 12 % and shakes it 2 px, which pushes a 13 px spear tip about a pixel over the edge for
  a few milliseconds. If that ever matters, lower `weapon_held_scale`, not the margin.
- The hero's pivot and the 14 px base line are the table's numbers: if the owner changes the hero's height, the wake
  clip's position keys (authored for a 20 px body) need a new pivot; the in-cell test will say how far out it goes.
