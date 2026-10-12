# The Unbound Pawn - Production Aspect Specs

This document defines the completion requirements for every major production
aspect. A task, milestone, or lane cannot be marked `accepted` unless it meets
the requirements listed here.

The checklist tracks status. This spec defines the quality bar.

Related docs:

- `docs/game-production-aspects-checklist.md`
- `docs/production-checklist.md`
- `docs/design/full-gameplay-design-v2.md`

## Global Completion Rule

No aspect is complete just because content exists.

An aspect is complete only when:

1. Its purpose is clear.
2. Its deliverables exist in the project.
3. Its deliverables can be reviewed by the owner.
4. It meets the aspect-specific acceptance requirements.
5. It does not break another accepted aspect.
6. The owner accepts it or explicitly marks it "good enough for now."

## Shared Review States

| State | Meaning |
|---|---|
| `draft` | Spec or content exists but is not approved |
| `approved_to_build` | Owner approved the plan/spec |
| `implemented` | Work exists in the project |
| `verified` | Work runs/checks correctly |
| `owner_review` | Waiting for owner judgment |
| `accepted` | Meets spec and owner accepts |
| `blocked` | Cannot satisfy requirements yet |

---

## Aspect Spec: Gameplay

### Purpose

Gameplay defines what the player repeatedly does, why it is fun, and how mastery
develops from the opening room to the final boss.

### Required Deliverables

- Core gameplay loop.
- Player verb list.
- Movement feel targets.
- Combat feel targets.
- Weapon and skill roles.
- Child intervention rules.
- Failure/checkpoint rules.
- Progression and unlock pacing.
- At least one gameplay sandbox or test room for tuning.

### Completion Requirements

Gameplay cannot be accepted unless:

- The player can move one grid cell at a time in four directions.
- Holding a direction can repeat movement without feeling uncontrolled.
- Turning without moving is supported and useful.
- The sword/basic attack has clear range, timing, and feedback.
- At least one skill changes tactical decisions instead of only increasing damage.
- Enemy telegraphs give the player enough time to react.
- Failure rules are understandable and do not punish experimentation too harshly.
- The owner can play a test slice and say the core action feels promising.

### Cannot Complete If

- Movement feels floaty, delayed, or visually disconnected from the grid.
- Attacks land without readable cause.
- Child intervention solves combat by itself.
- Weapons are only stat upgrades.
- The player cannot explain what they should do next.

---

## Aspect Spec: Level And World Design

### Purpose

Level and world design turns the child's bedroom into a playable structure with
clear routes, readable rooms, memorable districts, and purposeful progression.

### Required Deliverables

- Bedroom world layout.
- First room chain plan.
- Hub layout.
- Room template.
- District layouts.
- Shortcut/lock/intervention routing.
- Per-room purpose notes.
- Reviewable Godot room scenes for implemented areas.

### Completion Requirements

Level/world design cannot be accepted unless:

- The physical bedroom arrangement makes sense.
- Each district has a visual identity and gameplay identity.
- The player can understand major routes without external explanation.
- Each room has a purpose: story, teach, test, twist, reward, boss, or rest.
- Exits and entrances are readable.
- Important interactables are not hidden by decoration.
- Backtracking and shortcuts feel intentional.
- Implemented rooms are editable in Godot, not hidden in code.

### Cannot Complete If

- The map is only a diagram and not translatable to playable rooms.
- Rooms look nice but do not teach or test anything.
- The player gets lost for the wrong reason.
- Collision, exits, and visible art disagree.
- Future rooms cannot reuse the same authoring pattern.

---

## Aspect Spec: Enemy And Boss Design

### Purpose

Enemies and bosses create readable chess-shaped threats that escalate across the
game without becoming random or visually overwhelming.

### Required Deliverables

- Behavior spec for Pawn, Knight, Bishop, Rook, Queen, and King.
- Weapon replacement rules for armed enemies.
- Telegraph rules per enemy family.
- Encounter recipes.
- Boss phase specs.
- Counterplay notes for every major attack.

### Completion Requirements

Enemy/boss design cannot be accepted unless:

- Each enemy has a distinct role.
- Each attack has a readable tell before it deals damage.
- Each enemy has at least one clear weakness or recovery window.
- Armed enemies replace their chess attack with a weapon behavior instead of stacking infinite threats.
- Boss phases change behavior, arena, or pressure, not only HP.
- Enemy combinations are tested for unfair overlaps.
- The player can learn from failure.

### Cannot Complete If

- Enemies feel alive but unreadable.
- Bosses cover too many cells at once.
- Weapon enemies break the chess identity rules.
- Enemy pressure leaves no legal response.
- Bosses require memorization without visual logic.

---

## Aspect Spec: Art Direction

### Purpose

Art direction makes the game look like a child's bedroom chess war while keeping
combat readable at real gameplay speed.

### Required Deliverables

- Visual target sheet.
- Tile palette list.
- District art targets.
- Character sprite scope.
- Prop list.
- Readability rules.
- First-chain art target.

### Completion Requirements

Art direction cannot be accepted unless:

- The game reads as a child's room, not a generic fantasy dungeon.
- Chess pieces remain readable against light and dark floors.
- Enemy, player, pickup, and hazard silhouettes are distinct.
- Gameplay cells remain visible under decoration.
- Each district uses different materials and shapes.
- Important combat colors are reserved and consistent.
- The owner approves the style direction in-editor or through production references.

### Cannot Complete If

- Pretty props hide threats.
- The map looks like a concept image but not a playable game space.
- The palette becomes one-note or muddy.
- Tiles do not align to the 32px grid.
- Sprites cannot be recognized at gameplay zoom.

---

## Aspect Spec: Animation

### Purpose

Animation communicates state, intent, impact, and personality. It must support
gameplay readability before decoration.

### Required Deliverables

- Player animation list.
- Enemy animation list.
- Boss animation plan.
- Weapon animation plan.
- Child intervention animation plan.
- AnimationTree/editor ownership rules.

### Completion Requirements

Animation cannot be accepted unless:

- Player movement and attacks feel responsive.
- Enemy windups are visible before damage.
- Hit, hurt, defeat, and recovery states are readable.
- Animation does not move the logical grid anchor incorrectly.
- Boss phase changes are visually obvious.
- Editor-owned animation clips can be tuned in Godot.
- Animations improve decision-making instead of adding noise.

### Cannot Complete If

- Attacks happen before the tell is visible.
- Animation timing disagrees with hit timing.
- Movement appears to slide off-grid.
- Boss animations obscure danger cells.
- Only idle sprites exist for active combat actors.

---

## Aspect Spec: VFX And Combat Feedback

### Purpose

VFX and feedback make danger, hits, pickups, boss phases, and child interventions
clear without cluttering the board.

### Required Deliverables

- Telegraph visual language.
- Hit feedback rules.
- Pickup feedback rules.
- Defeat effects.
- Boss phase effects.
- Child intervention effects.
- Accessibility/readability checks.

### Completion Requirements

VFX cannot be accepted unless:

- Danger telegraphs are visible before impact.
- Threat colors and safe colors do not conflict.
- Hit feedback confirms contact without hiding the next threat.
- Pickups are noticeable but not mistaken for hazards.
- Child intervention effects are visually distinct from enemy magic.
- Boss phase effects communicate a real change.
- Effects are readable in busy rooms.

### Cannot Complete If

- VFX makes the room harder to read.
- Red/danger effects are used decoratively.
- Telegraphs and damage effects look the same.
- Camera shake or particles hide grid state.
- Effects are not tied to gameplay timing.

---

## Aspect Spec: Audio

### Purpose

Audio supports timing, impact, mood, and world identity. It should help the
player react, not only decorate the game.

### Required Deliverables

- Audio identity guide.
- Movement and attack SFX.
- Enemy telegraph SFX.
- Child intervention SFX.
- Pickup/defeat/room-clear SFX.
- Music plan.
- Mix priority rules.

### Completion Requirements

Audio cannot be accepted unless:

- Important attacks have recognizable warning sounds.
- Player actions feel responsive through sound.
- Child sounds feel physical: chalk, paper, blocks, hand movement.
- Music supports district mood without drowning warnings.
- SFX buses and volume priorities are sensible.
- The owner can play a room and understand danger with audio cues on.

### Cannot Complete If

- Warning sounds are too late or too quiet.
- Repeated sounds become annoying in normal play.
- Music masks combat information.
- Audio style feels unrelated to toys, chess, or bedroom materials.
- There is no mix rule for overlapping combat sounds.

---

## Aspect Spec: UI, UX, And Tutorial

### Purpose

UI and tutorial systems teach the player without breaking immersion or covering
the combat grid.

### Required Deliverables

- HUD scope.
- Tutorial prompt style.
- Rule Book/compendium behavior.
- Pause/settings plan.
- Keyboard/controller mapping.
- Accessibility options.

### Completion Requirements

UI/UX cannot be accepted unless:

- The HUD shows only information needed for decisions.
- Courage, skills, and child help are understandable at a glance.
- Tutorial prompts are short and placed safely.
- The Rule Book helps players review enemy rules.
- Controls are discoverable.
- UI never hides active combat threats.
- Basic settings exist for testing comfort.

### Cannot Complete If

- The player needs external explanation to understand controls.
- Tutorial text interrupts fast combat too often.
- HUD elements overlap important tiles.
- UI style clashes with the bedroom/chess identity.
- Accessibility needs are ignored until the end.

---

## Aspect Spec: Narrative And Worldbuilding

### Purpose

Narrative gives emotional meaning to the pawn's rule-breaking and the child's
help. It should be clear, compact, and playable.

### Required Deliverables

- Start-to-end story outline.
- Opening script.
- Child voice rules.
- District story beats.
- Boss identity beats.
- Ending script.
- Dialogue density rules.

### Completion Requirements

Narrative cannot be accepted unless:

- The player understands why the pawn is different.
- The child feels like a companion, not a menu system.
- Each district advances story or theme.
- Bosses represent more than a health bar.
- Dialogue does not stop gameplay too often.
- The ending resolves the pawn's freedom and the child's role.

### Cannot Complete If

- The story depends on long exposition.
- The child explains everything instead of being felt through play.
- Bosses lack personality or theme.
- The bedroom reality and imagined kingdom feel disconnected.
- The ending only says "you win" without emotional payoff.

---

## Aspect Spec: Technical Architecture

### Purpose

Technical architecture supports editor-first production, reliable gameplay, and
safe iteration without turning content into hidden script-only systems.

### Required Deliverables

- Scene ownership rules.
- Room transition system.
- Save/checkpoint plan.
- Gameplay sandbox scene.
- Automated checks.
- Performance budget.
- Authoring conventions.

### Completion Requirements

Technical architecture cannot be accepted unless:

- Rooms, actors, pickups, and exits are inspectable in Godot.
- Runtime code supports content instead of replacing content.
- Room travel works consistently.
- Checkpoints and resets are predictable.
- Tests or smoke checks catch broken core behavior.
- Technical choices are documented for future agents and human editing.

### Cannot Complete If

- Key content is only generated at runtime and cannot be edited.
- Room connections are fragile or unclear.
- A new room requires custom code every time.
- Tests cannot run or do not cover core travel/combat behavior.
- The owner cannot reasonably modify scenes in the editor.

---

## Aspect Spec: Tools And Editor Workflow

### Purpose

Tools and workflow make production repeatable for both Codex and the owner.

### Required Deliverables

- Godot MCP workflow notes.
- Room authoring guide.
- Asset import rules.
- Tile editing workflow.
- Review checklist template.
- Error/recovery instructions.

### Completion Requirements

Tools/workflow cannot be accepted unless:

- The owner can open and inspect relevant scenes.
- The owner knows which nodes are safe to move/edit.
- Tile and sprite import rules are documented.
- Review feedback can be given in a structured way.
- Codex knows what to do before and after editor review.

### Cannot Complete If

- Only Codex understands how content is built.
- Manual editor work is required but undocumented.
- Asset imports are inconsistent.
- Review instructions are vague.
- Fixing a room requires guessing which script owns it.

---

## Aspect Spec: QA And Playtesting

### Purpose

QA and playtesting prove the game works, feels good, and remains stable as
parallel production continues.

### Required Deliverables

- Smoke test checklist.
- Room QA checklist.
- Combat feel test format.
- Bug tracking format.
- Vertical slice test plan.
- Regression checklist.

### Completion Requirements

QA cannot be accepted unless:

- The game can be launched reliably.
- Core movement/combat/travel can be checked quickly.
- Bugs have reproduction steps.
- Owner playtest feedback is captured and acted on.
- Accepted features do not repeatedly regress.
- Vertical slice can be tested end-to-end.

### Cannot Complete If

- "It worked once" is treated as proof.
- Bugs are fixed without recording cause.
- Feel feedback is ignored because tests pass.
- Test coverage only checks code and not playability.
- Owner review notes are not tracked.

---

## Aspect Spec: Release And Presentation

### Purpose

Release and presentation prepare the game or vertical slice to be shared,
tested, and understood by people outside the project.

### Required Deliverables

- Vertical slice package plan.
- Screenshot plan.
- Trailer beat list.
- Store/page description draft.
- Final build checklist.
- Known issues list.

### Completion Requirements

Release/presentation cannot be accepted unless:

- A playable build can be exported or packaged.
- Screenshots show actual gameplay, not only mood.
- The trailer plan communicates pawn, chess combat, child room, and rule-breaking.
- The pitch is understandable to a new player.
- Known issues are listed honestly.
- The owner accepts the slice as representative of the game.

### Cannot Complete If

- The game only works in the editor.
- Marketing images hide gameplay.
- The pitch sounds generic.
- The build has unresolved blocker bugs.
- The slice does not represent the intended final direction.

