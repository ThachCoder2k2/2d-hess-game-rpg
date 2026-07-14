# Grid World

**File:** `scripts/core/grid_world.gd` · **Class:** `GridWorld` (extends Node)
**The single source of truth for the board.** If it affects gameplay, it lives here as
a cell entry. Sprites are just paint on top ([[Presentation]]).

Back to [[Home]] · related: [[Movement]] · [[Enemy AI]] · [[World and Rooms]] · [[Glossary]]

## Board shape (Inspector exports)
- `cell_size = 32` — pixels per cell.
- `grid_origin = (64, 36)` — where cell (0,0) starts on screen.
- `bounds = Rect2i(0,0,16,9)` — the 16×9 playable area. One arena. (World is many
  connected rooms, each with its own bounds — see [[World and Rooms]].)

## The five dictionaries (the entire game state)
| Dict | key → value | means |
|---|---|---|
| `blocked_cells` | cell → true | walls/blockers nothing can enter |
| `actor_by_cell` | cell → actor | who stands where |
| `cell_by_actor` | actor → cell | reverse lookup (same fact, O(1) both ways) |
| `move_reservations` | dest cell → actor | "I'm moving there" — see protocol below |
| `item_by_cell` | cell → pickup | weapons on the floor |

Each has a `##` doc comment in the file (shows in the editor tooltip).

## The movement protocol (the heart)
Two-phase, like a transaction — see [[Movement]] for the actor side:
1. `begin_move(actor, dest)` — **reserve** the destination (rejects blocked/occupied/
   already-reserved cells). Now both origin (still occupied) and dest (reserved) are
   protected while the sprite tweens.
2. `finish_move(actor, dest)` — **commit**: free origin, occupy dest.

Why it matters:
- **No clipping / no races** — two actors can never enter the same cell.
- **Honest AI** — `get_reserved_cell(actor)` returns where an actor has *committed*.
  [[Enemy AI]] reads the *hero's* reserved cell, so enemies aim where you're visibly
  going, never at raw input.
- **The dodge** — your step reserves instantly but damage checks `current_cell`;
  commit timing is what lets you escape a telegraph ([[Combat and Telegraph]]).

## Pathfinding (built-in, not hand-rolled)
`get_grid_path()` builds a fresh `AStarGrid2D` per query, marking blocked + other
actors' occupied + reserved cells solid (goal excluded). Wrappers the AI uses:
`get_path_distance` (999999 = unreachable), `get_next_path_cell`. Follows the
built-in-first rule.

## Legal-move queries
`get_destinations(actor, origin, directions)` returns which of a direction list are
enterable now. This is why movement is data: a Pawn passes 4 cardinals, a Knight 8
L-jumps, a Bishop 4 diagonals — from their `MovementConfig.allowed_directions`
([[Data Resources]]). Same function, different data → different piece.

## Notable fix
`register_actor` rejects reserved cells (not just occupied) — else a spawn could
overwrite an actor mid-step. Guarded + tested.
