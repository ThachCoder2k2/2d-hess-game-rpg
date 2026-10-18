# Art direction notes for the asset request list (2026-10-12)

Written by the art director pass over `characters.json`, `world.json`, `ui_story.json`, `vfx.json` and `audio.json`. The shared look and sound live in `style.json`; the five spec files were rewritten in place by script and all six files parse.

## 0. Tóm tắt cho anh (Vietnamese summary)

- Anh nói số lượng phải nhiều vì đây là cả game, nên mình KHÔNG cắt bớt. Tổng cộng vẫn là **7953 file / 821 nhóm** (trước đó 7872 file). Các nhóm bị gỡ chỉ là bản trùng (cùng một vật bị hai nhóm vẽ), không phải nội dung bị bỏ; phần thêm vào nhiều hơn phần gỡ.
- (Đã thay thế 2026-10-13, mục 15: mọi ảnh là 1x1.) Một quy tắc pixel duy nhất: tranh thế giới (tile, vật cảnh, quân cờ, boss, hiệu ứng) vẽ theo **lưới 2x2** (vẽ trên lưới nửa kích thước rồi phóng gấp đôi) giống bộ quân cờ anh đã duyệt; giao diện, icon, chân dung và bàn tay của bé vẽ pixel 1x1 (bàn tay mịn gấp đôi thế giới, đúng như bible).
- Mỗi file là MỘT vật: đã bỏ các ảnh nguyên cảnh (vista 704x360, nền màn hình chính 640x360, thảm 384x288, vignette toàn màn hình). Thay bằng bộ phần nhỏ 64x64 để anh thay từng mảnh; công cụ sẽ ghép.
- Đã gỡ các vật bị vẽ hai lần (Vua trắng, quân ngã, ngai Xe, 4 quân phong cấp, bia tập, khối phấn, đường Đen, bóng của Mã, cầu phấn, vết chà Rule Mark) và giao mỗi vật cho đúng một nhóm.
- Đã thêm các thứ còn thiếu: vật cầm của Pawn và kẻ địch (kiếm, bút chì, thước, cục tẩy), bóng chạm sàn dưới nhân vật, mũi tên hướng nhìn, chấm máu kẻ địch, cục tẩy và mẩu phấn là vật mở khoá, ô thảm khuyết ở màn hình chính, thanh thời gian và chấm đợt, hai kẻ địch E7 còn lại (cùng âm thanh), đủ 6 cảm xúc chân dung cho mọi nhân vật.
- Các câu hỏi mở của từng nhóm đã được trả lời ở mục 1; những việc cần anh xác nhận trước khi tạo prompt đầu tiên nằm ở mục 8.

## 1. Decisions taken as art director

- **Pixel scale.** (Superseded 2026-10-13, section 15: every image is 1x1 and the chunky 2x2 world scale no longer exists.) World art is CHUNKY: each art pixel is a 2x2 block (draw on a half-size grid, upscale 2x nearest). UI, icons, portraits, fonts and the child hand are FINE (1:1). The approved chess family (`tools/generate_chess_sprites.gd`, `block_size_in_world_pixels: 2`) and the tile generator are already chunky, and the bible says the hand is 'twice the pixel density of the chess world', which only holds if the world is 2x2. This answers characters open question 1 and ui_story question 1 (the hand stays 192x144 at 1:1, no 384x288).
- **Pawn canvas.** (Superseded 2026-10-12, section 13: a piece is smaller than its cell, 32x32.) 32x40 stays (16x20 art pixels). The hero body is restated as about 26x32 px inside it, because the approved generator pawn is 18 art pixels wide with its outline and would not fit; the owner may widen every pawn-family canvas to 36x40 later by editing one scale-table row.
- **Eyes and mouths.** Chess pieces have no mouths, ever. The hero has two small dark dot eyes (answers characters question 2). Portraits of pieces were rewritten to carry emotion through eyes, brow ridge, lids and tilt (Pebble, Knight Captain and the Queen had smiles in their text).
- **One view convention.** Camera 65 degrees above the floor (`tools/generate_demo_map.gd`): flat things from straight above, standing things show a short south face, actors are symmetric front elevations with shallow bands for rings. One fixed light from the upper left. Documented once in `style.json`.
- **Palette.** One value per gameplay colour: coral #D84A3A (matches `prototype_board.gd`), dark orange #E0762A, crayon blue #3A6FE0 (glow #4DA3FF), gold #F2C23C (glow #FFD34E), mint #63D68B. The five lanes had three blues, four reds, three oranges and two mints; 91 strings carrying those hex values were unified. Toy-paint reds stay duller on purpose.
- **Boss canvases.** (Superseded 2026-10-12, section 13: bosses are pieces too, 32x32 with a body of at most 24x28.) Kept as written (64x72, 64x88, 80x80, 80x96, 96x80) with the body footprint within two cells wide. The bible's 64x64 for Queen and King has no room for a crown and a rule card; plan 12 allows 64-96 px. Answers characters question 3.
- **Facings.** Hero: S, N, E drawn (free_step SE, NE), W/SW/NW are tool mirrors. Enemies and bosses: front view only plus static body_n and body_e. Kept (answers characters question 4); four-way enemy animation would multiply the enemy files by about 3 for little readability gain, because the telegraph overlays carry direction.
- **Remains and deferred variants.** Remains of defeated pieces stay (D-17: cleared rooms stay cleared) and the deferred variants (Veteran, Desperate, Wraith, Zealot, Guard Knight, Mirror and Torn Bishop, plus the two newly added Marble Launcher and Wind-Up Hammer) stay at could so the art exists when the owner enables them.
- **Rescued pieces.** Pebble, Slant and Stout keep three states each (trapped, freed, hub resident); Slant and Stout are hub props in the plan but the owner asked for the full story arc.
- **Vistas, title, big images.** No file larger than 128x96 remains except the child hand (192x144), the logo and the application icon (the optional 272x304 page-turn frames were replaced in round 1 by three small parts and a code tween, section 10). Vistas became 9 part kits of 64x64 files; the title screen is built from shared wood-floor tiles, chess-rug tiles and a small overlay kit; the completed title board uses one new missing-square tile.
- **Ownership of duplicated things.** Each thing now has exactly one owner (table in section 4). Where the same body was drawn twice, the lane that owns the entity keeps it and the effect lane keeps only the overlay.
- **High-contrast twins.** The 104 `_hc` clips (322 frames) are set to could: a tool can generate the cream and charcoal keylines and a heavier pattern from the normal frames, hand-drawing them only if the generated result is weak. They stay listed. Answers vfx question 1.
- **Frame counts.** Everything is inside the guidance (idle 2-4, step 4, attack 3-6, hurt 2-3, defeat 4-6, effects 3-8, transitions 6) except the hero rule_step_takeoff at 36 fps (3 frames for 0.083 s, a timing from plan 6.3). The King defeat (8) and final blow (10) were trimmed to 6 and 8.
- **Audio.** (Superseded 2026-10-12, section 13: SFX WAV, music and ambience OGG, one track per area, no stems.) Convention kept: `assets/sfx/<family>/<event>_NN.wav`, `assets/music/<area>/<cue>.wav`, stems separate. WAV with an smpl loop chunk stays the default because the plan and `unbound_march.wav` use it; if repo weight becomes a problem (about 0.9 GB for music and ambience) the owner may deliver OGG at the same stem name and the sound bank row changes once. The C-pentatonic music-box motif is provisional: the owner should compose the real one first.

## 2. Scale table (what every size and anchor must match)

`style.json -> scale_table` lists 57 classes. Rules: feet-anchored art puts the anchor at (width/2, height-4), or height-2 when the canvas is 32 px high or less; flat decals and tiles have no anchor; effects use one generated rule per size (cell centre, ground contact, feet). UI sizes are even numbers up to 384 px. A validator walked every group against the table: 0 mismatches.

## 3. What changed, by category

### characters

- unified the gameplay colour hex values (crayon blue #3A6FE0, coral #D84A3A, anticipation #E0762A, gold #F2C23C, mint #63D68B) in 80 strings
- removed the repeated 'show only this object' suffix from file texts
- removed 1 group(s) / 1 files: knight_destination_shadow (duplicates vfx telegraph/knight/knight_shadow, which has 3 clips and covers the same destination shadow)
- removed 1 group(s) / 8 files: boss_rook_throne (duplicates the modular world throne (rook_throne_parts + rook_throne_break), which follows the one-swappable-part rule)
- renamed 9 Act-6 alcove memory figure paths to alcove_memory_<piece>/... (they collided with the world memory-wall drawings memory_<piece>/prop.png)
- hero body size restated in 7 groups: 26x32 px body inside the 32x40 canvas (the old 22x32 was smaller than the approved pawn)
- boss_king_story defeat clip trimmed 8 -> 6 frames (frame guidance: defeat 4-6) by merging flash+cracks and cape+cards
- added weapons_hero, weapons_enemy (held overlays on the WeaponPivot), enemy_marble_launcher and enemy_windup_hammer (E7 variants named in plan 6.10)
- normalised 3 anchors to the scale-table rule: boss_remains_as_toys [feet/base centre of the object at (32,42] -> [feet/base centre of the object at (32,44]; white_king_fallen [centre of the base-contact line on the f] -> [centre of the base-contact line on the f]; fallen_white_pieces [centre of the floor-contact point at (24] -> [centre of the floor-contact point at (24]
- removed 51426 characters of style text that was pasted into group details, avoid and palette fields and now lives once in the style block

### world

- unified the gameplay colour hex values (crayon blue #3A6FE0, coral #D84A3A, anticipation #E0762A, gold #F2C23C, mint #63D68B) in 9 strings
- removed the repeated 'show only this object' suffix from file texts
- removed 1 group(s) / 4 files: act1_white_king (duplicates characters white_king_fallen (one 64x40 object with an interact clip); the 4 quarter files made one object four files)
- removed 1 group(s) / 9 files: crayon_target (duplicates characters enemy_crayon_target (the Crayon Target is an enemy entity with HP 2))
- removed 4 group(s) / 28 files: token_bishop, token_knight, token_queen, token_rook (duplicate characters ending_promotion_tokens (the four promotion tokens, 40x56 with bump frames))
- act1_fallen_white_pieces reduced to 4 fragment files (renamed act1_fallen_white_fragments, 32x32); the 8 whole fallen pieces duplicated characters fallen_white_pieces
- chalk_block now owns the hold/crumble/vanish clips moved from vfx (the old vfx chalk_block_raise/idle/crumble/vanish drew the same body a second time)
- moved 10 pickup sprites from content/props/<id>/prop.png to content/pickups/<id>/pickup.png (plan 12 and 13.2 give pickups their own folder)
- tiles_shared_chalk gained chalk_cap_e/chalk_cap_s and the chalk_h/v_fade_warn clips (moved from the removed vfx chalk_path_* overlays)
- pickup_special_items gained eraser_guard and chalk_stub (the audio spec already has btb_eraser_handed_over and unlock_eraser_guard, but no pickup art existed)
- added tiles_chess_rug_title (the missing-square tile of the completed title board)
- normalised 3 anchors to the scale-table rule: book_of_house_rules [base centre at (16,36)] -> [base centre at (24,36)]; hub_under_bed_shadow [base centre at (48,38); lies along the h] -> [base centre at (48,36); lies along the h]; map_landmarks [base centre at (32,46)] -> [base centre at (32,44)]
- removed 203552 characters of style text that was pasted into group details, avoid and palette fields and now lives once in the style block

### ui_story

- unified the gameplay colour hex values (crayon blue #3A6FE0, coral #D84A3A, anticipation #E0762A, gold #F2C23C, mint #63D68B) in 2 strings
- removed the repeated 'show only this object' suffix from file texts
- removed 10 group(s) / 43 files: vista_act1_bed_edge, vista_act2_toy_overpass, vista_act3_top_shelf, vista_act4_tower_summit, vista_act5_dollhouse_stage, vista_act6_chess_box, vista_ending_morning, vista_h1_under_bed_silhouette, vista_midpoint, vista_opening_establishing (whole-scene 704x360 parallax layers broke one-file-one-thing; replaced by 9 vista PART kits of 64x64 pieces (vista_kit_*), plus the under-bed silhouette that duplicated world hub_under_bed_shadow)
- removed 2 group(s) / 6 files: title_layers, title_rug (full-screen floor layers and a 384x288 rug are whole-scene images; the title is assembled from shared wood-floor tiles, chess-rug tiles and title_kit_overlays)
- added 9 vista kit groups (117 part files), title_kit_overlays and 3 objective-progress groups (survive timer, wave pips, enemy-count dot)
- book_page_turn lowered to could: the leaf can be a tweened paper 9-patch, the 8 hand-drawn 272x304 frames are the largest single images left
- portraits: every speaker now has all six emotions of plan 12 (12 added at could) and every file text states its own expression; mouths removed from chess-piece portraits (pieces have no mouths)
- removed 623 characters of style text that was pasted into group details, avoid and palette fields and now lives once in the style block

### vfx

- removed the repeated 'show only this object' suffix from file texts
- removed 1 group(s) / 1 files: death_freeze_vignette (a 640x360 full-screen image; the death freeze reuses the HUD vignette corner and edge pieces tinted charcoal (ui hud_low_courage_vignette*))
- removed 1 group(s) / 6 files: close_the_box_vignette (a 640x360 x6 full-screen animation; Close the Box uses the tile wipe wipe_felt_lid (32x32 x8) assembled across the screen)
- removed 1 group(s) / 15 files: black_line_seal (duplicates world black_line_seal (dormant and sealed stills plus seal and unseal clips in both orientations))
- removed 4 group(s) / 17 files: chalk_block_crumble, chalk_block_idle, chalk_block_raise, chalk_block_vanish (the Chalk Block body is one entity owned by world chalk_block, which now carries the hold, crumble and vanish clips)
- removed 3 group(s) / 36 files: chalk_draw_stroke, chalk_path_cap, chalk_path_mid (the finished chalk bridge cell, its draw-on and its expiry are tile states owned by world tiles_shared_chalk (stills, draw and expire clips); caps and the fade warning moved there)
- rule_mark_rub reduced to a crumbs-only overlay (rule_mark_rub_crumbs, 4 frames): the erased and return frames duplicated the rub and restore clips of the world rule_mark props
- king_final_blow_burst trimmed 10 -> 8 frames (effects 3-8)
- 104 high-contrast twin clips (_hc) set to could with a note that tools can generate them from the normal frames; they stay listed so the owner can hand-draw them
- added actor_shadow_s/m/l/xl, facing_arrows and enemy_health_pips: the actor-view nodes of plan 12 (shadow, FacingArrow, HealthPips) had no art in any lane
- normalised 30 anchors to the scale-table rule: knight_shadow [shadow centre at (16,18)] -> [shadow centre at (16,20)]; step_dust_rug [contact point at (12,12), between the pa] -> [contact point at (12,14), between the pa]; step_dust_wood [contact point at (12,12), between the pa] -> [contact point at (12,14), between the pa]; step_dust_paper [contact point at (12,12), between the pa] -> [contact point at (12,14), between the pa]; step_dust_carpet [contact point at (12,12), between the pa] -> [contact point at (12,14), between the pa]; step_dust_felt [contact point at (12,12), between the pa] -> [contact point at (12,14), between the pa]; step_dust_desk [contact point at (12,12), between the pa] -> [contact point at (12,14), between the pa]; turn_skid_puff [centre at (8,12)] -> [centre at (8,14)]; takeoff_dust_kick [contact point at (16,18)] -> [contact point at (16,22)]; land_dust_ring_small [contact point at (16,16)] -> [contact point at (16,22)]; land_dust_ring_large [contact point at (32,26)] -> [contact point at (32,24)]; train_steam_puff [puff base at (16,26)] -> [puff base at (16,30)]; menace_lift_small [base centre at (16,34)] -> [base centre at (16,36)]; menace_lift_medium [base centre at (24,50)] -> [base centre at (24,52)]; menace_lift_large [base centre at (48,90)] -> [base centre at (48,92)]; pickup_glow_gold [centre at (16,18), under the item] -> [centre at (16,20), under the item]; rescue_reunion_burst [centre at (32,38)] -> [centre at (32,40)]; gate_open_dust [centre at (16,22)] -> [centre at (16,20)]; proximity_dust_lift [centre at (16,24)] -> [centre at (16,20)]; checkpoint_refill_ring [ring centre at (24,28), around the pawn'] -> [ring centre at (24,30), around the pawn']; respawn_wake_dust [centre at (16,22)] -> [centre at (16,20)]; rule_step_afterimage [feet centre at (16,34)] -> [feet centre at (16,36)]; guard_lockout_crumbs [centre at (12,12), at the pawn's feet] -> [centre at (12,14), at the pawn's feet]; hand_place_paper_dust [centre at (24,22), under the hand's plac] -> [centre at (24,20), under the hand's plac]; promotion_token_glow [centre at (16,18), under a promotion tok] -> [centre at (16,20), under a promotion tok]; promotion_token_bump [centre at (16,18), at the token] -> [centre at (16,20), at the token]; summon_rise_poof [feet centre at (16,34)] -> [feet centre at (16,36)]; throne_smash_burst [centre at (48,64), at the throne] -> [centre at (48,60), at the throne]; queen_promotion_glow [centre at (24,34), around the pawn's fee] -> [centre at (24,30), around the pawn's fee]; box_open_light [centre at (48,48), at the box opening] -> [centre at (48,40), at the box opening]
- removed 24 characters of style text that was pasted into group details, avoid and palette fields and now lives once in the style block

### audio

- renamed group child_hand -> sfx_child_hand (the id collided with the ui_story hand sprite group)
- added enemy_e7_marble_launcher and enemy_e7_windup_hammer sound groups (could) for the two deferred E7 enemies

## 4. Who owns what now

- Fallen white King: characters `white_king_fallen` (one 64x40 object with the interact clip); crown, cloth tie and shadow dressing in world `act1_white_king_extras`
- Fallen white pieces: characters `fallen_white_pieces` (10 whole pieces); world `act1_fallen_white_fragments` (4 fragments only)
- Crayon Target: characters `enemy_crayon_target`
- Promotion tokens: characters `ending_promotion_tokens`; vfx keeps the glow and bump overlays
- Rook throne: world `rook_throne_parts` (modular) and `rook_throne_break`
- Knight landing shadow: vfx `knight_shadow` (three clips)
- Chalk Block body: world `chalk_block` (place, hold, crumble, vanish); vfx keeps `chalk_block_hit_spark`
- Chalk Path cell: world `tiles_shared_chalk` (stills, caps, draw, fade warning, expire); vfx keeps only the hand-lane call markers
- Black Line seal: world `black_line_seal`
- Rule Mark rub: world `rule_mark` and `rule_mark_diagonal` (rub, erased, restore); vfx keeps the crumbs overlay
- Under-bed silhouette: world `hub_under_bed_shadow` (states 0-5 and boxed)
- Memory figures: characters `act6_memory_figures` (ids alcove_memory_*, in the alcoves); world `underbed_memory_wall` (pinned drawings on the wall)
- Pickups: all under `content/pickups/<id>/pickup.png` (plan 12); skill/pickup icons stay `icon.png`
- Weapons held by actors: characters `weapons_hero` (content/skills/<id>/weapon.png) and `weapons_enemy` (content/enemies/_shared/weapons)
- Actor shadows, facing arrows, enemy health pips: vfx `actor_shadow_*`, `facing_arrows`, `enemy_health_pips`
- Whole-screen vignettes: none: low-Courage and death use the ui `hud_low_courage_vignette*` pieces, Close the Box uses `wipe_felt_lid`

## 5. Coverage walk (plan 4 to 12.1)

Every beat S01-S26, every enemy and boss of 5.3-5.4, every verb, page, annotation and extension of 6, every room's props, locks, clues, rescues and hub states of 7 (34 rooms plus the hub states and the boxed regress), the narrative UI of 8, the shell of 9, the feel table of 10, the SFX and music tables of 11 and every required clip of 12.1 was matched to at least one group by a path and name check (78 explicit items) plus a per-room review. Found missing and added: held weapon overlays (WeaponPivot), actor ground shadows, FacingArrow and HealthPips art, the Eraser Guard and Chalk Path unlock tokens, the survive timer and wave pips, the title missing-square tile, the title overlay kit, vista part kits (replacing whole-scene layers), the Marble Launcher and Wind-Up Hammer (named in plan 6.10 E7) with their sounds, and the full six-emotion portrait set for every speaker. Not given art, on purpose: deferred UI (key remap screen, multi-slot screen, captions, dialogue log; they reuse menu rows and panels), PointLight2D textures and fades (built in the editor), camera zoom (dropped by R25).

## 6. Counts

| category | groups before | groups now | files before | files now | added paths | removed paths | must | should | could |
|---|---|---|---|---|---|---|---|---|---|
| characters | 55 | 57 | 1618 | 1681 | 83 | 20 | 1244 | 142 | 295 |
| world | 271 | 266 | 2258 | 2234 | 35 | 59 | 1198 | 642 | 394 |
| ui_story | 144 | 145 | 725 | 816 | 140 | 49 | 256 | 471 | 89 |
| vfx | 251 | 247 | 1838 | 1760 | 13 | 91 | 795 | 458 | 507 |
| audio | 104 | 106 | 1433 | 1462 | 29 | 0 | 702 | 480 | 280 |
| total | 825 | 821 | 7872 | 7953 | 300 | 219 | 4195 | 2193 | 1565 |

Files by milestone and priority (all categories), for the owner's delivery order:

| needed_by | must | should | could |
|---|---|---|---|
| M2 | 3 | 0 | 0 |
| M3b | 8 | 15 | 0 |
| M4 | 141 | 101 | 42 |
| M5 | 117 | 95 | 36 |
| M6 | 469 | 353 | 96 |
| M7a | 73 | 11 | 13 |
| M7b | 48 | 43 | 4 |
| M7c | 44 | 82 | 6 |
| M8a | 211 | 53 | 110 |
| M8b | 305 | 83 | 6 |
| M8c | 76 | 113 | 28 |
| M9 | 437 | 199 | 109 |
| M10 | 497 | 232 | 146 |
| M11 | 656 | 254 | 84 |
| M12 | 390 | 179 | 102 |
| M13 | 699 | 379 | 162 |
| M14 | 21 | 1 | 621 |

Suggested order: all `must` of M2-M6 first (first playable and Act 1), then M4 shell, then M7-M9, and so on by milestone; `should` and `could` follow their milestone.

## 7. Plan amendments these specs assume (apply to docs/game-base-plan.md)

- 12: rooms are composed from per-tile and per-prop PNGs; `content/rooms/<id>/background.png` and `assets/tiles/<district>/atlas.png` are replaced by `assets/tiles/<district>/<tile_id>.png` and tool-built atlases. Tools build `tileset.tres`, atlases, sprite sheets and room scenes.
- 12: VFX are per-frame files `content/feel/vfx/<family>/<id>/anim/<clip>/NN.png`; actor and prop frames are `<folder>/anim/<clip>/NN.png`; painted vistas become part kits `content/story/vistas/<id>/parts/*.png` with a tool-written `vista_layout.json`.
- 12.1: hero directional clips are saved as `<clip>_s`, `_n`, `_e` (and `_se`, `_ne` for free_step); the art-contract test and the sheet tool map them to the manifest names. Boss clips are per phase and `BossPhase` gains commit, hurt, recover and idle clip fields.
- 13.2: new folders `content/enemies/_shared/weapons/`, `content/skills/<id>/weapon.png`, `content/feel/vfx/actor/`, `content/story/vistas/<id>/parts/`, `content/ui/title/kit/`; bosses keep their bodies in `content/bosses/<id>/`; pickups use `content/pickups/<id>/pickup.png`.
- 11: audio subfolders per family (`assets/sfx/<family>/`, `assets/music/<area>/`, `assets/music/ambience/`), sound_bank row id = file name without `_NN`, a tool generates rows by folder scan.

## 8. Still needs a human decision before the first prompt is generated

(Superseded on 2026-10-13, section 15: the 2x2 chunky scale is gone, everything is 1x1. Answered on 2026-10-12, see section 13: the pawn canvas, the glyphs, the audio format and the stems, the deferred files. Still open: the 2x2 scale, the hand, the story language, the logo wording, the White Queen, the real motif.)

- (Answered 2026-10-13, section 15: no 2x2 chunky scale, everything is 1x1.) Confirm the 2x2 chunky world scale (section 1) and the 26x32 hero body inside 32x40, or widen the pawn canvas to 36x40.
- Child hand: skin tone, age, sleeve; the child's portrait style (crayon self-drawing is the default).
- Source language of the story (O-4) and the fonts; if Vietnamese, run `python3 tools/asset_requests/build_requests.py --check-font <font>` (automated, reads the cmap table that `FontFile.has_char` reads) and then judge the diacritic clearance at real size by eye.
- Logo wording (`THE UNBOUND PAWN` is the only image allowed to contain text).
- Keyboard and gamepad glyphs: draw about 60 by hand or use the Kenney CC0 'Input Prompts Pixel' set as the long-term placeholder.
- Whether the White Queen exists in the ending (there is no white Queen in the story; the Queen token on the desk is the only Queen on the white side).
- Audio: WAV versus OGG for music and ambience, whether to compose the stems as specified or one track per area, the real music-box motif, and whether the wordless child vocalisations (17 files, could) stay.
- Deferred enemy variants (291 files at could) and remains of defeated pieces (28 files): draw now or later.

## 9. Build notes

(Round 1 note: `finalize.py` regenerates the PRE-round-1 specs. After running it, copy its five outputs plus `style.json` to a folder and run `python3 /tmp/asset_spec/build/round1/run_all.py --source <that folder>`; the round-1 patch is a set of scripts in `/tmp/asset_spec/build/round1/` that start from the pre-round-1 specs and write the patched ones, so it is safe to re-run.)

The five specs are regenerated from untouched backups of the author files (`/tmp/asset_tools/orig/`) by `python3 /tmp/asset_tools/build/finalize.py`; the pipeline is idempotent, validates scale-table sizes and anchors, unique group ids and paths, clip pose counts, tile_data, wav/png extensions and gitignored output folders, and fails loudly on any problem (0 problems at the time of writing).


## 10. Round 1 patch (2026-10-12)

Totals after the patch: **8090 files in 835 groups** (before: 7953 in 821). Per category (groups / files / must / should / could): characters 57 / 1772 / 1250 / 175 / 347; world 274 / 2258 / 1216 / 648 / 394; ui_story 147 / 813 / 256 / 472 / 85; vfx 250 / 1776 / 795 / 458 / 523; audio 107 / 1471 / 702 / 489 / 280. Net +137 files: 154 added paths and 17 removed paths (the composite files and the 8 page-turn frames that were split into single objects); 204 existing files changed milestone or priority (151 M8a to M6, 34 M9 to M6, 13 to M7c, 6 M13 to M8b).

### Added

- **Boss `move` clips** (4 frames, loop, 8 fps, P1 look, priority should, each boss's own milestone) for black_pawn_captain, knight_captain, bishop_oracle, rook_warden, queen_of_tricks and black_king, plus optional per-phase variants `move_p2`, `move_p3` (King also `move_p4`) at could: 76 files. The Rule Engine never moves and has none (stated in its group).
- **Hero Ruler Blade sweep** `attack_ruler_s/n/e` (5 frames each, 32x40, one-shot, 16 fps so the impact frame lands at 0.12 s, last frame held for the 0.45 s recovery; should, M7b) and its Strike-slot icon `content/skills/wooden_sword/icon_ruler_blade.png`. The SkillDefinition sets `anim_state = attack_ruler`; without the files the engine falls back to `attack`.
- **Hub shard nook** `content/props/hub_shard_nook/` (prop, prop_open, 4-frame open clip, 32x40, M7c): a felt-flapped cubby in the foot of the hub toy shelf that the tack switch unlatches; the shard itself stays its own pickup.
- **Wave sfx** `assets/sfx/world/wave/`: wave_start, wave_enemy_emerge, wave_clear, 3 takes each (M13, should).
- **Deferred E7 visuals** (could, M14): `marble_roll` (16x16, 4 frames, loop, drawn facing east), `marble_stop_puff` (32x32, 4 frames) and `hammer_slam_impact` (48x48, clips `slam` 5 frames and `rebound` 3 frames), all under `content/feel/vfx/enemy/`.
- **Tooling**: `build_requests.py --check-font <fonts>` and `--check-fonts <repo root>` (Vietnamese coverage read from the cmap table, cross-checked against fontTools and Godot's `FontFile.has_char`); a `lint_specs` step (tile colour cap, translucency paragraph present, voice-blip counts, warnings for pair-style names and images larger than 128x96); the script now also runs bare from the folder that holds the spec.

### Quality fixes and the decisions behind them

- **Who owns a rescue trap**: the world prop `rescue_trap_<name>` owns the trap and is layered in FRONT of the piece; the TRAPPED sprite of Pebble, Slant and Stout is now the bare piece (cowering, bent or squeezed, no block, ribbon or cage), and the rescue_progress and freed clips no longer draw a blockage. Pebble's trap palette now says faded toy yellow, matching its prop.
- **Translucency**: one global paragraph in the style block, PERCENTAGES AND TRANSLUCENCY. A written percentage is opacity unless the text names what it measures; opacity is a flat translucent fill with one alpha (alpha = percentage x 255) and hard edges, or on an opaque tile a one-art-pixel checkerboard or a colour blended once. The global avoid list and the Vietnamese delivery rules point at it, and the acceptance line of an entry that uses a percentage allows the intermediate alpha. Two size percentages that read as opacity were reworded (toy pawn squash, courage pip swell).
- **Milestones**: the world Courage Shard moves M9 to M7c (hub nook, icon and glow are M7c), the shard pickup sound and the tack-switch sounds move to M7c; the hero `victory` clip moves M13 to M8b and becomes must (B1 plays it; its sound and sparkle were already due); the Recruit, Armed and Backstep sprites, the enemy weapon overlays, the pawn_slash, pencil_bar_mid, pencil_bar_tip, backstep_hop and small telegraph aura markers and the pawn move, alert and hop sounds move to M6 because T3 and T4 (M6) already place those enemies. The enemy weapon pick-up rules (grab_weapon) stay at M8a/M9.
- **Veteran Pawn**: the red service stripe became a pale-bone stripe (#B9B3A0). The same contradiction (DO NOT forbids red, SUBJECT or PALETTE names a red part) existed in 14 more character groups; each one now names its own red part as an exception, and the permanent #D84A3A cracks of the King, the Rule Engine and the activated Toy Pawn Blocker became ember red #B8362F (dull #9C2F2A for the blocker) that brightens to coral only on a commit frame, so coral keeps its single meaning.
- **Tile colour cap**: tiles_bookshelf_chapel (13 colours) now lists 9 (the shelf spine colours are not used on chapel tiles; each light pool tile uses one pool colour), tiles_under_bed_memory_wall (11 plus unnamed crayon accents) lists exactly 10.
- **One file = one thing**: desk_second_set_board, desk_chess_box_full, desk_mug_pair, desk_captured_tray, gather_pawn_pair, the footprint pairs, spoon_pair and cog_pair became single-object files in new groups (desk_second_board, desk_second_set_pieces, desk_chess_box_tray, desk_chess_box_pieces, desk_mugs, desk_captured_tray, desk_captured_pieces); book_page_turn (8 frames of 272x304) became book_page_turn_curl, book_page_turn_edge and book_page_turn_shadow plus a code tween of the existing page panels.
- **Voice blips**: voice_queen_of_tricks (to_child, 4 takes) and voice_child (whisper, 2 takes) now describe their extra sets in DETAILS and the files say which set they belong to; every voice group carries `audio.variations_by_event`, and the lint keeps them honest.
- **Fonts**: the Vietnamese coverage check is automated (see Tooling); only the visual check of line height and diacritic clearance stays with the owner before M4 picks a font.

### Still open

- The owner has not confirmed the Veteran bone stripe or the ember-red cracks; both are art direction and easy to change in one string each.
- The Marble Launcher and Wind-Up Hammer keep their M14 / could status; nothing in the base places them.


## 11. Round 2 patch (2026-10-12)

Totals after the patch: **8215 files in 840 groups** (before: 8090 in 835). Per category (groups / files / must / should / could): characters 57 / 1772 / 1250 / 175 / 347; world 275 / 2360 / 1294 / 660 / 406; ui_story 147 / 813 / 256 / 472 / 85; vfx 250 / 1776 / 795 / 458 / 523; audio 111 / 1494 / 708 / 496 / 290. Net +125 files (126 added paths, 1 renamed). The patch is `python3 /tmp/asset_spec/build/round2/run_all.py`; it starts from the pre-round-2 specs saved in `/tmp/asset_spec_backup_round2/` and is safe to re-run. `build_requests.py` was edited in place.

### Added

- **Gap autotile completion, all 7 districts (56 tiles, must).** `gap_end_n/e/s/w` (3-sided trench end caps, the named side is the closed one) and `gap_inner_ne/nw/se/sw` (concave inner corners: all four edge neighbours are gap, only the named diagonal is floor) in chess_rug (M6), toybox (M9), bookshelf (M10), block_tower (M11), dollhouse (M12), under_bed and desk (M13). Each description reuses that district's lip material and the 10 px far-wall language of its `gap_edge`/`gap_corner`; the group notes and DETAILS now state the 21-tile set.
- **Path strips (20 tiles).** Chess rug runner: `runner_corner_ne/nw/se/sw` and `runner_t_n/e/s/w` (M6, must; a winding T1 runner and the Act 1 rooms can now be laid). Bookshelf ribbon: `bookmark_corner_*` x4 (M10, should). Dollhouse pink path: `path_pink_corner_*` x4 and `path_pink_end_n/e/s/w` (M12, should; the lawn group stays could for the lawn itself).
- **Royal boss steps (audio, must).** `queen_move_01..03` (0.2 s, M12) and `king_move_01..03` (0.25 s, M13) in `assets/sfx/enemy/motion/`, one set serving all of the boss's phase clips. Optional boss-weight steps (could): `captain_move`, `knight_captain_move`, `oracle_move`, `warden_move`, 2 takes each. Boss alert ticks were not added: every boss opens with its own intro sound, so there is no "notices the player" moment to key.
- **Hub chess box lid clips (14 frames, must, M13).** New group `hub_chess_box_lid` at `content/props/chess_box_open/anim/`: `lid_close` (6 frames, S22) and `lid_open` (8 frames, S24-S25, with a small overshoot), same canvas, anchor and palette as `prop.png`, which is the declared reference image of the group (`reference_image`).
- **Toybox mechanism sounds.** `track_switch_clunk_01..03`, `spinning_top_whirr_loop_01..02` (loop) and `spinning_top_settle_01..02` in `assets/sfx/world/props/toybox/` (should, M9), plus `ruler_gate_open_01..02` in `assets/sfx/world/props/blocktower/` (could, M11).
- **Fence end posts (12 props, could).** `bookend_fence_end_n/e/s/w` (M10), `block_pen_end_n/e/s/w` (M11), `rail_end_n/e/s/w` (M13), 32x40 like the rest of each set.

### Quality fixes and the decisions behind them

- **DO NOT variants.** The one shared DO NOT line forbade the thing a tile, a panel or a fence IS. `style.json` now carries `global_avoid_variants_en`: `surface` (every tile, the map ground tiles, the paper tiles, the 23 opaque vista `tile_` fills: the surface fills the canvas edge to edge, no transparent pixel, a frame/rim/cap is allowed when the description says so) and `frame` (every `ui` file, plus the four fence sets, the exterior fence, picture and window frames: the panel, border, key cap, rail or fence is the subject and 9-patch art may run to the canvas edge). Both keep every clause they do not relax, including text, crayon blue, coral red, pure white or black, and the PERCENTAGES AND TRANSLUCENCY pointer; the lint enforces that. A file or group picks a variant with `avoid_profile`; tile defaults to `surface` and `ui` to `frame`. Files that really are opaque but are not tiles carry `opaque: true`, so their CANVAS line and acceptance line say "fully opaque" instead of "transparent background" (this also fixed the map ground tiles, whose old prompt said both). `map_district_ground` lost its contradictory "1 px outline" for a seamless tile.
- **Audio avoid.** `global_avoid_audio_variants_en`: `child_voice` (the child's wordless breaths, hum, gasp, sigh, sniff and giggle are what the group asks for) and `ambient_life` (the faint far birdsong of the two morning ambiences and the desk spot bird); the rest of each list is unchanged.
- **Defeat effects.** `menace_lift_small/medium/large` no longer spend coral red or dark orange on a harmless release: the seams are the dull seam red #9C2F2A fading through a muddy brown-red #7A4A38 to wood brown, and the avoid line forbids coral.
- **Cooldown pulse.** The ring is 30, 28, 26 px across (it contracts onto the 24 px slot) so it fits the 32x32 canvas.
- **One grey pencil.** Grey pencil #9A9AA3 is now the single enemy-amendment ink and the style block says so: it is used only for a rule an enemy rewrites or revokes (Book strike-throughs, underlines, doodles, stamps, rule diagrams, loose pages and margin notes, the amendment scribble, the disabled-help scribble, the direction-lock scribble, the King's rule-card lines). Every other grey is a neutral material grey named by its material: neutral graphite #6B7380 (UI lines, tracks, ticks, cursors, disabled state, sketches, effect dust and smudges), a district's own graphite (#5D5B63 on the desk and the memory wall) and ink grey #55525A (bookshelf). The stray #8A8D98, #8A8F9C and #9A9AA6 are gone. The UI ivory #F2E8D0 is now the style's white-side light #F1E8D2 in all 49 places; the UI charcoal #2B2D3A stays because the style block defines it as the UI outline.
- **Crayon blue.** The control prompt slip (now held by masking tape), the unlock toast (reward-gold stitching), the prompt badges, the boss-bar checkpoint flag (mint, safe) and the lock tags (graphite only, including the latch hand) no longer use crayon blue; the style block adds that it is never a decorative accent on neutral HUD or signage, with menu focus rings as the one documented exception. The menu focus colour and a few other UI blues (skill slot rims, lore ribbons, chapter and ending cards) were left as written; they are the owner's call.
- **Animation references.** Every frame prompt now says to draw the reference file first (frame 01 for the first frame of a group, `body.png` or `prop.png` otherwise) and to attach it to the generator as the reference image; the README and its checklist say the same in Vietnamese. 3430 frame prompts name their reference, the 226 first-of-group frames say they are the reference. A group may declare `reference_image` (used by the lid clips).
- **Milestones.** `emotes_pawn/afraid.png` M8c to M6 (S06b plays afraid then hesitant at the B1 notice); the Chalk Block body, its hold, crumble and vanish clips M11 to M9 (the scripted tb3 block, S09); `block_raise` and `block_stops_projectile` M11 to M9 must (`block_move`, `block_destroyed` stay M11); `credits_card`, `credits_dividers`, `credits_section_icons` M13 to M4 (the credits scene is built in M4; priorities unchanged, still non-blocking).
- **Style contradictions.** The giant box's lid shadow is now a flat translucent wedge at one opacity (60 percent), not a gradient, and its path moved from `box_lid_shadow_gradient/prop.png` to `box_lid_shadow/prop.png`; the cache chest, the Toybox crayon-cache map node and the box clasp seam no longer glow.

### Still open

- The owner has not confirmed the neutral graphite #6B7380 for UI lines or the ivory/charcoal split.
- The `hud_prompt_done` tick (M4, could) and the menu focus blue are still crayon blue; say if you want them neutral too.
- The `spinning_top_whirr_loop` is two takes of 2 s; a longer bed can be requested if the tilt of the loop is audible.


## 12. Round 3 patch (2026-10-13)

Totals after the patch: **8344 files in 863 groups** (before: 8215 in 840). Per category (groups / files / must / should / could): characters 57 / 1774 / 1250 / 177 / 347; world 275 / 2370 / 1294 / 661 / 415; ui_story 149 / 835 / 256 / 472 / 107; vfx 265 / 1844 / 795 / 466 / 583; audio 117 / 1521 / 708 / 505 / 308. Net +129 files and +23 groups (characters +2, world +10, ui_story +22, vfx +68, audio +27); no `must` file was added. The patch is `python3 /tmp/asset_spec/build/round3/run_all.py`; it starts from the pre-round-3 specs saved in `/tmp/asset_spec_backup_round3/` and is safe to re-run (a second run gives byte-identical specs). `build_requests.py` was edited in place (its previous version is in the same backup folder).

### Added

- **Charging Pawn Page cues for the hero (M9, 12 frames + 5 sounds).** `charging_armed_cue` (`content/feel/vfx/skill/charging_pawn/charging_armed/anim/loop/01-04.png`, 32x40, feet-anchored, ivory dust-lines gathering at the base, no blue, no red, should), `charging_armed_snap` (4 frames, the one beat when 1.0 s of stillness is reached, could), `charging_double_step_streak` (`.../double_step_streak/anim/dash/01-04.png`, 64x32 = two cells, east-facing, should) and the sound group `pawn_charging_page` (`assets/sfx/pawn/charging_page/charging_armed_01..02.wav`, 0.3 s, and `double_step_01..03.wav`, 0.25 s). The existing `charging_dash` sounds stay with the enemy.
- **Cast feedback for the deferred skills (M14, could).** vfx under `content/feel/vfx/skill/<id>/`: In Passing (`in_passing_window_marker`, a 0.45 s clock ring in 5 frames at 11 fps, and `in_passing_drag_trail`), Ruler Gate (`ruler_gate_anchor_mark`, `ruler_gate_press`, `ruler_gate_hold` loop, `ruler_gate_release`), Castling (`castling_swap_flash_pawn` ivory and `castling_swap_flash_block` crayon blue, played in both cells), Turn the Board (`turn_board_quarter_sweep` 64x64, `turn_board_settle_dust`), Paper Bridge (`paper_bridge_unfold`, whose last frame matches the finished `paper_bridge_h_mid` prop) and Erase Rule Mark (`erase_rule_mark_dust`). The child's hand gets the `erase` clip (6 frames, `content/story/characters/child/anim/erase/01-06.png`, the pink eraser is drawn in the hand like the crayon of `draw`). Sounds: `pawn_in_passing` (window x2, drag x3), `pawn_castling` (swap x3), `child_ruler_gate_hold` (press x2, release x2), `child_turn_board` (rotate x2, settle x2) and `child_paper_bridge` (settle x2; the longer drop-and-fold sound already existed as `paper_drop_fold`, and `eraser_rub_child` already covers the erase).
- **Icons and Book diagrams for the deferred Pages (M14, could).** `icons_rule_pages_deferred`: `passant_wraith`, `castling`, `promoted_zealot`, `black_queen`, `bishop_of_order` and one blank `vow_blank` template (`content/rules/<id>/icon.png`, 16x16; the Vow set is not fixed, so only the frame is asked for). `book_rule_diagrams_deferred`: `<page>_original.png` and `<page>_amended.png` for the five pages (10 files, 48x48).
- **Battlement ends.** `battlement_end_n` and `battlement_end_s` (32x48, M11, could) complete the Block Tower kit.
- **Bedroom floorboard step.** `step_wood_01..04.wav` (M6, should) in `assets/sfx/pawn/step/`. The wood floor tile groups now name `step_wood` and `step_dust_wood`, and `pawn_step_surfaces` states the rule: every walkable tile maps to one of its surfaces and a tile with no surface of its own falls back to `step_rug`.
- **Held pawn stills.** `held_by_hand.png` (calm hang) and `held_by_hand_tilted.png` (carried) in `content/player/` (M8c, should).

### Quality fixes and the decisions behind them

- **PALETTE lines never point elsewhere (82 prompts named in the review, 24 more fixed with them).** A palette may now contain `{palette:<group_id>}`; `build_requests.py` copies that group's real palette text, hex values included, into every prompt, and a file may carry its own `palette_en`. Used by the four district gate arches (24 props), the seven `map_nodes_*` groups (34 files, the hub node adds its five door accents), `map_district_plates` (8 files, one district palette each, the Window plate has its own), `dialogue_nameplates`, `dialogue_speech_bubbles` and `dialogue_bubble_tails` (16 files, one speaker palette each), and also `hub_gates_district` (12) and `map_district_ground` (12), which listed colour names without values. New checks: a palette that says "see ...", "same as ..." or "the district's palette" fails the build, and so does an unresolved token. Audio had the same defect (231 prompts said "MATERIALS: see stems / see character / see per file"); those lines now name the materials, and the build rejects a new one.
- **No prompt cites a document or an id.** About 2,270 prompts carried "plan 10", "fx1", "pixel-art bible 7", "gdd", "au5", requirement ids R<n>, decision ids D-<nn> and story-beat ids S<nn>. The citations are removed from the 134 spec fields that held them (the rule next to each was already written inline); the audio REFERENCES line, which was nothing but citations, is rewritten as real sonic references (recordings of the group's own materials plus any quoted design intent). `build_requests.py` now fails the build if any image or audio prompt still matches one of those patterns (R3 is allowed: it is the gamepad stick click).
- **One file, one thing.** Split into single objects: `marbles_pile` (3 marbles), `block_scatter_a/b` (4 single blocks), `block_pile_small` (1 block), `paperclips_pile` (2 paper clips), `crayon_pile_big` (3 crayons), `marbles_spilled` (2 big marbles); the three cover tiles that were rows or stacks became `cover_book_standing_h/v`, `cover_plank_block_h/v` and `cover_fallen_black_knight`. `child_drawing_two_figures` stays: it is one sheet of paper and now says so. Nine true compounds (rubble heaps, the barricade cushions, litter decals, the fragments of one broken piece) are marked `compound_ok` with a reason; the build warns about any other file that describes a pile, heap or scatter.
- **Held pawn.** The child-hand `pick_up` and `place_pawn` clips now name the sprite at the contact point in every frame (`held_by_hand.png`, `held_by_hand_tilted.png`, and `content/player/anim/defeat/06.png` for the toppled pawn, which is the same pose as wake frame 1), and the hand details say the thumb and finger are drawn over the lowest 6 px of the base.
- **Filler removed.** "Only the global avoid list applies." no longer ends the DO NOT line of 645 prompts (it pointed at a list the prompt already contains).

### Still open

- The new cluster replacements are a design call: a heap of fallen pieces (chess rug cover) is now one fallen Knight, and the book row is one standing book. Say if you would rather keep the heap as a hand-painted tile.
- Hero groups (`hero_*`) still have no hex colours in their PALETTE line (the style block carries the white-side palette); the pointer lint does not flag that.
- Story-beat ids that are plain labels (room ids such as `tb3`, boss ids such as `B1`) remain in prompts; only plan, document, requirement, decision and beat ids are linted.

## 13. Owner answers applied 2026-10-12

Source: `docs/owner-decisions.md` (the answers are quoted verbatim there). Totals after the patch: **8300 files in 856 groups** (before: 8344 in 863). The patch is `python3 /tmp/asset_spec/build/round4/run_all.py`; it starts from the pre-round-4 specs saved in `/tmp/asset_spec_backup_owner_answers/` and is safe to re-run (a second run gives byte-identical specs). `build_requests.py` was edited in place (its previous version is `/tmp/asset_spec_backup_owner_answers/build_requests.py.orig`). Do NOT run `build/merge.py`, the `build/part*.py` scripts or the round 1 to 3 `run_all.py` on their own afterwards: they rebuild the merged json from older backups and would overwrite this patch. `sh /tmp/asset_spec/build/finalize_all.sh` runs round 3, round 4 and round 5 (section 14) in the right order and then the generator.

### Tóm tắt cho anh

- **Quân cờ nhỏ hơn ô.** Mọi quân cờ (pawn của anh, mọi kẻ địch và biến thể, quân trắng được cứu, Vua trắng đã ngã và các quân ngã, sáu boss) giờ vẽ trên canvas 32x32 = đúng một ô, thân quân cách mọi mép ít nhất 2 px. Thân quân: Tốt 18x22, Mã/Tượng/Xe 20x24, Hậu 22x26, Vua 22x28; boss rộng hơn một chút nhưng không quá 24x28. Điểm neo chung (16,30). 62 nhóm quân cờ dùng canvas 32x32 (khoảng 1800 khung ảnh đổi canvas); bảng cỡ có thêm hàng cho từng hạng quân.
- **Glyph phím và tay cầm lấy từ Kenney CC0.** Sáu nhóm vẽ tay (61 file) thay bằng MỘT nhóm `glyphs_kenney`: bộ "Input Prompts Pixel" (kenney.nl/assets/input-prompts-pixel, 800 tile 16x16). Giữ nguyên 61 đường dẫn. 40 file có số tile cụ thể, 9 file bộ có nhưng anh phải tìm trên ảnh xem trước, 12 file bộ không có (dùng tile thay thế hoặc bỏ trống).
- **SFX là WAV, nhạc và ambience là OGG, một bài cho mỗi khu.** Không còn stem. Còn 62 file nhạc (20 bài lặp); 58 file nhạc cũ đã gỡ (42 stem/lớp và 16 cue phụ gộp vào bài của khu), thêm 14 bài hoàn chỉnh.
- **Các file hoãn (could)** giữ nguyên ở could. 21 ảnh thân tĩnh của các biến thể hoãn trước đây ghi `must` nên nằm đầu M14, nay đã về could để nằm cuối.
- **Prompt tự đủ ý.** Không prompt nào còn nêu tên nhóm khác; 1126 prompt đã được viết lại.

### Totals, before and after

| category | before (groups / files) | after (groups / files) | change |
|---|---|---|---|
| characters | 57 / 1774 | 57 / 1774 | +0 |
| world | 275 / 2370 | 275 / 2370 | +0 |
| ui_story | 149 / 835 | 144 / 835 | +0 |
| vfx | 265 / 1844 | 265 / 1844 | +0 |
| audio | 117 / 1521 | 115 / 1477 | -44 |
| **total** | 863 / 8344 | 856 / 8300 | -44 |

| kind | before | after | change |
|---|---|---|---|
| sprite | 1807 | 1807 | +0 |
| vfx | 1765 | 1765 | +0 |
| prop | 1401 | 1401 | +0 |
| sfx | 1192 | 1196 | +4 |
| tile | 1012 | 1012 | +0 |
| ui | 583 | 522 | -61 |
| icon | 185 | 185 | +0 |
| voice_blip | 116 | 116 | +0 |
| music | 110 | 62 | -48 |
| ambience | 103 | 103 | +0 |
| portrait | 66 | 66 | +0 |
| sourcing | 0 | 61 | +61 |
| font | 4 | 4 | +0 |

| priority | before | after | change |
|---|---|---|---|
| must | 4303 | 4250 | -53 |
| should | 2281 | 2271 | -10 |
| could | 1760 | 1779 | +19 |

Changes inside the category and kind pairs (only the pairs that moved):

| category / kind | before | after | change |
|---|---|---|---|
| audio / music | 110 | 62 | -48 |
| audio / sfx | 1192 | 1196 | +4 |
| ui_story / sourcing | 0 | 61 | +61 |
| ui_story / ui | 378 | 317 | -61 |

### 1. A piece is smaller than its cell

Rule (owner, verbatim in `docs/owner-decisions.md`): every chess piece is drawn on one 32x32 cell with its visible body at least 2 px from every edge; never exactly cell-sized, never taller than the cell, no overlap into the row above. Applied to the body, the facing stills and EVERY animation frame of: the hero pawn, every enemy family and variant (the Crayon Target and the toy gadgets of the deferred variants included), the three rescued white pieces, the white pawn soldier and the hub's gathered white pawns, the six bosses (default until the owner says otherwise), the fallen white King, the fallen pieces and the toys the bosses become, plus the things that belong to a piece (weapon overlays, ground shadows, facing arrow, health pips, rescue traps, memory figures, promotion tokens, the ending's white pieces, the afterimage, charging cues, menace-lift overlays).

Anchor for every standing piece: **base-bottom centre at (16,30)**, the base rim on the line y=30 (last drawn row y=29), 2 px of empty canvas under it. This is the style block's existing rule for canvases up to 32 px high (width/2, height-2), so shorter pieces just leave more empty canvas above their head. The brief said "slightly below the cell centre": a 28 px king cannot keep a 2 px margin and sit higher, so the base line is the same for all and the shorter bodies end up 2 to 3 px below the cell centre (pawn body centre y=19, king y=16); say if you want a different baseline and only the scale rows and the CELL FIT paragraph change.

New scale-table rows (the old `actor_*` and `boss_*` sprite rows, `weapon_overlay_32x64`, `prop_40x56`, `prop_48x56`, `vfx_48x56` and `vfx_48x16` were removed, and the `use` of `prop_48x32`, `prop_48x48`, `prop_64x40`, `prop_64x48`, `vfx_32x40` and `boss_engine_96x80` was restated):

| scale row | canvas | anchor and body box | use |
|---|---|---|---|
| piece_pawn_32 | 32x32 | base-bottom centre at (16,30); body box 18x22 px (9x11 art pixels), top at y=8, 2 px margin on every side | CHESS PIECE, pawn class: the hero pawn, every pawn-family enemy (recruit, armed, backstep, charging, commanded, toy blocker, veteran, desperate, passant wraith), the Crayon Target standee, the white pawn soldier, the hub's gathered white pawns |
| piece_knight_32 | 32x32 | pedestal base-bottom centre at (16,30); body box 20x24 px (10x12 art pixels), top at y=6, 2 px margin | CHESS PIECE, knight class: Knight Tracker, Guard Knight, rescued Pebble |
| piece_bishop_32 | 32x32 | base-bottom centre at (16,30); body box 20x24 px (10x12 art pixels), top at y=6, 2 px margin | CHESS PIECE, bishop class: Bishop Zoner, Mirror Bishop, Torn Bishop, rescued Slant |
| piece_rook_32 | 32x32 | base-bottom centre at (16,30); body box 20x24 px (10x12 art pixels), top at y=6, 2 px margin | CHESS PIECE, rook class: Wooden Rook, Iron Rook, rescued Stout, and the minor-height deferred variants (Promoted Zealot, Marble Launcher, Wind-Up Hammer) |
| piece_queen_32 | 32x32 | base-bottom centre at (16,30); body box 22x26 px (11x13 art pixels), top at y=4, 2 px margin | CHESS PIECE, queen class: reserved for a standing queen (the base game has none: the Queen of Tricks uses the boss row, and the white queen appears only lying down or as a promotion token) |
| piece_king_32 | 32x32 | base-bottom centre at (16,30); body box 22x28 px (11x14 art pixels), top at y=2, 2 px margin | CHESS PIECE, king class: the standing white King of the ending (the tallest piece) |
| piece_boss_32 | 32x32 | base-bottom centre at (16,30); body box at most 24x28 px: Captain 24x22, Knight Captain 24x24, Bishop Oracle 22x24, Rook Warden 24x24, Queen of Tricks 24x26, Black King 24x28 (pawn lowest, king tallest) | CHESS PIECE, boss: the six bosses (they are chess pieces too, smaller than the cell like every piece; they read as bosses through crown, silhouette details, colour and their aura and burst effect files, not through size) |
| piece_fallen_32 | 32x32 | centre of the floor-contact line at (16,30); a lying piece is its standing box turned 90 degrees (pawn 22x18, knight/bishop/rook 24x20, queen 26x22, king 28x22), 2 px margin on every side | fallen white pieces, the fallen white King, fragments of broken pieces, the toys the six bosses become, remains of defeated enemies |
| piece_mixed_32 | 32x32 | base centre at (16,30); every piece inside obeys its own class box above | props that hold or cover chess pieces: the three rescue traps, the Act-6 memory figures and crayon outlines, the four promotion tokens (piece plus disc at most 24x28), the ending's white pieces |
| weapon_overlay_32x32 | 32x32 | grip pivot at (16,26), blade pointing north (the WeaponPivot rotates it); the weapon spans y=2..28, at most 26 px long and 8 px wide | held weapon overlays (hero and enemy): they fit the cell like the pieces that hold them |

How each group states it: `piece_class` in the spec (lint: the canvas must be 32x32, details_en must carry a CELL FIT paragraph, the scale row must exist), the group `anchor`, a body-size sentence in the subject, and a CELL FIT paragraph in the details of every one of the 62 piece groups (the body box, the top line y, the headroom above it, and the rule that squash, stretch, tilt, lean, lunge and lift stay inside x 2..29, y 2..29). Boss boxes: Captain 24x22, Knight Captain 24x24, Bishop Oracle 22x24, Rook Warden 24x24, Queen of Tricks 24x26, Black King 24x28, so the order pawn < minor pieces < queen < king still holds and every boss is wider than a common piece of its kind. The old boss wording ("a boss is bigger than a cell", "1.7 times the height of a common pawn", "hugely oversized", "towering") is rewritten: bosses read as bosses through crown, silhouette details, colour and the separate aura and burst files. Pixel measures in about 500 pose and file texts (squash, stretch, lunge, lift, sway) were scaled to the smaller bodies (body height ratio, rounded to the 2 px grid, nothing below 2 px); airborne lifts are capped at what the headroom allows (pawn 4 px, knights, bishops and rooks 2 px, boss captain 4 px, other bosses 2 px; the jump arc is the engine's and the separate flight shadow shows the height). The Queen's and the Commanded Pawn's puppet threads no longer leave the canvas (2 px and 6 px stubs; the game draws the long strings). The King has no headroom (28 px is the full allowance), so growth poses are drawn by width, cape and finial.

Not a piece, so unchanged: the Rule Engine (a machine in a chess box, 96x80, the one boss larger than a cell, with its own shadow `actor_shadow_xl`), the child's hand and its shadow, props, furniture and the desk's small second-set pieces. Ground shadows s, m and l are now 32x16 (pawn class 24x8 oval, minor pieces 28x10, bosses 28x12 since round 5); the facing-arrow chevron is 8x8 inside its 16x16 canvas; the three-pip health row is 24 px wide. Weapon overlays are 32x32 with the grip pivot at (16,26) and the whole weapon at most 26 px long. World: the three rescue traps (48x48), the hub's gathered pawns (32x40) and the ending's white pieces (32x48) moved to 32x32; the Act-6 memory figures and crayon outlines (48x56) and the four promotion tokens (40x56) moved to 32x32 (a token, piece plus disc, fits 24x28).

What the scene must do for this list (M2, one shared actor view): the sprite offset (anchor (16,30) in a 32x32 texture), the health-pip row and facing arrow inside the cell, the weapon pivot at (16,26) of its 32x32 overlay, the shadow files, and a single 32x32 texture size for every piece.

### 2. Input glyphs come from Kenney's CC0 pack

The six hand-drawn glyph groups (`glyph_keys_1u`, `glyph_keys_1p5u`, `glyph_keys_2u`, `glyph_key_space`, `glyph_gamepad`, `glyph_misc`; 61 files) are replaced by ONE sourcing group, `glyphs_kenney` (new kind `sourcing`, entries still one per file). Pack (read on kenney.nl, nothing was downloaded): **Input Prompts Pixel**, by Kenney, https://kenney.nl/assets/input-prompts-pixel, licence **CC0 1.0**, version 1.0 (2021), 800 files, 16x16 PNG tiles in a `Tiles` folder named `tile_0000.png` upward (plus tilesheets); the OpenGameArt mirror is https://opengameart.org/content/input-prompts-pixel-16%C3%97. The tiles are numbered, not named, so each entry gives the tile number to copy and the exact target path. Tile numbers were read from a community rename listing of the same Tiles folder (gist idbrii/804ba1b902d8631f3bc82b8cb08b5f5f), not from the pack itself: confirm each picture before copying. Coverage of the 61 paths (all kept, so the UI needs no change): **40 `tile`** (a tile number is given), **9 `locate`** (the pack should have it; Tab, Ctrl, Alt, Enter and the five D-pad files: pick the tile on the preview sheet, candidates named), **12 `compose`** (the pack has no tile: a stand-in tile or a quick edit is named in the entry, or leave it out and let the game draw the key name). Every glyph is now 16x16 (the 24x16, 32x16 and 48x16 widths are gone). Any file can be overwritten later by a hand-drawn PNG at the same path. The generator got the new kind (the prompt is a sourcing brief with the pack, the licence, the source tile and the target path), a lint (no hand-drawn group may sit in `assets/ui/glyphs`) and a README rule.

### 3. SFX are WAV, music and ambience are OGG, one track per area

- Format: SFX and voice blips stay WAV 44.1 kHz 16-bit mono (the 17 looping SFX keep their smpl loop chunk). Music and ambience are OGG Vorbis 44.1 kHz stereo, quality about 6, loops with continuous first and last samples and NO loop tags (the engine switches looping on at import). 165 music and ambience paths changed from `.wav` to `.ogg`; the generator accepts `.ogg` only for music and ambience and `.wav` only for SFX and voice, and the loop wording and acceptance text depend on the format. The sound brief (`style.json`) no longer mentions stems and states the one-track-per-area rule.
- Removed: every stem and layer file. 58 old music files are gone: 42 stem or layer files (the core set, Act 1, the hub, the five districts, the six bosses and the Desk loop) and 16 district sub-cues and vistas folded into the area tracks (the toybox relief and tb3 chase, the bookshelf relief and bs3 page-slide, the block tower relief and bt2 hold-the-line, the dollhouse relief and dh1 tea party, the Under-Bed castle gate and Rule Engine room, and the six vista loops). 14 new complete tracks were written in their place. Music files: 110 before, 62 after (the 4 phase stings moved to SFX: SFX 4 net).
- Boss phase changes: the existing four phase accents (phase 2, phase 3, the King's phase 4, the safe-beat pad) are now SFX (`boss_phase_stings`, WAV, `assets/sfx/boss/phase_sting/`) laid over the one boss track.
- Kept as their own OGG cues because they are distinct moments: the opening, the B1 notice, the Queen's offer, quiet beat and farewell, the lid closing, the three memory alcoves, the King's rehearsal beat and the free-step peak, the box opening, the rescue, keepsake and first-fiero stings, the nine boss intro and afterglow stings, the three reset and seven act-title stings, the Midpoint confession, the four token epilogues, the step off the board and the held final image. The credits are one complete piece that now loops (no final chord; the engine fades it out).

The 62 music files:

| track | length | kind | priority | needed by |
|---|---|---|---|---|
| `assets/music/title/title_music_box_loop.ogg` | 40 s | loop | must | M4 |
| `assets/music/title/title_post_game.ogg` | 40 s | loop | could | M13 |
| `assets/music/act1/act1_theme.ogg` | 58.2 s | loop | must | M6 |
| `assets/music/hub/hub_theme.ogg` | 45.7 s | loop | must | M6 |
| `assets/music/hub/hub_boxed.ogg` | 48 s | loop | must | M13 |
| `assets/music/hub/hub_free.ogg` | 41.7 s | loop | could | M13 |
| `assets/music/hub/hub_midpoint_confession.ogg` | 100 s | one-shot | must | M11 |
| `assets/music/toybox/toybox_theme.ogg` | 53.3 s | loop | must | M9 |
| `assets/music/bookshelf/bookshelf_theme.ogg` | 64 s | loop | must | M10 |
| `assets/music/blocktower/blocktower_theme.ogg` | 73.8 s | loop | must | M11 |
| `assets/music/dollhouse/dollhouse_theme.ogg` | 48 s | loop | must | M12 |
| `assets/music/underbed/underbed_theme.ogg` | 57.6 s | loop | must | M13 |
| `assets/music/boss/b1_captain/b1_theme.ogg` | 38.4 s | loop | must | M8b |
| `assets/music/boss/kb_knight_captain/kb_theme.ogg` | 32 s | loop | must | M9 |
| `assets/music/boss/bsb_bishop_oracle/bsb_theme.ogg` | 45.7 s | loop | must | M10 |
| `assets/music/boss/btb_rook_warden/btb_theme.ogg` | 53.3 s | loop | must | M11 |
| `assets/music/boss/dhb_queen/dhb_theme.ogg` | 48 s | loop | must | M12 |
| `assets/music/boss/ubb_black_king/ubb_theme.ogg` | 60 s | loop | must | M13 |
| `assets/music/ending/ending_desk_theme.ogg` | 53.3 s | loop | must | M13 |
| `assets/music/ending/ending_epilogue_queen.ogg` | 14 s | one-shot | should | M13 |
| `assets/music/ending/ending_epilogue_rook.ogg` | 14 s | one-shot | should | M13 |
| `assets/music/ending/ending_epilogue_bishop.ogg` | 14 s | one-shot | should | M13 |
| `assets/music/ending/ending_epilogue_knight.ogg` | 14 s | one-shot | should | M13 |
| `assets/music/ending/ending_step_off_board.ogg` | 26.7 s | one-shot | must | M13 |
| `assets/music/ending/ending_hold_image.ogg` | 26.7 s | loop | must | M13 |
| `assets/music/ending/credits_theme.ogg` | 150 s | loop | must | M13 |

Old files removed, by old group:

| old group | old files removed |
|---|---|
| music_vistas | 6 |
| music_hub | 5 |
| music_blocktower | 4 |
| music_bookshelf | 4 |
| music_boss_ubb | 4 |
| music_core_stems | 4 |
| music_dollhouse | 4 |
| music_toybox | 4 |
| music_underbed | 4 |
| music_boss_b1 | 3 |
| music_boss_bsb | 3 |
| music_boss_btb | 3 |
| music_boss_dhb | 3 |
| music_boss_kb | 3 |
| music_act1 | 2 |
| music_ending_credits | 2 |

### 4. Deferred files stay at could, ordered last

No deferred file was dropped. One repair: 21 file-level `must` priorities (the body, body_n and body_e stills of the Veteran and Desperate Pawn, Passant Wraith, Promoted Zealot, Guard Knight, Mirror Bishop and Torn Bishop) sat inside `could` groups and sorted first in M14; they now inherit `could`. `by-milestone.md` lists must, then should, then could inside every milestone (M14 now holds 0 must, 1 should and 754 could). The owner's "28 fallen-piece remains" are the 28 `remains*.png` files (the 27 `remains.png` plus `remains_b.png` of the Pawn Recruit): they are NOT all `could` today (10 could, 11 should for active enemies, 7 must for the six bosses' toys and the Rule Engine's open box, which the 'cleared rooms stay clean' decision needs). The brief was "no change", so their priorities are untouched; setting the 11 `should` enemy remains to `could` is one line per group if the owner wants them deferred too.

### 5. Prompts that pointed at another group

The 82 `PALETTE` lines that pointed at other groups were fixed in round 3 with `{palette:<group_id>}` tokens: 17 groups, 106 prompts, every one now carries the real hex list (checked again). This pass removed the remaining look and role pointers: **252 prompts in 38 groups named another group by its id** ("the same pad as guard_raise_arc", "the separate prop rescue_trap_pebble", "matches guard_hold_shield frame 1", "Same brackets as call_target_valid"); each now carries the colours, rows or one-line description it needs, or just says "a separate file". A further batch of pointers a text-only tool cannot open (feel_profile.tres, "the plan", "bible", concept art, repo file paths of other groups, "same design as the in-game sprite", "same material language as its box") was rewritten inline: 1126 prompts in 101 groups changed in all. A new lint (`lint_self_contained`) fails the build if any prompt text names another group again.

### Generator changes (`build_requests.py`)

New kind and media `sourcing`; `.ogg` for music and ambience and `.wav` for SFX and voice (per-kind check); OGG loop and acceptance wording; lints `lint_self_contained`, `lint_pieces` (piece_class groups are 32x32 with a CELL FIT paragraph and a scale row; no other character sprite is larger than a cell), `lint_audio_formats` (music and ambience declare `ogg`, SFX `wav`, no stem or layer wording in music), `lint_sourcing`; README rules for pieces, one-track-per-area and glyphs; the by-milestone intro says could is deferred and last.

### Still open

- Decide whether the credits should be a one-shot with a final chord (a different file) or the looping piece now specified.
- The Kenney tile numbers marked `tile` come from a community listing, not from the pack: check each against the preview. Tab, Ctrl, Alt, Enter and the D-pad are `locate`.
- (Answered 2026-10-13, section 15: boss size is per boss.) Bosses are treated as pieces (24x28 at most) by default; tell me if a boss may be larger and only `piece_boss_32` and the six boss groups change.
- The scene must change with this list (M2): sprite offset, pips, arrow, weapon pivot, shadows.

## 14. Owner answers applied 2026-10-12, round 5: fixes after the verifier

The verifier checked the round-4 result against the four owner answers and found six open points (below). Round 5 fixes what is a spec defect and
leaves what is a decision to the owner. It is `python3 /tmp/asset_spec/build/round5/run_all.py`: it patches the round-4 output in place, every edit
checks whether it is already applied (a second run changes nothing), and `sh /tmp/asset_spec/build/finalize_all.sh` now runs round 3, round 4,
round 5 and the generator in that order. `/tmp/asset_spec_backup_round5/` is a copy of the specs exactly as the verifier saw them (kept for
comparison; the old `build_requests.py` is `/tmp/build_requests.py.before_round5`). Totals did not change: **8300 files in 856 groups**, same
paths, same priorities, same milestones.

### What changed

1. **Prompts that pointed at a sibling file.** The verifier counted about 84 mentions in 35 groups; the new lint (below) found **149 text fields in 79 groups** on the
   round-4 specs once it also looked for bare names, parenthesised names and "idle frame 1" style frame pointers. All are rewritten: 272 text fields in
   129 groups changed in all. Each pointer became the description it stood for, or was dropped when the sentence before it already described the thing:
   - `tiles_dollhouse_lawn` (16 path and corner files): the group now carries a PATH GEOMETRY and LAWN note (a 16 px band, 6x6 px cobbles, 2 px cream grout, lawn #6E9B58) and every file uses it instead of "as path_pink_h and path_pink_v / matching lawn_a". The geometry is a new concrete choice made here (the old text never gave a width): change it in one place if you prefer another.
   - `hub_chess_box_lid` (14 frames), `box_clasp_close`, `drape_sway`, `rook_throne_break`, `ruler_sweep_diag`, `hud_rank_tally`, `hud_strip_bottom`, `menu_rows`, `hud_courage_pips`, `hud_skill_slots`, `tiles_shared_wood_light` and `_shade`, `tiles_chess_rug_runner`, `tiles_bookshelf_bookmark`, the seven exits groups (open gate = "the same gate (design below) swung aside"), the chalk bridge, cracked blocks, `black_line_seal`, rescue traps, the Under-Bed props and the 21 "(as prop_open.png)" end-state notes on animation frames.
   - Frame pointers to another clip ("matches idle_authority_p2 frame 1", "identical to hold frame 1", "exactly like WARNING frame 1", "same pose as wake frame 1"): the pose now says what is drawn. The boss story transitions, the telegraph grow-in frames, `hero_reactions`, `hero_leap_and_free_step`, `ruler_gate_press`, `corruption_cell` and `knight_landing_cell` changed.
   - "Matches the last frame of the defeat clip" on 25 text fields of the enemy and boss `remains` files and "matches remains.png" on the matching defeat poses ("matches remains.png"): each side now describes itself.
   - Facing stills and phase notes: "the body_n / body_e stills" became "the back-view and side-view body stills"; "body.png is phase 1" became "the plain standing body still is the phase 1 look"; the boss `move_p2/p3/p4` sentence says "per-phase variants of that loop".
   - Look pointers to another group ("same crayon-tick language as the objective tick", "same cardboard language as the boss nameplate", "the same track as the Toybox tiles", "same as light A", the diagonal Rule Mark, `call_target_free_cast`, `book_strike_medium`, `hub_under_bed_shadow`, `white_pawn_soldier`): rewritten with the colours or the description.
   - Room ids that read like file names in the SFX/VFX text (`ub2_last_board`, `bs3_torn_page_bridge`) became room names; a stale "wave-intensity layer" in `world_waves` is gone (one track per area, no layers).
2. **The lint now catches file names, not only group ids** (`lint_sibling_pointers` in `build_requests.py`; the README section 8 lists it). It fails the build for (a) an image or sound file name (`x.png`, `dir/x.wav`) other than the entry's own, (b) the file stem, folder name or clip name of another entry after a cue such as same / identical to / matches / as / like / than / exactly / frame of, or in brackets, and (c) "<clip> frame N" naming a different clip. Merely naming an own clip or file as a label ("lane_channel is the loop while a lane grows") is still allowed. Sourcing and font groups are exempt (their text is about the pack's files). On the round-4 specs it reports 149 problems; on the round-5 specs 0.
3. **Black King poses that broke the zero-headroom rule.** The verifier named five frames; checking every King pose against the 28 px body found thirteen: `windup_kings_reach` 1 and 2, `windup_lock_direction` 4, `windup_restore_formation` 1 and 4, frame 3 of the four `move` variants (it lifted the base 2 px), and in `boss_king_story` `intro` 3, `idle_authority_p1` 2, `transition_p1_p2` 3 and `transition_p2_p3` 4. Each now says what a full-height body can do: squash, widen, cape or cross-lift instead of "stretching 2 px", "base lifting 2 px", "rising 2 px". A rise out of the stoop is allowed only up to the 28 px full height. A scan of every piece group's pose texts for lifts, rises and stretches larger than the headroom stated in its CELL FIT paragraph found nothing else.
4. **Fit with a 2 px margin for the pieces' attached files.** `act1_white_king_extras` (crown, tie and shadow; the shadow was 30x14) now carries a CELL FIT note (2 px of empty canvas on every side, shadow at most 28x14). `actor_shadow_l` (bosses) is now 28x12 outer ring instead of 30x12, and all three piece shadows say the outer ring leaves at least 2 px at both ends. Effect files that are larger than a cell by design (telegraph auras of 40, 56 and 96 px, boss auras and phase bursts of 96x96, `defeat_poof_medium` and `pawn_victory_sparkle` of 48x48, `actor_shadow_xl` for the Rule Engine) are NOT pieces and keep their size.
5. **Anchor stated exactly.** Every piece stands on the base-bottom centre (16,30) of its 32x32 cell: 14 px below the cell centre (16,16); the body box is centred 3 px below the cell centre for the pawn, 2 for knight, bishop and rook, 1 for the queen and 0 for the king (bosses 3, 2, 2, 2, 1, 0). The style block and the seven `piece_*_32` scale rows say so. This is a reading of "the base sits slightly below the cell centre", see the open list.
6. **Glyph tile numbers.** On 2026-10-13 all 40 `tile` numbers were re-read against the community rename listing (gist idbrii/804ba1b902d8631f3bc82b8cb08b5f5f): every number carries the matching name (W is 0086, Esc 0017, A button 0004, left bumper 0553, stick click 0152 and so on), and its D-pad and meta-key blocks are commented out there, which is why those stay `locate`. The pack page (kenney.nl/assets/input-prompts-pixel) was read again: CC0, version 1.0 (2021), 16x16, 800 files. Nothing was downloaded, so the pack's own pictures were still not opened; the sourcing prompt says that and asks the owner to look at each tile before copying.
7. **Overwrite hazard closed.** `/tmp/asset_tools/build/finalize.py` and `build_all.py`, `/tmp/asset_spec/build/merge.py` and the round 1 and round 2 `run_all.py` now refuse to run (exit 1, message points at `finalize_all.sh`) unless `ASSET_SPEC_ALLOW_REBUILD=1` is set. The `part*.py` scripts and the `*.partN.json` files are fragments the generator never reads.

### Decisions that stay with the owner

- **The 28 `remains` files are not all `could`**: 10 are, 11 (active enemies) are `should` and 7 (the six boss toys and the Rule Engine's open box, which the 'cleared rooms stay clean' decision needs) are `must`. Answer 4 said "no change", so priorities are untouched. Setting all 28 to `could` is one line in each of the 18 groups; say so and it moves them to the end of their milestone.
- **Anchor**: (16,30) is the only anchor a 28 px king can use with a 2 px margin. If "slightly below the centre" meant the sprite node's origin should be the cell centre instead, that is a scene offset of (0,-14), not a change to the art.
- (Answered 2026-10-13, section 15: boss size is per boss.) **Bosses are pieces** (24x28 at most) until you say otherwise; only `piece_boss_32` and the six boss groups change.
- **Kenney tile pictures**: still to be looked at once next to the pack preview; 9 `locate` and 12 `compose` entries need your judgement.
- The scene must change with this list (M2): sprite offset, pips, arrow, weapon pivot, shadows.

## 15. Owner answers applied 2026-10-13: all art at 1x1, boss size per boss

Source: `docs/owner-decisions.md` (the 2026-10-13 entry quotes the owner: "Tất cả 1×1" and "tuỳ boss"). Two commits on the branch `assets/1x1-bosses`, one per decision. Only `docs/assets/` and `tools/asset_requests/` changed.

### 1. "Tất cả 1×1": everything is drawn at 1x1 pixels

Tóm tắt cho anh: mọi ảnh (quân cờ, tile, vật cảnh, hiệu ứng thế giới, giao diện, icon, chân dung, bàn tay của bé) giờ là một pixel vẽ = một pixel game ở 640x360. Không còn lưới 2x2 "chunky", không còn "vẽ nửa kích thước rồi phóng đôi". Canvas 32x32 có đủ 32x32 pixel thật để vẽ chi tiết nên các mô tả đếm chi tiết bằng "art pixel" được viết lại bằng pixel.

What changed:

- **Style block** (`style.json`): the RESOLUTION AND PIXEL SCALE paragraph now says one scale, 1x1, for every file, and states the detail budget (a 32x32 piece or tile has 32x32 individually placed pixels, so single-pixel eye glints, rivets, stitches and grain lines are expected). The two-scale text (CHUNKY 2x2 world, FINE UI, "steps of 2", "2 canvas pixels in world art") is gone; a "1 px" outline is exactly one pixel.
- **Scale table**: every row has `block_px` 1 (it was 2 on 47 world rows: 21 effect, 16 prop, 9 sprite and 1 tile). The `(NxM art pixels)` counts in the piece rows were dropped (the px size beside them was already right). The child's hand row no longer calls the hand "the only fine-pixel world sprite": it keeps its 192x144 canvas, drawn at the same 1x1 as everything else.
- **Group texts**: the 67 `(NxM art pixels)` counts in the CELL FIT and body-size sentences were removed (the pixel sizes stay); 7 pawn groups no longer compare the pawn with "the 16-pixel-wide generator output"; the remaining art-pixel counts (marble 6 art pixels, health pip 4x4 art-pixel disc, facing arrow, guard crumbs, swipe crumbs, a dash "a multiple of the 2 px art pixel") are restated in pixels; "chunky" in pixel-art senses (the Rule Engine, vista kits, title overlays, actor shadows, HUD shapes, the wordmark) became "1x1 pixels" or "bold", and in object senses (a chunky toy block, post, train) "sturdy" or "thick"; "2x2" fragments, sparks and dots became "2 px square"; the child hand is no longer "twice the pixel density of the chess pieces".
- **Generator** (`build_requests.py`): `resolve_block_px` is always 1; the CANVAS line of every image prompt reads "1 art pixel = 1 game pixel"; the acceptance line asks for real 1x1 pixels; README/STYLE text and the relaxed-rule notes follow. New lint `lint_pixel_scale` (below).

The new lint fails the build when any image prompt still mentions a 2x2 block, "chunky" art, half-size or half-resolution drawing, upscaling, art pixels as a unit of their own, a block of identical pixels, "steps of 2", or a "world" versus "fine" pixel scale; it also requires the RESOLUTION AND PIXEL SCALE paragraph, `block_px` 1 on every scale row and the 1x1 CANVAS wording. A bare "2x2" is rejected unless it counts cells ("a 2x2-cell emblem", "the 2x2 hub emblem", "a 2x2 round table"). `python3 tools/asset_requests/build_requests.py --self-test` proves it on sample phrases.

Totals did not change: **8300 files in 856 groups**, same paths, ids, priorities and milestones. Every one of the 6758 image prompts changed (the style block and the CANVAS line); 2098 files in 109 groups also changed in their own text.

### 2. "Tuỳ boss": boss size per boss

Tóm tắt cho anh: mỗi boss có chỗ đứng riêng. Đội Trưởng Tốt Đen, Mã Đội Trưởng, Giáo chủ Tượng, Nữ hoàng Mánh Khóe và Vua Đen đứng trên MỘT ô (canvas 32x32, thân gọn trong đó chừa 2 px). Xe Cai Ngục chiếm 2x2 ô ở giai đoạn 1 và 2 (canvas 64x64, thân tối đa 56x52, đế ở (32,62) sát đáy, chừa 2 px mỗi cạnh) rồi chỉ còn một ô ở giai đoạn 3 sau khi tự phá ngai. Cỗ máy Luật sau lưng Vua chiếm 3x3 ô (canvas 96x96, thân tối đa 92x92, đế ở (48,94)). Các số thân boss ở bảng dưới là đề xuất của mình (anh sửa được: mỗi dòng là một hàng của bảng cỡ).

| boss | footprint | canvas | body box (px) | base-bottom anchor | groups |
|---|---|---|---|---|---|
| Black Pawn Captain | 1 cell | 32x32 | at most 24x22 | (16,30) | `boss_captain_looks`, `_combat`, `_story` |
| Knight Captain | 1 cell | 32x32 | at most 24x24 | (16,30) | `boss_knight_captain_*` |
| Bishop Oracle | 1 cell | 32x32 | at most 22x24 | (16,30) | `boss_bishop_oracle_*` |
| Rook Warden, phases 1 and 2 | 2x2 cells | 64x64 | at most 56x52, top y=10 | (32,62) | `boss_rook_warden_looks`, `_combat`, `_story` |
| Rook Warden, phase 3 | 1 cell | 32x32 | at most 24x24 | (16,30) | `boss_rook_warden_looks_p3`, `_combat_p3`, `_story_p3` |
| Queen of Tricks | 1 cell | 32x32 | at most 24x26 | (16,30) | `boss_queen_*` |
| Black King | 1 cell | 32x32 | at most 24x28 | (16,30) | `boss_king_*` |
| Rule Engine (machine behind the King) | 3x3 cells | 96x96 | at most 92x92 (squat cabinet about 88x80) | (48,94) | `boss_rule_engine` |

What changed:

- **Scale table**: `piece_boss_32` now lists the five one-cell bosses and the Warden's phase 3; new rows `piece_boss_2x2_64` (Warden, phases 1 and 2) and `boss_engine_3x3_96` replace `boss_engine_96x80`. The style block says a boss's size is its own, and that a body on a larger footprint obeys the rule of a piece on one cell (smaller than the footprint, 2 px margin, base line near the bottom).
- **Bodies, phase looks and every frame**: the five one-cell bosses keep their canvas and gain the sentence that this boss stands on one cell. The Rook Warden is split by phase because a group has one canvas: the looks, combat and story groups (phases 1 and 2, 64x64) each get a sibling `_p3` group (phase 3, 32x32). The Warden's 17 combat clips and 5 story clips on the big canvas are re-measured for a 56x52 body (every px measure x2.4: a 2 px squash is now 5 px); phase 3 keeps its clips. The charge loops had one look for any phase, so three one-cell `charge_p3_s/n/e` loops (9 frames) were added. The phase 2 to phase 3 transition starts on the full footprint, so it stays on the 64x64 canvas and its last two frames show the Warden shrinking to one cell (24x24 body) in the footprint's south-west cell: that cell is my proposal for where the shrunk piece stands (the engine can keep another cell; the art would then be mirrored). The Rule Engine goes from 96x80 to 96x96 with a CELL FIT paragraph (92x92 at most, 2 px margin, base rim y=94).
- **Boss-owned overlays sized to the footprint**: the boss shadow `actor_shadow_l` (32x16) now covers the five one-cell bosses and the Warden's phase 3; a new `actor_shadow_2x2_cells` (64x24, rings 60x20 and 44x10) is the Warden's shadow in phases 1 and 2; `actor_shadow_xl` (96x24) is the Rule Engine's, with rings 92x20 and 68x10; the heavy stun bar `status_stunned_boss` (64x24) now serves the Warden's phase 2 stun (Breach Wall) and the 3 s stun after the throne smash, which is phase 3, uses the one-cell stun bar. Auras and bursts (the six idle auras, the large telegraph aura, the phase bursts, the kill star and the toy-transform ring, all 96x96) are effects and stay as they are; their text says they may extend beyond the footprint.
- **Generator**: groups may carry `footprint_cells` (default 1x1); a piece's canvas must be 32 px per cell and carry a CELL FIT paragraph; `BOSS_FOOTPRINTS` pins every boss group to its footprint (an unlisted boss group fails the build); scale-table rows exist for the 2x2 and 3x3 footprints and only those rows (and the hand) may be larger than a cell; a Warden pose that names the wrong phase for its canvas fails the build; the horizontal drift allowed between the frames of a clip is 3 px on one cell, 7 px on 2x2 cells and 11 px on 3x3; README, STYLE and delivery rule 8 are rewritten.

Totals: **8310 files in 860 groups** (before this decision: 8300 in 856; +4 groups: three Warden `_p3` groups and the 2x2-cell shadow; +10 files: 9 `charge_p3` frames and the shadow). 32 files kept their path but moved to a `_p3` group, so their ids changed (ids carry the group name); no path was removed.

### Still open

- The placeholder generators that still draw 2x2 blocks (kingdom tiles, Stage 1 room art, `tools/generate_chess_sprites.gd`) are brought to 1x1 when next touched; this list does not depend on them.
- Which cell the shrunk Warden keeps (south-west here) and the 56x52 / 92x92 body boxes are proposals; each is one data row.
- The hand is no longer "twice as fine" as the world. Its 192x144 canvas is unchanged; if you want it to read as bigger or smaller next to a pawn, that is one scale-table row.
