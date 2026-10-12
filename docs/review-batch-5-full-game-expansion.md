# Review Batch 5 - Full Game Expansion

**Status:** draft for owner review  
**Purpose:** approve or revise the full-game production direction after the first
vertical slice target is understood.  
**Batch source:** `docs/production-review-dashboard.md`

This batch is not a request to build the whole game at once. It is the full
production map for everything beyond the first playable slice: later bosses,
advanced skills, complete art/animation/feedback coverage, narrative payoff,
save/testing support, and demo/release preparation.

Approving this batch means the long-term direction is stable enough that each
lane can produce detailed task specs in parallel.

---

## Included Gates

| Group | Gates | Specs |
|---|---|---|
| Boss/enemy expansion | `EN.3`, `EN.4`, `EN.5`, `EN.6`, `EN.7` | Bishop, Rook, Queen, King, encounter recipes |
| Advanced skills | `GP.4`, `GP.5`, `GP.6` | Skills, child intervention, checkpoints |
| Art production | `ART.3` through `ART.7` | District art, characters, props, readability, polish |
| Animation | `AN.1` through `AN.6` | Player, enemies, bosses, weapons, child help, AnimationTree QA |
| VFX/audio/UI | `FX.3` through `FX.6`, `AU.1` through `AU.6`, `UI.2` through `UI.6` | Pickup, defeat, boss phase, readability, sound, tutorial, rulebook, settings |
| Narrative | `NAR.2` through `NAR.6` | Opening, child voice, district beats, boss beats, ending |
| Technical/QA/release | `TECH.3`, `TECH.5`, `TECH.6`, `TOOL.5`, `QA.3`, `QA.4`, `REL.1` through `REL.5` | Save, tests, performance, review forms, feel tests, bugs, package, screenshots, trailer, page, final build |

---

## Full Game Direction Summary

## 1. Boss And Enemy Expansion

Approved enemy arc:

```text
Pawn -> Knight -> Bishop -> Rook -> Queen -> King
```

Each piece must feel like a different tactical problem:

| Enemy | Main Question | Player Answer |
|---|---|---|
| Bishop | How do I cross diagonal control? | timing, cover, Chalk Path |
| Rook | How do I survive straight-line pressure? | cover, Eraser Guard, baiting |
| Queen | How do I read mixed patterns under pressure? | mastery of all prior rules |
| King | How do I break the system without losing the pawn identity? | final rule breaks, learned restraint |

Encounter recipes must protect readability:

```text
one primary threat + one supporting pressure + one terrain idea
```

No room should combine multiple unlearned threats.

## 2. Advanced Skill Arc

Approved skill set:

```text
Sword
Pencil Thrust
Rule Step
Chalk Path
Eraser Guard
Final Rule Break
```

Skill rule:

```text
Skills change decisions; they do not replace one-cell movement.
```

Each skill needs:

- a boss or room that earns it,
- a safe teach moment,
- a combat test,
- one optional mastery use,
- clear UI/readability support.

## 3. Child Intervention System

The child is the fourth-wall force. The player pawn is not becoming a normal
action hero; the child is imagining, moving, and rewriting the battlefield.

Approved intervention types:

| Type | Example |
|---|---|
| Physical help | pencil bridge, eraser block, ruler gate |
| Emotional help | whispered encouragement, hesitation break |
| Rule help | temporary rewritten path or final rule break |
| World help | desk light, toy shift, paper fold |

Restriction:

```text
Child help creates openings. It should not win fights automatically.
```

## 4. Art Production Direction

The full game should read as:

```text
Enter-the-Gungeon-like 2D top-down readability
+ child's bedroom materials
+ chess-war fantasy
+ real editable Godot sprites and TileMaps
```

Art production must cover:

- district material identity,
- enemy silhouettes,
- toy/bedroom props,
- readable floors and blockers,
- telegraph-safe color zones,
- final polish pass for the vertical slice.

Cannot approve full art production if the rooms still depend on script-drawn
placeholder shapes for final visuals.

## 5. Animation And Feedback Direction

Animation must solve the current reaction problem. Enemies should feel alive
because their intent is visible before damage happens.

Required combat readability stack:

```text
pose tell -> tile telegraph -> sound cue -> attack -> hit/whiff result
```

Animation coverage:

- player idle, step, turn, sword, hurt, pickup, defeat/recover,
- each enemy's idle, move, tell, attack, hurt, defeated,
- boss phase changes,
- weapon-specific attack silhouettes,
- child intervention animations,
- AnimationTree states editable in Godot.

## 6. UI, Tutorial, And Rule Book

UI should feel like a child's physical play space, not a heavy RPG menu.

Approved UI objects:

| UI Object | Purpose |
|---|---|
| Minimal HUD | health, skill, current rule pressure |
| Tutorial prompts | short contextual hints |
| Rule Book | review learned movement/combat/rule-break ideas |
| Pause/settings | tester usability |
| Input remap/controller | fast combat support |
| Accessibility options | readable telegraphs and screen shake control |

Tutorial principle:

```text
teach through room shape first, text second.
```

## 7. Narrative Direction

The emotional spine:

```text
the pawn survives a broken game
the child notices
the child helps without fully understanding the pain
the pawn learns to use broken rules without becoming the same as black pieces
the final fight resolves both chess war and child imagination
```

Each district should add one emotional beat:

| District | Beat |
|---|---|
| Opening | loss, shock, first defiance |
| Toybox | courage through movement |
| Bookshelf | imagination writes new paths |
| Block Tower | defense and endurance |
| Dollhouse | deception and control |
| Under-Bed | fear, final rule break, ending |

Bosses need behavior and dialogue beats, not long cutscenes.

## 8. Technical, QA, And Release Direction

The editor-first rule continues:

```text
rooms, actors, props, TileMaps, markers, and resources should be visible and
editable in Godot whenever practical.
```

Required support:

- save/checkpoint rules,
- automated smoke tests for critical systems,
- performance budgets for crowded rooms,
- bug report format,
- combat feel test procedure,
- vertical slice package,
- screenshot and trailer capture plan,
- final build checklist.

---

## Parallel Work Model

After this batch is approved, the following can move in parallel:

```text
Enemy lane: Bishop/Rook/Queen/King behavior refinement
Gameplay lane: skill and checkpoint implementation planning
Art lane: district tile/sprite/prop production planning
Animation lane: player/enemy/boss animation task sheets
Feedback lane: pickup/defeat/boss phase effect tests
Audio lane: warning/action/music direction
UI lane: rulebook, prompts, settings
Narrative lane: opening, district beats, ending
Technical lane: save, tests, performance
Release lane: demo packaging and presentation
```

But no individual item skips its own gate:

```text
specific spec -> owner approval -> implementation -> verification -> owner review
```

---

## Approval Questions

| Question | Recommended Answer |
|---|---|
| Should the full enemy arc stay Pawn -> Knight -> Bishop -> Rook -> Queen -> King? | yes |
| Should advanced skills stay limited to Pencil, Rule Step, Chalk Path, Eraser Guard, Final Rule Break? | yes |
| Should child intervention be supportive instead of solving fights alone? | yes |
| Should final visuals use real sprites/TileMaps instead of script-drawn shapes? | yes |
| Should animation/telegraph readability be mandatory before harder encounters are accepted? | yes |
| Should the game target 90-120 minutes rather than a larger scope? | yes |
| Should release planning start with a vertical slice package before a final build? | yes |

---

## If Approved

If this batch is approved, these implementation-planning tasks may begin in
parallel after earlier batch dependencies are respected:

```text
Bishop district production spec
Rook district production spec
Queen district production spec
King finale production spec
full skill implementation plan
child intervention production plan
full art asset list
animation task sheets
rulebook UI production spec
save/checkpoint implementation plan
vertical slice packaging checklist
```

Recommended immediate use:

```text
Use this batch as the long-term guardrail.
Do not build Batch 5 content before the first playable chain and vertical slice
foundation are accepted.
```

## If Not Approved

Revise only the disputed lane. Possible revision areas:

- boss order,
- skill count,
- child intervention power level,
- art workload,
- animation scope,
- target game length,
- demo/release standard.

Do not restart the whole plan unless the core fantasy changes.

---

## Approval State

Current state:

```text
draft
```

Owner decision:

```text
pending
```
