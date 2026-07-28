# Map build plan — the world, file by file

Implementation plan for the soulslike map (docs/soulslike-world-plan.md,
owner-scoped: map first, Knight later). Research inputs: fade-swap beats
scroll when palettes differ between zones (Waking Cloak devlog; Zelda ALttP
uses both); exit triggers as border cells with explicit destination markers
(the "Mario pipe" problem — direction alone can't say where you arrive);
constrained camera bounds double as secret-hiding (Hyper Light Drifter);
pacing = teach-test-twist with deliberate rest beats around landmarks
(Level Design Book, Pete Ellis).

## Decisions
- **Transition**: fade-to-black swap (~0.25s out/in). Zones have different
  palettes; fade hides the swap and the reboot. Slide variant reconsidered
  later, per-edge.
- **Exits are board data**: an exit cell on the border (a door gap in the
  painted wall). Player's step lands on it → MovementSystem emits
  `zone_exit`. Systems decide; the bridge swaps scenes.
- **Zones are room scenes**: same RoomEncounter base + new exports
  (zone_id, board_size) + marker children. EcsBoot keeps booting everything.
- **The player view persists**: PawnHero lives in main.tscn, outside the
  zone node — the swap never frees it. Health carries across travel via
  WorldState; death clears the carry (full heal, zone reloads).
- **World mode kills the room win-screen**: with a WorldGraph assigned and
  no explicit objective on the zone, _check_completion does nothing —
  clearing a zone is just quiet (objectives return for boss arenas).

## New files
- `scripts/world/zone_exit_marker.gd` — ZoneExitMarker (Marker2D):
  target_zone, target_entry. Zero logic.
- `scripts/world/zone_entry_marker.gd` — ZoneEntryMarker (Marker2D):
  entry_id. Zero logic.
- `scripts/data/world_graph.gd` — WorldGraph resource:
  zone_scene_by_id: Dictionary[StringName, PackedScene].
- `resources/world/world_graph.tres` — toybox_yard, chalk_gardens.
- `scripts/world/world_state.gd` — WorldState autoload (script-only):
  current_zone_id, last_entry_id, player_health_carry, taken_pickup_ids
  ("zone/PickupName" → true), opened_gate_ids (phase 2). No decisions,
  no saving yet (save-to-disk arrives with gates).
- `tools/paint_zone_tilemaps.gd` — paints both zone tilemaps (border walls
  with door gaps, interior walls, landmark tiles) from layout consts;
  saves objects/world/{zone}_tilemap.tscn. Rerun after layout edits.
- `scenes/zones/toybox_yard.tscn` — 20×11 per the drawn design: teach
  sequence recruit → pair ambush → armed pawn + spear pickup → backstep
  pawn corridor; clock-tower landmark; north door to the Gardens.
- `scenes/zones/chalk_gardens.tscn` — 24×12: three chalk lanes, inkwell
  rest-beat plaza, charging pawns in the lanes; south door back.
- `resources/movement/pawn_backstep.tres`, `resources/enemies/backstep_pawn.tres`
  — retreat-and-pounce pawn (fast steps, keeps distance 3).
- `resources/movement/pawn_charging.tres`, `resources/enemies/charging_pawn.tres`
  — two-square leaps only (±2 straight), the knight-offset machinery
  already supports multi-cell moves.
- `tests/zone_travel_runtime_test.gd` — boots the Toybox Yard through
  EcsBoot, walks the player onto the exit cell, asserts the zone_exit
  event carries the right destination; asserts per-zone grid bounds.

## Touched files
- `scripts/ecs/ecs_grid.gd` — `exit_by_cell: Dictionary` (cell → {zone, entry}).
- `scripts/ecs/ecs_boot.gd` — apply room board_size to grid.bounds; bake
  ZoneExitMarkers into exit_by_cell; skip pickups whose stable id is taken;
  cast gains pickup_name_by_entity.
- `scripts/ecs/systems/movement_system.gd` — player step lands on an exit
  cell → emit `zone_exit` {zone, entry}.
- `scripts/world/room_encounter.gd` — @export zone_id, board_size.
- `scripts/main.gd` — becomes the ZoneDirector: world_graph export, boot
  refactored into _boot_zone(entry), zone_exit → fade → teardown (fresh
  EcsWorld) → swap zone node → reboot → fade in. WorldState records
  travel + pickups; death keeps zone but clears health carry.
- `scenes/main.tscn` — FirstEncounter replaced by CurrentZone
  (toybox_yard), FadeLayer (CanvasLayer + ColorRect, editor-owned),
  world_graph assigned, PawnHero parked on the start entry cell.
- `project.godot` — WorldState autoload.
- `tests/run_tests.gd` — world graph validation: every zone instantiates,
  every exit targets a known zone AND an existing entry marker there,
  variant definitions validate.
- `tests/encounter_hud_runtime_test.gd` — expectations follow the Toybox
  Yard (5 enemies, new start message).

## Phase 2 next (gates + the loop)
GateComponent blocker entity, one-side opening, WorldState persistence +
save-to-disk, the Zone-3→1 one-way gate, Bookshelf Pass zone. Then the
world loop exists and zone authoring is pure content.
