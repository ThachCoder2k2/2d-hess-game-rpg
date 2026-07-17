# Script Index

Every `.gd` file, one line each, linked to the concept note that explains it. Back to [[Home]].

## core
- `core/grid_world.gd` — the board, cells, reservations, A*. → [[Grid World]]

## actors
- `actors/grid_actor.gd` — base body, cell stepping + tween. → [[Movement]]
- `actors/pawn_hero.gd` — the player. → [[Player]]
- `actors/free_enemy.gd` — the AI engine (state machine + scoring). → [[Enemy AI]]

## entities
- `entities/enemy_actor.gd` — generic enemy host, delegates to components. → [[Enemy Composition]]

## components
- `components/enemy_component.gd` — component base (holds the host ref). → [[Enemy Composition]]
- `components/grid_movement_component.gd` — steps/legal moves. → [[Movement]]
- `components/health_component.gd` — damage + hurt/defeat feedback. → [[Enemy Composition]]
- `components/equipment_component.gd` — weapons + armed geometry. → [[Enemy Composition]]
- `components/enemy_brain_component.gd` — optional per-enemy DecisionConfig. → [[Enemy Composition]]

## ai
- `ai/attack_pattern.gd` — attack shape from offsets. → [[Data Resources]]
- `ai/enemy_context.gd` — the AI decision snapshot. → [[Enemy AI]]
- `ai/enemy_intent.gd` — one scored candidate action. → [[Enemy AI]]

## combat
- `combat/attack_profile.gd` — player weapon data. → [[Data Resources]]
- `combat/enemy_weapon.gd` — toy weapon data (LINE/FAN). → [[Data Resources]]
- `combat/encounter_director.gd` — the one attack token. → [[Combat and Telegraph]]

## data (Resource schemas)
- `data/enemy_definition.gd` — master enemy definition. → [[Data Resources]]
- `data/movement_config.gd` — directions + timing. → [[Data Resources]]
- `data/decision_config.gd` — AI weights. → [[Data Resources]] / [[Enemy AI]]
- `data/visual_definition.gd` — visual scene + colors. → [[Data Resources]]
- `data/difficulty_profile.gd` — global multipliers. → [[Data Resources]]
- `data/room_objective.gd` — win condition + text. → [[Data Resources]]

## world
- `world/grid_marker.gd` — editor drag-to-snap base. → [[World and Rooms]]
- `world/blocker_marker.gd` — a blocked cell (legacy; walls are painted solid tiles). → [[World and Rooms]]
- `world/pickup_spawn_point.gd` — pickup spawn (weapon). → [[World and Rooms]]
- `world/room_encounter.gd` — reads markers, spawns the room. → [[World and Rooms]]
- `world/weapon_pickup.gd` — droppable weapon item. → [[Combat and Telegraph]]
- `world/prototype_board.gd` — telegraph/hit/debug overlay. → [[Presentation]]
- `world/grid_lines_overlay.gd` — one-node grid draw. → [[Presentation]]

## visuals
- `visuals/pickup_visual.gd` — pickup sprite + glow. → [[Presentation]]
  (actors own their sprites directly — see `pawn_hero.gd` / `free_enemy.gd`)

## ui
- `ui/hud.gd` — courage/skill/status/result HUD. → [[Presentation]]

## entry
- `main.gd` — wires every system together. → [[World and Rooms]]
