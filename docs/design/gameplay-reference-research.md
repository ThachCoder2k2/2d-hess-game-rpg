# Gameplay Reference Research - 2026-09-29

Purpose: collect recent and relevant gameplay lessons for *The Unbound Pawn*.
The goal is not to copy these games, but to choose useful design principles for
a real-time, grid-based, top-down chess action adventure.

## Researched References

| Game | Why It Matters | Lesson For This Project |
|---|---|---|
| *Guidus Zero* | Real-time grid-based action roguelike with four-direction grid movement and enemy telegraphs | Proves our core idea can feel fast if attacks are readable and movement timing is sharp |
| *Shogun Showdown* | Small-grid tactical combat built around positioning, attack timing, upgrades, and combos | The player should always be thinking about facing, timing, and the next two actions |
| *Hades II* | Modern action roguelike with weapon identity, boons, boss progression, and strong moment-to-moment feel | We should make each toy weapon change rhythm, not just damage numbers |
| *Into the Breach* | Perfect-information grid combat where enemies telegraph attacks | Threats should be visible early enough that survival feels earned, not random |
| *Tactical Breach Wizards* | Short tactical encounters with consequence preview and rewind experimentation | The game should support short, dense encounters with fast restart and readable consequences |
| *The Plucky Squire* | Childlike imagined-world adventure crossing between fiction and physical space | The bedroom should not be background only; physical objects should become gameplay verbs |
| *Shotgun King* | Chess rules transformed into a new combat fantasy | Chess identity should be the rules language, not a skin pasted onto normal combat |

## Design Takeaways

### 1. The Core Loop Should Be Small But Deep

Recommended core loop:

```text
Enter room
Read enemy intent
Step one cell
Turn or strike
Exploit a toy/room object
Clear or escape
Receive story/progression beat
```

The game does not need loot spam, procedural maps, or many systems. It needs
rooms that ask clear questions.

### 2. Combat Should Be Real-Time, But Rules Should Be Board-Clear

Enemies can move freely one cell at a time, but their attack identities should
stay chess-shaped:

- Pawn: diagonal threat or weapon replacement.
- Knight: L-shaped target pressure.
- Bishop: diagonal lanes.
- Rook: row/column lock and charge.
- Queen: controlled mix of straight and diagonal patterns.
- King: short-range rule corruption.

The player wins by reading the board, not by stat scaling.

### 3. Weapons Should Change Rhythm

Toy weapons should feel like new verbs:

| Weapon | Gameplay Role |
|---|---|
| Wooden Sword | Fast adjacent strike, baseline |
| Pencil Spear | Long straight poke, slower recovery |
| Ruler Blade | Wide front arc, good crowd control |
| Eraser Guard | Defensive/parry tool, teaches patience |
| Chalk Line | Temporary path/control tool from child help |

Avoid simple "+1 damage" upgrades.

### 4. The Child Should Be A Gameplay System

The fourth-wall idea should become limited, physical interventions:

- Draw chalk path.
- Move toy block.
- Place paper bridge.
- Erase a rule mark.
- Hold a ruler gate open.

The child helps by changing the room, not by deleting enemies.

### 5. Room Design Should Teach-Test-Twist

Each room group should have:

```text
Teach: safe version of the rule
Test: real combat version
Twist: combine it with another rule or prop
Reward: shortcut, weapon, story, or new child intervention
```

This keeps the two-hour game compact while still escalating.

### 6. Production Should Be Parallel

The correct workflow is not pure sequence. Multiple tracks should move together:

- Gameplay design
- Room layout
- Map/world art
- Enemy behavior
- Animation/VFX/SFX readability
- UI/tutorial language
- Technical integration

Each track still needs approval gates. Parallel does not mean careless.

## Candidate General Gameplay Design

### Player

- Moves one grid cell in four directions.
- Can hold movement for repeat stepping.
- Can hold Shift plus direction to turn without moving.
- Uses sword/basic weapon in facing direction.
- Uses one equipped skill.
- Calls one child intervention when charged/unlocked.

### Room Formula

Most normal rooms should last 30-90 seconds.

| Room Type | Purpose |
|---|---|
| Story room | Mood, dialogue, no combat or tiny threat |
| Teach room | Introduce one enemy/prop safely |
| Combat room | Main fight |
| Pressure room | Same idea with less safety |
| Reward room | Weapon, shortcut, rescued piece, or child beat |
| Boss room | One major pattern set, two or three phases |

### Progression

The player gains verbs, not stats:

```text
Sword -> Pencil Spear -> Dodge/Rule Step -> Eraser Guard -> Child Interventions -> Final Rule Break
```

### Failure

- Defeat returns to latest room/checkpoint.
- No currency loss.
- Room resets.
- Story progress and major unlocks remain.

## Source Notes

- Guidus Zero Steam page: real-time grid-based roguelike, four-direction field navigation, timing movement to dodge attacks.
- Guidus Zero Steam news: developers increased dodge distance to 2 tiles and allowed attack-cancel into movement for more dynamic battles.
- Official Shogun Showdown wiki: positioning, attack timing, tile upgrades, combos, and roguelike/deck-building structure.
- Hades II official FAQ and update posts: action roguelike identity built around evolving weapons, powers/boons, bosses, and heavy polish iteration.
- Subset Games *Into the Breach* page and GameDeveloper interview: all enemy attacks are telegraphed, making combat a planning puzzle.
- Tactical Breach Wizards reference pages: short tactical encounters, consequence preview, and rewind/experimentation.
- The Plucky Squire Steam page and Unreal interview: adventure between fictional world and physical childlike space.
- Shotgun King references: chess identity transformed through one strong combat twist.

