# The Unbound Pawn - Enemy Behavior Bible

**Status:** Implementation-ready design proposal
**Engine:** Godot 4.6.3
**Combat model:** Real-time, one-cell grid movement with locked telegraphs

## 1. Purpose

Every enemy should ask the player a clear tactical question.

The player should be able to answer:

1. What is this piece trying to make me do?
2. Which cells will become dangerous?
3. What changed when it picked up a weapon?
4. When is it safe to punish?

Enemy intelligence is measured by the quality of the combat puzzle, not by how well it surprises or imitates a human.

## 2. Research Principles

### Enemies Need Distinct Roles

Combat archetypes create target-priority decisions. A group is interesting when each member changes the player's behavior in a different way: a rusher compresses space, a controller divides space, a support unit changes priorities, and a heavy reshapes terrain.

For this game, chess identity supplies those roles:

| Piece | Primary role | Player question |
|---|---|---|
| Pawn | Skirmisher | Can I approach without entering its diagonals? |
| Knight | Flanker | Which cells become unsafe two-by-one away? |
| Bishop | Controller | How do I cross or redirect a diagonal lane? |
| Rook | Charger | What can I place between us? |
| Queen | Commander | Which known threat must I solve first? |
| King | Rule manipulator | Which battlefield rule is currently active? |

### Tells Must Describe the Counter

An anticipation animation is not enough by itself. Telegraph shape, color, sound, and timing must communicate both the incoming threat and the expected response.

- Diagonal marks communicate Pawn or Bishop geometry.
- L-shaped landing marks communicate the Knight.
- Centered arrows communicate a Rook charge.
- Weapon colors override chess colors while equipped.
- Stronger attacks receive longer and more distinctive tells.

### Groups Need Coordination

Independent enemies frequently create unreadable attack overlap. Common enemies therefore share an attack token and near/far engagement roles.

- Near group: at most two enemies actively pressure the player.
- Far group: repositions, pursues equipment, guards routes, or performs visible idle behavior.
- Common attacks do not resolve simultaneously.
- Support or boss actions use a separate authored budget.

### Bosses Are Authored Tests

Regular AI must work in many rooms. A boss should use its arena deliberately and test mechanics already learned in the preceding region.

Boss phases follow:

```text
REVEAL -> TEACH -> TEST -> ESCALATE -> FINAL EXAM -> DEFEAT
```

Each phase adds one complication. Bosses gain new combinations, not merely more health or damage.

## 3. Shared Common-Enemy Model

### High-Level States

```text
OBSERVE
  -> SCORE ACTIONS
  -> REQUEST TOKEN
  -> TELEGRAPH
  -> COMMIT
  -> RECOVER
  -> OBSERVE
```

Movement, weapon collection, stagger, and defeat are shared modules.

### Shared Action Set

- Use unarmed chess attack.
- Use equipped weapon attack.
- Move toward an attack position.
- Move toward a weapon.
- Deny a weapon by occupying or collecting it.
- Increase spacing from nearby allies.
- Wait visibly.

### Shared Utility Inputs

- Can the current attack hit the committed hero cell?
- Will this move threaten the hero next decision?
- Is an attack token available?
- Is the enemy in the near or far group?
- Is a weapon reachable?
- Does the equipped weapon improve this matchup?
- Is the destination threatened by the player?
- Will the destination crowd another enemy?

### Difficulty Rules

Difficulty may change:

- Think delay.
- Telegraph duration.
- Recovery duration.
- Attack-token count.
- Quality of position scoring.

Difficulty must not change:

- Attack geometry.
- Locked target cells.
- Whether an enemy can move through obstacles.
- Damage without a new tell.

## 4. Pawn - The Skirmisher

### Purpose

The Pawn teaches facing, diagonal danger, and weapon denial.

### Free Movement

- Moves one cardinal cell.
- Prefers positions one or two cells from the player.
- Rotates its forward direction to match the latest step.
- Avoids stacking directly beside another Pawn unless forming a deliberate pincer.

### Unarmed Attack: Diagonal Jab

- Threat cells: forward-left and forward-right.
- Telegraph: two red corner-to-corner slashes.
- Commit: both cells resolve together.
- Recovery: long enough for one player step and attack.

### Utility Priorities

```text
attack_diagonal: 100 when hero is threatened
collect_weapon: 65 - distance * 10
create_diagonal_threat: 45
flank_hero: 30
increase_spacing: 20
wait: 10
```

### Counterplay

- Stand directly in front or behind while unarmed.
- Force it to rotate before attacking.
- Reach nearby weapons first.
- Punish after the double-diagonal commit.

### Variants

- Recruit: slow telegraph and long recovery.
- Veteran: scores flanks more strongly.
- Desperate Pawn: aggressively pursues dropped weapons at low health.

## 5. Knight - The Flanker

### Purpose

The Knight punishes stationary play and teaches non-adjacent threat reading.

### Free Movement

- Repositions one cardinal cell.
- Prefers destinations that create an L-shaped threat next decision.
- Avoids repeating the same approach axis more than twice when alternatives exist.
- Uses obstacles as protection because its unarmed threat ignores adjacent blockers.

### Unarmed Attack: L-Leap Strike

- Threat cells: all legal L offsets from the Knight.
- Telegraph stage 1: target cell outline.
- Telegraph stage 2: L-shaped travel cue and moving shadow.
- Commit: Knight leaps visually, strikes the locked target, and returns to or completes at an authored landing cell.
- Recovery: pronounced vulnerable crouch.

For common Knight enemies, the first implementation damages the locked L cell without changing logical occupancy. The Knight Captain boss later performs true landing displacement.

### Utility Priorities

```text
leap_strike: 100 when hero occupies an L cell
move_to_create_L: 70
collect_weapon: 50 - distance * 8
break_repetition: 25
maintain_mid_range: 20
```

### Counterplay

- Keep changing relative geometry.
- Move adjacent when the Knight is unarmed.
- Punish its landing recovery.
- Use blocks to reduce useful reposition cells.

### Variants

- Tracker: emphasizes repeated pressure on the hero.
- Guard Knight: stays near a weapon or objective.
- Knight Captain: boss with chained landings and train hazards.

## 6. Bishop - The Controller

### Purpose

The Bishop divides rooms and forces route planning.

### Free Movement

- Repositions one cardinal cell.
- Prefers distance of four to seven cells.
- Seeks cells with long unobstructed diagonals.
- Retreats when the player becomes adjacent.

### Unarmed Attack: Diagonal Claim

- Selects one or two diagonal rays.
- Telegraph begins near the Bishop and grows outward cell by cell.
- Commit resolves the entire locked ray.
- Obstacles stop the ray unless a specific magical variant says otherwise.

### Utility Priorities

```text
claim_diagonal_hitting_hero: 100
claim_escape_route: 65
gain_long_diagonal: 55
retreat_from_adjacent: 70
collect_ranged_weapon: 35
wait: 10
```

### Counterplay

- Cross before the ray locks.
- Use blocks and room geometry to shorten the lane.
- Approach cardinally.
- Attack after a long channel.

### Variants

- Mirror Bishop: attack reflects once from a marked mirror.
- Torn Bishop: claims broken page gaps that the player must bridge.
- Bishop of Order: boss that rotates or closes diagonal routes.

## 7. Rook - The Charger

### Purpose

The Rook turns obstacles and child-placed blocks into tactical resources.

### Free Movement

- Repositions one cardinal cell slowly.
- Prefers row or column alignment with the player.
- Maintains at least three cells of charge distance when possible.
- Scores destructible objects as secondary targets.

### Unarmed Attack: Line Charge

- Threat cells: locked row or column until the first solid blocker.
- Telegraph: directional arrows fill outward from the Rook.
- Commit: Rook travels through the line and stops at the blocker or final valid cell.
- Collision with a block destroys or damages it and stuns the Rook.

### Utility Priorities

```text
charge_hitting_hero: 100
charge_breaking_useful_wall: 55
align_row_or_column: 65
create_charge_distance: 45
collect_weapon: 20
```

### Counterplay

- Leave the locked line.
- Place a block in its path.
- Bait it into destroying useful walls.
- Punish the collision stun.

### Variants

- Wooden Rook: breaks after repeated obstacle collisions.
- Iron Rook: armored from the front during charge.
- Iron Rook boss: rotates room sections and creates its own charge corridors.

## 8. Queen - The Commander

### Purpose

The Queen is an authored boss and battlefield coordinator. She tests prioritization across previously learned attack shapes.

### Movement

- Moves one cardinal cell during neutral repositioning.
- Uses authored phase transitions for larger relocations.
- Prefers central command cells with several visible lanes.
- Avoids direct pursuit behavior.

### Unarmed Maneuvers

The Queen does not fire unrestricted chess rays. She selects readable maneuvers:

- Royal Line: one straight lane.
- Royal Diagonal: two opposite diagonal lanes.
- Command Mark: orders one common enemy to reposition.
- Seize Toy: pulls or destroys one loose weapon.
- Tear the Drawing: removes a child-created object after a long warning.

### Phase Structure

#### Phase 1 - Authority

- Alternates Royal Line and Royal Diagonal.
- Teaches the Queen's larger telegraph language.

#### Phase 2 - Isolation

- Adds Command Mark and Seize Toy.
- Common enemies receive movement orders but still obey attack tokens.

#### Phase 3 - Partnership Test

- Removes one intervention temporarily.
- Combines one Queen lane with one common-enemy threat.
- Guarantees at least one legal response cell.

### Counterplay

- Read lane family before acting.
- Protect useful toys and interventions.
- Defeat or reposition commanded enemies.
- Attack during command recovery, not during lane commits.

## 9. King - The Rule Manipulator

### Purpose

The King is the final boss. He attacks the game's rules rather than simply producing larger patterns.

### Movement

- Moves one cardinal cell during ordinary pursuit.
- Uses one-cell defensive steps to stay near the Rule Engine.
- Cannot freely teleport.

### Rule Maneuvers

- Lock Direction: temporarily marks one movement direction as forbidden after a warning.
- Restore Formation: returns defeated toy Pawns as harmless blockers before later activating them.
- Reverse Color: swaps safe and danger presentation only after a full-screen, unmistakable cue; used once.
- Close the Box: disables child interventions for the final phase.
- King's Reach: threatens the eight adjacent cells, matching the King's chess neighborhood.

### Phase Structure

#### Phase 1 - False Weakness

- King uses King's Reach and retreats around the Rule Engine.
- Player learns that the machine, not the body, controls the fight.

#### Phase 2 - Selective Rules

- Adds Lock Direction and blocker formations.
- Rules are always displayed physically on cards or board marks.

#### Phase 3 - No Hand Above

- Close the Box disables interventions.
- The pawn restores free directions through authored story beats.
- Final opening requires the pawn's first self-directed diagonal step.

### Counterplay

- Attack the Rule Engine during King recovery.
- Read physical rule cards before moving.
- Use freed directions to escape King's Reach.
- The final victory is a mechanic-driven story action, not a health sponge.

## 10. Equipped Weapon Behavior

Equipment replaces the unarmed attack but does not erase piece personality.

- Pawn still flanks and pursues nearby tools.
- Knight still prefers unusual angles and mid-range positions.
- Bishop still seeks distance and clear lanes.
- Rook still values alignment and obstacles.

### Pencil Spear

- Attack: two-cell straight thrust.
- Preferred distance: two cells.
- Counter: sidestep or close adjacent.

### Ruler Blade

- Attack: front cell plus both forward diagonals.
- Preferred distance: one cell.
- Counter: retreat or move directly behind.

### Marble Launcher - Future

- Attack: slow projectile traveling along one straight lane.
- Preferred distance: four to six cells.
- Counter: use blocks or leave the lane.

### Wind-Up Hammer - Future

- Attack: one-cell strike plus four cardinal impact cells.
- Preferred distance: adjacent.
- Counter: leave the impact cross during its long wind-up.

## 11. Pickup Decisions

An unarmed enemy considers a weapon when:

- It is reachable.
- No immediate unarmed attack is available.
- The weapon supports its preferred distance.
- Another enemy is not already committed to the same pickup.

Pickup reservation prevents several enemies from chasing one item.

Enemies abandon a pickup when:

- The player threatens its cell.
- A higher-priority attack opens.
- The path becomes blocked.
- Another enemy reserves it first.

## 12. Encounter Composition

### Teaching Encounters

| Encounter | Composition | Lesson |
|---|---|---|
| Diagonal Lesson | 2 unarmed Pawns | Facing and diagonal safety |
| Toy Race | 1 Pawn, 1 loose Spear | Weapon denial |
| Crooked Threat | 1 Knight | L-shaped reading |
| Mixed Angles | 1 Pawn, 1 Knight | Threat prioritization |
| Armed Choice | 2 enemies, 2 different weapons | Weapon replacement |

### Composition Rules

- Introduce one new unarmed geometry at a time.
- Introduce a weapon on a familiar enemy before combining it with a new piece.
- Do not introduce a new piece and new weapon in the same first encounter.
- Limit the near group to two common enemies.
- Every combination receives an automated response-cell validation test.

## 13. Implementation Order

1. Harden shared free-enemy context and utility scoring.
2. Add weapon pickup reservations.
3. Complete Pawn role and variants.
4. Complete Knight attack presentation and repetition memory.
5. Add Bishop rays and obstacle tracing.
6. Add Rook charge path and collision results.
7. Build Knight Captain as the first authored boss.
8. Build Queen after all common patterns are proven.
9. Build King only after intervention and Rule Engine systems exist.

## 14. Testing Matrix

Each enemy requires tests for:

- Every attack cell at room edges.
- Rotation through all four facings.
- Locked telegraph targets.
- Attack-token denial and release.
- Weapon replacement.
- Weapon pickup reservation.
- Obstacle interaction.
- Recovery vulnerability.
- Pause on dialogue, victory, and player defeat.
- At least one legal response cell in authored combinations.

Boss tests additionally cover:

- Phase transition health thresholds.
- Maneuver cooldowns.
- Intervention availability.
- Arena-state restoration after retry.
- No phase can loop indefinitely.

## 15. Research References

- [Enemy design and enemy AI for melee combat systems](https://www.gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems)
- [Enemy Attacks and Telegraphing](https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing)
- [Enemy AI Design in Tom Clancy's The Division](https://www.gamedeveloper.com/design/enemy-ai-design-in-tom-clancy-s-the-division)
- [Open-world Enemy AI in Mafia III](https://www.gameaipro.com/GameAIProOnlineEdition2021/GameAIProOnlineEdition2021_Chapter16_Open-world_Enemy_AI_in_Mafia_III.pdf)
- [Boss Battle Design and Structure](https://www.gamedeveloper.com/design/boss-battle-design-and-structure)
- [Designing for Difficulty: Readability in ARPGs](https://www.gamedeveloper.com/game-platforms/designing-for-difficulty-readability-in-arpgs)
- [Psychonauts 2 modular boss maneuvers](https://www.gamedeveloper.com/marketing/using-a-modular-system-of-maneuvers-to-design-i-psychonauts-2-i-s-boss-fights-in-a-hurry)
- [Game AI Pro - An Introduction to Utility Theory](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter09_An_Introduction_to_Utility_Theory.pdf)
- [Game AI Pro - Managing NPC Attacks](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter28_Beyond_the_Kung-Fu_Circle_A_Flexible_System_for_Managing_NPC_Attacks.pdf)

## 16. Recommendation

Build enemies as modular role packages:

```text
shared free movement
+ piece positioning personality
+ chess-shaped unarmed attack
+ optional weapon replacement
+ room-level coordination
```

This preserves recognizable chess identity while supporting the child's playground fantasy, dynamic weapon stories, fair group combat, and practical Godot implementation.

## 17. Shared Timing Specification

All values are starting targets for playtesting at the current 0.18-second player step.

| Event | Recruit | Standard | Elite | Notes |
|---|---:|---:|---:|---|
| Observe delay | 0.60 s | 0.42 s | 0.28 s | Time before choosing another action |
| Basic move | 0.22 s | 0.20 s | 0.18 s | Player remains slightly faster than most enemies |
| Short telegraph | 0.75 s | 0.60 s | 0.48 s | One-cell or simple shape |
| Long telegraph | 1.00 s | 0.82 s | 0.68 s | Lane, leap, or area attack |
| Basic recovery | 0.70 s | 0.52 s | 0.42 s | Guaranteed punish opportunity |
| Heavy recovery | 1.00 s | 0.82 s | 0.65 s | Charge, leap, or terrain interaction |
| Hit stagger | 0.28 s | 0.22 s | 0.16 s | Elites remain responsive but not immune |

Timing rules:

- A telegraph must last at least two player step durations for a new attack pattern.
- Familiar late-game patterns may approach 0.48 seconds but never resolve instantly.
- Recovery begins after damage resolution and token release.
- Hit stagger does not cancel a locked attack after its final 0.12-second commit window begins.
- Slow motion, accessibility settings, and difficulty modifiers scale telegraph timers consistently.

## 18. Utility Evaluation Contract

### Normalized Inputs

Each consideration returns a value from `0.0` to `1.0`:

- `can_hit_now`
- `creates_threat_next`
- `distance_fit`
- `weapon_value`
- `pickup_reachability`
- `ally_spacing`
- `destination_safety`
- `token_available`
- `role_fit`
- `repetition_penalty`

### Score Formula

```text
score = base_score
      + sum(weight * consideration)
      - hard_penalties
```

Hard penalties reject an action rather than merely lowering preference:

- Destination is blocked or reserved.
- Attack token is required but unavailable.
- Attack target is off-screen.
- Pickup is reserved by another enemy.
- Action would create a validated no-response state.

### Tie-Breaking

When scores are within five points:

1. Prefer the action not used last time.
2. Prefer the action with shorter commitment.
3. Prefer the action that improves ally spacing.
4. Use deterministic seeded variation only after the first three rules tie.

The seed comes from room seed plus enemy spawn index. Reloading a checkpoint therefore produces learnable behavior while still allowing authored room variation.

### Decision Memory

Each enemy stores:

- Last three chosen actions.
- Last two movement axes.
- Last threatened cells.
- Last pursued weapon.
- Time since last successful attack.
- Time spent in near and far groups.

Memory prevents mechanical loops without giving enemies hidden knowledge.

## 19. Godot Data Contracts

### `EnemyArchetype` Resource

```gdscript
class_name EnemyArchetype
extends Resource

@export var id: StringName
@export var role: StringName
@export var max_health: int
@export var move_duration: float
@export var observe_delay: float
@export var telegraph_duration: float
@export var recovery_duration: float
@export var preferred_distance: Vector2i
@export var utility_weights: Dictionary
@export var unarmed_pattern: AttackPattern
@export var allowed_weapons: Array[StringName]
```

### `AttackPattern` Resource

```gdscript
class_name AttackPattern
extends Resource

@export var id: StringName
@export var relative_cells: Array[Vector2i]
@export var damage: int
@export var telegraph_style: StringName
@export var locks_facing: bool
@export var stops_at_obstacle: bool
@export var requires_attack_token: bool
```

Ray and charge patterns use a generator strategy instead of storing every cell.

### `EnemyContext` Snapshot

```gdscript
class_name EnemyContext
extends RefCounted

var self_cell: Vector2i
var facing: Vector2i
var hero_cell: Vector2i
var hero_reserved_cell: Vector2i
var legal_moves: Array[Vector2i]
var nearby_allies: Array[Node]
var reachable_weapons: Array[Node]
var threatened_cells: Dictionary
var token_available: bool
var near_group_open: bool
```

The context is rebuilt at `OBSERVE`. It remains immutable while scoring so every candidate sees the same world state.

### `EnemyIntent`

```gdscript
class_name EnemyIntent
extends RefCounted

var action_id: StringName
var score: float
var destination: Vector2i
var target_cells: Array[Vector2i]
var reserved_pickup: Node
var required_token: StringName
```

The selected intent is locked before `TELEGRAPH`. Presentation reads the intent; it does not recompute gameplay cells.

## 20. Piece State Tables

### Pawn State Table

| Current state | Condition | Next state | Action |
|---|---|---|---|
| Observe | Hero in unarmed diagonals and token granted | Telegraph | Lock both diagonal cells |
| Observe | Armed and hero in weapon pattern | Telegraph | Lock weapon cells |
| Observe | Valuable weapon reachable | Reposition | Reserve pickup and step toward it |
| Observe | Move creates next-turn diagonal | Reposition | Step and rotate facing |
| Observe | No useful action | Wait | Face hero without moving |
| Telegraph | Timer finishes | Commit | Resolve locked cells |
| Commit | Damage resolved | Recover | Release attack token |
| Recover | Timer finishes | Observe | Rebuild context |

Pawn-specific safety:

- Two Pawns cannot reserve the same pincer destination.
- A Pawn does not rotate after its telegraph locks.
- A Pawn standing on a weapon collects it before evaluating attacks.

### Knight State Table

| Current state | Condition | Next state | Action |
|---|---|---|---|
| Observe | Hero in L cell and token granted | Telegraph | Lock target and L path cue |
| Observe | Cardinal move creates L threat | Reposition | Step toward best attack geometry |
| Observe | Repeated axis detected | Reposition | Prefer alternate axis |
| Observe | Weapon improves immediate score | Reposition | Reserve and pursue pickup |
| Telegraph | First 55% elapsed | Telegraph | Move shadow along L cue |
| Telegraph | Timer finishes | Commit | Perform leap-strike presentation |
| Commit | Impact finishes | Recover | Enter vulnerable crouch |
| Recover | Timer finishes | Observe | Rebuild context |

Knight-specific safety:

- Common Knight logical occupancy does not change during the attack.
- Knight Captain landing cells must be empty at lock time and commit time.
- If a boss landing becomes invalid, use the authored fallback cell rather than retargeting the player.

### Bishop State Table

| Current state | Condition | Next state | Action |
|---|---|---|---|
| Observe | Diagonal ray reaches hero | Telegraph | Lock shortest useful ray |
| Observe | Ray blocks escape route | Telegraph | Lock control ray if budget allows |
| Observe | Hero adjacent | Reposition | Retreat to a long diagonal |
| Observe | No useful ray | Reposition | Maximize diagonal visibility |
| Telegraph | Channel grows | Telegraph | Reveal cells from near to far |
| Telegraph | Timer finishes | Commit | Resolve entire locked ray |
| Commit | Ray fades | Recover | Expose Bishop to attack |

Bishop-specific safety:

- Ray cells stop at the first solid obstacle.
- Reflected rays preview both original and reflected segments before commit.
- A Bishop control ray cannot combine with another controller to remove every cardinal exit.

### Rook State Table

| Current state | Condition | Next state | Action |
|---|---|---|---|
| Observe | Hero aligned with charge space | Telegraph | Lock charge line |
| Observe | Useful destructible object aligned | Telegraph | Lock demolition line |
| Observe | Too close for charge | Reposition | Create at least three-cell spacing |
| Observe | Not aligned | Reposition | Seek row or column alignment |
| Telegraph | Timer finishes | Commit | Travel through locked cells |
| Commit | Hits hero | Recover | Stop one cell beyond impact if valid |
| Commit | Hits block | Stunned | Damage block and stop before it |
| Stunned | Timer finishes | Observe | Rebuild context with reduced defense |

Rook-specific safety:

- Charge never turns after commit.
- Dynamic obstacles added after lock stop the charge safely.
- The final stop cell is reserved for the entire commit.

## 21. Weapon Compatibility Matrix

Scores express preference, not permission.

| Piece | Pencil Spear | Ruler Blade | Marble Launcher | Wind-Up Hammer |
|---|---:|---:|---:|---:|
| Pawn | 90 | 80 | 55 | 60 |
| Knight | 70 | 85 | 60 | 75 |
| Bishop | 45 | 35 | 95 | 30 |
| Rook | 50 | 65 | 40 | 90 |

Preference modifies `weapon_value`:

```text
weapon_value = compatibility / 100
```

Behavior after pickup:

- Pawn with Spear holds two-cell spacing and circles for straight alignment.
- Pawn with Ruler closes distance and attempts side approaches.
- Knight with Ruler seeks unusual adjacent angles instead of L geometry.
- Knight with Spear maintains middle distance and changes axes frequently.
- Bishop with Launcher preserves long distance and uses obstacles as cover.
- Rook with Hammer approaches slowly and creates impact-cross pressure.

An enemy keeps a weapon until defeated or an authored disarm event occurs. Common enemies do not constantly swap equipment because repeated pattern changes reduce readability.

## 22. Boss Maneuver Data

Bosses use modular maneuvers with explicit telegraph, commit, and recovery segments.

### Knight Captain

| Maneuver | Telegraph | Commit | Recovery | Phase |
|---|---:|---:|---:|---|
| Single Landing | 0.85 s | 0.18 s | 0.75 s | 1-3 |
| Twin Landing | 0.75 s each | 0.18 s each | 0.90 s | 2-3 |
| Track Feint | 0.95 s | 0.20 s | 0.65 s | 2-3 |
| Train Crossing | 1.10 s | 0.80 s hazard | 0.60 s | 2-3 |

Phase rules:

- Phase 1 teaches one locked landing.
- Phase 2 adds a second landing only after the first resolves.
- Phase 3 combines one landing with one train row, never two overlapping train rows.
- Place Block always creates at least one meaningful response.

### Bishop of Order

| Maneuver | Telegraph | Commit | Recovery | Phase |
|---|---:|---:|---:|---|
| Single Sermon | 0.90 s | 0.25 s | 0.70 s | 1-3 |
| Mirror Verse | 1.15 s | 0.30 s | 0.85 s | 2-3 |
| Fold the Page | 1.00 s | Arena change | 0.65 s | 2-3 |
| Torn Passage | 1.20 s | Gap opens | 0.80 s | 3 |

### Iron Rook

| Maneuver | Telegraph | Commit | Recovery | Phase |
|---|---:|---:|---:|---|
| Straight Decree | 0.90 s | Variable charge | 0.85 s | 1-3 |
| Breach Wall | 1.05 s | Variable charge | 1.10 s stun | 1-3 |
| Cross Corridor | 1.20 s | Two sequential charges | 0.95 s | 2-3 |
| Rotate Fortress | 1.30 s | Arena rotation | 0.70 s | 3 |

### Queen

| Maneuver | Telegraph | Commit | Recovery | Phase |
|---|---:|---:|---:|---|
| Royal Line | 0.75 s | 0.25 s | 0.60 s | 1-3 |
| Royal Diagonal | 0.90 s | 0.25 s | 0.70 s | 1-3 |
| Command Mark | 1.00 s | Ally repositions | 0.55 s | 2-3 |
| Seize Toy | 1.10 s | Pull or destroy | 0.80 s | 2-3 |
| Tear Drawing | 1.30 s | Disable intervention | 1.00 s | 3 |

Queen selection rules:

- Never repeat the same lane family three times.
- Command Mark cannot order an ally into a resolving danger cell.
- Seize Toy targets only visible, unreserved toys.
- Phase 3 combinations pass response-cell validation before telegraphing.

### Black King

| Maneuver | Telegraph | Commit | Recovery | Phase |
|---|---:|---:|---:|---|
| King's Reach | 0.70 s | 0.22 s | 0.55 s | 1-3 |
| Lock Direction | 1.20 s | Rule duration 4 s | 0.75 s | 2-3 |
| Restore Formation | 1.30 s | Spawn blockers | 0.90 s | 2 |
| Reverse Color | 1.80 s | Rule duration 6 s | 1.00 s | 2, once |
| Close the Box | Story beat | Persistent phase rule | N/A | 3 |

King selection rules:

- Only one global rule modifier may be active at a time.
- Rule cards appear before affected input is disabled.
- King's Reach cannot begin until the player has at least one legal exit.
- The final diagonal step is authored and cannot trigger accidentally earlier.

## 23. Encounter Recipes

### Recipe A - Facing Lesson

Room: open 10x7 grid.

- Two Recruit Pawns.
- No weapons.
- One attack token.
- Pawns start on opposite horizontal sides.

Expected learning:

- Pawn facing changes diagonal geometry.
- Directly forward cells are safe while unarmed.

### Recipe B - Toy Race

Room: 12x7 grid with a central block cluster.

- One Veteran Pawn.
- One Pencil Spear equidistant from hero and Pawn, but reachable by different routes.
- One attack token.

Expected learning:

- A loose weapon is an objective.
- The player's route choice changes the enemy's future attack.

### Recipe C - Crooked Threat

Room: 12x8 grid with two low block islands.

- One Tracker Knight.
- No weapon.
- Long first telegraph.

Expected learning:

- L cells remain dangerous despite adjacent blockers.
- Moving adjacent breaks immediate Knight geometry.

### Recipe D - Mixed Angles

Room: 14x8 grid with one central corridor.

- One Veteran Pawn.
- One Tracker Knight.
- One Ruler Blade near the far group.
- One attack token and two movement permissions.

Expected learning:

- Prioritize the currently armed or aligned threat.
- Use attack-token rhythm to find punish windows.

### Recipe E - Controller Introduction

Room: storybook spread with two diagonal folds.

- One Bishop.
- One Recruit Pawn already familiar to the player.
- Bishop receives a separate control budget but cannot resolve with the Pawn.

Expected learning:

- Bishop shapes routes while Pawn pressures locally.
- Obstacles shorten diagonal rays.

## 24. Debug and Telemetry Specification

### Enemy Overlay

Development toggle displays:

- State.
- Role group: near or far.
- Facing.
- Equipped weapon.
- Selected action and final score.
- Reserved destination or pickup.
- Token ownership.

### Decision Log

Store the last 100 decisions:

```text
timestamp
enemy_id
context_hash
candidate_actions
selected_action
selected_score
rejection_reason
```

### Playtest Metrics

Track per encounter:

- Hits received by attack type.
- Percentage of attacks avoided after telegraph.
- Average enemy recovery punished.
- Weapons collected by player versus enemies.
- Time each enemy spends in near and far groups.
- Repeated-action frequency.
- Deaths with zero legal response cells.

Target thresholds:

- At least 80% of received hits are understood by the player immediately afterward.
- Zero deaths occur from validated no-response combinations.
- A new enemy's core pattern is correctly described after two encounters.
- Common enemies repeat one action no more than twice when a viable alternative exists.
- Players notice weapon replacement before the armed enemy's second attack.

## 25. Production Acceptance Gates

An enemy type is ready for content production only when:

1. Its unarmed role is recognizable without UI text.
2. All four facing rotations produce correct cells.
3. Weapon replacement works with every allowed weapon.
4. Telegraph targets remain locked through player movement.
5. It respects attack and pickup reservations.
6. It exposes a reliable punish window.
7. Its debug overlay explains every chosen action.
8. Tests cover room edges, obstacles, defeat, and retry.
9. At least three authored encounters demonstrate different combinations.
10. A five-minute playtest produces no unexplained damage.
