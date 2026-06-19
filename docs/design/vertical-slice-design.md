# The Unbound Pawn - Godot 4 Vertical Slice Design

**Version:** 1.0  
**Engine:** Godot 4.6.3  
**Target:** Desktop prototype  
**Playtime:** 10-15 minutes

## 1. Slice Goal

Prove that one-cell real-time movement, adjacent sword combat, chess-pattern enemies, and child intervention are enjoyable together.

The slice begins after the pawn takes the sword. It contains a short tutorial room, one combat room, one intervention room, and a two-phase Knight Captain fight.

## 2. Success Criteria

- A new player understands cardinal one-cell movement without written instructions.
- Movement feels responsive despite grid commitment.
- The player predicts a Knight landing after no more than two failed reads.
- The player intentionally places a block to alter an attack.
- The player understands the child as a companion.
- A successful run takes 10-15 minutes.
- No unexplained hit or extra movement step occurs.

## 3. Project Structure

```text
The_Unbound_Pawn/
  project.godot
  assets/
    audio/
    fonts/
    sprites/
    tiles/
    ui/
  scenes/
    actors/
    combat/
    rooms/
    ui/
    world/
  scripts/
    actors/
    combat/
    core/
    interventions/
    world/
  tests/
```

## 4. Core Runtime Units

### GridWorld

Owns cell occupancy, walkability, coordinate conversion, and reservation during movement.

Public responsibilities:

- Convert between world positions and grid cells.
- Validate cardinal steps.
- Reserve and release destination cells.
- Query actors and obstacles in a cell.

It does not control animation, enemy decisions, or damage.

### GridActor

Base behavior for the hero and enemies.

- Tracks current and reserved cell.
- Executes a timed step between cell centers.
- Exposes facing direction.
- Emits step-started and step-finished signals.
- Refuses a second move while committed, except through the input buffer.

### PawnController

- Reads player input.
- Buffers one movement direction.
- Turns in place when Shift modifies a directional press.
- Requests movement from `GridActor`.
- Starts attacks through reusable attack profiles.
- Activates Pencil Thrust from the first skill slot.
- Requests child intervention targeting.
- Locks conflicting actions during commitment windows.

### CombatResolver

- Resolves cell-based attacks.
- Applies damage, stagger, invulnerability, and defeat.
- Emits events used by effects, audio, and UI.
- Keeps damage logic independent from sprite animation.

### EnemyBrain

Each enemy uses a small state machine:

```text
IDLE -> TELEGRAPH -> COMMIT -> RECOVER -> IDLE
```

The Black Pawn and Knight provide separate pattern strategies while sharing timing and damage infrastructure.

### InterventionController

- Tracks Believe charges.
- Enters a cell-targeting state.
- Validates placement.
- Spawns the child-hand presentation and block obstacle.
- Updates GridWorld occupancy.

### RoomController

- Activates a room when the hero enters.
- Closes exits during combat.
- Tracks active enemies.
- Opens exits and checkpoints on victory.
- Resets the room after defeat.

## 5. Scene Composition

### Hero

```text
PawnHero (Node2D)
  AnimatedSprite2D
  Shadow (Sprite2D)
  Hurtbox (Area2D)
  SwordOrigin (Marker2D)
  GridActor
  PawnController
```

### Enemy

```text
Enemy (Node2D)
  AnimatedSprite2D
  Shadow (Sprite2D)
  Hurtbox (Area2D)
  GridActor
  EnemyBrain
```

### Room

```text
Room (Node2D)
  Floor (TileMapLayer)
  Walls (TileMapLayer)
  DecorationBelow (TileMapLayer)
  DecorationAbove (TileMapLayer)
  Telegraphs (TileMapLayer)
  Actors (Node2D)
  Obstacles (Node2D)
  RoomController
```

## 6. Movement Contract

- Input selects one cardinal direction.
- `GridWorld` validates and reserves the destination.
- The actor animates to the destination over 0.18 seconds.
- The logical cell changes when movement begins, while occupancy remains reserved at both cells until completion.
- One buffered direction may execute immediately after completion.
- Releasing the direction clears held-repeat intent but not a discrete buffered press.
- Movement always ends on an integer pixel position.

This contract prevents actors from colliding midway through a step and prevents mysterious additional movement.

## 7. Combat Contract

- An attack profile defines range, recovery, impact delay, damage, and presentation color.
- Wooden Sword targets one adjacent cell based on facing.
- Pencil Thrust targets the first and second cells in a straight line.
- All target cells are captured when the attack begins.
- Damage resolves on the impact frame, not continuously.
- The hero cannot move during the initial attack commitment.
- Common enemies stagger briefly on hit.
- Repeated overlaps cannot deal duplicate damage during one attack.
- The hero has three Courage points and short post-hit invulnerability.

### Slice Loadout

- Wooden Sword: range 1, damage 1, 0.30-second recovery.
- Pencil Thrust: range 2, damage 1, 0.52-second recovery, 1.25-second skill cooldown.
- `Shift + direction`: turn in place.
- `Q`: Pencil Thrust.
- The skill cooldown is a slice-only balancing choice; final progression resources remain outside this milestone.

## 8. Enemy Behaviors

### Black Pawn

1. Generate legal cardinal destinations.
2. Face toward the selected destination.
3. If unarmed, threaten both forward diagonals relative to facing.
4. If armed, replace diagonals with the equipped weapon pattern.
5. Score attacking, repositioning, pursuing a weapon, and waiting.
6. Lock and telegraph attack cells after receiving the room attack token.
7. Recover before choosing again.

### Knight

1. Reposition through legal cardinal destinations.
2. Prefer cells that create an L-shaped threat on the hero.
3. Telegraph all legal L-shaped targets while unarmed.
4. Replace the L-shaped attack with an equipped weapon pattern while armed.
5. Share the room attack token with Pawns.

### Enemy Weapons

- Pencil Spear: two-cell straight attack.
- Ruler Blade: front cell plus forward diagonals.
- Pickups use a non-blocking item layer.
- An unarmed enemy may prioritize a reachable weapon.
- Enemies can also receive a weapon when spawned.

### Knight

1. Find legal L-shaped destinations near the hero.
2. Prefer a destination that threatens the hero without overlapping obstacles.
3. Mark the landing cell.
4. Animate the shadow toward the destination.
5. Remove the Knight from ground occupancy during the jump.
6. Damage the landing cell and four cardinal neighbors on impact.
7. Remain vulnerable during recovery.

### Knight Captain Boss

Phase one:

- Single jumps.
- Long recovery.
- One Black Pawn reinforcement at a time.

Phase two:

- Two linked jumps.
- Toy train crosses one marked row between jumps.
- The player must place a block to create a safe lane or limit the second landing.

## 9. Place Block

- The player presses Call when at least one Believe charge is available.
- Time slows to 35 percent while selecting a cell.
- Valid cells appear in blue within a five-cell range.
- Confirming consumes one charge.
- A child hand enters, places the block, and leaves.
- The block occupies one cell and stops movement and Knight landings.
- The block lasts until room completion or destruction.
- Cancelling selection consumes nothing.

The slow-motion selection preserves the real-time identity without making placement frustrating.

## 10. Room Flow

1. **Sword Yard:** movement, facing, and attack taught through breakable paper targets.
2. **Pawn Ambush:** two Black Pawns teach diagonal telegraphs.
3. **Helping Hand:** a Rook-like toy cart creates an unfair lane; the child introduces Place Block.
4. **Knight Arena:** two-phase boss and short ending conversation.

## 11. UI

- Courage: three marks at top left.
- Believe: two blue marks below Courage.
- Current intervention: block icon at bottom right.
- Boss health: centered at top only during the fight.
- Dialogue: lower screen band outside active combat.

## 12. Save and Reset

- The slice stores only room checkpoint and settings.
- Checkpoint data uses a small Resource or dictionary serialized to `user://`.
- Restarting a room restores its authored initial state.
- No inventory or campaign save system is required.

## 13. Error Handling

- Invalid movement produces a subtle bump animation, never silent input loss.
- Failed block placement keeps targeting active and explains invalidity through color and sound.
- Missing sprite animation falls back to idle without stopping logic.
- A room cannot complete while an enemy registered to it remains active.
- Debug overlays can display cell coordinates, occupancy, reservations, and AI state.

## 14. Testing

Automated tests should cover:

- Cardinal movement validation.
- Cell reservation and release.
- Buffered movement.
- Sword target calculation.
- Pawn diagonal attack cells.
- Knight destination generation.
- Block placement validation.
- Believe charge consumption.
- Room completion after the final enemy is defeated.

Manual tests should cover:

- Input feel at keyboard and controller.
- Pixel-perfect scaling at common 16:9 resolutions.
- Telegraph recognition.
- Camera framing.
- Boss completion without taking unavoidable damage.
- Restart behavior from every room.

## 15. Scope Boundary

The slice does not include Bishop, Rook, Queen, King, Draw Path, Turn Board, Gentle Nudge, nonlinear exploration, final art for every region, voice acting, or complete campaign saving.

Those systems begin only after the slice passes its success criteria.
