# Hướng dẫn cho chủ dự án (Owner Guide)

> **Trạng thái (Status): CẬP NHẬT Ở M2 (2026-10-13).** Tạo ở M1a, M1b điền đường dẫn thật vào mục 5,
> M2 thêm mục 6 (quân cờ nhỏ hơn ô) và cập nhật các hàng về con tốt, enemy, sprite. Các milestone
> M3-M14 của `docs/game-base-plan.md` sẽ điền tiếp phần còn lại của bảng đích; M14 viết bản đầy đủ.
>
> **Ngôn ngữ:** tiếng Việt đứng trước, thuật ngữ tiếng Anh giữ nguyên. Nếu hai bản khác nhau thì
> **bản tiếng Anh là bản chuẩn** (plan D19). Phần tiếng Việt do agent viết, chưa có người bản ngữ
> rà lại; bạn cứ sửa thẳng vào file nếu thấy sai.
>
> *EN: Updated at the end of M2. Vietnamese first, English authoritative where they differ. Section 5
> lists what you can change today at its real path, with file counts; the target table below it says
> which milestone makes each remaining row true. Section 6 is the new rule that a piece is smaller than
> its cell, where its size table lives, and the picture that shows it.*

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
| `docs/owner-decisions.md` | Mọi quyết định của bạn, chép **nguyên văn** (tiếng Việt), kèm điều agent đã làm theo. Quân cờ nhỏ hơn ô nằm ở đây (2026-10-12) |
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
  bằng hình của bạn (không lớn hơn hộp của loại quân, mục 6). Không cần sửa code hay scene. Muốn biết còn những file tạm nào:

```bash
../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/list_placeholders.gd
```

  Danh sách này dựa trên mã băm (sha256) trong `content/_placeholders.json`: một file còn là "tạm"
  khi mã băm của nó vẫn bằng mã đã ghi lúc tạo, nên bạn ghi đè file là nó tự biến khỏi danh sách,
  không phải đánh dấu gì thêm. Hiện có 26 file tạm (4 hình quân cờ: con tốt của bạn, tốt đen, mã, tượng; 4 icon, 1 pickup, 2 nền
  phòng, 1 bộ tile, 4 hình giao diện, 9 tiếng, 1 bản nhạc).
- Quy ước của bạn: mỗi thứ một file (một PNG cho một ô tile, một prop, một icon, một khung hình), không
  gộp sheet hay atlas; công cụ sẽ ghép atlas sau. Chỗ để sẵn: `assets/tiles/<khu>/<tile_id>.png` cho
  từng tile và `content/<loại>/<id>/anim/<clip>/<NN>.png` cho từng khung hình. Công cụ ghép chưa có (nó
  không thuộc M1b), nhưng cây thư mục không chặn nó.

*EN: M1b is done, so the whole tree has moved (`docs/migration-notes.md`). If you have an unsaved or
uncommitted scene using an old path, tell the agent: `tools/move_res.py --rewrite-only <file>` fixes the
paths in your file by script. `content/` is yours and holds no `.gd`. To swap art or audio, overwrite the
file with the same name; `tools/list_placeholders.gd` prints what is still a stand-in by comparing file
hashes recorded in `content/_placeholders.json`, so an overwrite clears the flag by itself (26 stand-ins
today: four of them are the chess pieces, which M2 redrew inside their cells). Your direction of one file per thing is honoured: single tiles go in `assets/tiles/<district>/
<tile_id>.png` and animation frames in `content/<kind>/<id>/anim/<clip>/<NN>.png`; the assembly tools
are later work, and nothing in the tree blocks them.*

## 5. Bảng "Muốn đổi X thì sửa Y" (How do I change X?)

**Hôm nay (sau M2)**, các việc hay làm nằm ở đây, với đường dẫn thật và số file phải sửa:

| Bạn muốn... | Hôm nay sửa ở đâu |
|---|---|
| Chỉnh một enemy (máu, tốc độ, AI, kiểu tấn công) | **1 file**: `content/enemies/<id>/enemy.tres` (máu là `max_health`, tên hiện trên HUD là `display_name`) hoặc một trong các `.tres` nó trỏ tới: `movement.tres`, `decision.tres`, `unarmed_attack.tres`, `visual.tres` nằm cạnh nó, hoặc trong `content/enemies/_shared/{movement,attacks,decisions,visuals}/` khi nhiều pawn dùng chung (sửa file `_shared` là đổi **tất cả** enemy trỏ tới nó: năm pawn đen cùng dùng `_shared/attacks/pawn_diagonal.tres` và `_shared/decisions/pawn_skirmisher.tres`) |
| Thêm một biến thể enemy, ví dụ pawn đen 5 máu (đổi máu, vũ khí, tốc độ) | **1 file**: chép `content/enemies/pawn_recruit/enemy.tres` thành `content/enemies/<id>/enemy.tres` (trong Godot: chuột phải file trong FileSystem → **Duplicate**, đặt tên mới trong hộp thoại, rồi kéo bản sao vào thư mục `<id>`; làm vậy file có uid mới), sửa `id` (trùng tên thư mục, chữ thường và dấu gạch dưới), `display_name`, `max_health`. Nó dùng lại hình và luật của `_shared/`. Muốn chỗ đứng: mở `content/rooms/<id>/room.tscn`, kéo `presentation/views/actors/actor_view_base.tscn` vào, đặt **Definition** = file vừa tạo, kéo lên một ô (**+1 file**, nhưng sửa phòng là đổi `tests/baselines/dump_<phòng>.txt`, nhờ agent). Đã thử thật một lần (enemy `test_pawn`, 5 máu): `tests/content/test_validate_all.gd` tự thấy và kiểm; chi tiết từng bước trong `.claude/commands/new-enemy.md` |
| Thêm một enemy có hình riêng (không code) | **3 file**: `content/enemies/<id>/enemy.tres` + `content/enemies/<id>/visual.tres` (chép `_shared/visuals/pawn_compatibility.tres`, đổi `body_texture` trỏ tới hình mới, `piece_type` là loại quân: pawn, knight, bishop, rook, queen hoặc king) + `content/enemies/<id>/body.png` (hình không lớn hơn hộp của loại quân, mục 6); Godot tự thêm file `body.png.import`. Cộng chỗ đứng trong phòng như hàng trên. Lệnh `/new-enemy` (xem `.claude/commands/new-enemy.md`) làm hết và kiểm. Muốn một hành vi mới (kiểu di chuyển hay tấn công chưa có) thì cần code: xem bảng đích |
| Đổi bố cục phòng hoặc chỗ đứng của enemy | mở `content/rooms/<id>/room.tscn`, kéo node (enemy là node `ActorView` đậu trên một ô) |
| Chỉnh cảm giác con tốt (thời gian bước, thời gian giữ phím để lặp bước, courage, invulnerability, hồi chiêu kỹ năng, có kiếm ngay từ đầu hay không) | **1 file**: `content/player/player.tres` (Inspector: nhóm **Courage** = `max_courage`, `invulnerability_duration`; nhóm **Movement** = `step_duration`, `held_repeat_delay`; nhóm **Combat** = `skill_cooldown_duration`, `starts_with_sword`; `piece_name` là tên con tốt trong chữ trạng thái). Hai đòn đánh của nó là `content/skills/wooden_sword/wooden_sword.tres` và `content/skills/pencil_thrust/pencil_thrust.tres` (1 file mỗi đòn). Tốc độ clip `idle` của nó nằm ở `content/player/visual.tres` (`clip_speed_scales`). Con tốt trong `presentation/views/actors/player.tscn` không còn mang con số chỉnh nào (chỉ trỏ tới `player.tres`); muốn một phòng riêng khác đi thì kéo node `HealthComponent`/`MovementComponent`/... vào con tốt trong phòng đó, node đó thắng file |
| Đổi sprite (con tốt, enemy, icon, pickup) | **1 file**: ghi đè `body.png` / `icon.png` / `pickup.png` trong thư mục của nó: `content/player/body.png` (con tốt trắng của bạn), `content/enemies/<id>/body.png`, `content/skills/<id>/icon.png`, `content/pickups/<id>/icon.png` (xem mục 4). Quân cờ **nhỏ hơn ô** (quyết định của bạn ngày 2026-10-12, mục 6): vẽ hình ở tỉ lệ 1:1, **không lớn hơn hộp của loại quân** trong `content/feel/piece_sizes.tres` (tốt 18×22 px, mã và tượng 20×24, xe 20×24, hậu 22×26, vua 22×28; ô là 32×32). Đáy hình tự đứng trên vạch cách tâm ô 14 px, không cần chỉnh vị trí (nếu cần xê dịch một chút: `anchor_offset` trong `visual.tres`, **+1 file**). Mọi pawn đen dùng chung hình `content/enemies/pawn_recruit/body.png` (qua `_shared/visuals/pawn_compatibility.tres`); mã có `knight_tracker/body.png`; tượng có hình riêng `bishop_zoner/body.png`. Muốn mỗi pawn một hình: cho nó `visual.tres` riêng (hàng "enemy có hình riêng" ở trên). Hình lớn hơn hộp thì bài kiểm `test_validate_all` báo đỏ và nêu tên hình, cỡ hình, cỡ hộp |
| Đổi hình bàn đồ vẽ tay | `assets/map_pieces/` (hình bạn vẽ tay, được track; thay thế bản sinh tự động) |
| Đổi hình nền của phòng T1 hoặc T2 | **Tạm thời:** ghi đè `content/rooms/t1_white_kings_fall/background.png` hoặc `content/rooms/t2_fallen_sword_tile/background.png`. Hai tấm nền vẽ sẵn này là đồ cũ: theo quyết định của bạn (vẽ từng thứ một, `docs/owner-decisions.md`), phòng sẽ được ghép từ từng tile và từng đồ vật riêng, nên đừng vẽ lại cả tấm — hãy vẽ theo danh sách trong `docs/assets/`. |
| Đổi một trang của Book of House Rules | `content/rules/<id>/page.tres` (chữ nằm trong file này tới khi có hệ `.po` ở M4); danh sách trang: `content/rules/rule_book.tres` |
| Đổi độ khó (nhân máu và sát thương toàn cục) | `content/difficulty/standard.tres` |
| Đổi vũ khí nhặt được trên sàn | `content/pickups/<id>/<id>.tres` |
| Đổi đồ thị thế giới (phòng nào nối phòng nào) | `content/world/world.tres` |
| Đổi bộ tile của sàn/tường | `content/tilesets/<bộ>/tileset.tres` và `tilemap.tscn` (đừng sửa tay `tile_map_data`, dùng `tools/paint_*.gd`); atlas ở `assets/tiles/<bộ>/atlas.svg` là đồ cũ; bạn vẽ từng tile riêng (`assets/tiles/<khu>/<tile_id>.png`), công cụ sẽ tự ghép atlas |
| Đổi âm thanh sự kiện / âm thanh chuyển động | ghi đè `assets/sfx/<tên>.wav` (cùng tên là mọi chỗ dùng tự nâng cấp), hoặc `presentation/audio/sfx_manager.tscn` (mục `streams` trong Inspector) / track âm thanh trong clip của actor |
| Đổi phím | `project.godot`, mục `[input]` (hoặc Project Settings → Input Map) |
| Đổi chữ (thoại, thông báo) | còn nằm rải rác: `RoomEncounter` trong `content/rooms/<id>/room.tscn`, `RoomObjective` `.tres` (`tests/fixtures/first_encounter/objective.tres` là ví dụ), `shell/game_root.gd`, `presentation/ui/hud/hud.gd`. Hệ thống `.po` đến ở M4 |
| Xem còn file art/âm thanh tạm nào | `tools/list_placeholders.gd` (mục 4) |

**Bảng đích** (từ `docs/game-base-plan.md` §13.5). Các thư mục `content/enemies`, `rooms`, `rules`,
`skills`, `pickups`, `player`, `difficulty`, `world`, `tilesets` **đã tồn tại** từ M1b; các đường dẫn
khác trong bảng (`content/story`, `audio`, `feel`, `progression`, `ui`, `bosses`, `props`, các file
`skill.tres`, `pickup.tres`, `.po`...) **chưa có** cho tới milestone ghi ở cột cuối.
Cột cuối ("available after Mx") là milestone sau đó hàng ấy mới đúng. Plan không ghi milestone cho
từng hàng, nên cột này là cách đọc của docs lane từ §15 và sẽ được kiểm lại ở mỗi milestone. Khi một
milestone xong, nó phải kiểm đường dẫn thật của các hàng thuộc về mình và xoá chữ "available after Mx" ở
hàng đó. M1b đã kiểm và ghi "available now" bốn hàng: chỉnh một enemy, đổi bố cục phòng, đổi sprite, đổi
art nền phòng. **M2 kiểm thêm và ghi "available now"** các hàng: thêm biến thể enemy (kèm số file đã đếm bằng
cách làm thật một lần), đổi cảm giác con tốt, đổi sprite (theo hộp kích thước), đổi kích thước quân trong ô
(hàng mới), đổi animation hay âm thanh chuyển động.

| Bạn muốn... (You want to...) | Sửa file này (Edit this) | Số file (Files) | Cần code? (Code?) | Trạng thái (Status) |
|---|---|---|---|---|
| Thêm một biến thể enemy (đổi skin, máu, tốc độ hoặc vũ khí) (Add a variant enemy (re-skin, new health, speed or weapon)) | `content/enemies/<id>/enemy.tres` (reusing `_shared` sub-resources), a `visual.tres` that names its `piece_type` and `body.png`; in a room, instance `actor_view_base.tscn` and set `definition` (no scene of your own); the `ENEMY_<ID>_NAME` row in `story/text/<locale>/story.po`. | 4 | no | **available now** for everything but the name row (dòng tên trong `.po`: M4). Counted by doing it (M2): 1 file when it reuses `_shared`, 3 with a picture of its own, plus the room edit that places it; `/new-enemy` walks through it |
| Thêm enemy có hành vi mới (Add an enemy with new behaviour) | `enemy.tres` + one `EntityComponent` or `AttackBase` script + one system file + one line in `ecs/schedule/<phase>.gd`; plus `events.gd` if it emits a new event and `ViewSyncSystem` if its visuals are new. | 4 new, up to 3 existing edited | yes | available after M3a (kiểu tấn công mới: M8a) |
| Chỉnh (retune) một enemy hoặc boss (Retune an enemy or boss) | its `.tres` | 1 | no | **available now** for an enemy (`content/enemies/<id>/enemy.tres` and the `.tres` it points at, 1 file), M8b (boss) |
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
| Đổi sprite (Swap a sprite) | overwrite `body.png`, drawn at scale 1 and no larger than the box of its kind in `content/feel/piece_sizes.tres` (the game stands its bottom edge on the kind's base line; `VisualDefinition.anchor_offset` nudges it); the placeholder flag clears by hash | 1-2 | no | **available now** for `content/player/body.png` (white pawn) and the enemies' (`pawn_recruit` is every black pawn, `knight_tracker`, `bishop_zoner`); `ContentDb.validate_cross_refs()` fails a picture larger than its box; `assets/_generated/previews/pieces_in_cells.png` (`tools/render_actor_preview.gd`) shows the hero, a black pawn, the knight and the bishop in their cells, and section 6 reads it |
| Đổi kích thước quân trong ô (Change how big a kind of piece is inside its cell) | `content/feel/piece_sizes.tres`: one row per kind with the largest picture (`body_box`), the base line (`base_offset_y`, px below the cell's centre) and a footprint in cells. `validate()` keeps every box 2 px from the cell's edges and the heights as in a real chess set (pawn < knight, bishop, rook < queen < king) | 1 | no | **available now**; the placeholder pieces come from `tools/generate_chess_sprites.gd`, which reads the same file and refuses a piece that does not fit |
| Đổi art của một phòng (Swap a room's art) | overwrite its single tile and prop PNGs (one file per thing, see `docs/assets/`); a tool assembles the room. The painted `background.png` of T1/T2 is a legacy placeholder, not something to redraw | 1 per thing | no | tiles and props: after the assembly tool lands; T1/T2 backgrounds: overwrite now if wanted |
| Đổi portrait, skin UI hoặc font (Swap a portrait, UI skin or font) | overwrite the file in `content/story/characters/`, `content/ui/theme/`, `assets/fonts/` | 1 | no | available after M4 (skin UI, font), M6 (portrait) |
| Thêm nhạc hoặc đổi bài nhạc đang phát (Add music or change which track plays) | drop the file in `assets/music/` + a row in `music_cues.tres` | 2 | no | available after M6 |
| Thêm hoặc đổi âm thanh sự kiện (pickup, jingle, UI) (Add or swap an event sound (pickup, jingle, UI)) | drop the file + a row in `sound_bank.tres` | 2 | no | available after M6 |
| Đổi âm thanh chuyển động hoặc sửa một animation clip (Swap a motion sound or edit an animation clip) | an **editor task** in `presentation/views/actors/actor_view_base.tscn` (changes every actor that inherits it) or in a bespoke inherited view; how fast a clip plays for one kind of piece is `clip_speed_scales` in its `visual.tres`, no scene edit. Keep hops and shakes within the 2 px margin: `test_pieces_inside_cell` samples every clip | 1 scene | no | **available now** |
| Đổi bố cục HUD (Change the HUD layout) | the widget scene in `presentation/ui/hud/` | 1 | no | available after M4 |
| Chỉnh độ khó hoặc assist (Tune difficulty or assists) | `content/difficulty/<profile>.tres` (global health and damage multipliers live here); for one enemy, its `enemy.tres` | 1 | no | available after M8a |
| Chỉnh cảm giác chơi (rung, nháy, hit-stop, màu telegraph, chord window) (Tune game feel (shake, flash, hit-stop, telegraph colours, chord window)) | `content/feel/feel_profile.tres` | 1 | no | available after M7b |
| Đổi cảm giác của con tốt (thời gian mỗi bước, courage, invulnerability) (Change how the pawn feels (step time, courage, invulnerability)) | `content/player/player.tres` (`PlayerDefinition`: Courage, invulnerability, step time, hold-repeat delay, skill cooldown, sword unlocked or not; the player scene holds none of these any more, and a node on a room's instance still beats the file) | 1 | no | **available now** (M2; `tests/content/test_player_definition.gd` proves every field reaches the hero) |
| Đổi luật kinh tế (Believe, shard, stagger, ngưỡng assist) (Change economy rules (Believe, shards, stagger, assist thresholds)) | `content/progression/rules.tres` | 1 | no | available after M7c |
| Đổi phím mặc định (Change input defaults) | the `[input]` section of `project.godot` | 1 | no | available after M4 |
| Đổi chữ ở màn title hoặc credits (Change title text or credits) | `credits.tres` + `.po` rows | 2 | no | available after M4 |
| Thêm cơ chế sàn mới (gai, công tắc) (Add a new floor mechanic (spikes, switch)) | marker + component + system + one schedule line (+ an event) | 4-5 | yes | available after M3a |

*EN: The first table lists today's real locations (all of these paths exist). The second is the target
Owner Change Table from plan §13.5; each row says which milestone makes it true, and the rows marked
"available now" were checked against the tree at the end of M1b and M2 (M2 counted the files of the
enemy rows by adding a test enemy for real, then deleting it).*

## 6. Quân cờ nhỏ hơn ô (A piece is smaller than its cell)

**Quyết định của bạn, 2026-10-12** (nguyên văn trong `docs/owner-decisions.md`): "quân cờ phải nhỏ hơn ô
chứ nhỉ? không vừa cũng chẳng to hơn và dĩ nhiên là phải sửa scene". M2 đã làm đúng như vậy.

**Luật.** Mỗi quân cờ được vẽ **bên trong ô 32×32 của nó**, chừa lề ít nhất **2 px** ở mọi phía: không bao
giờ vừa khít ô, không bao giờ cao hơn ô (không còn chồng lên hàng phía trên). Độ cao theo một bộ cờ thật:
tốt thấp nhất, vua cao nhất. Luật này thay quy ước cũ của phase 66 trong `task_plan.md` (quân cao 1,5 ô,
nửa trên đè lên hàng trên); phase 66 giờ được ghi là đã bị thay thế. Mọi thứ một quân vẽ ra (thân, chấm
máu, mũi tên hướng nhìn, vũ khí cầm tay, vòng cảnh báo khi sắp đánh) đều nằm trong phạm vi 14 px quanh tâm
ô của nó, nên không lấn sang ô bên cạnh.

**Bảng kích thước nằm ở đâu: `content/feel/piece_sizes.tres`** (một file, mở trong Inspector). Mỗi dòng của
`rows` là một loại quân:

- `piece_type`: tên loại (`pawn`, `knight`, `bishop`, `rook`, `queen`, `king`; boss sẽ là một dòng riêng);
- `body_box`: hình **lớn nhất** bạn được vẽ cho loại đó, rộng × cao tính bằng px (cả phần trong suốt của
  file PNG cũng tính);
- `base_offset_y`: đáy của hình đứng cách **tâm ô** bao nhiêu px về phía dưới (hiện là 14 cho mọi loại, nghĩa
  là đáy cách mép dưới ô đúng 2 px);
- `footprint_cells`: quân chiếm mấy ô (hiện là 1×1; một boss đứng trên nhiều ô sẽ có footprint lớn hơn và hộp
  lớn hơn theo).

| Loại quân | Hộp (rộng × cao, px) | Lề phía trên | Lề hai bên | Lề phía dưới |
|---|---|---|---|---|
| tốt (pawn) | 18 × 22 | 8 | 7 | 2 |
| mã (knight), tượng (bishop), xe (rook) | 20 × 24 | 6 | 6 | 2 |
| hậu (queen) | 22 × 26 | 4 | 5 | 2 |
| vua (king) | 22 × 28 | 2 | 5 | 2 |

Bảng tự giữ luật: hàm `validate()` của nó báo lỗi nếu một hộp để lề dưới 2 px, nếu một loại bị liệt kê hai
lần, hoặc nếu thứ tự độ cao sai (tốt < mã, tượng, xe < hậu < vua).

**Vẽ thế nào.** Vẽ ở tỉ lệ 1:1 (một pixel của file PNG là một pixel của game, không phóng to hay thu nhỏ), PNG không lớn hơn
hộp của loại quân, chân quân sát đáy PNG. Game tự đặt đáy PNG lên vạch cách tâm ô 14 px và căn giữa theo chiều
ngang (nên chọn bề rộng chẵn); bạn không phải chỉnh vị trí trong scene. Muốn xê dịch một chút cho riêng một
quân: `anchor_offset` trong `visual.tres` của nó. Thay hình = ghi đè `content/player/body.png` hoặc
`content/enemies/<id>/body.png` (hàng "Đổi sprite" ở mục 5). Nếu hình lớn hơn hộp, bài kiểm tra báo đỏ và nói rõ
hình nào, cỡ hình, cỡ hộp.

**Xem kết quả mà không cần mở editor: `assets/_generated/previews/pieces_in_cells.png`.** Đó là một ảnh 1336×568
(phóng 4 lần, số nguyên, không làm mờ): bốn hàng, chín cột. Hàng là HERO (con tốt trắng của bạn), BLACK PAWN,
KNIGHT, BISHOP. Cột là AT REST (đứng yên) nhìn xuống, phải, lên, trái; ARMED (đang cầm vũ khí, hoặc con tốt
đang đâm bút chì) nhìn bốn hướng; ALERT (đang báo trước đòn đánh, vòng cảnh báo hiện ra). Mỗi ô vuông là một ô
game 32×32: đường lưới xám là mép ô, **khung đỏ mờ là vạch lề 2 px**; quân phải nằm gọn trong khung đỏ. Ô ALERT
của hero để trống vì con tốt của bạn không bao giờ báo đòn. Thư mục `assets/_generated/` không nằm trong git, nên
ảnh có sẵn sau `tools/bootstrap_worktree.sh`; vẽ lại bất cứ lúc nào (không cần cửa sổ, vài giây):

```bash
../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/render_actor_preview.gd
```

Ảnh này vẽ đúng chỗ game vẽ: công cụ chạy chính `ViewSyncSystem` thật lên chính cảnh actor thật rồi
đọc lại điểm ảnh, chứ không phải một bản vẽ tay của bố cục. Cổng kiểm thật là
`tests/architecture/test_pieces_inside_cell.gd`: nó đặt con tốt, ba cảnh enemy mỏng và **cả bảy enemy** của `content/enemies/` lên cảnh actor, cho nhìn bốn
hướng, cầm từng loại vũ khí, đang báo đòn, và lấy mẫu mọi clip animation (khoảng 600 tư thế); mọi điểm ảnh phải
cách mép ô ít nhất 2 px ở trạng thái đứng yên (hẹp nhất đo được đúng 2,0 px). Ảnh chỉ có bốn hàng: một enemy
mới chỉ có `definition` (không có cảnh riêng) không có hàng riêng trong ảnh, nhưng bài kiểm vẫn đo nó và nêu tên
nó nếu lấn ra ngoài.

**Đổi cỡ.** Muốn một loại quân to hơn hay nhỏ hơn: sửa `body_box` của loại đó trong `piece_sizes.tres` (1 file,
không cần code), rồi vẽ lại hình cho vừa hộp mới. Hộp lớn hơn mà không còn lề 2 px thì `validate()` từ chối. Hình
tạm do `tools/generate_chess_sprites.gd` sinh đọc chính file này và không chịu vẽ một quân không vừa hộp.

**Còn thiếu, nói thẳng.**

- Xe, hậu, vua và boss **chưa có hình**; hiện chúng chỉ là dòng trong bảng (boss: chưa có actor nào).
- Bốn hình đang dùng là hình tạm (`tools/list_placeholders.gd` liệt kê): con tốt trắng, tốt đen, mã, tượng. Bộ
  cờ sinh tự động bạn đã duyệt được vẽ lại cho vừa hộp. **Con mã** phải vẽ lại trên 15 hàng (cùng hình dáng,
  dò lại từ cùng ký tự font) vì không cách nào thu nhỏ nguyên số lần mà vẫn vừa hộp 20×24 và vẫn cao hơn tốt;
  đó là một sửa đổi trên hình bạn đã duyệt, được ghi ở `THIRD_PARTY_NOTICES.md`; bạn có thể vẽ lại hoàn toàn.
  **Tốt đen và tượng** là hình tạm mới (tốt đen là hình con tốt, đổi sang màu đen bóng; tượng là hình mới) đang
  chờ bạn duyệt hoặc vẽ lại.
- Vũ khí cầm tay được vẽ nhỏ (0,16 lần) để vừa ô 32 px; tầm đánh được thể hiện bằng lớp phủ trên bàn cờ, không phải
  bằng độ dài của hình vũ khí.

*EN: A piece is smaller than its 32 x 32 cell (owner, 2026-10-12): at least a 2 px margin on every side, never
cell-sized, never taller, heights as in a real chess set. The rule lives in the data: `content/feel/piece_sizes.tres`
has one row per kind with the largest picture (`body_box`, whole PNG), the base line (`base_offset_y`, 14 px below the
cell's centre, so the bottom margin is 2 px) and a footprint in cells; `validate()` holds the margin and the height
order. Draw at scale 1, no larger than the box, feet at the bottom of the PNG: the game stands the bottom edge on the
base line and centres the picture sideways. To see the result without the editor open
`assets/_generated/previews/pieces_in_cells.png` (made by `tools/bootstrap_worktree.sh`, or run
`tools/render_actor_preview.gd`): four rows (hero, black pawn, knight, bishop) by nine cells (at rest facing four
ways, armed facing four ways, alert), 4x, with the cell edge as a grey line and the 2 px margin as a faint red frame.
`tests/architecture/test_pieces_inside_cell.gd` is the real gate and measures the hero, the three thin enemy scenes and all seven enemies of `content/enemies/`, in every
facing and about 600 clip poses; an enemy that is only a `definition` is measured but is not a row of the picture.
Not yet: rook, queen, king and boss pictures exist only as table rows; the four bodies are placeholders (the knight was
retraced on 15 rows to fit its box, an edit to an approved shape recorded in `THIRD_PARTY_NOTICES.md`).*

## 7. Từ điển nhỏ (Glossary)

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
| `ContentDb` | sổ đăng ký nội dung của game: tra mọi thứ trong `content/` theo id (tên thư mục), và có hai hàm kiểm tra (`validate()`, `validate_cross_refs()`) mà các bài test chạy để chắc mọi file hợp lệ và mọi tham chiếu trỏ tới một id có thật. Bạn không phải gọi nó |
| `actor_view_base.tscn` | **một** cảnh duy nhất vẽ mọi con tốt/enemy (`presentation/views/actors/`); enemy mới chỉ cần kéo cảnh này vào phòng rồi đặt `definition`. `player.tscn`, `black_pawn.tscn`, `knight_enemy.tscn`, `bishop_enemy.tscn` là cảnh mỏng kế thừa nó |
| `PlayerDefinition` | file `content/player/player.tres`: mọi con số của con tốt (Courage, thời gian bước, hồi chiêu...) |
| base line / `body_box` | vạch đáy của quân (14 px dưới tâm ô) và hộp lớn nhất của hình, trong `content/feel/piece_sizes.tres` (mục 6) |
