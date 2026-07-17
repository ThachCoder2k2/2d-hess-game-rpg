# Glossary

Key terms, linked to where they live. Back to [[Home]].

- **Cell** — one grid square (32px). All gameplay position/collision is cell-based, not
  pixel/physics. Owned by [[Grid World]].
- **Reservation** — a claim on a destination cell made *before* a body finishes moving
  there, so no one else can enter. `move_reservations` in [[Grid World]]; drives the
  [[Combat and Telegraph|dodge]] and honest AI targeting.
- **Occupied vs reserved** — occupied = standing there now (`actor_by_cell`); reserved =
  moving there (`move_reservations`). Both block entry.
- **Telegraph** — the warning window where an enemy shows the cells it *will* hit, before
  it hits them. See [[Combat and Telegraph]].
- **Dodge** — stepping out of telegraphed cells before the strike resolves = no damage.
  The core skill. [[Combat and Telegraph]].
- **Attack token** — one room-wide permission slip; only one enemy may attack at a time.
  `EncounterDirector`. [[Combat and Telegraph]].
- **Intent** — one scored candidate action (attack/move/turn/pickup/wait) the AI weighs.
  `EnemyIntent`. [[Enemy AI]].
- **Context** — the per-decision snapshot the AI reasons over. `EnemyContext`. [[Enemy AI]].
- **decision_profile** — the runtime AI-weights object on an enemy, a `DecisionConfig`.
  [[Data Resources]].
- **Definition** — an `EnemyDefinition` `.tres`; everything that makes an enemy unique.
  [[Data Resources]].
- **Component** — a child node giving an enemy one capability (movement/health/equipment/
  brain). [[Enemy Composition]].
- **Marker** — an editor-draggable node whose `grid_cell` drives runtime placement
  (hero start / blocker / spawn). `GridMarker`. [[World and Rooms]].
- **Appearance** — the sprites + `AnimationPlayer` an actor owns directly
  (`MotionRoot/SpriteRoot/...`); mirrors state, never drives it. [[Presentation]].
- **Reserve → commit** — the two-phase move: `begin_move` (reserve) then `finish_move`
  (commit). [[Movement]].
