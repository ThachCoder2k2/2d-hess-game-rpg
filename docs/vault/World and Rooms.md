# World and Rooms

How a room is authored (draggable markers) and assembled at runtime, and how `Main`
wires every system together.

Back to [[Home]] · related: [[Grid World]] · [[Enemy Composition]] · [[Presentation]] · [[Data Resources]]

## Main — the coordinator
**File:** `scripts/main.gd` · **Scene:** `scenes/main.tscn` (root `Main`)
The entry point. Its children are the whole game: [[Grid World|GridWorld]],
EncounterDirector ([[Combat and Telegraph]]), PrototypeBoard, [[Player|PawnHero]],
the room (`FirstEncounter`), and the HUD. `main.gd` resolves those child nodes, connects
their signals (it's the **common parent**, so it wires hero ↔ room ↔ HUD — "call down,
signal up"), runs setup, and handles screen shake / damage flash / restart. It builds
**no content** in code.

## Markers — authoring by dragging (`scripts/world/`)
All extend **`GridMarker`** (`grid_marker.gd`), which owns the editor drag-to-snap:
move the node in the editor → it snaps to a cell and writes `grid_cell`. Subclasses add
only their data + `_draw` gizmo:
| Marker | File | Holds |
|---|---|---|
| HeroStartMarker | `hero_start_marker.gd` | the hero's start cell |
| BlockerMarker | `blocker_marker.gd` | a blocked cell (wall) |
| EnemySpawnPoint | `enemy_spawn_point.gd` | `enemy_scene` PackedScene + `definition` |
| PickupSpawnPoint | `pickup_spawn_point.gd` | `pickup_scene` + `weapon` |

The room scene shows a **preview** child (the real sprite) at each marker, so the editor
is WYSIWYG.

## RoomEncounter — assembling the room
**File:** `scripts/world/room_encounter.gd` · **Scene:** `objects/world/room_encounter.tscn`
On `setup()`: reads the markers → tells [[Grid World]] which cells are blocked → spawns
enemies ([[Enemy Composition]]) and pickups at their marker cells → tracks remaining →
emits `room_completed` when the `RoomObjective` ([[Data Resources]]) is met.
`first_encounter.tscn` is the one authored room today; `weapon_pickup.gd` is the droppable
item spawned here.

## World shape (decision)
**Connected rooms**, not one big scrolling map: many bounded boards joined by door
transitions (Zelda-screen style). `GridWorld.bounds` stays per-room; exploration comes
from connectivity. The door transition system is the next build (roadmap E6).
