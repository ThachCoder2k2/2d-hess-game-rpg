# THE UNBOUND PAWN — THE GAME BASE PLAN

Version 1.1 · 2026-10-12 · branch `game-base` (HEAD `f122db0`) · lead designer and technical architect · status: PLAN ONLY (nothing here is built yet; the repo was checked read-only)

**Summary.** The Unbound Pawn is a Godot 4.6.3 top-down grid action-adventure about a white pawn that breaks free of chess rules inside a child's imagined chess war in a bedroom. This plan describes ONE complete, playable, testable base that runs from the title screen through six acts and an ending to the credits. Every system the final game needs exists, is data-driven on the existing ECS runtime, and is fed by placeholder content that the owner replaces by hand: art, prose, music and tuning. Version 1.1 folds in four adversarial reviews (technical feasibility, emotion and story, completeness, progression and ECS). The main changes are:

- A scripted, text-level migration toolchain (UID stamping, safe moves) and a test harness that cannot hang or pass vacuously.
- A leaner entity pipeline that keeps today's `EnemyDefinition` + `ActorView` + `EntityComponent` design.
- Runtime seams landed once, early: commands, tuning, input snapshot, cell kinds, player carry and a HUD snapshot.
- An attack-stage framework before any new enemy family.
- Six verbs plus one shipped worked example, instead of seven.
- No Rest Squares and no Rank-derived power, which keeps the owner's 2026-07-28 cut intact.
- A Believe economy that can never soft-lock.
- A playable ending, relationship-keyed death resets, an explicit clue chain, a requirement ledger, and 20 smaller milestones with four owner-play gates.

**Authority order.**
1. The owner's directions of 2026-10-12 (verbatim below).
2. `CLAUDE.md`. Where this plan departs from it, §2.4 lists the exact change, and the departure takes effect only after the owner signs off at gate OG0. Until then `CLAUDE.md` wins.
3. `docs/ecs-conversion-plan.md`.
4. This plan.
5. Older docs (`AGENTS.md`, `docs/ARCHITECTURE.md` and `docs/coding-standards.md` still describe the retired node era and are wrong).

Where this plan departs from an older doc, §2 says so.

## 0. The owner's directions, verbatim and numbered

These are the only verbatim owner texts in this task (translated from Vietnamese by the harness). Every "Follows" cell in §2 cites one of them as `OWNER-10-12 #n`, or marks the row `OWNER-OLDER(date)`, `RULE(file)` or `PROPOSAL`.

| # | Owner direction, 2026-10-12 |
|---|---|
| #1 | "A game is not only gameplay — it must tell a story. Build ONE complete base with everything; I will do the art and upgrade the story myself. Make it as perfect as possible before I jump in. Research human emotions when playing games. I trust you." |
| #2a | "The gameplay must also have a proper PROGRESSION path and proper SKILLS." |
| #2b | "Arrange the code and folders so I can jump in and handle things WITHOUT changing too much — based first of all on the ECS design pattern." |

| Owner direction | Where it is answered |
|---|---|
| #1 Tell a story; ONE complete base; art and story upgrades are the owner's | §1, §4, §8, §12 |
| #1 Research human emotion in games | §3 (frameworks, arc, rules R1-R37) |
| #2a Proper progression and proper skills | §6 (six verbs plus one worked example, Pages, Margin, curve, extension recipes) |
| #2b Code and folders arranged for the owner, ECS first | §13 (tree, change table), §14, M1a-M3b in §15 |
| #1 "Everything" and the old complaint "you never delivered all the requirements" | §1.4 scope tiers, §1.5 and the requirement ledger |

**Evidence labels.**
- `[repo]` is a path:line from the research.
- `[measured]` means a file was opened on 2026-10-12 (plan author or reviewer).
- `[start value]` means a number chosen by the plan, to be tuned in playtest. It is not a sourced constant.
- `[unverified]` means a claim the plan relies on that a named milestone must prove first.
- Web sources are cited by short name (see the Source key).

**Requirement numbers.** `req#i` means `docs/requirements.json` `requirements[i]`, zero-based, as in the review notes. The research the plan was built from is in `docs/research/` (emotion, story, progression, organisation, codebase).

**Source key (repo).**
- `gdd` = docs/design/gdd.md
- `v2` = docs/design/full-gameplay-design-v2.md
- `flow` = docs/production/act-1-opening-to-first-boss-flow-map.md
- `t1spec` = docs/production/t1-white-kings-fall-production-spec.md
- `soul` = docs/soulslike-world-plan.md
- `bible` = docs/design/enemy-behavior-bible.md
- `where` = docs/where-we-are.md
- `eco` = docs/ecs-conversion-plan.md
- `nar1`..`nar6`, `gp1`..`gp7`, `en1`..`en7`, `fx1`..`fx6`, `ui1`..`ui6`, `au1`..`au6`, `ld1`..`ld7` = docs/design/<id>-*-spec.md

**Source key (web).**
- Lazzaro: https://www.nicolelazzaro.com/the4-keys-to-fun/
- SDT: https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf
- MDA: https://cdn.aaai.org/Workshops/2004/WS-04-04/WS04-04-001.pdf
- Chen (flow): https://www.jenovachen.com/flowingames/p31-chen.pdf
- Gutwin (peak-end): https://www.benlafreniere.ca/assets/papers/p5608-gutwin.pdf
- Juul: https://www.penguinrandomhouse.com/books/656618/the-art-of-failure-by-jesper-juul/
- Hitchcock bomb: https://nevalalee.wordpress.com/2011/10/26/the-bomb-under-the-table/
- Bopp (moving experiences): https://research.aalto.fi/en/publications/negative-emotion-positive-experience-emotionally-moving-moments-i/
- Pathos in Play: https://arxiv.org/abs/1909.06799
- Swink: http://mycours.es/gamedesign2014/files/2014/10/Game-Feel-Steve-Swink-chapter-1.pdf
- Nintendo four-step: https://mcvuk.com/business-news/publishing/video-nintendos-level-design-secrets-in-four-steps/
- Schreiber: https://gamebalanceconcepts.wordpress.com/2010/08/18/level-7-advancement-progression-and-pacing/
- Sid Meier: https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions
- Dreamnoid: https://dreamnoid.com/articles/how-to-create-your-own-metroidvania
- Zelda dungeons: https://thecolorandshapeofplay.substack.com/p/how-zelda-dungeons-prepare-you-for
- Hades narrative: https://www.gamedeveloper.com/design/how-supergiant-weaves-narrative-rewards-into-i-hades-i-cycle-of-perpetual-death
- Godot pausing: https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
- Godot RichTextLabel: https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html
- Godot i18n: https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html
- Godot project organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Godot UIDs: https://godotengine.org/article/uid-changes-coming-to-godot-4-4/
- `ResourceLoader.list_directory`: https://github.com/godotengine/godot/pull/96590
- Dialogue Manager: https://github.com/nathanhoad/godot_dialogue_manager
- Flecs prefabs: https://github.com/SanderMertens/flecs/blob/master/docs/PrefabsManual.md
- GDQuest layering: https://www.gdquest.com/library/modular_game_architecture/
- Unity baking: https://docs.unity3d.com/Packages/com.unity.entities@1.4/manual/ecs-workflow-example-authoring-baking.html
- Caves of Qud blueprints: https://wiki.cavesofqud.com/wiki/Modding:Objects

---
## 1. What "complete base" means

**Definition.** The base is a game the owner can start, play to the credits and then change one data file at a time. It is a finished skeleton with finished anatomy. Every system the final game needs exists, works and is tested. Each system is fed by placeholder content that is data: art, prose, music and tuning numbers. The owner replaces the placeholders by hand without touching code. "Complete" is audited, not claimed: §1.4 sorts every item into a scope tier, and §1.5 maps all 249 requirements in `reqs.json` to a section, a milestone and a test (or an explicit owner waiver).

### 1.1 Definition of done

The base is done when every line below is true and proven by the test or check named in §15-§16.

| # | Done means |
|---|---|
| D1 | Cold start on a clean clone (after `tools/bootstrap_worktree.sh`): `boot -> title -> New Game -> T1 ... -> Ending -> Credits -> Title (completed mark)` in one sitting. Keyboard or gamepad, no editor, no script errors in the log. |
| D2 | 34 shipping rooms (31 on the critical path, 3 optional) plus `dev_sandbox` (list in §7). Each is at least GREYBOX status, connected by the world graph, with every lock explained in text. |
| D3 | Six bosses (Captain, Knight, Bishop, Rook, Queen, King), each with phases, intro/phase/defeat beats, phase checkpoints, a player-executed kill and a permanent defeat. |
| D4 | Six verbs (Sword, Pencil Thrust, Rule Step, Chalk Path, Eraser Guard, Free Step) on ONE generic skill system. Chalk Block ships as the worked example of "a new effect kind", and the Lead Tip Annotation ships as the worked example of a `SkillUpgrade`. Five Rule Pages plus Lore entries for every piece and boss, Margin, six Courage Shards, Believe and the Rank label. The HUD is generated from data. In Passing, Ruler Gate, Castling and the other Annotations are documented extension recipes (§6.10). |
| D5 | Six enemy families (pawn family with Recruit, Armed, Backstep and Charging; knight; bishop; rook; queen; king) with the identity table of §5. Each family is previewed before its first lethal use. |
| D6 | Child layer: hand, shadow, crayon, Believe, scripted help, free traversal calls, Chalk Path and Chalk Block, disruption in Act 5, cut-off in Act 6, and a zero-text presence layer (§4.5). |
| D7 | The whole story of §4 exists as `StoryBeat` data plus placeholder lines in `.po`. Zero literal story strings in scripts or scenes (grep-tested). A six-clue prop chain shows the shape of the child's loss without stating it (§4.8). |
| D8 | Shell: title, Continue and New Game over one save slot (the API is slot-aware), pause, settings, gamepad, credits, playable ending. |
| D9 | Save format v3, migration from v2, atomic writes with `.bak` fallback, autosave on success events only. |
| D10 | Death: control returns in 5 s or less, the death frame is held 0.6 s or more, nothing is lost, cleared rooms stay cleared (D-17), the reset presentation follows the relationship with the child. |
| D11 | Feel: hit-stop, particles, flash, shake (with settings), the telegraph colour-and-pattern language, red reserved for danger. |
| D12 | Audio: the bus layout is fixed (the SFX bus really exists). `sound_bank` and `music_cues` cover every event and state. A minimal `MusicDirector` and the child's SFX set exist from M6. Every placeholder is flagged. |
| D13 | Accessibility: reduce shake, reduce flash (at most 3 flashes per second, tested), high-contrast danger with patterns, telegraph time, enemy pace, extra Courage, input forgiveness, hold-or-toggle for held actions, UI high contrast. |
| D14 | Localization: all text comes through keys. `en` is complete. A missing-key test and a pseudo-locale layout test exist. The source language is an owner decision (O-4). |
| D15 | The art-swap contract is tested. `tools/list_placeholders.gd` prints the owner's remaining TODO list from content hashes, so overwriting a file clears its flag with no extra edit. |
| D16 | Layout per §13. Architecture guards are enforcing. Every row of the Owner Change Table (§13.5) has been dry-run once on a temp copy under `user://`, never in the working tree. |
| D17 | `python3 tools/run_all_tests.py --strict` is green, every baseline `PASS:` label from the pre-restructure suites still passes (or is listed in `tests/label_renames.txt`), and the suites listed in §15 exist. |
| D18 | Every room and beat carries `emotion_target`, `release_beat`, `lazzaro_key`, `intensity` (rule R1). The check is a soft lint (see §3.5). |
| D19 | `docs/OWNER_GUIDE.md` (Vietnamese first, English authoritative), `content/README.md` and a handoff note (Open/Tune/Goal/Try/Tell me) per system. |
| D20 | `LICENSE` and `THIRD_PARTY_NOTICES.md` exist and the credits include them (Tier A). A macOS export smoke runs from a tracked preset template (Tier B). |
| D21 | An automated route test boots every critical-path room in order from boot to credits in under 90 s headless. A manual feel checklist covers what headless cannot prove. |
| D22 | No soft-lock. Every lock has a reachable opener, mandatory verbs are separated from optional verbs (§6.8), and the walk also holds under the worst resource state (Believe 0, Courage 1, cooldowns running). |
| D23 | Time to control is 10 s or less from New Game or Continue (R2). |
| D24 | Zero `STUB` rooms remain. |
| D25 | The requirement ledger (§1.5) has no `must` row that is uncovered or unwaived. `tests/content/test_requirements_ledger.gd` enforces it. |
| D26 | The ending is the player's act: the last input before the final hold is a step by the player (R30). |
| D27 | Four owner-play gates (OG1-OG4, §15) have been passed, or each is logged in `progress.md` as "no owner response, defaults taken". |

### 1.2 What the base does NOT include, and how the owner swaps each

Deferred items carry their `req#`, so the owner can overrule any deferral. A `must` requirement can only be deferred with a waiver listed here.

| Not included | req# | Why | How the owner swaps or adds it |
|---|---|---|---|
| Final art (sprites, tiles, UI skin, portraits, child hand, VFX) | 149, 156 | Art direction is human-owned (`AGENTS.md:64-90`). The owner judged AI art poor and will hand-draw. | Overwrite named PNGs in `content/<kind>/<id>/` (§12). Nothing else needs editing. |
| Final writing | 198 | Tone and story are the owner's. All prose is placeholder and flagged `placeholder`. | Edit `msgstr` rows in the `.po` files (§8), or edit the text-first script (§8.2). Structure stays in `.tres`. |
| Final music and SFX | 173, 176 | Current audio is generated chiptune. | Drop a file in `assets/music/` or `assets/sfx/` and edit one row of `music_cues.tres` or `sound_bank.tres` (§11). |
| Voice acting | n/a | Out of scope (`gdd:557`). | Not needed. Dialogue uses per-speaker blips. |
| Languages other than the source language; Vietnamese glyph test | 197 | Agent-written Vietnamese prose cannot be reviewed (O-4). | Fill `vi/*.po`. The font shortlist in M4 is checked for Vietnamese coverage only if the owner picks `vi` as source. |
| Key remapping UI | 12 | Waiver (should). `InputMap` defaults, gamepad defaults and generated hints ship. Remap conflicts are not an issue until a UI exists. | Recipe in `content/README.md`: edit the `[input]` section of `project.godot`, or add a settings tab later. |
| Multi-slot save UI, slot delete and copy | n/a | One slot is enough for the base. | The `SaveService` API takes a slot id from day one; a slots screen is a UI-only change. |
| World map screen | 121 | Waiver (could). `map_slot` data and the map backdrop ship in `world.tres`; `tools/print_world_map.gd` prints an ASCII map. | Add a screen that reads `world.tres`. |
| Captions UI, text-size and text-speed options, dialogue history UI | 195 | Waiver (should) for text speed and size. The schema ships: `caption_key` on every `sound_bank` row, a `dialogue_log` flag array. | UI-only additions later. |
| Branching dialogue and a dialogue addon | 201 | Branching campaigns are out of scope (`gdd:555`). Addons need owner approval. | Optional Dialogue Manager adoption (§8.10). The seam is `StoryDirector.play(beat_id)`. |
| XP, levels, currency, shops, bonfires, Rest Squares, corpse run | n/a | Cut by the owner on 2026-07-28 (`soul:4-8, 96-97`). | Never added (§2.3 shows the one departure the plan keeps: cleared rooms stay cleared). |
| Child calls Paper Bridge, Erase Rule Mark, Ruler Gate, Turn the Board; Gentle Nudge | 45, 46, 47, 48, 49 | Deferred extensions (45 should; the rest could). Gentle Nudge is removed and replaced by a scripted room change (D-14). | Each is one `SkillDefinition` plus a room marker (§6.10). Turn the Board needs one new effect kind. |
| In Passing, Passant Wraith, Castling, Promoted Zealot, Veteran and Desperate pawns, Marble Launcher, Wind-Up Hammer | 74, 75, 104 | Deferred. The base ships six verbs with full teaching instead of seven with one that had no valid target (see §6.10 E1, E3). | Recipes in §6.10. |
| Annotations other than Lead Tip | n/a | One ships as the `SkillUpgrade` worked example. | Recipe in §6.10 E4. |
| Targeting mode and time-slow | 51 | Dropped (D-20). Enemy Pace (§5.8) covers "slow enemies while the pawn is stationary" (req#33). | n/a |
| Boss camera pull-back | 119 | Dropped (R25): awe is shown by painted vistas and parallax at integer scale, not live zoom. | Owner art. |
| Separate shadow sprites, PointLight2D lighting | 151, 152 | Could-haves. | Owner art pass. |
| Windows or Linux export, Steam page, trailer, screenshots, store text, public demo plan | 241 (Windows and Linux only), 243, 244 | Waiver. Release lane, not the base. | `rel1-4` specs. |
| macOS notarization | 241 | Owner-only: needs the owner's Apple account. | `docs/release-checklist.md` lists the steps. |
| Outside playtest results | 240 | Agents cannot produce them. | Owner and testers use `docs/playtest-form.md` (M14); the attempt logger and decision-gap metric ship in M8c. |
| Cancel a dangerous step before leaving the start cell | 5 | Could-have. | Later input-system change. |
| Enemy decision log (last 100) | 90 | Could-have. The F3 overlay and the attempt logger cover tuning. | Later. |

### 1.3 Content status ladder (used by tools and tests)

`STUB` (placeholder shape, reachable) -> `GREYBOX` (playable layout, real enemies and beats) -> `DRESSED` (placeholder art in place) -> `FINAL` (owner art). It lives in `RoomEncounter.content_status`. `tools/list_placeholders.gd` reports counts per status and lists every asset whose content hash still equals the seeded hash in `content/_placeholders.json` (§12). At the end of M14 the base has no `STUB`. Rooms are `GREYBOX` or `DRESSED`, and `FINAL` is the owner's mark.

### 1.4 Scope tiers and the cut order

The reviews found that the full wish list is about 35-40 percent more than the milestone budget can verify. The plan therefore sorts every item into a tier, and each milestone in §15 names its Tier B items separately.

- **Tier A (the base).** Everything in §1.1 not marked Tier B. A milestone is not done until its Tier A items pass.
- **Tier B (cut-first, in this order if a milestone overruns).** Each is data-only or UI-only, and cutting it never breaks a Tier A test.
  1. macOS export smoke and a CI workflow file (M14). A documented local equivalent stays.
  2. Colour-blind simulation screenshot pass, dialogue log, first-run card (M14).
  3. Night tint application (`time_of_night` stays as inert data) (M5/M14).
  4. The `dh1` tea-party format-breaker and the Tier-2 cutscene worked example (M12, M6).
  5. Ending variants keyed to rescues, hub-resident reflections for Slant and Stout (M13).
  6. Sprite-sheet block and sound-id overrides in `VisualDefinition` (M2, M14).
  7. Flag registry drop-downs and `renamed_from` save migration (M14).
  8. Act 6 `DirectionLock` (M13). The fallback keeps "Close the Box" as help-blocked only, and the memory alcoves become lore.
- **Tier C (deferred, with a waiver in §1.2).** Items listed there.

Lint tiers follow the same split. **Hard** checks (engine integrity: dangling ids and keys, soft-locks, schedule order, the telegraph contract R6, the player-kill-only rule R14, architecture edges, sidecars) fail every run. **Soft** checks (emotion fields, word counts, threat budgets, preview-first, arc shape) are warnings in the editor so the owner's rewrites never turn the suite red. Agent gates run `--strict`, which promotes soft warnings to failures on the shipped base content.

### 1.5 Requirement ledger

The ledger below lists `reqs.json` `requirements[0..248]`: `req#`, priority (m must, s should, c could), the first words of the requirement, the plan section, the milestone, the verifying test and a status (`covered`, `amended D-xx`, `deferred W` for an owner-waivable deferral in §1.2, or `partial: <what is missing>` for a requirement that is only partly verified yet, with the gap named). M1a writes it to `docs/requirements_ledger.md`, and `tests/content/test_requirements_ledger.gd` parses it and fails if a `m` row has no section plus test or waiver (D25). Numbers are zero-based: `req#45` is "Place Paper Bridge over broken tiles".

#### Ledger, req# 0-124

| req# | P | Requirement (start) | Plan section | Milestone | Verified by | Status |
|---|---|---|---|---|---|---|
| 0 | m | One-cell cardinal step per input, no diagonal movement | §5.1 | exists; M3a keeps | baseline labels | covered |
| 1 | m | Step duration about 0.16-0.20 s (target 0.18 s) | §5.1 | exists; M3a keeps | baseline labels | covered |
| 2 | m | Held direction repeats a step after about 0.22 s | §5.1 | exists; M3a keeps | baseline labels | covered |
| 3 | s | Input buffer of about 0.12 s that expires (code buffers one... | §5.1, §9.4 | M7b | test_input_buffer | amended T-1 |
| 4 | m | Pawn faces its last movement direction, also when the step i... | §5.1 | exists | baseline labels | covered |
| 5 | c | A dangerous step may be cancelled only before the pawn leave... | §1.2 | n/a | n/a | deferred W |
| 6 | m | Shift+direction turns instantly without moving or reserving... | §5.1 | exists | baseline labels | covered |
| 7 | s | Turning cannot interrupt an active step or an attack impact... | §5.1 | M7b | test_turn_lock | covered |
| 8 | s | Blocked step gives visible or audible bump feedback, never s... | §10 | M8c | test_step_blocked_feedback | covered |
| 9 | m | Reserve-then-commit grid occupancy; both cells held during a... | §5.11 | M3a | test_leap_occupancy; baseline labels | covered |
| 10 | s | Pixel-snapped motion and camera, no subpixel blur (camera ea... | §10, D-30 | M4 | test_camera_snap; test_piece_slide_snap | covered |
| 11 | m | Every gameplay verb has a keyboard and a controller mapping... | §9.4 | M4 | test_input_actions_have_pad_events | covered |
| 12 | s | Full input remapping | §1.2 | n/a | n/a | deferred W |
| 13 | m | InputMap actions for Interact (E), Call child (R), Select he... | §9.4 | M4, M7a | test_input_actions_have_pad_events | covered |
| 14 | s | B, F3 and F11 become InputMap actions instead of raw key polls | §9.4 | M4, M7a | test_input_actions_have_pad_events | covered |
| 15 | m | Room restart must not share the R key with Call child; resta... | §9.4, D-18 | M4 | test_pause_restart_is_menu_only | covered |
| 16 | s | Controls explainable in one small panel (today a static Help... | §9.2 | M4 | test_controls_panel_from_inputmap | covered |
| 17 | m | Wooden Sword hits one adjacent cell in the facing direction;... | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 18 | m | Sword recovery about 0.30 s so spamming is worse than reading | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 19 | m | Pawn cannot move during the first part of a swing (MovementS... | §5.1 | M7b | test_move_lock | amended T-8 |
| 20 | s | A hit staggers common enemies briefly | §5.1 | M7b | test_stagger | amended T-8 |
| 21 | s | Attacking an armored face causes recoil and no damage | §5.1 | M11 | test_armor_recoil | covered |
| 22 | m | No combo strings | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 23 | m | Target cells locked at swing start; one damage application p... | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 24 | m | Player invulnerability window after a hit (0.7 s) | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 25 | m | Pencil Thrust: two-cell line on Q, impact 0.11 s, recovery 0... | §6.3 verb 2 | M7b | test_combat_parity | covered |
| 26 | m | Enemy telegraph locks target cells so stepping out dodges; t... | §5.10 | M8a | test_attack_stages; baseline labels | covered |
| 27 | m | One room-level attack token prevents simultaneous enemy stri... | §5.10 | M8a | test_attack_stages; baseline labels | covered |
| 28 | s | Hit feedback: flash, chip particles, small shake (stronger o... | §10 | M8c | test_hit_stop_restores_time_scale | covered |
| 29 | m | Sword attack refused before the sword unlock, with HUD feedb... | §6.3 | M7c | test_unlock_gating | covered |
| 30 | s | Player loadout of one toy weapon plus up to two Imagination... | §6.4 | M7c | test_pages_margin | amended D-12 |
| 31 | s | Weapons change rhythm and geometry (Pencil Spear, Ruler Blad... | §6.3 | M7a, M7b | test_skill_cooldowns | covered |
| 32 | s | Focus: hold to emphasise enemy telegraphs without stopping t... | §10 | M8c | test_focus_emphasis | covered |
| 33 | c | Assist option that slows enemies while the pawn is stationary | §5.8 | M8a | test_tuning_scales | covered |
| 34 | s | F3 debug overlay explains each enemy decision, off by defaul... | §9.2 | M14 | test_debug_overlay_default | covered |
| 35 | m | Rule Step: fast two-cell emergency move with cooldown, earne... | §6.3 verb 3 | M7a | test_rule_step | amended D-37 |
| 36 | m | Chalk Path: child-assisted temporary walkable route, earned... | §6.3 verb 4 | M10 | test_chalk_rules | covered |
| 37 | m | Eraser Guard: guard or parry against straight-line attacks,... | §6.3 verb 5 | M11 | test_guard_tags; test_perfect_rub | covered |
| 38 | m | Final Rule Break: one-time story power (first unassisted dia... | §6.3 verb 6 | M12, M13 | test_free_step_window; test_free_step_rehearsal | amended D-14 |
| 39 | m | Each skill has a boss or room that earns it, a safe teach, a... | §6.6 | M5, M9-M13 | test_verb_exam | covered |
| 40 | m | Skills change decisions and never replace one-cell movement | §6.2 P1-P7 | M7a | test_rule_step | covered |
| 41 | m | HUD shows only unlocked skills with cooldown (Q THRUST only... | §6.2 | M7a | test_hud_slots_from_data | covered |
| 42 | m | Child intervention system with a Believe meter (max 2 calls;... | §5.5 | M10 | test_believe_rules | covered |
| 43 | m | Place or Move Block on a highlighted empty cell: stops proje... | §5.5 | M11 | test_chalk_block | amended D-37 |
| 44 | m | Draw Chalk Path across up to three gap cells; fades in boss... | §6.3 verb 4 | M10 | test_chalk_rules | covered |
| 45 | s | Place Paper Bridge over broken tiles | §1.2, §6.10 | n/a | n/a | deferred W |
| 46 | c | Erase Rule Mark disables a marked hazard or lock briefly | §1.2, §6.10 | n/a | n/a | deferred W |
| 47 | c | Hold Ruler Gate opens a shortcut or timed path | §1.2, §6.10 | n/a | n/a | deferred W |
| 48 | c | Turn the Board rotates an authored marked room section 90 de... | §1.2, §6.10 | n/a | n/a | deferred W |
| 49 | c | Gentle Nudge moves the pawn one otherwise illegal diagonal c... | §2.1 D-14 | n/a | n/a | amended D-14 |
| 50 | m | Help changes the room, never enemy HP, and cannot clear a ph... | §5.5 | M10 | test_child_help_not_damage | covered |
| 51 | s | Targeting mode: valid cells in blue within 5 cells, time slo... | §2.1 D-20 | n/a | n/a | amended D-20 (waiver) |
| 52 | m | Child hand sprite: larger and smoother than the chess world,... | §12 | M6 | test_art_contract | covered |
| 53 | s | Child actions animate physically, slower and heavier than pa... | §5.5 | M6, M10 | manual feel checklist (M14) | covered |
| 54 | s | Child intervention sounds from crayon, paper, block, eraser,... | §11 | M6 | test_sound_bank_coverage | covered |
| 55 | m | Bosses can temporarily disrupt help (Queen Tear Drawing, Kin... | §5.4 | M12, M13 | test_quiet_beat_after_disable | covered |
| 56 | m | Interventions authored per room (allowed types and placement) | §5.5, §7.5 | M10 | test_allowed_calls | covered |
| 57 | s | Crayon-blue visual language reserved for child help | §10 | M8c | palette lint (R7) | covered |
| 58 | m | Three Courage points; boss signature attacks may remove two | §5.1 | exists | baseline labels | covered |
| 59 | s | Rescued white pieces restore one Courage at fixed safe locat... | §2.1 D-34, D-40 | M3b, M6 | test_checkpoint_rules; test_rescue_in_h1 | amended D-34 |
| 60 | m | On defeat return to the latest checkpoint with the room rese... | §5.2 | M3b | test_checkpoint_rules; test_owner_guide_steps | amended D-16 |
| 61 | m | Boss defeat resets the boss room to phase one, retries are f... | §5.4, D-43 | M8b | test_boss_phase_checkpoints | amended D-43 |
| 62 | m | Checkpoints before bosses, at hubs, after major rewards | §5.2 | M3b | test_checkpoint_rules | covered |
| 63 | m | Pickup reset rule: room pickups reset unless marked persiste... | §9.3 | M3b | test_pickup_persistence | covered |
| 64 | s | Low-health state gets feedback (colour change only today) | §10 | M8c | test_low_health_feedback | covered |
| 65 | s | Death rule explainable in one sentence; copy 'The child rese... | §4.6 | M8c | prompt.reset in test_prompts | covered |
| 66 | m | Major unlocks persist across death | §9.3 | M3b | test_save_roundtrip | covered |
| 67 | m | Persist zone, entry, taken pickups, opened gates, unlocks, r... | §9.3 | M3b | test_save_roundtrip | covered |
| 68 | m | New Game, Continue and a clean-start path (WorldState.reset... | §9.1 | M4 | test_new_game_resets_slot | covered |
| 69 | m | Cleared rooms and defeated bosses persist (bosses never reset) | §9.3, §5.4 | M3b, M8b | test_save_roundtrip; test_boss_defeat_persists | covered |
| 70 | m | Settings (volume, shake, accessibility) persist | §9.2 | M4 | test_settings_roundtrip | covered |
| 71 | s | Save format versioned so it can grow; an old save must not b... | §9.3 | M3b | test_save_migration_v2 | covered |
| 72 | m | Pawn Recruit: moves one cardinal cell, faces last move, slow... | §5.3 | M8a | test_enemy_identity_table; baseline labels | covered |
| 73 | m | Armed pawns: a toy weapon replaces the diagonal attack; Penc... | §5.3 | M8a | test_enemy_identity_table; baseline labels | covered |
| 74 | s | Pawn variants each bend exactly one rule: Backstep and Charg... | §5.3, §6.10 | M9, M10; Wraith and Zealot deferred | test_enemy_placement | deferred W (Wraith, Zealot) |
| 75 | c | Veteran and Desperate pawn variants | §1.2, §6.10 E7 | n/a | n/a | deferred W |
| 76 | m | Knight: L-shaped locked telegraph, leap, left vulnerable aft... | §5.3 | M8a, M9 | test_knight_leap_occupancy | covered |
| 77 | s | Knight shadow shows the destination and the knight leaves gr... | §5.10 | M8a | test_knight_leap_occupancy | covered |
| 78 | m | Bishop: long diagonal lane with a telegraph that grows outwa... | §5.3 | M10 | test_bishop_growth | covered |
| 79 | s | Mirror and Torn Bishop variants (mirrors and folded paper re... | §5.3 | M10 (Oracle mirrors); variants deferred | test_mirror_bounce | deferred W (variants) |
| 80 | m | Rook: locks a row or column, charges until blocked, breaks f... | §5.3 | M11 | test_ray_stops_at_blockers | covered |
| 81 | s | Rook must turn in place before changing attack axis; Wooden... | §5.3 | M11 | test_rook_turn_tell | covered |
| 82 | m | Queen maneuvers Royal Line, Royal Diagonal, Command Mark, Se... | §5.4 | M12 | test_queen_phases | covered |
| 83 | m | King: one-cell movement, King's Reach (8 cells), Lock Direct... | §5.4 | M13 | test_king_phases | covered |
| 84 | m | Every enemy has a distinct role, a tell before damage, and a... | §5.3 | M8a | test_enemy_identity_table | covered |
| 85 | s | Aggro leash so far enemies stay idle | §7.1 fixtures | exists; M1b moves to tests/fixtures | kingdom and first_encounter fixture tests | covered |
| 86 | s | Weapon pickup reservation and abandonment rules | §7.1 fixtures | exists; M1b moves to tests/fixtures | kingdom and first_encounter fixture tests | covered |
| 87 | m | Encounter recipes: Pawn Intro, Pair, Armed Lesson, Knight Pr... | §7.4, R4, R28 | M5 | test_room_data_audit | covered |
| 88 | m | Introduce one new geometry at a time; near group at most two... | §7.4, R4, R28 | M5 | test_room_data_audit | covered |
| 89 | s | Automated response-cell validation for every authored combin... | §5.10 | M8a (Tier B) | test_response_cells | covered |
| 90 | c | Enemy decision log (last 100) and playtest metrics | §1.2 | n/a | n/a | deferred W |
| 91 | m | Armed enemies replace, never stack, the chess attack | §5.3 | exists | baseline labels | covered |
| 92 | m | Boss framework: phases by condition, authored maneuvers (tel... | §5.4, §5.10 | M8b | test_boss_phase_swaps | covered |
| 93 | m | Boss HUD bar shown only during boss fights | §5.4 | M8b | test_boss_bar_only_in_fights | covered |
| 94 | m | Arena seal (Black Line) on entry, short runback, defeat stor... | §5.4 | M8b | test_boss_defeat_persists | covered |
| 95 | m | Phase change is visible and mechanical: animation, arena or... | §5.4 | M8b, M8c | test_boss_phase_differs | covered |
| 96 | m | B1 Black Pawn Captain with three phases (slow diagonal; shov... | §5.4 | M8b | test_boss_phase_swaps | covered |
| 97 | m | Knight Captain, three phases (one mark; two cells with late... | §5.4 | M9 | test_knight_captain_phases | covered |
| 98 | m | Bishop Oracle: beams, mirrored beams, drawn path across isla... | §5.4 | M10 | test_bishop_oracle_phases | covered |
| 99 | m | Rook Warden: one line, breaks weak blocks, needs Eraser Guar... | §5.4 | M11 | test_rook_warden_phases | covered |
| 100 | m | Queen of Tricks: lanes, armed-pawn summons, disables a child... | §5.4 | M12 | test_queen_phases | covered |
| 101 | m | Black King and Rule Engine: four phases, child help blocked... | §5.4 | M13 | test_king_phases | covered |
| 102 | s | Bosses are defeated, not killed; broken pieces become ordina... | §5.4 | M8c | test_defeat_becomes_toy | covered |
| 103 | s | A boss rule amendment is written into the Book of House Rule... | §5.4 | M9 | test_book_flip_midfight | covered |
| 104 | c | Promoted Zealot elite guarding the boss door | §1.2, §6.10 E7 | n/a | n/a | deferred W |
| 105 | m | Rooms are separate editable scenes with the standard tree (R... | §7.5 | M5 | test_room_tree | covered |
| 106 | m | Room metadata: zone_id, board_size, room_message, objective,... | §7.5 | M5 | test_room_status | covered |
| 107 | m | World graph as one resource; every door resolves to a real z... | §7.1, §7.5 | M5 | test_world_graph | covered |
| 108 | m | Exit data: target_zone, target_entry, requires_flag, locked_... | §7.1, §7.5 | M5 | test_world_graph | covered |
| 109 | m | Fade-swap transition and spawn at the target entry | §9.1 | exists; M1a | test_bridge_travel | covered |
| 110 | m | Backtracking works unless intentionally blocked | §9.1 | exists; M1a; fixed in the M3b review | test_bridge_backtracking (the hero walks H1 -> B1 -> T4 -> T3 -> T2 -> T1 on foot); test_room_doors_reachable (every door of every room is floor, reachable, and leads to a real entry) | covered |
| 111 | m | Each locked exit explains why it is locked (code has one har... | §5.7 | M5 | test_world_graph | covered |
| 112 | m | Locks are visible before they open and tied to skill, story... | §5.7 | M5 | test_world_graph | covered |
| 113 | m | One-way shortcut gates opened from the far side stay open fo... | §5.7 | exists | gate fixture test | covered |
| 114 | m | Shortcut back to the hub at the end of every district (mecha... | §7.2 | M9-M13 | test_district_shortcuts | covered |
| 115 | m | Stage 1 chain T1-T2-T3-T4-B1-H1 wired and playable | §7.4 Act 1 | M5, M6 | test_full_route | covered |
| 116 | m | Decide the fate of legacy world content: 72x40 kingdom, firs... | §2.1 D-02 | M1b | test_fixtures_present | amended D-02 |
| 117 | s | Hub evolution after each boss (shelter, banners and bridges,... | §7.3 | M9-M13 | test_hub_states | covered |
| 118 | m | Camera frames the room, keeps threats visible, scrolls large... | §10, D-30 | M3a | test_camera_frames | covered |
| 119 | c | Boss camera pullback only when integer scaling stays stable | §1.2 | n/a | n/a | deferred W |
| 120 | s | Gameplay sandbox room for tuning movement, sword, telegraph | §8.11 | M6 | dev_sandbox beat launcher | covered |
| 121 | c | In-game map screen | §1.2 | n/a | n/a | deferred W |
| 122 | m | T1 White King's Fall: quiet, no enemies, dead King focal poi... | §7.4 | M6 | test_t1_audit | covered |
| 123 | m | T2 Fallen Sword Tile: sword unlock, turn and strike tutorial... | §7.4 | M6 | test_prompts | covered |
| 124 | m | T3 First Pawn Clash: one Pawn Recruit, exit locked until cle... | §7.4 | M5, M6 | test_full_route | covered |
#### Ledger, req# 125-248

| req# | P | Requirement (start) | Plan section | Milestone | Verified by | Status |
|---|---|---|---|---|---|---|
| 125 | m | T4 Broken Rule Yard: repositioning, cover tiles, pawn plus a... | §7.4 | M6 | test_room_data_audit | covered |
| 126 | m | H1 Chess Rug Hub: Toybox open; Bookshelf, Block Tower, Dollh... | §7.3 | M6 | test_world_graph | covered |
| 127 | s | Every room answers: which part of the room, why adjacent, wh... | §7.5 | M5 | test_room_data_audit | covered |
| 128 | m | Toybox Knight district: Gate, L-Jump Lanes, Toy Track Ambush... | §7.4 Act 2 | M9 | test_full_route | covered |
| 129 | m | Bookshelf Bishop district: Book Spine Steps, Diagonal Chapel... | §7.4 Act 3 | M10 | test_full_route | covered |
| 130 | m | Block Tower Rook district: Block Yard, Ruler Bridge, Breakab... | §7.4 Act 4 | M11 | test_full_route | covered |
| 131 | m | Dollhouse Queen district: Foyer, Mixed Court, Royal Stage, Q... | §7.4 Act 5 | M12 | test_full_route | covered |
| 132 | m | Under-Bed Black Castle: Castle Gate, Last Board, Rule Engine... | §7.4 Act 6 | M13 | test_full_route | covered |
| 133 | m | Each district follows Rest, Teach, Test, Twist, Boss or Rewa... | §7.5 | M5 | test_room_roles | covered |
| 134 | m | About 25 authored rooms in total (6 Stage 1 rooms exist) | §2.1 D-03 | M5 | test_world_graph | amended D-03 |
| 135 | s | Optional O1_CrayonCache and three optional rescues | §2.1 D-34 | M9-M11 | test_rescue_in_h1; test_reward_cadence | amended D-34 |
| 136 | s | Desk and child area as a support space | §7.3, §9.1 | M13 | test_continue_after_completion | covered |
| 137 | m | Finale gauntlet with all enemy types, then the chess box | §7.4 Act 6 | M13 | test_full_route | covered |
| 138 | m | Ending scene: bedroom morning | §8.8 | M13 | test_ending_audit | covered |
| 139 | m | Top-down pixel art at 640x360, 32 px tiles, nearest filterin... | §12 | exists | baseline labels | covered |
| 140 | m | Colour language: red = danger, dark orange = anticipation, b... | §10 | M8c | palette lint (R7) | covered |
| 141 | s | Pickups never look like damage warnings | §10 | M8c | palette lint (R7) | covered |
| 142 | m | Hero sprite set: four-direction idle, step, sword, pencil, t... | §12.1 | M14 | test_art_contract | covered |
| 143 | m | Common enemy sprite sets for Pawn, Knight, Bishop, Rook | §12.1 | M14 | test_art_contract | covered |
| 144 | m | Boss sprites (Black Pawn Captain, Knight Captain, Bishop Ora... | §12.1 | M14 | test_art_contract | covered |
| 145 | m | Fallen White King and fallen white pieces as story props (Po... | §4.8 | M6 | test_state_variants | covered |
| 146 | s | Owner-approved generated chess family (pawn, double-step, pr... | §12 | M2, M14 | test_art_contract | covered |
| 147 | m | Tile palette and district tile kits (toybox, bookshelf, bloc... | §12 | M9-M13, M14 | test_tilesets_per_district | covered |
| 148 | s | Prop list: chess remains, writing tools, paper, toys, furnit... | §12 | M14 | test_art_contract | covered |
| 149 | m | Art-swap contract: owner drops hand-drawn files over placeho... | §12 | M14 | test_art_contract | covered |
| 150 | m | Actor and pickup bodies are Sprite2D plus AnimationPlayer, n... | §12 | exists | test_art_contract | covered |
| 151 | c | Separate shadow sprites | §1.2 | n/a | n/a | deferred W |
| 152 | c | Lighting: warm global tone, PointLight2D only for lamps, mag... | §1.2 | n/a | n/a | deferred W |
| 153 | s | Pixel UI font, Courage as ivory chess bases, Believe as cray... | §10, §9.2 | M4, M10 | test_hud_safe_zone | covered |
| 154 | s | Dialogue portraits for the pawn and a child treatment | §12 | M6 (Tier B) | manual check | covered |
| 155 | s | Readability audit: light and dark tiles, grayscale, busy com... | §10 | M14 | grayscale readability pass | covered |
| 156 | c | Final polish pass that removes placeholder look from the sli... | §1.2 | n/a | n/a | deferred W |
| 157 | m | Player clips wake, idle, step, attack, hurt, defeat | §12.1 | exists | test_art_contract | covered |
| 158 | s | Player turn, pickup reaction and victory clips | §12.1 | M14 | test_art_contract | covered |
| 159 | m | Enemy clips idle, move, alert, windup, commit, recover, hurt... | §12.1, §5.10 | M8a, M14 | test_art_contract | covered |
| 160 | m | Editor-owned AnimationTree state graphs on every actor | §12 | exists; M2 collapse | test_actor_collapse_golden | covered |
| 161 | m | Boss animation plans: idle authority, windup per pattern, ph... | §12.1, §5.4 | M8b | test_art_contract | covered |
| 162 | s | Weapon animations with unique silhouettes and timing | §12.1 | M14 (Tier B) | manual check | covered |
| 163 | m | Animation never moves the logical grid anchor; RESET pose cl... | §12 | exists | test_art_contract | covered |
| 164 | m | Telegraph shapes per threat family (pawn corner slashes, kni... | §10 | M8c | test_telegraph_patterns | covered |
| 165 | s | Particles for chips, dust, crayon strokes, paper | §10 | M8c | manual check; test_hit_stop_restores_time_scale | covered |
| 166 | s | Pickup glow and idle motion | §10 | M8c | manual check; test_hit_stop_restores_time_scale | covered |
| 167 | m | Boss phase effects and room-light shifts | §5.4, §10 | M8b, M8c | test_boss_phase_differs | covered |
| 168 | m | Defeat leaves no stale telegraph; no gore | §5.10 | exists; M8a | test_no_stale_telegraph | covered |
| 169 | m | Bus layout Master, SFX, Music, UI | §11 | M1a | test_audio_buses | covered |
| 170 | m | Three-layer sound law: clip tracks, bus layout, SfxManager r... | §11 | exists | test_sound_bank_coverage | covered |
| 171 | m | Warning sound per threat family (pawn, knight, bishop, rook,... | §11.1 | M8c, M14 | test_sound_bank_coverage | covered |
| 172 | m | Player step tap, turn tick, sword hit, guard sounds | §11.1 | M8c, M14 | test_sound_bank_coverage | covered |
| 173 | m | Music states: opening, hub, district, combat, boss, final Ki... | §11.2 | M6, M14 | music_cues coverage audit | covered |
| 174 | s | Mix priority and ducking so warnings beat music | §11.2 | M14 | manual mix check | covered |
| 175 | s | Room ambience per area; final fight strips voice and ambience | §11.2 | M14 (Tier B) | manual check | covered |
| 176 | s | Toy, wood, paper, crayon sound identity rather than generic... | §11.1 | M14 | test_sound_bank_coverage | covered |
| 177 | m | Master, SFX, Music volume sliders | §9.2 | M4 | test_settings_roundtrip | covered |
| 178 | m | HUD: Courage, equipped weapon, short status prompt, optional... | §10, D-29 | M4, M7a | test_hud_slots_from_data | covered |
| 179 | m | Believe meter and intervention icon appear only once the chi... | §5.5 | M10 | test_believe_hud_appears_with_chalk | covered |
| 180 | m | HUD and dialogue never cover danger cells | §10 | M4 | test_hud_safe_zone | covered |
| 181 | s | Separate production HUD from debug readouts (cell coordinate... | §10, D-29 | M4 | test_debug_overlay_default | covered |
| 182 | m | Prompts: one idea each, short, safe moments, fade after use,... | §8.5 | M6 | test_prompts_cover_actions | covered |
| 183 | m | Teach move, hold, turn, sword, telegraph dodge, thrust, pick... | §8.5 | M6 | test_prompts_cover_actions | covered |
| 184 | m | Book of House Rules: pages unlock on first meeting, original... | §4.7 | exists; M6 | test_bridge_book | covered |
| 185 | m | Pages for every piece and boss (5 pages exist; none for Capt... | §4.7, D-47 | M6, M7c | test_pages_reachable | amended D-47 |
| 186 | m | Opening the book safely pauses or interrupts play (enemies k... | §4.7 | M4 | test_pause_freezes_tick | covered |
| 187 | m | Title screen | §9.2 | M4 | test_new_game_resets_slot | covered |
| 188 | m | Pause menu: resume, restart room, volumes, controls, quit | §9.2 | M4 | test_pause_freezes_tick | covered |
| 189 | m | Settings screen | §9.2 | M4 | test_settings_roundtrip | covered |
| 190 | m | Credits | §8.8 | M5, M13 | test_full_route | covered |
| 191 | m | End-of-game and epilogue screen | §8.8 | M13 | test_ending_audit | covered |
| 192 | m | Quit to menu or desktop | §9.2 | M4 | test_quit_to_title_confirm | covered |
| 193 | m | Reduced camera shake and reduced flashing | §10 | M8c | test_flash_rate; test_high_contrast_patterns | covered |
| 194 | m | High-contrast danger mode and pattern cues in addition to co... | §10 | M8c | test_flash_rate; test_high_contrast_patterns | covered |
| 195 | s | Hold or toggle Focus, adjustable telegraph duration, text sp... | §5.8, §1.2 | M8c; text speed deferred | test_tuning_scales; test_hold_toggle | deferred W (text speed) |
| 196 | s | Grayscale readability check of every room | §10 | M14 | grayscale readability pass | covered |
| 197 | s | Localization-ready strings (all text out of code and scenes) | §8.9 | M4 | test_text_keys | covered |
| 198 | m | Story text lives in data the owner can rewrite: dialogue, ro... | §8.9 | M4, M6 | test_story_literals | covered |
| 199 | m | Story spine: powerless pawn becomes free, never royal; child... | §4.1 | M6 | test_beat_graph | covered |
| 200 | m | Opening mostly visual: army defeated, King falls, black retr... | §3.4, §4.3 | M6 | test_time_to_control | covered |
| 201 | m | Dialogue system: short lines (4 or fewer), outside active co... | §8.3 | M6 | test_child_voice; line budget | covered |
| 202 | m | Cutscene and story-beat system (AnimationPlayer beats, trigg... | §8.4 | M6 | test_beat_graph; test_skip_equals_play | covered |
| 203 | m | Child voice rules: short, curious, sometimes scared, never a... | §4.5, R21 | M6 | test_child_voice | covered |
| 204 | m | Child presence staged in Act 1: none, crayon scratch at T4,... | §4.3 S01-S07 | M6 | test_beat_graph | covered |
| 205 | m | Pawn first believes the child is a god; the child admits the... | §4.3 S06b, S18 | M6, M11 | test_beat_graph | covered |
| 206 | s | Midpoint reveal: the battle began as a story the child playe... | §4.3 S18 | M11 | test_beat_graph | covered |
| 207 | m | One story or theme beat per district | §4.3 | M9-M12 | test_beat_graph | covered |
| 208 | m | Boss beats: short intro, personality behaviour, phase-change... | §5.4, §8.2 | M8b+ | test_boss_beats_present | covered |
| 209 | m | Queen speaks directly to the child (freedom is forgotten); K... | §4.3 S20, S24 | M12, M13 | test_beat_graph | covered |
| 210 | m | Character arcs for the Pawn, Child, Queen (ideological antag... | §4.2 | M6+ | manual review | covered |
| 211 | m | Ending: pawn refuses promotion, pieces freed, child rebuilds... | §8.8, D-33 | M13 | test_ending_audit | covered |
| 212 | c | Ending varies slightly with rescued pieces | §8.8 | M13 (Tier B) | test_ending_variants | covered |
| 213 | s | Environmental storytelling: moved toys, child drawings, bedr... | §4.8, §8.5 | M6 | test_state_variants; test_clues | covered |
| 214 | s | Rescued white pieces offer optional reflections | §4.2, D-34 | M6, M13 (Pebble real; others flag-only) | test_rescue_in_h1 | covered |
| 215 | s | Tone: serious war, warm playground, no gore, humour from sca... | §4.1 | M6 | manual review | covered |
| 216 | m | Emotional beat map: every room and act tagged with a target... | §3.5 R1 | M5, M6 | test_emotion_fields; print_arc | covered |
| 217 | m | Intended arc: vulnerable opening, clever in encounters, surp... | §3.2 | M14 | test_arc | covered |
| 218 | s | At least three of Lazzaro's four fun keys (hard, easy, peopl... | §3.5 R19 | M14 | act checklist | covered |
| 219 | m | Autonomy, competence and relatedness: rule-breaking choice,... | §3.5 R20, R24 | M14 | solutions field audit | covered |
| 220 | m | Child must read as a companion (hesitation, fear, delight),... | §3.5 R21-R22, §3.6 | M12, M14 | test_child_voice; probes P1-P3 | covered |
| 221 | s | Layered juice (squash, particles, shake, sound) added only a... | §10 | M8c | test_hit_stop_restores_time_scale | covered |
| 222 | m | Design the finale and ending as the peak and end; avoid fron... | §3.5 R30 | M13 | test_ending_audit | covered |
| 223 | s | Gentle failure plus fine-grained assist options | §5.8, D-22 | M8c | test_tuning_scales | covered |
| 224 | s | Quiet beats and music rests: silent T1, safe hubs, final-fig... | §3.5 R3 | M6 | test_t1_audit | covered |
| 225 | s | Grief without gore: toppled pieces, cracked bases, pieces re... | §4.1 | M8c | test_defeat_becomes_toy | covered |
| 226 | s | Attachment through rescue: rescued pieces return to the hub... | §4.2, D-34 | M6, M13 | test_rescue_in_h1 | covered |
| 227 | s | Post-boss and ending emotion questionnaire in the playtest f... | §3.6 | M14 | docs/playtest-form.md | covered |
| 228 | m | Complete flow: title, new game, opening, Acts 0-6, ending, c... | §1.1 D1 | M5 | test_full_route | covered |
| 229 | m | Automated start-to-end route test (boot to credits) | §1.1 D21 | M5 | test_full_route | covered |
| 230 | s | Difficulty and balance pass for every fight (standard.tres i... | §6.7 | M14 | tuning pass with attempt logger | covered |
| 231 | s | Room authoring guide matching the ECS and zone markers (docs... | §15 M1a | M1a, M14 | the rewritten docs/design/room-authoring-guide.md (checked against the code by hand; M14 re-reads it) | covered |
| 232 | s | Asset import rules and tile-editing workflow documented | §15 M1a | M1a, M14 | sections 6 and 7 of docs/design/room-authoring-guide.md (checked against project.godot and the tileset by hand; M14 re-reads them) | covered |
| 233 | s | Structured owner review template | §16.2 G8 | exists | docs/owner-review-template.md | covered |
| 234 | m | Fresh clone builds and runs; generators documented with order | §13.7 | M1a | tools/bootstrap_worktree.sh | covered |
| 235 | s | Single test runner and CI (7 test scripts, no .github) | §13.7 | M1a; CI file Tier B | run_all_tests.py (pinned by its --self-test) | partial: the runner is done; the CI workflow file (Tier B, M14) does not exist |
| 236 | s | Editor handoff note per system: Open, Tune, Goal, Try, Tell me | §16.2 G8 | each milestone, M14 | handoff notes | covered |
| 237 | s | Smoke checklist, room QA checklist, combat-feel test log, bu... | §15 M14 | M14 | docs/qa templates | covered |
| 238 | m | Automated coverage: movement, combat, telegraph, graph valid... | §13.7 | M1a onward | run_all_tests.py --strict | covered |
| 239 | s | Performance budget: stable 60 FPS, capped enemies, short VFX | §5.11 | M3a, M14 | test_room_tick_budget | covered |
| 240 | s | At least three outside playtesters | §1.2, §3.6 | M8c, M14 | attempt logger; playtest form | deferred W (testers) |
| 241 | m | Exported build that runs outside the editor (macOS zip from... | §1.2, §15 M14 | M14 (macOS Tier B) | export smoke | deferred W (Windows, Linux) |
| 242 | s | Package notes: controls, known issues, playtime, feedback qu... | §15 M14 | M14 | package notes | covered |
| 243 | c | Screenshot plan, trailer beats, store-page text | §1.2 | n/a | n/a | deferred W |
| 244 | c | Steam page and public demo plan (15-25 min demo, Next Fest) | §1.2 | n/a | n/a | deferred W |
| 245 | s | LICENSE, font and asset credits | §1.1 D20 | M1a stub, M14 | LICENSE and THIRD_PARTY_NOTICES check | covered |
| 246 | m | ECS rules: state in components, decisions in systems, only V... | §2.4, §13 | M1a onward | test_dependency_edges (report-only; it checks layer edges, not node access) | partial: nothing yet checks that only ViewSyncSystem touches nodes; the edge guard stays report-only until the owner decides its table at OG0 |
| 247 | m | Verify suite green and import clean before every commit; one... | §2.4, §13 | M1a onward | run_all_tests.py (suites green, import clean); commit size is a review rule | partial: one logical change per commit is checked by review only |
| 248 | m | Research built-in nodes then addons (ask owner) before custo... | §2.4, §13 | M1a onward | the research rule in CLAUDE.md and AGENTS.md; checked in review | partial: a review rule, no automated check exists |

**Ledger summary.** `m` rows: 156, all with a section and a test or a waiver. Rows marked `deferred W` are the owner-waivable items of §1.2. Rows marked `amended` point to the decision or trigger that changed them.
## 2. Decisions taken

The owner said "I trust you". Where docs conflict I took the newest recorded owner direction. Only the 2026-10-12 messages are verbatim (§0). Every other "owner approved" line in the repo is agent-written (`where:188-192`). The "Follows" column uses four kinds of source so nothing is dressed up as an owner decision when it is not:

- `OWNER-10-12 #n`: one of the verbatim directions in §0.
- `OWNER-OLDER(date)`: an older recorded owner direction (agent-written record).
- `RULE(file)`: a standing project rule.
- `PROPOSAL`: the plan's own idea. The owner may overturn it. All `RULE`-only and `PROPOSAL` rows are repeated in §2.2 as "needs owner confirmation" where the flip cost is more than one data edit.

### 2.1 Decision table

| # | Topic | Decision | Reason | Follows | Easy to change by |
|---|---|---|---|---|---|
| D-01 | Slice vs full game | Build Acts 1-6 plus Ending as one tested chain. "Stage 1 + Toybox" is the first owner-play gate (OG3), not the cut line. | The newest direction supersedes every slice framing (`gdd:560-572`, `flow:37-44`, market report 15-25 min demo). | OWNER-10-12 #1 | n/a |
| D-02 | World model, scale, arenas | Separate editable room scenes on a world graph. Default board 16x9. Boss arenas and `ub2` are at most **18x9** (576x288 px). Each room sets a centred `grid_origin` (16 wide: x 64; 18 wide: x 32; y 36) in `EcsBoot`, and `CameraRig` clamps to it (today `grid_origin` is fixed at (64,36), `ecs_grid.gd:10`). The HUD safe zone (§10) keeps the top 32 px and the bottom 34 px free of danger rows. The pawn-scale bedroom (128x96 cells, 1 cell = 1.5 in) is the WORLD MAP backdrop and scale reference only: 8x10 slots of 16x9 cells, `map_slot` lives in `world.tres`. The 72x40 kingdom and `first_encounter` become **test fixtures** under `tests/fixtures/` (they are the only coverage for gates, the aggro leash, large-board A*, floor pickups and Knight/Armed spawn), excluded from `ContentDb` and from room lints. **Monotony guard** (owner verdict 2026-07-29: "too anotony", "door-connected rectangles read as Enter the Gungeon rooms"): every district has at least one loop or shortcut, no two consecutive critical-path rooms share a `layout_archetype`, each district has one format-breaker room (§7.4), hubs evolve, per-district tile kits and tint. Fallback if the owner rejects a room graph: semi-open hub-and-spoke (O-9). | Batch 1 (2026-09-30) and the 2026-07-14 rule "connected rooms, not one big scrolling map" (`task_plan.md:296`). A* is rebuilt per call (`ecs_grid.gd:167-187`, `enemy_ai_system.gd:199-219`), so 128x96 is unplayable. An 18x10 board (576x320) from the fixed origin runs flush to the right edge and under the HUD bars (`scenes/ui/hud.tscn:9-12, 87-90`). | OWNER-OLDER(2026-09-30, 2026-07-29), OWNER-10-12 #1 | `world.tres`, `RoomEncounter.board_size` |
| D-03 | Length | No minute promise. Structure: 34 rooms. First-play estimate 125-140 min `[start value]`, derived from the route bot's measured minimum clear time per room times a multiplier (§7.4), not guessed. | The owner will deepen content, so the base proves structure. Hand-written minutes were contradicted by measured room geometry (T1 is crossed in about 3 s). | OWNER-10-12 #1 | n/a |
| D-04 | First boss | B1 Black Pawn Captain. Knight Captain is Act 2's district boss. "The Knight may move twice" is its phase-2 amendment. | `flow` (2026-09-30) explicitly replaced Knight-in-Act-1 (`flow:44-67`). | OWNER-OLDER(2026-09-30) | `boss.tres` |
| D-05 | Names and ids | v2 names. Prefixes `tb/bs/bt/dh/ub`; suffix `b` boss, `o` optional, `4` shortcut; `B1` stays the Pawn Captain. Page ids never equal boss ids (test). | v2 is the newest full design. World-graph ids must be unique. | OWNER-OLDER(2026-09-29) | folder rename |
| D-06 | Act numbering | Act 1 = T1..H1 (the Prologue is T1-T2 inside it). Acts 2-6 = Toybox, Bookshelf, Block Tower, Dollhouse, Under-Bed. Ending = "Morning". | `flow` is newest. | OWNER-OLDER(2026-09-30) | n/a |
| D-07 | Art method | Placeholders under a swap contract (§12). The generated chess family is wired in as placeholder and flagged. Missing pieces (rook, queen, king, bishop, bosses) come from the same generator, also flagged. No AI art is ever finalized. Hand art never lives in a gitignored folder. Provenance of the glyph-traced Knight silhouette (`where:178`) is recorded, and the sprite is redrawn or replaced before release. | Owner hand-draws. Today the T1/T2 backgrounds load from a gitignored folder (`t1_white_kings_fall.tscn:8`), which would lose hand art. | OWNER-OLDER(2026-09-03), OWNER-10-12 #1 | overwrite PNG |
| D-08 | Enemy locomotion | Every piece moves by its OWN chess locomotion, one move per `step_duration`. Pawn family: one cardinal cell. Knight: L-step, 8 offsets, lands on a free cell [measured: `resources/movement/knight_standard.tres:14`]. Bishop: one diagonal cell [measured: `bishop_diagonal.tres`]. Rook: one cardinal cell; its CHARGE is the attack. Queen: rook plus bishop cells, one at a time. King: one cell any direction. New files `rook_standard.tres`, `queen_standard.tres`, `king_standard.tres` ship in M11-M13. `test_locomotion_from_data` asserts that locomotion comes only from `movement.tres`. M1b amends `findings.md:45-51`. | The data already encodes this. The June revision "all common enemies move in four cardinal directions, chess identity lives in the attack" (`findings.md:45-51`) is **superseded** by the July chess-law direction for Knight, Bishop and Queen. A prior summary said "one cardinal step for all"; the files disagree, so the files win. `where:156` still lists this as an unresolved owner-only decision, so it is also O-8. | OWNER-OLDER(2026-07-28), supersedes OWNER-OLDER(2026-06-19..21) | `movement.tres` |
| D-09 | Child intervention | Staged arc: none (T1-T3), crayon scratch (T4), notices after B1, first speech in H1, first scripted help in Toybox (`tb3`, **no line during the fight**, the line is spoken at room clear), Chalk Path (Act 3), Chalk Block (Act 4, Midpoint), disrupted (Act 5), cut off (Act 6), partnership (Ending). Believe max 2. Help changes the room, never enemy HP (`gdd:229-272`, `v2:654-677`). | `flow:561-571` and `v2` are newest. The relatedness curve of §3. | OWNER-OLDER(2026-09-30) | `progression/`, beats |
| D-10 | T2 "child whispers: take it" | Removed. No child voice before the B1 victory. | Contradicts `flow:563-567` and `t1spec:278-280` (`where:97`). | OWNER-OLDER(2026-09-30) | `.po`, beat |
| D-11 | Pencil Thrust timing | The Pencil is a guaranteed pickup **on the T4 exit path**, just past the Armed Pawn. Q is locked until picked up. The mandatory path never needs it. The Ruler Blade (alternate Strike) is the B1 drop (the existing `RulerBladePickup` in `b1`), not a Block Tower find. | "Suffer first, then wield" (§6), but both emotion and progression reviews found a 37-minute single-verb stretch if the Pencil is missable. The Q key was approved in the June playtest (`findings.md:26-33`). | OWNER-OLDER(2026-06-19) | move the grant marker |
| D-12 | Skills | Six verbs: Sword, Pencil Thrust, Rule Step, Chalk Path, Eraser Guard, Free Step. Chalk Block ships as the worked example of a new effect kind. Pages, Margin and one Annotation (Lead Tip) ship as the build layer. In Passing, Ruler Gate, Castling and other Annotations are extension recipes (§6.10). Skill slots are generic data-bound actions `skill_slot_1..4` (§9.4). This replaces the GDD's "one weapon plus two Imagination slots" (`gdd:111-114`). | gp4/gp7/v2 are newest. A seventh verb (In Passing) had no trigger enemy where it was taught and broke three Pages; cutting it buys depth for the six that remain. | OWNER-10-12 #2a | `skill.tres`, `slots.tres` |
| D-13 | Progression spine | "The Long March": the Rank badge (2 to 8) is a **story label** that reads defeated-boss flags and gates nothing. Margin comes from explicit `margin_gain` rows on milestones (2 after B1, 3 after Knight, 4 after Bishop, then fixed at 4). Verbs, equippable Pages under Margin, Believe. No XP, levels, currency, shops, bonfires, Rest Squares or corpse run. The HUD badge is drawn as the child's blue tally marks. | The owner cut those on 2026-07-28 (`soul:4-8, 96-97`) and `gdd:554` excludes statistical upgrades. Deriving Margin and locks from Rank re-created the cut "promotion levelling" under a new name. | OWNER-OLDER(2026-07-28), OWNER-10-12 #2a | `milestones/*.tres` |
| D-14 | Final Rule Break | The Black Castle seal in Act 5 opens by a **room change**: the child's hand lifts a latch, in the established language "help changes the room, never the pawn". The seal bears a diagonal mark, the pawn tries a chord, and the denial beat plays (foreshadowing). Free Step is first used by the player in the Black King's P4, after a 10 s rehearsal beat (§6.3). The first diagonal the player ever makes is the King's open cell. | The draft had the child's nudge make the pawn's first diagonal step in a cutscene, which spent the game's thesis 20 minutes early and contradicted D-19. Gentle Nudge is therefore removed (req#49). | OWNER-10-12 #2a (reconciles `v2:484`, `gp7:22`) | `progression/`, beat |
| D-15 | Forward-only prologue | Rejected. The pawn moves in four directions from frame one. The rule-breaking is carried by the verbs and by the Act 6 direction lock. | The June playtest approved the 0.18 s four-way feel. A locked start breaks R2 and R3. The `DirectionLock` is saved for Act 6, where taking away what the player relies on is the Brothers technique. | OWNER-OLDER(2026-06-19) | n/a |
| D-16 | Save and checkpoint | Low-punishment. **Checkpoints**: hub entry and every boss-room entry; each refills Courage and Believe. Death resets only the current uncleared room, and the pawn stands on the entry it came into that room by, never at the checkpoint (§5.2); a boss resets to its highest checkpointed phase (D-43). Persistent: unlocks, flags, defeated bosses, cleared rooms, opened gates, rescues, Pages, shards, counters. Room-local floor weapons reset. Autosave only on success events (R17). One slot; the `SaveService` API is slot-aware. | GP.6/TECH.3 (`gp6:12-30`, draft) plus the peak-end save-on-success rule (Gutwin). | OWNER-OLDER(2026-06-19) | `SaveService`, `rules.tres` |
| D-17 | Cleared rooms | Cleared rooms stay cleared. **This departs from `soul` rule 3** (`soul:76`: re-entry respawns normal enemies). | Shortcuts home are one-way and backtracking would otherwise be a chore. Flip cost: one field, `RoomEncounter.respawn_on_reentry`, plus one test. Listed in §2.3 for the owner. | PROPOSAL (cites `soul:38-44` for shortcut relief only) | field |
| D-18 | Key bindings | R = Call child. Restart room is a pause-menu command with confirm (not a bound action). Full table in §9.4. | `v2:134` is newest. A single-key instant restart also fights the "child resets the board" story. | OWNER-OLDER(2026-09-29) | `project.godot` |
| D-19 | Final-fight help | Phase 3: help blocked (Close the Box). Phase 4: the hand reaches in but cannot help. The pawn takes the diagonal step unassisted. | Reconciles `gdd:366-373`, `en6:28-35`, `v2:522-530`. | OWNER-OLDER(2026-09-30) | `boss.tres` |
| D-20 | Targeting and time-slow | No cursor, no targeting mode, no time-slow. Chalk and Block use the facing line. Focus (hold or toggle) emphasizes telegraphs and never slows time. Enemy Pace (§5.8) is the accessibility answer. | Real-time identity (`gdd:159-161`), fewer systems. `conflicts[17]` in the requirement research recommended keeping the slow-time mode as an accessibility toggle; Enemy Pace delivers the same benefit without a new input mode (req#51 waived). | OWNER-OLDER(2026-06-18) | n/a |
| D-21 | District order | Linear: Toybox, Bookshelf, Block Tower, Dollhouse, Under-Bed. Flexible Bishop/Rook order (`gdd:294-299`) is one data edit on the hub lock. | Each district teaches a verb the next one needs: Chalk before the Rook district, Believe before Perfect Rub. This halves balancing. | OWNER-OLDER(2026-09-29) | hub lock condition |
| D-22 | Difficulty | One Standard difficulty plus opt-in assists with neutral names. `DifficultyProfile` gains `health_multiplier`, `damage_multiplier` and `telegraph_floor_seconds`. Never silent. An assist is OFFERED once after 5 deaths or 15 minutes on one boss, whichever comes first, and a persistent "Assist options" entry exists in the Pause menu from the first run. Thresholds are data. | Celeste model (§3). Eight deaths on a 6-9 minute fight is 20-40 minutes of frustration before the first offer. | PROPOSAL | `difficulty/*.tres`, `rules.tres` |
| D-23 | Dialogue tooling | Built-in: `Resource` data plus `RichTextLabel` typewriter. Dialogue Manager 4 (MIT) is an option that NEEDS OWNER APPROVAL. | `CLAUDE.md:34-39` (built-ins first, ask before dependencies). `AGENTS.md:175` already says dialogue is a typed `.tres`. | RULE(CLAUDE.md) | n/a |
| D-24 | Text storage | gettext `.po` files, not CSV, one file per domain (`story`, `ui`, `skills`, `rooms`) registered as several translations of the same locale. `test_po_domains_merge` proves the merge works before anything relies on it `[unverified]`. | Verified on Godot 4.6.3 in a scratch project: `.po` files listed in `project.godot` load headlessly with no import pass, a missing key returns the key, and the default locale `en_VN` falls back to `en`. CSV imports to `.translation`, which `.gitignore` excludes. Per-domain files stop every lane conflicting on one `en.po`. | RULE(CLAUDE.md gotchas) | `*.po` |
### 2.1 Decision table (continued)

| # | Topic | Decision | Reason | Follows | Easy to change by |
|---|---|---|---|---|---|
| D-25 | Source language | Default: English source in `en/*.po`, `vi` empty (falls back to `en`). This is an owner decision (O-4) because the owner writes to the team in Vietnamese. If the owner picks `vi` as source, the font shortlist is checked with `FontFile.has_char` over the Vietnamese set, the placeholder-flag lint runs per locale, and the other locale falls back. Owner-facing docs are bilingual (§1.1 D19). | The owner is the author of final text. 2026-10-12 says nothing about language. | PROPOSAL | `.po` files |
| D-26 | Autoloads and registry | Exactly two autoloads: `SaveService` and `Sfx`. `ContentDb` is a **static class** with a lazy id cache, not an autoload. Both autoloads are injectable (tests pass a path or a stub). No `GameEvents` autoload. Flow, pause, transition, music and settings live in a persistent `AppRoot` main scene. Scenes are loaded on demand; `validate()` runs from tests and the editor tool, never at process start. | Verified in a scratch project: in a `SceneTree` script's `_init`, `/root/WorldState` and `/root/SfxManager` are null, and six of the seven suites run synchronously in `_init`. | RULE(eco), reviewer-verified | n/a |
| D-27 | Folder layout | ECS-first tree (§13): `content/` (zero code), `schema/`, `ecs/`, `authoring/`, `presentation/`, `shell/`. This replaces the `CLAUDE.md` folder-ownership block (see §2.4). | GDQuest layering, Godot "organise by subject". | OWNER-10-12 #2b | n/a |
| D-28 | Entity assembly and attack vocabulary | **Keep today's pipeline**: `EnemyDefinition` (`.tres` composed of shared sub-resources) + `ActorView` instances in room scenes + `EntityComponent` nodes baked by `EcsBoot` (a node on an instance beats the definition). No `EntityDefinition`, `parts[]`, `EntityBuilder` or `EntitySpawn`. The four near-identical 353-line actor scenes collapse into one `actor_view_base.tscn` plus thin inherited scenes, with the body texture and anchor in `VisualDefinition`. For attacks, `CellPattern` is the shared shape type and a new `AttackBase` Resource (telegraph time, tags, damage) is the common base of `AttackProfile` (player legacy), `AttackPattern` (enemy) and `EnemyWeapon` (floor), so R6 and the tag lints run over one base class. No ECS addon. | A Godot `Resource` cannot tell "not overridden" from "default", so the draft's variant-overrides-only-what-differs semantics were undefined; `EnemyDefinition` already composes shared sub-resources (`resources/enemies/black_pawn_captain.tres`) and tests assert resource identity (`ecs_enemy_test.gd`). The cut also keeps `CLAUDE.md`'s "parked ActorViews become entities" rule, so it is not a departure. | RULE(CLAUDE.md) | `enemy.tres` |
| D-29 | HUD | Production HUD (Courage pips, Rank tally, skill slots from data, Believe marks, objective line, boss bar inside the 28 px top strip). Every widget is its own scene instanced by `game_root`. Debug fields only behind F3, off by default in exports. | UI.1 (`ui1:12-30`). One scene per widget stops six milestones editing `hud.tscn`. | OWNER-OLDER(2026-09-30) | `hud` scenes |
| D-30 | Camera | Static framing for single-screen boards (at most 18x9), integer-pixel snap, per-room centred origin, shake scaled by a setting. | `gdd:139-144`, pixel-art bible. | OWNER-OLDER(2026-06-18) | `feel_profile.tres` |
| D-31 | One-night frame | Adopted as data: `time_of_night` per room. Applying the tint is Tier B, and it tints the background and tile layers only. Telegraph, HUD and dialogue layers are never tinted. | Nearly free and gives the player a clock without text. A global tint could wash out saturated red telegraphs and mint safe markers. | PROPOSAL | `RoomEncounter.time_of_night` |
| D-32 | "Rule" motif | Adopted as the placeholder interpretation: a rule is a chess rule, a house rule and a ruler. Black is the child's own "rules" made pieces. What the child lost is never said aloud (O-2) but is shown by a prop clue chain (D-45). | Latent in the assets (Captain's ruler blade, pencil and eraser). It is a reading, not in the docs. | PROPOSAL | `.po`, beats |
| D-33 | Ending | The approved `nar1` ending, but **playable**: morning, the quiet board, four promotion tokens as props (Queen, Rook, Bishop, Knight; bumping one plays its one-line epilogue), and the refusal is the player walking past them and off the board's edge, along the blue crayon line. The child's hand is the one that offers the tokens, kindly, so refusing is a loving "no" the child must accept. Rescues vary the final shot. | `nar1:105-118`, `nar6:11-19`, `gdd:375-380`; the emotion research requires the final playable act to be a previously forbidden free move chosen by the player. | OWNER-OLDER(2026-09-30) | `ending.tres` |
| D-34 | Rescues | Three white pieces: Pebble (Knight, H1), Slant (Bishop, in `bs3`), Stout (Rook, in `bt2`). Each is a 60-90 s hold-E beat **on the critical path**. Only Pebble has extras (hub resident, one bark). Slant and Stout are flag-only plus a hub prop. Each rescue refills Believe, restores one direction in the finale (Left, Right, Back), and varies the ending. There are no Rest Squares. | `gdd:134-135, 546-547`, rule R24. Optional rescues made the Act 6 climax depend on optional content. | OWNER-OLDER(2026-06-18), OWNER-10-12 #1 | `rooms` |
| D-35 | Approval workflow | The 2026-10-12 message authorises building the whole base and restructuring code and folders (#2b). It does **not** pre-approve the `AGENTS.md:78-83` triggers (core controls, scope, removed mechanics, destructive migration). Those are listed in §2.3 with defaults. Gates OG0-OG4 (§15) give the owner a cheap veto. If the owner does not respond, agents continue on the stated defaults and log the assumption in `progress.md`. | The per-task gate would block a full base (`production-checklist.md:20-30`), but silently overriding the standing rules would be worse. | OWNER-10-12 #1, RULE(AGENTS.md) | n/a |
| D-36 | Doctrine docs | `CLAUDE.md` and the code win over `AGENTS.md`, `ARCHITECTURE.md` and `coding-standards.md`. `CLAUDE.md` changes follow §2.4 and wait for OG0. The others are rewritten in M1a. | `eco:3`, owner chose full ECS on 2026-07-19. | OWNER-OLDER(2026-07-19) | n/a |
| D-37 | Rule Step shape | Rule Step is an L-shaped leap (two ahead, one aside, untargetable in flight) with a 4.0 s cooldown. It is not the two-cell emergency step of `v2:320-326` / `gp4:26` (req#35). Chalk Block blocks Knight landing cells, matching req#43. | The leap is the only verb that crosses a one-cell gap, which the forced first use, the Bookshelf island rooms and the Knight boss need. | PROPOSAL | `skill.tres` |
| D-38 | Inbound channel | The simulation has one inbound channel from presentation and settings: `world.commands` (typed requests drained by `CommandSystem` at the head of the schedule), plus `world.tuning` for assists and settings. Presentation reads only `drain_events()` and a read-only `HudSnapshot`. The beat step `Grant` is dropped: a grant is a `SetFlag` plus a milestone flag trigger. | `BeatPlayer` setting `frozen`, writing flags and granting skills would put decisions in presentation. | RULE(CLAUDE.md) | n/a |
| D-39 | Test harness | `UnboundTest` base class (watchdog 30 s, `_expect`, `soft_expect`), a subprocess runner `tools/run_all_tests.py` (isolated HOME, import pass first, fails on `SCRIPT ERROR`, `Parse Error` or non-zero exit), a baseline-label manifest, minimum-file-count rules for lints. | Verified: a script error in `_init` hangs the Godot process forever, and a stale `res://` path makes a file-read check pass vacuously. | RULE(CLAUDE.md "keep tests green") | n/a |
| D-40 | No Rest Squares | There is no Rest Square object. Courage and Believe refill at checkpoints (D-16). Pages equip from the Book whenever no hostile is alive in the current room. | The owner cut bonfires and shrines on 2026-07-28; a full-heal tile that is also the only equip point is a bonfire. | OWNER-OLDER(2026-07-28) | `rules.tres` |
| D-41 | Believe economy | Believe max 2, starts full at the Chalk Path grant. Refills: hub entry, any checkpoint, boss defeat, rescue reunion, +1 per 3 hits landed in the current room, +1 per Perfect Rub. Mandatory traversal gaps (`TraversalGap` marker) cost 0 Believe when no hostile is alive. Believe is saved. | Draft Believe could reach 0 with no enemy left to hit at the enemy-free hub door that needs Chalk Path, a permanent soft-lock for a trust mechanic. | PROPOSAL | `rules.tres` |
| D-42 | Free Step input | Primary: the dedicated `free_step` modifier plus a direction. Alternative: two perpendicular directions pressed within `chord_window` (default 0.07 s, FeelProfile, floor 0.05 s, 8-way stick diagonal cone of 20 degrees). The chord hold-off applies only while Free Step is owned and a diagonal destination is legal, so ordinary steps never gain latency. From T1 on, a chord press shows a head-shake denial once and writes a Book margin note. | A 0.06 s window is 3.6 frames, collides with normal buffering, and an untrained input at the climax is a design failure. A 0.12 s window would add 0.12 s latency to every step. | PROPOSAL | `feel_profile.tres` |
| D-43 | Boss phase checkpoints | Each `BossPhase` has `checkpoint: bool`. Death restarts at the highest checkpointed phase, earlier phases' HP stay spent. Intro and phase beats play abbreviated (5 s or less) once their `seen` flag is set. | Retry cost inside a 6-9 minute boss with 90 s of non-interactive ritual is unbounded. Amends D-16. | PROPOSAL | `boss.tres` |
| D-44 | Relationship-keyed presentation | The death reset presentation is chosen by relationship flags, as data on the reset beat: before the notice the pawn simply rises with the `wake` clip; after B1 the hand places it gently; after the Queen's address the hand hesitates; under the lid in Act 6 there is no hand; the ending is gentle. | A constant "the hand resets the board" defuses the B1 reveal and contradicts Act 6's cut-off child. The death loop becomes a free relationship meter. | PROPOSAL | beats |
| D-45 | What the child lost | The base ships a default answer as **props only, never lines**: six clues (§4.8) and a Desk reveal that references at least four of them. The owner keeps O-2 open and can replace any clue. | Without a clue chain the Midpoint confession, the Queen's "put them away" and the ending have nothing to recognise. | PROPOSAL | `clue_index`, props |
| D-46 | Who writes the Book | Two inks, one hand. Enemy amendments are in grey pencil (the child's rules; the child cheats for Black when the pawn wins). The pawn's unlocks are blue crayon (the child's love). The Midpoint reveals both are one hand. Death-knowledge notes are neutral printed ink, never the child's blue. `RulePage.ink` is a field. | `resources/rules/backstep_pawn.tres:11` already says "The child wrote it in the margin, and the board obeyed" on an enemy's amendment. | PROPOSAL | `page.tres` |
| D-47 | Pages and Lore | Five equippable Rule Pages ship (First Law, Armed Pawn, Backstep Pawn, Charging Pawn, Knight Errant), each tied to an enemy that a room places. Lore entries (zero Margin cost, no modifiers) exist for every piece and boss: Black Pawn Captain, Knight Captain, Bishop Oracle, Rook Warden, Queen of Tricks, Black King, Bishop, Rook. | req#185 wants a page for every piece and boss. Three of the draft's ten pages had no enemy that could unlock them. | OWNER-OLDER(2026-07-28 Book), PROPOSAL | `page.tres` |
| D-48 | Scope tiers | §1.4: Tier A (base), Tier B (cut-first, ordered), Tier C (deferred with `req#` waivers in §1.2). | Reviewers sized the full list at 35-40 percent over capacity. | PROPOSAL | §1.4 |

### 2.2 Items still open for the owner (defaults taken)

| ID | Question | Default in the base | Flip cost |
|---|---|---|---|
| O-1 | Approve Dialogue Manager 4 as the writing format after the base ships? | No. Built-in system. | n/a |
| O-2 | What loss does the child's imagined war replay? | Never stated. A six-clue prop chain implies a missing second player (a lost game partner) and a bedtime (D-45). | Replace the clue props and the Desk reveal. |
| O-3 | Does the child sleep or smile at the end? | Child is out of frame; one line "Good morning, pawn." | One `.po` row. |
| O-4 | Which locale is the SOURCE of the story: English or Vietnamese? Ship Vietnamese text? | English source in `en/*.po`; `vi` empty and falls back to `en`. Owner-facing docs are bilingual. | Make `vi` first-class: run the per-locale placeholder lint and the glyph test on the chosen font. |
| O-5 | Replace `Sfx` with an audio addon, or adopt GECS? | No. Not needed. | n/a |
| O-6 | Is Margin too close to levelling? | Margin is an explicit table of `margin_gain` rows that stops at 4 (D-13). | Set the rows to a constant. |
| O-7 | Keep the one-night tint? | Yes, as data; applying it is Tier B and touches the background layer only. | One field per room. |
| O-8 | Enemy locomotion: chess-law moves (Knight L, Bishop diagonal) or one cardinal step for all? (`where:156` open item #7) | Chess-law moves (D-08). | Edit `movement.tres` only. |
| O-9 | Is a door-connected room graph acceptable after the 2026-07-29 verdicts ("too anotony", "Enter the Gungeon rooms")? | Yes, with the monotony guard of D-02. | Fall back to a semi-open hub-and-spoke layout (rooms stay, doors become openings). |
| O-10 | Add a short "obey the rules before you are freed" card sequence before the finale (story research proposal)? | No, except the optional `dh1` tea-party room (Tier B). | New beats only. |
| O-11 | Should the pawn choose its own closing rule (story research proposal)? | The playable ending already makes the pawn's last act a choice (D-33). | n/a |
| O-12 | Confirm D-27, D-28, D-38 and the §2.4 `CLAUDE.md` amendments. | Proceed on the stated defaults after OG0 (D-35). | Revert via the `pre-restructure` tag. |

### 2.3 Standing-rule triggers and departures (needs the owner's yes or no)

`AGENTS.md:78-83` says to ask the owner before changing core controls, changing the 2-hour scope, removing a mechanic, or making a destructive migration. The 2026-10-12 message does not mention any of these. Nobody has confirmed any row below. The defaults are what the plan builds. "Reversal cost" is what it costs to undo.

| # | Trigger | What the plan does | Default | Reversal cost |
|---|---|---|---|---|
| T-1 | Core controls | R becomes "Call child"; instant restart leaves the keyboard and becomes a pause-menu command (D-18). Q is locked until the T4 pickup (D-11). The `skill_1` action becomes `skill_slot_1..4`. The input buffer now expires (req#3, a feel change). | Yes. | `project.godot` edits; one setting for the buffer. |
| T-2 | 2-hour scope | 34 rooms, 125-140 minute first-play estimate (D-03). | Yes. | Drop rooms from `world.tres`; the route test adapts. |
| T-3 | Removed mechanics | Time-slow targeting (req#51, D-20), Gentle Nudge (req#49, D-14), Courage-heal rescues and Rest Squares (req#59, D-40), the "seven verbs" claim (In Passing moves to a recipe, D-12). | Yes. | Recipes in §6.10. |
| T-4 | Destructive migration | M1b moves the whole code tree and content (the `pre-restructure` tag exists and the move is scripted and reversible per folder). The 72x40 kingdom and `first_encounter` become test fixtures (D-02). | Yes after OG0. | `git revert` per folder commit, or the tag. |
| T-5 | Departure from the 07-28 cut: room respawn | Cleared rooms stay cleared (D-17), reversing `soul` rule 3 (`soul:76`). | Yes. | One field (`respawn_on_reentry`) and one test. |
| T-6 | Departure from the 07-28 cut: promotion levelling | Rank is shown as a badge but is a label only; Margin and locks never read it (D-13). | Yes. | Edit `margin_gain` rows. |
| T-7 | Departure from the 07-28 cut: bonfires and shrines | No Rest Squares (D-40). Checkpoints (hub entry, boss-room entry) refill Courage and Believe. | Yes. | A Rest Square marker is a recipe if the owner wants a shrine; then rewrite §1.2 and §6.9. |
| T-8 | Feel changes that alter the approved June feel | Movement lock during a swing (req#19), enemy stagger (req#20), buffer expiry (req#3). All land in M7b before the OG2 feel gate. | Yes. | `rules.tres`, `skill.tres`. |
| T-9 | Docs rewrite | `AGENTS.md`, `ARCHITECTURE.md`, `coding-standards.md` and `.claude/commands/*` are rewritten to match the code (D-36). | Yes. | git. |

D-35: the batch approval covers building the base, not these rows.

### 2.4 `CLAUDE.md` amendment list (applied only after OG0)

The M1a deliverable is a `docs/claude-md-diff.md` with these exact old and new lines for the owner to approve before any code moves in M1b. Rules that stay as they are: "Editor-first, ECS runtime", "parked ActorViews become entities at boot", "a node on an instance beats the definition", "never duplicate a value", "self-documenting names", "no `_draw()` for actors", "research before building", "one logical change per commit".

| # | Old text (CLAUDE.md) | New text |
|---|---|---|
| A-1 | "Folder ownership: `scenes/` = entry/rooms/ui only · `objects/` = reusable prefabs · `resources/` = `.tres` data · `scripts/` = behavior · `assets/` = raw art · `tools/` = build scripts." | "`content/` = the owner's data, art, audio and words (zero `.gd`) · `schema/` = Resource classes · `ecs/` = simulation · `authoring/` = things dragged into scenes · `presentation/` = views and UI · `shell/` = app, save, flow · `assets/` = shared raw art and audio · `tools/` · `tests/`." |
| A-2 | "Presentation (HUD/board/camera/main.gd) consumes `drain_events()` only; it never reaches into the simulation." | "Presentation consumes `drain_events()` and the read-only `HudSnapshot`. It writes the simulation only by pushing typed requests on `world.commands`, never by setting components." |
| A-3 | "New editor-draggable component → extend `EntityComponent` in `scripts/ecs/components/`." | "... in `authoring/entity_components/`. Runtime data classes live in `ecs/components/`." |
| A-4 | "New state → pure-data class + key const in `scripts/ecs/ecs_components.gd`." | "New state → a pure-data class with a `KEY` const in its own file under `ecs/components/`. `ecs_components.gd` is frozen except for edits to existing classes." |
| A-5 | "New decision/behavior → a system in `scripts/ecs/systems/` ticked by the world." | "... a system in `ecs/systems/<phase>/` plus one line in `ecs/schedule/<phase>.gd`. `test_schedule_complete` fails if a system file is unlisted." |
| A-6 | "Verify before you commit" block. | `python3 tools/run_all_tests.py --strict`, then `godot --headless --path . --editor --quit`, `git diff --check`, `tools/stamp_uids.gd --check`. |
| A-7 | "Environment gotchas". | Add: stamp UIDs before moving files; move files only with `tools/move_res.py`; new `.gd` and PNG files need their `.gd.uid` and `.import` sidecars committed; headless `ResourceSaver` resaves drop UIDs. |
| A-8 | "Workflows" list. | Add `/new-skill`, `/new-room`, `/new-beat`; rewrite `/new-enemy` and `/verify`. |
| A-9 | "Sound (three layers, one owner each)". | Unchanged, plus: the `Sfx` autoload registry is keyed from `content/audio/sound_bank.tres`. |
## 3. The emotional arc

### 3.1 Frameworks and what each constrains

| Framework | What it forces in this game | Source |
|---|---|---|
| MDA: design backwards from aesthetics | Every room and beat names its target emotion and release (R1). | MDA |
| Flow (challenge vs skill) | Player-chosen assists, never silent difficulty. Modal text never interrupts combat. A board-state decision every 30-90 s (R31). | Chen; `v2:31-43` |
| Self-Determination Theory | Autonomy: at least 2 viable clears per room (R20). Competence: telegraphs and informational rewards. Relatedness: the child and rescued pieces are interactive (SDT only tested relatedness socially, so using it for a companion is an extension). | SDT |
| Lazzaro's Four Keys | Each act serves at least 3 of Hard (fiero), Easy (curiosity), Serious (meaning), People (the child). Story rides on Serious Fun, not instead of Hard Fun. | Lazzaro |
| Schell interest curve | Rest/Teach/Test/Twist/Boss/Shortcut per district. The Black King is the single highest peak. Intensities rise across bosses (R32). | MDA; `v2:627-650` |
| Peak-end rule | Every boss ends in a clean player-executed win. The pre-boss room is easier than the boss. A relief room follows each boss. Save on success. The ending image, and the player's own last step, is the strongest memory. Evidence in games is mixed, so this is a heuristic, not a law. | Gutwin |
| Failure and fairness | Every damage cell is pre-telegraphed. Deaths are attributable. Retry is fast, and cheaper inside a boss after its first clear of a phase (D-43). | Juul; Miyazaki, Ma, Clark interviews in `emotion.sources` |
| Suspense over surprise | The telegraph is the bomb under the table. True surprise is reserved for single authored moments. | Hitchcock bomb |
| Moving experiences | Loss, attachment and reduced control, followed by reflection. The Queen disabling help and the King shutting the box are earned by prior reliance (R22). The hub is put away at the Under-Bed entry so the loss is real (§7.3). | Bopp; Pathos in Play |
| Awe | Vastness plus low attentional demand. One scale reveal per act, enemies at zero, painted vistas at integer scale, no live zoom (R25). | Possler (search summary only) |
| Game feel | Polish carries emotion. Juice follows a hierarchy so peaks stay special. | Swink |

### 3.2 Arc by act (target emotions, keys, peak, remembered end)

| Act | Target emotion(s) | Lazzaro keys (>=3) | What produces it | Peak | The end the player remembers | Awe slot (enemies = 0) | Child presence |
|---|---|---|---|---|---|---|---|
| 1 Prologue (T1-T2) | Grief, loneliness -> agency | Serious (loss), Easy (props, curiosity), Hard (light: first strike) | Dead King on the first screen, no text, no music, a winding walk past three stations. Sword on a tile. | Standing with the fallen King (optional E) | Picking up the sword | n/a | none |
| 1 Rug (T3-B1-H1) | First competence, defiance, then being seen | Hard (B1), Easy (hub locks, Book), People (Pebble), Serious (the notice) | One clash, repositioning, a captain boss, the child's hand | B1 phase 3 win, then the hand stops above the pawn | H1 relief and a rescue; the under-bed shadow is in view | H1 first look: the bed edge as cliff | none -> crayon scratch (T4) -> notices after B1 |
| 2 Toybox | Suspense -> surprise -> fiero -> lightness | Hard (Knight), Easy (toys), People (first scripted help), Serious (status vs freedom) | 0.9 s L-markers; "may move twice" amendment; the first block from the child, line spoken at room clear | Knight Captain phase 2 late marker, then the train | First Rule Step across the lid gap | Toy-track overpass: the whole rug below | first help (silent block during the fight, one word after) |
| 3 Bookshelf | Wonder, trust | Hard (Bishop), Easy (page worlds), People (chalk, Slant), Serious (written rules vs drawn ones) | Lanes of ink, a crayon bridge drawn before you | Crossing a line the Oracle calls unreal | The crayon handed over; Believe appears | Top shelf: window moonlight over the room | helping hand: Chalk Path |
| 4 Block Tower | Patience, resolve; then a gear-change | Hard (Rook), Easy (blocks), Serious (the confession), People (Stout) | Standing still is brave; holding a line | The Rook smashes its own throne | The Midpoint: "I started this by myself", both inks one hand | Tower summit: the child's hand shadow crosses the rug | Chalk Block; confession |
| 5 Dollhouse | Vulnerability, betrayal -> compassion | Hard (Queen), Serious (the Queen's fear), People (the loss of help) | Believe locked; the Queen offers promotion as being kept, then speaks to the child | The hand stops; Believe greys; the 20 s address | The seal opens when the child's hand lifts a latch; "Then remember us" | Dollhouse stage curtain rises | disrupted |
| 6 Under-Bed | Powerlessness -> defiance -> catharsis | Hard (all verbs re-tested), Serious (freedom), People (memories) | The lid closes and the hub is put away; directions withdrawn and restored by walking three memory alcoves; one open diagonal cell | The free diagonal step and the final strike (highest peak of the game) | The box opens; the pieces become toys again | The Chess Box looming (visible from H1 since Act 1) | cut off, then a non-solving hand |
| Ending | Bittersweet freedom | Serious (primary), Easy (quiet), People | The child offers promotion tokens; the player walks past them and off the board | The pawn steps beyond the board (the player's act) | A held image (10 s or more) before credits | Morning bedroom, zero hostiles | partnership; the child leaves it there |

### 3.3 Arc by boss (tension, release, peak-end)

`Int` is the room intensity used by R32 (bosses are non-decreasing, never three equal in a row).

| Boss | Int | Tension | Mechanic or moment that produces it | Peak | Remembered end | Relief |
|---|---|---|---|---|---|---|
| B1 Pawn Captain | 7 | dread -> first fiero | Corner-slash telegraphs; P3 summons and crumbling cover | Last phase win | The Captain becomes a plain toy, 2 s of silence, then the hand stops above the pawn | H1 |
| KB Knight | 8 | suspense -> surprise -> lightness | 0.9 s L-marker; the Book flips mid-fight ("may move twice"); train hazard | Late second marker, then the train | The leap that clears the lid gap | tb4, H1 shelter |
| BSB Bishop Oracle | 8 | wonder, trust | Growing diagonal lanes; mirrored beams; the arena tears into islands; the child draws the bridge | Crossing the "unreal" line | The crayon handed over | bs4, H1 banners |
| BTB Rook Warden | 9 | patience, resolve | Declared lane, charge, stun; the Rook will not turn | The Rook smashes its throne | The stunned Rook among the broken throne pieces, then the Eraser (Guard) handed over as its lost line | bt4, H1 train, Midpoint |
| DHB Queen | 9 | betrayal, fear -> compassion | Tear the Drawing; the Queen's promotion offer; the Queen's sincere fear | Hand-stop and Believe greying | The seal opens by the hand's latch | dh4, H1 gather |
| UBB Black King | 10 | powerlessness -> defiance -> catharsis | Direction lock; memory alcoves restore directions; one open diagonal cell | The free step and the final strike | The box opens | Ending |

### 3.4 The first five minutes, beat by beat

The clock matches the room minutes of §7.4 (T1 2 min, T2 3 min, T3 3 min, T4 4 min). The route bot's measured minimum clear time per room replaces these estimates in M5 and M9.

| Time | Player sees and does | System | Emotion | Feedback channels (R2: 3 or more at the first step) |
|---|---|---|---|---|
| 0:00 | Title: the rug board in dusk light, one white pawn standing apart, room tone only. Press New Game. | `AppRoot`, title | quiet | UI confirm sound |
| 0:01-0:05 | Fade. Establishing shot: pieces fallen, the lamp, Black pieces leaving frame. Wordless. Skippable (skip -> control at 1.5 s). | BLOCKING beat `s01_opening`, `CinematicStage` | loss | slow camera push |
| 0:05-0:08 | The pawn wakes (existing `wake` clip). Control at about 7.5 s. | `view_commands` | | |
| 0:08 | First step. | MovementSystem | | step tap SFX, dust puff, squash/stretch |
| 0:08-2:00 | T1 walk. A winding route past three proximity-reactive stations: scattered white pieces (dust lifts as the pawn nears), the lamp (it flickers), and the King (a music-box note on approach). The exit lies beyond the King. No enemies, no text, no music. A distant Black Recruit marching away is a non-lethal preview. After 6 s of idle, a movement hint fades in (R5). Optional E at the King: the pawn bows. The silent stretch is capped at 60 s (R3). | `InteractComponent`, `TriggerSystem` | grief, reflection | silence is the feature |
| 2:00 | Fade. Chapter tint: dusk. | | | |
| 2:00-5:00 | T2: a sword on a lit tile, left by a cheating Black piece. Pickup unlocks the Wooden Sword at about 2:45. Page 1 of the Book appears. | GrantMarker, ProgressionSystem | agency | pickup chime, glow (not red), HUD slot fades in |
| 2:45-5:00 | One prompt: "Press {attack} to strike." A harmless crayon target on the pawn's side forces one Shift-turn. Prompt "Hold {turn_mode} and a direction to turn." The prompt shows once, when no hostile is alive, and fades on use. First strike at about 3:15. | `PromptWidget` | competence | hit-stop 60 ms, chips, thunk |
| 5:00-8:00 | T3 First Pawn Clash. The room line "Wait for the warning. Strike." appears before aggro, in the Book's printed ink. One Pawn Recruit, 0.58 s telegraph, the exit locked until clear. | EnemyAISystem, ObjectiveSystem | suspense -> first fiero | room-clear sting, exit unlock sound, autosave (success event) |
| 8:00 | T4 begins. A blue crayon scratch runs across one tile. The Armed Pawn pokes from range 2. | | defiance, curiosity | |
| about 11:30 | The Pencil lies just past the Armed Pawn on the exit path. | GrantMarker | defiance | pickup glow |

If the player is faster, nothing is skipped. If slower, nothing nags (R5, R12).

### 3.5 Emotion rules R1-R37: how each is enforced

`H` = hard check (fails every run). `S` = soft check (a warning in the editor tool; a failure only in `--strict` agent gates).

| R | Rule | Enforcement | H/S | Milestone |
|---|---|---|---|---|
| R1 | Emotion is data: every room and beat has `emotion_target`, `release_beat`, `lazzaro_key`, `intensity`. `release_beat` must resolve to a real room or beat id within the next two route nodes, with a lower intensity. The four designated peaks (Queen reveal, box closing, final step, ending hold) carry `peak: true`. | `test_emotion_fields.gd`, `tools/print_arc.gd` | S | M5/M6 |
| R2 | Control within 10 s of New Game, 3 or more feedback channels at the first step | `test_time_to_control.gd` plus feedback matrix | H | M6 |
| R3 | T1 is a loss scene: no enemies, no text boxes, no music; three proximity stations each within 2 cells of the route; route length 28 cells or more; the King within 3 cells of the route; the silent stretch is 60 s or less | `test_t1_audit.gd` (route length and station count, not just distance) | S | M6 |
| R4 | Teach ladder: a Teach room introduces at most one new verb or shape; the new shape is shown telegraph-only (fenced) before any damaging instance in that room; threat 3 or less | `test_room_data_audit.gd` | S | M5+ |
| R5 | One prompt at a time, only when no hostile is alive; every gameplay action has exactly one prompt or a documented "no prompt" reason | `test_prompts.gd`, `test_prompts_cover_actions.gd` | S | M6 |
| R6 | Telegraph contract: every `AttackBase` has a telegraph of at least `telegraph_floor_seconds` (0.45 s; knight landing 0.9 s) after assists, and damage cells are a subset of telegraphed cells | `test_telegraph_contract.gd` over all attack data | H | M8a |
| R7 | Red is sacred: saturated red only for imminent damage | palette lint plus screenshot review | S | M8c |
| R8 | Hold the death frame 0.6 s or more with the damage origin visible (the damage payload carries `source`) | `test_death_freeze.gd` | H | M8c |
| R9 | Retry control in 5 s or less; the walk from the retry spot to a boss is 20 s or less; inside a boss, death-to-next-damage is measured | `test_retry_time.gd` | S | M8c |
| R10 | The first death by each enemy family writes a Book margin note in neutral printed ink | `test_death_knowledge.gd` | S | M8c |
| R11 | Forgiveness never tightens under stress (buffer 0.12 s is the floor). The Free Step chord window is detection latency, not forgiveness, and is a `FeelProfile` field | `test_input_buffer.gd`, `test_free_step_window.gd` through `InputSnapshot` | H | M7b |
| R12 | No hidden rubber-banding; one gentle offer after 3 consecutive deaths in one encounter; an assist offer after 5 deaths or 15 minutes on one boss | grep that no system reads `deaths.*` unless an assist flag is on | H | M8c |
| R13 | Boss `rule_taught` and `rule_bent` are present and phase configs differ in shape, timing or arena | `test_boss_phase_differs.gd` | S | M8b |
| R14 | The final blow always traces to a player attack entity (payload `source`) | `test_player_kill_only.gd` | H | M8b |
| R15 | Juice hierarchy: normal hit has 4 channels; boss kill the maximum; reduce toggles never remove telegraphs | FX matrix review plus accessibility test | S | M8c/M14 |
| R16 | Relief after every boss: a zero-hostile sequence (shortcut room plus hub arrival) of 45 s or more that visibly changes | `test_relief_after_boss.gd` | S | M9+ |
| R17 | Autosave only on success events | list of `SaveService.request_save` callers | H | M3b |
| R18 | The room before a boss has a lower threat budget than the boss's phase-1 budget; Test and Twist rooms 3-6 (per wave in gauntlets; a room flagged `intro`, such as T3, is exempt from the floor) | `test_threat_budget.gd` | S | M5+ |
| R19 | Each act spec lists 3 or more keys with the room serving each | act checklist in §3.2 | S | M14 |
| R20 | At least 2 viable clears per combat room (`solutions` field in room meta) | QA recording | S | M14 |
| R21 | The child is a person, not a menu: no speech before B1; lines of 8 words or fewer; at most 1 per room; speech only in safe states, never while a telegraph or the attack token is live. (These numbers are this plan's own; `nar3` lists only the qualitative rules.) | `test_child_voice.gd` | S | M6 |
| R22 | Earned reliance: the critical path forces at least 3 child calls before `dhb` (`bs4`, the H1 Block Tower door, the `bt2` entry gap, the `dh1` foyer gap) as free `TraversalGap` casts, counted in `child_calls_used`. Help is disabled only when the counter is 3 or more, with a hand-stop, a HUD change and a 20 s quiet beat | counter in flags plus sequence test; asserted in `test_full_route` | H | M12 |
| R23 | Controls as story in Act 6: no damage in the 30 s after any withdrawal; learnable in 30 s or less | scripted test plus QA | S | M13 |
| R24 | At least one rescue by the end of the Act 1 hub, via an interaction that costs time | `test_rescue_in_h1.gd` | S | M6 |
| R25 | One awe slot per act, enemies = 0 at trigger, view held 3 s or more. The slot is a painted vista or parallax layer at integer scale. The `Camera` beat step may only pan and shake | camera-event audit | S | M9+ |
| R26 | The Under-Bed silhouette is in the H1 backdrop and gains detail after each boss | screenshot checklist | S | M6+ |
| R27 | Preview before lethal for every enemy family: a fenced, telegraph-only instance appears earlier on the route | `test_preview_before_lethal.gd` (graph audit) | S | M5+ |
| R28 | Simultaneous threat shapes, by act: normal rooms 2/2/2/2/3/4, bosses 2/3/3/3/4/4. Each shape has a pattern as well as a colour | encounter data audit | S | M8a |
| R29 | Story is data: no literal story strings in scripts or scenes | grep test | H | M4/M6 |
| R30 | The ending is earned release: the last 3 minutes have zero damage; the final image holds 10 s or more; **the final playable act is a previously forbidden free move chosen by the player (the pawn steps outside its square), and the last input before the hold is a movement step** | `test_ending_audit.gd` | H | M13 |
| R31 | Decision gap: the longest stretch without a board-state decision per room, measured by the route bot and logged in playtests, is 90 s or less | `test_decision_gap.gd`, attempt logger | S | M8c |
| R32 | Arousal alternation: no three consecutive critical-path rooms share an `intensity`; boss intensities are non-decreasing with no three equal; never two boss-grade rooms (8 or more) in a row; a 20 s low-demand stretch follows any room with 3 or more shapes | `tools/print_arc.gd`, `test_arc.gd` | S | M14 |
| R33 | Resource states never soft-lock: the graph walk runs with Believe 0, Courage 1, all cooldowns running, and chalk expiry mid-gap | `test_no_softlock_resources.gd` | H | M10 |
| R34 | Free Step is learned before it is needed: a head-shake denial and margin note on the first chord press from T1 on, and a 10 s rehearsal beat at the start of Black King P4 | `test_denied_chord.gd`, `test_free_step_rehearsal.gd` | H | M6/M13 |
| R35 | Presentation follows the relationship: no hand before the notice, reset variants by flag (D-44) | `test_reset_variants.gd` | H | M8c |
| R36 | The clue chain: six clues, the Desk reveal references 4 or more; `child_trust` rises at least once every 10 minutes of critical path | `test_clues.gd`, route bot | S | M6/M13 |
| R37 | Micro-rewards: at least one persistent reward (Page, shard, keepsake drawing, hub change, rescue or earned story beat) per 6 minutes of critical path | `test_reward_cadence.gd` over the Reward column of §7.4 | S | M5 |

Evidence caveat: hit-stop durations differ by source (about 40-80 ms versus about 0.2 s), telegraph minimums and rest-beat lengths are `[start value]`, and peak-end evidence for games is mixed. All are tuned in QA against outside playtesters.

### 3.6 Emotional playtest gates (G9)

The only emotional instrument in the draft was an M14 form. Three probes are now built in, each with the owner plus any testers available (agents cannot recruit testers; the instrument is what the base ships).

| Probe | When | What to ask (5-question form in `docs/playtest-form.md`) |
|---|---|---|
| P1 | End of M8c: Act 1 complete (about 22 min) | 1. What did you feel at the end of the first room? 2. Where were you bored? 3. What do you remember? 4. What killed you (the cause, in your words, R8)? 5. Did the hand feel like a person (hesitation, fear, delight)? |
| P2 | End of M11: the Midpoint | The same five, plus "what did the confession change?" |
| P3 | End of M13: the ending | The same five, plus the last 2 minutes recorded (events log) and "what did the final step feel like?" |

The attempt logger (M8c) records attempts per room, death causes, time per room, the longest decision gap, and the last 2 minutes of events. A hook compares reported emotion with each room's `emotion_target` in the owner's spreadsheet; no tool is written for that.
## 4. The story skeleton

### 4.1 Premise and tone

A child plays a chess war on the bedroom rug. The white side loses. The white King is laid down, the Black pieces leave, and one white pawn, the weakest piece, is left on its square. It gets up. It has no one to tell it where to step, so it steps. The pawn does not win by becoming a Queen. It wins by being free: it learns the moves the board forbade it, one at a time, and at the end it declines promotion and steps outside the board. The child, who started the war alone, learns to let the pawn act alone.

- **Tone** (`gdd:447-449`): serious war, warm playground, no gore, humour only from scale and material. Defeated pieces "become ordinary toys again". Grief is never mocked. Each district also carries one designed play or humour beat (§7.4), so the arc is not uniformly heavy.
- **The one-night frame**: the game runs from dusk to morning (D-31, Tier B tint on the background layer only).
- **The rule motif** (D-32): "rule" means chess rule, house rule and ruler. Black are the child's own rules made pieces (bedtime, tidy-up, play it right). The Captain wields a ruler blade (`resources/enemies/black_pawn_captain.tres`, default weapon `ruler_blade` [measured]). The toolset is pencil and eraser.
- **Never explained**: whether the pawn is "really" alive (Winnicott's transitional space, per the story research). The bedroom shows the toy truth, the board shows the felt truth, and the blue crayon crosses both.
- **Told through mechanics** as well as words: every verb is a chess rule the pawn breaks; every unlock flips a Book page from "may not" to "amended" in the child's handwriting (§4.4, §4.7).

### 4.2 Characters

| Character | Role | Arc | How it appears |
|---|---|---|---|
| The Pawn | Hero. Silent: emote icons only (afraid, determined, relieved, glad, hesitant, calm; §4.5). | Obedient survivor -> angry rebel -> responsible liberator; chooses its own rule by stepping off the board. | Actor, "bow" and "hesitate" animations, the playable ending |
| The Child | Companion and relatedness engine. | Distant player -> notices -> protector -> trusted companion -> learns to leave the pawn alone. Curious, sometimes scared, never sarcastic. | A large smooth hand, a shadow, blue crayon lines, a close soft voice (8 words or fewer) |
| White King | Dead focal prop in T1. | none | Fallen prop; optional bow |
| Pebble (white Knight) | Rescue 1 (H1). Fear of being put away. | Restores LEFT in the finale. | Interactable, then hub resident with one bark |
| Slant (white Bishop) | Rescue 2 (`bs3`). Afraid of off-diagonals. | Restores RIGHT. | Interactable, then a hub prop |
| Stout (white Rook) | Rescue 3 (`bt2`). Always fell in line. | Restores BACK. | Interactable, then a hub prop |
| Black Pawn Captain | Rank Breaker. Pride in holding a line. | Falls into a toy. | B1 |
| Knight Captain | Pride in status: "You cannot catch what leaps." | Teaches the leap by being outgrown. | TBB |
| Bishop Oracle | Faith in written lines: "Every piece has a purpose." | Cannot see the crayon line. | BSB |
| Rook Warden | Force and walls: "The straight path is the only path." | Breaks its own throne. | BTB |
| Queen of Tricks | Ideological antagonist; sincere fear that a world without rules is forgotten (`gdd:442-443`). She offers the pawn promotion as being kept. | Speaks to the child. | DHB |
| Black King and the Rule Engine | A rule system pretending to be a person (`nar1:99`). | "The rules are mine." | UBB |
| The Book's printed ink | A fourth voice: room lines, boss intros and Book notes. Neutral, never the child's blue. | n/a | `DialogueBox` style, `CharacterDefinition` `book_ink` |

### 4.3 Beats in order

Every beat is a `StoryBeat` (§8). Lines are PLACEHOLDER, short, and the owner will rewrite them in the `.po` files. "Key" is the `.po` key. Each placeholder carries a `purpose` (what it is for) so a rewrite keeps the intent. Room lines are spoken by the Book's printed ink, not by the child.

| ID | Where | How delivered | Beat | Placeholder line (key) |
|---|---|---|---|---|
| S01 | Title -> T1 | Cinematic, wordless | War over; King down; Black leaves; one pawn remains; the pawn wakes | none |
| S02 | T1 | Environment + optional interact | Dead King; scattered white pieces; retreat marks; clue 1 (the King's base is worn by another hand). E at the King: bow and a music-box note | none (emote only) |
| S03 | T2 | Environment + mechanic | A toy sword where no toy belongs; unlock Wooden Sword; Book page 1 (The First Law) | `PROMPT_STRIKE`: "Press {attack} to strike." |
| S04 | T3 | Room line + mechanic | First Black pawn: wait, then strike | `ROOM_T3_START`: "Wait for the warning. Strike." (existing, Book ink) |
| S05 | T4 | Prop (crayon scratch) + mechanic | The pawn must reposition to survive; the Armed Pawn teaches reach; a blue line crosses one tile; the Pencil lies just past it | `ROOM_T4_START`: "A pawn need not stand and be struck." |
| S06 | B1 | Boss intro, phase, defeat, then cutscene | Captain: "Nothing passes the rug's edge." Defeat: it becomes a toy, 2 s silence. The hand stops above the pawn, draws a small blue mark, the desk light snaps on. Rank label 3. The Ruler Blade drops. | `BOSS_B1_INTRO`: "Nothing passes the rug's edge." |
| S06b | B1 notice | Emote only | The pawn bows to the hand (afraid, then hesitant): at first it believes the child is a god (req#205) | none (emote) |
| S07 | H1 | Ambient child line + interaction | The child's first word. Rescue Pebble (hold E 1.5 s). The under-bed shadow is in view. Doors explain their locks. Clue 2 (a second mug by the bed) | `CHILD_H1_FIRST`: "...You moved." / `PEBBLE_RESCUED`: "I thought I'd be put away." |
| S08 | tb1-tb2 | Environment | Knight previewed behind a fence, telegraph-only. The Charging Pawn's dust lane. | `ROOM_TB1_START`: "Mind the leap." |
| S09 | tb3 | Scripted child intervention | The hand drops a block to stop the toy train: **sound and hand only during the fight**. At room clear the first spoken help. The alcove grants Rule Step. | `CHILD_TB3_BLOCK` (at clear): "...here?" |
| S10 | tbb | Boss beats | Knight: "You cannot catch what leaps." P2: the Book flips in grey pencil: "The Knight may move twice." Defeat: it becomes a toy horse. Knight Errant page flips ("...and so may you"). | `BOSS_KB_INTRO`, `BOOK_KNIGHT_AMEND` / `CHILD_KB_AFTER`: "You jumped. Higher than him." |
| S11 | tb4 + H1 | Mechanic + hub change | The lid path has a gap that only a leap crosses (forced first use). Hub: the hand places a block shelter while the pawn is at the far edge. | none |
| S12 | bs1 | Room line + preview | A fenced Bishop shows its lane band (telegraph-only); the Book notes the Bishop never leaves its colour | `BOOK_BISHOP_NOTE`: "A bishop keeps to its colour." |
| S13 | bs3 | Child demo + rescue | The child draws a bridge by script while you watch (Believe not spent). Rescue Slant (hold E 1.5 s). | `CHILD_BS3_DRAW`: "Hold on... there." / `SLANT_RESCUED`: "I only dared the diagonal." |
| S14 | bsb | Boss beats | Oracle: "Every piece has a purpose." P3: the pawn crosses the crayon line the Oracle says is not real. Reward Chalk Path. | `BOSS_BSB_P3`: "That line is not real." |
| S15 | bs4 + H1 | Hub change | Crayon banners and paper bridges appear while the pawn is away | none |
| S16 | bt1-bt3 | Environment + rescue | Standing still is brave. Rescue Stout in `bt2` (hold E 1.5 s). Clue 4 (two names on a block, one scribbled out) | `STOUT_RESCUED`: "Straight lines kept me safe. Not free." |
| S17 | btb | Boss beats | Rook: "The straight path is the only path." P3: the Rook refuses to turn and breaks its throne. Reward Eraser Guard. | `BOSS_BTB_INTRO` |
| S18 | H1 Midpoint | Tier-1 cutscene + painted vista (awe) | The child's confession: the war began as a story told alone, and "I only imagined it ending better" (req#205). Both inks are one hand. Chalk Block unlocked. | `CHILD_MIDPOINT_1`: "I started this by myself." / `CHILD_MIDPOINT_2`: "You kept going." / `CHILD_MIDPOINT_3`: "I only imagined it ending better." |
| S19 | dh1-dh3 | Environment | The Queen's voice offstage; furniture barricade; clue 5 (a framed photo turned face-down) | `QUEEN_DH1`: "Tidy up, little one." |
| S20 | dhb | Boss beats | The Queen offers promotion as being kept ("Rank up. Be kept."), then addresses the child (20 s quiet beat): "Put them away." / "A world without rules is forgotten." / "I only wanted it kept." Help disabled. | `QUEEN_OFFER`, `QUEEN_ADDR_1..3` |
| S21 | dhb defeat | Tier-1 cutscene | The seal bears a diagonal mark. The pawn tries a chord and the head-shake denial plays. The child's hand lifts a latch and the seal opens. The Queen: "Then remember us." | `QUEEN_LAST`, `CHILD_SEAL`: "I won't forget." |
| S22 | Under-Bed entry, ub1 | Environment | The lid closes: the child is cut off and H1 changes to its `boxed` state (the gathered pieces, banners and train are put away). Rescued pieces' memories on the wall (zero hostiles). Clue 6 (an empty box slot) | `MEM_PEBBLE`: "Left is yours." / `MEM_SLANT`: "Right is yours." / `MEM_STOUT`: "Back is yours." |
| S23 | ub2-ub3 | Mechanic | Every earlier verb re-tested; the Rule Engine rewrites tiles | none |
| S24 | ubb | Boss beats | King: "The rules are mine." P3: Close the Box, the pawn is forward-only and walks three memory alcoves, each restores a direction (a crayon outline stands in for any piece not rescued). P4: a 10 s rehearsal, then one open diagonal cell. Final strike. | `BOSS_UBB_INTRO`, `KING_P3`: "Enough play." |
| S25 | e1 | Playable ending | The Desk board; the child's hand offers four promotion tokens (Queen, Rook, Bishop, Knight); bumping a token plays its epilogue; the pawn walks past them and off the board's edge along the blue line; the child leaves it there. Desk reveal references 4+ clues. | `END_PROMOTE_TITLE`: "Rank 8. Choose what you become." `CHILD_END`: "Good morning, pawn." |
| S26 | Credits | Data credits over the held final image | Hold 10 s or more, then credits, then title with the "one square empty" board | `CREDIT_*` |

### 4.4 The pawn breaks the rules: unlocks as story

| Unlock | Chess rule | What the pawn breaks | Book page change |
|---|---|---|---|
| Wooden Sword (T2) | A pawn captures one square diagonally | It strikes straight ahead, with a toy | "Nobody said it couldn't." |
| Pencil Thrust (T4) | Two-square first move | The double step becomes an attack | page margin: "first move, every move" |
| Rule Step (`tb3`) | Only the Knight jumps | The pawn borrows the leap | "The Knight may move twice" (grey pencil) -> "...and so may you" (blue crayon) |
| Chalk Path (Bishop) | The board cannot change | The child bends the board | "The board obeyed." (existing flavor) |
| Eraser Guard (Rook) | The Rook owns straight lines | Standing still, rubbing the line out | "Hold the line." |
| Free Step (King) | A pawn captures diagonally but NEVER moves diagonally | The first diagonal move | "A pawn may step. Any way." |
| Refusing promotion | A pawn on rank 8 must promote | It declines, and walks off the board | "Stay as I am." |

Rule: unlocks never come from XP. Each negates the belief of the boss that held the rule. Enemy amendments are written in grey pencil, the pawn's unlocks in blue crayon (D-46).

### 4.5 The child layer

- **Presence curve**: none (T1-T3), trace objects (T4), recognition (after B1), a helping hand (Acts 2-4), disrupted help (Act 5), silence in the box (Act 6), together at the end (R21-R22).
- **Voice rules** (R21, this plan's own numbers): 8 words or fewer, at most 1 line per room, emotional before instructional, never while a telegraph or the attack token is live, never a tutorial robot. The pawn is silent.
- **Zero-text presence layer** (data only, so the bond is felt in the 80 minutes where the child speaks about 20 words):
  1. Hub states are the child's gifts: the hand visibly places the shelter, banners and train while the pawn is at the far edge.
  2. A blue tally tick appears on each cleared room's exit marker.
  3. The child's drawing of the pawn appears in the Book after each boss and gains detail. These are the keepsakes (one on the critical path per district, R37).
  4. The hand's shadow crosses the board when a checkpoint refills.
  5. A flinch animation on the hand's shadow when the pawn takes damage.
  6. Rescued pieces appear as bystanders in later rooms.
  7. `child_trust` is a counter incremented by these events. `test_clues.gd` asserts it rises at least every 10 minutes of critical path (R36).
- **Show, do not tell**: hesitation (the hand hovers before it arrives). Its shadow crossing the board is the telegraph of a child call.
- **Pawn emote palette** (`content/story/emotes.tres`, event -> emote, cooldowns): afraid (low Courage), determined (boss intro), relieved (boss defeat, rescue), glad (pickup, reunion), hesitant (hand arrives), calm (hub). Emotes are fired by presentation from drained events, never by the simulation. A beat can also fire an `Emote` step.
- **Fourth-wall tone**: gentle (`gdd:447-449`).

### 4.6 Death and retry as story

The default defeat line is "THE CHILD RESETS THE BOARD" (`scripts/main.gd:296`; `soul:94`), but the presentation of the reset is chosen by relationship flags (D-44, R35):

| State (flags) | Reset presentation |
|---|---|
| Before the B1 notice | No hand. The pawn simply rises with the existing `wake` clip. The line is replaced by silence. |
| After B1 | The hand places the pawn back gently (the first gentle reset is a small relatedness beat). |
| After the Queen's address | The hand hesitates before it places the pawn. |
| Under the lid in Act 6 | No hand. The pawn rises alone. |
| Ending | Gentle. |

| Tier | Trigger | Child's response | Key |
|---|---|---|---|
| 1 | Any death | silent | none |
| 2 | 3 consecutive deaths in one encounter, after the notice | a hesitant, non-solving nudge, once | `CHILD_RETRY_2`: "...another way?" |
| 3 | 5 deaths or 15 minutes on one boss | an assist offer, once, neutral name | `CHILD_RETRY_3`: "Want it a little slower?" |

The first death by each enemy family also writes a margin note in the Book in neutral printed ink (R10). Assists are also always reachable from the Pause menu (D-22).

### 4.7 The Book of House Rules as lore

The Book is the optional lore channel (`ui3:21-30`). Each page has an `original_rule`, an `amendment` (existing `RuleEntry` fields) and an `ink` (grey pencil for enemy amendments, blue crayon for the pawn's unlocks, neutral printed ink for notes, D-46). A page can be unread, read, new or rewritten. Pages unlock on first sight in combat, not on zone load. The world freezes while the Book is open (M4).

- **Rule Pages** (equippable, §6.4): First Law, Armed Pawn, Backstep Pawn, Charging Pawn, Knight Errant.
- **Lore entries** (no Margin cost, no modifiers), one per piece and boss: Black Pawn Captain, Knight Captain, Bishop Oracle, Rook Warden, Queen of Tricks, Black King, plus the Bishop and Rook families. A test asserts that no page id equals a boss id.
- **Drawings tab**: the child's keepsake drawings (§4.5).

### 4.8 Environment first, and the clue chain

Every room spec has a required `what_happened_here` line (one prop-level vignette). Every beat has a prop version so text is optional and the owner can redraw it. Examples: T1 scattered pieces; T4 the crayon scratch; H1 the half-built shelter; UB1 the wall of memories.

**What the child lost (D-45, O-2).** The base shows the shape of the loss with props only, never lines. The owner can replace every clue. Each room carries a `clue_index` in its meta, `tools/list_clues.gd` prints them, and `test_clues.gd` checks that the Desk reveal references at least four earlier clues.

| Clue | Room | Prop |
|---|---|---|
| 1 | `t1_white_kings_fall` | The white King's base is worn smooth by another hand |
| 2 | `h1_chess_rug_hub` | A second mug beside the bed |
| 3 | `bs2_diagonal_chapel` | A bookmark in a book too big for the child |
| 4 | `bt1_block_yard` | Two names written on a block, one scribbled out |
| 5 | `dh1_foyer` | A framed photo turned face-down |
| 6 | `ub1_castle_gate` | An empty slot in the chess box |
| Desk | `e1_morning_desk` | A second chess set and an unfinished game |

Props that follow a flag (hub evolution, the memory wall, clues and ending variants) are built with the `StateVariantMarker` (§13.2), so the owner can add one without code.
## 5. Gameplay systems

### 5.1 Core rules

| System | Rule |
|---|---|
| Movement | Four-way, one cell per input, no diagonal (until Free Step). Step 0.18 s, held repeat 0.22 s (`gdd:94-100`). **Buffered input of 0.12 s that expires is new behaviour**: today `PlayerInput.buffered_direction` has no timer and never expires (`ecs_components.gd:47-52`; req#3). It lands in M7b as an owner-visible change (T-1, T-8) with a `buffer_window` field in `FeelProfile`. Shift+direction turns in place; it cannot interrupt a step or an impact window (the current turn branch runs before the moving check, req#7: fixed in M7b). A blocked step gives a bump sound and animation, never silent (the `step_blocked` event has no consumer today, `movement_system.gd:44`; M8c adds one). Reserve-then-commit occupancy (existing). Facing is the last direction, also when blocked. |
| Strike | Wooden Sword: 1 cell ahead, damage 1, impact 0.07 s, recovery 0.30 s (`attack_profile.gd` defaults). The pawn cannot step during `move_lock_seconds` (0.17 s `[start value]`, new in M7b: `MovementSystem` never reads `PlayerCombat` today). Target cells locked at swing start; one damage per swing. |
| Hit reaction | An enemy hit staggers 0.35 s (no new telegraph can start; it does not cancel a committed attack). Armored faces recoil with no damage (Iron Rook front, M11). |
| Player damage | Courage 3, one hit = 1 (signature boss attacks = 2). Invulnerable 0.7 s after a hit (existing). The damage payload is `{target, source, amount, direction, tags}` and is built only by `Events.emit_damage()` (M3a). |
| Enemy attacks | Telegraph locks the cells; stepping out dodges (existing). One room attack token; boss phases may set capacity 1-2. Telegraph 0.45 s or more after assists; knight landing 0.9 s (R6). Attacks are staged (§5.10). |
| Camera | Static for boards up to 18x9, with a per-room centred origin and integer-pixel snap (§10). |
| Grid | Cell kinds, leaps and rays are first-class (§5.11). |

### 5.2 Health, healing, death

- **Courage**: 3 base, up to 5 with Courage Shards (3 shards = +1; 6 shards exist).
- **Healing**:
  - **Checkpoints** (hub entry and every boss-room entry, D-16) restore full Courage and full Believe. There is no Rest Square (D-40).
  - Courage carries between rooms inside a district through the `PlayerSnapshot` (§14.2).
  - Respawning gives full Courage (the pawn comes back on the entry of the room it fell in, not at a checkpoint: see below).
  - Nothing heals by time.
- **Death**: freeze-frame 0.6 s or more showing the damaging attack's origin, then the reset presentation chosen by relationship flags (§4.6), control within 5 s. The room the pawn fell in resets, and the pawn stands on the entry it came into that room by (below); a boss resets to its highest checkpointed phase (D-43). Death is `respawn_requested` handled by `GameFlow`, never `reload_current_scene()` (`main.gd:120, 302`), so the shell and music survive.
- **Checkpoints**: coming into a hub or a boss room through a door. A checkpoint refills Courage (and Believe, from M10), is recorded in the run (`checkpoint_zone_id`, `checkpoint_entry_id`, `[checkpoint]` in the save) and saved (`checkpoint_reached`), and is what the pause menu names (M4). It is not where a death returns. Cleared rooms stay cleared (D-17).
- **What a death returns to (a gap in D-16, filled in M3b step 3).** The plan says both "return to the latest checkpoint" (req#60) and "a death resets only the current uncleared room", and a checkpoint exists only at a hub entry and a boss-room entry, so read literally a death in T3 would send the pawn back to the start of the district. The least punishing reading is built, and it is exactly this: **a fallen pawn is respawned on the entry of the room it fell in** (the entry marker it came into that room by; full Courage, that room whole, a boss room back at its first phase), so no death takes the pawn farther back than the room it fell in. **The checkpoint** (the hub and boss-room entries) **is recorded, and is where Courage (and Believe, from M10) refill**; no death, restart or Continue sends the pawn to it. **A Continue resumes in the room and on the entry of the last save** (`[meta] room` and `room_entry`; a save is written only at a success event, so that is the room of the latest success event, and right after a checkpoint it is the checkpoint's own entry). To send a death to the checkpoint instead, `GameRoot._ready()` and `GameRoot.respawn()` read `checkpoint_zone_id` and `checkpoint_entry_id` where they read `room_zone_id()` and `room_entry_id()` today (`SaveBridge`), and the death tests change with them.
- **Autosave** on room clear, shortcut opened, persistent pickup, boss defeat, rescue, hub entry and beats flagged `save_after`. Never mid-fight (R17). A plain trip between rooms, a death and a restart are not success events and write nothing.

### 5.3 Enemies (identity, tell, counter). All numbers are `[start value]` unless marked `[measured]`.

| Family | Enemy (id) | Identity (one sentence) | Tell | Counter | Placed in |
|---|---|---|---|---|---|
| Pawn | Recruit (`pawn_recruit`) | A conscript who attacks the two cells diagonally in front, slowly. | Corner-slash hatch, 0.58 s `[measured: pawn_diagonal.tres]`, orange then red | Step out, strike in the long recovery | t3, t4, tb1, bs1, bt1, bt2, bt3, dh3, ub2, ub3, boss guards |
| Pawn | Armed (`pawn_armed`) | A pawn with a toy weapon; Pencil Spear hits 2 straight cells, Ruler Blade the front plus forward diagonals. | Straight bar 0.56 s or fan 0.62 s `[measured]` | Sidestep; the pencil lane is also yours | t4, ub2, boss summons |
| Pawn | Backstep (`backstep_pawn`) | "May move backward" (amendment). Retreats after a hit. | Short hop-back before it strikes | Corner it | t4 (as in the repo, `t4_broken_rule_yard.tscn:62`), bs1 |
| Pawn | Charging (`charging_pawn`) | Moves two cells in a leap (amendment). | A 2-cell dust line, 0.50 s | Stand beside the lane | tb2, bs3, ub2 |
| Knight | Tracker / Guard (`knight_tracker`) | Steps in L-shapes and lands on you; vulnerable after landing. | Outlined L marker with crosshair, 0.9 s; its shadow shows the destination | Step to the safe cell; strike during the 1.2 s recovery | tb1 (fenced), tb2, tb3, dh2, ub2 |
| Bishop | Zoner (`bishop_zoner`) | Keeps range 4-7 and fires a diagonal lane. | Lane band with chevrons growing outward over 0.8 s | Cross the lane between bands | bs1 (fenced), bs2, bs3, dh2, ub2 |
| Rook | Wooden / Iron | Declares a row or column and charges until blocked. | Arrow row, 1.0 s declaration, then 0.08 s per cell | Cover, side or back strikes; Wooden breaks after 2 collisions; Iron has a front armor | bt1 (fenced), bt2, bt3, dh3, ub2 |
| Queen | (boss) | Combines lines with command marks. | Union of rook and bishop bands; fewer simultaneous lanes | Read which lane is live | dhb |
| King | (boss) | One-cell pressure with the Rule Engine rewriting tiles. | Pulsing ring and tile grid | Everything you learned | ubb |

A lint asserts that every enemy in this table is placed in at least one room (`test_enemy_placement`), because pages and previews depend on it. Mirror and Torn Bishop variants are deferred (req#79); the Oracle's mirrored beams in P2 are boss data plus a redirect-cell prop. Passant Wraith, Promoted Zealot, Veteran and Desperate pawns are deferred (§1.2, §6.10).

**Threat points** (budget lint R18/R28): recruit 1, armed 2, backstep 2, charging 2, knight 3, bishop 3, rook 4, commanded pawn 1, tile-rewrite or train hazard 1.
**Budgets**: Teach rooms 3 or less with a fenced preview first (R4); Test and Twist rooms 3-6 (per wave in gauntlets; a room flagged `intro`, such as T3's single Recruit, is exempt from the floor); the room before a boss at most 6 and always below the boss's phase-1 budget. **Boss phase-1 budgets**: B1 6, KB 7, BSB 7, BTB 8, Queen 8, King 9.
**Shapes at once (R28)**: normal rooms by act 2/2/2/2/3/4, bosses 2/3/3/3/4/4.

### 5.4 Bosses (each teaches, then twists)

HP is capped between 8 and 18 so late fights are lengthened by phases and objectives, not by hit points. Bosses are tuned for the mandatory-only kit plus 3 Courage; Pages, Pencil and Chalk Block only make them easier. `cp` marks a phase checkpoint (D-43).

| Boss (id) | Arena | HP | Phases (rule_taught -> rule_bent) | Reward and persistence |
|---|---|---|---|---|
| Black Pawn Captain (`black_pawn_captain`) | 16x9 | 8 (today's 4 in `black_pawn_captain.tres` [measured]; raised for 3 phases) | P1 slow diagonal poke (read the slash). P2 `cp` ruler blade: front plus forward diagonals, shove (standing in front is no longer safe). P3 `cp` summons 2 recruits and cover crumbles (the arena shrinks). | Rank label 3, Margin +2, the Ruler Blade drops, H1 opens, the notice cutscene. Permanent. |
| Knight Captain (`knight_captain`) | 18x9 | 10 | P1 one marked leap, 0.9 s, vulnerable 1.2 s. P2 `cp` "may move twice": two leaps, the second marker revealed 0.5 s late (written into the Book mid-fight in grey pencil). P3 `cp` shaking toybox and the train crossing a row; the island gap makes Rule Step the dominant answer (exam). | Knight Errant page flips, Margin +1, hub shelter |
| Bishop Oracle (`bishop_oracle`) | 18x9 | 12 | P1 growing diagonal lanes. P2 `cp` mirrored beams (bend once). P3 `cp` the arena tears into islands; the child draws chalk bridges by script (no Believe); the Oracle calls the crayon line "not real". This is the puzzle-form fight. | Chalk Path, Believe appears (full), Margin +1, banners |
| Rook Warden (`rook_warden`) | 18x9 | 14 | P1 one declared lane, charge, stun on block. P2 `cp` breaks weak blocks, alternates axes (0.4 s turn tell), front armor. P3 `cp` refuses to turn: the throne behind the lane; the player stands so the charge smashes it (3 s stun). This is the endurance-hold fight. | Eraser Guard, hub train |
| Queen of Tricks (`queen_of_tricks`) | 18x9 | 16 | P1 Royal Line and Royal Diagonal, one live lane at a time. P2 `cp` Command Mark summons (2 alive max) and **Seize Toy** (she takes the floor weapon or the alternate Strike from the arena). P3 `cp` Tear the Drawing: Believe disabled for the phase; the promotion offer; a 20 s no-enemy address (abbreviated on retry); then attacks. | The latch lifts, the seal opens, hub gather |
| Black King (`black_king`) | 18x9 | 18 | P1 King's Reach (the 8 cells around him) plus toy-pawn formation. P2 `cp` re-activates every earlier shape from the arena edges, one at a time, and **Reverse Color** once (the safe tile colour inverts for the rest of the fight). The King holds at most one global rule modifier at a time (`active_rule_modifier`). P3 `cp` Close the Box: help blocked, the pawn forward-only, directions restored by walking three memory alcoves (objective-driven, not HP). P4 `cp` a 10 s rehearsal beat, then tiles rewritten so every cardinal approach burns; one open diagonal cell: Free Step and strike. | Free Step owned; Rank label 8; the Ending |

Boss rules:
- **R14**: the final damage always comes from a player attack (payload `source`); the child never deals damage.
- **Seal**: the Black Line seals the entry when the pawn crosses the boundary of the **antechamber**, a 3-column zero-hostile entry strip of the boss room. Entering the room is a checkpoint (D-16).
- **Attacks**: phases hold several weighted attack patterns built from the stage model of §5.10.
- **R22 gating**: help is disabled only if `child_calls_used` is 3 or more, and the disable is always followed by a quiet beat.
- **Retries**: death restarts at the highest checkpointed phase; intro and phase beats shrink to 5 s or less once seen.

### 5.5 Child intervention (Believe)

- **Believe**: max 2 marks (crayon), starts full when Chalk Path is granted, and is saved. The hit progress (1 of 3) is visible as a pip on the marks. Refills (D-41): hub entry, any checkpoint, boss defeat, rescue reunion, +1 per 3 hits landed in the current room, +1 per Perfect Rub (Eraser Guard), scripted refills at boss phase breaks. Never by time.
- **Calls** (all `SkillDefinition` with `source = CHILD`; see §6):
  - **Chalk Path**: bridge up to 3 gap cells ahead for 12 s (6 s in boss arenas, a field on the skill).
  - **Chalk Block**: a block on the free cell ahead that stops Rook charges, straight beams and Knight landings (req#43).
  - Ruler Gate is an extension recipe (§6.10 E2).
- **Free traversal gaps**: a `TraversalGap` marker flags a mandatory crossing. Outside combat (no hostile alive) the cast costs 0 Believe and still shows the hand. `child_calls_used` increments on every successful call (R22).
- **Per-room control** (req#56): room meta has `allowed_calls` (default: all unlocked calls; the Queen and King rooms follow their phase config).
- **Scripted interventions** (no Believe): the `tb3` block, the `bs3` bridge demo, the `bsb` P3 bridges.
- **Selection**: R casts the selected call; Tab / right-stick click cycles. The default pick is Path if a gap is within 3 cells, else Block.
- **Rejection costs nothing**: no gap, a unit on the target cell, or an occupied cell.
- **Help changes the room, never enemy HP, and cannot finish a phase by itself.** The child hand animates slowly, heavier than the pawn.

### 5.6 Pickups

| Pickup | Rule |
|---|---|
| Skill unlock | Persistent. Granted by a `GrantMarker` or boss defeat as a milestone row (`content/progression/milestones/`). |
| Courage Shard (6) | Persistent, crayon-blue glow. Locations: hub tack-switch (a Pencil hit across a one-cell hole), `tbo` (Rule Step gap), `bso` (Chalk Path gap, free cast), `bto` (Guard rubs a Rule Mark), `dh1` (Rule Step over the barricade), `ub1` (Guard rubs a Rule Mark, Believe locked). |
| Annotation (1) | Persistent. Lead Tip (`tbo`) ships as the worked `SkillUpgrade` example (§6.10 E4). |
| Keepsake drawing | Persistent, on the critical path: one in the middle room of each district (`tb2`, `bs2`, `bt2`, `dh2`) plus the B1 notice drawing. It appears in the Book's Drawings tab and raises `child_trust`. |
| Rule page | Unlocks the first time its piece is seen in combat. |
| Floor weapon (Ruler Blade) | Room-local. The player CAN pick it up (new in M7b). The Queen can Seize it (P2). |

### 5.7 Locks, shortcuts, seals

- **Lock kinds** (one `Condition[]` per exit or gate): room clear, flag, unlock id, boss defeated, counter >= n. There is no rank condition (D-13).
- **Every locked exit shows why** (`locked_message_key`). Locks are visible before they open.
- **Gates** open from the far side and stay open (existing).
- **Shortcuts**: every district ends with a one-way shortcut home to H1, and its first crossing is also the forced first use of the new verb (10 s or less, zero risk).
- **Hub locks**:
  - Toybox: open after B1.
  - Bookshelf: needs Rule Step (a page-pile gap).
  - Block Tower: needs Chalk Path (a 3-cell page tear, a free `TraversalGap`).
  - Dollhouse: the royal seal is a Rule Mark that needs Eraser Guard (the furniture barricade is a Rule Step shortcut variant).
  - Under-Bed: the fear gate opens when the latch lifts after the Queen.
  - Desk: visible but unreachable until the Ending; in the post-game state it is reachable (§9.1).

### 5.8 Difficulty and assists (neutral names, opt-in, per save)

Standard is the intended challenge. Assist options (Celeste model), all stored in `world.tuning`:
- Telegraph Time 100/125/150 %. The floor of `telegraph_floor_seconds` (0.45 s) still applies.
- Enemy Pace 100/85/70 % while the pawn is stationary.
- Extra Courage +0/+1/+2.
- Input Forgiveness: buffer 0.12 / 0.20 s.
- Hold-or-toggle for Guard, Focus, turn mode and the rescue hold (accessibility, not difficulty).

The offers come from §4.6 (5 deaths or 15 minutes on one boss, plus a persistent Pause entry). Silent adjustment is forbidden (R12). Chen's flow model says players have different flow zones.

### 5.9 Fairness contract

1. Every damaging cell is highlighted at least telegraph_min before impact (R6).
2. There is no off-screen damage and no unreadable stack of shapes (R28).
3. The death frame names the cause (R8).
4. Retry is fast (R9), and cheaper inside a boss after a phase checkpoint (D-43).
5. Red means danger only (R7).
6. Forgiveness never tightens under stress (R11).
7. Ambushes come only after the family has been previewed (R27).

### 5.10 Attack stages (the framework every enemy family uses)

The draft's attack resolver locked a static cell list at telegraph start and compared it with the hero's cell at one instant (`enemy_ai_system.gd:264`). That cannot express a Rook charge (0.08 s per cell), a growing Bishop lane, a Knight leap with airborne occupancy, a Queen union of lanes or the King's tile rewrites. M8a therefore lands one model before any new family:

- `AttackBase` (Resource): `id`, `tags[line|diagonal|leap|...]`, `damage`, `telegraph_time`, `pattern: CellPattern`. `AttackProfile`, `AttackPattern` and `EnemyWeapon` extend it, so R6 and the tag lints run over one class (D-28).
- `AttackStage` list per attack: **declare** (optional tell), **telegraph** (cells locked), **active** (a sequence of cell sets over time, for example one cell per 0.08 s), **recover**. The currently dead `STATE_COMMIT` (`ecs_components.gd:100`, `enemy_ai_system.gd:31`) becomes the active stage.
- Events carry shape and progress: `telegraph_started{entity, family, shape, cells, duration}`, `attack_progress{entity, stage, progress, cells}`, `attack_resolved{...}`. Presentation draws the language of §10 from these fields.
- `world.tuning` (telegraph scale, pace scale, buffer window, extra Courage) is read by the systems, including weapon telegraphs, which ignore `DifficultyProfile` today (`_telegraph_time`, `enemy_ai_system.gd:314`).
- Recruit, Armed and Knight are ported first, with the existing tests as parity. `EnemyAISystem` has one owner across M8a-M13, because every family touches it.
- A response-cell check (`test_response_cells`, Tier B) asserts that for every authored room and telegraph a reachable safe cell exists within two steps (req#89).

### 5.11 Grid semantics (landed once, in M3a)

- `EcsGrid.cell_kind_by_cell`: `Dictionary[Vector2i -> StringName]`, kinds `floor` (default), `wall`, `gap`, `leapable_block`, `chalk`, `corruption`. `blocked_cells` is derived from it. A `kind` custom-data layer joins the existing `solid` layer on the TileSets and is written by the paint tool (`CLAUDE.md` forbids hand-editing `tile_map_data`).
- `begin_leap(entity, from, to)`: the origin is released at takeoff and the destination reserved. Today the origin stays occupied until `finish_move` (`ecs_grid.gd:106-113`).
- `ray_cells(origin, direction, max_cells, stop_kinds)`: a ray helper that stops at blockers. Rook charges, Bishop lanes and Queen lines use it.
- `layout_version`: increments when blocked cells change. The `AStarGrid2D` is cached per version instead of rebuilt per call (`ecs_grid.gd:167-187`), and the attack-setup search is bounded to a radius (`enemy_ai_system.gd:199`). `tests/perf/test_room_tick_budget.gd` runs an 18x9 board with 8 enemies and asserts a mean tick of 2 ms or less `[start value]`.
## 6. Progression and skills

### 6.1 The spine: "The Long March", and why

Four layers, no grind:

1. **RANK 2 to 8** (a story label, not a stat). White pawns start on rank 2 and promote on rank 8. Six bosses are six steps: Captain -> 3, Knight -> 4, Bishop -> 5, Rook -> 6, Queen -> 7, Black King -> 8 (the Last Rank). The label is computed in the `HudSnapshot` from defeated-boss flags. **Nothing reads it**: no lock, no Margin and no condition uses Rank (D-13). The HUD draws it as the child's blue tally marks. The word "level" is never used in the UI.
2. **VERBS** (the mandatory path). Six verbs, each a chess rule borrowed, plus Chalk Block as the shipped example of a new effect kind. They are earned at fixed story markers (§6.3).
3. **RULES** (the build layer). Five Book Pages are equippable under a Margin budget that comes from explicit `margin_gain` rows (§6.4).
4. **THE CHILD** (the relationship axis): Believe (§5.5).

**Power stays flat** (Courage 3, damage 1; Courage Shards are optional). What grows is the option space. Difficulty comes from threat shapes and telegraph timing, which are data.

**Why this and not an RPG tree.** XP and levels were cut by the owner (`soul:96-97`). A 130-minute game has no room for a tree, and stat grinding is forbidden by `gp7:33-37` and `gdd:554`. The models I took pieces from:

| Model | What we take | Source |
|---|---|---|
| Ability-gated world (Metroid, Hollow Knight) | Hub locks are ability locks; a new verb recontextualises old rooms | Dreamnoid |
| Zelda item-dungeon | Suffer the problem first, then wield the tool; the boss asks what the dungeon taught | Zelda dungeons |
| Mega Man / Kirby borrowed powers | The pawn borrows a rule from the piece it beats but stays a pawn | story research |
| Charms / shards loadouts | Pages under a Margin budget: exclusive choices without a tree | Hollow Knight, Ori |
| Knowledge as progression (Tunic, Outer Wilds) | The Book is the lore and the loadout screen | story research |
| Few verbs, deep mastery (Celeste, Sekiro) | Hard cap on button-bound verbs; forgiveness windows | Celeste |
| Intent-visible grids (Into the Breach) | Skills answer telegraph shapes | Into the Breach |
| Chess vocabulary | Promotion, en passant, castling, check as skill ideas (the extras are recipes, §6.10) | Wikipedia chess articles |

### 6.2 One generic skill pipeline (data on top of one system)

```
SkillDefinition  (schema/skills/skill_definition.gd)       file: content/skills/<id>/skill.tres
  id (= folder = unlock id)  name_key  desc_key  hint_key  desc_params{}  icon.png
  slot:    STRIKE | GUARD | CALL | MOVE_MOD | SLOT      slot_index: 1..4 (used by SLOT)
  source:  OWN | CHILD                       granted_by_page: StringName ("" = none)
  attack:  AttackBase   (CellPattern offsets in the facing frame: forward, right; pierce; tags[line|diagonal|leap])
  timing:  SkillTiming  (wind_up, impact_delay, recovery, move_lock_seconds, cooldown, hold_max, lockout)
  cost:    believe_cost                       boss_arena_duration (Chalk Path)   blocks_tags (Eraser Guard)
  trigger: PRESS | HOLD | WINDOW_AFTER_EVENT (+ event, window_seconds)
  effects: Array[SkillEffect]   shipped kinds: strike_cells, leap_self, step_self, status_self, paint_cells, raise_block
  view:    anim_state (falls back to &"attack"), sfx_event (a sound_bank id), vfx_id
  upgrades: Array[SkillUpgrade]  (Annotations: parameter overrides)
```

- **Slot table** (`content/progression/slots.tres`): one row per slot, `slot id -> InputMap action, HUD position`. The shipped rows: STRIKE -> `attack`, GUARD -> `guard`, CALL -> `child_help`, MOVE_MOD -> `free_step`, SLOT 1 -> `skill_slot_1`, SLOT 2 -> `skill_slot_2`, SLOT 3 and 4 -> `skill_slot_3`, `skill_slot_4` (declared, unused, hidden by the HUD). A new button is one `InputMap` action and one row. This fixes the draft's claim that an eighth verb needed an enum edit and a HUD layout change.
- **Components** (own files in `ecs/components/`): `SkillBook` (unlocked ids, per-skill `cooldown_left`, applied upgrades), `SkillCast`, `Status` (guard_left, untargetable_left, in_check_left, stagger_left, help_disrupted_left), `Believe`, `Loadout` (equipped pages, margin, `active_modifiers`), `DirectionLock`.
- **Systems**: `SkillSystem` hosts all new verbs from M7a. `CombatSystem` and `PlayerCombat` keep driving Sword and Pencil until the parity cutover in M7b; the old `ecs_combat_test` keeps passing untouched until then. `StatusSystem` and `ProgressionSystem` are new. `HealthSystem` is the single damage choke point where `Status` is checked.
- **View**: `ViewSyncSystem` fires `travel(skill.anim_state)` on the `skill_cast_started` edge generically. Today it hard-codes one attack state (`view_sync_system.gd:126-130`).
- **Authoring cost (honest)**:
  - New skill in an existing slot from existing effect kinds = `skill.tres`, `icon.png`, one milestone row, three `.po` rows (name, description, hint), plus a `sound_bank` row if the sound is new: 3-5 files, no code.
  - New button = one `InputMap` action plus one `slots.tres` row.
  - New effect kind = one effect schema file, one handler file and one line in `ecs/schedule/act.gd`, then the `skill.tres`: code.
  - Retune = edit `skill.tres`. Tests use fixture definitions under `tests/fixtures/` or read the loaded `.tres`, so retuning never turns a test red (the current `ecs_combat_test.gd:73-86` hard-codes tick counts; M7b removes that).
  - `test_add_skill_by_data_only` proves the first case and asserts that the HUD slot, `anim_state`, `sfx_event` and the three text keys resolve.
- **Kept names**: the serialized `wooden_sword` and `pencil_thrust` exports on the player's `CombatComponent` are migrated, not silently renamed (the rename rule in `CLAUDE.md`). The `skill_1` input action becomes `skill_slot_1` via `tools/move_res.py --rename-action`, after a grep for string access (62 `get()/set()` sites today).

**Skill principles** (they gate every verb):
- **P1**: a skill must change a decision, not a number (Sid Meier). Each verb names one situation where NOT using it is correct and one only it solves.
- **P2**: one verb answers one chess threat shape.
- **P3**: every limiter is a readable rule, not a hidden number.
- **P4**: two economies: cooldowns for the pawn's own rules, Believe for the child's calls.
- **P5**: suffer first, then wield (Rule Step is the one item-first exception, D-12/§6.3).
- **P6**: every verb has a traversal use and a combat use and opens a loop.
- **P7**: forgiveness windows are part of the spec (a missed guard degrades to a safe block).

### 6.3 The six verbs

Timings are `[start value]` except Sword and Pencil, which are [measured] (`attack_profile.gd` defaults; `resources/attacks/pencil_thrust.tres`).

**1. Wooden Sword (Capture)**
- *Slot and input*: STRIKE, Space/K, pad A.
- *Rule*: 1 cell ahead, damage 1, impact 0.07 s, recovery 0.30 s, no cooldown, no cost. It cannot start while stepping or casting. A press during recovery is swallowed, not banked. Targets are locked at swing start.
- *Chess meaning*: the pawn's one legal capture, shrunk to the cell in front.
- *Decision created*: when to commit. The 0.30 s recovery is the price of every swing; every other verb must do something the Sword cannot.
- *Unlock*: T2 `GrantMarker` at about minute 2.75.
- *Story*: agency after loss.
- *Teach -> test -> twist -> master*: T1 shows the problem (the dead King and the path), T2 get-and-use (the crayon target, one forced Shift-turn), T3 makes it necessary, B1 is the exam.
- *Upgrades*: none. The **Ruler Blade** (front plus both forward diagonals, impact 0.12 s, recovery 0.45 s) is the B1 drop (the existing `RulerBladePickup` in `b1`) and is swapped in the Book whenever no hostile is alive: duel versus crowd. It gives an early choice at H1.
- *Data*: `content/skills/wooden_sword/skill.tres`.

**2. Pencil Thrust (First Move)**
- *Slot and input*: SLOT 1, Q, pad X.
- *Rule*: the two cells ahead, pierces both, damage 1, impact 0.11 s, recovery 0.52 s [measured], cooldown 1.25 s [measured per `combat_component.gd:12`]. It shares the attack lock with the Sword. Straight line only.
- *Chess meaning*: the pawn's two-square first move, turned into an attack.
- *Decision created*: spacing. Two cells away in a line is a cell no unarmed pawn, knight or bishop threatens. A miss costs 0.52 s and Armed Pawns contest the same lane.
- *Unlock*: T4, a `GrantMarker` on the exit path just past the Armed Pawn, about minute 11.5. Walking to the exit collects it (guaranteed on the path, D-11); no room ever requires it.
- *Story*: defiance, taking a toy back from the cheaters.
- *Teach -> test -> twist -> master*: T4 the Armed Pawn pokes you at range 2, then you find the stub in a cover alcove; `tb2` makes the straight lane a safe lane; the hub tack-switch shard needs a Pencil hit across a one-cell hole.
- *Upgrades*: Annotation **Lead Tip** (`tbo`: the first target hit is shoved 1 cell if free) is the shipped `SkillUpgrade` worked example (a `ParamOverride` of `knockback_cells`). Page Armed Pawn (Margin 1): Q may be pressed in the last 0.20 s of Sword recovery.
- *Data*: `content/skills/pencil_thrust/skill.tres`.

**3. Rule Step (the Knight's Leap)**
- *Slot and input*: SLOT 2, F, pad B.
- *Rule*: ghost marks show the two forward L cells (2 ahead, 1 left/right). Tap left or right within 0.15 s to choose, else the free one (right if both are free). Takeoff 0.08 s; flight 0.22 s during which the pawn is untargetable; recovery 0.25 s; cooldown 4.0 s from the cast. The landing cell is reserved at takeoff with `begin_leap` (§5.11). It passes over entities, one-cell gaps and `leapable_block` cells. It cannot cross walls, gates or exits. If the landing cell is inside a currently locked telegraph, the ghost turns red and the pawn is hit on touchdown. This is an L-leap, not the two-cell step of `v2:320-326` (D-37).
- *Chess meaning*: the Knight, the only piece that jumps.
- *Decision created*: when to leave and where to land. A committed attack can be dodged by relocating over the obstacles that made stepping impossible. With a 4 s cooldown there is one escape per exchange: spend it early to claim a Knight's landing cell, or save it.
- *Unlock (item-first, the one exception to "after the boss")*: the `tb3` alcove, about minute 33. `tb1` and `tb2` are the suffering (Knight leaps against you). `tb3` uses it with a low-pressure train, `tb4` forces the first use (a lid-path gap), and `tbb` is the exam. Giving it before the boss means the Knight Captain's "You cannot catch what leaps" lands on a pawn that can. Both emotion and progression reviews asked for this; it is a one-node switch back to "after the boss".
- *Story*: freedom beats tradition. The Book's Knight page flips to "may move twice" and becomes the Knight Errant Page.
- *Teach -> test -> twist -> master*: `tb1`/`tb2` Knight leaps against you; `tb3` get; `tb4` forced first use; **exam** `bs2` (an island gap in the exit) and `tbb` P3; the Bookshelf hub lock; the Dollhouse barricade and the `ub2` gauntlet.
- *Upgrades*: Page Knight Errant (Margin 2): a second Rule Step within 1.0 s, then the full cooldown.
- *Data*: `content/skills/rule_step/skill.tres` (effects: `leap_self`).

### 6.3 The six verbs (continued)

**4. Chalk Path and Chalk Block (the child's call)**
- *Slot and input*: CALL, R, pad RB. Source: child. `allowed_calls` in the room meta can restrict it (req#56).
- *Rule (Path)*: costs 1 Believe, except at a `TraversalGap` with no hostile alive, where it costs 0 (D-41). A 0.60 s hand wind-up shows as a shadow over the target cells (enemies or the Queen can disrupt it, `Status.help_disrupted_left`); the pawn may move meanwhile. Up to 3 consecutive gap cells in a straight line, starting at the first gap within 3 cells ahead, become walkable chalk for 12 s (6 s in boss arenas, `boss_arena_duration` on the skill). Enemies can walk on it too. It is rejected with no Believe spent if no gap is within 3 cells or a unit stands on a target cell.
- *Rule (Block, the shipped worked example of a new effect kind `raise_block`)*: the same call on a free floor cell directly ahead raises a Block that stops Rook charges, straight beams and Knight landings (req#43) until destroyed or the room ends. Cost 1 Believe; max one alive (a new cast moves it); never under a unit.
- *Chess meaning*: the child bends the board; a cell that does not exist becomes legal.
- *Decision created*: spend or save. Believe only comes from courageous play, so help is paid for in courage. With Chalk Block the choice becomes bridge or cover.
- *Unlock*: Path when `bsb` is defeated (about minute 61), with Believe full (2). Block at the Midpoint (about minute 86). **Four forced free uses** keep the child's help earned and the R22 counter honest: the `bs4` shortcut (a 3-cell page tear), the H1 Block Tower door, the `bt2` entry gap and the `dh1` foyer gap.
- *Story*: trust. The Midpoint confession.
- *Teach -> test -> twist -> master*: `bs3` demo by script; `bs4` forced use; **exam** `bt3` (a Rook line fires across a gap: the chalk crossing is dominant) and `btb` P2 (Block as cover); Midpoint combined rooms; the Queen locks Believe for a whole phase.
- *Upgrades*: none shipped. The Bishop-of-Order and Castling Pages are recipes (§6.10).
- *Data*: `content/skills/chalk_path/`, `chalk_block/`.

**5. Eraser Guard (Hold the Line)**
- *Slot and input*: GUARD, hold G (or toggle in Settings), pad LT.
- *Rule*: raise 0.10 s. While held the pawn is planted; Shift plus direction turns but re-raises 0.10 s. It negates damage from attacks whose tags are in the skill's `blocks_tags` (`line`: Rook charge, pencil pokes, straight beams) that arrive through the faced side. The tag list is a field in `skill.tres`, not a literal in `HealthSystem`. Attacks tagged `diagonal` or `leap` ignore it. **Perfect Rub**: a line attack landing within the first 0.25 s after the guard is active puts the attacker In Check (cannot telegraph or attack for 0.8 s, pushed back 1 cell if free) and gives +1 Believe. An early guard is a normal safe block, a late guard is no guard. Max hold 1.5 s, then an 0.8 s lockout. Holding on a Rule Mark erases it for 6 s.
- *Chess meaning*: the Rook owns straight lines and shields the King in castling; check forces the attacker to answer.
- *Decision created*: read the SHAPE of the telegraph and answer with the matching verb. Lines: plant and hold. Diagonals and L-shapes: leave. The best defence is the latest safe one, and defence feeds offence without replacing movement.
- *Unlock*: `btb` defeated, about minute 82. Antepiece: a fenced (telegraph-only) Wooden Rook in `bt1`. Forced use: the `bt4` shortcut needs a Rule Mark rubbed out (free, zero risk). Item-first placement is a one-node switch if playtests show the Rook fight demands it.
- *Story*: standing still can be brave.
- *Teach -> test -> twist -> master*: `bt1` preview; `bt4` forced use; **exam** `dh3` (Rook lines plus the Queen's lane preview) and the Queen's Royal Line; `dh2` diagonals ignore the guard; the Dollhouse royal seal and the `ub` lanes.
- *Upgrades*: none shipped (Rub Out and the Black Queen Page are recipes, §6.10).
- *Data*: `content/skills/eraser_guard/skill.tres`.

**6. Free Step (the Final Rule Break)**
- *Slot and input*: MOVE_MOD. Primary: hold the `free_step` modifier (Left Alt) and press a direction pair. Alternative: two perpendicular direction keys within `chord_window` (default 0.07 s, `FeelProfile`, floor 0.05 s), or an 8-way stick push inside a 20-degree cone of a diagonal. The chord hold-off applies only while Free Step is owned and a diagonal destination is legal, so ordinary steps never gain latency (D-42). Tested through `InputSnapshot`.
- *Rule*: one diagonal cell, 0.18 s, same reserve-then-commit protocol; it may squeeze between two blockers that touch at a corner; facing becomes the axis of the later key.
- *Staging*:
  1. **Foreshadow (R34)**. From T1 the first chord press (two perpendicular keys down together) plays a head-shake denial once and writes a Book margin note in the Book's printed ink: "A pawn captures diagonally. It never steps." At `dhb` the seal bears a diagonal mark; the pawn tries a chord; the denial plays again. The seal then opens when the child's hand lifts a latch (D-14). The pawn never moves diagonally here.
  2. **Act 6 loss**. At the Under-Bed entry the lid closes (the child is cut off, Believe locked). In `ubb` P3 the Rule Engine strips the pawn to forward steps only; the player walks three memory alcoves, each restoring one direction (Left, Right, Back) and used at once to dodge a telegraph. A piece that was not rescued leaves a blue crayon outline in its alcove ("drawn before you"), which restores the direction without the child acting now, so nobody soft-locks and D-19 stays intact.
  3. **Rehearsal (R34)**. P4 begins with a 10 s zero-damage beat: the `PromptWidget` shows "Hold {free_step} and two directions" and one practice diagonal cell is outlined in crayon. The burning tiles begin after the first Free Step or after 10 s, whichever comes first. A mistimed chord costs nothing.
  4. **The peak**. The King's rewritten tiles cover every cardinal approach. The one open cell is diagonal: Free Step into it plus a Sword strike is the finishing blow. The first diagonal the player ever makes is this one.
  5. Afterwards Free Step is permanent.
- *Chess meaning*: a pawn captures diagonally but never moves diagonally. Promotion would turn it into another piece; this keeps it a pawn.
- *Decision created*: the only new movement decision that is not a cooldown. It arrives only when help is gone: how to use complete freedom.
- *Unlock*: owned at `ubb` P4, about minute 126.
- *Story*: the courage to disobey now belongs to the pawn.
- *Upgrades*: none. After the finale it reopens diagonal gaps for optional exploration.
- *Data*: `content/skills/free_step/skill.tres` (`step_self` effect), `FeelProfile.chord_window`.

### 6.4 Rule Pages and Margin (the build layer)

- **Margin** is the sum of `margin_gain` rows on milestones, not a function of Rank: +2 at B1, +1 at the Knight Captain, +1 at the Bishop Oracle, then fixed at 4 (O-6 flattens it).
- **Equip rules**: pages equip from the Book whenever no hostile is alive in the current room and no beat is running (D-40). Equipping is a typed `equip_page_requested` command (D-38). A page unlocks when its piece is first seen in combat and is equippable from then on (Knight Errant also needs Rule Step).
- **A page is data**: `content/rules/<id>/page.tres` = the existing `RuleEntry` fields plus `kind` (PAGE or LORE), `margin_cost`, `ink`, `modifiers[]` and a required `when_not_to_wear` line (validated, so no page is an always-on pick). A page changes a rule, never a stat.

| Page (id) | Cost | Typed modifier | Seen in | Ships in |
|---|---|---|---|---|
| The First Law (`first_law`) | 0 | none (lore) | T2 | M7c (exists) |
| Armed Pawn (`armed_pawn`) | 1 | `ChainWindow(wooden_sword -> pencil_thrust, 0.20 s)` | t4 | M7c |
| Backstep Pawn (`backstep_pawn`) | 1 | `MoveRule(cancel_sword_recovery_on_backstep)` | t4, bs1 | M7c |
| Charging Pawn (`charging_pawn`) | 1 | `MoveRule(double_step_after_stillness, 1.0 s)` | tb2, bs3 | M9 |
| Knight Errant (`knight_errant`) | 2 | `ChainWindow(rule_step -> rule_step, 1.0 s)` | tb2, tb3 | M9 |

At Margin 3 (after the Knight Captain) three of the four priced pages compete for the budget, and the total cost (5) exceeds the cap (4), so a real choice never disappears. `when_not_to_wear` examples: Backstep Pawn, "when you plan to trade blows: the cancel steps you out of range of your own strike"; Charging Pawn, "in tight rooms: a double step can end beside a telegraph".

**PageModifier is a typed Resource family** (`schema/progression/modifiers/`), not a free-form array: `ParamOverride(skill_id, field, op, value)`, `TagFilter(skill_id, add/remove tags)`, `ConditionalStat(when, field, value)`, `GrantSkill(skill_id)`, `ChainWindow(skill_a, skill_b, seconds)`, `MoveRule(kind, params)`. Systems read only `Loadout.active_modifiers`. The base ships handlers for `ParamOverride` (used by Lead Tip), `ChainWindow` and `MoveRule`; the other three kinds exist as schema with a documented handler skeleton (§6.10). A grep test (`test_page_modifiers_data_only`) asserts that no system contains a page id literal, so the owner can add a page whose modifier kind already has a handler with two files and no code. A page that needs a new modifier kind is schema plus handler plus one schedule line, which is code.

**Lore entries** (`kind = LORE`, cost 0, no modifiers) exist for every piece and boss (§4.7). `test_pages_reachable` asserts that every `page.piece_id` appears in a room on the route before the page is needed.

### 6.5 Every other growth axis

| Axis | Rule | How earned |
|---|---|---|
| Courage (health) | 3 base, up to 5 | 3 Courage Shards = +1 (6 shards exist). Optional, verb-gated. |
| Believe | Max 2, fixed | Hits landed (1 of 3), Perfect Rub, rescues, boss phase breaks, hub entry and checkpoints (D-41). Never by time. |
| Rank label and Margin | Rank 2-8 (label); Margin 2-4 | Boss defeats only; Margin from `margin_gain` rows. |
| Pages | 5 priced pages, exclusive choice under Margin | See §6.4. |
| Annotations | 1 shipped (Lead Tip) | The optional room `tbo`. The others are recipes. |
| Rescued pieces | 3 | Each: a Believe refill at reunion, a direction restored in the finale, ending variation (SDT relatedness). Pebble also becomes a hub resident. |
| Hub evolution | 5 visible states plus a `boxed` regress | Shelter after the Knight, banners after the Bishop, train after the Rook, gathering after the Queen, boxed at the Under-Bed entry, free building in the Ending (`gdd:303-310`). |
| Child trust | `child_trust` counter driving the presence layer and HUD marks | Story events (§4.5). |
| Deferred extensions | Paper Bridge, Turn the Board, Erase Rule Mark, Ruler Gate, In Passing, Castling, Vow pages | §6.10. |
### 6.6 The teaching table (ki-sho-ten-ketsu per verb, with a Verb Exam)

Each cycle follows Nintendo's introduce, develop, twist, resolve. Unlock default: AFTER the boss, so the boss tests prediction with the tools already owned and the new verb is needed in the NEXT place. Rule Step is the one item-first exception (§6.3). The **Exam** column names the one room or boss phase where the verb is required or clearly dominant in combat (the documented requirement `gp4:33-37` is "a combat test" per skill); `test_verb_exam` asserts that every shipped verb has one.

| Verb | Suffer | Get and force | Twist | Exam | Master |
|---|---|---|---|---|---|
| Sword | T1 shows the problem | T2 sword + target | T3 first clash | B1 | B1 |
| Pencil | T4 Armed Pawn pokes | stub on the T4 exit path | `tb2` straight safe lane | `tb2`, H1 shard tack-switch | hub shard |
| Rule Step | `tb1`/`tb2` leaps against you | `tb3` alcove, then the `tb4` lid-path gap (10 s or less, zero risk) | Bookshelf island gaps | `bs2` island exit, `tbb` P3 | `ub2`, Dollhouse barricade |
| Chalk Path | `bs3` scripted demo | `bs4` 3-cell page tear (free) | the H1 Block Tower door, `bt2` entry gap (free) | `bt3` gap under line fire (dominant), `bsb` P3 (scripted) | the Queen locks Believe for a whole phase |
| Chalk Block (optional) | `bt2` Rook charges | Midpoint unlock | `btb` P2 cover | `btb` P2 | `dh3` cover |
| Eraser Guard | `bt1` fenced Rook | `bt4` Rule Mark (free) | `dh2` diagonals ignore the guard | `dh3` and the Queen's Royal Line | `ub2`/`ub3` |
| Free Step | T1 and `dhb` chord denials | `ubb` P4 rehearsal | `ubb` P4 tiles | the final strike | the final strike |

Meta-systems have teaching prompts too (§8.5 prompt table): equipping Pages and Margin (first time the Book opens with a priced page), Believe hit progress (the pip on the marks), and the rescue hold. Each is one R5-compliant prompt.

### 6.7 Power curve against the difficulty curve

Perceived difficulty = (skill challenge + power challenge) - (player skill + player power) (Schreiber). Power is flat, so the sawtooth is controlled with shapes, timings and the option space. Each district: difficulty jumps on entry, plateaus, spikes at the boss, then a trough room with the new verb's safe first use and a small power jump (verb, Page, Margin +1). Minutes are boss-defeat marks on the critical path with 1 minute of H1 pass-through per district `[start value]`; M5 and M9 replace them with route-bot measurements (D-03).

| Point | Cum. min | Rank label | Courage max | Verbs owned | Margin | Shapes normal/boss | Boss median attempts | Challenge shape |
|---|---|---|---|---|---|---|---|---|
| After T2 | 5 | 2 | 3 | Sword | 0 | 0/- | - | none |
| After T4 | 12 | 2 | 3 | +Pencil | 0 | 2/- | - | spacing |
| After B1 | 18 | 3 | 3 | +Ruler Blade (alternate Strike) | 2 | 2/2 | 2 | read and dodge |
| After tb3 | 33 | 3 | 3 | +Rule Step | 2 | 2/- | - | L-leap suffered, then owned |
| After KB | 39 | 4 | 3-4 | | 3 | 2/3 | 3 | L-leap exam |
| After BSB | 61 | 5 | 3-4 | +Chalk Path | 4 | 2/3 | 3 | lanes and terrain |
| After BTB | 82 | 6 | 3-4 | +Eraser Guard, +Chalk Block | 4 | 2/3 | 3-4 | lines and hold |
| After DHB | 104 | 7 | 4 | (the latch lifts) | 4 | 3/4 | 4 | mixed + loss of help |
| After UBB | 128 | 8 | 5 | +Free Step | 4 | 4/4 | 5-6 | everything + freedom |

Bosses are tuned for the mandatory-only kit plus 3 Courage; the Courage-max column only counts optional shards. HP is capped at 18 (§5.4) so the late curve is phases and objectives, not hit-point inflation.

Micro-rewards (R37) keep the long gap between Pencil (12) and Rule Step (33) from feeling empty: B1's Ruler Blade and keepsake drawing, Pebble and the H1 hub gift, the Charging Pawn page and the `tb2` keepsake drawing. The `Reward` column of §7.4 is the lint fixture: at least one persistent reward per 6 minutes of critical path.

Assist offer: after 5 deaths or 15 minutes on one boss, once; always reachable from the Pause menu (D-22).

### 6.8 Soft-lock policy

- **Mandatory** verbs (gate the critical path): Sword, Rule Step, Chalk Path (only through free `TraversalGap` crossings), Eraser Guard (only through free Rule Mark rubs), Free Step.
- **Optional**: Pencil, Chalk Block, all Pages.
- Rooms may require only mandatory verbs already owned. A test walks the graph with only mandatory unlocks and asserts the Ending is reachable.
- **Resource-state walk (R33)**: the same walk runs with Believe 0, Courage 1, all cooldowns running, and a chalk crossing expiring mid-gap, and still reaches the Ending. This is the test that would have caught the draft's Block Tower door.
- Directions lost in Act 6 are always returned by the three alcoves; an un-rescued piece leaves a crayon outline.

### 6.9 How this respects the 2026-07-28 cut

No XP, levels, currency, shops, bonfires, Rest Squares or corpse run exist. Death keeps the zone reload. Rank is a label that nothing reads. Margin is an explicit table, so nothing is grindable (O-6 lets the owner flatten it). The only numeric growth is optional Courage Shards. `gdd:112-115` and `gdd:326-364` (Place Block, Draw Path, Turn the Board, Gentle Nudge as boss rewards) are replaced with the gp4/v2 verb chain. The child still places a block for the pawn once, by script, in Toybox (`gdd:330`).

The plan keeps **one** departure from the cut, listed for the owner in §2.3: cleared rooms stay cleared (T-5, D-17), which reverses `soul` rule 3 (`soul:76`). The earlier claim that "no bonfires exist" was only true after the draft's Rest Squares and checkpoints were removed or renamed; they are now just checkpoints that refill Courage and Believe on a hub or boss-room entry (D-16, D-40).

### 6.10 Extension recipes (not in the base, each a few files)

These are the items the reviews and the owner's "everything" brief asked for that did not fit the verifiable budget. Each lists the files and whether it needs code. The base ships the schema and a worked example (Chalk Block as a new effect kind, Lead Tip as a `SkillUpgrade`) so each recipe is a copy of a pattern that already works.

| Recipe | Files | Code? |
|---|---|---|
| **E1 In Passing** (+ Passant Wraith + page): Strike inside a 0.45 s window after an enemy completes a move of 2 or more cells beside the pawn drags it back to the crossed cell, stagger 0.8 s that cancels its telegraph. Knight leaps never open it. | `content/skills/in_passing/skill.tres` (trigger `WINDOW_AFTER_EVENT`, event `enemy_moved_multi_cell`), `content/enemies/passant_wraith/enemy.tres` + `body.png`, `content/rules/passant_wraith/page.tres` (`GrantSkill`), a `PassantWindow` component, a `drag_target` effect + handler, and `from_cell` + `cells_crossed` on the move event. The Wraith must dash 2 cells so a window exists; Charging Pawns also open it. | Yes |
| **E2 Ruler Gate** (hold a shortcut open at an anchor cell) | `skill.tres`, an `anchor_call` effect + handler, an `InterventionAnchor` marker, room placement | Yes |
| **E3 Pages that need new handlers**: Castling (swap with your Block), Promoted Zealot (`ConditionalStat`: at 1 Courage invulnerability extends to 1.2 s), Black Queen (`TagFilter`: Perfect Rub also rubs out diagonal hits). Bishop of Order (`ParamOverride`: chalk lasts 18 s) needs no code. | `page.tres`, handler for the modifier kind, `swap_with_marker` effect for Castling | Yes, except Bishop of Order |
| **E4 More Annotations**: Full Knight (all 8 L cells, a pattern override), Rub Out (Perfect Rub also clears one lane telegraph). Lead Tip ships. | `SkillUpgrade` rows on `skill.tres`, `.po` rows; Rub Out needs a handler | Full Knight no, Rub Out yes |
| **E5 Paper Bridge, Erase Rule Mark call, Turn the Board, Vow pages** | `skill.tres` each; Turn the Board needs a `rotate_section` effect; Vow pages need negative `margin_cost` allowed in `validate()` | Turn the Board and Vow pages yes |
| **E6 Rest Square** (only if the owner reverses D-40) | a marker, a `RestState` component, a refill in `CheckpointSystem`; then rewrite §1.2 and §6.9 | Yes |
| **E7 Enemy variants**: Veteran and Desperate pawns, Promoted Zealot elite, Marble Launcher, Wind-Up Hammer, Mirror and Torn Bishop | `content/enemies/<id>/enemy.tres` + `body.png` and a room placement when the attack data fits `AttackBase`; weapons need an `EnemyWeapon` `.tres` | No, unless a new attack kind is needed |
## 7. World and content list

### 7.1 World model, scale and map slots

- **Play spaces**: 16x9 rooms (512x288 px) on a world graph. Boss arenas and `ub2` are at most 18x9 (576x288 px). Each room sets a centred `grid_origin` in `EcsBoot` (x 64 for 16 wide, x 32 for 18 wide, y 36) and `CameraRig` clamps to it. The HUD safe zone keeps the top 32 px and bottom 34 px free (§10), so no danger row is ever covered. A test asserts that no HUD control rectangle intersects the board rectangle.
- **Scale**: the bedroom is 128x96 cells at 1.5 in per cell = 16 x 12 ft. A room slot is 16x9 cells = 24 x 13.5 in. The map grid is **8 columns x 10 rows of slots**. `map_slot` for each room lives in `world.tres` only (one home).
- **World map screen**: deferred (req#121, §1.2). The backdrop (placeholder from `tools/generate_demo_map.gd`, redrawn by the owner) and the slot data ship. `tools/print_world_map.gd` prints an ASCII map for QA.
- **Fixtures, not content**: `tests/fixtures/the_kingdom.tscn` (72x40, 17 enemies, 2 gates, leash) and `tests/fixtures/first_encounter.tscn` (pickups, Knight and Armed spawn) keep their coverage and are excluded from `ContentDb` and from room lints. M5 ports the world-graph assertions in `tests/run_tests.gd:196-222` to the new `world.tres` instead of dropping them.
- **Monotony guard** (D-02): every district has a loop or shortcut (`test_district_loops`), no two consecutive critical-path rooms share a `layout_archetype` (`test_layout_archetypes`), and each district has one format-breaker room with a different objective kind.

District regions on the slot grid (the owner may rearrange in `world.tres`):

| Region | Slots (col, row) |
|---|---|
| Chess Rug (Act 1 and H1) | cols 2-5, rows 4-6 |
| Toybox | cols 6-7, rows 3-7 |
| Bookshelf | cols 2-5, rows 0-2 |
| Block Tower | cols 0-1, rows 2-6 |
| Dollhouse | cols 5-7, rows 8-9 |
| Under-Bed | cols 1-4, rows 7-9 |
| Desk (Ending) | cols 6-7, rows 0-1 |
| Window | cols 0-1, rows 0-1 (decorative, awe) |

### 7.2 Route

```
[t1]-[t2]-[t3]-[t4]-[b1] --> [H1 Chess Rug hub] <== one-way shortcut home from every district
                                   |
   +---------------+---------------+---------------+---------------+
 Toybox        Bookshelf      Block Tower      Dollhouse       Under-Bed
 tb1-tb2-tb3   bs1-bs2-bs3    bt1-bt2-bt3      dh1-dh2-dh3     ub1-ub2-ub3
   |  (tbo)        |  (bso)        |  (bto)         |               |
  tbb --> tb4     bsb --> bs4    btb --> bt4      dhb --> dh4     ubb --> e1 --> credits
```

Rescues sit on the route: Pebble in H1, Slant in `bs3`, Stout in `bt2`. The optional rooms `tbo`, `bso`, `bto` hold only a shard (and Lead Tip in `tbo`).

### 7.3 Hub H1 and its states

State is a set of flags; each hub prop is a `StateVariantMarker` (§13.2), so the owner adds a prop that appears after a condition without code.

| State | Trigger | Visible change | Lock effect |
|---|---|---|---|
| 0 | Start | Bare rug; locked doors with reasons; under-bed shadow; Pebble stuck under a block; clue 2 (a second mug) | Toybox opens after B1 |
| 1 | `boss.knight_captain` | The hand places a block shelter while the pawn is away | Bookshelf door needs Rule Step |
| 2 | `boss.bishop_oracle` | Crayon banners, paper bridges | Block Tower door needs Chalk Path (a free `TraversalGap`) |
| 3 | `boss.rook_warden` | Toy train; Midpoint cutscene | Dollhouse seal needs Eraser Guard (a free Rule Mark rub) |
| 4 | `boss.queen_of_tricks` | Pieces gather at the chess box | Under-Bed fear gate opens (the latch lifts) |
| boxed | Under-Bed entered | The gathered pieces, banners and train are put away into the box; the child's hand is absent. S22 opens with a 4 s cut to H1 in this state before the lid closes. | none |
| 5 | Ending (post-game) | Free building; the Desk is reachable | none |

The under-bed silhouette gains detail at each state (R26). The `boxed` state makes the Under-Bed's "put away" literal (Pebble, the Queen), and returning the pieces to their squares in the Ending a real release.

### 7.4 Rooms

`Role` is Rest / Teach / Test / Twist / Boss / Shortcut. `Threat/shapes` is the lint fixture of R4, R18 and R28 (`test_threat_budget`, `test_room_data_audit`, `test_preview_before_lethal` run against this table in M5, before any room is built). `Obj` is the objective kind: `clear` (default), `reach`, `survive`, `waves`, `none`. `Int` is intensity 0-10 (R32). `Min` is the first-play estimate `[start value]` that the route bot replaces (D-03). `Reward` is the persistent reward used by R37 (lore counts as an earned story beat). The `layout_archetype` is the second item in `Size / archetype`.

**Act 1: Prologue and Rug (22 min)**

| Room id | Size / archetype | Role | Enemies (threat / shapes) | Obj | Gate, exam | Reward | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|---|---|---|---|
| `t1_white_kings_fall` | 16x9 winding | Rest | none (0/0); three stations | reach | exit open | clue 1 | S01-S02 | grief / 3 | 2 |
| `t2_fallen_sword_tile` | 16x9 open | Teach | Crayon Target (HP 2, no attack) (0/0) | clear | Wooden Sword | Sword, Book page 1 | S03 | agency / 2 | 3 |
| `t3_first_pawn_clash` | 16x9 split | Test | 1 Recruit (1/1), flagged `intro` | clear | exit locked until clear | Recruit lore | S04 | suspense, fiero / 5 | 3 |
| `t4_broken_rule_yard` | 16x9 yard | Twist | Recruit + Armed + Backstep (5/2), cover tiles | clear | Pencil on the exit path (optional to use) | Pencil, Armed and Backstep pages | S05 | defiance / 6 | 4 |
| `b1_black_pawn_captain` | 16x9 arena | Boss | Captain, 3 phases (P1 budget 6) | clear | Margin +2; Ruler Blade drops | Rank label 3, keepsake drawing | S06, S06b | dread -> fiero / 7 | 6 |
| `h1_chess_rug_hub` | 16x9 hub | Rest | none | none | Pebble rescue (hold E 1.5 s) | Pebble, hub gift | S07 | relief, awe / 2 | 4 |

**Act 2: Toybox (18.5 min critical path)**

| Room id | Size / archetype | Role | Enemies (threat / shapes) | Obj | Gate, exam | Reward | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|---|---|---|---|
| `tb1_toybox_gate` | 16x9 fence | Teach | fenced Knight preview (telegraph-only) + 1 Recruit (1/1) | clear | | Knight lore | S08 | curiosity / 3 | 3 |
| `tb2_l_jump_lanes` | 16x9 lanes | Test | 1 Knight + 1 Charging Pawn (5/2); the straight lane is also the Pencil lane | clear | exam: Pencil | keepsake drawing, Charging and Knight Errant pages | S08 | suspense / 5 | 4 |
| `tb3_toy_track_ambush` | 16x9 track | Twist | 1 Knight + toy train hazard (4/2). **Format-breaker**: a train chase | reach | Rule Step alcove; the first scripted block (silent in the fight) | Rule Step | S09 | surprise / 6 | 4 |
| `tbb_knight_captain` | 18x9 arena | Boss | Knight Captain (P1 budget 7) | clear | exam: Rule Step | Margin +1, Knight Errant page flips | S10 | surprise -> lightness / 8 | 6 |
| `tb4_lid_path` | 16x9 path | Shortcut | none | reach | forced Rule Step first use (one-cell gap) | hub shelter | S11 | flight / 3 | 1.5 |
| `tbo_crayon_cache` | 16x9 nook | optional | none | none | Rule Step gap | shard 2, Lead Tip | - | discovery / 2 | 1.5 |

**Act 3: Bookshelf (21 min critical path)**

| Room id | Size / archetype | Role | Enemies (threat / shapes) | Obj | Gate, exam | Reward | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|---|---|---|---|
| `bs1_book_spine_steps` | 16x9 stairs | Teach | fenced Bishop preview + 1 Recruit + 1 Backstep (3/1 live) | clear | | Bishop lore | S12 | wonder, dread / 4 | 4 |
| `bs2_diagonal_chapel` | 16x9 chapel | Test | 2 Bishops (6/1); clue 3 | clear | exam: Rule Step (the exit lies beyond an island gap) | keepsake drawing | - | tension / 5 | 4 |
| `bs3_torn_page_bridge` | 16x9 bridge | Twist | 1 Bishop across a tear + 1 Charging Pawn (5/2). **Format-breaker**: a page slide, scripted chalk demo | reach | Slant rescue (hold E 1.5 s) | Slant | S13 | trust / 6 | 5.5 |
| `bsb_bishop_oracle` | 18x9 islands | Boss | Bishop Oracle (P1 budget 7); the puzzle-form fight | clear | Chalk Path, Believe appears (full) | Margin +1 | S14 | wonder, trust / 8 | 6 |
| `bs4_page_tear_shortcut` | 16x9 tear | Shortcut | none | reach | forced Chalk Path (free `TraversalGap`, 3-cell tear) | hub banners | S15 | relief / 3 | 1.5 |
| `bso_margin_nook` | 16x9 nook | optional | none | none | Chalk Path gap (free) | shard 3 | - | care / 2 | 1 |
### 7.4 Rooms (continued)

**Act 4: Block Tower (20 min critical path, plus a 2 min Midpoint in H1)**

| Room id | Size / archetype | Role | Enemies (threat / shapes) | Obj | Gate, exam | Reward | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|---|---|---|---|
| `bt1_block_yard` | 16x9 yard | Teach | fenced Wooden Rook preview (telegraph-only) + 2 Recruits (2/1 live); clue 4 | clear | Guard antepiece | Rook lore | S16 | patience / 3 | 3.5 |
| `bt2_ruler_bridge` | 16x9 bridge | Twist | Wooden Rook + 1 Recruit (5/2). **Format-breaker**: hold the line for 30 s | survive | entry gap (free Chalk Path); Stout rescue (hold E 1.5 s) | Stout, keepsake drawing | S16 | trust / 5 | 5 |
| `bt3_breakable_wall_test` | 16x9 wall | Test | Iron Rook + 1 Recruit (5/2) | clear | exam: Chalk Path (a Rook line fires across a gap) | Iron armor margin note | - | resolve / 6 | 4 |
| `btb_rook_warden` | 18x9 arena | Boss | Rook Warden (P1 budget 8); the endurance-hold fight | clear | Eraser Guard | hub train | S17 | resolve / 9 | 6 |
| `bt4_ruler_gate_shortcut` | 16x9 gate | Shortcut | none | reach | forced Eraser Guard (rub a Rule Mark, free); Midpoint cutscene in H1 | Chalk Block | S18 | confession / 4 | 1.5 |
| `bto_rubble_nook` | 16x9 nook | optional | none | none | Eraser Guard rubs a Rule Mark | shard 4 | - | care / 2 | 1.5 |

**Act 5: Dollhouse (18.5 min critical path)**

| Room id | Size / archetype | Role | Enemies (threat / shapes) | Obj | Gate, exam | Reward | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|---|---|---|---|
| `dh1_foyer` | 16x9 foyer | Rest/Teach | none (the Queen's voice offstage); clue 5. **Format-breaker (Tier B)**: a no-combat tea party where the pawn obeys table rules | none | entry gap (free Chalk Path); barricade shard needs Rule Step | Queen voice beat, shard 5 (optional) | S19 | unease / 3 | 3 |
| `dh2_mixed_court` | 16x9 court | Test | Knight + Bishop (6/2) | clear | diagonals and leaps ignore the guard | keepsake drawing | - | tension / 6 | 5 |
| `dh3_royal_stage` | 16x9 stage | Twist | Wooden Rook + 1 Recruit (5/2) + a fenced Queen lane preview | clear | exam: Eraser Guard | Queen lore | - | dread / 5 | 3 |
| `dhb_queen_of_tricks` | 18x9 arena | Boss | Queen (P1 budget 8) | clear | the latch lifts; the seal opens | hub gather | S20-S21 | betrayal -> compassion / 9 | 6.5 |
| `dh4_seal_stair` | 16x9 stair | Shortcut | none | reach | relief sequence with the H1 gather beat (R16 needs 45 s or more) | hub gather | - | relief / 3 | 1 |

**Act 6: Under-Bed (22 min)**

| Room id | Size / archetype | Role | Enemies (threat / shapes) | Obj | Gate, exam | Reward | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|---|---|---|---|
| `ub1_castle_gate` | 16x9 gate | Rest | none; the lid closes, H1 is `boxed`; clue 6 | none | memories wall; a Rule Mark guards shard 6 | memory beat, shard 6 (optional) | S22 | memory / 3 | 3 |
| `ub2_last_board` | 18x9 waves | Test | 3 waves, each 6 or less: Knight + Recruit; Bishop + Charging + Recruit; Rook + Armed (up to 4 shapes) | waves | every earlier verb re-tested (Believe is locked) | Black King lore | S23 | mastery / 7 | 6 |
| `ub3_rule_engine` | 16x9 engine | Twist | corruption tiles + 1 Recruit (4/2); a fenced corruption pulse first | clear | tile rewrite hazards | Rule Engine margin note | S23 | dread / 6 | 4 |
| `ubb_black_king` | 18x9 arena | Boss | Black King (P1 budget 9), 4 phases | clear | memory alcoves; Free Step | Free Step, Rank label 8 | S24 | catharsis / 10 | 9 |

**Ending and dev**

| Room id | Size / archetype | Role | Beat | Emotion / Int | Min |
|---|---|---|---|---|---|
| `e1_morning_desk` | 16x9 desk | Ending (playable) | S25-S26 | bittersweet / 6 | 8 |
| `dev_sandbox` | 16x9 | dev only | - | - | - |

**Totals**: 34 shipping rooms: 31 on the critical path (the boss-fight, shortcut and hub rooms included) and 3 optional (`tbo`, `bso`, `bto`), plus the sandbox. About 130-136 minutes first-play estimate. Critical-path minutes: Act 1 22, Act 2 18.5, Act 3 21, Act 4 20 (+2 Midpoint), Act 5 18.5, Act 6 22, Ending 8, plus 4 H1 pass-throughs. Optional rooms add about 4.5 minutes. Threat budgets, telegraph timings and HP are tuned in M14.

**Intensity check (R32).** Critical-path order: 3, 2, 5, 6, 7, 2 | 3, 5, 6, 8, 3 | 4, 5, 6, 8, 3 | 3, 5, 6, 9, 4 | 3, 6, 5, 9, 3 | 3, 7, 6, 10 | 6. No three equal in a row, the boss peaks run 7, 8, 8, 9, 9, 10 (non-decreasing, no three equal), and no two boss-grade rooms are adjacent.

### 7.5 Room authoring rules

- **Formula**: Rest, Teach, Test, Twist, Boss/Reward, Shortcut (`v2:627-650`).
- **Meta on the room root** (`RoomEncounter`): zone id (= folder), board size, name key, district, `layout_archetype`, `time_of_night`, `content_status`, `threat_budget`, `recipe`, `objective` and its kind, `allowed_calls`, `solutions`, `emotion_target`, `release_beat`, `lazzaro_key`, `intensity`, `peak`, `what_happened_here_key`, `clue_index`, `intro`, `respawn_on_reentry`. `map_slot` is not here: it lives in `world.tres`. Every field has a `##` doc and an editor `_get_configuration_warnings()` check, so a mistake shows in the Inspector.
- **Greybox tool**: agents cannot hand-edit TileMap blobs, so `tools/build_room.gd` builds `room.tscn` from `tools/layouts/<id>.txt` (an ASCII legend: `#` wall, `.` floor, `E` entry, `X` exit, `s:<enemy_id>` spawn, `b` block, `g` gap, `m` rule mark). It emits `.tscn` **text** with `uid=` taken from `ResourceLoader.get_resource_uid()` and then runs `tools/stamp_uids.gd`, because a `ResourceSaver` resave produces uid-less scenes. It refuses to overwrite an existing `room.tscn` unless `--force`, so the scene is the truth once the owner edits it and the layout file can never drift. Generated rooms need the import pass; the new `.import` sidecars are staged in the same commit.
- **Cell kinds**: gap, wall, leapable block and chalk cells are painted through the `kind` custom-data layer by the same tool (§5.11).
- **Placement**: every enemy family is previewed before its first lethal room (R27), and every enemy in §5.3 is placed in at least one room (`test_enemy_placement`).
- **Format-breakers and play beats** (one per district): `tb3` a train chase with a toy-box joke, `bs3` a page slide, `bt2` a hold-the-line timer, `dh1` a tea party (Tier B). Each uses an objective kind other than `clear`.
## 8. Narrative systems

### 8.1 Pipeline

```
trigger markers / events / boss phases / flags
   -> TriggerSystem + StoryBeatSystem (ecs): decide WHEN a beat fires
        (requires/forbids against world.flags, once/seen) and emit story_trigger{beat_id}
   -> EventRouter (presentation/bridges)
   -> StoryDirector.play(beat_id) -> BeatPlayer runs BeatSteps
   -> visual and audio steps play in presentation; state steps push typed requests on world.commands
   -> CommandSystem applies them at the head of the next tick -> flags change
   -> SaveService saves at the next success event
```

**The split, in one paragraph.** `StoryBeatSystem` (simulation) owns *whether and when* a beat fires and owns the `seen` flags. `StoryDirector` and `BeatPlayer` (presentation) own *how it looks and sounds*. The only thing that crosses back is `world.commands` (`set_flag`, `freeze_requested`, `unfreeze_requested`, `actor_command`, `tuning_set`, `equip_page`), and a beat's `seen` flag is written by a `set_flag` command at its end. Presentation never decides anything. It reads `drain_events()` and the read-only `HudSnapshot`, plays the result, and writes only commands (D-38, amended `CLAUDE.md` A-2). An architecture test forbids `presentation -> ecs/components`. Systems never play dialogue.

### 8.2 Data format (schemas live in `schema/story/`, instances in `content/story/`)

```
StoryBeat              content/story/beats/<act>/<beat_id>.tres   (ONE file per beat: short Inspector, clean merges)
  id: StringName                      purpose: String (what this beat is for; for the owner, never shown)
  when: Array[BeatTrigger]            kinds: zone_enter, cell_enter, room_clear, enemy_defeated,
                                      boss_phase, boss_defeated, pickup, unlock, flag_set,
                                      death_count, idle_at_cell(seconds), interact
  requires / forbids: Array[Condition]   Condition = {kind: FLAG|COUNTER_GTE|UNLOCK|BOSS|ROOM_CLEARED, arg}
  once: bool = true                   mode: BLOCKING | AMBIENT | WORLD_SPACE
  steps: Array[BeatStep]              sets_flags: Array[StringName]   save_after: bool
  emotion_target, release_beat, lazzaro_key, intensity, peak      (R1)
  placeholder: bool = true
BeatStep kinds           Line, Wait, WaitForInput, Fade, Camera(pan to an anchor or cell, shake only; no zoom),
                         Shake, Sfx, Music, SetFlag, Emote, ActorCommand(entity, action), HandEnter/HandExit,
                         CrayonDraw, TitleCard, FreezeSim, UnfreezeSim, Choice(writes a flag)
DialogueLine             speaker_id, text_key, emote, hold_seconds, wait_for_input
                         + a read-only @tool preview_text that shows the resolved text in the Inspector
CharacterDefinition      content/story/characters/<id>.tres: name_key, color, blip stream, pitch range,
                         portrait_<emotion>.png (optional), anchor mode.
                         Voices: pawn (emote only), child, kingdom pieces, and `book_ink` (the Book's printed ink)
AmbientLines             content/story/ambient.tres: rows {trigger event, text_key, speaker, priority,
                         cooldown_seconds, once, conditions}. One table replaces the draft's BarkTable.
Ending                   content/story/endings/ending.tres: promotion tokens, variants keyed by rescue flags,
                         post_game_zone
Credits                  content/story/credits.tres: sections of keys
FlagRegistry             content/story/flags.tres: id, type, doc  (every flag a Condition names must be declared)
```

Notes on the changes from the draft:
- **No `Grant` step.** A grant is a `SetFlag` plus a milestone flag trigger in `content/progression/milestones/`. This keeps skills and Pages granted only by `ProgressionSystem`, so saves and tests never diverge.
- **No camera zoom.** The `Camera` step pans and shakes. Awe slots are painted vista scenes or parallax layers shown at integer scale (R25).
- **Named anchors.** A `StoryAnchor` marker in the room names a place (`anchor:kings_bier`). `Camera` and `ActorCommand` use anchor names, not cell numbers, so editing a layout never silently breaks a cutscene.
- **`Choice`** is a generic step that writes a flag. The Last Rank prompt (§8.8) and any choice the owner adds share it.
- **No prose in these files**, only keys. Prose lives in `.po`. Every placeholder line has a `purpose`.

**Text-first authoring.** Beats made only of lines are written as a plain script that `tools/build_beats.gd` compiles to `StoryBeat` `.tres` and `.po` stubs. The owner can reorder, add or delete a beat in a text file instead of nested Inspector arrays:

```
@beat QUEEN_ADDRESS  when boss_phase:queen_of_tricks:3  blocking  once  intensity 9  peak
queen: QUEEN_ADDR_1   | purpose: she speaks to the child, not the pawn
queen: QUEEN_ADDR_2
queen: QUEEN_ADDR_3
```

Complex beats (camera, hand, crayon, fades) stay as `.tres`. `tools/export_script.gd` dumps all text in play order for proofreading, and `tools/import_script.gd` (Tier B) writes edited prose back into `.po` rows. It never changes structure.

### 8.3 Dialogue

- **Presenter**: `DialogueBox` (`presentation/ui/dialogue_box/`). A `RichTextLabel` with `visible_ratio` typewriter, BBCode effects (wave, shake) for emotion, and a per-speaker blip. The pawn never speaks (emote icon only).
- **Length**: 4 lines or fewer per sequence (`gdd:431`); at most 2 lines of about 40 characters per box; minimum glyph height 10 px at 640x360 with extra line height for diacritics.
- **Controls**: advance and fast-forward on `dialogue_advance` (a dedicated action, so Space-as-attack can never leak). Skip all on hold. Text speed is a fixed default in the base (the setting is deferred, §1.2).
- **Placement**: a screen-space bar in the bottom 34 px strip, or a world-space bubble above the speaker. It never covers danger cells (`gdd:522`, tested with the HUD safe zone). While a telegraph or the attack token is live, only AMBIENT lines of 5 words or fewer may show, and none from the child.
- **Style**: the child is crayon-blue, soft blip, hand-lettered font if the owner provides one. The Book's printed ink is neutral. Kingdom voices have "subtle imagined resonance" (`gdd:508`). The finale mutes the child's voice and ambience (`gdd:510`).
- **Translation changes**: every `DialogueBox`, `PromptWidget` and HUD label re-resolves its text on `NOTIFICATION_TRANSLATION_CHANGED`, so a runtime language switch works.
- **Dialogue log** (Tier B): `StoryDirector` appends every shown key to a `dialogue_log` flag array, and the Pause menu shows the last 30. Text is never timed-only.

### 8.4 Cutscene sequencer

- **Tier 1 (data), used by every beat in the base**: a `StoryBeat` with steps, run by `BeatPlayer` with `await` and Tweens. Headless-testable and skippable. The opening, the B1 notice, the Midpoint, the seal and the Ending are all Tier 1 and use the child hand, crayon, fades, painted vistas and the `CinematicStage`.
- **Tier 2 (staged visuals), a seam with one worked example (Tier B)**: an `AnimationPlayer` in `content/story/cutscenes/<id>/cutscene.tscn` with method-call tracks into `BeatPlayer`, audio tracks and property tracks on props. The worked example is `s01_opening`. A test opens every `cutscene.tscn` and checks that each method track's target exists.
- **Freeze**: BLOCKING beats push `freeze_requested`, which sets `EcsWorld.frozen` (only `ViewSyncSystem` ticks), hide the HUD, disable player control, and restore all of it on end or skip. `Engine.time_scale` is reset on every exit.
- **Staging the pawn**: via `world.view_commands` (e.g. `wake`, `bow`, `hesitate`) consumed by `ViewSyncSystem`, the only node-toucher among actors. The child hand, shadow and crayon are presentation props owned by `ChildHandPresenter`.
- **Skip equals play**: skipping executes every `SetFlag` and final `ActorCommand` position instantly and restores camera, HUD, input and time scale. Tested.
- **Input leak guard**: after unfreeze the player has 2 frames of ignored `attack` just-pressed.
- **Save safety**: a beat's `seen` flag is set at its end. A beat cannot be interrupted by death (the sim is frozen).

### 8.5 Triggers, interactables, prompts

- **`TriggerMarker`** (`authoring/markers/`): a cell rectangle with `fires_on`, `once`, `requires/forbids`, `sets_flags`, `beat`. `EcsBoot` bakes it into `trigger_by_cell`. `TriggerSystem` compares the player's `GridPos` with `TriggerWatch.last_cell`, evaluates flags against `world.flags`, and emits `story_trigger` or `flag_set`. It also handles ROOM_ENTER, ROOM_CLEAR and BOSS_ENGAGED.
- **`InteractComponent`** (an `EntityComponent` on props): E near a prop plays a beat or a one-line emote (yellow = interactable). Used for "stand with the fallen", the rescues (hold E 1.5 s, with a toggle or tap alternative in Settings) and Book margins. `InteractionSystem` handles the hold timer.
- **`StateVariantMarker`** (`authoring/markers/`): holds `Condition[]`; `EcsBoot` bakes it into a `FlagVisible` component read by `ViewSyncSystem`. This is the single primitive for hub states, clues, the memory wall, the boxed hub and ending variants. A test asserts that every hub state and clue named in a milestone or room meta has at least one variant node.
- **Prompts** (R5): `ControlPrompt` data with `{action}` tokens resolved from the live `InputMap` (keyboard glyph or pad glyph). One idea each, shown once in a safe moment, dismissed by performing the action, and a `prompt.<id>` flag is set. `test_prompts_cover_actions.gd` asserts every gameplay `InputMap` action has exactly one prompt below or a documented "no prompt" reason.

| Prompt id | Trigger | Action taught | Room | Once flag |
|---|---|---|---|---|
| `prompt.move` | 6 s idle | `move` | T1 | yes |
| `prompt.interact` | near the King | `interact` | T1 | yes |
| `prompt.strike` | after the sword pickup | `attack` | T2 | yes |
| `prompt.turn` | harmless target on the pawn's side | `turn_mode` | T2 | yes |
| `prompt.hold_repeat` | after 3 single steps in T2 | `move` (hold to repeat) | T2 | yes |
| `prompt.dodge` | before aggro | "step out of the red cells" | T3 | yes |
| `prompt.pencil` | after the Pencil pickup | `skill_slot_1` | T4 | yes |
| `prompt.reset` | first respawn | the death rule in one sentence | any | yes |
| `prompt.book` | first Page unlock | `rule_book` | T2 | yes |
| `prompt.equip` | first priced Page, Book open | equip within Margin | H1 | yes |
| `prompt.rescue` | next to Pebble | `interact` (hold) | H1 | yes |
| `prompt.rule_step` | at the alcove | `skill_slot_2` | tb3 | yes |
| `prompt.call` | at the gap | `child_help` | bs4 | yes |
| `prompt.help_next` | Chalk Block unlock | `help_next` | H1 | yes |
| `prompt.guard` | at the Rule Mark | `guard` | bt4 | yes |
| `prompt.focus` | first long telegraph | `focus` | T4 | yes |
| `prompt.free_step` | start of Black King P4 | `free_step` | ubb | yes |
| no prompt | | `skill_slot_3`, `skill_slot_4` (unused), `pause` (standard), `dialogue_advance` (the box shows it), `debug_overlay`, `toggle_fullscreen` (system) | | |

### 8.6 Ambient lines and the child-voice layer

A single `AmbientLines` table in the bridge fires rows on events, one at a time, with a priority, a cooldown, a once flag and conditions. Rows are suppressed while a telegraph is live. Death tiers (§4.6) are rows keyed by `deaths.<zone>`; the reset presentation variants (D-44) are rows keyed by relationship flags. The pawn "barks" with an emote icon (the palette of §4.5). `test_child_voice.gd` lints that child lines are 8 words or fewer, at most 1 per room, and only fire in safe states (soft, R21).

### 8.7 Lore: Book of House Rules v2

Pages come from `content/rules/<id>/page.tres` (`kind` PAGE or LORE). Page states are unread, read, new and rewritten (crossed-out and re-inked amendment). Inks follow D-46: grey pencil for enemy amendments, blue crayon for the pawn's unlocks, neutral printed ink for notes and death-knowledge notes. The Drawings tab holds the child's keepsakes (§4.5). Opening the Book freezes the world by tree pause. Pages never gate progress (`ui3:21-30`).

### 8.8 Endings and credits

`Ending` data drives: the playable Desk board (`e1`), the four promotion tokens (Queen, Rook, Bishop, Knight; each is an `InteractComponent` prop that plays a one-line bittersweet epilogue when bumped and leaves the board unchanged), the exit beyond the board's edge (a `ZoneExit` of kind `OUTSIDE_BOARD`, cued by the blue crayon line), rescue-flag variants of the final shot, the 10 s hold, and `credits.tres` scrolling over the live image. The last input before the hold is the player's step (R30, `test_ending_audit`). `WorldFlags.completed` is written to the **profile** (`user://profile.cfg`), not the slot, so the title shows the post-game board (one square empty) even after a New Game. **Continue on a completed save** loads `Ending.post_game_zone` (H1 in state 5, the Desk reachable). The credits can be replayed from the title menu. New Game Plus is not included. The last 3 minutes contain zero damage sources.

### 8.9 Localization

- **Format**: gettext `.po` in `content/story/text/<locale>/{story,ui,skills,rooms}.po`, registered in `project.godot` `[internationalization]` as several translations of the same locale (`test_po_domains_merge` proves the merge `[unverified]` before M4 relies on it).
- **Keys**: stable UPPER_SNAKE with prefixes `ROOM_`, `DLG_`, `AMB_`, `BOOK_`, `SKILL_`, `PAGE_`, `UI_`, `CHAR_`, `ENEMY_`, `BOSS_`, `PROMPT_`, `CREDIT_`, `END_`, `CLUE_`.
- **Context**: translator comments (`#. speaker=child emotion=hush purpose=... placeholder`) sit above each entry.
- **Resolution**: `TextService.t(key, params)` is the ONLY caller of `tr()`. It fills `{pawn}`-style placeholders with `String.format`. A missing key renders the key and fails `test_text_keys.gd`.
- **Resources store keys, not text**: scenes and `.tres` hold key strings. A tool checks every key used in `content/` exists in the source locale.
- **Tests set `en` explicitly**; this machine's default locale resolves to `en_VN`. The source locale is O-4.
- **Pseudo-locale**: a generated `qps` locale expands every string by 40 percent and adds accented characters. `test_layout_pseudo_locale.gd` checks that dialogue, HUD and menu text still fit their boxes.
- **Font**: an OFL pixel font of at least 10 px, picked from a shortlist in M4 and credited in `THIRD_PARTY_NOTICES.md`. `FontFile.has_char` over the Vietnamese set runs only if the owner picks `vi` as the source (O-4).

### 8.10 Built-in versus addon

Built-in is the default: `Resource`, `RichTextLabel`, `Tween`, `AnimationPlayer`, `TranslationServer`. **Dialogue Manager 4 (MIT, Godot 4.6+, stateless)** would give a script-like `.dialogue` authoring format. It **needs owner approval** and a plugin import step for `.dialogue` files. If adopted, it replaces only the source of `DialogueLine` data; `StoryDirector.play(beat_id)` and the flag store stay. Dialogic 2 is not recommended (alpha, owns its own state and layout).

### 8.11 Owner and QA tools

`dev_sandbox` with a beat launcher, a flags and counters panel, and the validator suite. Everything the owner needs is also reachable inside the Godot editor, not only headless:

- Markers and `RoomEncounter` implement `_get_configuration_warnings()`, so a wrong id, a missing key or a duplicate shows in the Inspector.
- `tools/validate_content.gd` is an `EditorScript` (File > Run) that prints ids, keys, placeholders and clickable results. `dev_sandbox` has an `@export_tool_button` "Check content".
- Validators: unreachable beat, missing speaker, flag read but never set, flag set but never read, every boss has intro/phase/defeat beats, every key present in every shipped locale, `ContentDb.validate_cross_refs()` (every referenced id exists).
- Narrative tests: reachability, skip equals play, no soft-lock on death during a beat, save round-trip of flags, line budget.
- Lints come in two tiers (§1.4): hard integrity checks fail every run; soft checks (word counts, emotion fields, threat) are warnings for the owner and failures only in `--strict` agent gates.
## 9. Game shell

### 9.1 Flow

`AppRoot` (main scene, `shell/app_root.tscn`) owns a `GameFlow` state machine, a persistent transition layer, the `MusicDirector` and the pause menu. It swaps child scenes instead of calling `change_scene`, so music and transitions survive reloads. The autoplaying music player that sits in `scenes/main.tscn` today (asserted at `tests/run_tests.gd:180-182`) moves into `AppRoot` in M4, not M14.

```
BOOT -> (FIRST_RUN, once, Tier B) -> TITLE -> (NEW GAME | CONTINUE) -> PLAYING <-> PAUSED
PLAYING -> RESPAWNING -> PLAYING          (death: respawn_requested, never reload_current_scene)
PLAYING -> ENDING (playable e1, 10 s hold) -> CREDITS -> TITLE (completed mark)
TITLE -> CREDITS                          (replay at any time)
```

- **Death and restart** raise a `respawn_requested` signal that `GameFlow` handles by rebooting the same zone through `game_root`. Both `reload_current_scene()` calls in `scripts/main.gd` (lines 120 and 302) are removed in M3b. Once `AppRoot` is the main scene (M4), a scene reload would reload the title.
- **Continue on a completed save** loads `Ending.post_game_zone` (H1 in state 5, the Desk reachable). New Game over a used slot asks to confirm. The `completed` mark lives in the profile (`user://profile.cfg`) so it survives a New Game.
- `game_root` (in-game scene) stays testable alone, with no `AppRoot`.

### 9.2 Screens and behaviours

| Screen or behaviour | Contents |
|---|---|
| Title | Rug board with one standing pawn, room tone. New Game, Continue, Settings, Credits, Quit. After completion, one board square is empty. The build version string is shown (req#242 package notes). |
| Save slot | One slot in the base. The card reads `[meta]` only: zone name key, Rank label, play time, deaths, completed, saved_at. The `SaveService` API takes a slot id, so a slots screen later is a UI-only change. |
| Pause (Esc / Start) | Resume, Book, Settings, Controls, Assist options, Restart Room (confirm; this is a menu command, not a bound action), Quit to Title (confirm; the dialog names the last checkpoint and says progress since then is lost). `get_tree().paused = true`; the pause UI and music are `PROCESS_MODE_ALWAYS`. Pause is blocked during zone travel. The game also pauses when the window loses focus (`NOTIFICATION_APPLICATION_FOCUS_OUT`). |
| Controls | A panel built from the live `InputMap` (keyboard and pad glyphs). It replaces the static `HelpLabel`. |
| Settings | Volume per bus (Master, Music, SFX, UI, Voice), screen-shake scale 0-100 %, reduce flashing, high-contrast danger, UI high contrast, fullscreen or windowed, language, assists (§5.8), hold-or-toggle for Guard, Focus, turn mode and the rescue hold. Stored in `user://settings.cfg`, separate from saves. Remap UI, text size and speed, and captions are deferred (§1.2). |
| Autosave indicator | A small tick icon shows for 1 s after every autosave. |
| Corrupt or newer save | The loader falls back to the `.bak` and shows a one-line notice. A save from a newer version shows "This save needs a newer game" and is never overwritten. Nothing is wiped silently (the current `WorldState` wipes on a version mismatch). |
| First run (Tier B) | A one-time card: language and a photosensitivity notice. |
| Credits and Ending | Data-driven (§8.8). Credits can be skipped by holding Confirm. The credits include a Licenses section generated from `THIRD_PARTY_NOTICES.md`. |

There is no `game_over` screen (the draft's `shell/game_over/` folder is dropped). Defeat is the hand-reset (or no hand, §4.6). The world map screen is deferred (req#121).

### 9.3 Save

`SaveService` autoload. `ConfigFile` at `user://saves/slot_N.cfg`.
- Schema v3: `[meta]` (which also holds `room` and `room_entry`, the room and entry the pawn is in: a death returns to them and a Continue resumes at the ones of the last save, see 5.2) plus world flags (namespaced bool/int), counters (`child_calls_used`, `child_trust`, shard count), `checkpoint_zone/entry` (the latest hub or boss-room door only: where Courage refills; nothing returns the pawn to it), `cleared_room_ids`, `defeated_boss_ids`, taken pickup ids, opened gates, unlocked skill and rule ids, equipped pages, Margin, Believe, Courage max, `dialogue_log` (Tier B).
- Atomic write (tmp file, rename, keep `.bak`); `Error` checked. A crash between the two renames leaves no file, the
  old save as `.bak` and the new save, complete, as `.tmp`: the loader reads that `.tmp` (when it is not older than
  the `.bak`) before the `.bak`, and `load_slot` finishes the rename, so the interrupted save is not lost.
- A `_migrate(from_version)` chain replaces the silent wipe on mismatch. The v2 fixture is tested.
- No auto-load in `_ready`; `GameFlow` loads on Continue.
- `SaveService.configure(root_dir)` is injectable. Tests pass a unique `user://test_saves/<id>/` folder (and run with `HOME=/tmp/unbound-pawn-godot`) so a stale save can never change which room a test boots into.
- Player runtime state that must survive a room change is carried by the `PlayerSnapshot` (§14.2), not rebuilt from scratch with the world.

### 9.4 Input map (all are `InputMap` actions; no raw `KEY_` polling)

| Action | Keyboard | Gamepad |
|---|---|---|
| move | WASD / arrows | left stick (dominant axis, deadzone 0.35; 8-way when Free Step is owned) / d-pad |
| turn_mode (hold or toggle) | Shift | LB |
| attack (Strike) | Space, K | A |
| skill_slot_1 (Pencil) | Q | X |
| skill_slot_2 (Rule Step) | F | B |
| skill_slot_3, skill_slot_4 (declared, unused; the HUD hides empty slots) | C, V | unbound |
| guard (hold or toggle) | G | LT |
| child_help (cast selected) | R | RB |
| help_next | Tab | R3 |
| focus (hold or toggle) | Left Ctrl | RT |
| free_step (modifier) | Left Alt | stick diagonal cone |
| interact | E | Y |
| rule_book | B | L3 |
| pause | Esc | Start |
| dialogue_advance | Space, Enter, E | A |
| debug_overlay, toggle_fullscreen | F3, F11 | n/a |

`restart_room` is not an action: it is a Pause menu command. The `map` action is not shipped (the map screen is deferred). The existing `skill_1` action becomes `skill_slot_1` through `tools/move_res.py --rename-action` after a grep for string access.

- A test asserts each used gameplay action has at least one keyboard and one joypad event (unused slot actions are exempt).
- The control hints are generated from the `InputMap`, never hard-coded. Two glyph sets ship (keyboard, generic gamepad), chosen by the last input device (hot-swap). Xbox, PlayStation and Switch skins are a later art task.
- Pad menu navigation uses the built-in `ui_*` actions (which have joypad events by default); focus handling is set up in M4.
- There is no rumble in the base (a decision, not an omission).
- **Input seam**: an `InputPoller` in `game_root` fills an `InputSnapshot` once per tick (per action: pressed, just_pressed, just_released, held_time, timestamp). `PlayerInputSystem` reads only the snapshot (today it reads the global `Input` singleton at `player_input_system.gd:27-93`), so the buffer, the chord, the tap window, hold-G and the hold-E rescue are tested by injecting snapshots, in the same style as the other ECS tests. Hold-or-toggle is applied in the poller.
## 10. Feel and feedback

All values are `[start value]` in `content/feel/feel_profile.tres` (edited by the owner, one file). Stage A makes the step, strike and defeat feel great. Stage B inverts feel on purpose in the King fight, after the feel is learned.

| Event | Channels | Numbers |
|---|---|---|
| Step | tap SFX, dust puff, squash | 3 particles, squash 0.92/1.08 for 0.06 s |
| Blocked step | bump sound, small recoil (the `step_blocked` event finally has a consumer, M8c) | 0.08 s |
| Strike swing | anticipation pose, swing arc, wooden thunk | 0.05 s anticipation |
| Hit on enemy | hit-stop, white flash, 4 chips, camera nudge, stagger | 60 ms, flash 0.08 s, nudge 1 px 0.06 s, stagger 0.35 s |
| Player damage | hit-stop, shake, desaturate flash, pip pop, flicker, the child's shadow flinches | 100 ms, 3 px for 0.20 s, flash 0.12 s, invuln flicker 0.7 s |
| Low Courage (1 left) | slow pulse of the pips and a soft vignette edge, never red-saturated | 1.2 s cycle |
| Enemy defeat | topple into toy, paper chips, soft sound | 5-8 particles, hit-stop 90 ms, no gore |
| Boss phase change | hit-stop, shake, light change, music layer, safe beat | 150 ms, 5 px for 0.4 s, 0.8 s transition |
| Boss kill | maximum budget, silence, soft sound | hit-stop 220 ms, shake 6 px for 0.5 s, music duck -12 dB for 2 s |
| Rule Step | whoosh, dust trail, landing thud | 2 px landing nudge |
| Pickup | glow in ivory or yellow, never red, sparkle | 0.4 s |

- **Hit-stop**: set `Engine.time_scale` and restore with a timer that ignores time scale. It is reset in `_exit_tree` and on every transition. It is blocked while `travel_in_progress`. Tuned range 60-120 ms (`test_hit_stop_restores_time_scale`).
- **Knockback**: a 1-cell push uses the `direction` in the damage payload. Normal hits only recoil 4 px visually; real cell knockback belongs to specific skills (Lead Tip, Perfect Rub).
- **Particles**: pooled `CPUParticles2D` (safe under `gl_compatibility`), z-ordered BELOW the telegraph overlay.
- **Telegraph language** (R6, R7, R28): the palette lives in `feel_profile.tres` as a `TelegraphPalette`, so it is data and art direction stays the owner's.
  - Red solid fill plus hatch means damage imminent.
  - Dark orange outline plus dots means anticipation.
  - Blue means child-made.
  - Yellow means interactable.
  - Mint means safe.
  - Ivory versus charcoal separates the sides.
  - Every shape also has a pattern, so colour is never the only cue.
  - Pawn = corner slashes. Knight = outlined L with crosshair. Bishop = lane band with chevrons. Rook = arrow row. Queen = union. King = pulsing ring and grid.
  - The red pickup glow of today is recoloured.
- **HUD safe zone and readability**: the board occupies y 36 to 324. The top strip (y 0-32, HUD bars at most 28 px tall, the boss bar inside it) and the bottom strip (y 326-360: status bar and the dialogue bar) never overlap a board row. `test_hud_safe_zone` asserts that no HUD control rectangle intersects the board rectangle. Simultaneous threat shapes are capped by act (R28). A grayscale readability pass is part of M14; a colour-blind simulation pass is Tier B.
- **Camera**: static per room, with a centred origin and integer-pixel snap (req#10: today the camera eases with smoothing 8.0 and no snap). Awe slots are painted vistas or parallax layers at integer scale; the `Camera` beat step pans and shakes only (R25).
- **Tint** (D-31, Tier B): `time_of_night` tints the background and tile layers only. Telegraph, HUD and dialogue layers are never tinted, so saturated red and mint stay legible. The readability pass takes one screenshot per `time_of_night` value.
- **Death**: freeze 0.6 s or more with the damage origin visible (the payload `source`), then the reset presentation chosen by relationship flags (§4.6), with control in 5 s or less.
- **Accessibility**: reduce-shake and reduce-flash remove effects but never telegraphs. A boss-kill and phase-change flash test keeps flashes at 3 per second or fewer (`test_flash_rate`). High-contrast danger adds a pattern and a thicker outline. UI high contrast gives dialogue and menus an opaque background. Focus (hold or toggle) emphasizes telegraphs without slowing time.
- **Optional pulse**: an audio pulse aligned to telegraph timing (NecroDancer lesson); window tolerances are never tighter in boss fights than in tutorials (R11).
## 11. Audio

**Buses**: Master <- SFX / Music / UI / Voice. The current layout is wrong: bus 0 is defined as "SFX" with no Master, so at runtime `get_bus_index(&"SFX")` is -1 and any SFX slider would do nothing (verified on Godot 4.6.3). It is fixed in M1a and asserted by `test_audio_buses.gd`.

**Three layers, one owner each** (`CLAUDE.md`, unchanged): motion sounds are audio tracks inside the actor's clips; mixing lives in `default_bus_layout.tres`; event sounds with no clip are keyed in `content/audio/sound_bank.tres` and played ONLY from the bridge. Systems never play audio. Every `sound_bank` row carries a `caption_key` (the captions UI is deferred, the data is not).

**Music and the child's sounds start early.** The draft left music and the child's SFX to the last milestone, yet at least seven designed beats depend on silence or subtraction: T1 silence (R3), the music-box leitmotif, the B1 two-second silence, the boss-kill duck, the Queen's address, the King's subtraction of voice and ambience, and the ending piece. Subtraction needs something to subtract. A minimal `MusicDirector`, four placeholder stems (calm, tension, boss, music-box motif) and the child's SFX set land in **M6** and are extended per act; M14 completes coverage.

### 11.1 SFX per event (all placeholders until the owner swaps them)

| Group | Events |
|---|---|
| Pawn | step tap, step blocked bump, turn tick, strike swing, strike hit, pencil thrust, Rule Step takeoff and land, guard raise, guard block, Perfect Rub, hurt, defeat, victory |
| Child | hand arrive and depart, crayon scratch, chalk draw and expire, block raise, paper rustle, music-box note, call rejected (M6) |
| Enemy | telegraph warning per family (pawn, knight, bishop, rook, queen, king, boss), hurt, topple-to-toy, charge, leap, lane grow |
| World | pickup, unlock jingle, Book page flip, room clear, door open and locked, gate open, rescue, Black Line seal, tile rewrite, train rumble |
| Boss | phase change, boss defeat, box close |
| UI | navigate, confirm, cancel, typewriter tick, per-speaker blips |

Existing: 10 generated chiptune SFX and `unbound_march.wav` (embedded loop points). Missing events get generator output (`tools/generate_sfx.py` extended), each flagged `placeholder` by hash (§12). `test_sound_bank_coverage.gd` asserts that every event in `events.gd` that needs a sound has a row.

### 11.2 Music per area and state (`content/audio/music_cues.tres`: room / boss / beat / mood -> track)

| State | Cue |
|---|---|
| Title | room tone plus a single music-box note |
| T1 | silence and room tone only (R3) |
| T2-T4 | a sparse sustained instrument |
| Combat | a layer on the area theme (`AudioStreamSynchronized` stems) |
| H1 | warm hub theme (changes with hub state; the `boxed` state drops the layers) |
| Districts | one theme each (Toybox, Bookshelf, Block Tower, Dollhouse, Under-Bed) |
| Boss | per-boss theme with phase layers |
| Final King | subtraction: the child's voice and ambience removed |
| Ending, credits | one continuous piece |

- **Crossfade**: 1.0 s between themes, 2.0 s into a boss. `MusicDirector` is `PROCESS_MODE_ALWAYS` and lives in `AppRoot`, so it survives death respawns.
- **Mix priority and ducking**: telegraph warnings beat everything. The Music bus ducks -6 dB during blocking dialogue and takes a low-pass while paused.
- **Accessibility**: `caption_key` is in the data; the captions UI is deferred.
- **Leitmotif**: a music-box phrase for the child, and its subtraction in Act 6 is the story.
- **Swap**: the owner drops a file in `assets/music/` and edits one row; the registry key stays stable.
- **Ambience** per area is Tier B (a looping room tone row per room in `music_cues.tres`).
## 12. Art pipeline for the owner

**Rule**: the owner overwrites a file whose name and role never change. No code, no node renames. Hand-drawn art never goes in a gitignored folder (`assets/_generated/` is generator output only and may be overwritten).

| Replace | File to overwrite | Size and rules |
|---|---|---|
| Pawn, enemies, bosses | `content/<kind>/<id>/body.png` (the pawn's is `content/player/body.png`) | **A piece is smaller than its 32 px cell** (owner decision 2026-10-12, `docs/owner-decisions.md`; it replaces the sizes this row used to give, a 32x40 pawn, a 48x48 knight and 64-96 px bosses from `gdd:465-476`, which let a piece rise into the row above). Drawn at scale 1 on the **32x32 canvas of the owner's art spec** (`docs/assets`: base rim on row 30, the two rows under it empty, anchor (16,30)) with the drawn pixels inside the box of its kind in `content/feel/piece_sizes.tres`: pawn 18x22 (x 7 to 24, y 8 to 29 of the canvas), knight, bishop and rook 20x24, queen 22x26, king 22x28; transparent padding is free. The canvas lands exactly on the cell (canvas pixel (x,y) shows at cell pixel (x,y); `PieceSizeTable.body_top_left`), so no scene repeats a position. A tight picture no larger than the box (the whole PNG counts then) also works, its bottom edge on the base line; the generated stand-ins are canvases too. The base line is 14 px below the cell centre, so every piece keeps 2 px below it and the king keeps 2 px above; heights follow a real chess set (pawn lowest, king tallest). A boss is one more row of the table with a bigger `footprint_cells` (and a box that grows with it): it stays inside the cells it stands on. `VisualDefinition.anchor_offset` nudges the picture from the base line. Optional `body_n.png/e.png/w.png`; if missing the view rotates or flips as today. Nearest filtering. |
| Skill and item icons | `content/skills/<id>/icon.png` | 16x16 |
| Pickups and props | `content/pickups/<id>/pickup.png`, `content/props/<id>/prop.png` | any, feet-anchored |
| Room art | `content/rooms/<id>/background.png` (+ optional `foreground.png`) | 512x288 for 16x9, 576x288 for 18x9 |
| Tiles | `assets/tiles/<district>/atlas.png`, referenced by `content/tilesets/<district>/tileset.tres` (one home each) | 32x32, custom data `solid` and `kind` |
| Portraits | `content/story/characters/<id>/portrait_<emotion>.png` | 64x64; emotions neutral, glad, worried, afraid, hush, surprised. Optional; otherwise an emote icon is shown. |
| Child hand and shadow | `content/story/characters/child/hand_*.png` | 160x120 or larger, smoother than the chess world (`pixel-art-bible.md:53-58, 85`) |
| UI skin | `content/ui/theme/` 9-patches, `assets/fonts/` | one `Theme` resource; an OFL pixel font |
| VFX | `content/feel/vfx/<id>.png` | small sprite sheets |
| Painted vistas (awe slots) | `content/story/vistas/<act>.png` | one per act, shown at integer scale (R25) |

- **In-cell rule (built in M2)**: everything an actor draws stays inside its own cell: the body from the size table, the health pips along the top edge, the facing arrow 10 px out on the facing side, the held weapon at 0.16 scale, the telegraph aura 22 to 27 px, all within 14 px of the cell centre and 2 px from every edge, and every clip caps its hops and shakes at the 2 px margin. `PieceSizeTable.validate()` holds the margin and the height order; `PieceSizeTable.picture_problems()` is the one rule for a picture (a tight picture inside the box, or the 32x32 canvas with its drawn pixels inside the box on it) and `ContentDb.validate_cross_refs()` applies it; `tests/architecture/test_pieces_inside_cell.gd` measures the hero, every enemy and **every actor a room scene places, as placed** (a stretched instance, like the B1 captain once was at 1.18x, fails by room and name; the probe measures in the cell's frame, so a scale shows), facing every way, armed, telegraphing, shoved by a hit (the drawn shove is limited to the 2 px margin: it may touch the cell edge, never cross it) and across every clip, and holds the pip row against the head of every kind; `tools/render_actor_preview.gd` writes `assets/_generated/previews/pieces_in_cells.png` and `pieces_placed_in_rooms.png` for the owner, with a gutter around each cell, the grid and margin under the pieces, and any piece pixel in the margin band painted magenta and counted. The health pips sit on the top margin line; a queen and a king stand up into that row (nothing above them fits in the cell), so their pips are drawn over the crown, and the test names the two kinds so a new tall row cannot join them unnoticed. **Not settled with `docs/assets` (game-base):** it sizes the telegraph aura files at 40, 56 and 96 px ("not pieces"), the facing arrow 8x8 in a 16x16 canvas and the pip row 24 px wide, while this scene draws the aura 22 to 27 px, the arrow about 6 px and three 4 px pips; the owner's rule says nothing a piece shows leaves its cell, so the integrator picks one set of numbers (they are data in `actor_view_base.tscn`). **`task_plan.md` phase 66 (pieces 1.5 cells tall, `BodySprite` at (0,-8), the top half in the row above) is superseded.** Row-based depth (`z_index` by row) is kept and nothing needs it any more.
- **Templates**: `tools/export_art_templates.gd` (not built yet; it will read `piece_sizes.tres`) writes guide PNGs (cell grid, the box and base line of each kind of piece, the 2 px margin) into `assets/_templates/` for each role.
- **Masters**: layered sources go in `assets/_source/` (`.gdignore` so Godot never imports them).
- **Sprite sheets (Tier B)**: `VisualDefinition` takes an optional `hframes/vframes/clip_frames` block so a frame-animated sprite needs no scene edit. Today `body.png` is one static image with transform-only clips.
- **Contract test**: `tools/art_contract_check.gd` run by `tests/content/test_art_contract.gd` verifies that every actor derives from `actor_view_base.tscn`, that every clip of the animation manifest (§12.1) exists on every actor of that role, that `MotionRoot/SpriteRoot/BodySprite`, `WeaponPivot`, `HealthPips`, `TelegraphAura`, `FacingArrow` and `AudioPlayer` exist, that the telegraph-to-attack transition exists in the `AnimationTree` graph, that every `body.png` exists, that every room has a `background.png`, and that every placeholder is listed.
- **The owner's TODO**: `tools/list_placeholders.gd` prints remaining placeholders by room and kind. A file is a placeholder if and only if its sha256 still equals the hash recorded in `content/_placeholders.json` when `tools/seed_placeholders.gd` seeded it. Overwriting the file clears the flag with no extra edit; a sidecar flag would go stale.
- **Placeholder generators** (`tools/generate_chess_sprites.gd`, `generate_stage1_room_art.gd`) write only to `assets/_generated/`; the chess generator reads the size table and refuses a piece that does not fit its box. `tools/seed_placeholders.gd` copies into `content/` only when a file is absent (or, for a row marked `supersedes_stand_in`, replaces an earlier stand-in that is provably still the recorded one), and records the hashes.
- **Provenance**: the Knight silhouette was traced from a system font glyph (`where:178`); M2 retraced the same glyph on 15 rows so it fits its 20x24 box. The base records this in `THIRD_PARTY_NOTICES.md` and flags the sprite for redraw or replacement before any release.
- **Editing a clip or the `AnimationTree`** is an editor task in `presentation/views/actors/actor_view_base.tscn` (and thin inherited scenes). It changes every actor that inherits it. The telegraph-to-attack edge is added once, in the base, after the M2 collapse.

### 12.1 Animation manifest (required clips per role)

The owner will draw to this list, and the contract test fails if a clip is missing. All clips key `SpriteRoot`, never `MotionRoot` (the cell-to-cell slide is procedural). Frame counts are guidance for hand art.

| Role | Required clips | Notes |
|---|---|---|
| Pawn (player) | `wake`, `idle`, `step`, `turn`, `attack`, `pencil`, `rule_step_takeoff`, `rule_step_flight`, `rule_step_land`, `guard_raise`, `guard_hold`, `guard_block`, `free_step`, `pickup`, `hurt`, `defeat`, `victory`, `bow`, `hesitate`, `head_shake` | `bow`, `hesitate` and `head_shake` are used by beats and the chord denial |
| Pawn-family enemy | `idle`, `move`, `alert`, `windup`, `commit`, `recover`, `hurt`, `defeat` | the `attack` clip never plays for enemies (req#159) |
| Knight | the pawn-family set plus `leap_takeoff`, `airborne`, `land` | its shadow shows the destination |
| Bishop | the pawn-family set plus `lane_channel` | |
| Rook | the pawn-family set plus `turn_tell`, `charge`, `stunned` | |
| Boss | `idle_authority`, a `windup_clip` per pattern, a `transition_clip` per phase, `hurt`, `recover`, a `defeat_clip` (becomes a toy) | `BossPhase` gains `windup_clip`, `transition_clip` and `defeat_clip` fields (req#161) |
| Child hand | `arrive`, `hover`, `place`, `draw`, `lift_latch`, `offer`, `leave`; shadow `cross`, `flinch` | smoother and heavier than the chess world |
| Props | `idle`, `interact`, state variants through `StateVariantMarker` | |

Weapon animation silhouettes (req#162) are Tier B.
## 13. Code and folder organisation: ECS first

### 13.1 The ECS contract mapped to folders

| ECS idea | Where | Rule |
|---|---|---|
| Entity | an integer id, assembled by `authoring/ecs_boot.gd` (and `ecs_actor_factory.gd`) from an `EnemyDefinition` or `PlayerDefinition`, an `ActorView` instance in the room and any `EntityComponent` nodes on it | today's pipeline is kept (D-28). A node on an instance beats the definition. |
| Prefab / blueprint | `EnemyDefinition` (a `.tres` composed of shared sub-resources in `content/enemies/_shared/`) plus a thin inherited actor scene | a variant is a new `enemy.tres` that reuses the shared sub-resources |
| Component | `ecs/components/` | pure data, no decisions |
| System | `ecs/systems/<phase>/` | one rule per file; order lives only in `ecs/schedule/<phase>.gd` |
| Authoring | `authoring/entity_components/` (Inspector data + one `apply()`), `authoring/markers/`, `authoring/ecs_boot.gd` | the bake is one-way; zero logic |
| View | `presentation/views/` | only `ecs/systems/view/ViewSyncSystem` touches actor nodes |
| Events | `ecs/events/events.gd` | the only channel from simulation to presentation |
| Commands | `world.commands` | the only channel from presentation and settings into the simulation (D-38) |
| Content | `content/` | zero `.gd` files; looked up by id through `ContentDb`, never by path |

**Dependency rule** (enforced by `tests/architecture/test_dependency_edges.gd`). The allowed-edge table is **derived from the real `class_name` graph** by a report-only run in M1a, then frozen as `tests/architecture/allowed_edges.txt`. Starting point:

| From | May depend on |
|---|---|
| `content` | `schema`, `authoring`, `presentation/views` base scenes |
| `schema` | engine only (parts' `apply()` calls were the only schema-to-ecs dependency, and the entity components now live in `authoring`) |
| `ecs` | `schema`; **one documented exception**: `ecs/systems/view/ViewSyncSystem -> presentation/views/ActorView` (the art-contract test guards the node paths). `PlayerInputSystem` no longer touches the `Input` singleton (the snapshot replaces it) |
| `authoring` | `ecs/core`, `ecs/components`, `schema`. `EcsBoot` is the baker and lives here |
| `presentation` | `ecs/events`, `schema`, `HudSnapshot`. Never `ecs/components` |
| `shell` | everything. `ContentDb` lives in `shell/content/` and is the only code that loads `content/` |

Every exception is a line in `allowed_edges.txt` with a comment. No agent adds an exception ad hoc.

### 13.2 Target tree

```
res://
├─ project.godot            main_scene = shell/app_root.tscn; autoloads: SaveService, Sfx
├─ default_bus_layout.tres  Master <- SFX / Music / UI / Voice
├─ CLAUDE.md AGENTS.md README.md task_plan.md progress.md findings.md   rewritten to this tree (CLAUDE.md per §2.4)
├─ LICENSE THIRD_PARTY_NOTICES.md
│
├─ content/                 THE OWNER'S FOLDER: data, art, audio, words. Zero .gd files (test-enforced).
│  │                        Folder name = id. A leading underscore (_shared, _template) is skipped.
│  ├─ README.md             "I want to change X -> open Y" (the Change Table of §13.5), bilingual
│  ├─ _placeholders.json    sha256 of every seeded placeholder file (§12)
│  ├─ player/               player.tres (PlayerDefinition: courage, invulnerability, step and hold timings),
│  │                        player.tscn (thin inherited actor), body.png
│  ├─ skills/<id>/          skill.tres, icon.png   (wooden_sword, pencil_thrust, rule_step, chalk_path,
│  │                        chalk_block, eraser_guard, free_step)
│  ├─ rules/<id>/           page.tres (Book page or lore entry: text keys, margin_cost, ink, modifiers)
│  ├─ progression/          milestones/<id>.tres (one file per milestone, with an order field),
│  │                        slots.tres (slot -> InputMap action -> HUD position), rules.tres (economy values)
│  ├─ enemies/<id>/         enemy.tres (EnemyDefinition), actor.tscn (thin inherited view), body.png
│  │                        (_shared/ holds shared movement, attacks, decisions, visuals, difficulty)
│  ├─ bosses/<id>/          boss.tres (BossDefinition: phases[]), referenced from that boss's enemy.tres
│  ├─ pickups/<id>/         pickup.tres, pickup.png
│  ├─ props/<id>/           prop.tres (interactables, hazards), prop.png
│  ├─ rooms/<id>/           room.tscn (RoomEncounter root), background.png, objective.tres
│  ├─ world/                world.tres (WorldDefinition: start room, act order, map slots, regions), map_backdrop.png
│  ├─ story/                text/<locale>/{story,ui,skills,rooms}.po · characters/<id>/ · beats/<act>/<beat_id>.tres
│  │                        · script/<act>.txt · ambient.tres · flags.tres · emotes.tres · vistas/
│  │                        · cutscenes/<id>/cutscene.tscn (Tier 2 seam) · endings/ending.tres · credits.tres
│  ├─ audio/                sound_bank.tres, music_cues.tres
│  ├─ feel/                 feel_profile.tres (+ telegraph palette, vfx/)
│  ├─ difficulty/           standard.tres (+ assist presets)
│  ├─ ui/                   theme/ (theme.tres, 9-patches)
│  └─ tilesets/<district>/  tileset.tres (do not hand-edit tile_map_data)
│
├─ schema/                  THE SHAPE OF CONTENT: one Resource class per file, @export + ## docs + validate()
│  ├─ entity/               EnemyDefinition, PlayerDefinition, VisualDefinition, MovementConfig, DecisionConfig,
│  │                        BossDefinition, BossPhase
│  ├─ attacks/              AttackBase, CellPattern, AttackProfile, AttackPattern, EnemyWeapon, AttackStage
│  ├─ skills/               SkillDefinition, SkillTiming, SkillUpgrade, effects/, slots
│  ├─ progression/          Milestone, Condition, modifiers/ (ParamOverride, TagFilter, ConditionalStat,
│  │                        GrantSkill, ChainWindow, MoveRule), ProgressionRules
│  ├─ story/                StoryBeat, BeatStep types, DialogueLine, CharacterDefinition, AmbientLines, Ending
│  ├─ world/                WorldDefinition, RulePage, RoomObjective, WorldGraph
│  └─ feel/ audio/          FeelProfile, SoundBank, MusicCues, DifficultyProfile
│
├─ ecs/                     THE SIMULATION: rules only; no art, prose or tuning numbers
│  ├─ core/                 EcsWorld, EcsSystem, EcsGrid, WorldFlags, InputSnapshot, PlayerSnapshot, HudSnapshot
│  ├─ components/           ecs_components.gd (frozen) + every NEW component in its own file with a KEY const
│  ├─ systems/<phase>/      command/ input/ decide/ world/ move/ act/ resolve/ progress/ view/
│  ├─ events/events.gd      every event name, payload keys, and emit_* helpers (emit_damage)
│  └─ schedule/             one file per phase + schedule.gd that concatenates them in order
│
├─ authoring/               THINGS YOU DRAG INTO A SCENE: Inspector data + apply(); no logic
│  ├─ ecs_boot.gd           THE baker (reads a room scene, builds the world; takes an options object)
│  ├─ ecs_actor_factory.gd  builds actor entities from definitions (kept)
│  ├─ entity_components/    today's *_component.gd EntityComponent nodes (names unchanged)
│  ├─ markers/              zone_entry, zone_exit, gate, blocker, trigger, grant, pickup_spawn, traversal_gap,
│  │                        state_variant, story_anchor, rule_mark, seal
│  └─ room_encounter.gd/.tscn
│
├─ presentation/            HOW THE WORLD IS SHOWN: reads events and the HudSnapshot, never decides
│  ├─ views/                actor_view.gd, actors/ (actor_view_base.tscn and the thin inherited scenes), pickup view, vfx scenes
│  ├─ ui/                   hud/ (ONE SCENE PER WIDGET: courage, rank tally, skill slots, believe, objective,
│  │                        boss bar), dialogue_box/, prompt/, codex/ (Book)
│  ├─ board/ camera/ audio/ text/ (text_service.gd is the only tr() caller)
│  ├─ story/                story_director, beat_player, cinematic_stage, child_hand_presenter
│  ├─ vfx/                  juice_director
│  └─ bridges/              event_router + small handlers (hud, audio, camera, board, dialogue, save)
│
├─ shell/                   THE GAME AROUND THE GAME
│  ├─ app_root.tscn/.gd     main scene: flow, transition, music, pause
│  ├─ game_root.tscn/.gd    in-game scene (replaces main): builds the world from the schedule, ticks it. Target 150 lines, zero rules
│  ├─ content/              content_db.gd (a static class, not an autoload)
│  ├─ input/                input_poller.gd (fills the InputSnapshot)
│  ├─ title/ pause/ settings/ credits/
│  └─ save/                 save_service (autoload), migration
│
├─ assets/                  shared raw art/audio not owned by one content item
│  ├─ tiles/ ui/ fonts/ music/ sfx/ concept-art/ _templates/
│  ├─ _source/              layered masters (.gdignore)
│  └─ _generated/           generator output (gitignored, never hand-edited)
├─ tools/                   generators, room builder, validators, migration scripts (never shipped)
├─ tests/                   support/ (unbound_test.gd, paths.gd) · architecture/ · bridge/ · ecs/ · content/ ·
│                           playthrough/ · perf/ · fixtures/ (the_kingdom, first_encounter, definitions) ·
│                           baselines/ · baseline_labels.txt · label_renames.txt
├─ docs/                    ARCHITECTURE.md · OWNER_GUIDE.md · requirements_ledger.md · design/ · archive/
└─ addons/                  third-party only; empty (any addition needs owner approval)
```

### 13.3 Conventions

- **Folder = id**. `ContentDb` derives the id from the folder name, so the id is spelled in one place. A test forbids duplicate ids per kind. Ids that appear in flags and conditions are declared in `flags.tres`, and `ContentDb.validate_cross_refs()` fails on a reference to a missing id.
- **Reference by id in code, by uid in scenes**. The only hard-coded content path is the `world.tres` constant in `ContentDb`.
- **File naming**: snake_case files, PascalCase classes, suffix by role: `*_system.gd`, `*_effect.gd`, `*_handler.gd`, `*_marker.gd`, `*_bridge.gd`. The editor nodes in `authoring/entity_components/` keep their `*_component.gd` names and the `EntityComponent` base (`CLAUDE.md` names them). The folder says which kind of "component" it is: `ecs/components/` is runtime data, `authoring/entity_components/` is editor nodes.
- **One Resource class per file**; never inner-class Resources. Every schema class has `##` docs on each `@export` and a `validate()` run by a test over every file `ContentDb` finds.
- **Components** are nouns of pure data. Every NEW component gets its own file with a `KEY` const. `ecs_components.gd` is frozen except for edits to existing classes; its inner classes migrate only when touched (193 `EcsComponents.` references in 22 files today).
- **Systems**: one rule per file with a `##` header (reads, writes, emits), a `PHASE` const, no calls to other systems, no node API outside `systems/view/`. `test_schedule_complete` fails if a `*_system.gd` is not listed exactly once in `ecs/schedule/`.
- **Events** are past-tense snake_case, declared once in `events.gd` (19 types exist today, matched in `main.gd:156-193` for only 15 of them). A lint greps emitted `&"type"` strings against the file.
- **One value, one home**: anything tunable lives in `content/` (`rules.tres` holds the economy values: Believe max and refill rules, shards per Courage, max Courage, stagger time, telegraph floor, assist thresholds, ambient-line cooldown); code holds structural constants only.
- **Art names are roles** (`body.png`, `icon.png`, `background.png`, `portrait_<emotion>.png`).
- **Moves and renames are scripted, not done in the editor dock**: workflow agents cannot drive the FileSystem dock, and UIDs protect only scene and resource references. `tools/move_res.py` does `git mv` for the file and its `.uid`/`.import` sidecar and rewrites every `res://` string in `*.gd`, `*.tscn`, `*.tres`, `project.godot`, `*.cfg` and `*.md`, then runs the import pass. Moves are committed separately from edits, one folder per commit. About 40 `res://` string literals in `.gd` files are not UID-protected (23 in `tests/run_tests.gd`, `scripts/combat/enemy_weapon.gd:35,39`, the `tools/*.gd` constants), which is exactly what the script rewrites.
- **Sidecars**: every tracked `.gd` has a tracked `.gd.uid`, and every tracked PNG/WAV has a tracked `.import` (`test_sidecars_tracked`). Run the import pass before each commit.
- **Naming rule** (`CLAUDE.md`): self-documenting names; dictionaries state direction.
### 13.4 System phases (order is data in `ecs/schedule/<phase>.gd`)

One file per phase stops six milestones editing one list. `schedule.gd` concatenates the phases in this order. Systems carry a `PHASE` const, and `test_schedule_order` asserts the final order.

1. `command/CommandSystem` (head: drains `world.commands`)
2. `input/PlayerInputSystem` (reads the `InputSnapshot`)
3. `decide/EnemyAISystem` (one owner across M8a-M13)
4. `world/CellEffectSystem`
5. `move/MovementSystem`
6. `act/SkillSystem` (+ effect handlers; `CombatSystem` runs beside it until the M7b parity cutover)
7. `act/StatusSystem`
8. `resolve/HealthSystem`
9. `resolve/KnockbackSystem`
10. `world/InteractionSystem` (hold-E timers, rescues, Book margins)
11. `world/TriggerSystem`
12. `world/ObjectiveSystem`
13. `progress/BossPhaseSystem`
14. `world/CheckpointSystem` (refills, death handling, `respawn_requested`)
15. `progress/ProgressionSystem` (milestones, Margin, counters, DirectionLock restore)
16. `progress/StoryBeatSystem`
17. `view/HudSnapshotSystem` (builds the read-only DTO)
18. `view/ViewSyncSystem` (last)

### 13.5 OWNER CHANGE TABLE

"Files" counts new and edited files honestly, including `.po` rows and a room edit. "Code?" says whether a script must change. The dry-run test (`test_change_table_dry_run`) walks **every** row on a temp copy of `content/` under `user://change_table_dry_run/`, applies the edit and diffs afterwards; it never touches the working tree, so an aborted run leaves the repo clean.

| Owner wants to | Edit this | Files | Code? |
|---|---|---|---|
| Add a variant enemy (re-skin, new health, speed or weapon) | `content/enemies/<id>/enemy.tres` (reusing `_shared` sub-resources), `body.png`; in a room, instance `actor_view_base.tscn` and set `definition`; the `ENEMY_<ID>_NAME` row in `story/text/<locale>/story.po`. | 4 | no |
| Add an enemy with new behaviour | `enemy.tres` + one `EntityComponent` or `AttackBase` script + one system file + one line in `ecs/schedule/<phase>.gd`; plus `events.gd` if it emits a new event and `ViewSyncSystem` if its visuals are new. | 4 new, up to 3 existing edited | yes |
| Retune an enemy or boss | its `.tres` | 1 | no |
| Add a skill in an existing slot from existing effect kinds | `content/skills/<id>/skill.tres`, `icon.png`, one `milestones/<id>.tres`, three rows in `skills.po` (name, description, hint), a `sound_bank.tres` row if the sound is new. HUD slot, input and cooldown bar come from the file and `slots.tres`. | 4-5 | no |
| Add a skill that needs a free button | the above + one `InputMap` action in `project.godot` + one `slots.tres` row | 6-7 | no |
| Add a skill needing a new effect kind | effect schema + handler + one line in `ecs/schedule/act.gd` + `skill.tres` + milestone + `.po` rows (Chalk Block is the worked example) | 7-9 | yes |
| Retune a skill | `skill.tres` | 1 | no |
| Change when or how a skill is earned | the milestone `.tres` (trigger kind: boss_defeated, room_cleared, grant_marker, flag). Moving a physical marker = delete in room A + add in room B. | 1-2 | no |
| Add or edit a Book page whose modifier kind already has a handler | `content/rules/<id>/page.tres` + rows in `story.po` | 2 | no |
| Add a Book page that needs a new modifier kind | modifier schema + handler + schedule line + `page.tres` | 4-5 | yes |
| Add an Annotation (a `SkillUpgrade`) | the upgrade row on `skill.tres` + `.po` rows | 2 | no |
| Rewrite a line of story, UI text or a name | one `msgstr` in `story/text/<locale>/*.po` (soft lints only warn in the editor) | 1 | no |
| Add a language | `story/text/<locale>/{story,ui,skills,rooms}.po` + register them in `project.godot` | 5 | no |
| Rename a character | the `CHAR_<ID>_NAME` row | 1 | no |
| Add a conversation, ambient line or prompt | a beat `.tres` (or a line in `script/<act>.txt` + `tools/build_beats.gd`) + its `.po` rows | 2-3 | no |
| Stage a cutscene | beat `.tres` files + `.po` rows + a `TriggerMarker` in the room + `sound_bank` rows + `characters/<id>.tres` if there is a new speaker (+ a `cutscene.tscn` for a Tier-2 cutscene) | 5-7 | no |
| Add a room | `room.tscn`, `background.png`, one exit marker in the neighbouring room, a `world.tres` entry (map slot), `.po` rows (name, start message, what happened here, locked message) | 5-6 | no |
| Change a room's enemies or layout | that `room.tscn` | 1 | no |
| Change a lock or add a shortcut | the exit or gate marker in `room.tscn` + the `locked_message` row | 2 | no |
| Add a prop that appears after a condition | a `StateVariantMarker` on the prop in `room.tscn` | 1 | no |
| Change the hub evolution or ending variants | `StateVariantMarker` props in H1's `room.tscn`, `ending.tres` | 1-2 | no |
| Add a pickup, shard or keepsake | `pickup.tres`, `pickup.png`, a spawn in `room.tscn`, a `.po` row (+ a milestone row if it grants) | 4-5 | no |
| Add an NPC or rescue | a prop with an `InteractComponent`, a beat, a flag in `flags.tres`, `room.tscn`, `.po` rows | 5 | no |
| Add a boss | `boss.tres`, `enemy.tres`, `body.png`, the arena `room.tscn`, beats + `.po` rows, a milestone row, a `music_cues` row | 7-10 | no, if its attacks use existing kinds |
| Add or retune a boss phase | `boss.tres` (a new windup clip also edits the boss's actor scene) | 1-2 | no |
| Swap a sprite | overwrite `body.png`, drawn at scale 1 on the 32x32 canvas of `docs/assets` with the drawn pixels inside the box of its kind in `content/feel/piece_sizes.tres` (+ `VisualDefinition.anchor_offset` to nudge it); the placeholder flag clears by hash | 1-2 | no |
| Change how big a kind of piece is inside its cell | `content/feel/piece_sizes.tres` (a row's `body_box`, `base_offset_y`, `footprint_cells`); `validate()` keeps the 2 px margin and the chess height order | 1 | no |
| Swap a room's art | overwrite `background.png` | 1 | no |
| Swap a portrait, UI skin or font | overwrite the file in `content/story/characters/`, `content/ui/theme/`, `assets/fonts/` | 1 | no |
| Add music or change which track plays | drop the file in `assets/music/` + a row in `music_cues.tres` | 2 | no |
| Add or swap an event sound (pickup, jingle, UI) | drop the file + a row in `sound_bank.tres` | 2 | no |
| Swap a motion sound or edit an animation clip | an **editor task** in `presentation/views/actors/actor_view_base.tscn` (changes every actor that inherits it) or in a bespoke inherited view; how fast a clip plays for one kind of piece is `clip_speed_scales` in its `visual.tres`, no scene edit | 1 scene | no |
| Change the HUD layout | the widget scene in `presentation/ui/hud/` | 1 | no |
| Tune difficulty or assists | `content/difficulty/<profile>.tres` (global health and damage multipliers live here); for one enemy, its `enemy.tres` | 1 | no |
| Tune game feel (shake, flash, hit-stop, telegraph colours, chord window) | `content/feel/feel_profile.tres` | 1 | no |
| Change how the pawn feels (step time, courage, invulnerability) | `content/player/player.tres` | 1 | no |
| Change economy rules (Believe, shards, stagger, assist thresholds) | `content/progression/rules.tres` | 1 | no |
| Change input defaults | the `[input]` section of `project.godot` | 1 | no |
| Change title text or credits | `credits.tres` + `.po` rows | 2 | no |
| Add a new floor mechanic (spikes, switch) | marker + component + system + one schedule line (+ an event) | 4-5 | yes |

### 13.6 Safe migration from today's layout

| Today | Becomes | Via |
|---|---|---|
| `scripts/data/*`, `scripts/combat/*`, `scripts/ai/*` | `schema/*` | M1b scripted move, no logic edits |
| `scripts/ecs/ecs_world.gd`, `ecs_grid.gd`, `ecs_system.gd` | `ecs/core` | M1b |
| `scripts/ecs/ecs_components.gd` | `ecs/components/ecs_components.gd` (frozen) | M1b |
| `scripts/ecs/systems/*` | `ecs/systems/<phase>/` | M1b |
| `scripts/ecs/ecs_boot.gd`, `ecs_actor_factory.gd` | `authoring/` | M1b |
| `scripts/ecs/components/*_component.gd` (EntityComponent nodes) | `authoring/entity_components/`, names unchanged | M1b |
| `scripts/ecs/actor_view.gd` | `presentation/views/actor_view.gd` | M1b |
| `scripts/world/*` markers, `objects/markers/*` | `authoring/markers/`, `authoring/room_encounter.gd` | M1b |
| `scripts/ui`, `scripts/visuals`, `scripts/audio`, `camera_rig`, `prototype_board` | `presentation/*` | M1b |
| `scripts/main.gd`, `scenes/main.tscn` | `shell/game_root.gd/.tscn` (body untouched, split in M3b) | M1b, M3b |
| `scripts/world/world_state.gd` | `shell/save/save_service.gd` + `ecs/core/world_flags.gd` | M3b |
| `resources/enemies/*`, `movement`, `attacks`, `decisions`, `visuals`, `difficulty` | `content/enemies/<id>/`, `content/enemies/_shared/`, `content/difficulty/` | M1b, regrouped in M2 |
| `resources/rules/*` | `content/rules/<id>/page.tres` | M1b, M7c |
| `resources/world/world_graph.tres` | `content/world/world.tres` | M5 |
| `objects/actors/*.tscn` (4 copies of 353 lines) | `presentation/views/actors/actor_view_base.tscn` + four thin inherited scenes beside it (as built in M2; a new enemy needs no scene, and `content/enemies/<id>/actor.tscn` is the home of one only if a piece ever needs its own) | M2 |
| `scenes/rooms/*.tscn` | `content/rooms/<id>/room.tscn` (`first_encounter` moves to `tests/fixtures/`) | M1b |
| `scenes/zones/the_kingdom.tscn` | `tests/fixtures/the_kingdom.tscn` (with its tilemaps and tilesets) | M1b |
| `scenes/ui/*`, `objects/audio/sfx_manager.tscn` | `presentation/ui/`, `presentation/audio/` | M1b |
| tracked sprites in `assets/sprites/generated/` (12 files) | `content/<kind>/<id>/body.png` | M1b |
| `assets/sprites/generated/{chess,tiles,maps,rooms}` (gitignored) | `assets/_generated/` | M1b + `.gitignore` + tool OUT_DIR |
| `tests/*` | `tests/{architecture,bridge,ecs,content,playthrough,perf,fixtures}/` under the runner | M1a |

**Safety rules**:
- Stamp UIDs first with `tools/stamp_uids.gd` (213 of 251 `ext_resource` lines are path-only today, so a plain move breaks every scene and resource that names them).
- Move only with `tools/move_res.py`, one folder per commit, with the full suite and the deterministic dump run after each.
- Do the migration in a separate worktree while the owner is not editing, tag every milestone (`m1a-done`, ...), and keep the `pre-restructure` tag. If the owner edits a `.tscn` during M1b, the owner's changed files are fed to `move_res.py --rewrite-only <files>` after the rebase instead of hand-merged.
- `EcsActorFactory` is kept (D-28); only the four duplicated actor scenes are collapsed, behind a golden oracle (§15 M2).

### 13.7 Migration and test tooling (specified once, used by every milestone)

- **`tools/stamp_uids.gd`**: text-level, never calls `ResourceSaver`. Pass 1 adds `uid="uid://..."` (from `ResourceUID.create_id()` / `id_to_text`) to every uid-less `.tscn`/`.tres` header. Pass 2 adds `uid=` to path-only `ext_resource` lines, taking it from the target's header, its `.gd.uid` or its `.import`. It is idempotent, supports `--check`, and runs after every generator. A prototype stamped exactly 213 lines with no misses and a one-to-one line diff, and the scenes still resolved after folders moved.
- **Why not the editor UID tool or the `update_project_uids` MCP tool**: a headless `ResourceLoader.load` plus `ResourceSaver.save` over all 66 scenes and resources added 0 uids and turned 38 more lines path-only (213 to 251 of 251), dropped the header uid of `scenes/main.tscn`, and changed 587 non-uid lines (`format=4` became `format=3`). Do not use it. The repo's own `tools/paint_kingdom_tilemap.gd:57`, `paint_zone_tilemaps.gd:394` and `generate_playground_tilemap.gd:50` use `ResourceSaver` and produce uid-less scenes, so each runs the stamper last (or writes text).
- **`tools/move_res.py`**: described in §13.3. It also supports `--rename-action` for the `skill_1` rename and `--rewrite-only`.
- **`tests/support/paths.gd`**: the only place tests name a `res://` path, and it asserts `FileAccess.file_exists`. Every file-read check also asserts non-empty content. A stale path otherwise makes `FileAccess.get_file_as_string()` return `""` and "actor views hold no logic at all" (`tests/run_tests.gd:103`) still prints PASS, and the first stale `load()` (`run_tests.gd:124`) raises a script error that hangs the Godot process.
- **`UnboundTest`** (`tests/support/unbound_test.gd`, `class_name UnboundTest extends SceneTree`): `_expect`, `soft_expect`, a 30 s watchdog timer that quits 1, `finish()`, and a default frame await.
- **`tools/run_all_tests.py`**: runs the import pass first, then each suite as its own subprocess (`subprocess.run(timeout=60)`) with `HOME=/tmp/unbound-pawn-godot`, and fails on any `SCRIPT ERROR`, `Parse Error` or non-zero exit. `--strict` promotes soft warnings to failures. Content lints assert a minimum file count so zero files cannot pass vacuously.
- **Baseline-label manifest**: M1a captures every `PASS:` label the current suites print into `tests/baseline_labels.txt`. A milestone may retarget setup and call sites, but every baseline label must still print PASS or be listed with its replacement in `tests/label_renames.txt`. This replaces the draft's unprovable "tests unchanged".
- **Deterministic dump**: `tools/dump_world.gd` boots a room headless, runs N manual ticks and prints sorted node paths, sprite texture paths and entity cells. M1a and later milestones compare it with `tests/baselines/dump_<room>.txt`. Screenshots are owner-review artefacts, not gates.
- **`tools/bootstrap_worktree.sh`**: runs the generators and the import pass, so a fresh clone or parallel worktree has the generated art and the sidecars.
- **Architecture tests** (`tests/architecture/`): `test_dependency_edges`, `test_no_path_only_ext_resource` (zero path-only `ext_resource` lines), `test_sidecars_tracked`, `test_content_has_no_gd` (with a minimum file count), `test_schedule_complete`, `test_events_declared`, `test_ids_unique`.
## 14. Architecture

### 14.1 Autoloads, scenes, core

| Item | Role | New or changed |
|---|---|---|
| `SaveService` (autoload) | slots (a slot-aware API with one slot), flags, migration, `request_save(reason)`, an injectable save root | replaces `WorldState` |
| `Sfx` (autoload) | the existing `SfxManager`; the registry now comes from `sound_bank.tres`; tolerates absence in `_init`-time tests | changed |
| `ContentDb` (static class in `shell/content/`) | lazy id cache over `content/**` using `ResourceLoader.list_directory`; skips `_*`; scenes load on demand, never all 34 at startup; `validate()` and `validate_cross_refs()` are called by tests and the editor tool, not at process start; falls back to `content/_index.json` (written by `tools/build_content_index.gd`) in an exported build | new |
| `AppRoot` + `GameFlow` | flow, transition, music, pause, settings, respawn handling | new |
| `game_root` | builds the world from the schedule, ticks it, owns the `InputPoller`, hands events to `EventRouter` | replaces `main.gd` (605 -> about 150 lines) |
| `EcsWorld` | adds `frozen`, `flags` (WorldFlags), `view_commands`, `commands`, `tuning`, `input_snapshot`, `hud_snapshot`, the heal queue | changed |
| `EcsGrid` | `cell_kind_by_cell`, `begin_leap`, `ray_cells`, `layout_version` with a cached `AStarGrid2D`, generic `marker_by_cell[kind]`, `cell_effects`, per-room `grid_origin` | changed |
| `EcsBoot` | takes an options object instead of 3-6 positional arguments (the call sites at `room_encounter_runtime_test.gd:35,92`, `zone_travel_runtime_test.gd:31` and `run_tests.gd:224` are retargeted in M3a); markers bake themselves | changed |

`systems.size() == 6` (`encounter_hud_runtime_test.gd:42`) is retargeted to `test_schedule_complete` in M3a. It was a pin on the old count, not behaviour.

### 14.2 New components (each its own file with a KEY const) and the player carry contract

New components: `SkillBook`, `SkillCast`, `Status` (guard, untargetable, in_check, stagger, help_disrupted), `Believe`, `Loadout`, `DirectionLock`, `BossState` (including `active_rule_modifier`), `TriggerWatch`, `Knockback`, `FlagVisible`, `Tuning`, `InteractionState`. (`RestState` and `PassantWindow` are cut with the Rest Square and In Passing.)

`_boot_zone` (`main.gd:64-101`) builds a fresh `EcsWorld` for every room, and today only the integer `player_health_carry` survives (`world_state.gd`). The draft never said what survives a room change. The contract is a **`PlayerSnapshot`** resource, captured by `game_root` at room exit and applied right after `EcsBoot.boot`. `test_player_carry_roundtrip` runs two zone swaps and compares every row of this table.

| State | Class | Across a room change |
|---|---|---|
| Courage current and max | persistent | carried (refilled at checkpoints) |
| Believe current | persistent | carried and saved |
| `SkillBook` unlocked ids, applied upgrades | persistent | derived from flags and saved |
| `SkillBook` cooldowns | per-room | reset to 0 on room load |
| `Loadout` (equipped pages, Margin) | persistent | carried and saved |
| `DirectionLock` (Act 6) | persistent for the act | carried and saved |
| `Status` (guard, untargetable, in_check, stagger, invulnerability, help_disrupted) | per-room | reset |
| `SkillCast`, attack lock, attack token, telegraphs | per-encounter | reset |
| Hit progress toward Believe (1 of 3) | per-room | reset |
| Floor weapon held | per-room | reset (room-local) |
| `child_calls_used`, `child_trust`, shard count, deaths, flags | persistent counters in `WorldFlags` | carried and saved |
| Cell effects (chalk), the raised Block | per-room | cleared |
| Facing | per-room | set by the entry marker |

### 14.3 Events (declared in `ecs/events/events.gd`)

**Existing (19 distinct types emitted today)**: `step_started`, `step_finished`, `step_blocked`, `intent_changed`, `attack_started`, `attack_locked`, `attack_landed`, `attack_resolved`, `telegraph_started`, `telegraph_finished`, `damaged`, `defeated`, `pickup_taken`, `weapon_changed`, `skill_cooldown`, `player_unlock`, `gate_opened`, `zone_exit`, `zone_exit_locked`. (`main.gd:156-193` matches only 15 of them. The draft said 18.)

**New**: `attack_progress`, `skill_cast_started`, `skill_unlocked`, `believe_changed`, `page_equipped`, `rank_changed`, `milestone_reached`, `story_trigger`, `flag_set`, `boss_engaged`, `boss_phase_changed`, `boss_defeated`, `cell_effect_started`, `cell_effect_ended`, `child_intervened`, `child_help_disrupted`, `direction_locked`, `direction_restored`, `healed`, `knocked_back`, `rescue_completed`, `checkpoint_set`, `room_cleared`, `perfect_rub`, `guard_blocked`, `respawn_requested`, `ending_reached`.

**Damage payload**: `{target, source, amount, direction, tags}`. `direction` already exists (`combat_system.gd:80-84`, `enemy_ai_system.gd`, `health_system.gd:15`). `source` and `tags` are new, and R8, R10 and R14 need `source`. Every producer calls `Events.emit_damage(...)`, never builds the dictionary by hand, so the retrofit is one change in M3a. A lint greps the emitted types against `events.gd`.

### 14.4 Presentation classes

`EventRouter` plus handlers (`HudBridge`, `AudioBridge`, `CameraBridge`, `BoardBridge`, `DialogueBridge`, `SaveBridge`), `StoryDirector`, `BeatPlayer`, `CinematicStage`, `ChildHandPresenter`, `DialogueBox`, `PromptWidget`, `BossBar`, `RuleBookUI v2`, `ControlsPanel`, `JuiceDirector`, `MusicDirector`, `TextService`, `PauseMenu`, `SettingsMenu`, and one scene per HUD widget. `WorldMapScreen` is deferred.

### 14.5 Hot spots

| Hot file | Why | Rule |
|---|---|---|
| `ecs/core/ecs_world.gd`, `ecs_grid.gd` | every system uses them | **every world field lands in M3a in ONE commit**: `frozen`, `flags`, `view_commands`, `commands`, `tuning`, `input_snapshot`, `hud_snapshot`, the heal queue, cell kinds, `cell_effects`, `layout_version`. Later milestones add behaviour, not fields. |
| `ecs/components/ecs_components.gd` | every lane adds state | frozen; new components get their own file |
| `ecs/systems/decide/enemy_ai_system.gd` (337 lines) | every enemy family changes the brain and the telegraph event shape | one owner for M8a-M13; extend through `AttackStage` data |
| `resolve/health_system.gd`, `move/movement_system.gd` | guard and untargetable (M7a), knockback and death freeze (M8c) | one owner per milestone; extend through data and components |
| `view/view_sync_system.gd` (185 lines) | `view_commands`, guard and flight visuals, flash, generic `anim_state` | seam edits land in M3a and M7a; later milestones use data |
| `shell/save/save_service.gd` | one owner | |
| `presentation/ui/hud/*` | six milestones touched `hud.tscn` (M4, M6, M7, M8, M10, M12) | **each HUD widget is its own scene** (M4), instanced by `game_root` |
| Book UI | M6 (Book v2 shell), M7c (equip), M11 (Pages tab) | sequential, one owner at a time |
| `presentation/board/prototype_board.gd` (235 lines, the telegraph language) | edited in M8c, M10 (chalk), M13 (corruption) | M8c turns it into a registry that draws by cell kind, so later milestones add data, not code |
| `ecs/schedule/<phase>.gd` | every system adds a line | one file per phase |
| `ecs/events/events.gd` | everyone adds events | append inside your own banner; `test_events_declared` |
| `project.godot` | the editor rewrites it | commit only what you changed; input action edits belong to M4 and M7a |
| `content/story/text/<locale>/*.po` | all lanes add keys | per-domain files and per-lane key prefixes |
| `tests/` | everyone adds suites | new suites in new files; the runner discovers them |
| `progress.md`, `task_plan.md`, `findings.md` | append-only logs | per-lane fragments in `docs/progress/`, merged by one integrator |
| Parallel worktrees | each needs the generated art and an import pass | `tools/bootstrap_worktree.sh` |

Because M3a lands every shared field and M4 splits the HUD, the schedule and the `.po` files, M6 (story) and M7a (skills) can run as two lanes with disjoint file ownership. Without those landing first they must run sequentially.
## 15. Milestones

Each milestone is one implementation workflow with checkpointed commits, tagged `m<N>-done`. Every commit keeps `python3 tools/run_all_tests.py --strict` green and every baseline label passing (or renamed in `tests/label_renames.txt`). Sizes: S/M/L. The reviews found that 14 milestones could not carry the scope, so there are now **20**, and the sizes are honest: the old M7 (a skill engine, a combat cutover, a progression system, Pages and Margin) is three milestones; the old M8 (attack kinds, bosses, feel, death flow) is three; and M9-M11 are relabelled L.

Order: tooling and approval first (M1a, OG0), the scripted folder migration (M1b), the content registry and actor collapse (M2), runtime seams landed once (M3a, M3b), shell, input and text (M4), the playable start-to-end skeleton (M5, OG1), story (M6) and skills (M7a-c, OG2) before any new district, the attack and boss frameworks (M8a-c), then one district per milestone (M9-M13), then completeness (M14).

**Owner gates.** OG0 is an approval gate; OG1-OG4 are play gates. At each, the owner can veto cheaply. If the owner does not respond, agents continue on the stated defaults and log the assumption in `progress.md`.

| Gate | When | What the owner checks |
|---|---|---|
| OG0 | End of M1a, before M1b | The `CLAUDE.md` diff (§2.4), the standing-rule table (§2.3), the migration plan. The `pre-restructure` tag exists, so everything is revertible. |
| OG1 | After M5 | Plays title to credits (about 10 min) through stub rooms: does the skeleton feel right? |
| OG2 | After M7b | The feel: Sword, Pencil, Rule Step, movement lock, stagger, buffer expiry in a sandbox room. Feel-critical rules land here and everything after depends on them. |
| OG3 | After M9 | Stage 1 plus Toybox, the first complete district. |
| OG4 | After M13 | The whole game, before the handoff polish. |

### M1a: Safety net and tooling (M)

- **Scope (Tier A)**:
  1. Worktree, branch `base/m1a`, tag `pre-restructure`, baseline numbers from `/verify`. Copy `reqs.json` to `docs/requirements.json`; write `docs/requirements_ledger.md` (§1.5) and `tests/content/test_requirements_ledger.gd`.
  2. The test harness of §13.7: `UnboundTest`, `tools/run_all_tests.py`, `tests/baseline_labels.txt` (captured from every current `PASS:` label), `tests/label_renames.txt`, `tests/support/paths.gd`. Fix `/verify` so it runs the runner and includes `zone_travel_runtime_test` (the project's own `/verify` omits it).
  3. **Bridge characterization tests**, landed against the CURRENT `main.gd` before any port: `test_bridge_travel` (drive `main._travel_to` through an exit cell, assert the zone swap, the entry cell and that the health carry is consumed; `zone_travel_runtime_test.gd` never calls `_travel_to`), `test_bridge_death_respawn` (death reboots the same zone), `test_bridge_persistence` (pickups, gates and unlocks persist across `_boot_zone`), `test_bridge_book` (the Book blocks control), `test_bridge_health_carry`.
  4. `tools/stamp_uids.gd` (+ `--check`), `tools/move_res.py`, `test_no_path_only_ext_resource` (report-only until M1b stamps), `test_sidecars_tracked`.
  5. Fix the bus layout: Master as bus 0, then SFX / Music / UI / Voice, and `test_audio_buses`.
  6. `tools/dump_world.gd` and baselines for all six Stage-1 rooms and H1. Check whether a real-renderer boot runs in the agent sandbox; record yes or no (G7 depends on it).
  7. Architecture guards in report-only mode: the allowed-edge table derived from the real `class_name` graph (§13.1).
  8. Docs truth: rewrite `ARCHITECTURE.md`, `coding-standards.md`, `AGENTS.md`, `README.md` and `.claude/commands/*`; archive `restructure-plan.md`; add an `OWNER_GUIDE.md` stub; amend `findings.md:45-51` (D-08); rewrite or archive the stale authoring docs (`docs/design/room-authoring-guide.md`, the asset-import and tile-editing docs, `docs/room-generator*.md`, the vault); write `docs/claude-md-diff.md` (§2.4).
  9. `tools/bootstrap_worktree.sh`; `LICENSE` and a `THIRD_PARTY_NOTICES.md` stub.
- **Tier B**: a CI workflow draft.
- **Acceptance**: the runner is green on the unchanged tree and every baseline label is captured; the bridge tests are green against the current `main.gd`; the stamper stamps 213 lines with zero missing on a scratch copy and the scene diff is one-to-one; `test_audio_buses`; the ledger test; dump baselines recorded.
- **Owner can try**: `/verify` as one command; read the `CLAUDE.md` diff.
- **Dependencies**: none. **OG0 follows.**

### M1b: Folder migration (L, mechanical)

- **Scope**: run `tools/stamp_uids.gd` over the whole tree and commit that alone; then move code and content in the §13.6 order, leaf-first, **one folder per commit** with `tools/move_res.py`, running the suite and the dump after each; the fixtures (`the_kingdom` with its tilemaps and tilesets, and `first_encounter`) move to `tests/fixtures/`; `project.godot` main scene and autoload paths; generator output to `assets/_generated` with `.gitignore` and tool `OUT_DIR` updated; `tools/seed_placeholders.gd` and `content/_placeholders.json`; every `tools/*.gd` that uses `ResourceSaver` runs the stamper last; architecture guards switch from report-only to enforcing rule by rule as each lands.
- **Files**: the whole tree; `project.godot`.
- **Acceptance**: `run_all_tests.py --strict` green with **every baseline label passing or renamed**; import clean (no ERROR or Parse); `grep` for `res://scripts|objects|scenes|resources` returns 0 outside `docs/archive`; zero path-only `ext_resource` lines; `test_sidecars_tracked`; `content/` contains 0 `.gd` with a minimum file count; the deterministic dump equals the baseline for each Stage-1 room and H1.
- **Owner can try**: play exactly as before; browse `content/`; read `docs/OWNER_GUIDE.md`.
- **Dependencies**: M1a and OG0. Done in a separate worktree while the owner is not editing (§13.6).

### M2: Content registry and actor collapse (M)

- **Scope (Tier A)**: `ContentDb` as a static class with a lazy id cache and `validate()` / `validate_cross_refs()`; `PlayerDefinition` and `content/player/player.tres` (courage, invulnerability, step and hold timings move out of `player.tscn` exports; `EcsBoot` bakes from it and a node on the instance still wins); enemies regrouped into `content/enemies/<id>/` with `_shared/`; **one `actor_view_base.tscn` plus thin inherited scenes** replacing the four 353-line copies, with the body texture and anchor in `VisualDefinition` and clip speed scales as data; `/new-enemy` rewritten. The old `EcsActorFactory` stays.
- **Tier B**: sprite-sheet block and sound ids in `VisualDefinition`.
- **Acceptance**: `test_actor_collapse_golden.gd` (per actor, the node paths and every baked component field equal the old scene's, and the per-room entity set and cells equal the pre-port dump); `test_validate_all.gd` (every definition passes `validate()`, ids equal folders, no duplicates, minimum count); `test_content_db_in_init.gd` (the registry works inside a `_init`-time suite with no autoloads); baseline labels intact.
- **Owner can try**: add `content/enemies/test_pawn/enemy.tres` reusing `_shared` (HP 5), instance `actor_view_base.tscn` into `dev_sandbox` and set `definition`; swap `body.png`. A playable checkpoint: T1 to H1 equals the baseline.
- **Dependencies**: M1b.
- **Also built in M2 (the owner's decision of 2026-10-12, `docs/owner-decisions.md`)**: a piece is smaller than its cell. The size table `content/feel/piece_sizes.tres` (`PieceSizeTable` and `PieceSize` in `schema/feel/`, `ContentDb.piece_sizes()`), the placement and the in-cell geometry of `actor_view_base.tscn`, the owner-approved generated chess family drawn to the table and seeded into `content/<kind>/<id>/body.png` as placeholders, `tools/render_actor_preview.gd`, `test_pieces_inside_cell`. It reverses `task_plan.md` phase 66, and §12 states the new rule.
- **After the review of M2 (fix round)**: the owner's request list (`docs/assets`) asks for every piece on a 32x32 canvas, which M2's first contract (the whole PNG inside the box) rejected, so the canvas is now a body shape the game accepts and places exactly (`cell_canvas_base_row` 30 in the table, `box_on_cell_canvas`, `picture_problems`), the generator writes the four stand-ins as canvases, and `actor_view_base.tscn`'s `BodySprite` is the cell's own corner (-16,-16) so no thin scene repeats a position; the B1 captain lost its 1.18x scale and the in-cell test now boots every actor every room places; a hit's drawn shove is limited to the margin; the preview draws a gutter, keeps its lines under the pieces, paints crossings magenta and has a second picture of the placed actors; `VisualDefinition` lost five fields nothing read (`telegraph_color`, `impact_color`, `weapon_anchor`, `hurt_animation`, `defeat_animation`); `ContentDb.validate()` reports a reference Godot silently drops (a resource of the wrong class). Left to the owner or the integrator: the bishop is drawn 22 px against the knight's 24 (a real set has the bishop taller; the table puts knight, bishop and rook on one rung, as the task's suggested numbers did), the retraced knight and the new black pawn and bishop need the owner's yes, and the aura, arrow and pip sizes above.
- **As built, where it differs from the text above**: the thin actor scenes stay in `presentation/views/actors/` beside the base (not in `content/enemies/<id>/`, which keeps scene uids and test labels intact); the registry method is `fetch`, not `get` (a static `get` would override `Object.get`); `dev_sandbox` does not exist before M6, so the owner tries a new enemy by instancing `actor_view_base.tscn` in a room (the walk is recorded in `.claude/commands/new-enemy.md`, and a throwaway scene in the project root boots with `tools/dump_world.gd --room=res://<scene>`); the `content/_index.json` export fallback of §14.1 is not built. Counted by doing it: a re-skin that reuses `_shared` is 1 file, with a picture of its own 3 (`enemy.tres`, `visual.tres`, `body.png`), plus the room edit that places it.

### M3a: Runtime seams (L)

Every shared field lands in ONE milestone, so later lanes extend behaviour instead of fighting over `EcsWorld` (§14.5).

- **Scope**:
  - `EcsWorld` fields: `frozen`, `flags` (WorldFlags), `view_commands`, `commands`, `tuning`, `input_snapshot`, `hud_snapshot`, the heal queue. `CommandSystem` at the head of the schedule.
  - `ecs/schedule/<phase>.gd` and `schedule.gd`; `events.gd` with the 19 existing types, payload docs and `emit_damage()` (the `source` and `tags` retrofit across every producer, R8/R10/R14).
  - `InputSnapshot` and `InputPoller`; `PlayerInputSystem` reads only the snapshot with identical behaviour (the buffer expiry is a behaviour change and waits for M7b).
  - Grid: `cell_kind_by_cell`, the TileSet `kind` layer and the paint-tool support, `begin_leap`, `ray_cells`, `layout_version` with a cached `AStarGrid2D`, bounded attack-setup search.
  - `EcsBoot` options object, per-room centred `grid_origin`, `CameraRig` clamp; `PlayerSnapshot`; `HudSnapshot` and `HudSnapshotSystem`.
  - Retarget the old pins: the `EcsBoot` call sites (`room_encounter_runtime_test.gd:35,92`, `zone_travel_runtime_test.gd:31`, `run_tests.gd:224`) and the `systems.size() == 6` assertion (`encounter_hud_runtime_test.gd:42`).
- **Acceptance**: `test_schedule_order`, `test_schedule_complete`, `test_frozen_world`, `test_commands_channel`, `test_input_snapshot` (buffer, chord and tap window by injected snapshots), `test_grid_cell_kinds`, `test_leap_occupancy`, `test_ray_stops_at_blockers`, `test_events_declared`, `test_hud_snapshot`, `test_player_snapshot_roundtrip`, `tests/perf/test_room_tick_budget.gd` (18x9, 8 enemies, 2 ms or less `[start value]`); baseline labels intact or renamed.
- **Dependencies**: M2.

### M3b: Game root and save (L)

- **Scope**: the `game_root` split (about 150 lines) plus `EventRouter` and bridges, one responsibility per commit, with the old path kept until the ported bridge tests pass; `ObjectiveSystem` (room clear and defeat, from `main.gd:264-302`); `CheckpointSystem`; `WorldFlags` and `SaveService` v3 (one slot behind a slot-aware API, `[meta]`, checkpoint, `cleared_room_ids`, `defeated_boss_ids`, atomic write with `.bak`, migration from v2, `configure(root)` for tests, the profile file); a minimal `GameFlow` that handles `respawn_requested` and replaces both `reload_current_scene()` calls (`main.gd:120, 302`); checkpoint and death rules (D-16, D-17) with Courage and Believe refills; `PlayerSnapshot` used by the zone swap.
- **Acceptance**: the M1a bridge tests, ported to the new `game_root`, stay green; `test_save_roundtrip`, `test_save_migration_v2` (fixture), `test_corrupt_save_falls_back`, `test_checkpoint_rules`, `test_objective_system`, `test_player_carry_zone_swaps` (two swaps), `test_request_save_callers` (R17); architecture test: no direct `save_state()` outside `SaveService`; `game_root.gd` size lint.
- **Owner can try**: die and respawn on the entry of the room you fell in (a hub or boss door is a checkpoint and refills Courage, but nothing sends you back to it); cleared rooms stay cleared; quit and relaunch resumes in the room of the last save. (`docs/OWNER_GUIDE.md` section 7 lists the steps the rooms allow today; `test_owner_guide_steps` walks them.)
- **Dependencies**: M3a.
- **As built, step 1 of 3 (`base/m3b-1`, save v3 and world flags; the `game_root` split, `ObjectiveSystem`, `CheckpointSystem`, `GameFlow` and the death rules are steps 2 and 3)**:
  - `shell/save/`: `SaveService` (the autoload; `WorldState` and its test double are deleted, every caller migrated in the same commit), `SaveData` (the slot, as a `ConfigFile`: `[meta]` `[checkpoint]` `[world]` `[player]` `[flags]`), `SaveFile` (temp, verify, `.bak`, rename), `SaveMigration` (v2 to v3, tested on a real v2 file written by the old code), `SaveLoadResult`. Slot-aware (`slot_path(n)`), `configure(root)` for tests, the profile file (`completed`, kept by a New Game). The loader never wipes: file, `.bak`, the v2 `world_state.cfg`, a clean new game, each step logged with a notice key; a newer game's file is never read as damaged and never overwritten.
  - **Differs from 9.3 as written**: the file ends with an integrity footer (a ConfigFile comment holding a sha256), because `ConfigFile` prints an engine error on text it cannot parse and the strict runner fails on engine errors, so damage has to be recognised before the parser sees it. `[player]` does not store current Courage (health never saves; a checkpoint refills it).
  - `request_save(reason)` takes the success events of 5.2 plus two persistent unlocks (`unlock_gained`, `rule_page_unlocked`); everything else is refused. `test_request_save_callers` is the R17 caller list. **`checkpoint_reached` is interim**: until step 3 the shell reports every zone travel with it, because the checkpoint still moves on every travel. A death no longer writes the save (D-16, R17).
  - World flags are carried by the shell through room swaps, the file and a relaunch (`test_bridge_flags`); the `PlayerSnapshot` is in the file but the zone swap still carries a bare health integer (step 3).
  - Also landed with this step, left over from M3a: the generic `EcsGrid.marker_by_cell[kind]` of 14.1 (`test_grid_markers`) and the dumper's entry-cell fix (`test_world_dumper_entry_cell`).
- **As built, step 2 of 3 (`base/m3b-2`, the `game_root` split and `GameFlow`; `ObjectiveSystem`, `CheckpointSystem`, the `PlayerSnapshot` in the zone swap and the D-16/D-17 rules are step 3)**:
  - **The split, one responsibility per commit.** `presentation/bridges/`: `EventRouter` (events to the bridges that registered for their type, in registration order; a type nobody asked for is dropped), `EventBridge` (the base: `register`, `bind_world(snapshot, cast)`), `HudBridge`, `BoardBridge`, `CameraBridge`, `AudioBridge`, `MessageBridge`. `shell/bridges/`: `ShellBridge` (the base, holds the `GameRoot`), `SaveBridge`, `ZoneTravelBridge`, `BookBridge`, `RoomOutcomeBridge`, `DespawnBridge`. The list is what `game_root.gd` did. **Differs from 13.2 as written**: 13.2 puts a `save` handler in `presentation/bridges/`, but 13.1 forbids presentation to name the `SaveService` or a component, so the five bridges that write the run, rebuild the world or flip a component live in `shell/bridges/` (the layer allowed to name everything); the `dialogue` handler waits for M6. `ZoneStage` (the world node, the entry cell, swapping a zone or the hero's view) and `ShellKeys` (R, F3, F11, B) are small shell classes that took the rest, and `GameRoot._bridges()` lists the order the bridges react in. `shell/game_root.gd` went from 637 to 176 lines, holds no event reaction and is held under 200 by `test_game_root_is_thin`.
  - **`GameFlow`** (`shell/game_flow.gd`): `request_respawn(reason)` raises `respawn_requested`, waits out a zone trip under way, and at the end of the frame has `GameRoot.respawn()` rebuild the room (a fresh zone from the checkpoint, a fresh hero view in its boot pose, the Book closed, nothing carried); `respawned` follows. It replaces both `reload_current_scene()` calls (`test_no_scene_reload`). **Differs from 9.1 as written**: the request is a method plus a signal on `GameFlow`, raised by `RoomOutcomeBridge` (after the 0.85 s defeat beat) and `ShellKeys` (R); `Events.RESPAWN_REQUESTED` stays reserved, because in this step the bridge, not the simulation, decides the hero has fallen. Step 3's `ObjectiveSystem` will announce the fall and the router will hand it to `request_respawn`.
  - **Behaviour kept, behaviour that follows from not reloading.** Every bridge suite keeps its assertions and changes only its call sites (through `tests/bridge/bridge_support.gd`). Three checks that pinned the reload itself were reworded in `test_bridge_death_respawn` (the old `Main` freed, "the scene has not reloaded yet", the authored `CurrentZone` node); they are not in `tests/baseline_labels.txt`, so `label_renames.txt` is untouched. What changes with the reload gone, all intended: the music is not restarted by a death or R, the F3 switch survives them, R during a zone trip waits for the trip (the checkpoint is the destination either way), the board overlay forgets the last world's marks when it is bound to a new room, and a defeated enemy's despawn timer holds instance ids so it cannot strip a view in a world built after it.
  - Tests: `test_event_router`, one suite per bridge (`test_board_bridge`, `test_camera_bridge`, `test_audio_bridge`, `test_message_bridge`, `test_hud_bridge`), `test_bridge_despawn`, `test_bridge_room_outcome` (the win half, which no suite drove), `test_game_flow`, `test_shell_keys`, `test_game_root_is_thin`, `test_no_scene_reload`; `test_request_save_callers` now names `shell/bridges/save_bridge.gd` as the only asker.
- **As built, step 3 of 3 (`base/m3b-3`, objectives, checkpoints, the death rules and the `PlayerSnapshot` in the zone swap; M3b is complete and waits for the owner, `human_review`)**:
  - **`ObjectiveSystem`** (`ecs/systems/react/`): counts the room's enemies each tick, asks the room's `RoomObjective` (default: every enemy down) whether it is met and says `room_cleared` once; marks the room failed when the hero's Courage is 0 (a failed room is never cleared, so a simultaneous last kill and fall is a fall). State is `RoomObjectiveState` on the room's own entity (`ecs/components/room_objective_state.gd`), made by `EcsBoot` only when the shell asks (`EcsBootOptions.with_room_rules`), so the world dumps and the actor golden hold exactly the entities they held. The HUD's enemy count is the `HudSnapshot`'s (`room_enemies_total`, `room_enemies_remaining`), one owner instead of a tally in the bridge. **Differs from 13.4 as written**: the plan files the system under `world/`; the folder follows the stage (`react/`, `progress/`), as for every system since M3a.
  - **`CheckpointSystem`** (`ecs/systems/progress/`, state in `RoomCheckpoint`): on the first tick after the pawn came through a door into a room whose scene says `checkpoint_on_entry` (data on `RoomEncounter`, set on the hub and the boss room; a test fails if a script names a room id) it sets the checkpoint, refills Courage through the heal queue (source 0) and says `checkpoint_set` with what it refilled; Believe has one named seam (`_refill_believe`) and refills nothing until M10. When `ObjectiveSystem` has marked the room failed it says `respawn_requested` (zone and entry) once. A launch and a respawn are not arrivals. Three events moved from reserved to emitted: `room_cleared`, `checkpoint_set`, `respawn_requested`.
  - **The death rule** is the reading recorded in 5.2: the room the pawn fell in starts again from the entry it came by, with full Courage; the checkpoint does not move; nothing persistent is touched. The run keeps the position apart from the checkpoint: `[meta] room_entry` (new; a file without it resumes on its checkpoint entry; v2 migrates its position there and has no checkpoint) and `[checkpoint]` (the latest hub or boss-room door only). `SaveBridge.room_zone_id()` / `room_entry_id()` are what a death and a Continue read; `checkpoint_reached` is saved only for a checkpoint now.
  - **D-17 and the room-local half of D-16.** `SaveBridge` writes the zone into `cleared_room_ids` on `room_cleared` (a success event: `room_cleared` is saved), and every later boot of that zone spawns none of its enemies (their parked views are removed) and opens the exits that need the room cleared. A floor weapon an enemy takes is no longer written into the run or saved; only a `PickupSpawnPoint` with `persistent` set is, and only a persistent marker honours a taken record, so a stale record from an older save hides nothing.
  - **The zone swap carries a `PlayerSnapshot`** (captured when the trip starts, applied by `EcsBoot` through `EcsBootOptions.player_snapshot`, forgotten by the bridge): Courage current and max, the sword, the flags; the per-room rows reset and the facing is the entry's. A snapshot of a hero with no Courage is not carried. The world's flags also reach the run when a trip begins and when the hero falls, so a death keeps them; the file learns them at the next success event.
  - **Behaviour changes, all required by D-16/D-17**: (1) a room whose enemies all fell stays empty (D-17); (2) floor weapons reset with their room (D-16); (3) a plain trip between rooms no longer saves (it was `checkpoint_reached`), only a hub or boss-room door does; (4) a door into the hub or a boss room refills Courage; (5) a death returns the pawn to its room's entry rather than a checkpoint that moved at every trip: the same place as before, now by rule. Nothing else changed.
  - **Not done, and why**: `Tuning.extra_courage` is not read at the refill (the assist settings arrive in M4, nothing sets it); a boss's phases, `defeated_boss_ids` and "highest checkpointed phase" are M8b (a boss room starts over whole, which is its first phase today); `rescue_completed` and `beat_save_after` saves wait for their events (M6); the `deaths` counter and the reset presentation chosen by relationship flags are M8c; the checkpoint is recorded but nothing returns the pawn to it (see 5.2).
  - Tests: `test_objective_system`, `test_checkpoint_system`, `test_checkpoint_rules`, `test_cleared_rooms`, `test_player_carry_zone_swaps`; changed with their reasons in the commits: `test_bridge_persistence`, `test_bridge_travel`, `test_bridge_flags`, `test_bridge_death_respawn`, `test_game_flow`, `test_bridge_room_outcome`, `test_hud_bridge`, `test_hud_snapshot`, `test_save_migration_v2`, `test_save_roundtrip`, `test_request_save_callers` (and `encounter_hud_runtime_test`, whose labels did not change).
### M4: Shell, input, text (L)

- **Scope (Tier A)**:
  - `AppRoot`, `GameFlow` and the transition layer; title; pause (tree pause, pause on focus loss, a quit confirm that names the last checkpoint, a Controls panel built from the `InputMap`, an Assist options entry); settings (buses, shake, reduce flash, high-contrast danger, UI high contrast, fullscreen, language, assists, hold-or-toggle); the credits scene; the autosave indicator, version string and corrupt-save notice.
  - The full `InputMap` of §9.4 with gamepad defaults and two glyph sets chosen by the last input device; `skill_1` becomes `skill_slot_1` through `tools/move_res.py --rename-action`.
  - The text pipeline: per-domain `.po` files, `TextService` (the only `tr()` caller, handling `NOTIFICATION_TRANSLATION_CHANGED`), every literal moved to a key (`main.gd`'s 9 strings, HUD labels, room messages, `RuleEntry`, markers, objectives); the pseudo-locale; an OFL pixel font from a shortlist, credited in `THIRD_PARTY_NOTICES.md`.
  - The music player moves from `main.tscn` into `AppRoot` (the assertion at `run_tests.gd:180-182` is retargeted). The Book freezes the world.
  - The production HUD: **each widget is its own scene**, the HUD safe zone, debug fields behind F3 (off by default in exports); camera integer snap (req#10).
- **Tier B**: the first-run card.
- **Acceptance**: `test_input_actions_have_pad_events`, `test_pause_freezes_tick`, `test_focus_loss_pauses`, `test_text_keys`, `test_po_domains_merge`, `test_layout_pseudo_locale`, `test_settings_roundtrip`, `test_new_game_resets_slot`, `test_continue_loads_checkpoint`, `test_hud_safe_zone`, `test_camera_snap`, `test_controls_panel_from_inputmap`; the HUD test updated to set `en`.
- **Owner can try**: launch, title, New Game, pause mid-fight (enemies freeze), play T1-T3 on a gamepad, edit a line in a `.po` file and see it.
- **Dependencies**: M3b.
- **As built, step 1 of 4 (`base/m4-1`: the app root, the flow, the title and the credits; the input map and glyphs, the pause menu and Controls panel, settings, the text pipeline and the production HUD are steps 2 to 4)**:
  - **`AppRoot` is the main scene** (`shell/app_root.tscn`, `project.godot` `run/main_scene`). It owns `GameFlow`, the music (the `MusicPlayer` moved out of the game scene; `tests/run_tests.gd`'s three assertions now load `app_root.tscn`, the labels unchanged), the autosave tick and a persistent `TransitionLayer`, and shows ONE screen under `ScreenHost`: the title, the game or the credits. Screen changes are fade to black, free, build, fade back, run one after another in the order asked; nothing calls `change_scene` (`test_app_root_is_main_scene`). `game_root.tscn` is unchanged except for the missing music player and its root node being named `GameRoot`; it still runs alone (the bridge suites, F6 in the editor) with its own flow, already PLAYING. **Differs from 9.1 as written**: the zone trip keeps the game scene's own `FadeLayer` (`ZoneTravelBridge`): moving the trip's fade into `AppRoot` would have changed what every bridge suite pins and made the scene need an `AppRoot`; a trip between two rooms is the game's, a change of screen is the app's.
  - **`GameFlow` is the whole state machine of 9.1** (`BOOT, TITLE, PLAYING, PAUSED, RESPAWNING, ENDING, CREDITS`, a transition table, a refused request changes nothing: `test_game_flow_states`). It is a plain object, so it is driven with no scene. `start_new_game` and `continue_game` go through `SaveService`; `request_pause` is refused during a zone trip, while a rebuild waits and during the defeat beat (9.2); `reach_ending` writes the profile's `completed` mark (8.8); `quit_to_title` writes nothing. AppRoot sets `get_tree().paused` from the state; the pause menu, the focus-loss pause and the pause key are step 2 to 4. A room rebuild now goes behind AppRoot's fade (`before_respawn`, `after_respawn`): the old `respawn_requested` and `respawned` signals are unchanged.
  - **New Game resets the slot** (`SaveService.start_new_run`; the plan says "New Game resets the slot (keeps the profile)" and "asks to confirm" and nothing more): the clean run is written over the slot's file at once, so a relaunch cannot bring the old run back; the old file is kept as the `.bak` (a damaged one as `.corrupt`, a newer game's as `.newer_game`), the profile and its `completed` mark are untouched, and it is not an autosave (R17: no tick, `request_save` refuses nothing new). **Continue** is offered exactly when `read_slot()` finds readable progress and resumes the AS-BUILT point (the room and entry of the LAST SAVE, with the latest checkpoint recorded beside it; nothing returns the pawn to a checkpoint, 5.2). Continue on a completed save loading `Ending.post_game_zone` waits for M13.
  - **The title** (`shell/title/`): New Game (a `ConfirmPanel`, `presentation/ui/menu/`, asks first when a readable save would be replaced), Continue (only then, with a card: room, time played, day saved), Settings (shown DISABLED until a settings scene is wired into `AppRoot.settings_scene`; step 3 or 4 wires it), Credits (9.1: "the credits can be replayed from the title"), Quit, the version (`application/config/version`, 0.4.0) and, once the game was finished, one empty square on the rug board. The art is plain nodes plus the hero's own `body.png` at its own size (the owner draws the real title later through `docs/assets`, `title_*` groups). **The corrupt-save notice** (9.2): `TitleSummary.from_save()` turns `SaveLoadResult.notice_key` into one line on the title; a damaged newest file with an intact `.bak` still offers Continue (the card describes the save that will load) and the status line of the room repeats the notice; a damaged file with no backup, a save too old to migrate and a save from a newer game offer New Game only. Until the text pipeline (step 3) moves the words to `UI_` keys they are English constants (`TitleSummary.NOTICE_TEXT_BY_KEY`, the scene's labels).
  - **The credits** (`shell/credits/`, `content/story/credits.tres`, a `CreditsDefinition` of `CreditsSection`s in `schema/story/`; `ContentDb.credits()`): the owner's block (the line says "The owner": the owner types the name), the engine, and the Licenses block, which is GENERATED from `THIRD_PARTY_NOTICES.md` (9.2) by `tools/build_credits_licenses.gd` into `content/story/credits_licenses.tres`; an entry with a `- **License:**` bullet is credited, anything else is not, and `test_credits_licenses_current` fails while the two disagree. Holding Confirm skips the roll (read from events, not from `Input`). **Differs from 8.8 as written**: the credits do not scroll over the live ending image (the ending is M13); they roll over the plain backdrop.
  - **The autosave tick** (`presentation/ui/autosave_indicator/`): shown for 1 s by `AppRoot` on every `SaveService.autosaved`. **Not done in this step**: the first-run card (Tier B), the settings screen, the pause menu and its confirms (`ConfirmPanel` is ready for them), `NOTIFICATION_APPLICATION_FOCUS_OUT`.
  - Tests (`tests/shell/`): `test_app_flow` (boot, title, New Game into T1, pause, a rebuild behind the fade, Quit to Title during a defeat, Continue, the credits, the ending), `test_game_flow_states`, `test_new_game_resets_slot`, `test_continue_loads_checkpoint`, `test_title_summary`, `test_title_screen`, `test_credits_screen`, `test_credits_licenses_current`, `test_transition_layer`, `test_autosave_indicator`, `test_confirm_panel`, `test_app_root_is_main_scene`. Changed: `test_game_flow` (the music player is no longer the game scene's), `test_validate_all` (the `credits` kind), `test_suites_isolate_the_save` (`boot_app`), `TestPaths` (`main_scene()` is `AppRoot`, `game_scene()` the room).
- **As built, step 2 of 4 (`base/m4-2`: the input map and the pause menu; the step landed green without its log, so what follows is read off its code and tests)**:
  - The full `InputMap` of 9.4 with a gamepad event on every played action (`test_input_actions_have_pad_events`; `skill_1` is `skill_slot_1`, `restart_room` is gone, **R is `call_child`**, D-18); the `InputPoller` picks the left stick's dominant axis and publishes a hold-or-toggle action as a switch (`test_input_poller_rules`); `F3`, `F11`, `B` and Esc/Start are `InputMap` actions read from the snapshot (`ShellKeys`).
  - **The pause menu** (`shell/pause/`, laid in `AppRoot`'s `MenuLayer`, `PROCESS_MODE_ALWAYS`): Resume, Book of House Rules, **Restart Room** (a `ConfirmPanel` asks; the only way to restart a room, `test_pause_restart_is_menu_only`), **Quit to Title** (asks, names the last checkpoint, says progress since the last save is lost; writes nothing: `test_quit_to_title_confirm`). `get_tree().paused` follows the flow (`test_pause_freezes_tick`); the game pauses when the window loses focus and asks again each frame while a trip refuses it (`test_focus_loss_pauses`). The Book freezes the world with a `freeze_requested` command. Settings, Assist options and the Controls panel are not in the menu yet (step 4).
- **As built, step 3 of 4 (`base/m4-3`: the settings screen, the Controls panel and the glyph lookup that step 2 left, then the text pipeline and the font slot)**:
  - **The Settings screen** (`shell/settings/`, reachable from the title and from the pause menu): four pages built from the `GameSettings` table (`schema/settings/`, one `SettingDefinition` per setting): **Sound** (Master, Music, SFX, UI volumes), **Screen** (Fullscreen, Language, High-contrast menus), **Comfort** (Screen shake 0 to 100 percent, Reduce flashing, High-contrast danger, press-to-switch for turn mode, Guard and Focus) and **Assists** (Warning time 100/125/150, Enemy pace 100/85/70, Extra Courage +0/+1/+2, Input forgiveness: neutral names, all at the standard game, never switched on by the game, D-22). The values live in the **profile file** (`setting_<key>` beside `completed`), so a New Game keeps them; a missing, wrongly typed, out-of-range or unknown value takes its default and is logged with the reason (`SettingsStore`, `test_settings_roundtrip`). Each setting DRIVES a real target, and one suite per setting looks at it (`test_setting_*`, `test_every_setting_has_a_target`): the bus volumes and mutes, the window's fullscreen, `TextService.set_language` (live; `vi` falls back to `en` per key), `UiContrast` on the project theme (opaque panels, outlines, white text; the theme's own entries are restored when it is turned off), the camera bridge's shake scale, the HUD's damage flash, the board's strike flash and pulse and, through a `Tuning.reduce_flash` knob read by `ViewSyncSystem`, the pieces' hurt tint and the hero's 7 Hz invulnerability blink; the board's High-contrast danger look (thick outline, stripes, no pulse); `InputPoller.set_toggle_mode`; and the four assists as `tuning_set` commands (sent again after every rebuild). **Differs from the plan as written**: assists are per profile and not per save (one place, reachable from the title; 5.8 says per save); the Voice bus has no slider (nothing plays on it before M6); the rescue hold's toggle waits for the rescue (M6). The assists reach `world.tuning` and no system reads them yet (the milestone is named on each `Tuning` field: M7b, M8a, M8c), so each assist and press-to-switch Guard and Focus say "(coming later)" beside their row (`SettingDefinition.coming_later`; `test_settings_coming_later` keeps the mark true: a setting is marked exactly when no system under `ecs/systems/` reads its tuning field or its action). The screen is walkable by keys and pad alone (explicit focus neighbours, `test_settings_focus_walk`), the language drop-down lists only languages that have words (`TextService.offered_languages`; the generated `qps` only in a debug build), and a profile write refused because a newer game owns the file is said on the screen. The pause menu now lists Resume, Book, **Settings**, **Controls**, **Assist options** (opens the Assists page; there from the first run), Restart Room, Quit to Title.
  - **The Controls panel** (`presentation/ui/controls/`): three pages (Moving, Acting, Game), a keyboard column and a gamepad column, **built from the live InputMap every time it opens** (a rebound key or a new action shows with no other change; `ControlsCatalog` only names actions and says which do nothing yet; `test_controls_panel_from_inputmap`). The child's R and the other actions nothing reads yet say "(coming later)" (D-18 and the owner's rule); the unused skill slots 3 and 4 are hidden. It replaces the static help line in spirit: the HUD's own help line is the production HUD's job (step 4).
  - **The glyph lookup** (`presentation/ui/input_glyphs/`): `InputGlyphs` answers, for an InputMap action and a device, one glyph per event: the owner's 16x16 picture at the path of the asset list (group `glyphs_kenney`, folder `assets/ui/glyphs`: `keyboard/key_w.png`, `gamepad/btn_a.png`, ...; the owner copies Kenney's CC0 'Input Prompts Pixel' there later, nothing is downloaded) and always the words that stand in (`[Space]`, `[A]`, `[Left Stick Up]`). `test_input_glyphs` holds every path to the asset list and every control the InputMap binds to a slot in it. `LastInputDevice` (a key press, a pad button, a stick past drift) chooses the set; `GlyphStrip` and `ActionPrompt` draw it and follow both the device and the language.
  - **The text pipeline and the font slot:**
  - **Words are `.po` rows** (`content/story/text/<language>/{story,ui,skills,rooms}.po`, D-24): eight files registered in `project.godot` as four translations of `en` and four of `vi`; `en` is complete (138 rows, every one with a `#.` translator comment), `vi` is empty and falls back to `en` per key (`test_po_domains_merge`: the engine resolves every row of the four files as one table, no key is written twice in or across files, each key sits in the file of its prefix). The plan's prefixes (`ROOM_`, `UI_`, `BOOK_`, `PAGE_`, `ENEMY_`, `CHAR_`, `CREDIT_`, ...) gain two it did not list: `MSG_` (the sentences the status line says when something happens, in `ui.po`) and `ITEM_` (floor weapons, in `skills.po`); the table is `TextService.PREFIXES_BY_DOMAIN`.
  - **`TextService`** (`presentation/text/`) is a static class, not an autoload (D-26 allows two), and the only code that asks the engine to translate: it calls `TranslationServer.translate` because `tr()` is an instance method; `test_tr_only_in_text_service` forbids `tr`, `atr`, `tr_n`, `atr_n` and `TranslationServer.translate` everywhere else. `t(key, params)` fills `{name}` with `String.format`; a missing key renders as itself. **NOTIFICATION_TRANSLATION_CHANGED**: a Label a scene authored holds its key in `text` and the engine translates and redraws it by itself; text a script sets sits on a `LiveText` (a child node of the screen that resolves its key and params again on the notification) and a name inside another sentence is a `TextKey` param, so it changes with the sentence (`test_language_switch_redraws_live`: the HUD, the title with a question up, the pause menu with the Quit question naming a checkpoint, the Book, the credits). `set_language`, `languages` and `language_name` are there for the Settings screen.
  - **Every player-facing literal is a key**: the HUD labels and help line, the status-line sentences (`MessageBridge`, `ShellKeys`, `BookBridge`), the room's start, locked-door and unlock lines (`ROOM_<ID>_START`, `_LOCKED`, `_UNLOCK_SWORD`, and each room's name), the result panel and the stock objective lines (one copy of each instead of three), the Book's labels and pages, the pieces', weapons' and attacks' names, the hero's piece name, the credits (the Licenses block's legal text stays verbatim and its heading is `CREDIT_LICENSES_HEADING`), the title, the pause menu, its questions, the notices, the save card (`UI_CARD_PLAYED`, time and version formats). `test_text_keys` defines "player-facing literal" and holds the line: prose (two words or more) anywhere in a shipped script, scene or resource, or any word at all in a text property or on a text-sink line, fails, except inside developer functions and lines (`validate*`, `*problems*`, `push_error`...) and the exact `ALLOWED_LITERALS` list (event and command tables, cell-kind notes, save-file reasons, the editor's blocker label, the licence texts), which says why per entry and fails on an entry that matches nothing.
  - **The pseudo-language** `qps` is generated (`PseudoLocale`: every row 40 percent longer by repeating its letters evenly, accented, `{name}` and `%d` untouched) and not Godot's own pseudolocalization, which accents the name inside `{pawn}` and so leaves `String.format` nothing to fill. `test_layout_pseudo_locale` builds the HUD (every line of the status bar, the longest piece name, the result panel), the title (every notice, the card, the New Game question) and the pause menu (both questions) at 640 x 360 in English and in `qps` and fails when a text leaves the screen or its panel, a fixed box grows, a wrapped text needs more height than it had, or two texts meet that did not. It found real overflows, so the HUD was re-laid (the banner and the skill, count and cell labels have their own columns, the objective line has the full row, the result panel is wider) and the title's logo wraps. The settings screen is measured as soon as `shell/settings/settings_screen.tscn` exists.
  - **Behaviour changes:** the HUD help line says `PAUSE ESC` and no longer `RESET R` (D-18); T1 reads "White King's Fall" on the save card and in the pause question (the old name was derived from the folder id and lost the apostrophe); nothing else a player sees changed. Tests run in English (`UnboundTest` sets it before any suite starts).
  - **The font slot (the owner rule of M4: nothing is downloaded)**: `content/ui/theme/theme.tres` is a `UiTheme` (`schema/ui/`), the project theme (`gui/theme/custom`, so it reaches the HUD under its `CanvasLayer`, which a Window theme does not), naming the four files of the asset list (`assets/fonts/ui_body_pixel.ttf`, `ui_small_pixel.ttf`, `ui_title_pixel.ttf`, `child_hand.ttf`). `UiFonts.apply`, called by `AppRoot`, uses the ones that exist (the body file is the Theme's default font; the others are the fonts of the Label variations `HudNumeral`, `MenuTitle`, `ChildLine`) and leaves the engine's default font where there is none. `test_font_vietnamese_coverage` checks all 134 precomposed Vietnamese letters (stacked marks included) of every font in use and reports it: an owner file that lacks a letter FAILS, the engine's default font that lacks one WARNS (it has all 134 today); the owner-file path is exercised with the default font's own bytes in a throwaway folder. `THIRD_PARTY_NOTICES.md` records the slots as "owner-supplied" and says what to add with a file. The plan's "OFL font from a shortlist" is replaced by this slot (owner rule).
  - **Dumps and goldens print keys:** `tools/world_dumper.gd` writes `enemy:ENEMY_PAWN_RECRUIT_PIECE` and a door's `ROOM_..._LOCKED`, never the sentence, so rewriting a `.po` line cannot change a baseline; four baselines were regenerated and `test_actor_collapse_golden` names the three piece labels and four room heads that moved for that reason.
  - **Docs:** OWNER_GUIDE (Vietnamese: section 8 "edit a line of a `.po` file and see it", the font file names and what to check; the keys table and section 7 now say the pause menu restarts a room, not R), ARCHITECTURE ("Text"), CLAUDE.md (the words rule), coding-standards, README (controls), `/new-enemy` (name keys), THIRD_PARTY_NOTICES. **Not done in step 3**: the production HUD with its help line made from the InputMap and the camera snap (step 4); the first-run card (Tier B); `vi` rows (the owner's); the glyph files and the fonts (the owner's); `DLG_`, `AMB_` and the story rows (M6).

- **As built, step 4 of 4 (`base/m4-4`: the production HUD, the camera's integer snap and the docs; M4 is built and waits in `human_review`)**:
  - **The HUD is a layer of widgets, each its own scene** (D-29; `presentation/ui/hud/`, `GameHud` plus `widgets/`): `CouragePips` (a caption and one ivory chess-base pip per point, at most 5, the Courage plate of the asset list), `RankBadge` (the Rank label as blue tally marks, hidden while `HudSnapshot.rank_label` is 0, which is until M7c), `SkillSlots` + `SkillSlot` (a 24 x 24 frame that fills from the bottom, and the name and state beside it; room for four), `EnemyCount`, `ObjectiveLine` (the status line), `ControlPrompts`, `DebugReadout`, the RESERVED `BelieveSlot` (M10) and `BossBarSlot` (M8b, 96 x 20: they draw nothing, read nothing, are hidden and keep their rectangles) and the two effects, `DamageFlash` and `ResultPanel`. A widget extends `HudWidget` (`refresh(snapshot)`, drawing only when what it shows changed; `forget_drawn()`), names no component, no world and no `Input` (`test_hud_widgets` scans the scripts). The `HudBridge` shrank to its job: it hands the snapshot to `GameHud.refresh()` every frame, flashes the screen on a hit and tells the debug readout who strikes next (a name is the cast's); it needs no event for Courage because the snapshot is rebuilt at the end of the tick that took it, before the events are routed. `HudSnapshot` gains one field, `rank_label` (0 until M7c's `ProgressionSystem` copies the label there).
  - **The HUD safe zone** (requirement 180, `test_hud_safe_zone`): everything sits in the top strip (y 0 to 32, bars at most 28 px) or the bottom strip (y 326 to 360), 4 px from the picture's edges, and intersects no board: measured for every widget, shown or reserved, against the board of every room (read off the room scenes) and the largest 18 x 9 board, and shown able to fail on the old HUD's own rectangles (the top panel y 4 to 46, the status line y 28 to 44, the strike line y 322 to 336). Top strip, left to right: Courage 6..152, Believe 156..192, skill slots 198..318, boss bar 322..418, enemy count 420..552, Rank 556..630. Bottom strip: the status line (y 327..341), the control hints and the debug readout (y 342..358, the same place). The result panel and the damage flash are the only things that cover the board, and only after the room ends or for a fifth of a second.
  - **Control hints replace the static help line** (9.4, "generated from the InputMap, never hard-coded"): `ControlPrompts` shows the first glyph of Move (four keys on a keyboard, one on a pad), Sword, Thrust and Pause for the device used last, in the language in use, from the step-3 glyph lookup; AppRoot owns the finder and the tracker and hands them to the game scene. The skill line no longer spells "Q" (it said "Q THRUST READY"); the hint beside it names the key. **Debug fields** (requirement 181, `test_debug_overlay_default`): the cell line and the strike line are the `DebugReadout`, hidden at the start; F3 swaps it for the hints and switches the board's layer with it; `ShellKeys.debug_view_at_start` forces the view off in a release export whatever the scene says.
  - **The camera starts the picture on a whole pixel** (D-30, requirement 10, `test_camera_snap`): `CameraRig.snap_to_whole_pixels` (on) keeps the follow, the ease, the board's limits and the shake, then moves the finished view by less than half a pixel through the camera's `offset` (which the engine adds after the limits) with `force_update_scroll()`; the rig eases the follow point itself (same exponential catch-up) because the engine's smoothing runs after anything the rig can do; the shake is rounded to whole pixels and is still scaled by the Screen shake setting. Measured on the SubViewport's own canvas transform, with fractional hero positions, with the ease on, in the four room sizes, zoomed, at the world's corners, with and without shake, and shown able to fail with the snap off. The piece's slide between cells is snapped too (review fix, `test_piece_slide_snap`): `ViewSyncSystem` works the eased slide out in floats and draws the view on the nearest whole pixel, so the simulation's numbers (cell, progress, the dodge window) are untouched; `snap_2d_transforms_to_pixel` (window pixels) and `stretch/scale_mode = integer` were left alone, for the owner.
  - **Behaviour changes a player sees** (D-29, D-30, D-18): the HUD has no title banner and no "COURAGE ***" text (a caption and pips); the skill reads THRUST READY and THRUST 0.5 (the key is in the hints); the status line moved from under the top panel (it covered row 0) to the bottom strip and reads left to right; the enemy count is at the top right; the cell and strike lines are gone until F3; the keys line is the hints; nothing else about the rules changed. Text rows: `UI_HUD_TITLE` and `UI_HUD_HELP` removed, `UI_HUD_COURAGE` is "COURAGE", `UI_HUD_RANK` and four `UI_HUD_PROMPT_*` added.
  - Tests: new `test_hud_widgets` (44), `test_hud_safe_zone`, `test_debug_overlay_default`, `test_camera_snap` (24); changed `test_hud_bridge` (the widgets draw the snapshot), `test_layout_pseudo_locale` (the HUD states, now nine plus every status line, with the top strip at its fullest, the pad's words and the debug readout), `test_language_switch_redraws_live`, and the suites that read a label (`objective_line.text_label`, `enemy_count.count_label`, `courage_pips.filled_count()`: their labels unchanged). 137 suites, 235 of 235 baseline labels (14 through `label_renames.txt`, unchanged).
  - **Docs:** ARCHITECTURE ("The HUD: widgets in two strips", the camera, the bridge table), coding-standards ("The HUD and the camera"), CLAUDE.md (the HUD and camera rule, R and Restart Room), AGENTS.md, README (controls with the pad), tools/README (`render_hud_preview.gd`), OWNER_GUIDE (Vietnamese: the controls table with the gamepad column, how to read the HUD, "what to try in M4", the camera, a glossary), task_plan, progress, findings, where-we-are.
  - **Not done, and why:** the first-run card (Tier B); the HUD's pictures (the asset list's `hud_*` groups are the owner's; the widgets are plain nodes with the Courage pip's two looks as exports); the equipped-weapon readout and skill slots 2 to 4 (`test_hud_slots_from_data` is M7a's: the snapshot has one skill until then); the Rank badge, Believe slot and boss bar are inert until M7c, M10 and M8b; the pad's Move hint reads "[Left Stick Up]" until the owner's glyph files exist; the assists still reach `world.tuning` with no system reading them (M7b, M8a, M8c; the Settings screen says "(coming later)" for each).

### M5: Vertical skeleton, start to end (M)

- **Scope**: `tools/build_room.gd` (ASCII layout to `.tscn` text with uids, then the stamper; refuses to overwrite an existing scene; layouts in `tools/layouts/`); stub rooms for EVERY id in §7.4 with final ids, sizes, archetypes, entries, exits and lock messages; boss stubs (enemy variants with the final boss ids); `content/world/world.tres` replacing the world graph (the `run_tests.gd:196-222` assertions are ported, not dropped); H1 doors wired with flag locks (`boss.<id>`; skill locks arrive in M7c); `e1` as a card sequence with `Ending` and credits; `RoomEncounter` meta fields with configuration warnings; the `TraversalGap` and `StateVariantMarker` marker schemas; `tools/list_placeholders.gd` and `tools/print_world_map.gd`; `tests/playthrough/test_full_route.gd` and its route bot, which records the measured minimum clear time per room in `docs/route_times.md`.
- **Acceptance**: `test_full_route.gd` (boot to credits, under 90 s, bosses killed via damage events); `test_world_graph.gd` (every exit resolves, every room has an entry, no orphan, every lock has a message); `test_room_status.gd`; the lints run against the §7.4 table as their fixture (`test_preview_before_lethal`, `test_threat_budget`, `test_room_data_audit`, `test_enemy_placement`, `test_layout_archetypes`, `test_district_loops`, `test_reward_cadence`).
- **Owner can try (OG1)**: play title to credits in about 10 minutes through stub rooms; `print_world_map` shows all 34 nodes.
- **Dependencies**: M4.
- **As built, steps 1, 2 and 3 (`base/m5-1`, `base/m5-2`, `base/m5-3`)**: the room builder and the world file are as above. Step 2 made the 27 missing rooms and rebuilt `tb1` (28 stubs, `content_status` STUB, every one built by `tools/build_room.gd` from `tools/layouts/`), so the graph holds the plan's 34 rooms, 69 doors and 17 locks; `dev_sandbox` is in the 7.4 table but is not a shipping room and stays M6's. **No stub needs a verb that does not exist:** no layout puts a gap on the walk or uses a `TraversalGap`; the skill needs of the plan (Rule Step, Chalk Path, Eraser Guard) are `unlock` locks that name their milestone (`WorldLock.arrives_in = "M7c"`) and sit on eleven doors as `WorldEdge.skill_lock_id`, which the runtime does not hold. The boss stubs are data-only enemies on one cell with `EnemyDefinition.defeat_flag = boss.<id>`; `BossDefeatSystem` sets the flag when one falls and `SaveBridge` saves (`boss_defeated`). The hub's doors wait for the boss before each (`ZoneExitMarker.requires_flag` with its line, D-21) and `WorldCheck` gained a `progression` check that walks the route from T1. The Ending is a sequence of `END_` cards (`Ending`, `EndingCard`, `content/story/endings/ending.tres`) reached by the Desk's one door that ends the run (`ZoneExitMarker.ends_run`, `ending_reached`, `EndingBridge`) and followed by the credits and the title with the completed mark. **Step 3** made the route test, the lints and the owner's guide. `tests/playthrough/test_full_route.gd` (bot: `route_bot.gd`) walks the 35 steps of the critical path by key presses from New Game to the title in about 20 s (budget 90 s; the runner's per-suite timeout is 120 s for it, `SUITE_TIMEOUT_OVERRIDES`), clears each room (the sword for ordinary pieces, a damage event for a boss) and writes the measured minimum per room to `docs/route_times.md` (about 3.5 game minutes against the plan's 134; the same on every run). `EnemyDefinition.threat_points` (recruit 1 ... rook 4; a boss's phase-1 budget) and the `RoomEncounter` encounter meta (`objective_kind`, `threat_budget`, `threat_shapes`, `intro`, `intensity`; five new layout keys; all 34 rooms) are what the lints read, and `RoomEncounter.threat_problems()` is the one written form of R4, R18 and R28 (the Inspector's warnings and the lints call it). The seven lints run against the plan's 7.4 table as data (`tests/fixtures/plan_encounter_table.gd`, with `plan_room_table.gd`) and against the shipped rooms, each shown able to fail on a copy of the table; a rule a stub cannot be held to yet is a REPORT line that says when it becomes enforcing (the fenced instance of a family, near groups: M8a; boss shapes: M8b; rewards as pickups and beats: M6 on; ub2's waves: M13). **The lints found two things in the table as written:** R37 fails on the Reward column at the Queen's room (6.5 minutes without a reward) and the Black King's (9) unless the story beats the plan lists inside those fights (S20, the address; S24, the memory alcoves) are counted as the earned beats they are, which the fixture does (`mid_rewards`; the table should say so, `findings.md`); and the Under-Bed has no loop or shortcut, because its boss's door ends the run (7.2), so it is a written, self-expiring exemption in `test_district_loops` (the Desk is one room). Plan 7.4's `ub3` (`4/2`) is read as a Recruit and three rewrite pulses of one point each. **Differs from the scope as written:** the H1 hub is edited by hand (it is a Stage 1 scene), so its dump baseline moved for its new doors while the other five Stage 1 baselines did not; and `RoomEncounter` carries five of the plan's meta fields (the rest, `allowed_calls`, `solutions`, `emotion_target`, `release_beat`, `lazzaro_key`, `peak`, `what_happened_here_key`, `clue_index`, `respawn_on_reentry`, have no reader before M6, M12 or M14 and are added by the milestone that reads them). **After the review (`base/m5-fix`):** the real-input review found two defects of the owner's experience and both are fixed. Every door cell is drawn (the board overlay reads a `DoorBrief` per door from the `HudSnapshot`; `DoorRules` is the one rule of "shut" for the board and for `MovementSystem`), and a walking key held through a door or a respawn no longer walks the pawn back out (`InputPoller.require_fresh_press`). The route bot steps on every shut hub door before its boss, `docs/route_times.md` is called a slow bot's baseline and not a minimum, and the twelve rooms whose parked pieces differ from the designed threat are an exact list in `test_threat_budget` (report-only until M8a, M9, M13 and M8b make each room right).

### M6: Story engine and Act 1 told (L)

- **Scope (Tier A)**: `schema/story/*`; `TriggerMarker`, `TriggerSystem`, `StoryBeatSystem`, `InteractionSystem` and `InteractComponent`; `StoryDirector`, `BeatPlayer`, `CinematicStage`, `ChildHandPresenter`, `DialogueBox`, `PromptWidget` and the prompt table of §8.5; the ambient-lines table, the relationship-keyed reset rows and the pawn emote palette; Book v2 (inks, Drawings tab, Lore entries); `tools/build_beats.gd` and `tools/export_script.gd`; Act 1 authored in data (S01-S07 and S06b): the opening (control in 7.5 s or less), T1 designed as a winding route past three stations with the silent stretch capped at 60 s, the chord denial (R34), the T2 prompts, the T4 crayon scratch with the Pencil on the exit path, the B1 notice (stub boss), the first child line and the Pebble rescue in H1, the under-bed silhouette, clue props 1 and 2, locked-door messages; the T2 child whisper removed; **a minimal `MusicDirector`, four placeholder stems and the child's SFX set**; `dev_sandbox` (beat launcher, flags panel, "Check content" button); `StateVariantMarker` baking into `FlagVisible`; `child_trust` events.
- **Tier B**: the Tier-2 cutscene worked example; the dialogue log.
- **Acceptance**: `test_emotion_fields` (soft), `test_time_to_control`, `test_t1_audit`, `test_prompts`, `test_prompts_cover_actions`, `test_child_voice`, `test_rescue_in_h1`, `test_denied_chord` (R34), `test_beat_graph` (reachability, flags read and set), `test_skip_equals_play`, `test_no_softlock_on_interrupt`, `test_story_literals`, `test_state_variants`, `test_clues` (partial: clues 1-2).
- **Owner can try**: play Act 1 from the title to H1 with all story and music; rewrite a line in a `.po` file or the text-first script; fire any beat from the sandbox.
- **Dependencies**: M5. May run as a second lane beside M7a because the shared fields (M3a), the HUD widget scenes, the schedule files and the `.po` domains are already split.

### M7a: Skill engine (L)

- **Scope**: `schema/skills/*` (`SkillDefinition`, effects, slots); `slots.tres`; components `SkillBook`, `SkillCast`, `Status`, `Loadout`; `SkillSystem` hosting new verbs; `StatusSystem`; the `HealthSystem` status hook (guard, untargetable); the HUD slots generated from data; the `skill_slot_N` inputs; **Rule Step** as the first new verb (`begin_leap`, ghost marks, tap choice, 4.0 s cooldown); `ViewSyncSystem` fires `travel(skill.anim_state)` generically; a plain `GrantMarker` unlock (the full progression system is M7c); the `/new-skill` command. `CombatSystem` still drives Sword and Pencil, untouched.
- **Constraint found in the M3b review (third round)**: T4's Pencil is a hero-only `GrantMarker` on the exit path, never a floor weapon. The `PencilSpearPickup` that stands at (13,2) today is the D-16 floor-weapon demonstration, and weaponless pawns take floor weapons: in ten human-paced walk-throughs by a verifier a weaponless pawn (usually the Recruit) carried the spear off each time while the hero fought around the middle of the room (a bot that killed that pawn first kept it), and a cleared room stays empty (D-17), so the reward was gone for the run. M7a either removes that pickup or leaves it as a pure demonstration beside the grant.
- **Acceptance**: all baseline combat labels unchanged; `test_rule_step` (landing reserved, 0.22 s untargetable, 4.0 s cooldown, red ghost on a locked telegraph), `test_skill_cooldowns`, `test_leap_over_gap`, `test_add_skill_by_data_only` (the HUD slot, `anim_state`, `sfx_event` and the three text keys resolve), `test_hud_slots_from_data`, `test_slot_table`.
- **Owner can try**: press F after the Rule Step grant; retune the cooldown in `skill.tres` and feel it.
- **Dependencies**: M5 (the world fields come from M3a).

### M7b: Parity cutover and feel rules (M)

- **Scope**: Sword and Pencil become `SkillDefinition`s on `SkillSystem`; `CombatSystem` and `PlayerCombat` are removed. **`ecs_combat_test` is rewritten in the same commit** against fixture definitions with a 1:1 assertion checklist (`docs/combat_parity_checklist.md`), because the draft's "unchanged" cannot hold once `CombatSystem` is gone. Also: the movement lock during a swing, the turn lock during a step or impact window, enemy stagger, the armored-recoil hook, **input-buffer expiry** with `buffer_window` in `FeelProfile` (an explicit owner-visible change, T-1 and T-8), the player picking up floor weapons (the Ruler Blade is swapped in the Book when no hostile is alive), and the serialized `wooden_sword` and `pencil_thrust` exports migrated.
- **Acceptance**: `test_combat_parity` (every item of the checklist), `test_input_buffer` (R11), `test_move_lock`, `test_turn_lock`, `test_stagger`, `test_floor_weapon_pickup`; baseline labels intact or renamed with a reason.
- **Owner can try (OG2)**: the feel gate.
- **Dependencies**: M7a.

### M7c: Progression (M)

- **Scope**: `ProgressionSystem`, `content/progression/milestones/*.tres` and `rules.tres`; the Rank label (in `HudSnapshot` only) and Margin from `margin_gain`; `Loadout` and the Book equip through the `equip_page` command; the `PageModifier` family with handlers for `ParamOverride`, `ChainWindow` and `MoveRule`; the five existing Pages migrated (`margin_cost`, modifiers, `when_not_to_wear`, `ink`); Lore entries; Courage Shards and max Courage; checkpoint refills from `rules.tres`; the Pencil locked until the T4 grant; hub locks switched to unlock ids; the Lead Tip `SkillUpgrade`; unlock hint prompts.
- **Acceptance**: `test_progression_ledger` (milestones apply; the Rank label equals 2 plus defeated bosses and nothing reads it), `test_pages_margin`, `test_unlock_gating`, `test_page_modifiers_data_only` (no page id literal in any system), `test_pages_reachable` (the M5 stub rooms hold the enemies), `test_checkpoint_refills`, no literal `"wooden_sword"` in code.
- **Owner can try**: pick up the Pencil in T4 (Q is locked before); open the Book and equip within Margin; retune Pencil cooldown in `skill.tres`.
- **Dependencies**: M7b.

### M8a: Attack stages (L)

- **Scope**: `AttackBase` and the unified `CellPattern` (§5.10); `AttackStage` (declare, telegraph, active, recover); events carrying shape and progress; `world.tuning` read by the systems, including weapon telegraphs; `DifficultyProfile` multipliers and the telegraph floor; the dead `STATE_COMMIT` wired as the active stage; Recruit, Armed and Knight ported first (the Knight L-leap with its 0.9 s landing marker, destination shadow and `begin_leap` occupancy) with the existing enemy tests as parity; assists mapped to `tuning`. One owner now holds `EnemyAISystem` through M13.
- **Tier B**: `test_response_cells`.
- **Acceptance**: `ecs_enemy_test` labels intact; `test_attack_stages`, `test_attack_events_shape`, `test_telegraph_contract` (R6), `test_tuning_scales`, `test_knight_leap_occupancy`, `test_no_stale_telegraph`, `test_enemy_identity_table`.
- **Dependencies**: M7b.

### M8b: Boss framework and B1 (L)

- **Scope**: `BossDefinition` and `BossPhase` (`ends_on`, weighted patterns, summons, enter beat, music layer, disable-help, `rule_taught`, `rule_bent`, `checkpoint`, `windup_clip`, `transition_clip`, `defeat_clip`, `active_rule_modifier`); `BossPhaseSystem`; the seal marker (Black Line) and antechamber; permanent defeat; the boss bar; **multi-cell footprints** for the bosses the owner sized per boss on 2026-10-13 (`docs/owner-decisions.md`: Rook Warden 2x2 in phases 1-2 then 1 cell, Rule Engine 3x3; every other boss 1 cell) — a `footprint` on the definition and on `BossPhase`, `EcsGrid` occupancy over every covered cell, movement and reservation of the whole footprint, a hit on any covered cell, telegraph origins from the footprint, and the in-cell rule measured against the footprint; **B1 rebuilt as 3 phases (HP 8)** with real beats and the Ruler Blade drop; the `seen`-flag abbreviation of beats on retry and phase-checkpoint respawn (D-43).
- **Acceptance**: `test_multi_cell_footprint` (occupancy, movement, hits and the in-cell margin for a 2x2 and a 3x3 piece), `test_boss_phase_swaps`, `test_boss_defeat_persists`, `test_player_kill_only` (R14), `test_boss_phase_differs` (R13), `test_boss_phase_checkpoints`.
- **Dependencies**: M8a and M6.

### M8c: Feel, fairness and death flow (L)

- **Scope**: `JuiceDirector` (hit-stop, pooled particles, flash parameter set by `ViewSyncSystem`, shake scale); `KnockbackSystem`; the telegraph language (patterns, red sacred, the pickup glow recoloured, the `TelegraphPalette`, the board overlay registry); the death freeze-frame and the relationship-keyed reset (D-44), with control in 5 s or less; death-knowledge margin notes; accessibility (reduce shake and flash, high-contrast danger with patterns, UI high contrast, hold-or-toggle); the low-health feedback; the `step_blocked` consumer; Focus; the assist offers (5 deaths or 15 minutes) and the Pause entry; the attempt logger and the decision-gap metric; defeated pieces become toys. **Probe P1.**
- **Acceptance**: `test_hit_stop_restores_time_scale`, `test_death_freeze` (R8), `test_retry_time` (R9, including death-to-next-damage in a boss), `test_death_knowledge` (R10), `test_deaths_not_read` (R12), `test_reset_variants` (R35), `test_flash_rate`, `test_low_health_feedback`, `test_step_blocked_feedback`, `test_decision_gap` (R31), `test_focus_emphasis`, `test_defeat_becomes_toy`.
- **Owner can try**: fight B1 (3 phases, hit-stop, shake, flash); die and see the freeze-frame and the reset; toggle reduce-shake; tune `feel_profile.tres`.
- **Dependencies**: M8b.
### M9: Act 2, Toybox (L)

- **Scope**: rooms `tb1`-`tb4` and `tbo` at GREYBOX; the Knight family in full (attack clip, destination shadow); the toy-train hazard; the Knight Captain (HP 10, the "may move twice" mid-fight Book flip in grey pencil); **Rule Step granted in the `tb3` alcove** with its forced first use in `tb4`; the first scripted block (silent during the fight, one word at room clear); hub state 1; the Bookshelf lock; the painted-vista awe slot; the Charging Pawn and Knight Errant Pages and the `tb2` keepsake; Lead Tip and shard 2; the first format-breaker (`tb3`'s train chase), which adds the `reach` and `survive` objective kinds to `ObjectiveSystem`; Act 2 beats S08-S11; threat budgets; the route test's stubs replaced; the route bot's measured times replace the estimates in §7.4.
- **Acceptance**: Knight telegraph and landing tests; boss tests; `test_relief_after_boss` (R16); `test_threat_budget`; `test_preview_before_lethal`; `test_objective_kinds`; the route test.
- **Owner can try (OG3)**: Stage 1 plus Toybox start to finish (about 40 minutes); the first Rule Step over the lid gap.
- **Dependencies**: M8c.

### M10: Act 3, Bookshelf and the child intervention system (L)

- **Scope**: the Bishop family (the growing lane built on `ray_cells` and attack stages; the Oracle's mirrored beams as redirect-cell props); Believe (`Believe` component, HUD marks and hit pip), `cell_effects` and `CellEffectSystem`, Chalk Path, the `TraversalGap` marker (free cast with no hostile alive), `child_help` and `help_next`, `allowed_calls`, `child_calls_used`, the hand integration; rooms `bs1`-`bs4` and `bso`; the Slant rescue; the Bishop Oracle (HP 12, scripted chalk bridges in P3, the puzzle-form fight); the Chalk Path unlock with Believe full; hub state 2; the Block Tower lock (a free gap); Act 3 beats S12-S15; the `bs2` keepsake; the `bs3` page-slide format-breaker.
- **Acceptance**: cell-effect expiry; enemies may walk on chalk; a refused cast costs nothing; a traversal gap costs 0 Believe outside combat; Believe refill rules; the mirror bounce (once); the Bishop growth telegraph; boss tests; `test_allowed_calls`; `test_child_help_not_damage`; **`test_no_softlock_resources`** (R33: Believe 0, Courage 1, cooldowns running, chalk expiring mid-gap).
- **Owner can try**: Act 3; call chalk across a tear.
- **Dependencies**: M9.

### M11: Act 4, Block Tower, Pages UI and Midpoint (L)

- **Scope**: the Rook family (rays that stop at blockers, Wooden and Iron, the turn tell); Eraser Guard (`blocks_tags` as data), Perfect Rub and Rule Marks; **Chalk Block** as the worked example of a new effect kind (it also blocks Knight landings); rooms `bt1`-`bt4` and `bto`; the Stout rescue; the Rook Warden (HP 14, the throne in P3, the endurance-hold fight); the Pages tab complete (all states and the equip rules); the Midpoint cutscene at H1 (the confession, both inks one hand, a painted-vista awe slot); hub state 3; Act 4 beats S16-S18; the `bt2` hold-the-line objective; the `child_trust` rise check. **Probe P2.**
- **Acceptance**: rays stop at blockers; the guard negates only `line`-tagged hits from the faced side; the Perfect Rub timing window; Chalk Block against Rook charges and Knight landings; armored-face recoil; boss tests; Pages UI tests.
- **Owner can try**: hold a Rook charge; the Midpoint.
- **Dependencies**: M10.

### M12: Act 5, Dollhouse (M)

- **Scope**: the Queen of Tricks (HP 16): lane combinations (limited simultaneous), Command Mark commanded pawns, **Seize Toy**, Tear the Drawing (the R22 gating, the hand-stop, the promotion offer "Rank up. Be kept.", the 20 s quiet beat, abbreviated on retry); the latch-lifts seal opening with the chord-denial foreshadow; rooms `dh1`-`dh4`; the royal seal lock needing Eraser Guard; hub state 4; the `dh2` keepsake; Act 5 beats S19-S21. The route test asserts `child_calls_used` is 3 or more before `dhb`.
- **Tier B**: the `dh1` tea-party format-breaker.
- **Acceptance**: the R22 sequence test, `test_quiet_beat_after_disable`, boss tests, the mixed-court guard test (diagonals and leaps ignore it), `test_calls_before_queen`.
- **Owner can try**: the Queen's address and the loss of help.
- **Dependencies**: M11.

### M13: Act 6 and the Ending (L)

- **Scope**: the Black King and Rule Engine (HP 18, 4 phases, Reverse Color once, `active_rule_modifier`); **`DirectionLock`** with restore events through three memory alcoves (a crayon outline stands in for an un-rescued piece); tile rewrites as `corruption` cell effects; **Free Step** (modifier, chord and the 10 s rehearsal beat); rooms `ub1`-`ub3` (the `waves` objective); the `boxed` hub state and the S22 cut to H1; the **playable ending** `e1` (promotion tokens as props, the `OUTSIDE_BOARD` exit, the zero-damage last 3 minutes, the 10 s hold); credits; the post-game title and Continue-on-completed (`post_game_zone`); hub state 5 with the Desk reachable and its reveal referencing 4 or more clues; Act 6 beats S22-S26. **Probe P3.**
- **Cut-first rule**: if this milestone slips, `DirectionLock` is the first item cut (§1.4 Tier B 8); P3 then reduces to help-blocked and the memory alcoves become lore.
- **Acceptance**: R23 (no damage within 30 s of a withdrawal), `test_ending_audit` (R30, including that the last input before the hold is a step), the final blow is player-executed, directions never soft-lock, `test_free_step_window`, `test_free_step_rehearsal`, `test_hub_boxed_state`, `test_continue_after_completion`, `test_clues`, the route test with real bosses.
- **Owner can try (OG4)**: the whole game; the King fight, the free diagonal step, the ending.
- **Dependencies**: M12.

### M14: Completeness and handoff (L)

- **Scope (Tier A)**: `MusicDirector` completed (crossfade, stems, ducking, `music_cues` coverage); `sound_bank` coverage audit and generated placeholders for every event; accessibility complete; the art contract (`export_art_templates.gd`, `art_contract_check.gd`, hash-based `list_placeholders.gd`, flagged placeholder sprites for rook, queen, king, bishop and bosses, the animation manifest of §12.1); the tuning pass with the attempt logger; `OWNER_GUIDE.md` (bilingual) and `content/README.md`; the Change Table dry run of every row on a temp copy; handoff notes (Open/Tune/Goal/Try/Tell me); `docs/playtest-form.md`, the QA templates (smoke checklist, room QA, combat-feel log, bug format) and the performance budget test; `/new-room` and `/new-beat`; architecture guards enforcing; `LICENSE` and `THIRD_PARTY_NOTICES.md` complete (with the Knight silhouette provenance); `tools/print_arc.gd` and `test_arc` (R32); the R19/R20 checklists; the grayscale readability pass; the package notes (controls, known issues, version); the final ledger pass (D25); no `STUB` left.
- **Tier B** (cut in the order of §1.4): the macOS export smoke from a tracked preset template (`export_presets.cfg` is gitignored, so a template is tracked) with the route test run on the exported binary (to prove `ContentDb`'s directory scan works in an export) and an export filter that excludes tools, tests and docs; a CI workflow file; the colour-blind simulation pass; flag-registry drop-downs and `renamed_from` save migration; the dialogue log; the first-run card; the night tint; ambience rows.
- **Acceptance**: `run_all_tests.py --strict` green; the full route test; `test_art_contract`; `test_change_table_dry_run`; `test_requirements_ledger`; zero stubs; the telegraph, threat-budget, emotion-field and text-key lints green.
- **Owner can try**: everything; the placeholder TODO list.
- **Dependencies**: M13 (audio work may start in parallel from M8c).

### Parallelism and rollback

- After M5, M6 (story) and M7a (skills) may run as two lanes with disjoint file ownership, because M3a landed every shared field and M4 split the HUD, the schedule and the `.po` files. If those splits are not in, run them sequentially. A third lane may start on M14's audio items from M8c. From M9 on, content milestones are sequential because they share the boss framework and the attack stages.
- All lanes write per-lane progress fragments to `docs/progress/` and one integrator merges them. Each parallel worktree runs `tools/bootstrap_worktree.sh` first.
- M1b runs in its own worktree while the owner is not editing. Every milestone is tagged. If a milestone fails its acceptance, revert to the previous tag; folder-move commits are independent, so one folder can be reverted alone.
- The deterministic dump (not screenshots) is the cross-milestone regression check. Real-renderer captures are owner-review artefacts.
## 16. Risks, and how each milestone verifies itself

### 16.1 Risks

| # | Risk | Likelihood / impact | Mitigation | Verified in |
|---|---|---|---|---|
| 1 | Folder moves break references: path-only `ext_resource` lines, about 40 `res://` string literals in `.gd` files, `project.godot`, tool `OUT_DIR` | high / high | `tools/stamp_uids.gd` first; `tools/move_res.py` rewrites strings and sidecars; one folder per commit with the suite and the dump after each; `tests/support/paths.gd` asserts files exist | M1a, M1b |
| 2 | **The UID step destroys UIDs.** A headless `ResourceLoader.load` plus `ResourceSaver.save` (the editor tool or the `update_project_uids` MCP tool) added 0 uids and turned every uid ref path-only (213 to 251 of 251) | high / high | a text-level stamper that never calls `ResourceSaver`; every tool that saves scenes writes text or runs the stamper last; `test_no_path_only_ext_resource` | M1a |
| 3 | A script error in a suite's `_init` hangs the Godot process, so a gate never finishes | high / high | `UnboundTest` 30 s watchdog; the runner spawns each suite with a timeout and fails on `SCRIPT ERROR` | M1a |
| 4 | A stale `res://` path makes a file-read check pass vacuously (empty string) | med / high | `paths.gd` asserts `file_exists`; file-read checks assert non-empty content; lints assert a minimum file count | M1a |
| 5 | "Tests unchanged" is unprovable; the suites call deleted classes and old signatures | high / med | the baseline-label manifest and `label_renames.txt`; tests are retargeted in the same commit as the change | M1a-M7b |
| 6 | The actor-scene collapse drifts a node path or baked field | med / high | golden oracle on every actor and the per-room entity set; deterministic dump compare | M2 |
| 7 | Autoloads are null in `_init`-time suites, so registry-dependent tests fail or silently skip | high / med | `ContentDb` is a static class; the two autoloads are injectable | M2 |
| 8 | The `main.gd` split changes travel, fade, death or carry ordering | med / high | bridge characterization tests land against the current `main.gd` first and are then ported; one responsibility per commit; the old path stays until they pass | M1a, M3b |
| 9 | Save v3 migration wipes progress | med / high | v2 fixture; keep the v2 loader until confirmed on a real save; atomic write plus `.bak`; a corrupt or newer save is never overwritten | M3b |
| 10 | Pause and Book cannot close because they poll keys | med / med | all keys are `InputMap` actions handled by `PROCESS_MODE_ALWAYS` nodes; pause blocked during travel | M4 |
| 11 | Dismissing a dialogue with Space swings the sword | med / med | dedicated `dialogue_advance`; 2-frame input guard | M6 |
| 12 | The skill refactor regresses feel (timers, buffering) | high / high | Sword and Pencil stay on `CombatSystem` while new verbs land on `SkillSystem`; the cutover happens in M7b behind a 1:1 parity checklist; the buffer-expiry change is explicit; the OG2 feel gate | M7a, M7b |
| 13 | The enemy attack model cannot express Rook charges, growing lanes, leaps, unions or tile rewrites | high / high | M8a lands `AttackStage` before any new family; one owner of `EnemyAISystem` | M8a |
| 14 | Hit-stop leaves `time_scale` below 1 after a reload | med / med | reset in `_exit_tree` and every transition; test | M8c |
| 15 | A* cost on large boards or many entities (the per-call rebuild at `ecs_grid.gd:170`, the board scan at `enemy_ai_system.gd:199`) | med / med | cached `AStarGrid2D` by `layout_version`; boards capped at 18x9; leash; bounded search; `test_room_tick_budget` | M3a, M8a |
| 16 | A Believe or resource state soft-locks the child's help at an enemy-free door | high / high | D-41 (refills at hub, checkpoints, boss defeat; free `TraversalGap` casts); the resource-state walk R33 | M10 |
| 17 | Free Step is an untrained input at the climax | high / high | R34: denial from T1, a rehearsal beat, a modifier alternative, a tested chord window | M6, M13 |
| 18 | Too much content for the budget; Act 6 is thin | med / high | scope tiers (§1.4) with an ordered cut list; stubs exist from M5 so the chain always plays; `DirectionLock` is the first cut in M13 | M5, M13 |
| 19 | Emotional beats feel flat because tone is the owner's, or the child feels like a menu | high / med | placeholder prose flagged; peak-end design first; the zero-text presence layer; relationship-keyed presentation; the clue chain; music from M6; probes P1-P3 | M6, M8c, M11, M13 |
| 20 | Telegraph unfairness hides in boss data | med / high | R6 over every `AttackBase`; threat-budget lint; death freeze-frame; phase checkpoints | M8a-M8c |
| 21 | Re-creating the owner's 2026-07-28 cut under new names (shrines, promotion levelling) | med / high | D-13, D-40, T-5 to T-7 in §2.3; Rank is a label nothing reads | M7c |
| 22 | Presentation writes the simulation, or beats grant skills outside `ProgressionSystem` | med / med | `world.commands`, `HudSnapshot`, the architecture test, no `Grant` step | M3a |
| 23 | The owner has not play-reviewed Stage 1 (0 of 77 items accepted, `where`) and may reject the feel late | med / high | gates OG1-OG4 and the OG0 approval gate; defaults logged when there is no reply | M5, M7b, M9, M13 |
| 24 | The owner rejects the room-graph world (2026-07-29 verdicts) | low / high | the monotony guard of D-02; the semi-open fallback (O-9) | M5, M9 |
| 25 | The owner's dirty editor files are clobbered | med / med | stage explicit paths; never `git add -A`; leave `.mcp.json`, `reports/`, `research_notes/`; M1b in a separate worktree | all |
| 26 | A new `class_name` is not visible to headless scripts | high / low | the runner does the `--editor --quit` import pass first | all |
| 27 | Parallel lanes conflict on hot files | med / med | M3a lands every shared field; per-phase schedule files; per-domain `.po`; one scene per HUD widget; `bootstrap_worktree.sh` | M3a, M4, M6, M7a |
| 28 | A real renderer is unavailable in the agent sandbox, so frame capture gates are flaky or silently skipped | med / med | the deterministic headless dump is the gate; G7 runs only if M1a proved the renderer works | M1a |
| 29 | Addon pressure (Dialogue Manager, GECS) | low / low | built-in default; explicit "needs owner approval" | §8.10 |
| 30 | `.po` domains registered as one locale do not merge `[unverified]` | low / med | `test_po_domains_merge` runs before M4 relies on it; fallback: one `.po` per locale | M4 |

### 16.2 Global verification gates (every milestone)

- **G1**: `python3 tools/run_all_tests.py --strict` green, including all suites added by the milestone and every baseline `PASS:` label.
- **G2**: `godot --headless --path . --editor --quit` prints no ERROR or Parse.
- **G3**: `git diff --check` is clean.
- **G4**: the route test passes (boot -> credits) from M5 on.
- **G5**: architecture guards (report-only in M1a, enforcing for each rule as it lands), including `tools/stamp_uids.gd --check` (zero path-only references) and the sidecar check.
- **G6**: the deterministic headless dump of the affected rooms equals the previous milestone's. Real-renderer screenshots are owner-review artefacts, not gates.
- **G7**: an unattended 60-120 s real-renderer boot with `--quit-after`, only if M1a proved a renderer runs in the agent sandbox. The exact command and a perceptual tolerance are recorded then; otherwise the gate is skipped and logged.
- **G8**: a handoff note for the owner: Open, Tune, Goal, Try, Tell me. Feel, art and prose are accepted only by the owner's play review (`docs/owner-review-template.md`).
- **G9**: emotional probes P1 (M8c), P2 (M11), P3 (M13) with the five-question form of §3.6.

### 16.3 Per-milestone self-check summary

| M | Proves itself with |
|---|---|
| M1a | the runner on the unchanged tree; baseline labels captured; bridge tests green on the old `main.gd`; the stamper on a scratch copy; the bus test; the ledger test |
| M1b | identical baseline labels; zero old `res://` prefixes; zero path-only references; sidecars; dump equality |
| M2 | the actor-collapse golden oracle; `validate()` over all definitions; ids = folders; the registry inside `_init` |
| M3a | schedule order and completeness; frozen world; commands; input snapshot; grid kinds, leap and ray tests; player snapshot; perf budget |
| M3b | ported bridge tests; save round-trip and migration; checkpoint rules; respawn without a scene reload |
| M4 | pause freezes ticks; pad events; text keys; `.po` merge; pseudo-locale; HUD safe zone |
| M5 | the full-route test; the world-graph audit; the §7.4 table lints |
| M6 | beat reachability; skip equals play; T1 audit; child voice; time to control; chord denial |
| M7a | skill cooldowns; Rule Step; data-only skill; HUD slots from data |
| M7b | combat parity checklist; buffer; move lock; stagger; the OG2 feel gate |
| M7c | progression ledger; Margin; page modifiers data-only; pages reachable |
| M8a | attack stages; telegraph contract; tuning; Knight leap occupancy |
| M8b | boss phases, checkpoints, persistence; player-kill-only |
| M8c | death, retry, juice restore, reset variants, flash rate, decision gap |
| M9-M13 | per-district boss, relief, preview, budget, verb-exam and resource-state tests; the route test with real content; probes |
| M14 | art contract; Change Table dry run; requirement ledger; zero stubs; the strict suite |
## 17. Review points not taken

Every blocker and major issue in the four reviews is fixed, and every "missing" item is either built, scheduled in a named milestone, or listed here. Points that were rejected or only partly taken are below, each with a one-line reason. "Modified" means the intent was taken in a different form.

### From the technical review

| Review point | Outcome | Reason |
|---|---|---|
| Cap arenas at 18x9, **or 16x9 with in-room hazards** | Modified: 18x9 | 64-96 px bosses need the width, and a centred origin plus the HUD safe zone fixes the overlap without shrinking the arenas. |
| Auto-discover systems from `ecs/systems/**` (a `PHASE` const) | Not taken | Directory scans behave differently in an exported build and give no explicit order; one file per phase plus `test_schedule_complete` catches a forgotten system and stays merge-safe. |
| Put `ViewSyncSystem` under `presentation/` instead of allowing the single edge | Not taken | `CLAUDE.md` places it in the simulation and says only it touches nodes; one documented edge in `allowed_edges.txt` is cheaper than moving the system. |
| Spawn suites from Godot (`OS.execute_with_pipe` / `create_process`) | Modified: Python subprocess runner | `subprocess.run(timeout=...)` gives a hard kill and exit codes with less code, and the repo already ships Python tools. |
| Keep `layout.txt` and add a drift test | Modified: `tools/layouts/` plus "never overwrite an existing scene" | A refusal to overwrite removes the drift instead of detecting it. |
| Defer the font licence together with the `vi` locale | Partly taken | Shipping `vi.po` and the glyph test are deferred, but `LICENSE` and `THIRD_PARTY_NOTICES.md` are Tier A: they are cheap and the credits need them. |
| Keep only mechanical lints | Modified: two tiers | Soft lints stay as editor warnings (and fail only `--strict` agent gates), because they protect the design without failing the owner's rewrites. |
| Ship Chalk Block as an extension recipe, not a verb | Modified: shipped | Act 4's child layer and the Rook counter need it, and it is the one worked example of a new effect kind. |
| Make macOS smoke "or track a preset" a hard item | Modified: Tier B | `export_presets.cfg` is gitignored, so a tracked template plus the smoke is cut-first. |
| Replace a typed read-only facade with component reads | Modified: `HudSnapshot` DTO | A built DTO stops presentation depending on `ecs/components` at all, which the edge test can then enforce. |

### From the emotion and story review

| Review point | Outcome | Reason |
|---|---|---|
| Free Step chord window with a **0.12 s floor** | Not taken | A 0.12 s hold-off would add 0.12 s latency to every step, worse than the 0.18 s step; the window is 0.07 s with a 0.05 s floor, plus a modifier alternative, denial from T1 and a rehearsal beat. |
| Refill Believe at "any Rest Square" | Modified: at checkpoints | Rest Squares are removed (D-40), so the same refill happens on hub entry, boss-room entry and boss defeat. |
| Fallback rehearsal of three calls in `dh3` if the counter is under 3 | Not taken | Four forced free calls on the critical path make the counter 3 or more by construction, so no fallback beat is needed. |
| A `Free Step` practice gap in `ub1` or `ub3` | Modified: the rehearsal beat at the start of P4 | Practice before P4 would spend the peak; the first diagonal the player ever makes must still be the King's open cell. |
| Six objective kinds (escort, protect the prop, obey the rules, ...) | Partly taken | `clear`, `reach`, `survive` and `waves` ship; escort, protect-the-prop and obey-the-rules are recipes, and the `dh1` tea party is Tier B. |
| Three outside playtesters per probe | Partly taken | Agents cannot recruit testers; the base ships the form, the logger and the three probe points, and the owner supplies players. |
| Text-first script importer | Modified: Tier B | The compiler and exporter are Tier A; writing prose back to `.po` is a convenience that can be cut. |
| A bespoke tool comparing reported emotion with `emotion_target` | Not taken | A spreadsheet column does the same job; no code is worth writing before real testers exist. |

### From the completeness review

| Review point | Outcome | Reason |
|---|---|---|
| Put the ledger in an "Appendix A" | Modified: §1.5 | The section list is fixed at 16 plus this one, so the ledger is §1.5 with its rows in files `01b` and `01c`. |
| List every `RULE`-only and `PROPOSAL` row in an owner-confirmation table | Partly taken | Only rows whose flip cost is more than one data edit are in §2.2-§2.3; the rest are already marked in §2.1 with an "Easy to change by" cell. |
| O-items for "EntitySpawn versus parked views" and the timing of the `SkillDefinition` convergence | Modified | `EntitySpawn` is cut (D-28), so there is nothing to ask; the convergence is placed after the new verbs (M7b) and recorded in §15. |
| Write `OWNER_GUIDE.md` and the handoff notes in Vietnamese | Partly taken | Bilingual with English authoritative, because agent-written Vietnamese cannot be reviewed by the plan's author. |
| Xbox, PlayStation and Switch glyph sets, a remap conflict rule, rumble | Partly taken | Two glyph sets with hot-swap ship; console skins are an art task, a remap UI is deferred so a conflict rule has no home, and "no rumble" is an explicit decision. |
| A CI workflow | Modified: Tier B | CI needs a Godot binary in the runner; a documented local equivalent (`tools/run_all_tests.py --strict`) ships first. |
| Colour-blind simulation pass, dialogue log, first-run card in the base | Modified: Tier B | They are UI-only or review-only and cannot block a Tier A test. |
| Caption UI, caption size and background options | Deferred (waiver) | The `caption_key` data ships on every `sound_bank` row; the UI is req#195's "should" and is listed in §1.2. |
| A tap-sequence alternative for the rescue hold | Modified: hold-or-toggle | One setting covers every hold action, including the rescue. |
| Windows and Linux export, notarization | Deferred (waiver) | Release lane; notarization needs the owner's Apple account (§1.2). |

### From the progression and ECS review

| Review point | Outcome | Reason |
|---|---|---|
| Remove "cleared rooms stay cleared" | Not taken, flagged | The review asked for a yes or no; the default is yes (shortcuts home are one-way, backtracking would be a chore) and it is T-5 with a one-field flip. |
| Unify attacks by converting enemies and bosses into `SkillDefinition` (option A) | Not taken | Option B (`CellPattern` plus a common `AttackBase`) gives one lint target without rewriting every enemy attack. |
| Handlers for all six `PageModifier` kinds | Partly taken | Handlers ship for the three the base uses (`ParamOverride`, `ChainWindow`, `MoveRule`); `TagFilter`, `ConditionalStat` and `GrantSkill` ship as schema with a recipe (§6.10). |
| A grep over `ecs/` and `presentation/` for economy-value literals | Not taken | A numeric-literal grep is brittle and noisy; `rules.tres` is the single home and `test_page_modifiers_data_only` guards the page ids. |
| Flag drop-downs via `_validate_property` and `renamed_from` save migration | Modified: Tier B | `ContentDb.validate_cross_refs()` and the flag registry catch typos now; the editor niceties are cut-first. |
| Sound-id and sprite-sheet overrides in `VisualDefinition` | Modified: Tier B | CLAUDE.md puts motion sounds in the clips; the change table says honestly that a motion-sound swap is an editor task. |
| Seven verbs including In Passing | Not taken | In Passing had no valid trigger enemy where it was taught and broke three Pages; it is recipe E1 (§6.10). |
| Pages Passant Wraith, Promoted Zealot, Black Queen, Bishop of Order, Rook Warden | Deferred | Five Pages ship, each tied to a placed enemy; the rest are recipes E3. |
| Rest Square as the Believe and Courage refill point | Not taken | It is a bonfire in everything but name (the 2026-07-28 cut); checkpoints do the job (D-40). |
