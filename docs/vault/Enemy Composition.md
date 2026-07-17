# Enemy Composition

How a modern enemy is assembled: one generic host + component child nodes + a
[[Data Resources|definition]]. Composition over inheritance — a Pawn, Knight, and
Bishop are the *same* scene skeleton with different data.

Back to [[Home]] · related: [[Enemy AI]] · [[Data Resources]] · [[Movement]] · [[World and Rooms]]

## EnemyActor (the host)
**File:** `scripts/entities/enemy_actor.gd` · **Class:** `EnemyActor` (extends [[Enemy AI|FreeEnemy]])
A thin host. It keeps the FreeEnemy brain but **delegates** movement, health, and
equipment to child components, and resolves its AI profile:
- `try_step` → `GridMovementComponent`
- `take_damage` → `HealthComponent`
- `equip` / attack geometry → `EquipmentComponent`
- `_resolve_decision()` → an optional `DecisionConfig` on the brain node, else the
  definition's ([[Data Resources]]).
- `_get_configuration_warnings()` → the editor flags a missing definition/component
  (self-documenting scene).

## The four components (`scripts/components/`)
| Node | File | Owns |
|---|---|---|
| GridMovementComponent | `grid_movement_component.gd` | registration, steps, legal moves ([[Movement]]) |
| HealthComponent | `health_component.gd` | damage, hurt/defeat feedback (its own AnimationPlayer), token release + grid unregister on death |
| EquipmentComponent | `equipment_component.gd` | weapon equip/pickup, tag validation, armed attack geometry/damage/timing |
| EnemyBrainComponent | `enemy_brain_component.gd` | just an optional `DecisionConfig` export — the AI knob on the node |

All extend `enemy_component.gd` (`EnemyComponent`), which holds the `actor` ref via
`configure(host)` (dependency injection — the component never reaches up the tree).

## The scene skeleton (`objects/actors/*.tscn`)
```
EnemyActor  (script + EnemyDefinition .tres)
├─ TelegraphAura         (warning glow — [[Presentation]])
├─ MotionRoot/SpriteRoot (BodySprite, FacingArrow, WeaponPivot, HealthPips)
├─ AnimationPlayer       (idle/step/attack/hurt/telegraph clips)
├─ GridMovementComponent
├─ EnemyBrainComponent
├─ HealthComponent
└─ EquipmentComponent
```
`black_pawn.tscn`, `knight_enemy.tscn`, `bishop_enemy.tscn`, `enemy_base.tscn` are all
this, differing only by the assigned definition + sprite textures/animation values.

> Two dead components (`AttackComponent`, `EnemyDebugComponent`) were removed — their
> methods were never called; the attack lifecycle + debug live in [[Enemy AI|FreeEnemy]].
> Every remaining component does real work.
