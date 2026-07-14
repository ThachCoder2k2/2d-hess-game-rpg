# Enemy AI

**File:** `scripts/actors/free_enemy.gd` · **Class:** `FreeEnemy` (extends [[Movement|GridActor]])
The decision engine — the biggest, most important script (~530 lines). A state machine
that scores candidate actions and executes the best one. All weights come from a
[[Data Resources|DecisionConfig]] `.tres`, so behavior is data, not code.

Back to [[Home]] · related: [[Grid World]] · [[Combat and Telegraph]] · [[Data Resources]] · [[Enemy Composition]]

## Helper classes
- `scripts/ai/enemy_context.gd` — `EnemyContext`: the snapshot the AI reasons over
  (self cell, facing, **hero's reserved cell**, legal moves, item cells, is the token
  free). Reading the hero's *reserved* cell = honest targeting ([[Grid World]]).
- `scripts/ai/enemy_intent.gd` — `EnemyIntent`: one scored candidate (attack / move /
  turn / pickup / wait), with factory helpers.

## The state machine (`_process`)
5 states via `enum` + `match` (correct — a node state machine is over-engineering
under ~6 states):
```
OBSERVE   → _choose_action()   pick what to do
TELEGRAPH → _resolve_attack()  the strike lands (after the warning window)
COMMIT    → _resolve_attack()
RECOVER   → back to OBSERVE
DEFEATED  → stop
```
`state_time_left` counts down; the machine only thinks when it hits 0.
`observe_delay` (from data) sets the OBSERVE pause.

## How it decides (`_choose_action`)
1. `EnemyContext.capture(self)` — the snapshot.
2. `_build_intents(context)` — make scored candidates:
   - **attack** if hero is in my attack cells → `decision_profile.attack_score`
   - **move** to each legal cell → `_score_destination`
   - **turn / pickup / wait**
3. `_score_destination()` — the utility math, all from `decision_profile`
   ([[Data Resources|DecisionConfig]]): A* progress × `distance_score`, + future-threat,
   − preferred-distance penalty, − recent-cell penalty, + `get_positioning_bonus`
   (data-driven flank/axis — how a "flanker" role differs, no code branch).
4. `_select_intent()` picks the highest score. `_execute_intent()` acts.

## Attacking
If it picks ATTACK: request the token from the [[Combat and Telegraph|EncounterDirector]];
if granted, enter TELEGRAPH and emit `telegraph_started` (board shows danger cells);
next tick `_resolve_attack` damages only if the hero is still on a locked cell (the
dodge), then releases the token.

## Data → behavior (`_apply_definition`)
Reads the [[Data Resources|EnemyDefinition]] into runtime fields: health, movement
timing, `decision_profile`, unarmed `AttackPattern`, difficulty multipliers. This is
the seam where a `.tres` becomes a living enemy.

> Accepted tradeoff: this file concentrates sensing + scoring + movement + attack +
> damage. It stretches single-responsibility, but the AI is already data-driven, so
> splitting it buys churn, not capability. See [[Enemy Composition]].
