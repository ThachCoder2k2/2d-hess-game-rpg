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
- Content defects found by the bridge suites in M1a. FIXED in the M3b review (`base/m3b-fix`): the west return
  doors of T2, T3, T4, B1 and H1 (and H1's top door to the Toybox) stood on the ring of wall of the shared
  tilemap, cells (0,5) and (2,0), so the hero could never walk back; the doors now sit one cell inside the
  ring, like the east doors, each entry one cell further in (`tests/content/test_room_doors_reachable.gd`,
  `tests/bridge/test_bridge_backtracking.gd`). FIXED in the second review round (`base/m3b-fix2`, see "M3b review
  fixes, second round" below): T4's `PencilSpearPickup` and its Backstep pawn were both parked at (7,6), a solid cell
  (the wall column); the spear moved to (13,2) and the pawn to (10,6). Until then only the Ruler Blade in B1
  (cell (8,6), floor) could be taken by a pawn in play.
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

## Walk and Docs Facts (M2 step 3, 2026-10-13)

- The uid stamper fills a path-only `[ext_resource]` line from the target file's own uid, and a picture has none until an
  import pass has written its `.import`. So a new enemy's files go in this order: write them with no header uid and a path-only
  reference to the files just made, import, `stamp_uids.gd`, import again, `stamp_uids.gd -- --check`. A text copy of a `.tres`
  keeps the source's header uid, which two files must not share; duplicating in the editor's FileSystem dock does that part
  itself.
- A uid the stamper just wrote is unknown to the editor until the next import pass: a scene that names it logs `ext_resource,
  invalid UID ... using text path instead` and loads by path. Harmless, and gone after the import.
- `max_health` has a default (2) and a `.tres` omits every property equal to its default, so a copy of `pawn_recruit/enemy.tres`
  has no `max_health` line to edit: add one.
- Adding an enemy to a real room changes more than the room. That room's baseline (`tests/baselines/dump_<room>.txt`) fails until
  it is regenerated with `tools/dump_world.gd -- --write-baselines`, and tests that count a room's contents fail too: T3's pawn
  count is asserted by `test_bridge_travel` ("T3 holds its single living pawn").
- To see that a definition spawns without touching a room, put a throwaway scene in the **project root** and boot it with
  `tools/dump_world.gd --room=res://<scene>` (it accepts any scene path). Under `content/rooms/` the same scene fails four suites
  (`ContentDb.validate_cross_refs()`: "no zone of content/world/world.tres leads here"; `test_content_references`: it names
  `presentation/board/`; and the two registry suites that assert the whole tree is healthy), so delete it before running the
  runner.
- `dev_sandbox` (the room the plan's M2 "owner can try" names) is an M6 deliverable; until then the only place to play a new enemy
  is a real room.
- **Resolved in the M2 fix round:** `VisualDefinition` had five fields nothing read (`telegraph_color`, `impact_color`,
  `weapon_anchor`, `hurt_animation`, `defeat_animation`); they are deleted from the class and the three `.tres` that set them. The
  tint is `ActorView.telegraph_modulate` and the hand is `ActorView.weapon_anchor`; a field is added when a system reads it.
- `tools/render_actor_preview.gd` now writes two pictures: `pieces_in_cells.png` (the hero and the three thin scenes, the
  `ACTORS` rows) and `pieces_placed_in_rooms.png` (one row per actor a room scene places, as placed: seven today). An enemy
  that is only a `definition` is a row of the second picture once a room places it. `test_actor_preview_tool` reads the sizes
  from the tool's constants.
- The first picture is `(46 + 9 x 44) x 4` by `(14 + 4 x 44) x 4` = 1768 x 760: a name strip, nine cells of 32 px each with a
  6 px gutter on every side (pitch 44), a header strip and four rows, at whole-number 4x. Grid and margin lines are laid only
  on background pixels, so they sit under the pieces; a piece pixel in the margin band or outside the cell is magenta and counted.
- **The art spec's canvas.** The owner's request list (`docs/assets`, on game-base) asks for every piece on a 32 x 32 canvas
  (`block_px` 2: chunky 2 px art pixels), anchor (16,30), body boxes pawn 18 x 22 (top y 8), knight, bishop, rook 20 x 24 (y 6),
  queen 22 x 26 (y 4), king 22 x 28 (y 2): the same numbers as `piece_sizes.tres`, with the base rim 14 px below the cell
  centre. The game accepts that canvas (and a tight picture): `PieceSizeTable.cell_canvas_base_row` (30), `box_on_cell_canvas`,
  `picture_problems`. A canvas lands exactly on the cell, so `BodySprite` in the base scene is (-16,-16) for every picture.
- **Measuring in the cell's frame.** `ActorCellProbe` used the view's own inverse transform, which cancels a scale and made the
  B1 captain at 1.18x look exactly as big as its picture. It now measures from the cell (the view's position only).
- **A hit's drawn shove** (`Health.recoil`, 4 px) moved the whole piece and crossed the cell edge for about 57 ms; the drawn
  offset is limited to the size table's margin (a piece touches the edge, never crosses it). `Health.recoil` is unchanged.
- **Pips and tall pieces.** The pip row (4 px, on the top margin line, -14 to -10) clears the head of a pawn, knight, bishop and
  rook (a knight's head touches it) and cannot clear a queen (26 px) or a king (28 px): a king's box fills the 28 px the margin
  leaves. Their pips are drawn over the crown; `KINDS_WHOSE_PIPS_OVERLAP_THE_CROWN` in `test_pieces_inside_cell` names them, so a
  boss row tall enough to reach the pips fails until the owner decides.
- **Open between the two documents (game-base `docs/assets` and the M2 scene):** telegraph aura files of 40, 56 and 96 px
  (against 22 to 27 px in the scene), a facing arrow 8 x 8 in a 16 x 16 canvas (about 6 px in the scene), a pip row 24 px wide
  (14 px in the scene). The owner's rule says nothing a piece shows leaves its cell; whoever merges picks one set.
- **Ladder.** The table puts knight, bishop and rook on one rung and the drawn bishop is 22 px against the knight's 24; a
  real set has the bishop taller. A design call for the owner (split the rung and redraw, or keep).
- ContentDb now reports a reference Godot drops without a word (a resource of the wrong class loads as null with no engine
  message): `validate()` reads the `[resource]` section of each `.tres` for `name = ExtResource(...)` and compares with the
  loaded value, and follows resource files those properties name.
- Moving a file is the only thing that edits `tools/move_res_log.tsv`; M2 added files and deleted one and renamed none (`git diff -M`
  shows no rename), so the log has no M2 line.
- A scratch copy of a checkout for a destructive walk must be a `git clone`, not `cp -R`: a worktree's `.git` is a file that points at
  the main repository's worktree metadata, so git commands in a copied worktree would act on the original. A clone plus
  `tools/bootstrap_worktree.sh` is ready in about a minute.
- From a worktree-isolated agent session the sandbox refuses a command that sets `HOME=` in front of Godot and compound commands
  that mix git with another directory. What works: a tiny wrapper script that exports `HOME` and `exec`s Godot, `GODOT` and
  `UNBOUND_GODOT_HOME` for `tools/run_all_tests.py`, `BOOTSTRAP_HOME` and `GODOT_BIN` for the bootstrap script, plain separate `git
  clone` and `git -C <dir>` calls.

## Runtime Seam Facts (M3a step 1, 2026-10-19)

- `StringName` `sort()` orders by memory address, not by letters. Anything that must print in a stable order sorts
  `String(name)` or uses an explicit list (`COMPONENT_DUMP_ORDER`); the room dumps broke once because scripts loaded in another order.
- A failed `assert` in a headless debug run prints `SCRIPT ERROR: Assertion failed: <message>` and the function returns at
  once. The runner fails any suite that prints a `SCRIPT ERROR`, so `EcsWorld.emit_event`'s assert on a bad event stops the
  first test that emits it (and costs nothing in an exported build, where asserts are removed).
- A ternary such as `weapon.tags if weapon != null else []` is an untyped `Array`: returning it from a function declared
  `-> Array[StringName]` is a runtime `SCRIPT ERROR`, only on the path that takes the `[]`. Build a typed array and `assign()`.
- `a == b as T` parses as `(a == b) as T`; compare against a typed local instead.
- A script's constants are read with `script.get_script_constant_map()` and its `class_name` with `script.get_global_name()`;
  `get_property_list()` entries with `PROPERTY_USAGE_SCRIPT_VARIABLE` are exactly the variables a script declares (the engine's
  own `script` property is not among them), which is how `tuning_set` knows its keys.
- The schedule's stage names are not the system folders: the plan's order visits `world/` three times. A system's `PHASE` const
  names its stage; its folder says what it is about.
- A command handler is a `Callable(command: Dictionary) -> String` returning `""` when it applied the command or the reason it
  refused; one that returns anything else is reported as a bug. Handlers are registered in `setup()`, so a test world that lacks a
  system lacks its handlers and the request is dropped with `command_rejected`.
- `world.commands` and `world.view_commands` are drained with `duplicate()` then `clear()`, never by swapping in a new array, so a
  caller that kept the array keeps a live queue. (`damage_events` still swaps; nothing holds it.)
- `ViewSyncSystem` can only play an animation state on a view that has an `AnimationTree`; a bare view or one without the state is
  refused with `command_rejected`. `bow` and `hesitate` have no clips yet (only `wake` exists), which is the owner's art work.
- The trailer on every commit of this branch is `Co-Authored-By: Claude Sonnet 5.5` (the session's attribution), not the
  `Opus 5.5` line the task text named, as in M2.

## Runtime Seam Facts (M3a step 2, 2026-10-19)

- The engine's "just pressed" is a frame comparison: `Input.is_action_just_pressed` stays true for every call inside the frame of the
  press, even after a release. The bridge suites pump many ticks inside one frame and depend on that, so `InputPoller` copies the
  engine's flags verbatim; edges it worked out itself would have turned a held key into one press. Raw keys have no such flag, so the
  three shell keys get their edge from the poller's memory of the previous poll.
- A one-off equivalence check beats a claim: put the old script from `git show <commit>:path` (minus its `class_name`) in /tmp, load it
  by absolute path, drive both with the same random play and compare state after every tick. Sabotage the new side once to see it fail.
- `Camera2D` in Godot 4.6: when an axis's limits span less than the screen, the camera is centred on the limit rect (it is not
  anchored to the left or top limit). The 16x9 room was centred by that accident; `CameraRig.limits_for_board` states it. `offset`
  (screen shake) may pass the limits. A camera needs `is_inside_tree()` to `make_current()`, and a suite's `_init()` runs before the
  tree is up, so `await process_frame` first. `get_screen_center_position()` in a `SubViewport` of the game's size measures framing
  without a window.
- JSON hands every number back as a float and StringNames as Strings; anything saved goes through `int()` and `StringName()` on the
  way in (`PlayerSnapshot.from_dictionary`). `value is int` is false for a bool in GDScript.
- In tests, build the typed array first (`[..] as Array[StringName]`) before comparing arrays of StringName or Vector2i.
- Presentation reads a plain-data DTO that is rebuilt IN PLACE, never replaced: a widget that kept the reference sees every rebuild
  (`HudSnapshotSystem`), and a steady room allocates nothing per tick.
- The HUD's skill slot is redrawn on `skill_cooldown` events, so after the sword is found it keeps saying "find sword" until the first
  skill is used (pre-existing, kept on purpose in M3a; M4's widgets draw the snapshot each frame).
- A scene authored for a centred origin other than 16x9's (an 18x9 arena at x 32) must place its art, its `GridLinesOverlay` and its
  markers for that origin; the grid only reports it (`EcsGrid.centred_origin`, `EcsBoot.shape_grid`). The first non-16x9 room is M8b.
- The sandbox of a worktree-isolated agent refuses a command that combines a heredoc with git, and refuses `HOME=` in front of Godot.
  What works: a heredoc that runs alone (a python edit script), the file tools for writing, and a small python wrapper that sets
  `HOME` in the environment of the Godot subprocess.

## Runtime Seam Facts (M3a step 3, 2026-10-19)

- `AStarGrid2D` can be built once and reused: `set_point_solid(cell)` then `set_point_solid(cell, false)` puts it back exactly, so a
  question that needs the pieces solid marks them, asks, and unmarks only the cells it marked (a cell already solid because it is a
  wall must stay solid). The path is cell-for-cell the one a pathfinder built for that question gives; `test_path_cache` holds it.
  `is_point_solid` and `set_point_solid` on a cell outside `region` print an engine error, so a cache is built from `blocked_cells`
  inside the bounds only.
- On a board as small as 18x9 the pathfinder rebuild was not the main cost; the attack-setup search that walked and shaped every cell
  was (rebuilding the pathfinder for every question with the search bounded still measured a 99th percentile of 2.3 ms against 1.7 to
  2.0 ms with the cache). The cache pays on the 72x40 kingdom (12x on short questions). Measure before attributing a gain.
- A bound on a search is only safe if the thing bounded is a translation: the attack shape is the same set of offsets wherever the enemy
  stands (a pattern that clips to the board only drops cells), so no cell farther than the shape's reach from the hero can contain the
  hero. `AttackPattern.get_attack_cells(null, ...)` and `EnemyWeapon.get_attack_cells` give the unclipped shape. A future shape that
  depends on the board (a line to the wall) breaks the bound, and `test_attack_setup_search` measures the reach from the data to catch it.
- To keep a faster version honest, keep the old body in `tests/support/` as a subclass (`ReferenceGrid extends EcsGrid`,
  `ReferenceEnemyAI extends EnemyAISystem`), tick two worlds side by side and compare the whole state and every event after every tick;
  then sabotage the new side once (a search one cell too narrow) to see the comparison fail. A cross-checkout replay (a throwaway script
  played on a fresh clone of the previous branch and on the new one, then diffed) is the same idea with the real old code and needs no
  copy of it.
- A leap and a step differ in who holds what: a step holds both cells until it lands; a leap holds only the landing cell, so an airborne
  entity is in neither `entity_by_cell` nor `cell_by_entity`. Code that walks `cell_by_entity` to find "every entity" misses the leaper;
  ask `is_airborne()` or `leap_by_entity`. `unregister_entity` also removes an in-flight leap.
- `blocked_cells` is derived: write the terrain only through `EcsGrid.set_cell_kind()`; `test_grid_cell_kinds` greps for any other writer.
  A cell effect (chalk over a gap, M10) is a temporary kind change recorded in `cell_effect_by_cell` with the `kind_before` to restore.
- A TileSet custom-data layer can be added as text (`custom_data_layer_1/name = "kind"`, `custom_data_layer_1/type = 4`, string) without
  moving a uid; `TileSet.has_custom_data_layer_by_name` lets a reader tolerate a TileSet that lacks it. A tile that leaves `kind` empty
  means what its `solid` flag says, which is why adding the layer changed no room.
- Rerunning a paint tool is the check that a refactor of it changed no cell: `tile_map_data` must be identical, and only the node's
  `unique_id` and an `ext_resource` id differ (restore the file with `git checkout` when that is all).
- A performance test on a shared machine: assert on the mean AND the median of a long run, give the 99th percentile a bound several times
  above what it measures, only print the slowest tick (one tick of 88 ms was seen from outside the process), and assert one thing that does
  not depend on the clock (the pathfinder is built once). The same test measured 0.15 ms mean on a quiet machine and 0.5 ms on a busy one.
- The worktree-isolated sandbox refuses a command that mixes a heredoc with git, one that sets `HOME=` in front of Godot, and a
  `git clone` or other git call chained after a `cd` into another directory. What works: plain separate commands, `git clone -q -b <branch>
  . <dir>` run from the worktree, a wrapper script that exports `HOME` and `exec`s Godot, and `GODOT` / `UNBOUND_GODOT_HOME` /
  `BOOTSTRAP_HOME` for the project's own tools.

- `ConfigFile.get_value(section, key)` with no default, or with `null` as the default, prints an engine ERROR line when the key is
  missing; so do `erase_section_key` on a missing key and `load()`/`parse()` on text that does not parse (with no hint why). The strict
  runner fails a suite on an engine ERROR, so the save code asks `has_section_key` first, passes real defaults, and recognises a damaged
  file by its integrity footer BEFORE the parser sees it (`shell/save/save_file.gd`). A `;` comment line at the end keeps the file a
  plain ConfigFile.
- A `StringName` array sorts by memory address, not by letters (the dump tool already found this): to compare lists of ids in a test,
  convert to `String` first.
- An autoload cannot also be a `class_name` (the name is a global): `SaveService` has none, the shell types it with
  `const SaveServiceScript := preload(...)` and `get_node_or_null("/root/SaveService") as SaveServiceScript`, and tests make their own
  instance with `SaveSupport.new_service(root)`. In `_init`-time suites the autoload does not exist yet.
- `DirAccess.rename_absolute` replaces an existing target on macOS and works for both `user://` and absolute paths, which is what makes
  "write temp, rename over" the atomic step; `FileAccess.get_modified_time` is the best timestamp a v2 save has.
- The worktree-isolated sandbox also refuses a heredoc-fed `python3` or `git commit -F -` chained with `git add` in one command when
  it cannot tell what runs (and `time`, `for` loops around Godot); put repeated Godot commands in small wrapper scripts under /tmp,
  write multi-line files with the Write tool, and keep each git command on its own line. In zsh a bare `=====` argument is an
  expansion error, so do not echo it.

## Game Root and Bridge Facts (M3b step 2, 2026-10-19)

- A lambda (a `Tween.tween_callback`, a signal handler) that captures a node or world that is freed before it runs prints an engine
  ERROR ("Lambda capture at index N was freed"), which the strict runner fails a suite on. Capture `get_instance_id()` and resolve it
  with `instance_from_id()` inside (it returns null for a freed object). The same lambda also ran against the WRONG world once rooms
  are rebuilt in place, because entity numbers start over in every world: a timer must name the world it was made for.
- `class_name GameRoot` and `ShellBridge` (which holds a `GameRoot` and is held by it) reference each other and load fine in 4.6:
  cyclic `class_name` references are not a problem, a cyclic `preload()` would be. A new `class_name` still needs one import pass.
- `call_deferred` on a `RefCounted`'s method works and keeps no strong reference; a coroutine started that way (`GameFlow` waiting
  for a trip with `await get_tree().process_frame`) is fine. A request served "at the end of the frame" is what the scene reload
  already was, so a `_process` that asks for a respawn never has its world swapped under it.
- Rebuilding a room inside the scene needs a fresh hero view, not a reset one: a defeated hero's `AnimationTree` rests in a `defeat`
  state with no exit and its `SpriteRoot` holds the end of the clip, and the base graph's boot pose (the hero wakes up) belongs to a new
  instance. `ZoneStage.replace_hero_view` instantiates the view's own `scene_file_path` and parks it at the authored position; the
  camera rig is the view's child, so the camera bridge is handed the new rig.
- `PrototypeBoard.setup()` used to keep `telegraphs`, `enemy_intents` and the impact flash across rooms. Entity numbers start over per
  world, so a mark left by the last room could be drawn for an unrelated entity; `setup()` clears them now.
- A won room can only be left by starting it again (`room_ending` blocks a zone trip), so a suite that wants a second fresh room after a
  win frees the scene and boots a new one from the run (`test_bridge_room_outcome._boot_again`).
- The strict runner treats the engine's exit noise ("ObjectDB instances leaked at exit", "resources still in use at exit") as noise but
  any other `ERROR:` line as a failure. The worktree sandbox refuses a `HOME=` assignment in front of the Godot binary; wrapper scripts
  under /tmp that `export HOME` and call Godot avoid it.

## Room, Checkpoint and Carry Facts (M3b step 3, 2026-10-19)

- The world dump prints every component of every entity, and `tests/baselines/actor_collapse_golden.txt` fingerprints the heads of the
  six dumps and refuses to be re-recorded. A bookkeeping entity added to every booted room would move all of them, so the room's own
  entity is opt-in (`EcsBootOptions.with_room_rules`, set by the shell) and made last, which also keeps every other entity's number.
- D-16 reads two ways ("return to the latest checkpoint" and "a death resets only the current uncleared room"). With checkpoints at
  the hub and boss doors only, the first sends a death in T3 to the start of Stage 1 (T1..T4 have none). Built: the room entry; the
  position and the checkpoint are two facts in the run. A save written before the rule has no `room_entry`; it resumes on its
  checkpoint entry, which is where the position used to be kept.
- A checkpoint's refill is a heal request (source 0) queued by a system that runs AFTER `HealthSystem`, so the Courage is restored on
  the next tick and `healed` is what the HUD hears; `HudBridge` redraws the pips on it. The first tick of a room runs during the
  fade-in, so the checkpoint is recorded and saved a fraction of a second after the boot, not before the fade.
- `checkpoint_reached` used to be written at the start of every trip, which also carried the world's flags to the run. With a trip no
  longer a success event, the flags reach the run by `SaveBridge.remember_world()` (a trip begins, the hero falls, just before a
  write) and the file learns them at the next success event; a flag set in a room that is then lost to a death survives it.
- A resource nobody holds is unloaded and read again from disk: a test that edits the shared `WorldGraph` has to keep a reference
  (`edited_world_graph`), or the next `main.free()` throws the edit away. `PackedScene.pack()` of an instance of an inherited room
  scene works, so a test can swap in a copy of a room with one export changed.
- `ObjectiveSystem` counts `defeated` from Courage 0 or the AI's defeated state each tick and never lets the defeated count or the
  total go backwards, so a corpse cleaned away later does not un-clear a room. When the last enemy and the hero fall in one tick the
  fall wins (the room is not cleared), which the old event-order rule left to chance.
- `PlayerSnapshot.apply_to` writes the maximum Courage too, so a fresh run must not pass the run's own `player` snapshot to it
  (its default 3 would override the `PlayerDefinition`); only a snapshot captured from a live hero is passed, and only by a trip.
- Order of reactions matters in `GameRoot._bridges()`: `SaveBridge` is before `RoomOutcomeBridge`, so a cleared room is written and
  saved before its result screen goes up, and the world's flags are taken before the defeat beat starts.
- The worktree sandbox refuses `HOME=` in front of any command and refuses to run a quoted binary path directly; the runner reads
  `GODOT` and `UNBOUND_GODOT_HOME` from the environment, and a short Python wrapper that sets `HOME` in a child process runs the
  UID check (`stamp_uids.gd -- --check`).

## M3b review fixes (base/m3b-fix)

- A door is a FLOOR cell one step inside the 16x9 ring of wall, its entry marker one step further in; the ring itself is solid.
  A marker on the ring cannot be walked to (the wall is the collision since 0dddfd1), which is how every west return door of
  Stage 1 was dead for as long as the rooms existed. `tests/content/test_room_doors_reachable.gd` boots every room of the world
  graph and checks entries, doors, reachability and target entries on the real grid. Moving a marker changes the room dumps and
  the actor golden's room fingerprints: regenerate `tests/baselines/dump_*.txt` (`tools/dump_world.gd -- --write-baselines`) and add
  the new head line to `ROOM_HEADS_CHANGED_ON_PURPOSE` in `test_actor_collapse_golden.gd` with the reason (the golden file is never
  re-recorded).
- Standing still on a room's entry is safe in T3 (the Recruit does not come looking: 40 simulated seconds, no hit), but a hero who
  walks up to it is struck down in 4 to 6 s; in B1 the guards take the Ruler Blade within about 1 to 2 s and two of the three
  pieces already hold a weapon of their own (the captain's and a guard's default weapon).
- The T4 Backstep pawn is parked at (7,6) as well, a wall cell: it is counted as an enemy of the room but starts on a cell the grid
  does not list as walkable. Found here and not fixed; an independent verifier then showed it makes T4 impossible to clear, and it is
  fixed in the second round below.
- A write that dies between the two renames of `SaveFile.write` leaves the NEW save as `<file>.tmp`; the loader takes it when it is not
  older than the `.bak` (`SaveFile.read_unfinished_write`) and `load_slot` finishes the rename. File times are whole seconds, so the
  comparison is "not older"; the one test that needs an older `.tmp` waits 1.1 s.
- A Continue resumes at `[meta] room` and `room_entry` (the room of the LAST SAVE), not at the `[checkpoint]` record; the two coincide
  only when the last save was the checkpoint's. Nothing in the build reads `checkpoint_zone_id` to place the pawn.

## M3b review fixes, second round (base/m3b-fix2)

- **T4 could not be cleared, so B1 and the hub could not be reached.** T4 parked its Backstep Pawn and its Pencil Spear on (7,6), a cell of
  the wall column of the shared tilemap. `EcsBoot` spawns an enemy and calls `EcsGrid.register_entity`, which refuses a wall cell, and
  nothing looks at the answer: the pawn counted toward the room (`enemies_total` 3) but `entity_at((7,6))` was 0, so the sword could not
  hit it, it never moved, and the room (cleared when all three fall) was never cleared; the east door (`requires_room_clear`) never
  opened. In the old T4 world dump the pawn even "took" the spear by standing on it (a pawn on an item cell with no weapon picks it up at
  its next decision), and a hero beside the wall was struck by a pawn nobody could reach. M3b's own suites hid it: the owner-guide suite
  killed enemies with a damage request (`Events.emit_damage` with the hero as source), which needs no cell.
- **Fix: the cells.** Backstep Pawn (10,6): open floor in the lower east yard, four cells to its east and five to its north to back off
  into, two clear columns from the wall column, 9 cells from the entry so it is outside the 7-cell aggro radius of a hero arriving.
  Pencil Spear (13,2): the end of the room, just past the Armed Pawn (12,4) on its way to the east door (14,1), one step off both
  approach cells of that door ((13,1), (14,2)), not on the way-back entry, not in the Armed Pawn's first strike. The flow map and D-11
  ask for exactly that (an optional reward on the exit path beyond the Armed Pawn; the Backstep Pawn teaching its step in open floor).
  The hero cannot take the spear in this build (a Pencil grant that unlocks Q is M7, D-11); only weaponless pawns take floor weapons.
- **A guard against the class.** `tests/content/test_room_markers_on_floor.gd` boots every room of the world graph for real (EcsBoot,
  closed doors) and checks: entries walkable and not under a pawn; every parked enemy on a walkable cell AND in the grid
  (`entity_at(cell)` is that entity, which also finds two pawns on one cell) and its cell connected to every entry; every pickup on a
  walkable cell, listed by the grid (`register_item` silently drops a second item on a cell) and connected; every unlock marker the same;
  every gate over floor in the painted tiles and with a walkable, connected approach cell. It fails on copies of rooms that are right
  (a pawn on a wall, two pawns on a cell, a spear on a wall, a spear or a pawn walled in, the sword on the ring, an entry under a pawn, a
  gate in a wall, a gate nobody can push). Every other room (T1, T2, T3, B1, H1 and the kingdom fixture) was clean.
- **Markers place themselves two ways, and the scan reads each as `EcsBoot` does.** `PickupSpawnPoint` is read by its `grid_cell`
  (`position` is only the editor preview, computed for a 16x9 board at the preview origin); `ZoneEntryMarker`, `ZoneExitMarker`,
  `PlayerUnlockMarker`, `GateMarker` and the parked `ActorView`s are read by `position` through the room's own grid origin.
- **A damage request is not a sword.** `Support.kill_with_sword` (`tests/bridge/bridge_support.gd`) walks the hero by key presses to the
  floor cell beside the pawn with the shortest walk, pushes toward it (a step into a piece is blocked and only turns the hero) and
  presses attack, swing by swing, until it falls. The owner-guide, cleared-rooms and room-outcome suites use it, so a pawn the sword
  cannot reach fails them (the old T4 fails the owner-guide suite at the third pawn of step 3); `test_kill_with_sword` proves it says no
  for no sword, a pawn not in the grid and a pawn walled in. Direct damage stays only as a stand-in: `Support.damage_player` for "take a
  wound" or "fall", and the boss's one point, the old world's despawn timer and the despawn view lifecycle in the suites whose subject is
  something else (each says so in the file).
- **The idle-room facts behind the new T4.** A pawn only decides once the hero is within its aggro radius (7 cells, Manhattan, from
  `DecisionConfig`), so a hero standing on T4's entry sees nothing move for 40 s; walking to the middle gap (7,4) wakes all three, and a
  weaponless pawn (the Recruit, the Backstep Pawn) goes for the nearest floor weapon before it goes for the hero: the Recruit walks to the
  spear at (13,2), arrives out of its own leash and stands on it, still empty-handed.
- **The B1 dump explanation was backwards.** `test_actor_collapse_golden` said that with the hero one cell further east the guard beside
  the Ruler Blade "has not stepped onto it after 120 idle ticks". The recorded dumps say the opposite: before the door fix the guard had
  stepped onto the blade's cell (8,6) and not yet taken it (blade still listed, 3 events); after it the guard has taken the blade and
  walked back to (8,5) (blade gone, 9 events). The guard takes the blade either way; the entry move only changed how far it got in two
  seconds. The allowance now says so.
- **The guide's step 3 asked for something impossible.** "Redo it from T3 if needed" (let the T3 pawn wound you, then kill it) cannot be
  done once step 2 has cleared T3, and the suite got its wound in the empty room by a request. Step 3 now starts in T4, where step 2
  ended: wound, west door and back (an ordinary door heals nothing), sword clears T4, B1's door refills. Steps 1-3 are once-per-save;
  deleting `slot_0.cfg` and `slot_0.cfg.bak` is how the owner repeats them (the guide says so).

## M3b review fixes, third round (base/m3b-fix3)

A second independent verifier played Stage 1 on foot with real input (T1 to the hub and back, 13 runs, zero-delay and human-paced) on
`base/m3b-fix2`: every enemy hittable, every door opens, the guide's section 7 followed literally, no blocker. It left six
non-blocking notes. Two were wrong in the build and are fixed; one was wrong in the guide and is fixed; two are M7 and stay (one more
was the commit attribution line, which matches the harness and is no defect).

- **A locked door blamed a captain that was not there.** Every door that waits for a clear answered with one constant ("The captain still
  holds the rug edge..."), so T3's door (one pawn) and T4's (three pawns) named the boss. The words now travel with the door, the way the
  sword's line travels with `PlayerUnlockMarker.message`: `ZoneExitMarker.locked_message` is baked into `EcsGrid.exit_by_cell`,
  `MovementSystem` puts it in `zone_exit_locked` (`message`), `MessageBridge` says it, and an empty one falls back to a generic line that
  names no piece (`MessageBridge.DOOR_IS_LOCKED`). T3, T4 and B1 each say their own (B1 keeps the captain's line, where it is true).
  `test_room_doors_reachable` fails a `requires_room_clear` door with no line, and proves it can (a silenced T3 door). This is the
  editor-first half of ledger rows 108 and 111; the `.po` text key, `requires_flag` and `one_way` stay M4/M5. The six world dumps gained
  the `locked_message` key on every exit line and nothing else (reviewed line by line); the actor golden's table of room heads moved on
  purpose (`ROOM_HEADS_CHANGED_ON_PURPOSE`) now lists all six rooms, T1 included, with the reason.
- **The skill slot said "FIND SWORD" after the sword was taken.** `HudBridge` redrew the slot only on a `skill_cooldown` event and at
  boot, and taking the sword raises none, so the slot kept the old line until the next room or the first swing (7 s and more in the
  verifier's walk). `refresh()` now redraws the slot the frame the snapshot's `sword_unlocked` differs from what was last drawn
  (`last_sword_shown`); that does not depend on the order the bridges handle `player_unlock` in. A unit test in `test_hud_bridge`, and the
  on-foot route suite reads the real HUD before and after the sword.
- **The guide said a guard takes the Ruler Blade "after a few seconds".** `test_owner_guide_steps` measures it and prints it: about 1.0 s
  after the hero arrives on B1's entry (steps of 0.25 s, so 0.75 to 1.0); the verifier saw 0.5 to 1 s. Step 4 now says about a second,
  what the owner sees (the blade leaves the floor, the status line says `... picked up Ruler Blade`) and that `R` shows it again.
- **Left: a weaponless T4 pawn carries the Pencil Spear off.** In the verifier's ten human-paced runs a weaponless pawn (usually the
  Recruit) walked to (13,2) and took the spear while the hero fought near the middle of the room; the pawn that holds it drops nothing
  when it falls, and a cleared room stays empty (D-17), so the spear is gone for the run (the zero-delay bot killed that pawn first and
  kept it). That is how D-16 floor weapons work, the guide's step 4 already says weaponless pawns go for it, and the hero cannot take the
  spear in this build anyway. The durable conclusion is for M7: the T4 Pencil is a hero-only `GrantMarker` (D-11's "guaranteed on the exit
  path"), never a floor weapon; the plan's M7a entry now says so.
- **Left: the hero cannot take the spear** ("take the pencil spear" is not possible in this build; Q works from the sword on). The Pencil
  grant that locks Q is M7 (D-11); the M3b review rounds do not build that lock.

## App Root and Flow Facts (M4 step 1, 2026-10-19)

- A coroutine that awaits a `Tween.finished` hangs forever if the tween is killed, and a screen change that waits on it blocks the whole queue.
  `TransitionLayer` therefore awaits its own `fade_ended` signal and releases the waiter of a fade it replaces (a generation counter); it emits
  that release AFTER the new fade is set up, because the released caller continues synchronously inside `emit` and may start a fade of its own.
- `Node.create_tween()` starts on the next frame and its first step carries all the time that passed before it was made, so a test that times a
  fade gets less than the duration; assert "not instant, not forever", never the exact time.
- A `GameFlow` (a `RefCounted`) that keeps the `GameRoot` it rebuilds must test `is_instance_valid(_root)`, not `_root != null`: Quit to Title
  frees the room while a death beat or a fade is still awaited. Any timer or coroutine of a bridge that outlives the scene has the same
  hazard (`RoomOutcomeBridge`'s 0.85 s beat did).
- Setting `process_mode = PROCESS_MODE_DISABLED` on a container stops its mouse and key events and its focus, which is how the title silences
  its menu behind the New Game question and after a choice. `ConfirmPanel` also points every `focus_neighbor` at itself, because arrow keys
  otherwise find the nearest focusable control in the direction, behind the backdrop.
- `Signal` can be passed as an argument and `Callable`s of a `bool`-returning method connect to signals that carry nothing; `Signal.emit` is itself
  a `Callable` (`title.settings_chosen.connect(settings_requested.emit)`).
- Exported node references in a hand-written `.tscn` need `node_paths=PackedStringArray("a", "b")` on the node's header and `NodePath("...")` values;
  a new `.tscn`/`.tres` written without a header uid is stamped by `tools/stamp_uids.gd`, and its script references only after an import pass has
  made the `.gd.uid` sidecars (run the stamper twice: before and after the pass).
- A suite that extends `SceneTree` IS the tree: `get_tree()` does not exist in it, use `paused`, `current_scene`, `root` and `create_timer(...)`
  directly. Cannot-infer-type errors (`var x := node_typed_as_Node.method()`) are parse errors in this project: type the variable.
- The credits' Licenses block is a function of `THIRD_PARTY_NOTICES.md` (an entry is credited iff it is a `###` heading with a `- **License:**`
  bullet outside a "(not shipped)" section), so the notices are the one place a new third-party item is recorded; the font and the glyph pack
  of M4 become credits by being listed there and running `tools/build_credits_licenses.gd`.
- The Control-based screens are children of a plain `Node` host; their full-rect anchors resolve against the viewport, and no `Camera2D` exists
  while one of them is up (the game scene, which owns the camera, is freed first). A screen drawn in the default canvas would move with a camera.
- `SaveService.start_new_run` writes before any success event, which makes `has_save` true for a run with no progress: the title then offers
  Continue for a clean run, which resumes at the authored first room (the same place as New Game). That is intended.
