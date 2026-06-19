# The Unbound Pawn - Enemy AI Behavior Plan

**Status:** First mixed-enemy implementation complete
**Engine:** Godot 4.6.3  
**Scope:** Common enemies and encounter coordination for the vertical slice

## 1. Goal

Create enemies that feel intelligent without becoming unpredictable or unfair.

Each chess piece must remain understandable:

- Its movement is one free cardinal cell at a time.
- Its unarmed attack geometry comes from chess.
- Its equipped toy weapon replaces the chess-shaped attack.
- Its current intention is visible before damage occurs.
- It reacts to the pawn's current committed cell, not hidden buffered input.
- Groups coordinate so the player solves a spatial problem instead of receiving overlapping unavoidable attacks.

## 2. Research Conclusions

### Telegraphing Is Part of the Decision System

*Into the Breach* exposes enemy intentions so the challenge comes from responding to a known spatial problem. That model supports faster decision-making because the player can begin planning before the enemy action resolves.

For this real-time game, an enemy decision therefore has three distinct stages:

```text
CHOOSE INTENT -> DISPLAY INTENT -> COMMIT INTENT
```

An enemy does not silently change targets after its telegraph begins.

### Hand-Authored Encounters Matter

The developers of *Enter the Gungeon* handcrafted and playtested individual rooms even though the larger dungeon was assembled procedurally. The room layout and environmental tools were treated as part of combat behavior.

The Unbound Pawn should likewise use authored rooms with explicit enemy roles, spawn cells, cover, and expected attack combinations.

### Utility Scoring Fits Small Tactical Choices

Utility AI scores available actions against the current situation and selects the highest-value action. It is useful here for choosing between a small set of legal chess actions without requiring a large behavior tree or opaque learned model.

Utility scoring will choose an intention. A finite-state machine will execute it.

### Coordination Must Be Explicit

Independent enemies can accidentally attack together and create impossible states. A room-level director should control how much immediate danger is allowed and which enemy may become the current aggressor.

## 3. Recommended Architecture

Use a hybrid of four layers.

### Layer 1: Chess Pattern

Pure functions define unarmed attack cells:

- `get_attack_options(context)`
- `get_threatened_cells(context)`

Cardinal movement candidates are shared by all common enemies. Chess-pattern functions contain no timing, animation, or target selection.

### Equipment Override

An equipped `EnemyWeapon` replaces the pattern's attack options:

```text
attack_pattern = equipped_weapon if equipped_weapon else chess_pattern
```

Enemies may receive equipment at spawn or score reachable pickups as utility actions during combat.

### Layer 2: Utility Decision

The enemy scores a small action set:

- Attack.
- Reposition.
- Advance.
- Wait.
- Retreat or recover, when supported by that piece.

Example Black Pawn scores:

```text
attack =
  100 if hero is on a forward diagonal
  -100 otherwise

advance =
  30
  + distance_reduction * 8
  + flanking_bonus
  - danger_at_destination * 20

pickup_weapon =
  55 if an unarmed enemy can reach a weapon soon
  + weapon_value
  - pickup_distance * 10

wait =
  15 if no attack token is available
  + spacing_bonus
```

Scores are deterministic unless two actions are nearly equal. Small controlled variation may then break ties.

### Layer 3: Intent State Machine

Every enemy executes through the same high-level states:

```text
OBSERVE
  -> REQUEST_ACTION
  -> TELEGRAPH
  -> COMMIT
  -> RECOVER
  -> OBSERVE
```

Special movement states such as the Knight's jump remain inside `COMMIT`.

### Layer 4: Encounter Director

The room owns:

- Attack tokens.
- Current danger budget.
- Enemy roles.
- Minimum delay between major attacks.
- Allowed simultaneous telegraphs.
- Difficulty modifiers.

The director does not select exact cells. It grants permission for an enemy's chosen aggressive action.

## 4. Fairness Rules

1. Enemies read the hero's current logical or reserved destination cell.
2. Enemies never read buffered input.
3. Once telegraphed, an attack's target cells are locked.
4. Common enemies cannot damage on the same frame they enter telegraph.
5. At least one legal response cell must exist when an authored encounter begins an attack combination.
6. Simultaneous threats use different visual or timing layers.
7. An off-screen enemy cannot begin an attack.
8. Recovery creates a punish window after every committed attack.
9. Difficulty changes timing and coordination, not hidden rules.

## 5. Player Position Model

The hero has three relevant cells:

- `current_cell`: committed logical position.
- `reserved_cell`: destination during an active step.
- `previous_cell`: last completed position.

Enemy targeting uses:

- `reserved_cell` if the hero is already moving.
- `current_cell` otherwise.

This is not future prediction. The player has visibly committed to the step, so responding to the reserved cell remains fair.

## 6. Threat Map

The room builds a short-lived threat map from:

- Active telegraphs.
- Enemy legal attacks.
- Obstacles.
- Other actors.
- Recent attacks.

Threat values:

| Value | Meaning |
|---:|---|
| 0 | Safe |
| 1 | Potential future threat |
| 2 | Telegraphing danger |
| 3 | Damage resolves now |

Enemies use potential threat to avoid stacking on identical cells. The player UI displays only telegraphing and resolving danger.

## 7. Attack Tokens

The vertical slice starts with:

- One common-enemy attack token.
- One movement token per enemy.
- A 0.20-second minimum separation between common attack commitments.

An enemy requests an attack token after choosing an aggressive action:

```text
if director.request_attack(self, threatened_cells):
    begin_telegraph()
else:
    choose reposition or wait
```

The token is released when recovery begins, not when the telegraph starts. This prevents another enemy from creating a second immediate strike before the first punish window opens.

Bosses use a separate authored schedule rather than common-enemy tokens.

## 8. Enemy Personalities

### Black Pawn - The Marcher

Purpose: teach diagonal attacks and committed forward motion.

Actions:

- Move one cardinal cell toward a useful attack position.
- Face the direction of its latest movement.
- Strike both forward diagonals relative to facing while unarmed.
- Replace diagonal strikes with the equipped weapon pattern while armed.
- Pursue a nearby weapon when its pickup score beats immediate positioning.
- Wait when an attack token is unavailable.

Personality:

- Patient.
- Predictable.
- Stronger in formation.
- Free to retreat or flank when utility favors it.

### Knight - The Hunter

Purpose: teach destination prediction and punish stationary play.

Actions:

- Move one cardinal cell while repositioning.
- Threaten L-shaped cells while unarmed.
- Leap-strike a locked L-shaped target cell during commit.
- Replace the leap strike with an equipped weapon attack while armed.
- Prefer movement cells that create an L-shaped threat on the next decision.
- Avoid repeating the same landing direction.
- Reposition when no useful attack landing exists.

Telegraph:

- Landing cell first.
- L-shaped travel cue second.
- Shadow moves before the body.

Personality:

- Mobile.
- Opportunistic.
- Vulnerable after landing.

### Bishop - The Controller

Purpose: divide rooms into diagonal zones.

Actions:

- Claim the longest useful diagonal.
- Reposition to gain a clearer lane.
- Prefer lanes that push the hero toward another obstacle, not directly onto unavoidable damage.

### Rook - The Charger

Purpose: convert walls and blocks into tactical resources.

Actions:

- Lock a row or column.
- Charge until blocked.
- Prefer destructible environmental targets when the hero is not aligned.

### Queen - The Coordinator

Purpose: combine known patterns.

The Queen uses authored phase logic with utility-selected variants. She does not use unrestricted common-enemy utility AI.

## 9. Godot Components

### `EnemyContext`

Immutable snapshot passed to decision code:

- Hero target cell.
- Self cell and facing.
- Occupied and blocked cells.
- Active threats.
- Attack-token availability.
- Nearby allies.
- Room bounds.

### `EnemyAction`

Resource or lightweight object:

- Action type.
- Score.
- Target cell.
- Threatened cells.
- Telegraph duration.
- Recovery duration.
- Token requirement.

### `ChessPattern`

Base resource with piece-specific implementations:

- `PawnPattern`
- `KnightPattern`
- Future Bishop and Rook patterns.

### `EnemyWeapon`

Resource defining:

- Display name and visual color.
- Relative threatened cells.
- Damage, telegraph, and recovery timing.
- Desired engagement distance.

Initial weapons:

- Pencil Spear: two-cell straight thrust.
- Ruler Blade: front cell plus two forward diagonals.

### `WeaponPickup`

Grid item that:

- Occupies an item layer without blocking movement.
- Can be assigned to an enemy at spawn.
- Can be collected by an unarmed enemy entering its cell.
- Disappears from the room after collection.

### `EnemyBrain`

Shared state machine:

- Builds context.
- Requests candidate actions from the pattern.
- Scores and selects one.
- Requests director permission.
- Executes telegraph, commit, and recovery.

### `EncounterDirector`

Room-level node:

- Registers enemies.
- Grants and releases attack tokens.
- Tracks danger budget.
- Rejects overlapping unfair threats.
- Pauses AI during dialogue, victory, or player defeat.

### `ThreatMap`

Room-level service:

- Combines active intents.
- Answers cell danger queries.
- Feeds board telegraph rendering.

## 10. Implementation Phases

### Phase 1: Refactor Existing Black Pawn

- Extract target-cell calculation.
- Add the shared intent states.
- Add `EnemyContext` and `EnemyAction`.
- Add shared cardinal move generation and deterministic utility scoring.
- Move Black Pawn attacks into a facing-aware `PawnPattern`.
- Preserve current timings and visuals.

Acceptance:

- Existing encounter feels unchanged.
- Unit tests cover every legal Black Pawn action.

### Phase 2: Encounter Director

- Add one common-enemy attack token.
- Add attack permission requests.
- Add minimum commitment spacing.
- Pause enemies when the hero is defeated.
- Add debug text for token owner and enemy states.

Acceptance:

- Two Black Pawns never resolve attacks simultaneously.
- A denied attacker waits or advances instead.

### Phase 3: Threat Map and Fairness Validator

- Track active and potential threat cells.
- Lock target cells at telegraph start.
- Validate at least one response cell for authored combinations.
- Add a debug overlay for threat values.

Acceptance:

- Telegraph cells never move after appearing.
- Automated scenarios reject impossible room states.

### Phase 4: Knight AI

- Implement L-shaped unarmed attack generation.
- Use shared cardinal movement to seek a useful attack position.
- Score target alignment, post-move threat, repetition, and distance.
- Add landing telegraph and recovery vulnerability.
- Integrate attack tokens.

Acceptance:

- Knight behavior is recognizable after two encounters.
- The same landing direction is not selected more than twice consecutively when alternatives exist.

### Phase 5: Authored Pawn Ambush

- Replace runtime room construction with a Godot room scene.
- Assign enemy roles and director settings in the Inspector.
- Tune formation bonuses and attack spacing.
- Add encounter completion and checkpoint hooks.

Acceptance:

- The room is beatable without taking unavoidable damage.
- Players identify diagonal threats before the second attack.

## 11. Automated Tests

- Black Pawn legal move and attack generation.
- Common enemies generate four cardinal movement candidates.
- Black Pawn diagonal attacks rotate with facing.
- Unarmed enemies score reachable weapons.
- Armed attacks replace, rather than combine with, chess attacks.
- Weapon pickups disappear after collection.
- Utility chooses attack when the hero is diagonal.
- Utility chooses advance when no attack exists.
- Telegraph targets remain locked after hero movement.
- Attack token prevents simultaneous common attacks.
- Token releases during recovery.
- Threat map combines overlapping cells.
- Fairness validator finds at least one response cell.
- Knight generates all valid L-shaped unarmed attack cells.
- Knight free movement rejects blocked and occupied cardinal cells.
- AI pauses during defeat and room completion.

## 12. Debug Tools

Toggleable development overlay:

- Enemy state above each piece.
- Selected action and utility score.
- Attack-token owner.
- Hero target cell.
- Potential, telegraphed, and resolving threat colors.
- Last five AI decisions in a small console.

These tools are development-only and disabled in exported builds.

## 13. Non-Goals

- Machine learning.
- NavMesh pathfinding.
- Reading uncommitted player input.
- Fully emergent group tactics.
- Random behavior that changes chess rules.
- Predicting several moves into the future.

## 14. Recommendation

Implement the hybrid pattern/utility/state-machine/director architecture.

It provides enough intelligence to react to room conditions, preserves the chess identity of every piece, keeps attacks explainable, and gives designers direct control over encounter fairness.

## 15. Research References

- [Game AI Pro - An Introduction to Utility Theory](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter09_An_Introduction_to_Utility_Theory.pdf)
- [Game AI Pro - Beyond the Kung-Fu Circle: A Flexible System for Managing NPC Attacks](https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter28_Beyond_the_Kung-Fu_Circle_A_Flexible_System_for_Managing_NPC_Attacks.pdf)
- [Game AI Pro 3 - A Reusable, Light-Weight Finite-State Machine](https://www.gameaipro.com/GameAIPro3/GameAIPro3_Chapter12_A_Reusable_Light-Weight_Finite-State_Machine.pdf)
- [Game AI Pro 3 - Choosing Effective Utility-Based Considerations](https://www.gameaipro.com/GameAIPro3/GameAIPro3_Chapter13_Choosing_Effective_Utility-Based_Considerations.pdf)
- [Into the Breach - official Steam page](https://store.steampowered.com/app/590380/Into_the_Breach/)
- [Enter the Gungeon - official Steam page](https://store.steampowered.com/app/311690/Enter_the_Gungeon/)
