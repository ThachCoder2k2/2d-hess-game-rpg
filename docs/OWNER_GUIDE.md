# Hướng dẫn cho chủ dự án (Owner Guide)

> **Trạng thái (Status): CẬP NHẬT Ở M1b (2026-10-12).** Tạo ở M1a, M1b đã điền đường dẫn thật vào
> mục 5 cho những gì đang tồn tại. Các milestone M2-M14 của `docs/game-base-plan.md` sẽ điền tiếp phần
> còn lại của bảng đích; M14 viết bản đầy đủ.
>
> **Ngôn ngữ:** tiếng Việt đứng trước, thuật ngữ tiếng Anh giữ nguyên. Nếu hai bản khác nhau thì
> **bản tiếng Anh là bản chuẩn** (plan D19). Phần tiếng Việt do agent viết, chưa có người bản ngữ
> rà lại; bạn cứ sửa thẳng vào file nếu thấy sai.
>
> *EN: Updated at the end of M1b with the real paths. Vietnamese first, English authoritative where
> they differ. Section 5 lists what you can change today at its real path; the target table below it
> says which milestone makes each remaining row true.*

## 1. Chơi bản build hiện tại (How to play the current build)

1. Cần Godot 4.6. Mở `project.godot` trong Godot rồi bấm **F5** (cảnh chính là `shell/game_root.tscn`).
   Hoặc, trong terminal tại thư mục dự án (Godot nằm ở thư mục cha của dự án):
   `../Godot.app/Contents/MacOS/Godot --path .`
2. **Clone mới:** chạy một lệnh `tools/bootstrap_worktree.sh` (khoảng 50 giây). Nó import lần đầu, chạy
   bốn generator sinh art tạm vào `assets/_generated/` (thư mục này không nằm trong git) và import lần
   hai. Game không còn phụ thuộc vào thư mục đó: các hình tạm game dùng là file được track trong
   `content/`.
3. Game vào thẳng phòng T1 và đi theo tuyến Stage 1: T1 → T2 → T3 → T4 → B1 → H1 (greybox, chưa
   chỉnh art). Muốn chơi lại từ đầu: xoá file save `world_state.cfg` trong thư mục user data của
   game (trong Godot: menu **Project → Open User Data Folder**).
4. Phím:

| Phím | Việc |
|---|---|
| `WASD` hoặc mũi tên | đi một ô |
| `Shift` + hướng | xoay tại chỗ, không đi |
| `Space` hoặc `K` | Wooden Sword (có sau khi nhặt kiếm ở T2) |
| `Q` | Pencil Thrust |
| `R` | reset phòng |
| `B` | mở Book of House Rules |
| `F3` / `F11` | bật tắt debug view / toàn màn hình |

5. Chưa có: menu title, pause, settings, tay cầm. Các mục đó nằm trong lộ trình (milestone M4).

*EN: Open `project.godot` in Godot 4.6 and press F5 (main scene `shell/game_root.tscn`), or run the
binary with `--path .`. On a fresh clone run `tools/bootstrap_worktree.sh` first. Delete
`world_state.cfg` in the user data folder to restart the run. No title, pause, settings or gamepad yet
(milestone M4).*

## 2. Trạng thái nằm ở đâu (Where status lives)

| File | Dùng để làm gì |
|---|---|
| `docs/where-we-are.md` | **Trạng thái thật**: mỗi mảng đang ở bước nào, rủi ro, lộ trình, và các quyết định chỉ bạn chốt được |
| `docs/game-base-plan.md` | **Kế hoạch xây bản base hoàn chỉnh**: các quyết định đã chọn, milestone M1a-M14, các cổng OG0-OG4 |
| `docs/claude-md-diff.md` | Những dòng của `CLAUDE.md` đã đổi (cũ → mới). Bạn đã duyệt ở cổng OG0 và M1b đã áp dụng |
| `docs/migration-notes.md` | M1b đã chuyển file nào đi đâu (bảng cũ → mới) và những chỗ phải tự quyết |
| `content/_placeholders.json` | Danh sách art và âm thanh vẫn còn là hình/tiếng tạm (xem mục 4) |
| `docs/owner-review-template.md` | Form bạn điền sau khi chơi duyệt một việc |
| `task_plan.md`, `progress.md`, `findings.md` | Nhật ký của agent: phase, việc đã làm và cách đã kiểm, các phát hiện kỹ thuật |
| `docs/ARCHITECTURE.md` | Code chạy như thế nào (dành cho người đọc code) |

Mỗi việc đi qua sáu bước của bạn, không bỏ bước nào:

```text
1 lập kế hoạch → 2 bạn duyệt → 3 build → 4 verify → 5 bạn chơi và duyệt → 6 chấp nhận
```

Agent tự kiểm xong chỉ là bước 4. Bước 5 và 6 chỉ có khi **chính bạn** viết ra. Các cổng của bạn:

| Cổng (Gate) | Khi nào | Bạn kiểm gì |
|---|---|---|
| OG0 | cuối M1a, trước M1b | **đã trả lời 2026-10-12** ("Đồng ý", ghi nguyên văn trong `progress.md`): di chuyển thư mục, sửa `CLAUDE.md`, phòng đã dọn giữ sạch, truyện viết gốc bằng tiếng Anh |
| OG1 | sau M5 | chơi từ title đến credits qua các phòng stub (khoảng 10 phút): bộ khung có đúng cảm giác không? |
| OG2 | sau M7b | cảm giác chơi: Sword, Pencil, Rule Step, khoá chân khi chém, stagger, buffer |
| OG3 | sau M9 | Stage 1 và Toybox, district đầu tiên hoàn chỉnh |
| OG4 | sau M13 | cả game, trước đợt đánh bóng bàn giao |

Nếu bạn chưa trả lời, agent tiếp tục theo các giá trị mặc định đã ghi trong plan và ghi giả định vào
`progress.md`; bạn vẫn có thể đảo lại sau.

*EN: `docs/where-we-are.md` is the status page; `docs/game-base-plan.md` is the build plan.
Agent self-checks are step 4 only; steps 5 and 6 need your own words. Gates OG0-OG4 are your cheap
vetoes; with no reply, agents continue on the stated defaults and log them.*

## 3. Chạy /verify (How to run /verify)

Trong Claude Code, tại thư mục dự án, gõ **`/verify`**. Nó chạy: hai bài tự kiểm tra của công cụ
(`run_all_tests.py --self-test` và `move_res.py --self-test`), rồi một lệnh duy nhất chạy mọi suite
(`python3 tools/run_all_tests.py --strict`: bước import của editor, từng suite trong một tiến trình
có giới hạn thời gian, và kiểm tra mọi nhãn `PASS:` cũ vẫn còn), rồi `git diff --check`
(chi tiết trong `.claude/commands/verify.md`).

Kết quả đúng là:

- hai dòng `SELF-TEST: 0 failure(s)`;
- các dòng cuối của runner là `0 failed` và `GREEN`, kèm dòng `235 recorded, 235 still print PASS`;
- bước import không có dòng `ERROR` hay `Parse`;
- `git diff --check` không in gì.

Chạy tay (Godot nằm ở thư mục cha, đường dẫn dự án có dấu cách nên phải để trong ngoặc kép):

```bash
python3 tools/run_all_tests.py --strict
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd   # chỉ một suite
```

*EN: Type `/verify` in Claude Code. It runs the two `--self-test`s, then `python3 tools/run_all_tests.py
--strict` (import pass, every suite, the baseline labels), then `git diff --check`. Expect
`SELF-TEST: 0 failure(s)` twice, `0 failed` and `GREEN`, a clean import and a silent `git diff --check`.*

## 4. Khi bạn làm việc trong Godot editor (Editor handoff)

Khi cần bạn mở editor, agent đưa đúng khuôn này (xem `AGENTS.md`):

```text
Open:    <scene cần mở>
Tune:    <node và property cần chỉnh>
Goal:    <cảm giác muốn đạt>
Try:     <vài việc ngắn để chơi thử>
Tell me: <điều agent cần bạn báo lại>
```

Vài điều giúp tránh va chạm giữa bạn và agent:

- Agent chỉ `git add` từng đường dẫn cụ thể, không bao giờ `git add -A`, nên file bạn đang sửa dở
  trong editor không bị cuốn vào commit của agent.
- **M1b đã xong:** toàn bộ thư mục đã được chuyển (`docs/migration-notes.md` ghi file nào đi đâu). Nếu
  bạn có `.tscn`/`.tres` đang sửa dở theo đường dẫn cũ (`scenes/`, `objects/`, `resources/`, `scripts/`),
  đừng chép đè: báo agent, nó chạy `tools/move_res.py --rewrite-only <file>` để sửa đường dẫn trong file
  của bạn bằng script (plan §13.6).
- Thư mục `content/` là **của bạn**: dữ liệu, art, âm thanh, lời thoại, và không có file `.gd` nào ở đó
  (test kiểm điều này). Tên thư mục chính là id (ví dụ `content/enemies/knight_tracker/`).
- **Thay art hoặc âm thanh = ghi đè file cùng tên.** Ví dụ ghi đè `content/enemies/pawn_recruit/body.png`
  bằng hình của bạn. Không cần sửa code hay scene. Muốn biết còn những file tạm nào:

```bash
../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/list_placeholders.gd
```

  Danh sách này dựa trên mã băm (sha256) trong `content/_placeholders.json`: một file còn là "tạm"
  khi mã băm của nó vẫn bằng mã đã ghi lúc tạo, nên bạn ghi đè file là nó tự biến khỏi danh sách,
  không phải đánh dấu gì thêm. Hiện có 25 file tạm (3 hình nhân vật, 4 icon, 1 pickup, 2 nền phòng,
  1 bộ tile, 4 hình giao diện, 9 tiếng, 1 bản nhạc).
- Quy ước của bạn: mỗi thứ một file (một PNG cho một ô tile, một prop, một icon, một khung hình), không
  gộp sheet hay atlas; công cụ sẽ ghép atlas sau. Chỗ để sẵn: `assets/tiles/<khu>/<tile_id>.png` cho
  từng tile và `content/<loại>/<id>/anim/<clip>/<NN>.png` cho từng khung hình. Công cụ ghép chưa có (nó
  không thuộc M1b), nhưng cây thư mục không chặn nó.

*EN: M1b is done, so the whole tree has moved (`docs/migration-notes.md`). If you have an unsaved or
uncommitted scene using an old path, tell the agent: `tools/move_res.py --rewrite-only <file>` fixes the
paths in your file by script. `content/` is yours and holds no `.gd`. To swap art or audio, overwrite the
file with the same name; `tools/list_placeholders.gd` prints what is still a stand-in by comparing file
hashes recorded in `content/_placeholders.json`, so an overwrite clears the flag by itself (25 stand-ins
today). Your direction of one file per thing is honoured: single tiles go in `assets/tiles/<district>/
<tile_id>.png` and animation frames in `content/<kind>/<id>/anim/<clip>/<NN>.png`; the assembly tools
are later work, and nothing in the tree blocks them.*

## 5. Bảng "Muốn đổi X thì sửa Y" (How do I change X?)

**Hôm nay (sau M1b)**, các việc hay làm nằm ở đây, với đường dẫn thật:

| Bạn muốn... | Hôm nay sửa ở đâu |
|---|---|
| Chỉnh một enemy (máu, tốc độ, AI, kiểu tấn công) | `content/enemies/<id>/enemy.tres` và các `.tres` nó trỏ tới: `movement.tres`, `decision.tres`, `unarmed_attack.tres`, `visual.tres` nằm cạnh nó, hoặc `content/enemies/_shared/{movement,attacks,decisions,visuals}/` nếu nhiều pawn dùng chung |
| Thêm một enemy mới không cần code | lệnh `/new-enemy` (xem `.claude/commands/new-enemy.md`; tạo thư mục `content/enemies/<id>/`) |
| Đổi bố cục phòng hoặc chỗ đứng của enemy | mở `content/rooms/<id>/room.tscn`, kéo node (enemy là node `ActorView` đậu trên một ô) |
| Chỉnh cảm giác con tốt (bước, courage, invulnerability, kiếm) | các node `MovementComponent`, `InputComponent`, `CombatComponent`, `HealthComponent` trong `presentation/views/actors/player.tscn`, và `content/skills/wooden_sword/wooden_sword.tres`, `content/skills/pencil_thrust/pencil_thrust.tres` |
| Đổi sprite (con tốt, enemy, icon, pickup) | ghi đè `body.png` / `icon.png` / `pickup.png` trong thư mục của nó: `content/player/`, `content/enemies/<id>/`, `content/skills/<id>/`, `content/pickups/<id>/` (xem mục 4). Tới M2, mọi pawn dùng chung hình `pawn_recruit` và bishop dùng hình `knight_tracker` (chúng chưa có hình riêng) |
| Đổi hình bàn đồ vẽ tay | `assets/map_pieces/` (hình bạn vẽ tay, được track; thay thế bản sinh tự động) |
| Đổi hình nền của phòng T1 hoặc T2 | ghi đè `content/rooms/t1_white_kings_fall/background.png` hoặc `content/rooms/t2_fallen_sword_tile/background.png` |
| Đổi một trang của Book of House Rules | `content/rules/<id>/page.tres` (chữ nằm trong file này tới khi có hệ `.po` ở M4); danh sách trang: `content/rules/rule_book.tres` |
| Đổi độ khó (nhân máu và sát thương toàn cục) | `content/difficulty/standard.tres` |
| Đổi vũ khí nhặt được trên sàn | `content/pickups/<id>/<id>.tres` |
| Đổi đồ thị thế giới (phòng nào nối phòng nào) | `content/world/world.tres` |
| Đổi bộ tile của sàn/tường | `content/tilesets/<bộ>/tileset.tres` và `tilemap.tscn` (đừng sửa tay `tile_map_data`, dùng `tools/paint_*.gd`); atlas ở `assets/tiles/<bộ>/atlas.svg` |
| Đổi âm thanh sự kiện / âm thanh chuyển động | ghi đè `assets/sfx/<tên>.wav` (cùng tên là mọi chỗ dùng tự nâng cấp), hoặc `presentation/audio/sfx_manager.tscn` (mục `streams` trong Inspector) / track âm thanh trong clip của actor |
| Đổi phím | `project.godot`, mục `[input]` (hoặc Project Settings → Input Map) |
| Đổi chữ (thoại, thông báo) | còn nằm rải rác: `RoomEncounter` trong `content/rooms/<id>/room.tscn`, `RoomObjective` `.tres` (`tests/fixtures/first_encounter/objective.tres` là ví dụ), `shell/game_root.gd`, `presentation/ui/hud/hud.gd`. Hệ thống `.po` đến ở M4 |
| Xem còn file art/âm thanh tạm nào | `tools/list_placeholders.gd` (mục 4) |

**Bảng đích** (từ `docs/game-base-plan.md` §13.5). Các thư mục `content/enemies`, `rooms`, `rules`,
`skills`, `pickups`, `player`, `difficulty`, `world`, `tilesets` **đã tồn tại** từ M1b; các đường dẫn
khác trong bảng (`content/story`, `audio`, `feel`, `progression`, `ui`, `bosses`, `props`, các file
`skill.tres`, `pickup.tres`, `player.tres`, `.po`...) **chưa có** cho tới milestone ghi ở cột cuối.
Cột cuối ("available after Mx") là milestone sau đó hàng ấy mới đúng. Plan không ghi milestone cho
từng hàng, nên cột này là cách đọc của docs lane từ §15 và sẽ được kiểm lại ở mỗi milestone. Khi một
milestone xong, nó phải kiểm đường dẫn thật của các hàng thuộc về mình và xoá chữ "available after Mx" ở
hàng đó. Bốn hàng sau đã được M1b kiểm và ghi "available now" (kèm phần còn thiếu): chỉnh một enemy, đổi
bố cục phòng, đổi sprite, đổi art nền phòng.

| Bạn muốn... (You want to...) | Sửa file này (Edit this) | Số file (Files) | Cần code? (Code?) | Trạng thái (Status) |
|---|---|---|---|---|
| Thêm một biến thể enemy (đổi skin, máu, tốc độ hoặc vũ khí) (Add a variant enemy (re-skin, new health, speed or weapon)) | `content/enemies/<id>/enemy.tres` (reusing `_shared` sub-resources), `body.png`; in a room, instance `actor_view_base.tscn` and set `definition`; the `ENEMY_<ID>_NAME` row in `story/text/<locale>/story.po`. | 4 | no | available after M2 (dòng tên trong `.po`: M4) |
| Thêm enemy có hành vi mới (Add an enemy with new behaviour) | `enemy.tres` + one `EntityComponent` or `AttackBase` script + one system file + one line in `ecs/schedule/<phase>.gd`; plus `events.gd` if it emits a new event and `ViewSyncSystem` if its visuals are new. | 4 new, up to 3 existing edited | yes | available after M3a (kiểu tấn công mới: M8a) |
| Chỉnh (retune) một enemy hoặc boss (Retune an enemy or boss) | its `.tres` | 1 | no | **available now** for an enemy (`content/enemies/<id>/enemy.tres` and its pieces; M2 regroups them), M8b (boss) |
| Thêm một skill vào slot có sẵn, dùng các loại effect có sẵn (Add a skill in an existing slot from existing effect kinds) | `content/skills/<id>/skill.tres`, `icon.png`, one `milestones/<id>.tres`, three rows in `skills.po` (name, description, hint), a `sound_bank.tres` row if the sound is new. HUD slot, input and cooldown bar come from the file and `slots.tres`. | 4-5 | no | available after M7c |
| Thêm một skill cần một phím mới (Add a skill that needs a free button) | the above + one `InputMap` action in `project.godot` + one `slots.tres` row | 6-7 | no | available after M7a |
| Thêm một skill cần một loại effect mới (Add a skill needing a new effect kind) | effect schema + handler + one line in `ecs/schedule/act.gd` + `skill.tres` + milestone + `.po` rows (Chalk Block is the worked example) | 7-9 | yes | available after M7a |
| Chỉnh một skill (Retune a skill) | `skill.tres` | 1 | no | available after M7a (verb mới), M7b (Sword và Pencil) |
| Đổi cách hoặc lúc nhận một skill (Change when or how a skill is earned) | the milestone `.tres` (trigger kind: boss_defeated, room_cleared, grant_marker, flag). Moving a physical marker = delete in room A + add in room B. | 1-2 | no | available after M7c |
| Thêm hoặc sửa một trang Book mà loại modifier đã có handler (Add or edit a Book page whose modifier kind already has a handler) | `content/rules/<id>/page.tres` + rows in `story.po` | 2 | no | available after M7c |
| Thêm một trang Book cần loại modifier mới (Add a Book page that needs a new modifier kind) | modifier schema + handler + schedule line + `page.tres` | 4-5 | yes | available after M7c |
| Thêm một Annotation (`SkillUpgrade`) (Add an Annotation (a `SkillUpgrade`)) | the upgrade row on `skill.tres` + `.po` rows | 2 | no | available after M7c |
| Viết lại một câu truyện, chữ UI hoặc một cái tên (Rewrite a line of story, UI text or a name) | one `msgstr` in `story/text/<locale>/*.po` (soft lints only warn in the editor) | 1 | no | available after M4 |
| Thêm một ngôn ngữ (Add a language) | `story/text/<locale>/{story,ui,skills,rooms}.po` + register them in `project.godot` | 5 | no | available after M4 |
| Đổi tên một nhân vật (Rename a character) | the `CHAR_<ID>_NAME` row | 1 | no | available after M6 |
| Thêm một đoạn hội thoại, câu ambient hoặc prompt (Add a conversation, ambient line or prompt) | a beat `.tres` (or a line in `script/<act>.txt` + `tools/build_beats.gd`) + its `.po` rows | 2-3 | no | available after M6 |
| Dựng một cutscene (Stage a cutscene) | beat `.tres` files + `.po` rows + a `TriggerMarker` in the room + `sound_bank` rows + `characters/<id>.tres` if there is a new speaker (+ a `cutscene.tscn` for a Tier-2 cutscene) | 5-7 | no | available after M6 |
| Thêm một phòng (room) (Add a room) | `room.tscn`, `background.png`, one exit marker in the neighbouring room, a `world.tres` entry (map slot), `.po` rows (name, start message, what happened here, locked message) | 5-6 | no | available after M5 |
| Đổi enemy hoặc bố cục của một phòng (Change a room's enemies or layout) | that `room.tscn` | 1 | no | **available now** (`content/rooms/<id>/room.tscn`) |
| Đổi một khoá (lock) hoặc thêm lối tắt (shortcut) (Change a lock or add a shortcut) | the exit or gate marker in `room.tscn` + the `locked_message` row | 2 | no | available after M5 |
| Thêm một prop chỉ xuất hiện khi đủ điều kiện (Add a prop that appears after a condition) | a `StateVariantMarker` on the prop in `room.tscn` | 1 | no | available after M6 |
| Đổi cách hub tiến hoá hoặc các biến thể ending (Change the hub evolution or ending variants) | `StateVariantMarker` props in H1's `room.tscn`, `ending.tres` | 1-2 | no | available after M6 (hub), M13 (ending) |
| Thêm pickup, shard hoặc keepsake (Add a pickup, shard or keepsake) | `pickup.tres`, `pickup.png`, a spawn in `room.tscn`, a `.po` row (+ a milestone row if it grants) | 4-5 | no | available after M7c |
| Thêm NPC hoặc cuộc giải cứu (rescue) (Add an NPC or rescue) | a prop with an `InteractComponent`, a beat, a flag in `flags.tres`, `room.tscn`, `.po` rows | 5 | no | available after M6 |
| Thêm một boss (Add a boss) | `boss.tres`, `enemy.tres`, `body.png`, the arena `room.tscn`, beats + `.po` rows, a milestone row, a `music_cues` row | 7-10 | no, if its attacks use existing kinds | available after M8b |
| Thêm hoặc chỉnh một phase của boss (Add or retune a boss phase) | `boss.tres` (a new windup clip also edits the boss's actor scene) | 1-2 | no | available after M8b |
| Đổi sprite (Swap a sprite) | overwrite `body.png` (+ `VisualDefinition.anchor_offset` if the frame size changes); the placeholder flag clears by hash | 1-2 | no | **available now** for `content/player/body.png` and the enemies that have a `body.png` (`pawn_recruit`, `knight_tracker`); `anchor_offset` and a `body.png` per enemy: M2 |
| Đổi art nền của một phòng (Swap a room's art) | overwrite `background.png` | 1 | no | **available now** for T1 and T2 (`content/rooms/<id>/background.png`); the other rooms get one with M5 |
| Đổi portrait, skin UI hoặc font (Swap a portrait, UI skin or font) | overwrite the file in `content/story/characters/`, `content/ui/theme/`, `assets/fonts/` | 1 | no | available after M4 (skin UI, font), M6 (portrait) |
| Thêm nhạc hoặc đổi bài nhạc đang phát (Add music or change which track plays) | drop the file in `assets/music/` + a row in `music_cues.tres` | 2 | no | available after M6 |
| Thêm hoặc đổi âm thanh sự kiện (pickup, jingle, UI) (Add or swap an event sound (pickup, jingle, UI)) | drop the file + a row in `sound_bank.tres` | 2 | no | available after M6 |
| Đổi âm thanh chuyển động hoặc sửa một animation clip (Swap a motion sound or edit an animation clip) | an **editor task** in `presentation/views/actor_view_base.tscn` (changes every actor that inherits it) or in a bespoke inherited view | 1 scene | no | available after M2 |
| Đổi bố cục HUD (Change the HUD layout) | the widget scene in `presentation/ui/hud/` | 1 | no | available after M4 |
| Chỉnh độ khó hoặc assist (Tune difficulty or assists) | `content/difficulty/<profile>.tres` (global health and damage multipliers live here); for one enemy, its `enemy.tres` | 1 | no | available after M8a |
| Chỉnh cảm giác chơi (rung, nháy, hit-stop, màu telegraph, chord window) (Tune game feel (shake, flash, hit-stop, telegraph colours, chord window)) | `content/feel/feel_profile.tres` | 1 | no | available after M7b |
| Đổi cảm giác của con tốt (thời gian mỗi bước, courage, invulnerability) (Change how the pawn feels (step time, courage, invulnerability)) | `content/player/player.tres` | 1 | no | available after M2 |
| Đổi luật kinh tế (Believe, shard, stagger, ngưỡng assist) (Change economy rules (Believe, shards, stagger, assist thresholds)) | `content/progression/rules.tres` | 1 | no | available after M7c |
| Đổi phím mặc định (Change input defaults) | the `[input]` section of `project.godot` | 1 | no | available after M4 |
| Đổi chữ ở màn title hoặc credits (Change title text or credits) | `credits.tres` + `.po` rows | 2 | no | available after M4 |
| Thêm cơ chế sàn mới (gai, công tắc) (Add a new floor mechanic (spikes, switch)) | marker + component + system + one schedule line (+ an event) | 4-5 | yes | available after M3a |

*EN: The first table lists today's real locations (all of these paths exist). The second is the target
Owner Change Table from plan §13.5; each row says which milestone makes it true, and the rows marked
"available now" were checked against the tree at the end of M1b.*

## 6. Từ điển nhỏ (Glossary)

| Thuật ngữ | Nghĩa trong dự án này |
|---|---|
| ECS | cách tổ chức code: *entity* là một số id, *component* chỉ chứa dữ liệu, *system* chứa luật chơi |
| entity / component / system | con tốt hay enemy là entity; máu, vị trí, trạng thái AI là component; "di chuyển", "tấn công", "nhận sát thương" là system |
| event | tin nhắn một chiều từ mô phỏng ra phần hiển thị (HUD, âm thanh, rung màn hình) |
| `.tres` | file dữ liệu (Resource) bạn chỉnh trong Inspector: enemy, kiểu tấn công, vũ khí... |
| `.tscn` | file scene: phòng, actor, HUD |
| puppet view | node chỉ để hiển thị, không có logic; hệ thống `ViewSyncSystem` điều khiển nó |
| room / zone | một phòng (bảng 16×9 ô) / một khu trong world graph |
| Book of House Rules | cuốn sách luật mà con tốt "viết thêm", phím `B` |
| placeholder | nội dung tạm do agent làm (art, lời, nhạc, số liệu) để bạn thay bằng tay. Với file art/âm thanh, "còn là tạm" nghĩa là mã băm sha256 của file vẫn bằng mã đã ghi trong `content/_placeholders.json` |
| id | tên thư mục của một thứ trong `content/` (ví dụ `knight_tracker`); chỉ viết ở một chỗ. Thư mục bắt đầu bằng `_` (như `_shared`) không phải id |
| gate (OG0-OG4) | điểm dừng để bạn duyệt hoặc chơi thử trước khi làm tiếp |
