# The Unbound Pawn - Editor-First Entity Architecture Plan

**Status:** Phases 1-2 complete; Phase 3 movement and equipment extraction complete
**Date:** 2026-06-21
**Engine:** Godot 4.6.3

## Objective

Create an extendable initial structure where enemies, weapons, and encounters are visible and configurable in the Godot editor.

The editor owns composition, placement, and balancing data. Code owns reusable runtime rules.

No strict ECS framework will be introduced. Godot scenes provide entities, child nodes provide components, and Resources provide data.

## Architecture Rules

1. Core gameplay entities are saved `.tscn` scenes, not assembled entirely in `main.gd`.
2. Designer-facing values live in typed `.tres` Resources.
3. Components communicate through typed signals and small public methods.
4. Components do not search the whole Scene Tree for dependencies.
5. Piece definitions use composition before script inheritance.
6. Unique mechanics may add a strategy Resource or optional component.
7. A new ordinary enemy should require no new actor script.
8. Existing gameplay remains playable after every migration phase.

## Target Project Structure

```text
scenes/
  actors/
    enemy_base.tscn
    pawn_hero.tscn
    visuals/
      pawn_visual.tscn
      knight_visual.tscn
  components/
    grid_movement_component.tscn
    enemy_brain_component.tscn
    attack_component.tscn
    health_component.tscn
    equipment_component.tscn
    debug_component.tscn
  encounters/
    mixed_training_room.tscn
  items/
    weapon_pickup.tscn

resources/
  enemies/
    pawn_recruit.tres
    pawn_veteran.tres
    knight_tracker.tres
  attacks/
    pawn_diagonal.tres
    knight_leap.tres
  weapons/
    pencil_spear.tres
    ruler_blade.tres
  difficulty/
    recruit.tres
    standard.tres

scripts/
  entities/
    enemy_actor.gd
    encounter_room.gd
  components/
    grid_movement_component.gd
    enemy_brain_component.gd
    attack_component.gd
    health_component.gd
    equipment_component.gd
    debug_component.gd
  data/
    enemy_definition.gd
    movement_config.gd
    decision_config.gd
    visual_definition.gd
```

Godot-generated `.uid` files remain beside scripts.

## Enemy Base Scene

```text
EnemyActor
├── VisualRoot
├── GridMovementComponent
├── EnemyBrainComponent
├── AttackComponent
├── HealthComponent
├── EquipmentComponent
└── DebugComponent
```

### `EnemyActor`

Responsibilities:

- Holds the exported `EnemyDefinition`.
- Wires component references once during setup.
- Exposes stable signals to the encounter.
- Coordinates activation and defeat.
- Contains no piece-specific scoring or attack geometry.

Inspector fields:

- `definition: EnemyDefinition`
- `start_cell: Vector2i`
- `starting_weapon: EnemyWeapon`
- `starts_active: bool`
- `encounter_group: StringName`

### `GridMovementComponent`

- Registers with `GridWorld`.
- Owns current cell, facing, movement reservation, and tween.
- Exposes cardinal legal moves and path requests.
- Contains no enemy decision logic.

### `EnemyBrainComponent`

- Builds `EnemyContext`.
- Generates and scores intents from configured policies.
- Stores goal commitment and recent-cell memory.
- Requests permission from `EncounterDirector`.
- Sends selected intents to movement, attack, or equipment components.

### `AttackComponent`

- Reads the unarmed pattern or equipped weapon pattern.
- Locks threatened cells before telegraphing.
- Owns telegraph, commit, and recovery timing.
- Emits presentation-neutral attack signals.

### `HealthComponent`

- Owns health, hit response, invulnerability rules, and defeat state.
- Emits `damaged` and `defeated`.
- Does not unregister movement or remove visuals directly.

### `EquipmentComponent`

- Owns the current weapon.
- Validates allowed equipment.
- Collects a reserved pickup.
- Supplies the active attack configuration.

### `DebugComponent`

- Displays state, intent, score, route, and equipment.
- Observes component signals only.
- Can be removed or disabled without changing gameplay.

## Resource Contracts

### `EnemyDefinition`

```text
id
display_name
role
max_health
movement_config
decision_config
unarmed_attack
allowed_weapon_tags
weapon_preferences
visual_definition
difficulty_profile
```

### `MovementConfig`

```text
step_duration
move_recovery
allowed_directions
preferred_distance
path_memory_size
goal_commitment_decisions
```

### `DecisionConfig`

```text
observe_delay
attack_score
future_threat_score
pickup_score
turn_score
wait_score
recent_cell_penalty
role_policy
```

### `AttackPattern`

The existing pattern Resource is expanded rather than replaced:

```text
id
geometry_strategy
damage
telegraph_duration
recovery_duration
telegraph_style
requires_attack_token
locks_facing
```

Pawn, Knight, Bishop, and Rook geometry remain strategy Resources when fixed relative-cell data is insufficient.

### `VisualDefinition`

```text
visual_scene: PackedScene
telegraph_color
impact_color
weapon_anchor
hurt_animation
defeat_animation
```

The visual scene may contain `Sprite2D`, `AnimatedSprite2D`, `AnimationPlayer`, particles, and audio without changing AI code.

## Editor Workflow

### Create a Configured Variant

Example: Veteran Pawn.

1. Duplicate `pawn_recruit.tres` as `pawn_veteran.tres`.
2. Change health, timing, and decision weights in the Inspector.
3. Keep `pawn_diagonal.tres` or assign another attack.
4. Drag `enemy_base.tscn` into an encounter.
5. Assign `pawn_veteran.tres` to its `definition` field.

No new GDScript is required.

### Create a New Piece

Example: Bishop.

1. Create `bishop_controller.tres` using `BishopPattern`.
2. Create `bishop_standard.tres` using controller role data.
3. Create or assign `bishop_visual.tscn`.
4. Place `enemy_base.tscn` and assign the Bishop definition.
5. Add code only if the attack geometry requires a genuinely new strategy.

## Encounter Scene

```text
MixedTrainingRoom
├── GridWorld
├── PrototypeBoard
├── EncounterDirector
├── Hero
├── Geometry
│   └── Blockers
├── Enemies
│   ├── PawnRecruit
│   ├── PawnArmed
│   └── KnightTracker
├── Items
│   ├── PencilSpearPickup
│   └── RulerBladePickup
└── HUD
```

The enemies and items are visible before running the game. Their exported cells, definitions, equipment, and groups are editable in the Inspector.

`EncounterRoom` discovers only its owned child groups during `_ready()`, injects shared services, and activates them. It does not decide individual enemy configuration.

## Migration Plan

### Phase 1 - Typed Data Foundation

Create the Resource contracts and `.tres` files while current actor scripts remain active.

Deliverables:

- `EnemyDefinition`, `MovementConfig`, `DecisionConfig`, and `VisualDefinition`.
- Pawn Recruit, armed Pawn, and Tracker Knight definitions.
- Pencil Spear and Ruler Blade `.tres` resources replacing factory-only creation.
- Validation methods that report incomplete definitions in the editor.

Acceptance:

- Existing runtime behavior remains unchanged.
- Every current balancing value is visible in a Resource Inspector.
- Invalid definitions produce clear editor warnings.

### Phase 2 - Base Scene and Component Shell

Create `enemy_base.tscn` with real child component nodes.

The first pass may delegate execution to the existing `FreeEnemy` logic through a temporary adapter. This keeps behavior stable while scene ownership changes.

Acceptance:

- Enemy nodes and components are visible in the editor.
- The same base scene can load either Pawn or Knight definition data.
- Removing `DebugComponent` does not affect combat.

### Phase 3 - Incremental Responsibility Extraction

Extract one responsibility at a time:

1. Grid movement.
2. Equipment.
3. Health and defeat.
4. Attack execution.
5. Decision scoring.

After each extraction, run the complete behavior and attack regression suites.

Acceptance:

- `EnemyActor` only coordinates components.
- No component owns unrelated presentation and gameplay responsibilities.
- Pawn and Knight remain behaviorally equivalent to the current build.

### Phase 4 - Pawn and Knight Editor Scenes

Replace `BlackPawn.new()` and `KnightEnemy.new()` runtime construction with configured `enemy_base.tscn` instances.

Acceptance:

- Pawn and Knight are selectable and configurable before play.
- Starting weapons are Inspector assignments.
- Visual scenes can be swapped without changing AI.
- Piece subclass scripts are removed or retained only as thin compatibility adapters.

### Phase 5 - Authored Encounter Scene

Move the current board, blockers, hero, enemies, pickups, and HUD into `mixed_training_room.tscn`.

Acceptance:

- Opening the room shows its complete composition.
- Moving an enemy or item in the editor changes its runtime starting cell.
- `main.gd` becomes a scene/flow entry point rather than a room constructor.
- Restart and defeat reload the authored encounter correctly.

### Phase 6 - Extension Proof

Create one configuration-only Pawn variant and a Bishop placeholder definition.

Acceptance:

- The Pawn variant requires only a new `.tres` file.
- The Bishop placeholder can be placed and inspected before its unique attack strategy is implemented.
- A short contributor guide documents how to create enemies, weapons, and encounters.

## Migration Safety

- Never rewrite all components in one commit.
- Keep compatibility adapters until their replacement passes tests.
- Preserve current signals during migration.
- Do not delete the working runtime path until the authored scene passes visual verification.
- Commit each phase separately so regressions can be isolated.
- Avoid unrelated visual redesign during architecture migration.

## Verification

Every phase must pass:

- Existing automated behavior suite.
- Forced attack runtime test.
- 1,200-frame headless encounter simulation.
- Real-renderer capture for scene or visual changes.
- `git diff --check`.
- Editor inspection for missing Resources and broken node ownership.

## Definition of Done

The conversion is complete when:

1. The current encounter is fully visible in the editor before play.
2. Pawn and Knight use the same base enemy scene.
3. Their differences come from assigned Resources and visual scenes.
4. Components have one clear responsibility each.
5. Creating a normal enemy variant requires no new actor script.
6. Creating a unique piece requires only its unique strategy code.
7. Runtime behavior and attack stability remain unchanged.

## First Execution Batch

Implement Phase 1 only: typed data contracts and Resources.

Do not extract components or replace runtime spawning in the same batch. The first review point is a behavior-identical build whose important values are editable in Godot's Resource Inspector.
