# Requirement ledger

One row for every entry of `docs/requirements.json` (`requirements[0..248]`, zero-based: `req#45` is "Place Paper Bridge over broken tiles"). Each row says which plan section answers the requirement, which milestone delivers it, which test proves it, and what became of it.

Written in M1a from section 1.5 of `docs/game-base-plan.md` (v1.1, branch `game-base`). `tests/content/test_requirements_ledger.gd` parses this table and fails when an index is missing or repeated, or when a `m` (must) row has no plan section, no milestone, or neither a verifying test nor a waiver.

## Columns

- **req#**: zero-based index into `requirements` in `docs/requirements.json`. Never renumber; new requirements are appended.
- **P**: priority from `requirements.json` (`m` must, `s` should, `c` could).
- **System** and **Requirement**: copied from `requirements.json` (the requirement on one line).
- **Plan section**: where `docs/game-base-plan.md` answers it (`§` numbers, `D-xx` decisions, `T-x` standing-rule triggers).
- **Milestone**: the `docs/game-base-plan.md` §15 milestone that delivers or keeps it. `exists` means the current tree already does it; `n/a` marks a requirement the base does not build (a waiver or a decision replaced it).
- **Verified by**: the test, baseline labels, tool or checklist that proves it. `n/a` marks a requirement the base does not build.
- **Status**: `covered`; `amended D-xx` (or `T-x`), meaning the plan deliberately changed the requirement and the decision says how; `deferred W`, an owner-waivable deferral listed in plan §1.2.
  `partial: <what is missing>` is not covered: the plan answers the requirement and something verifies part of it, but the named gap is still open (a content defect, a Tier B file that does not exist, a rule only review can check). The test fails a `partial` row that does not name its gap and prints how many rows are partial.

## Updating the ledger

- A milestone that delivers a requirement keeps its row and replaces a planned test name with the real one if it differs.
- Keep one table row per line and do not put a `|` inside a cell; the test splits on it.
- A `m` row may only be marked `deferred W` with the owner's agreement (plan §1.2).

## Ledger

| req# | P | System | Requirement | Plan section | Milestone | Verified by | Status |
|---|---|---|---|---|---|---|---|
| 0 | m | movement | One-cell cardinal step per input, no diagonal movement | §5.1 | exists; M3a keeps | baseline labels | covered |
| 1 | m | movement | Step duration about 0.16-0.20 s (target 0.18 s) | §5.1 | exists; M3a keeps | baseline labels | covered |
| 2 | m | movement | Held direction repeats a step after about 0.22 s | §5.1 | exists; M3a keeps | baseline labels | covered |
| 3 | s | movement | Input buffer of about 0.12 s that expires (code buffers one direction with no expiry) | §5.1, §9.4 | M7b | test_input_buffer | amended T-1 |
| 4 | m | movement | Pawn faces its last movement direction, also when the step is blocked | §5.1 | exists | baseline labels | covered |
| 5 | c | movement | A dangerous step may be cancelled only before the pawn leaves its start cell | §1.2 | n/a | n/a | deferred W |
| 6 | m | movement | Shift+direction turns instantly without moving or reserving a cell | §5.1 | exists | baseline labels | covered |
| 7 | s | movement | Turning cannot interrupt an active step or an attack impact window (turn branch currently runs before the moving check) | §5.1 | M7b | test_turn_lock | covered |
| 8 | s | movement | Blocked step gives visible or audible bump feedback, never silent input loss (step_blocked event has no consumer in main.gd) | §10 | M8c | test_step_blocked_feedback | covered |
| 9 | m | movement | Reserve-then-commit grid occupancy; both cells held during a step; no collision mid-step | §5.11 | M3a | test_leap_occupancy; baseline labels | covered |
| 10 | s | movement | Pixel-snapped motion and camera, no subpixel blur (camera eases with smoothing_speed 8.0, no snap found) | §10, D-30 | M4 | test_camera_snap | covered |
| 11 | m | input | Every gameplay verb has a keyboard and a controller mapping (project.godot has zero joypad events) | §9.4 | M4 | test_input_actions_have_pad_events | covered |
| 12 | s | input | Full input remapping | §1.2 | n/a | n/a | deferred W |
| 13 | m | input | InputMap actions for Interact (E), Call child (R), Select help, Focus, Pause (project.godot holds only move, attack, skill_1, turn_mode, restart_room) | §9.4 | M4, M7a | test_input_actions_have_pad_events | covered |
| 14 | s | input | B, F3 and F11 become InputMap actions instead of raw key polls | §9.4 | M4, M7a | test_input_actions_have_pad_events | covered |
| 15 | m | input | Room restart must not share the R key with Call child; restart moves to pause menu or hold | §9.4, D-18 | M4 | test_pause_restart_is_menu_only | covered |
| 16 | s | input | Controls explainable in one small panel (today a static HelpLabel) | §9.2 | M4 | test_controls_panel_from_inputmap | covered |
| 17 | m | combat | Wooden Sword hits one adjacent cell in the facing direction; damage lands on the impact frame | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 18 | m | combat | Sword recovery about 0.30 s so spamming is worse than reading | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 19 | m | combat | Pawn cannot move during the first part of a swing (MovementSystem never reads PlayerCombat) | §5.1 | M7b | test_move_lock | amended T-8 |
| 20 | s | combat | A hit staggers common enemies briefly | §5.1 | M7b | test_stagger | amended T-8 |
| 21 | s | combat | Attacking an armored face causes recoil and no damage | §5.1 | M11 | test_armor_recoil | covered |
| 22 | m | combat | No combo strings | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 23 | m | combat | Target cells locked at swing start; one damage application per swing | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 24 | m | combat | Player invulnerability window after a hit (0.7 s) | §6.3 verb 1 | M7b | test_combat_parity | covered |
| 25 | m | combat | Pencil Thrust: two-cell line on Q, impact 0.11 s, recovery 0.52 s, cooldown 1.25 s | §6.3 verb 2 | M7b | test_combat_parity | covered |
| 26 | m | combat | Enemy telegraph locks target cells so stepping out dodges; token released on dodge | §5.10 | M8a | test_attack_stages; baseline labels | covered |
| 27 | m | combat | One room-level attack token prevents simultaneous enemy strikes | §5.10 | M8a | test_attack_stages; baseline labels | covered |
| 28 | s | combat | Hit feedback: flash, chip particles, small shake (stronger on player damage), hit-stop only if it helps clarity | §10 | M8c | test_hit_stop_restores_time_scale | covered |
| 29 | m | combat | Sword attack refused before the sword unlock, with HUD feedback | §6.3 | M7c | test_unlock_gating | covered |
| 30 | s | combat | Player loadout of one toy weapon plus up to two Imagination skills, changed only at safe zones | §6.4 | M7c | test_pages_margin | amended D-12 |
| 31 | s | combat | Weapons change rhythm and geometry (Pencil Spear, Ruler Blade, Eraser, Chalk Line), not stats; the player must be able to pick weapons up (only enemies take items today) | §6.3 | M7a, M7b | test_skill_cooldowns | covered |
| 32 | s | combat | Focus: hold to emphasise enemy telegraphs without stopping time | §10 | M8c | test_focus_emphasis | covered |
| 33 | c | combat | Assist option that slows enemies while the pawn is stationary | §5.8 | M8a | test_tuning_scales | covered |
| 34 | s | combat | F3 debug overlay explains each enemy decision, off by default in builds | §9.2 | M14 | test_debug_overlay_default | covered |
| 35 | m | skills | Rule Step: fast two-cell emergency move with cooldown, earned from the Knight boss | §6.3 verb 3 | M7a | test_rule_step | amended D-37 |
| 36 | m | skills | Chalk Path: child-assisted temporary walkable route, earned from the Bishop boss | §6.3 verb 4 | M10 | test_chalk_rules | covered |
| 37 | m | skills | Eraser Guard: guard or parry against straight-line attacks, earned from the Rook boss | §6.3 verb 5 | M11 | test_guard_tags; test_perfect_rub | covered |
| 38 | m | skills | Final Rule Break: one-time story power (first unassisted diagonal step) that opens the Black Castle and ends the King | §6.3 verb 6 | M12, M13 | test_free_step_window; test_free_step_rehearsal | amended D-14 |
| 39 | m | skills | Each skill has a boss or room that earns it, a safe teach, a combat test, an optional mastery use | §6.6 | M5, M9-M13 | test_verb_exam | covered |
| 40 | m | skills | Skills change decisions and never replace one-cell movement | §6.2 P1-P7 | M7a | test_rule_step | covered |
| 41 | m | skills | HUD shows only unlocked skills with cooldown (Q THRUST only today) | §6.2 | M7a | test_hud_slots_from_data | covered |
| 42 | m | child | Child intervention system with a Believe meter (max 2 calls; refills from hits, rescues, brave acts; bosses give controlled refills) | §5.5 | M10 | test_believe_rules | covered |
| 43 | m | child | Place or Move Block on a highlighted empty cell: stops projectiles, Rook charges, Knight landings; not under a unit | §5.5 | M11 | test_chalk_block | amended D-37 |
| 44 | m | child | Draw Chalk Path across up to three gap cells; fades in boss arenas | §6.3 verb 4 | M10 | test_chalk_rules | covered |
| 45 | s | child | Place Paper Bridge over broken tiles | §1.2, §6.10 | n/a | n/a | deferred W |
| 46 | c | child | Erase Rule Mark disables a marked hazard or lock briefly | §1.2, §6.10 | n/a | n/a | deferred W |
| 47 | c | child | Hold Ruler Gate opens a shortcut or timed path | §1.2, §6.10 | n/a | n/a | deferred W |
| 48 | c | child | Turn the Board rotates an authored marked room section 90 degrees | §1.2, §6.10 | n/a | n/a | deferred W |
| 49 | c | child | Gentle Nudge moves the pawn one otherwise illegal diagonal cell with brief immunity | §2.1 D-14 | n/a | n/a | amended D-14 |
| 50 | m | child | Help changes the room, never enemy HP, and cannot clear a phase by itself | §5.5 | M10 | test_child_help_not_damage | covered |
| 51 | s | child | Targeting mode: valid cells in blue within 5 cells, time slows to 35 percent, cancel costs nothing | §2.1 D-20 | n/a | n/a | amended D-20 (waiver) |
| 52 | m | child | Child hand sprite: larger and smoother than the chess world, never a cursor or divine beam (160x120 or larger) | §12 | M6 | test_art_contract | covered |
| 53 | s | child | Child actions animate physically, slower and heavier than pawn combat | §5.5 | M6, M10 | manual feel checklist (M14) | covered |
| 54 | s | child | Child intervention sounds from crayon, paper, block, eraser, cloth | §11 | M6 | test_sound_bank_coverage | covered |
| 55 | m | child | Bosses can temporarily disrupt help (Queen Tear Drawing, King Close the Box) | §5.4 | M12, M13 | test_quiet_beat_after_disable | covered |
| 56 | m | child | Interventions authored per room (allowed types and placement) | §5.5, §7.5 | M10 | test_allowed_calls | covered |
| 57 | s | child | Crayon-blue visual language reserved for child help | §10 | M8c | palette lint (R7) | covered |
| 58 | m | health | Three Courage points; boss signature attacks may remove two | §5.1 | exists | baseline labels | covered |
| 59 | s | health | Rescued white pieces restore one Courage at fixed safe locations; three optional rescues | §2.1 D-34, D-40 | M3b, M6 | test_checkpoint_rules; test_rescue_in_h1 | amended D-34 |
| 60 | m | failure | On defeat return to the latest checkpoint with the room reset; no progress lost (code reloads the scene at the last entry) | §5.2 | M3b | test_checkpoint_rules; test_owner_guide_steps | amended D-16 (read the least punishing way: the pawn returns to the entry of the room it fell in; the checkpoint is where Courage refills) |
| 61 | m | failure | Boss defeat resets the boss room to phase one, retries are fast | §5.4, D-43 | M8b | test_boss_phase_checkpoints | amended D-43 |
| 62 | m | failure | Checkpoints before bosses, at hubs, after major rewards | §5.2 | M3b | test_checkpoint_rules | covered |
| 63 | m | failure | Pickup reset rule: room pickups reset unless marked persistent (code keeps every taken pickup forever) | §9.3 | M3b | test_pickup_persistence | covered |
| 64 | s | failure | Low-health state gets feedback (colour change only today) | §10 | M8c | test_low_health_feedback | covered |
| 65 | s | failure | Death rule explainable in one sentence; copy 'The child resets the board' | §4.6 | M8c | prompt.reset in test_prompts | covered |
| 66 | m | save | Major unlocks persist across death | §9.3 | M3b | test_save_roundtrip | covered |
| 67 | m | save | Persist zone, entry, taken pickups, opened gates, unlocks, rule pages to disk | §9.3 | M3b | test_save_roundtrip | covered |
| 68 | m | save | New Game, Continue and a clean-start path (WorldState.reset has no caller) | §9.1 | M4 | test_new_game_resets_slot | covered |
| 69 | m | save | Cleared rooms and defeated bosses persist (bosses never reset) | §9.3, §5.4 | M3b, M8b | test_save_roundtrip; test_boss_defeat_persists | covered |
| 70 | m | save | Settings (volume, shake, accessibility) persist | §9.2 | M4 | test_settings_roundtrip | covered |
| 71 | s | save | Save format versioned so it can grow; an old save must not break a new build | §9.3 | M3b | test_save_migration_v2 | covered |
| 72 | m | enemy-pawn | Pawn Recruit: moves one cardinal cell, faces last move, slow diagonal telegraph, long recovery | §5.3 | M8a | test_enemy_identity_table; baseline labels | covered |
| 73 | m | enemy-pawn | Armed pawns: a toy weapon replaces the diagonal attack; Pencil Spear two straight cells, Ruler Blade front plus forward diagonals | §5.3 | M8a | test_enemy_identity_table; baseline labels | covered |
| 74 | s | enemy-pawn | Pawn variants each bend exactly one rule: Backstep and Charging exist, Passant Wraith and Promoted Zealot do not | §5.3, §6.10 | M9, M10; Wraith and Zealot deferred | test_enemy_placement | deferred W (Wraith, Zealot) |
| 75 | c | enemy-pawn | Veteran and Desperate pawn variants | §1.2, §6.10 E7 | n/a | n/a | deferred W |
| 76 | m | enemy-knight | Knight: L-shaped locked telegraph, leap, left vulnerable after landing; used in rooms (data exists, only the standalone first_encounter.tscn uses it) | §5.3 | M8a, M9 | test_knight_leap_occupancy | covered |
| 77 | s | enemy-knight | Knight shadow shows the destination and the knight leaves ground occupancy while airborne | §5.10 | M8a | test_knight_leap_occupancy | covered |
| 78 | m | enemy-bishop | Bishop: long diagonal lane with a telegraph that grows outward, keeps distance 4-7, retreats from adjacent (data-only bishop_zoner.tres, instant beams) | §5.3 | M10 | test_bishop_growth | covered |
| 79 | s | enemy-bishop | Mirror and Torn Bishop variants (mirrors and folded paper redirect beams) | §5.3 | M10 (Oracle mirrors); variants deferred | test_mirror_bounce | deferred W (variants) |
| 80 | m | enemy-rook | Rook: locks a row or column, charges until blocked, breaks fragile blocks, stunned on collision | §5.3 | M11 | test_ray_stops_at_blockers | covered |
| 81 | s | enemy-rook | Rook must turn in place before changing attack axis; Wooden and Iron Rook variants | §5.3 | M11 | test_rook_turn_tell | covered |
| 82 | m | enemy-queen | Queen maneuvers Royal Line, Royal Diagonal, Command Mark, Seize Toy, Tear the Drawing, with limited simultaneous lanes | §5.4 | M12 | test_queen_phases | covered |
| 83 | m | enemy-king | King: one-cell movement, King's Reach (8 cells), Lock Direction, Restore Formation, Reverse Color (once), Close the Box; one global rule modifier at a time | §5.4 | M13 | test_king_phases | covered |
| 84 | m | enemy-common | Every enemy has a distinct role, a tell before damage, and a weakness or recovery window | §5.3 | M8a | test_enemy_identity_table | covered |
| 85 | s | enemy-common | Aggro leash so far enemies stay idle | §7.1 fixtures | exists; M1b moves to tests/fixtures | kingdom and first_encounter fixture tests | covered |
| 86 | s | enemy-common | Weapon pickup reservation and abandonment rules | §7.1 fixtures | exists; M1b moves to tests/fixtures | kingdom and first_encounter fixture tests | covered |
| 87 | m | enemy-common | Encounter recipes: Pawn Intro, Pair, Armed Lesson, Knight Pressure, Bishop Crossing, Rook Cover, Queen Court | §7.4, R4, R28 | M5 | test_room_data_audit | covered |
| 88 | m | enemy-common | Introduce one new geometry at a time; near group at most two common enemies | §7.4, R4, R28 | M5 | test_room_data_audit | covered |
| 89 | s | enemy-common | Automated response-cell validation for every authored combination | §5.10 | M8a (Tier B) | test_response_cells | covered |
| 90 | c | enemy-common | Enemy decision log (last 100) and playtest metrics | §1.2 | n/a | n/a | deferred W |
| 91 | m | enemy-common | Armed enemies replace, never stack, the chess attack | §5.3 | exists | baseline labels | covered |
| 92 | m | boss | Boss framework: phases by condition, authored maneuvers (telegraph, commit, recover), arena events, retry-safe | §5.4, §5.10 | M8b | test_boss_phase_swaps | covered |
| 93 | m | boss | Boss HUD bar shown only during boss fights | §5.4 | M8b | test_boss_bar_only_in_fights | covered |
| 94 | m | boss | Arena seal (Black Line) on entry, short runback, defeat stored permanently | §5.4 | M8b | test_boss_defeat_persists | covered |
| 95 | m | boss | Phase change is visible and mechanical: animation, arena or light change, new telegraph, safe beat | §5.4 | M8b, M8c | test_boss_phase_differs | covered |
| 96 | m | boss | B1 Black Pawn Captain with three phases (slow diagonal; shove or swing; summons or breaks cover) and a reward that opens H1 (today a 4 HP single-phase definition plus two guards) | §5.4 | M8b | test_boss_phase_swaps | covered |
| 97 | m | boss | Knight Captain, three phases (one mark; two cells with late choice; shaking toybox and train), reward Rule Step | §5.4 | M9 | test_knight_captain_phases | covered |
| 98 | m | boss | Bishop Oracle: beams, mirrored beams, drawn path across islands, reward Chalk Path | §5.4 | M10 | test_bishop_oracle_phases | covered |
| 99 | m | boss | Rook Warden: one line, breaks weak blocks, needs Eraser Guard or a child block, reward Eraser Guard | §5.4 | M11 | test_rook_warden_phases | covered |
| 100 | m | boss | Queen of Tricks: lanes, armed-pawn summons, disables a child intervention, opens the Black Castle | §5.4 | M12 | test_queen_phases | covered |
| 101 | m | boss | Black King and Rule Engine: four phases, child help blocked then restored for the finale, final unassisted diagonal strike | §5.4 | M13 | test_king_phases | covered |
| 102 | s | boss | Bosses are defeated, not killed; broken pieces become ordinary toys | §5.4 | M8c | test_defeat_becomes_toy | covered |
| 103 | s | boss | A boss rule amendment is written into the Book of House Rules mid-fight (the Knight may move twice) | §5.4 | M9 | test_book_flip_midfight | covered |
| 104 | c | boss | Promoted Zealot elite guarding the boss door | §1.2, §6.10 E7 | n/a | n/a | deferred W |
| 105 | m | world | Rooms are separate editable scenes with the standard tree (RoomArt, Entries, Exits, Enemies, Pickups, Props, RoomLogic) | §7.5 | M5 | test_room_tree | covered |
| 106 | m | world | Room metadata: zone_id, board_size, room_message, objective, entry markers, exit markers | §7.5 | M5 | test_room_status | covered |
| 107 | m | world | World graph as one resource; every door resolves to a real zone and entry (tested) | §7.1, §7.5 | M5 | test_world_graph | covered |
| 108 | m | world | Exit data: target_zone, target_entry, requires_flag, locked_message, one_way (only requires_room_clear exists) | §7.1, §7.5 | M5 | test_world_graph | covered |
| 109 | m | world | Fade-swap transition and spawn at the target entry | §9.1 | exists; M1a | test_bridge_travel | covered |
| 110 | m | world | Backtracking works unless intentionally blocked | §9.1 | exists; M1a; fixed in the M3b review | test_bridge_backtracking (the hero walks H1 -> B1 -> T4 -> T3 -> T2 -> T1 on foot); test_room_doors_reachable (every door of every room is floor, reachable, and leads to a real entry) | covered |
| 111 | m | world | Each locked exit explains why it is locked (code has one hard-coded captain message for every lock) | §5.7 | M5 | test_world_graph | covered |
| 112 | m | world | Locks are visible before they open and tied to skill, story or district completion | §5.7 | M5 | test_world_graph | covered |
| 113 | m | world | One-way shortcut gates opened from the far side stay open forever | §5.7 | exists | gate fixture test | covered |
| 114 | m | world | Shortcut back to the hub at the end of every district (mechanism exists, no district uses it) | §7.2 | M9-M13 | test_district_shortcuts | covered |
| 115 | m | world | Stage 1 chain T1-T2-T3-T4-B1-H1 wired and playable | §7.4 Act 1 | M5, M6 | test_full_route | covered |
| 116 | m | world | Decide the fate of legacy world content: 72x40 kingdom, first_encounter demo room, pawn-scale 128x96 bedroom generator | §2.1 D-02 | M1b | test_fixtures_present | amended D-02 |
| 117 | s | world | Hub evolution after each boss (shelter, banners and bridges, train shortcut, pieces gather, free building) | §7.3 | M9-M13 | test_hub_states | covered |
| 118 | m | world | Camera frames the room, keeps threats visible, scrolls larger boards | §10, D-30 | M3a | test_camera_frames | covered |
| 119 | c | world | Boss camera pullback only when integer scaling stays stable | §1.2 | n/a | n/a | deferred W |
| 120 | s | world | Gameplay sandbox room for tuning movement, sword, telegraph | §8.11 | M6 | dev_sandbox beat launcher | covered |
| 121 | c | world | In-game map screen | §1.2 | n/a | n/a | deferred W |
| 122 | m | rooms | T1 White King's Fall: quiet, no enemies, dead King focal point, retreat marks, one exit | §7.4 | M6 | test_t1_audit | covered |
| 123 | m | rooms | T2 Fallen Sword Tile: sword unlock, turn and strike tutorial, harmless target to hit (scene has no strike target) | §7.4 | M6 | test_prompts | covered |
| 124 | m | rooms | T3 First Pawn Clash: one Pawn Recruit, exit locked until cleared | §7.4 | M5, M6 | test_full_route | covered |
| 125 | m | rooms | T4 Broken Rule Yard: repositioning, cover tiles, pawn plus armed pawn | §7.4 | M6 | test_room_data_audit | covered |
| 126 | m | rooms | H1 Chess Rug Hub: Toybox open; Bookshelf, Block Tower, Dollhouse, Under-Bed, Desk visible but locked with readable reasons; child foreshadow (scene has only a door into the legacy kingdom) | §7.3 | M6 | test_world_graph | covered |
| 127 | s | rooms | Every room answers: which part of the room, why adjacent, what fantasy, what rule it teaches | §7.5 | M5 | test_room_data_audit | covered |
| 128 | m | districts | Toybox Knight district: Gate, L-Jump Lanes, Toy Track Ambush, Knight Captain, return shortcut | §7.4 Act 2 | M9 | test_full_route | covered |
| 129 | m | districts | Bookshelf Bishop district: Book Spine Steps, Diagonal Chapel, Torn Page Bridge, Bishop Oracle | §7.4 Act 3 | M10 | test_full_route | covered |
| 130 | m | districts | Block Tower Rook district: Block Yard, Ruler Bridge, Breakable Wall Test, Rook Warden | §7.4 Act 4 | M11 | test_full_route | covered |
| 131 | m | districts | Dollhouse Queen district: Foyer, Mixed Court, Royal Stage, Queen of Tricks | §7.4 Act 5 | M12 | test_full_route | covered |
| 132 | m | districts | Under-Bed Black Castle: Castle Gate, Last Board, Rule Engine, Black King | §7.4 Act 6 | M13 | test_full_route | covered |
| 133 | m | districts | Each district follows Rest, Teach, Test, Twist, Boss or Reward, Shortcut; no filler rooms | §7.5 | M5 | test_room_roles | covered |
| 134 | m | districts | About 25 authored rooms in total (6 Stage 1 rooms exist) | §2.1 D-03 | M5 | test_world_graph | amended D-03 |
| 135 | s | districts | Optional O1_CrayonCache and three optional rescues | §2.1 D-34 | M9-M11 | test_rescue_in_h1; test_reward_cadence | amended D-34 |
| 136 | s | districts | Desk and child area as a support space | §7.3, §9.1 | M13 | test_continue_after_completion | covered |
| 137 | m | districts | Finale gauntlet with all enemy types, then the chess box | §7.4 Act 6 | M13 | test_full_route | covered |
| 138 | m | districts | Ending scene: bedroom morning | §8.8 | M13 | test_ending_audit | covered |
| 139 | m | art | Top-down pixel art at 640x360, 32 px tiles, nearest filtering, integer scaling | §12 | exists | baseline labels | covered |
| 140 | m | art | Colour language: red = danger, dark orange = anticipation, blue = child help, yellow = interactable, mint = safe, ivory vs charcoal sides | §10 | M8c | palette lint (R7) | covered |
| 141 | s | art | Pickups never look like damage warnings | §10 | M8c | palette lint (R7) | covered |
| 142 | m | art | Hero sprite set: four-direction idle, step, sword, pencil, turn, hurt, defeat, victory | §12.1 | M14 | test_art_contract | covered |
| 143 | m | art | Common enemy sprite sets for Pawn, Knight, Bishop, Rook | §12.1 | M14 | test_art_contract | covered |
| 144 | m | art | Boss sprites (Black Pawn Captain, Knight Captain, Bishop Oracle, Rook Warden, Queen, King) 48-96 px | §12.1 | M14 | test_art_contract | covered |
| 145 | m | art | Fallen White King and fallen white pieces as story props (Polygon2D placeholders in T1) | §4.8 | M6 | test_state_variants | covered |
| 146 | s | art | Owner-approved generated chess family (pawn, double-step, promoted, knight) wired into scenes | §12 | M2, M14 | test_art_contract | covered |
| 147 | m | art | Tile palette and district tile kits (toybox, bookshelf, block tower, dollhouse, under-bed) | §12 | M9-M13, M14 | test_tilesets_per_district | covered |
| 148 | s | art | Prop list: chess remains, writing tools, paper, toys, furniture, light sources | §12 | M14 | test_art_contract | covered |
| 149 | m | art | Art-swap contract: owner drops hand-drawn files over placeholders (fixed names, sizes, anchors, import) with a validation test | §12 | M14 | test_art_contract | covered |
| 150 | m | art | Actor and pickup bodies are Sprite2D plus AnimationPlayer, never _draw | §12 | exists | test_art_contract | covered |
| 151 | c | art | Separate shadow sprites | §1.2 | n/a | n/a | deferred W |
| 152 | c | art | Lighting: warm global tone, PointLight2D only for lamps, magic, interventions | §1.2 | n/a | n/a | deferred W |
| 153 | s | art | Pixel UI font, Courage as ivory chess bases, Believe as crayon marks, toy-object icons | §10, §9.2 | M4, M10 | test_hud_safe_zone | covered |
| 154 | s | art | Dialogue portraits for the pawn and a child treatment | §12 | M6 (Tier B) | manual check | covered |
| 155 | s | art | Readability audit: light and dark tiles, grayscale, busy combat | §10 | M14 | grayscale readability pass | covered |
| 156 | c | art | Final polish pass that removes placeholder look from the slice path | §1.2 | n/a | n/a | deferred W |
| 157 | m | animation | Player clips wake, idle, step, attack, hurt, defeat | §12.1 | exists | test_art_contract | covered |
| 158 | s | animation | Player turn, pickup reaction and victory clips | §12.1 | M14 | test_art_contract | covered |
| 159 | m | animation | Enemy clips idle, move, alert, windup, commit, recover, hurt, defeat; the attack clip never plays for enemies (attacking is read from PlayerCombat) | §12.1, §5.10 | M8a, M14 | test_art_contract | covered |
| 160 | m | animation | Editor-owned AnimationTree state graphs on every actor | §12 | exists; M2 collapse | test_actor_collapse_golden | covered |
| 161 | m | animation | Boss animation plans: idle authority, windup per pattern, phase transition, hurt/recover, defeat | §12.1, §5.4 | M8b | test_art_contract | covered |
| 162 | s | animation | Weapon animations with unique silhouettes and timing | §12.1 | M14 (Tier B) | manual check | covered |
| 163 | m | animation | Animation never moves the logical grid anchor; RESET pose clean | §12 | exists | test_art_contract | covered |
| 164 | m | vfx | Telegraph shapes per threat family (pawn corner slashes, knight outlined L, rook arrows, bishop lane band) | §10 | M8c | test_telegraph_patterns | covered |
| 165 | s | vfx | Particles for chips, dust, crayon strokes, paper | §10 | M8c | manual check; test_hit_stop_restores_time_scale | covered |
| 166 | s | vfx | Pickup glow and idle motion | §10 | M8c | manual check; test_hit_stop_restores_time_scale | covered |
| 167 | m | vfx | Boss phase effects and room-light shifts | §5.4, §10 | M8b, M8c | test_boss_phase_differs | covered |
| 168 | m | vfx | Defeat leaves no stale telegraph; no gore | §5.10 | exists; M8a | test_no_stale_telegraph | covered |
| 169 | m | audio | Bus layout Master, SFX, Music, UI | §11 | M1a | test_audio_buses | covered |
| 170 | m | audio | Three-layer sound law: clip tracks, bus layout, SfxManager registry via the event bridge | §11 | exists | test_sound_bank_coverage | covered |
| 171 | m | audio | Warning sound per threat family (pawn, knight, bishop, rook, queen, king); only telegraph_warning.wav exists | §11.1 | M8c, M14 | test_sound_bank_coverage | covered |
| 172 | m | audio | Player step tap, turn tick, sword hit, guard sounds | §11.1 | M8c, M14 | test_sound_bank_coverage | covered |
| 173 | m | audio | Music states: opening, hub, district, combat, boss, final King, ending (one looping track exists) | §11.2 | M6, M14 | music_cues coverage audit | covered |
| 174 | s | audio | Mix priority and ducking so warnings beat music | §11.2 | M14 | manual mix check | covered |
| 175 | s | audio | Room ambience per area; final fight strips voice and ambience | §11.2 | M14 (Tier B) | manual check | covered |
| 176 | s | audio | Toy, wood, paper, crayon sound identity rather than generic fantasy (current SFX are generated chiptune) | §11.1 | M14 | test_sound_bank_coverage | covered |
| 177 | m | audio | Master, SFX, Music volume sliders | §9.2 | M4 | test_settings_roundtrip | covered |
| 178 | m | hud | HUD: Courage, equipped weapon, short status prompt, optional enemy count | §10, D-29 | M4, M7a | test_hud_slots_from_data | covered |
| 179 | m | hud | Believe meter and intervention icon appear only once the child system matters | §5.5 | M10 | test_believe_hud_appears_with_chalk | covered |
| 180 | m | hud | HUD and dialogue never cover danger cells | §10 | M4 | test_hud_safe_zone | covered |
| 181 | s | hud | Separate production HUD from debug readouts (cell coordinates, facing, strike token currently always visible) | §10, D-29 | M4 | test_debug_overlay_default | covered |
| 182 | m | tutorial | Prompts: one idea each, short, safe moments, fade after use, teach by room shape first | §8.5 | M6 | test_prompts_cover_actions | covered |
| 183 | m | tutorial | Teach move, hold, turn, sword, telegraph dodge, thrust, pickup denial, reset | §8.5 | M6 | test_prompts_cover_actions | covered |
| 184 | m | rulebook | Book of House Rules: pages unlock on first meeting, original rule vs amendment, flavour, count of amendments | §4.7 | exists; M6 | test_bridge_book | covered |
| 185 | m | rulebook | Pages for every piece and boss (5 pages exist; none for Captain, Bishop, Rook, Queen, King) | §4.7, D-47 | M6, M7c | test_pages_reachable | amended D-47 |
| 186 | m | rulebook | Opening the book safely pauses or interrupts play (enemies keep ticking today) | §4.7 | M4 | test_pause_freezes_tick | covered |
| 187 | m | menu | Title screen | §9.2 | M4 | test_new_game_resets_slot | covered |
| 188 | m | menu | Pause menu: resume, restart room, volumes, controls, quit | §9.2 | M4 | test_pause_freezes_tick | covered |
| 189 | m | menu | Settings screen | §9.2 | M4 | test_settings_roundtrip | covered |
| 190 | m | menu | Credits | §8.8 | M5, M13 | test_full_route | covered |
| 191 | m | menu | End-of-game and epilogue screen | §8.8 | M13 | test_ending_audit | covered |
| 192 | m | menu | Quit to menu or desktop | §9.2 | M4 | test_quit_to_title_confirm | covered |
| 193 | m | a11y | Reduced camera shake and reduced flashing | §10 | M8c | test_flash_rate; test_high_contrast_patterns | covered |
| 194 | m | a11y | High-contrast danger mode and pattern cues in addition to colour | §10 | M8c | test_flash_rate; test_high_contrast_patterns | covered |
| 195 | s | a11y | Hold or toggle Focus, adjustable telegraph duration, text speed | §5.8, §1.2 | M8c; text speed deferred | test_tuning_scales; test_hold_toggle | deferred W (text speed) |
| 196 | s | a11y | Grayscale readability check of every room | §10 | M14 | grayscale readability pass | covered |
| 197 | s | text | Localization-ready strings (all text out of code and scenes) | §8.9 | M4 | test_text_keys | covered |
| 198 | m | text | Story text lives in data the owner can rewrite: dialogue, room messages, prompts, unlock lines, boss beats, ending (many strings are hard-coded in scripts/main.gd:169,202,214-223,403,425,499,568) | §8.9 | M4, M6 | test_story_literals | covered |
| 199 | m | narrative | Story spine: powerless pawn becomes free, never royal; child is a companion; bosses are rules | §4.1 | M6 | test_beat_graph | covered |
| 200 | m | narrative | Opening mostly visual: army defeated, King falls, black retreats, pawn remains, child notices, pawn wakes, player moves | §3.4, §4.3 | M6 | test_time_to_control | covered |
| 201 | m | narrative | Dialogue system: short lines (4 or fewer), outside active combat, data-driven | §8.3 | M6 | test_child_voice; line budget | covered |
| 202 | m | narrative | Cutscene and story-beat system (AnimationPlayer beats, trigger zones, player-hand events) | §8.4 | M6 | test_beat_graph; test_skip_equals_play | covered |
| 203 | m | narrative | Child voice rules: short, curious, sometimes scared, never a tutorial robot | §4.5, R21 | M6 | test_child_voice | covered |
| 204 | m | narrative | Child presence staged in Act 1: none, crayon scratch at T4, notices after B1, desk light in H1 (T2 scene still says the child whispers take it) | §4.3 S01-S07 | M6 | test_beat_graph | covered |
| 205 | m | narrative | Pawn first believes the child is a god; the child admits they only imagine a better ending | §4.3 S06b, S18 | M6, M11 | test_beat_graph | covered |
| 206 | s | narrative | Midpoint reveal: the battle began as a story the child played alone | §4.3 S18 | M11 | test_beat_graph | covered |
| 207 | m | narrative | One story or theme beat per district | §4.3 | M9-M12 | test_beat_graph | covered |
| 208 | m | narrative | Boss beats: short intro, personality behaviour, phase-change beat, defeat beat; no speeches in combat | §5.4, §8.2 | M8b+ | test_boss_beats_present | covered |
| 209 | m | narrative | Queen speaks directly to the child (freedom is forgotten); King closes the box | §4.3 S20, S24 | M12, M13 | test_beat_graph | covered |
| 210 | m | narrative | Character arcs for the Pawn, Child, Queen (ideological antagonist) and King (false believer) | §4.2 | M6+ | manual review | covered |
| 211 | m | narrative | Ending: pawn refuses promotion, pieces freed, child rebuilds, pawn stands outside the board by a blue crayon line | §8.8, D-33 | M13 | test_ending_audit | covered |
| 212 | c | narrative | Ending varies slightly with rescued pieces | §8.8 | M13 (Tier B) | test_ending_variants | covered |
| 213 | s | narrative | Environmental storytelling: moved toys, child drawings, bedroom layer in every scene | §4.8, §8.5 | M6 | test_state_variants; test_clues | covered |
| 214 | s | narrative | Rescued white pieces offer optional reflections | §4.2, D-34 | M6, M13 (Pebble real; others flag-only) | test_rescue_in_h1 | covered |
| 215 | s | narrative | Tone: serious war, warm playground, no gore, humour from scale and material | §4.1 | M6 | manual review | covered |
| 216 | m | emotion | Emotional beat map: every room and act tagged with a target emotion, stored as data and checked in playtest | §3.5 R1 | M5, M6 | test_emotion_fields; print_arc | covered |
| 217 | m | emotion | Intended arc: vulnerable opening, clever in encounters, surprised at first intervention, capable at the finale | §3.2 | M14 | test_arc | covered |
| 218 | s | emotion | At least three of Lazzaro's four fun keys (hard, easy, people, serious) present in each act, with fiero from boss wins | §3.5 R19 | M14 | act checklist | covered |
| 219 | m | emotion | Autonomy, competence and relatedness: rule-breaking choice, clear mastery curve, child bond | §3.5 R20, R24 | M14 | solutions field audit | covered |
| 220 | m | emotion | Child must read as a companion (hesitation, fear, delight), checked in playtest | §3.5 R21-R22, §3.6 | M12, M14 | test_child_voice; probes P1-P3 | covered |
| 221 | s | emotion | Layered juice (squash, particles, shake, sound) added only after controls respond instantly | §10 | M8c | test_hit_stop_restores_time_scale | covered |
| 222 | m | emotion | Design the finale and ending as the peak and end; avoid front-loading; remove cheap or unreadable deaths | §3.5 R30 | M13 | test_ending_audit | covered |
| 223 | s | emotion | Gentle failure plus fine-grained assist options | §5.8, D-22 | M8c | test_tuning_scales | covered |
| 224 | s | emotion | Quiet beats and music rests: silent T1, safe hubs, final-fight silence | §3.5 R3 | M6 | test_t1_audit | covered |
| 225 | s | emotion | Grief without gore: toppled pieces, cracked bases, pieces return to being toys | §4.1 | M8c | test_defeat_becomes_toy | covered |
| 226 | s | emotion | Attachment through rescue: rescued pieces return to the hub and the ending | §4.2, D-34 | M6, M13 | test_rescue_in_h1 | covered |
| 227 | s | emotion | Post-boss and ending emotion questionnaire in the playtest form | §3.6 | M14 | docs/playtest-form.md | covered |
| 228 | m | game-flow | Complete flow: title, new game, opening, Acts 0-6, ending, credits, back to title | §1.1 D1 | M5 | test_full_route | covered |
| 229 | m | game-flow | Automated start-to-end route test (boot to credits) | §1.1 D21 | M5 | test_full_route | covered |
| 230 | s | game-flow | Difficulty and balance pass for every fight (standard.tres is untuned) | §6.7 | M14 | tuning pass with attempt logger | covered |
| 231 | s | tools | Room authoring guide matching the ECS and zone markers (docs/design/room-authoring-guide.md predates the ECS flip) | §15 M1a | M1a, M14 | the rewritten docs/design/room-authoring-guide.md (checked against the code by hand; M14 re-reads it) | covered |
| 232 | s | tools | Asset import rules and tile-editing workflow documented | §15 M1a | M1a, M14 | sections 6 and 7 of docs/design/room-authoring-guide.md (checked against project.godot and the tileset by hand; M14 re-reads them) | covered |
| 233 | s | tools | Structured owner review template | §16.2 G8 | exists | docs/owner-review-template.md | covered |
| 234 | m | tools | Fresh clone builds and runs; generators documented with order | §13.7 | M1a | tools/bootstrap_worktree.sh | covered |
| 235 | s | tools | Single test runner and CI (7 test scripts, no .github) | §13.7 | M1a; CI file Tier B | run_all_tests.py (pinned by its --self-test) | partial: the runner is done; the CI workflow file (Tier B, M14) does not exist |
| 236 | s | tools | Editor handoff note per system: Open, Tune, Goal, Try, Tell me | §16.2 G8 | each milestone, M14 | handoff notes | covered |
| 237 | s | qa | Smoke checklist, room QA checklist, combat-feel test log, bug format | §15 M14 | M14 | docs/qa templates | covered |
| 238 | m | qa | Automated coverage: movement, combat, telegraph, graph validation, resource references, scene boot | §13.7 | M1a onward | run_all_tests.py --strict | covered |
| 239 | s | qa | Performance budget: stable 60 FPS, capped enemies, short VFX | §5.11 | M3a, M14 | test_room_tick_budget | covered |
| 240 | s | qa | At least three outside playtesters | §1.2, §3.6 | M8c, M14 | attempt logger; playtest form | deferred W (testers) |
| 241 | m | release | Exported build that runs outside the editor (macOS zip from 2026-07-28 is stale; no Windows or Linux preset) | §1.2, §15 M14 | M14 (macOS Tier B) | export smoke | deferred W (Windows, Linux) |
| 242 | s | release | Package notes: controls, known issues, playtime, feedback questions, version | §15 M14 | M14 | package notes | covered |
| 243 | c | release | Screenshot plan, trailer beats, store-page text | §1.2 | n/a | n/a | deferred W |
| 244 | c | release | Steam page and public demo plan (15-25 min demo, Next Fest) | §1.2 | n/a | n/a | deferred W |
| 245 | s | release | LICENSE, font and asset credits | §1.1 D20 | M1a stub, M14 | LICENSE and THIRD_PARTY_NOTICES check | covered |
| 246 | m | process | ECS rules: state in components, decisions in systems, only ViewSyncSystem touches nodes, content in .tres | §2.4, §13 | M1a onward | test_dependency_edges (report-only; it checks layer edges, not node access) | partial: nothing yet checks that only ViewSyncSystem touches nodes; the edge guard stays report-only until the owner decides its table at OG0 |
| 247 | m | process | Verify suite green and import clean before every commit; one logical change per commit | §2.4, §13 | M1a onward | run_all_tests.py (suites green, import clean); commit size is a review rule | partial: one logical change per commit is checked by review only |
| 248 | m | process | Research built-in nodes then addons (ask owner) before custom code | §2.4, §13 | M1a onward | the research rule in CLAUDE.md and AGENTS.md; checked in review | partial: a review rule, no automated check exists |

## Summary

- Rows: 249. Priorities: 156 must, 76 should, 17 could.
- Status: 213 covered, 15 amended, 21 deferred W (owner-waivable, plan §1.2).
