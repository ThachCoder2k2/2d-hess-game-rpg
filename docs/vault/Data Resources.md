# Data Resources

The `.tres` files that define **content**. Scripts here (`scripts/data/`, plus a few
in `combat/` and `ai/`) are just typed field-bags (`Resource` schemas). The actual
values live in `resources/*.tres`. This is why a new enemy/weapon needs **no new code**.

Back to [[Home]] · related: [[Enemy AI]] · [[Enemy Composition]] · [[Player]] · [[Glossary]]

## The schemas
| Script | Class | Holds |
|---|---|---|
| `data/enemy_definition.gd` | `EnemyDefinition` | the master: id, `piece_name`, role, health + refs to all below |
| `data/movement_config.gd` | `MovementConfig` | `allowed_directions`, step timing, preferred distance |
| `data/decision_config.gd` | `DecisionConfig` | the AI knobs — all scores, penalties, `flank_bonus`, `role_policy` (see [[Enemy AI]]) |
| `ai/attack_pattern.gd` | `AttackPattern` | attack shape as `cell_offsets` + `uses_facing` + `clip_to_board` |
| `data/visual_definition.gd` | `VisualDefinition` | which visual scene + telegraph/impact colors |
| `data/difficulty_profile.gd` | `DifficultyProfile` | global time multipliers |
| `data/room_objective.gd` | `RoomObjective` | win condition + start/clear/defeat text |
| `combat/attack_profile.gd` | `AttackProfile` | player weapon: range/damage/timing/texture |
| `combat/enemy_weapon.gd` | `EnemyWeapon` | toy weapon: shape (LINE/FAN), range, damage, tags, texture |

## How an enemy is composed from data
```
EnemyDefinition (resources/enemies/bishop_zoner.tres)
├─ movement       → resources/movement/bishop_diagonal.tres   (4 diagonal dirs)
├─ decision       → resources/decisions/bishop_sniper.tres    (sniper scores)
├─ unarmed_attack → resources/attacks/bishop_diagonal.tres    (diagonal beams)
├─ visual         → resources/visuals/bishop_compatibility.tres
└─ difficulty     → resources/difficulty/standard.tres (shared)
```
`FreeEnemy._apply_definition()` reads these into its runtime fields. Change the `.tres`,
change the enemy. See the `/new-enemy` workflow and the [[Enemy AI]] note.

## Flyweight / type-object pattern
Shared `.tres` are treated as **immutable at runtime**. When an instance needs to
mutate (e.g. a picked-up weapon), the code `duplicate(true)`s it first. Use `@export`
for Resource refs; `@onready`/`get_node` for node refs.
