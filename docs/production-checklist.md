# The Unbound Pawn - Production Checklist

This checklist is the project manager view of the game. It exists to stop the
project from becoming a pile of rushed generated pieces. Every production task
must pass its gate before the next task starts.

Related production docs:

- `docs/game-production-aspects-checklist.md`
- `docs/game-production-aspect-specs.md`
- `docs/production-review-dashboard.md`
- `docs/production-approval-board.md`
- `docs/owner-review-template.md`
- `docs/design/full-gameplay-design-v2.md`
- `docs/design/gameplay-reference-research.md`

## Working Rule

- Plan one small part.
- Confirm the plan with the owner.
- Implement only that part.
- Verify in Godot.
- Ask the owner to review it in the editor.
- Fix until accepted.
- Move that part forward only after acceptance.

If Codex is not confident it can finish a task cleanly, it must stop at planning
and explain what needs owner/editor/art input.

## Parallel Production Rule

Production is parallel, not waterfall. Gameplay, room layout, art, enemy design,
animation, UI, and technical integration can move at the same time as separate
tracks.

The restriction is not "only one thing exists at a time." The restriction is:
no individual task may move from planning to implementation without its own
approval gate.

Example:

```text
Gameplay loop planning can continue while T1 room art is being reviewed.
Enemy behavior planning can continue while tile palette research is happening.
UI tutorial planning can continue while room transitions are implemented.
```

But:

```text
No room is built without a room plan.
No enemy is implemented without a behavior spec.
No art pass replaces assets without an art target.
No mechanic is tuned without a test room.
```

## Status Key

| Status | Meaning |
|---|---|
| `not_started` | Not planned in detail yet |
| `planning` | Being specified before implementation |
| `approved` | Owner approved the plan; implementation may begin |
| `in_progress` | Currently being implemented |
| `owner_review` | Implemented and waiting for in-editor review |
| `accepted` | Owner approved; safe to move on |
| `blocked` | Needs a decision, tool, asset, or editor work |

## Production Gates

Every task must satisfy these gates:

| Gate | Requirement |
|---|---|
| Design gate | The goal, layout, assets, gameplay purpose, and risks are written down |
| Confidence gate | Codex states what can be done confidently and what cannot |
| Owner approval gate | Owner confirms the task may be implemented |
| Editor gate | Result opens as editable Godot scene/content, not hidden script-only content |
| Verification gate | Project runs or relevant checks pass |
| Review gate | Owner reviews the result in Godot and accepts or requests fixes |

## Current Approval Path

The active planning package is reviewed through five owner-facing batches:

| Batch | Review File | Purpose |
|---|---|---|
| Batch 1 | `docs/review-batch-1-foundation.md` | Fantasy, first chain, map premise, visual target, story spine, room transitions |
| Batch 2 | `docs/review-batch-2-first-playable-feel.md` | Movement, sword, first enemy, telegraphs, hit feel, HUD |
| Batch 3 | `docs/review-batch-3-first-chain-production-rules.md` | Room template, TileMap workflow, imports, QA |
| Batch 4 | `docs/review-batch-4-vertical-slice-expansion.md` | Hub, Toybox district, Knight boss, Rule Step, slice route |
| Batch 5 | `docs/review-batch-5-full-game-expansion.md` | Full enemy, skill, art, animation, audio, UI, narrative, QA, release guardrails |

Approval state is tracked in:

```text
docs/production-approval-board.md
```

No item in the milestone tables below may move to implementation only because a
document exists. A matching batch or task must be explicitly approved first.

## Act Structure

Player-facing acts are separate from approval batches.

Current act planning:

| Act | Scope | Plan |
|---|---|---|
| Act 1 | White King's fall through small tutorial boss | `docs/production/act-1-opening-to-first-boss-flow-map.md` approved for initial T1 build |
| Act 2 | Toybox Knight district through Knight Captain | pending |

## Milestone 0 - Production Setup

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M0.1 | Lock production workflow | accepted | This checklist | Owner agrees every task needs plan -> approval -> implementation -> review |
| M0.2 | Confirm Godot MCP connection | accepted | Godot MCP launch test | Godot project launches through MCP |
| M0.3 | Confirm art direction reference | accepted | Bedroom pathway concept image | The game world is a child's bedroom imagined as a chess war |
| M0.4 | Confirm room production order | accepted | Ordered room list | Owner approved first production chain in Batch 1 |
| M0.5 | Confirm parallel production lanes | planning | Lane board | Owner agrees which tracks may advance simultaneously |

## Parallel Production Lanes

These tracks should advance together. Each track has its own approval gates.

| Lane | Purpose | Can Work In Parallel With | First Output |
|---|---|---|---|
| Gameplay Design | Define player verbs, room loops, progression, combat feel | All lanes | General gameplay spec |
| Room/Map Design | Turn the bedroom into playable spaces | Gameplay, Art, Technical | Room chain and hub layout |
| Art Direction | Tile palette, props, pieces, visual readability | Room, Feedback, UI | Production art target per area |
| Enemy/Boss Design | Piece behaviors, threats, weapons, boss phases | Gameplay, Animation, Rooms | Enemy behavior spec |
| Animation/VFX/SFX | Telegraphs, hit feedback, pickup feel, child help | Gameplay, Enemy, Art | Feedback readability pass |
| UI/Tutorial | HUD, prompts, rule book, signs, player onboarding | Gameplay, Rooms | Tutorial language plan |
| Technical Integration | Scene templates, transitions, ECS hooks, tests | All lanes | Editable working slice |

## Milestone G - General Gameplay Design

Scope: define the real game, not just the room scenery. This milestone should
run in parallel with room production.

Reference doc:

```text
docs/design/gameplay-reference-research.md
docs/design/full-gameplay-design-v2.md
```

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| G0.1 | Research gameplay references | accepted | Gameplay reference research doc | Recent/relevant references are summarized into usable design lessons |
| G0.2 | Approve full gameplay design V2 | planning | Start-to-end gameplay design with graphs | Owner accepts the journey, loop, unlocks, bosses, and vertical-slice target |
| G0.3 | Approve player verb list | not_started | Player action list | Movement, turn, strike, skill, child help, interact, focus are accepted or cut |
| G0.4 | Approve weapon philosophy | not_started | Toy weapon roles | Weapons change rhythm and tactics, not only damage |
| G0.5 | Approve child-intervention rules | not_started | Fourth-wall mechanic rules | Child help changes the room physically but does not solve fights alone |
| G0.6 | Approve room formula | not_started | Teach-test-twist template | Every room group has a learning purpose and escalation pattern |
| G0.7 | Approve progression arc | not_started | 2-hour unlock order | Unlocks are paced across bosses and districts |
| G0.8 | Build gameplay test sandbox | not_started | Editor-owned test room | Mechanics can be tested without waiting for final art |
| G0.9 | Gameplay feel review 1 | not_started | Owner playtest notes | Owner confirms movement/combat direction before scaling content |

## Milestone 1 - First Playable Room Chain

Scope: build the first chain carefully before expanding the world.

```text
T1_WhiteKingsFall -> T2_FallenSwordTile -> T3_FirstPawnClash -> T4_BrokenRuleYard -> B1_BlackPawnCaptain -> H1_ChessRugHubOpens
```

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M1.1 | Plan `T1_WhiteKingsFall` | approved | `docs/production/t1-white-kings-fall-production-spec.md` | Layout, mood, assets, nodes, exits, and review criteria are approved |
| M1.2 | Build `T1_WhiteKingsFall` scene | in_progress | `scenes/rooms/t1_white_kings_fall.tscn` | Scene opens in editor, uses real nodes/assets, and reads as the White King's fall |
| M1.3 | Owner review of `T1` | not_started | Fix list or acceptance | Owner confirms the room looks and feels right enough to move on |
| M1.4 | Plan `T2_FallenSwordTile` | not_started | One-room production spec | Sword pickup moment, path, lighting, and interaction are approved |
| M1.5 | Build `T2_FallenSwordTile` scene | not_started | Editable Godot `.tscn` room | Player can understand and reach the sword pickup |
| M1.6 | Owner review of `T2` | not_started | Fix list or acceptance | Owner confirms pickup room quality |
| M1.7 | Plan `T3_FirstPawnClash` | not_started | One-room production spec | First combat layout, enemy count, cover, and exits are approved |
| M1.8 | Build `T3_FirstPawnClash` scene | not_started | Editable Godot `.tscn` room | First fight is readable, fair, and visually grounded in the chess rug |
| M1.9 | Owner review of `T3` | not_started | Fix list or acceptance | Owner confirms combat readability and room look |
| M1.10 | Plan `T4_BrokenRuleYard` | not_started | One-room production spec | Repositioning, turn-without-moving, simple cover, and rule-break theme are approved |
| M1.11 | Build `T4_BrokenRuleYard` scene | not_started | Editable Godot `.tscn` room | Player must reposition and use facing under light pressure |
| M1.12 | Owner review of `T4` | not_started | Fix list or acceptance | Owner confirms the tutorial escalation feels right |
| M1.13 | Plan `B1_BlackPawnCaptain` | not_started | Small boss production spec | Boss arena, phases, readable attacks, reward, and review criteria are approved |
| M1.14 | Build `B1_BlackPawnCaptain` scene | not_started | Editable Godot `.tscn` boss room | Boss tests movement, facing, sword, telegraph, and positioning |
| M1.15 | Owner review of `B1` | not_started | Fix list or acceptance | Owner confirms this is a satisfying first boss |
| M1.16 | Plan `H1_ChessRugHubOpens` | not_started | Hub production spec | Branch directions, blocked routes, props, and safe-room tone are approved |
| M1.17 | Build `H1_ChessRugHubOpens` scene | not_started | Editable Godot `.tscn` room | Hub clearly connects future districts and feels like the center of the bedroom war |
| M1.18 | Owner review of `H1` | not_started | Fix list or acceptance | Owner accepts the first hub |
| M1.19 | Connect Act 1 chain | not_started | Working transitions | Player can travel through T1 -> T2 -> T3 -> T4 -> B1 -> H1 |
| M1.20 | Act 1 verification | not_started | Test/run notes | No crash, no broken exits, player spawns correctly, owner confirms flow |

## Milestone 2 - Production Map Foundation

Scope: make the bedroom world expandable without remaking everything.

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M2.1 | Define room scene template | not_started | Standard node tree | Every room uses the same readable editor structure |
| M2.2 | Define exit/entry convention | not_started | Naming and target rules | Exits and spawn points are obvious in the scene tree |
| M2.3 | Define prop placement convention | not_started | Prop/layer rules | Decorative objects do not fight gameplay readability |
| M2.4 | Define collision convention | not_started | Tile/solid rules | Walls, blockers, and props are editable and logically consistent |
| M2.5 | Define room review checklist | not_started | Per-room QA list | Each room can be judged consistently before acceptance |

## Milestone 3 - Bedroom Districts

Scope: expand the world only after the first chain is accepted.

| ID | District | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M3.1 | Toybox Knight District plan | not_started | District spec | Owner approves room count, visual theme, enemies, boss idea |
| M3.2 | Toybox Knight District build | not_started | Rooms + boss arena | Complete loop from hub to Knight reward and back |
| M3.3 | Bookshelf Bishop District plan | not_started | District spec | Diagonal danger and book-fort look are approved |
| M3.4 | Bookshelf Bishop District build | not_started | Rooms + boss arena | Complete Bishop loop with readable diagonal threats |
| M3.5 | Block Tower Rook District plan | not_started | District spec | Cover, straight-line pressure, and block-tower identity are approved |
| M3.6 | Block Tower Rook District build | not_started | Rooms + boss arena | Complete Rook loop with clear cover gameplay |
| M3.7 | Dollhouse Queen District plan | not_started | District spec | Mixed enemy pressure and dollhouse visual identity are approved |
| M3.8 | Dollhouse Queen District build | not_started | Rooms + boss arena | Complete Queen loop with escalation toward finale |
| M3.9 | Under-Bed Black Castle plan | not_started | Final district spec | Final route, mood, King setup, and ending beat are approved |
| M3.10 | Under-Bed Black Castle build | not_started | Final rooms + boss arena | Final path feels dangerous and climactic |

## Milestone 4 - Combat And Game Feel

Scope: tune only after there is enough room content to judge it.

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M4.1 | Player movement feel pass | not_started | Tuned movement values | Step speed, turn behavior, and hold movement feel right in multiple rooms |
| M4.2 | Sword feel pass | not_started | Tuned basic attack | Attack range, timing, hit feedback, and recovery feel responsive |
| M4.3 | Weapon/skill unlock plan | not_started | Approved progression list | Each unlock has a purpose and a room/boss that teaches it |
| M4.4 | Enemy telegraph pass | not_started | Animation/VFX/SFX tells | Player can notice and react before attacks land |
| M4.5 | Boss prototype pass | not_started | One complete boss loop | At least one boss proves phases, telegraphs, rewards, and arena layout |

## Milestone 5 - Art Production

Scope: replace temporary art only when the gameplay container is stable.

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M5.1 | Tile palette audit | not_started | Approved tile list | Required floor, wall, prop, path, and hazard tiles are listed |
| M5.2 | Opening-room art pass | not_started | Polished T1-T3/H1 visuals | First chain no longer reads as placeholder |
| M5.3 | Actor sprite audit | not_started | Approved sprite list | Player, pawn, knight, bishop, rook, queen, king needs are clear |
| M5.4 | VFX/SFX style pass | not_started | Shared feedback language | Hits, telegraphs, pickups, defeats, and child help feel consistent |
| M5.5 | UI readability pass | not_started | HUD/rulebook polish | UI supports play without hiding the map |

## Milestone 6 - Vertical Slice

Scope: a polished 10-15 minute demo.

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| M6.1 | Vertical slice scope lock | not_started | Slice content list | Owner approves what is included and what is cut |
| M6.2 | Full playable slice | not_started | Buildable demo | Start, combat, one district, one boss, reward, and return loop work |
| M6.3 | QA pass | not_started | Bug list and fixes | No known blocker crashes or progression breaks |
| M6.4 | Owner acceptance | not_started | Accepted vertical slice | Owner agrees it represents the game's direction |

## Current Next Action

Do not implement yet.

Next professional steps can happen in parallel:

```text
M0.4 - Confirm room production order
M0.5 - Confirm parallel production lanes
G0.2 - Approve core gameplay loop
```

Recommended order:

```text
T1_WhiteKingsFall
T2_FallenSwordTile
T3_ChessRugBattlefield
H1_ChessRugHub
```

After the owner accepts this order, begin:

```text
M1.1 - Plan T1_WhiteKingsFall
```

At the same time, after the owner accepts the core gameplay loop, begin:

```text
G0.3 - Approve player verb list
G0.4 - Approve weapon philosophy
G0.5 - Approve child-intervention rules
```
