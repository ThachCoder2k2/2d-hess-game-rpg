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
