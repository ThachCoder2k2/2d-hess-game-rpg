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
