# Route times: a slow bot's baseline for every room of the critical path

Written by `tests/playthrough/test_full_route.gd` (the route bot, `tests/playthrough/route_bot.gd`) every time it runs. **Do not edit it by hand**: the next run puts the measurement back, and a change in it is a change in the game (a room that got longer, a door that moved).

**What a number is.** Game seconds (the simulation's own clock, not the wall clock) from the moment the pawn arrives in a room to the moment it steps onto the door that leads on. The bot walks the shortest path by key presses, takes what the room gives for the stepping (T2's sword), brings every ordinary piece down with the sword (walk beside it, face it, strike until it falls) and brings a boss down with a damage event, which the plan allows until the boss fights exist (M8b). The enemies' AI is off, so nothing strikes the bot and nothing is dodged. The time spent trying the doors the route has not earned yet (the hub's shut district doors) is not counted. A room the pawn passes more than once (the hub, five times) shows its shortest visit. The numbers sit beside the plan's first-play estimate (docs/game-base-plan.md 7.4, the Min column) so that the estimate can be replaced by a measurement (D-03).

**What kind of number it is: a SLOW BOT'S BASELINE, not a minimum.** The bot walks up to a piece that stands still and waits out the sword's whole recovery after every stroke, so a player does beat it: the M5 review played the same route by real input with the enemy AI on and was faster than the bot in 25 of the 31 rooms (172 s against the bot's 195 s over the first visits, the hub's returns apart), by keeping the pawn moving and striking as soon as the sword is ready. Only the six boss rooms took a player longer, because a real fight needs real strokes (1.4 to 2.9 times the bot's time) where the bot spends one damage event. So read the table as the length of the skeleton for a patient player who is never hurt, and as the thing a change in the game moves; D-03's true minima (a player's, or a bot that fights back) are M9's to measure once the rooms hold real fights.

**What it is not.** A first-play time (nobody reads, learns, dies or looks around here), a boss's time (a stand-in boss falls to one damage event; the fight is M8b's and M9's measurements to make), a minimum (see above), or a time for the optional nooks (`tbo`, `bso`, `bto` are off the critical path, and each waits for a verb of M7c).

| Room | Role | Visits | Pieces by sword | Bosses by damage event | Bot baseline | Plan estimate |
|---|---|---|---|---|---|---|
| `t1_white_kings_fall` | rest | 1 | 0 | 0 | 4.00 s | 2.0 min |
| `t2_fallen_sword_tile` | teach | 1 | 0 | 0 | 4.10 s | 3.0 min |
| `t3_first_pawn_clash` | test | 1 | 1 | 0 | 5.05 s | 3.0 min |
| `t4_broken_rule_yard` | twist | 1 | 3 | 0 | 9.15 s | 4.0 min |
| `b1_black_pawn_captain` | boss | 1 | 2 | 1 | 6.20 s | 6.0 min |
| `h1_chess_rug_hub` | rest | 5 | 0 | 0 | 1.00 s | 4.0 min |
| `tb1_toybox_gate` | teach | 1 | 2 | 0 | 8.00 s | 3.0 min |
| `tb2_l_jump_lanes` | test | 1 | 2 | 0 | 12.60 s | 4.0 min |
| `tb3_toy_track_ambush` | twist | 1 | 1 | 0 | 5.25 s | 4.0 min |
| `tbb_knight_captain` | boss | 1 | 1 | 1 | 5.10 s | 6.0 min |
| `tb4_lid_path` | shortcut | 1 | 0 | 0 | 8.50 s | 1.5 min |
| `bs1_book_spine_steps` | teach | 1 | 3 | 0 | 11.10 s | 4.0 min |
| `bs2_diagonal_chapel` | test | 1 | 2 | 0 | 7.00 s | 4.0 min |
| `bs3_torn_page_bridge` | twist | 1 | 2 | 0 | 6.00 s | 5.5 min |
| `bsb_bishop_oracle` | boss | 1 | 1 | 1 | 5.10 s | 6.0 min |
| `bs4_page_tear_shortcut` | shortcut | 1 | 0 | 0 | 3.00 s | 1.5 min |
| `bt1_block_yard` | teach | 1 | 3 | 0 | 9.10 s | 3.5 min |
| `bt2_ruler_bridge` | twist | 1 | 2 | 0 | 6.60 s | 5.0 min |
| `bt3_breakable_wall_test` | test | 1 | 2 | 0 | 10.60 s | 4.0 min |
| `btb_rook_warden` | boss | 1 | 1 | 1 | 5.60 s | 6.0 min |
| `bt4_ruler_gate_shortcut` | shortcut | 1 | 0 | 0 | 3.00 s | 1.5 min |
| `dh1_foyer` | rest | 1 | 0 | 0 | 3.00 s | 3.0 min |
| `dh2_mixed_court` | test | 1 | 2 | 0 | 9.50 s | 5.0 min |
| `dh3_royal_stage` | twist | 1 | 2 | 0 | 6.55 s | 3.0 min |
| `dhb_queen_of_tricks` | boss | 1 | 1 | 1 | 5.10 s | 6.5 min |
| `dh4_seal_stair` | shortcut | 1 | 0 | 0 | 4.25 s | 1.0 min |
| `ub1_castle_gate` | rest | 1 | 0 | 0 | 3.00 s | 3.0 min |
| `ub2_last_board` | test | 1 | 4 | 0 | 13.70 s | 6.0 min |
| `ub3_rule_engine` | twist | 1 | 1 | 0 | 5.05 s | 4.0 min |
| `ubb_black_king` | boss | 1 | 1 | 1 | 5.10 s | 9.0 min |
| `e1_morning_desk` | ending | 1 | 0 | 0 | 3.25 s | 8.0 min |

| Act | First visits, game seconds | Plan, minutes |
|---|---|---|
| 1 | 29.50 s | 22.0 min |
| 2 | 39.45 s | 18.5 min |
| 3 | 32.20 s | 21.0 min |
| 4 | 34.90 s | 20.0 min |
| 5 | 28.40 s | 18.5 min |
| 6 | 26.85 s | 22.0 min |
| 7 | 3.25 s | 8.0 min |
| the hub's returns (4) | 13.00 s | 4.0 min |
| **the whole route** | **207.55 s** | **134.0 min** |

The plan's 134 minutes are the sum of its Min column, the hub's four pass-throughs included (7.4 Totals: 130 to 136). The bot's total is the time a patient pawn needs when the game asks nothing of it but the walk and the strokes: until M9 puts real fights in the rooms it is the measure of the skeleton's length, not of the game's.
