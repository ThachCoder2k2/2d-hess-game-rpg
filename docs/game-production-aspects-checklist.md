# The Unbound Pawn - Game Production Aspects Checklist

This checklist tracks the major disciplines needed to make the game feel like a
real production, not a collection of disconnected prototypes.

Use this together with:

- `docs/game-production-aspect-specs.md`
- `docs/design/full-gameplay-design-v2.md`
- `docs/production-checklist.md`
- `docs/design/gameplay-reference-research.md`

## Status Key

| Status | Meaning |
|---|---|
| `not_started` | Not planned in detail yet |
| `planning` | Being designed or scoped |
| `approved` | Owner approved the plan |
| `in_progress` | Being produced |
| `owner_review` | Waiting for owner/editor review |
| `accepted` | Good enough to build on |
| `blocked` | Needs decision, tool, asset, or manual editor work |

## Production Principle

All aspects can move in parallel, but every individual task still needs:

```text
plan -> approval -> implementation -> verification -> owner review -> accepted
```

No aspect is allowed to silently become "done" just because the game runs.
Each lane's completion requirements are defined in
`docs/game-production-aspect-specs.md`.

## How To Read This Checklist

The sections below are **parallel production lanes**, not an ordered sequence.
The lane order in this file is only for readability.

IDs such as `GP.1`, `LD.1`, and `ART.1` are tracking labels. They do not mean
"do all Gameplay before Level Design" or "finish Level Design before Art."

Correct usage:

```text
Gameplay can plan GP.2 while Art plans ART.2.
Level Design can build LD.3 while UI plans UI.2.
Enemy Design can specify EN.2 while Animation plans AN.2.
Technical can support all lanes continuously.
```

The only ordering rule is inside a single task:

```text
plan -> approve -> implement -> verify -> owner review -> accept
```

## Parallel Lane Dashboard

| Lane | Current Track | Parallel Partner Lanes | First Approval Gate |
|---|---|---|---|
| Gameplay | Core feel, verbs, progression | Level, Enemy, UI, Technical | `GP.1` |
| Level / World | Bedroom map, rooms, hub, districts | Gameplay, Art, Technical | `LD.1`, `LD.2` |
| Enemy / Boss | Piece behaviors, boss identity | Gameplay, Animation, VFX | `EN.1` |
| Art Direction | Tiles, props, sprites, readability | Level, Animation, UI | `ART.1` |
| Animation | Player/enemy/boss motion | Gameplay, Enemy, VFX | `AN.1` |
| VFX / Feedback | Telegraphs, hits, readability | Gameplay, Animation, Audio | `FX.1` |
| Audio | Combat, music, warning sounds | VFX, Gameplay, Narrative | `AU.1` |
| UI / UX / Tutorial | HUD, prompts, rulebook, controls | Gameplay, Narrative, Technical | `UI.1` |
| Narrative | Story, child voice, boss beats | Level, UI, Audio | `NAR.1` |
| Technical | Scene systems, transitions, tests | Every lane | `TECH.2` |
| Tools / Workflow | Editor process, imports, review forms | Art, Level, QA | `TOOL.2` |
| QA / Playtesting | Checks, bug format, feel tests | Every lane | `QA.1` |
| Release | Demo packaging and presentation | QA, Art, Audio | `REL.1` |

---

## Lane: Gameplay

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| GP.1 | Core loop approval | planning | `docs/design/gp1-ld2-core-loop-first-chain-spec.md` | Owner accepts room-to-room rhythm |
| GP.2 | Player movement feel | planning | `docs/design/gp2-player-movement-feel-spec.md` | Movement feels responsive and readable |
| GP.3 | Basic sword combat | planning | `docs/design/gp3-basic-sword-combat-spec.md` | Sword feels fast, fair, and useful |
| GP.4 | Skill system | planning | `docs/design/gp4-skill-system-spec.md` | Skills create new decisions, not only damage |
| GP.5 | Child intervention system | planning | `docs/design/gp5-child-intervention-system-spec.md` | Child changes room state without solving fights alone |
| GP.6 | Failure/checkpoint rules | planning | `docs/design/gp6-failure-checkpoint-rules-spec.md` | Player understands loss and recovery |
| GP.7 | Progression pacing | planning | `docs/design/gp7-progression-pacing-spec.md` | Each unlock has a teach/test moment |

---

## Lane: Level And World Design

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| LD.1 | Bedroom world layout | planning | `docs/design/ld1-bedroom-world-layout-spec.md` | Districts make sense as a child's room |
| LD.2 | First room chain | planning | `docs/design/gp1-ld2-core-loop-first-chain-spec.md` | Opening flow is approved before build |
| LD.3 | Room template | planning | `docs/design/ld3-room-template-spec.md` | Every room has clear art, exits, gameplay objects |
| LD.4 | Room formula | planning | `docs/design/ld4-room-formula-spec.md` | Every district escalates cleanly |
| LD.5 | Hub design | planning | `docs/design/ld5-chess-rug-hub-spec.md` | Player can understand future routes |
| LD.6 | District layout plans | planning | `docs/design/ld6-district-layout-plans-spec.md` | Each area has identity, mechanic, boss, reward |
| LD.7 | Shortcuts and locks | planning | `docs/design/ld7-shortcuts-locks-spec.md` | Backtracking feels intentional, not confusing |

---

## Lane: Enemy And Boss Design

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| EN.1 | Pawn behavior spec | planning | `docs/design/en1-pawn-behavior-spec.md` | Pawn teaches the combat language |
| EN.2 | Knight behavior spec | planning | `docs/design/en2-knight-behavior-spec.md` | Knight feels different and readable |
| EN.3 | Bishop behavior spec | planning | `docs/design/en3-bishop-behavior-spec.md` | Bishop controls space without clutter |
| EN.4 | Rook behavior spec | planning | `docs/design/en4-rook-behavior-spec.md` | Rook rewards positioning and defense |
| EN.5 | Queen behavior spec | planning | `docs/design/en5-queen-behavior-spec.md` | Queen tests mastery without chaos |
| EN.6 | King behavior spec | planning | `docs/design/en6-king-behavior-spec.md` | Final boss pays off the whole game |
| EN.7 | Encounter recipes | planning | `docs/design/en7-encounter-recipes-spec.md` | Rooms escalate without unfair overlap |

---

## Lane: Art Direction

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| ART.1 | Visual target lock | planning | `docs/design/art1-visual-target-spec.md` | Owner approves the final art direction |
| ART.2 | Tile palette list | planning | `docs/design/art2-tile-palette-list-spec.md` | Tile needs are known before mass production |
| ART.3 | Bedroom district art targets | planning | `docs/design/art3-bedroom-district-art-targets-spec.md` | Each district has distinct shapes/materials |
| ART.4 | Character sprite list | planning | `docs/design/art4-character-sprite-list-spec.md` | Sprite scope is clear and finite |
| ART.5 | Prop list | planning | `docs/design/art5-prop-list-spec.md` | Props support gameplay and story |
| ART.6 | Readability audit | planning | `docs/design/art6-readability-audit-spec.md` | Gameplay cells, enemies, and telegraphs remain visible |
| ART.7 | Final polish pass | planning | `docs/design/art7-final-polish-pass-spec.md` | First slice no longer reads as placeholder |

---

## Lane: Animation

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| AN.1 | Player animation set | planning | `docs/design/an1-player-animation-set-spec.md` | Player state reads clearly |
| AN.2 | Enemy animation set | planning | `docs/design/an2-enemy-animation-set-spec.md` | Enemy intent is readable before impact |
| AN.3 | Boss animation plans | planning | `docs/design/an3-boss-animation-plans-spec.md` | Boss changes are visible, not only numeric |
| AN.4 | Weapon animation set | planning | `docs/design/an4-weapon-animation-set-spec.md` | Every weapon has unique rhythm and silhouette |
| AN.5 | Child intervention animation | planning | `docs/design/an5-child-intervention-animation-spec.md` | Child help feels physical and emotional |
| AN.6 | AnimationTree QA | planning | `docs/design/an6-animationtree-qa-spec.md` | Animations are tunable in Godot |

---

## Lane: VFX And Combat Feedback

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| FX.1 | Telegraph language | planning | `docs/design/fx1-telegraph-language-spec.md` | Player can react before damage |
| FX.2 | Hit feedback | planning | `docs/design/fx2-hit-feedback-spec.md` | Hits feel satisfying but not noisy |
| FX.3 | Pickup feedback | planning | `docs/design/fx3-pickup-feedback-spec.md` | Important objects are noticeable |
| FX.4 | Defeat feedback | planning | `docs/design/fx4-defeat-feedback-spec.md` | Defeat reads without gore |
| FX.5 | Boss phase feedback | planning | `docs/design/fx5-boss-phase-feedback-spec.md` | Player understands phase shifts |
| FX.6 | Accessibility/readability pass | planning | `docs/design/fx6-accessibility-readability-pass-spec.md` | Threats remain visible in busy rooms |

---

## Lane: Audio

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| AU.1 | Audio identity | planning | `docs/design/au1-audio-identity-spec.md` | Audio matches child-room fantasy |
| AU.2 | Movement/attack SFX | planning | `docs/design/au2-movement-attack-sfx-spec.md` | Actions feel responsive |
| AU.3 | Enemy telegraph SFX | planning | `docs/design/au3-enemy-telegraph-sfx-spec.md` | Audio supports reaction timing |
| AU.4 | Child intervention SFX | planning | `docs/design/au4-child-intervention-sfx-spec.md` | Child actions feel physical |
| AU.5 | Music plan | planning | `docs/design/au5-music-plan-spec.md` | Music supports pacing |
| AU.6 | Mix pass | planning | `docs/design/au6-mix-pass-spec.md` | Telegraphs and damage are audible |

---

## Lane: UI, UX, And Tutorial

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| UI.1 | HUD scope | planning | `docs/design/ui1-hud-scope-spec.md` | HUD shows only what matters |
| UI.2 | Tutorial prompt style | planning | `docs/design/ui2-tutorial-prompt-style-spec.md` | Player learns without long text boxes |
| UI.3 | Rule Book design | planning | `docs/design/ui3-rule-book-design-spec.md` | Player can review learned rules |
| UI.4 | Pause/settings | planning | `docs/design/ui4-pause-settings-spec.md` | Game is usable for testing |
| UI.5 | Input remap/controller plan | planning | `docs/design/ui5-input-remap-controller-plan-spec.md` | Controls support fast combat |
| UI.6 | Accessibility options | planning | `docs/design/ui6-accessibility-options-spec.md` | More players can read the game |

---

## Lane: Narrative And Worldbuilding

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| NAR.1 | Story outline approval | planning | `docs/design/nar1-story-outline-spec.md` | Owner accepts emotional arc |
| NAR.2 | Opening script | planning | `docs/design/nar2-opening-script-spec.md` | Opening sets stakes quickly |
| NAR.3 | Child voice rules | planning | `docs/design/nar3-child-voice-rules-spec.md` | Child feels like companion, not narrator spam |
| NAR.4 | District story beats | planning | `docs/design/nar4-district-story-beats-spec.md` | Every area advances story |
| NAR.5 | Boss dialogue/behavior beats | planning | `docs/design/nar5-boss-dialogue-behavior-beats-spec.md` | Bosses feel like characters |
| NAR.6 | Ending script | planning | `docs/design/nar6-ending-script-spec.md` | Ending resolves pawn and child arc |

---

## Lane: Technical Architecture

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| TECH.1 | Scene ownership rules | accepted | Editor-first rules | Content lives in scenes/resources where practical |
| TECH.2 | Room transition system | planning | `docs/design/tech2-room-transition-system-spec.md` | Rooms connect logically |
| TECH.3 | Save/checkpoint system | planning | `docs/design/tech3-save-checkpoint-system-spec.md` | Restart behavior is reliable |
| TECH.4 | Gameplay sandbox | planning | `docs/design/tech4-gameplay-sandbox-spec.md` | Mechanics can be tuned without final art |
| TECH.5 | Automated tests | planning | `docs/design/tech5-automated-tests-spec.md` | Changes do not silently break core systems |
| TECH.6 | Performance budget | planning | `docs/design/tech6-performance-budget-spec.md` | Rooms run smoothly |

---

## Lane: Tools And Editor Workflow

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| TOOL.1 | Godot MCP workflow | accepted | MCP connection verified | Codex can open/run/edit basic scenes |
| TOOL.2 | Room authoring guide update | planning | `docs/design/tool2-room-authoring-guide-update-spec.md` | Owner can edit rooms confidently |
| TOOL.3 | Asset import rules | planning | `docs/design/tool3-asset-import-rules-spec.md` | Art imports consistently |
| TOOL.4 | Tile editing workflow | planning | `docs/design/tool4-tile-editing-workflow-spec.md` | Owner can change tiles manually |
| TOOL.5 | Review checklist template | planning | `docs/design/tool5-review-checklist-template-spec.md` | Owner feedback is structured |

---

## Lane: QA And Playtesting

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| QA.1 | Smoke test checklist | planning | `docs/design/qa1-smoke-test-checklist-spec.md` | Every build opens and plays |
| QA.2 | Room QA checklist | planning | `docs/design/qa2-room-qa-checklist-spec.md` | Rooms are judged consistently |
| QA.3 | Combat feel tests | planning | `docs/design/qa3-combat-feel-tests-spec.md` | Combat decisions are based on play |
| QA.4 | Bug tracking format | planning | `docs/design/qa4-bug-tracking-format-spec.md` | Bugs are reproducible |
| QA.5 | Vertical slice test plan | planning | `docs/design/qa5-vertical-slice-test-plan-spec.md` | Slice can be tested end-to-end |

---

## Lane: Release And Presentation

| ID | Task | Status | Deliverable | Definition of Done |
|---|---|---|---|---|
| REL.1 | Vertical slice package | planning | `docs/design/rel1-vertical-slice-package-spec.md` | Demo can be shared/tested |
| REL.2 | Screenshot plan | planning | `docs/design/rel2-screenshot-plan-spec.md` | Screens show gameplay and style clearly |
| REL.3 | Trailer capture plan | planning | `docs/design/rel3-trailer-capture-plan-spec.md` | Trailer explains fantasy and combat |
| REL.4 | Store/page description | planning | `docs/design/rel4-store-page-description-spec.md` | Game is explainable to new players |
| REL.5 | Final build checklist | planning | `docs/design/rel5-final-build-checklist-spec.md` | Release candidate is trackable |

---

## Current Active Parallel Gates

These can move forward together after owner approval:

| Aspect | Active Gate | Can Move Alongside |
|---|---|---|
| Gameplay | `GP.1` approve core loop | Level, Enemy, UI, Technical |
| Level Design | `LD.2` approve first room chain | Gameplay, Art, Technical |
| Art Direction | `ART.1` lock visual target | Level, Animation, UI |
| Technical | `TECH.2` plan room transition system | All lanes |
| Narrative | `NAR.1` approve story outline | Level, UI, Audio |

Recommended immediate parallel review batch:

```text
Review full-gameplay-design-v2.md.
Approve or revise GP.1, LD.2, ART.1, TECH.2, and NAR.1 as separate gates.
Then plan T1_WhiteKingsFall and the gameplay sandbox in parallel.
Build only the specific tasks that have been approved.
```
