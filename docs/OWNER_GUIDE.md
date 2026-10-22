# Hướng dẫn cho chủ dự án (Owner Guide)

> **Trạng thái (Status): CẬP NHẬT Ở M5 bước 3 (2026-10-23): mục 9 là cổng OG1, chơi từ title tới credits qua các phòng stub.** (Trước đó: M4 bước 4, 2026-10-19.) Tạo ở M1a, M1b điền đường dẫn thật vào mục 5,
> M2 thêm mục 6 (quân cờ nhỏ hơn ô) và cập nhật các hàng về con tốt, enemy, sprite, M3b thêm mục 7
> (lưu game, checkpoint, chết và hồi sinh). M4 bước 1 thêm màn title (New Game, Continue), credits và dấu tick
> lưu game, và đổi cảnh chính thành `shell/app_root.tscn` (mục 1, 5, 7). M4 bước 2 thêm menu pause (`Esc`), đổi `R`
> thành phím gọi đứa trẻ và đưa việc chơi lại phòng vào menu pause. M4 bước 3 thêm mục 8: mọi chữ trong game nằm
> trong file `.po` (sửa một dòng rồi thấy ngay), chỗ đặt font và glyph phím của bạn, màn Settings và bảng Controls. **M4 bước 4 làm HUD thành
> các mảnh riêng (mỗi mảnh một scene), không còn đè lên hàng ô nào của bàn, thêm bảng phím có cột tay cầm, danh sách "thử gì" của M4 và cách
> đọc HUD (mục 1), và camera luôn đặt hình đúng trên một pixel.** Các milestone M4-M14 của
> `docs/game-base-plan.md` sẽ điền tiếp phần còn lại của bảng đích; M14 viết bản đầy đủ.
>
> **Ngôn ngữ:** tiếng Việt đứng trước, thuật ngữ tiếng Anh giữ nguyên. Nếu hai bản khác nhau thì
> **bản tiếng Anh là bản chuẩn** (plan D19). Phần tiếng Việt do agent viết, chưa có người bản ngữ
> rà lại; bạn cứ sửa thẳng vào file nếu thấy sai.
>
> *EN: Updated at the end of M2. Vietnamese first, English authoritative where they differ. Section 5
> lists what you can change today at its real path, with file counts; the target table below it says
> which milestone makes each remaining row true. Section 6 is the new rule that a piece is smaller than
> its cell, where its size table lives, and the picture that shows it. M3b added section 7: where the save
> file lives, how to start clean, what a death keeps and resets, and what to try. M4 step 2 moved restarting a
> room to the pause menu (R is Call child, D-18). M4 step 3 added section 8: every word of the game is a row of a
> `.po` file (how to edit one and see it), where the owner's font files and key-glyph files go, what each setting of the
> Settings screen does, and the Controls panel. M4 step 4 made the HUD a set of widgets (one scene each) that stay in two strips and
never cover a row of the board, gave section 1 the controls table with the gamepad column, what to try in M4 and how to read the HUD, and
made the camera start its picture on a whole pixel.*

## 1. Chơi bản build hiện tại (How to play the current build)

1. Cần Godot 4.6. Mở `project.godot` trong Godot rồi bấm **F5** (cảnh chính là `shell/app_root.tscn`: nó mở màn
   title; cảnh phòng chơi `shell/game_root.tscn` vẫn chạy riêng được bằng **F6** khi bạn đang mở nó).
   Hoặc, trong terminal tại thư mục dự án (Godot nằm ở thư mục cha của dự án):
   `../Godot.app/Contents/MacOS/Godot --path .`
2. **Clone mới:** chạy một lệnh `tools/bootstrap_worktree.sh` (khoảng 50 giây). Nó import lần đầu, chạy
   bốn generator sinh art tạm vào `assets/_generated/` (thư mục này không nằm trong git) và import lần
   hai. Game không còn phụ thuộc vào thư mục đó: các hình tạm game dùng là file được track trong
   `content/`.
3. Màn **title** hiện ra: **New Game** (bắt đầu sạch ở phòng T1; nếu đã có save thì hỏi xác nhận rồi ghi lần chơi mới
   đè lên, save cũ còn lại làm `.bak`), **Continue** (chỉ hiện khi có save đọc được; mở phòng và ô vào của lần lưu cuối,
   kèm một dòng "thẻ save": tên phòng, thời gian chơi, ngày lưu), **Settings** (mục 8), **Credits** và Quit.
   Góc dưới bên phải là số phiên bản. Sau khi xem hết kết thúc, một ô của bàn cờ trên title để trống. Vào game là đi
   theo tuyến Stage 1: T1 → T2 → T3 → T4 → B1 → H1 (greybox, chưa chỉnh art); từ H1, năm cửa dẫn sang năm quận (Toybox, Bookshelf, Block Tower, Dollhouse, Under-Bed, mỗi cửa chờ boss của quận trước) rồi tới bàn học và credits: bộ khung đầy đủ nhưng toàn **phòng stub**, cách chơi và điều cần xem ở **mục 9 (cổng OG1)**. Muốn chơi lại từ đầu: chọn **New Game**
   (hoặc xoá file save `saves/slot_0.cfg` và `saves/slot_0.cfg.bak` trong thư mục user data của
   game; trong Godot: menu **Project → Open User Data Folder**; trên macOS là
   `~/Library/Application Support/Godot/app_userdata/The Unbound Pawn/`). Chi tiết ở mục 7.
4. Phím (bảng này giống bảng **Controls** trong game, bảng đó đọc thẳng từ InputMap; nếu hai nơi khác nhau thì `project.godot` đúng):

| Việc | Bàn phím | Tay cầm | Hôm nay |
|---|---|---|---|
| đi một ô | `WASD` hoặc mũi tên | cần trái (hướng trội nhất) hoặc d-pad | có |
| xoay tại chỗ, không đi | `Shift` + hướng (giữ, hoặc bật tắt ở Settings) | `LB` | có |
| Wooden Sword | `Space` hoặc `K` | `A` | có (sau khi nhặt kiếm ở T2) |
| Pencil Thrust (ô kỹ năng 1) | `Q` | `X` | có |
| ô kỹ năng 2 (Rule Step) | `F` | `B` | **chưa** (M7a) |
| Guard (đỡ) | `G` | `LT` | **chưa** (M8a) |
| Focus | `Ctrl` trái | `RT` | **chưa** (M8a) |
| **gọi đứa trẻ** (call child, D-18) | `R` | `RB` | **chưa làm gì thấy được**: đứa trẻ giúp từ M10 |
| chọn lệnh gọi kế tiếp | `Tab` | `R3` | chưa (M7a) |
| tương tác (giải cứu, vật trong truyện) | `E` | `Y` | chưa (M6) |
| Book of House Rules | `B` | `L3` | có |
| **menu pause** | `Esc` | `Start` | có |
| debug view, toàn màn hình | `F3`, `F11` | (không có) | có |

   Menu pause (`Esc` hoặc `Start`) gồm: Resume, Book of House Rules, **Settings**, **Controls** (bảng phím), **Assist options** (các tuỳ chọn làm game dễ hơn,
   luôn có từ lần chơi đầu), **Restart Room** (chơi lại phòng như khi chết; hỏi xác nhận; **đây là cách duy nhất**, `R` không còn làm việc này), Quit to Title (hỏi
   xác nhận và nêu tên checkpoint gần nhất). Game cũng tự pause khi cửa sổ mất focus. Ô kỹ năng 3 và 4 (`C`, `V`) đã khai báo nhưng chưa dùng.
   Bạn chuyển giữa bàn phím và tay cầm lúc nào cũng được: hình phím trên HUD và trong bảng Controls đổi theo thiết bị bạn vừa chạm.
5. Đã có (M4 bước 1-4): màn title, credits (đọc `content/story/credits.tres`), dấu tick nhỏ ở góc trên bên phải mỗi khi game
   tự lưu, thông báo một dòng khi save bị hỏng hoặc của bản game mới hơn, menu pause (`Esc`/`Start`; mọi phím có thêm nút tay
   cầm), **màn Settings** (từ title và từ menu pause), **bảng Controls** (từ menu pause và từ Settings), **mọi chữ nằm trong
   file `.po`**, **chỗ đặt font** và **chỗ đặt glyph phím/tay cầm của bạn** (mục 8), và, ở bước 4, **HUD mới** và **camera đặt hình đúng pixel**.
   `R` là phím gọi đứa trẻ (chưa làm gì thấy được; bảng Controls ghi "(coming later)" bên cạnh).

6. **Đọc HUD (bước 4 của M4).** HUD nằm trong **hai dải**, và không dải nào đè lên hàng ô nào của bàn cờ (bàn lớn nhất, 18×9 ô, chiếm từ y 36 đến y 324 của khung
   640×360; trước đây bảng trên cùng lấn vào hàng 0 khoảng 10 px):

   ```text
   dải trên (y 0-32)
     COURAGE (o)(o)(o)   [chỗ để dành: Believe]   [ô kỹ năng: THRUST READY]   [chỗ để dành: thanh boss]   ENEMIES 3/4   RANK ||||
   dải dưới (y 326-360)
     dòng trạng thái:  They broke the rules first. Armed pawns reach farther than chess allows.
     gợi ý phím:       [W][A][S][D] MOVE   [Space] SWORD   [Q] THRUST   [Esc] PAUSE      (tay cầm: [A] SWORD, [X] THRUST, [Start] PAUSE...)
   ```

   - **COURAGE:** mỗi chấm là một điểm Courage còn lại, hình chiếc đế quân cờ màu ngà; chấm rỗng là điểm đã mất. Tối đa 5 chấm (Extra Courage của Assists sẽ làm tăng số chấm khi M8c xong; hôm nay nó chưa làm gì, màn Settings ghi "(coming later)").
   - **Ô kỹ năng:** ô vuông 24×24 đầy dần từ đáy khi kỹ năng hồi lại; chữ bên cạnh nói `FIND SWORD` (chưa nhặt kiếm), `THRUST READY` hay `THRUST 0.5`.
     Phím bấm không còn viết cứng trong chữ này: dòng gợi ý phím ở dải dưới lấy phím từ InputMap (đổi phím trong `project.godot` là HUD đổi theo).
   - **ENEMIES 3/4:** còn bao nhiêu địch trong phòng. **RANK:** nhãn Rank bằng các vạch kiểm đếm màu xanh (nhãn câu chuyện, không phải cấp độ); **ẩn cho tới M7c**.
   - **Hai chỗ để dành** (Believe của đứa trẻ, thanh máu boss) có sẵn trong dải trên nhưng ẩn và chưa vẽ gì: M10 và M8b điền vào mà không phải dời chỗ nào.
   - **Số liệu cho người làm game** (ô con tốt đang đứng, hướng nhìn, địch nào đánh tiếp) **không** hiện cho người chơi: bấm **F3** để chúng thế chỗ dòng gợi ý phím (và bật lớp debug trên bàn cờ);
     bấm F3 lần nữa để tắt. Game luôn mở với F3 tắt.
   - **Muốn đổi vị trí hay kích thước một mảnh HUD:** mở scene của nó (`presentation/ui/hud/widgets/<tên>.tscn`) hoặc vị trí của nó trong `presentation/ui/hud/hud.tscn`
     (các ô **Offset** trong Inspector). Bài test `test_hud_safe_zone` đỏ và nêu tên mảnh nếu bạn kéo nó ra khỏi hai dải hoặc đè lên một hàng ô của bất kỳ phòng nào.
   - **Muốn thay hình cho HUD** (chấm Courage, khung ô kỹ năng, dải nền...): danh sách asset có sẵn các nhóm `hud_*` (`docs/assets/spec/ui_story.json`). Hôm nay các mảnh là
     hình vẽ bằng node đơn giản; hình của bạn sẽ được gắn vào scene của từng mảnh (chấm Courage đã có sẵn hai ô **Full Style** và **Empty Style** trong Inspector).
   - **Camera:** hình luôn bắt đầu đúng trên một pixel của thế giới (không nằm giữa hai pixel), kể cả khi rung màn hình; độ rung vẫn theo thanh **Screen shake** trong Settings.
     (Cửa sổ lớn gấp đôi 640×360 là vừa đẹp nhất; cửa sổ không phải bội số nguyên vẫn bị vỡ pixel nhẹ, đó là chuyện của cách co giãn cửa sổ, một quyết định để dành cho bạn:
     `Project Settings → Display → Window → Stretch → Scale Mode = integer` sẽ chỉ phóng theo số nguyên và để viền đen.)

7. **Thử gì ở M4 (Owner can try).** Mỗi bước dưới đây là một việc bạn tự làm được, không cần sửa code:
   1. Mở game (F5): màn **title** hiện ra, nhạc không dứt khi bạn đi qua các màn. Bấm **New Game** (hoặc **Continue** nếu đã có save).
   2. Đi tới phòng T3 (kiếm nằm ở T2) và **bấm `Esc` giữa lúc con tốt đen đang tiến lại**: mọi thứ **đứng yên** (kẻ địch cũng đứng), nhạc vẫn chạy. **Resume** để chơi tiếp. Thử đổi cửa sổ sang
      ứng dụng khác: game tự pause.
   3. **Chơi T1 → T3 bằng tay cầm.** Cắm tay cầm rồi bấm một nút: dòng gợi ý phím ở đáy màn hình đổi từ `[Space]` sang `[A]`, từ `[Q]` sang `[X]`, từ `[Esc]` sang `[Start]` (chữ thay cho hình tới khi
      bạn chép file Kenney vào `assets/ui/glyphs/`, mục 8). Mở menu bằng `Start` và đi bằng cần trái. Bấm một phím bàn phím: gợi ý đổi lại ngay.
   4. **Chơi lại phòng:** `Esc` → **Restart Room** → xác nhận. (Bấm `R` không còn chơi lại phòng: nó là phím gọi đứa trẻ.)
   5. **Sửa một dòng chữ rồi thấy nó:** mở `content/story/text/en/ui.po`, đổi dòng `msgstr` của `UI_HUD_PROMPT_SWORD` từ `"SWORD"` thành `"STRIKE"`, lưu, chạy lại game: dải dưới đổi theo
      (mục 8 nói chi tiết).
   6. Mở **Settings** (từ title hoặc `Esc`): kéo Screen shake về 0, bật Reduce flashing, đổi Language sang Pseudo-language (chỉ có khi chạy bằng editor; Tiếng Việt chỉ hiện trong danh sách khi `vi/*.po` đã có dòng chữ): chữ trên HUD đổi ngay, và mọi thứ vẫn nằm trong hộp của nó. Thử đi hết màn Settings chỉ bằng phím mũi tên (hoặc cần trái): Lên/Xuống đi qua từng dòng theo thứ tự, tới ba nút Controls / Restore defaults / Back; Trái/Phải đi giữa ba nút; chọn một ngôn ngữ xong vẫn đi tiếp được.
   7. Bấm **F3** giữa trận để xem số liệu debug, rồi F3 để tắt.

*EN: Open `project.godot` in Godot 4.6 and press F5 (main scene `shell/app_root.tscn`, which opens the title;
the room scene `shell/game_root.tscn` still runs alone with F6), or run the binary with `--path .`. On a fresh
clone run `tools/bootstrap_worktree.sh` first. The title offers New Game (asks first when a save exists, then
writes the clean run over the slot; the old save stays as the `.bak`), Continue (only when a readable save exists:
the room and entry of the last save, with a card that names the room, the time played and the day), Settings, Credits
and Quit, with the version in the corner. To restart the run choose New Game, or delete
`saves/slot_0.cfg` (and `slot_0.cfg.bak`) in the user data folder. M4 step 1 added the title, the credits, the
autosave tick and the notice for a damaged or newer save. M4 step 2 added the pause menu (Esc or Start: Resume, Book,
Restart Room with a confirm, Quit to Title with a confirm that names the last checkpoint; the game also pauses when the
window loses focus), gamepad events on every action, and R as Call child (it does nothing visible until M10; restarting
a room is the menu's job). M4 step 3 added the Settings screen (from the title and from the pause menu; the pause menu also has Controls and
Assist options), the Controls panel (read from the InputMap), the key and gamepad glyphs (the owner's files, with words in
their place), and section 8: all text is in `.po` files and the font files go in `assets/fonts/`. M4 step 4 made the HUD a set of widgets (one scene
each, `presentation/ui/hud/widgets/`) that live in two strips, the top one (y 0 to 32: Courage pips, the reserved Believe slot, the skill slot, the
reserved boss bar, the enemy count, the Rank badge) and the bottom one (y 326 to 360: the status line and the control hints, built from the InputMap
for the device in use), so none covers a row of the board (`test_hud_safe_zone`); the pawn's cell and who strikes next are debug fields behind F3, off
at the start. The controls table above has the gamepad column. The camera starts its picture on a whole pixel (`test_camera_snap`), shake included, and a piece sliding between cells is drawn on whole pixels too (`test_piece_slide_snap`).
"What to try in M4": launch and see the title, pause in the middle of a fight (the enemies freeze), play T1 to T3 on a gamepad (the hints change to
[A], [X], [Start]), restart a room from the pause menu, edit a line of `ui.po` and see it, try the settings and F3.*

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
| Đặt một phòng là checkpoint (hub, phòng boss: vào cửa là hồi đầy Courage, game ghi lại và lưu) | **1 file**, trong Godot: mở `content/rooms/<id>/room.tscn`, chọn node gốc, trong Inspector bật **Checkpoint On Entry**. Hiện chỉ `h1_chess_rug_hub` và `b1_black_pawn_captain` bật; không có tên phòng nào nằm trong code |
| Biến một vật nhặt trên sàn thành phần thưởng giữ mãi (được nhặt một lần cho cả lần chơi, không bao giờ quay lại; chưa phòng nào dùng, dành cho mảnh Courage và trang Rule ở các milestone sau) | **1 file**: trong `content/rooms/<id>/room.tscn`, chọn node `PickupSpawnPoint` của nó và bật **Persistent**. Để tắt, đó là vũ khí rơi trên sàn của phòng: phòng bắt đầu lại là nó về chỗ cũ (mục 7) |
| Đổi hình bàn đồ vẽ tay | `assets/map_pieces/` (hình bạn vẽ tay, được track; thay thế bản sinh tự động) |
| Đổi hình nền của phòng T1 hoặc T2 | **Tạm thời:** ghi đè `content/rooms/t1_white_kings_fall/background.png` hoặc `content/rooms/t2_fallen_sword_tile/background.png`. Hai tấm nền vẽ sẵn này là đồ cũ: theo quyết định của bạn (vẽ từng thứ một, `docs/owner-decisions.md`), phòng sẽ được ghép từ từng tile và từng đồ vật riêng, nên đừng vẽ lại cả tấm — hãy vẽ theo danh sách trong `docs/assets/`. |
| Đổi một trang của Book of House Rules | **chữ của trang:** `content/story/text/en/story.po` (các dòng `PAGE_<ID>_TITLE`, `_RULE`, `_AMENDMENT`, `_FLAVOR`; mục 8). **Quân nào mở trang:** `content/rules/<id>/page.tres` (ô `piece_id`; các ô chữ trong đó chỉ chứa mã `PAGE_...`); danh sách trang: `content/rules/rule_book.tres` |
| Đổi độ khó (nhân máu và sát thương toàn cục) | `content/difficulty/standard.tres` |
| Đổi vũ khí nhặt được trên sàn | `content/pickups/<id>/<id>.tres` |
| Dựng một phòng mới từ một bản vẽ ký tự (Build a new room from a layout) | **1 file bản vẽ** `tools/layouts/<id>.txt` (id là tên file; mỗi ô một ký tự: `.` sàn, `#` tường, `o` hố, `+` khối nhảy qua được, `=` phấn, `~` sàn hỏng, chữ hoa là cửa, điểm vào, enemy, vật nhặt... khai báo ở mục `[objects]`; mục `[room]` còn có năm khoá ngân sách `objective`, `threat`, `shapes`, `intro`, `intensity`; `tools/build_room.gd -- --legend` in đủ bảng; cả quy trình ở mục 9), rồi chạy `tools/build_room.gd -- --room=<id>` (xem `tools/README.md`). Tool viết `content/rooms/<id>/room.tscn` bằng chữ, tô từng tile từ bộ `greybox`, thêm các dòng chữ tiếng Anh vào `rooms.po`, và **không bao giờ ghi đè** một scene đã có (bạn sửa scene trong Godot thì scene là bản đúng). Muốn xem cả thế giới: `tools/print_world_map.gd` |
| Đổi đồ thị thế giới (phòng nào nối phòng nào) | `content/world/world.tres` |
| Đổi bộ tile của sàn/tường | `content/tilesets/<bộ>/tileset.tres` và `tilemap.tscn` (đừng sửa tay `tile_map_data`, dùng `tools/paint_*.gd`); atlas ở `assets/tiles/<bộ>/atlas.svg` là đồ cũ; bạn vẽ từng tile riêng (`assets/tiles/<khu>/<tile_id>.png`), công cụ sẽ tự ghép atlas |
| Đánh dấu một tile là hố, khối nhảy qua được, phấn hay sàn bị hỏng (Mark a tile as a gap, a leapable block, chalk or corrupted floor) | **1 file**, trong Godot: mở `content/tilesets/<bộ>/tileset.tres`, ở TileSet editor chọn tile, trong Inspector mục **Custom Data** điền ô **kind**: `gap` (hố: không đi vào được, đường đạn và cú nhảy bay qua), `leapable_block` (khối: không đi qua được, chắn đường đạn, nhảy qua được), `chalk` (phấn: đi được), `corruption` (sàn hỏng: đi được); `wall` và `floor` cũng dùng được. Để trống thì tile là tường khi `solid` bật, còn không là sàn, nên mọi tile cũ vẫn như cũ. Hiện chưa tile nào điền `kind`: hình cho hố, khối, phấn và sàn hỏng thuộc về các milestone dùng chúng (M10, M13). Muốn tô chúng vào bản đồ thì công cụ `tools/paint_*.gd` nêu loại ô qua `tools/cell_kind_painter.gd`; đừng sửa tay `tile_map_data` |
| Đổi âm thanh sự kiện / âm thanh chuyển động | ghi đè `assets/sfx/<tên>.wav` (cùng tên là mọi chỗ dùng tự nâng cấp), hoặc `presentation/audio/sfx_manager.tscn` (mục `streams` trong Inspector) / track âm thanh trong clip của actor |
| Đổi bố cục HUD (vị trí và kích thước từng mảnh) | **1 file**: vị trí của mảnh trong `presentation/ui/hud/hud.tscn` (ô **Offset** của node đó), hoặc bên trong scene của chính nó `presentation/ui/hud/widgets/<tên>.tscn`. Mỗi mảnh HUD là một scene riêng. Mảnh phải nằm trong dải trên (y 0-32, cao tối đa 28 px) hoặc dải dưới (y 326-360) và không đè hàng ô nào: `test_hud_safe_zone` nhắc nếu sai (mục 1, mảnh 6) |
| Đổi một phím | `project.godot`, mục `[input]` (hoặc Project Settings → Input Map). Bảng **Controls** (menu pause) tự đọc InputMap nên tự cập nhật; một action mới cần một dòng tên `UI_ACTION_<TÊN>` trong `ui.po` và một hàng trong `presentation/ui/controls/controls_catalog.gd` (bài test `test_controls_panel_from_inputmap` nhắc nếu quên) |
| Đặt hình phím và nút tay cầm (glyph) | **1 file mỗi phím**, trong `assets/ui/glyphs/keyboard/` và `assets/ui/glyphs/gamepad/` (tên như danh sách asset, nhóm `glyphs_kenney`: `key_w.png`, `key_space.png`, `btn_a.png`, `dpad_up.png`...). Bạn tải bộ CC0 "Input Prompts Pixel" của Kenney rồi chép từng tile vào đúng tên; chưa có file nào thì game hiện chữ thay thế như `[Space]`, `[A]`. Chi tiết ở mục 8 |
| Đổi giá trị mặc định của một cài đặt, hay thêm một cài đặt | `schema/settings/game_settings.gd` (một hàng `SettingDefinition`: khoá, loại, trang, mặc định, khoảng giá trị) + một dòng tên trong `ui.po` + dòng làm cho nó có tác dụng (`shell/settings/settings_applier.gd` cho cả app, `shell/bridges/settings_bridge.gd` cho phòng). `test_every_setting_has_a_target` đỏ nếu không có bài test nào chứng minh nó chạm tới mục tiêu |
| Đổi chữ (thoại, thông báo, tên, menu, HUD) | **1 dòng** trong một file `content/story/text/en/*.po` (sửa phần sau `msgstr`, lưu, chạy lại game): `ui.po` (title, pause, HUD, các câu trên dòng trạng thái `MSG_...`), `rooms.po` (tên phòng, câu khi vào phòng, câu cửa khoá), `skills.po` (tên kỹ năng và vũ khí), `story.po` (Book, tên quân, credits). Ô chữ trong scene hay `.tres` chỉ chứa **mã** (ví dụ `ROOM_T3_FIRST_PAWN_CLASH_LOCKED`): đừng gõ chữ vào đó. Làm từng bước ở mục 8 |
| Đổi tên bạn, thêm dòng hay thêm khối vào credits (và tốc độ cuộn) | **1 file**: `content/story/credits.tres` (Inspector: `sections` là các khối, mỗi khối có `heading` và `lines`; dòng trống là khoảng cách; `scroll_pixels_per_second` là tốc độ). Chữ của các khối là dòng `CREDIT_...` trong `content/story/text/en/story.po` (dòng ghi tác giả là `CREDIT_OWNER_LINE`, hiện là "The owner": thay bằng tên bạn); `credits.tres` chỉ giữ mã của chúng. Khối **Licenses** ở cuối **sinh tự động** từ `THIRD_PARTY_NOTICES.md`: sửa file đó rồi chạy `godot --headless --path . -s tools/build_credits_licenses.gd` (đừng sửa tay `credits_licenses.tres`; bài test `test_credits_licenses_current` đỏ khi hai nơi lệch nhau). Giữ phím Confirm để bỏ qua credits |
| Đổi số phiên bản hiện ở góc màn title | **1 dòng**: `config/version` trong `project.godot` (Project Settings → Application → Config → Version) |
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
(hàng mới), đổi animation hay âm thanh chuyển động. **M3a kiểm thêm** hai hàng cuối cùng còn ghi "available after M3a": thêm enemy có hành vi mới và thêm cơ chế sàn mới. Đường dẫn thật đều đã có: `ecs/systems/<phase>/`, một dòng trong `ecs/schedule/<phase>.gd`, `ecs/events/events.gd` và `ecs/components/<tên>.gd`; hai hàng ấy giờ ghi "available now", kèm phần còn thiếu (kiểu tấn công mới, ô tạm thời).

| Bạn muốn... (You want to...) | Sửa file này (Edit this) | Số file (Files) | Cần code? (Code?) | Trạng thái (Status) |
|---|---|---|---|---|
| Thêm một biến thể enemy (đổi skin, máu, tốc độ hoặc vũ khí) (Add a variant enemy (re-skin, new health, speed or weapon)) | `content/enemies/<id>/enemy.tres` (reusing `_shared` sub-resources), a `visual.tres` that names its `piece_type` and `body.png`; in a room, instance `actor_view_base.tscn` and set `definition` (no scene of your own); the `ENEMY_<ID>_NAME` row in `story/text/<locale>/story.po`. | 4 | no | **available now** for everything but the name row (dòng tên trong `.po`: M4). Counted by doing it (M2): 1 file when it reuses `_shared`, 3 with a picture of its own, plus the room edit that places it; `/new-enemy` walks through it |
| Thêm enemy có hành vi mới (Add an enemy with new behaviour) | `enemy.tres` + one `EntityComponent` or `AttackBase` script + one system file + one line in `ecs/schedule/<phase>.gd`; plus `events.gd` if it emits a new event and `ViewSyncSystem` if its visuals are new. | 4 new, up to 3 existing edited | yes | **available now** (lịch `ecs/schedule/`, `events.gd` và `EntityComponent` đã có; kiểu tấn công mới với `AttackBase`: M8a) |
| Chỉnh (retune) một enemy hoặc boss (Retune an enemy or boss) | its `.tres` | 1 | no | **available now** for an enemy (`content/enemies/<id>/enemy.tres` and the `.tres` it points at, 1 file), M8b (boss) |
| Thêm một skill vào slot có sẵn, dùng các loại effect có sẵn (Add a skill in an existing slot from existing effect kinds) | `content/skills/<id>/skill.tres`, `icon.png`, one `milestones/<id>.tres`, three rows in `skills.po` (name, description, hint), a `sound_bank.tres` row if the sound is new. HUD slot, input and cooldown bar come from the file and `slots.tres`. | 4-5 | no | available after M7c |
| Thêm một skill cần một phím mới (Add a skill that needs a free button) | the above + one `InputMap` action in `project.godot` + one `slots.tres` row | 6-7 | no | available after M7a |
| Thêm một skill cần một loại effect mới (Add a skill needing a new effect kind) | effect schema + handler + one line in `ecs/schedule/act.gd` + `skill.tres` + milestone + `.po` rows (Chalk Block is the worked example) | 7-9 | yes | available after M7a |
| Chỉnh một skill (Retune a skill) | `skill.tres` | 1 | no | available after M7a (verb mới), M7b (Sword và Pencil) |
| Đổi cách hoặc lúc nhận một skill (Change when or how a skill is earned) | the milestone `.tres` (trigger kind: boss_defeated, room_cleared, grant_marker, flag). Moving a physical marker = delete in room A + add in room B. | 1-2 | no | available after M7c |
| Thêm hoặc sửa một trang Book mà loại modifier đã có handler (Add or edit a Book page whose modifier kind already has a handler) | `content/rules/<id>/page.tres` + rows in `story.po` | 2 | no | available after M7c |
| Thêm một trang Book cần loại modifier mới (Add a Book page that needs a new modifier kind) | modifier schema + handler + schedule line + `page.tres` | 4-5 | yes | available after M7c |
| Thêm một Annotation (`SkillUpgrade`) (Add an Annotation (a `SkillUpgrade`)) | the upgrade row on `skill.tres` + `.po` rows | 2 | no | available after M7c |
| Viết lại một câu truyện, chữ UI hoặc một cái tên (Rewrite a line of story, UI text or a name) | one `msgstr` in `content/story/text/<locale>/*.po` (soft lints only warn in the editor) | 1 | no | **available now** |
| Thêm một ngôn ngữ (Add a language) | `content/story/text/<locale>/{story,ui,skills,rooms}.po` + register them in `project.godot` (`internationalization/locale/translations`); `vi` exists and is empty (it falls back to English line by line) | 5 | no | **available now** (section 8): the files, and the language list on the Screen tab of Settings |
| Đổi tên một nhân vật (Rename a character) | the `CHAR_<ID>_NAME` row | 1 | no | available after M6 |
| Thêm một đoạn hội thoại, câu ambient hoặc prompt (Add a conversation, ambient line or prompt) | a beat `.tres` (or a line in `script/<act>.txt` + `tools/build_beats.gd`) + its `.po` rows | 2-3 | no | available after M6 |
| Dựng một cutscene (Stage a cutscene) | beat `.tres` files + `.po` rows + a `TriggerMarker` in the room + `sound_bank` rows + `characters/<id>.tres` if there is a new speaker (+ a `cutscene.tscn` for a Tier-2 cutscene) | 5-7 | no | available after M6 |
| Thêm một phòng (room) (Add a room) | one layout `tools/layouts/<id>.txt` (a map of characters: `tools/build_room.gd -- --legend` prints the legend) built into `content/rooms/<id>/room.tscn` by `tools/build_room.gd` (the tool also adds the `.po` rows: name, start message, locked message), one exit marker in the neighbouring room, one `WorldRoom` and its `WorldEdge`s in `content/world/world.tres` (the map slot lives there only). A room is made of individual tiles and props, never a painted background. The tool never overwrites a scene that exists: once you edit the scene in Godot, the scene is the truth | 4-5 | no | **available now** (M5 steps 1 and 2): the builder, the layout format and `tools/print_world_map.gd`; every room of the plan exists as a stub (`tools/list_placeholders.gd` counts them) |
| Đổi enemy hoặc bố cục của một phòng (Change a room's enemies or layout) | that `room.tscn`. Một cửa (`ZoneExitMarker`) phải nằm trên **ô sàn** sát tường, không nằm trong vòng tường: ô tường không đứng lên được nên cửa trong tường không bao giờ dùng được; marker vào (`ZoneEntryMarker`) đặt cách cửa một ô về phía trong. Bài `test_room_doors_reachable` báo lỗi nếu sai (*EN: a door goes on a floor cell next to the wall, never in the ring of wall; its entry marker one cell further in*) | 1 | no | **available now** (`content/rooms/<id>/room.tscn`) |
| Đổi một khoá (lock) hoặc thêm lối tắt (shortcut) (Change a lock or add a shortcut) | the exit or gate marker in `room.tscn` (a door that waits for a boss: its **Requires Flag**, `boss.<id>`, and its **Locked Message** key) + the `WorldLock` and the `WorldEdge` in `content/world/world.tres` + the `locked_message` row. A door that will need a skill later names a `skill_lock_id` (a promise, `arrives_in M7c`: the door is open until then). `tools/print_world_map.gd` prints every lock and the route | 3 | no | **available now** (M5 step 2) |
| Đổi câu nói khi bước vào cửa đang khoá chờ dọn phòng (Change the line a shut door says) | the words: the row `ROOM_<ID>_LOCKED` of `content/story/text/en/rooms.po` (section 8). Which row a door says: the exit marker's **Locked Message** in `room.tscn` holds that KEY (empty = the generic line `MSG_DOOR_IS_LOCKED`, which blames no piece). `test_room_doors_reachable` fails a shut door with no line, `test_text_keys` fails a key with no row. | 1 | no | **available now** |
| Thêm một prop chỉ xuất hiện khi đủ điều kiện (Add a prop that appears after a condition) | a `StateVariantMarker` on the prop in `room.tscn` | 1 | no | available after M6 |
| Đổi cách hub tiến hoá hoặc các biến thể ending (Change the hub evolution or ending variants) | `StateVariantMarker` props in H1's `room.tscn`, `ending.tres` | 1-2 | no | available after M6 (hub), M13 (ending) |
| Thêm pickup, shard hoặc keepsake (Add a pickup, shard or keepsake) | `pickup.tres`, `pickup.png`, a spawn in `room.tscn`, a `.po` row (+ a milestone row if it grants) | 4-5 | no | available after M7c |
| Thêm NPC hoặc cuộc giải cứu (rescue) (Add an NPC or rescue) | a prop with an `InteractComponent`, a beat, a flag in `flags.tres`, `room.tscn`, `.po` rows | 5 | no | available after M6 |
| Thêm một boss (Add a boss) | `boss.tres` (M8b), `enemy.tres` (with **Defeat Flag** `boss.<id>`: its fall sets the flag, and every door that waits for it opens), `body.png`, the arena `room.tscn`, beats + `.po` rows, a milestone row, a `music_cues` row. The five stand-in bosses of M5 are exactly the first three files and an arena | 7-10 | no, if its attacks use existing kinds | the stand-in is **available now** (M5 step 2); the full boss after M8b |
| Thêm hoặc chỉnh một phase của boss (Add or retune a boss phase) | `boss.tres` (a new windup clip also edits the boss's actor scene) | 1-2 | no | available after M8b |
| Đổi sprite (Swap a sprite) | overwrite `body.png`, drawn at scale 1 on the 32x32 canvas of `docs/assets` with the drawn pixels inside the box of its kind in `content/feel/piece_sizes.tres` (the canvas lands exactly on the cell; `VisualDefinition.anchor_offset` nudges it); the placeholder flag clears by hash | 1-2 | no | **available now** for `content/player/body.png` (white pawn) and the enemies' (`pawn_recruit` is every black pawn, `knight_tracker`, `bishop_zoner`); `ContentDb.validate_cross_refs()` fails a picture whose drawn pixels leave the box; `assets/_generated/previews/pieces_in_cells.png` and `pieces_placed_in_rooms.png` (`tools/render_actor_preview.gd`) show the hero and the enemies in their cells, and section 6 reads them |
| Đổi kích thước quân trong ô (Change how big a kind of piece is inside its cell) | `content/feel/piece_sizes.tres`: one row per kind with the largest picture (`body_box`), the base line (`base_offset_y`, px below the cell's centre) and a footprint in cells. `validate()` keeps every box 2 px from the cell's edges and the heights as in a real chess set (pawn < knight, bishop, rook < queen < king) | 1 | no | **available now**; the placeholder pieces come from `tools/generate_chess_sprites.gd`, which reads the same file and refuses a piece that does not fit |
| Đổi art của một phòng (Swap a room's art) | overwrite its single tile and prop PNGs (one file per thing, see `docs/assets/`); a tool assembles the room. The painted `background.png` of T1/T2 is a legacy placeholder, not something to redraw | 1 per thing | no | tiles and props: after the assembly tool lands; T1/T2 backgrounds: overwrite now if wanted |
| Đổi portrait, skin UI hoặc font (Swap a portrait, UI skin or font) | overwrite the file in `content/story/characters/`, `content/ui/theme/`, `assets/fonts/` | 1 | no | font: **available now** (`assets/fonts/ui_body_pixel.ttf` and the three other names of section 8); key and gamepad glyphs: **available now** (`assets/ui/glyphs/`, section 8); skin UI: the High-contrast menus setting is the only skin today; portrait: after M6 |
| Thêm nhạc hoặc đổi bài nhạc đang phát (Add music or change which track plays) | drop the file in `assets/music/` + a row in `music_cues.tres` | 2 | no | available after M6 |
| Thêm hoặc đổi âm thanh sự kiện (pickup, jingle, UI) (Add or swap an event sound (pickup, jingle, UI)) | drop the file + a row in `sound_bank.tres` | 2 | no | available after M6 |
| Đổi âm thanh chuyển động hoặc sửa một animation clip (Swap a motion sound or edit an animation clip) | an **editor task** in `presentation/views/actors/actor_view_base.tscn` (changes every actor that inherits it) or in a bespoke inherited view; how fast a clip plays for one kind of piece is `clip_speed_scales` in its `visual.tres`, no scene edit. Keep hops and shakes within the 2 px margin: `test_pieces_inside_cell` samples every clip | 1 scene | no | **available now** |
| Đổi bố cục HUD (Change the HUD layout) | the widget scene in `presentation/ui/hud/widgets/`, or its offsets in `hud.tscn` | 1 | no | **available now** (M4 step 4): one scene per widget; `test_hud_safe_zone` keeps each in a strip and off every row of every board |
| Chỉnh độ khó hoặc assist (Tune difficulty or assists) | `content/difficulty/<profile>.tres` (global health and damage multipliers live here); for one enemy, its `enemy.tres` | 1 | no | available after M8a |
| Chỉnh cảm giác chơi (rung, nháy, hit-stop, màu telegraph, chord window) (Tune game feel (shake, flash, hit-stop, telegraph colours, chord window)) | `content/feel/feel_profile.tres` | 1 | no | available after M7b |
| Đổi cảm giác của con tốt (thời gian mỗi bước, courage, invulnerability) (Change how the pawn feels (step time, courage, invulnerability)) | `content/player/player.tres` (`PlayerDefinition`: Courage, invulnerability, step time, hold-repeat delay, skill cooldown, sword unlocked or not; the player scene holds none of these any more, and a node on a room's instance still beats the file) | 1 | no | **available now** (M2; `tests/content/test_player_definition.gd` proves every field reaches the hero) |
| Đổi luật kinh tế (Believe, shard, stagger, ngưỡng assist) (Change economy rules (Believe, shards, stagger, assist thresholds)) | `content/progression/rules.tres` | 1 | no | available after M7c |
| Đổi phím mặc định (Change input defaults) | the `[input]` section of `project.godot` (keyboard and gamepad events); the HUD hints and the Controls panel read it | 1 | no | **available now** (M4: every played action has a keyboard and a gamepad event, `test_input_actions_have_pad_events`) |
| Đổi chữ ở màn title hoặc credits (Change title text or credits) | `credits.tres` + `.po` rows | 2 | no | credits: **available now** (the rows `CREDIT_...` of `content/story/text/en/story.po`; `content/story/credits.tres` holds their keys, 1 file; the Licenses block is generated from `THIRD_PARTY_NOTICES.md`); title words: **available now** (the rows `UI_TITLE_...` of `content/story/text/en/ui.po`) |
| Thêm cơ chế sàn mới (gai, công tắc) (Add a new floor mechanic (spikes, switch)) | marker + component + system + one schedule line (+ an event) | 4-5 | yes | **available now** (ô nguy hiểm tạm thời như phấn hay sàn hỏng: M10) |

*EN: The first table lists today's real locations (all of these paths exist). The second is the target
Owner Change Table from plan §13.5; each row says which milestone makes it true, and the rows marked
"available now" were checked against the tree at the end of M1b, M2 and M3a (M2 counted the files of the
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

**Vẽ thế nào.** Vẽ ở tỉ lệ 1:1 (một pixel của file PNG là một pixel của game, không phóng to hay thu nhỏ), **trên canvas
32×32 đúng bằng một ô, như danh sách yêu cầu trong `docs/assets`**: vành đế dưới chân quân nằm ở hàng 30 (hai hàng dưới
cùng để trống), thân quân nằm trong hộp của loại quân (Tốt 18×22 chiếm cột 7–24 và hàng 8–29; Mã, Tượng, Xe 20×24;
Hậu 22×26; Vua 22×28), phần còn lại của canvas để trong suốt. Canvas được đặt trùng khít lên ô: điểm ảnh (x, y) của
PNG hiện đúng ở điểm (x, y) của ô, nên bạn không phải chỉnh vị trí trong scene. (Một PNG nhỏ hơn, chỉ vừa hộp, cũng
chạy trong game, đáy PNG đặt lên vạch cách tâm ô 14 px; nhưng cảnh trong editor chỉ hiện đúng chỗ với canvas 32×32.)
Muốn xê dịch một chút cho riêng một quân: `anchor_offset` trong `visual.tres` của nó. Thay hình = ghi đè
`content/player/body.png` hoặc `content/enemies/<id>/body.png` (hàng "Đổi sprite" ở mục 5). Nếu thân quân lấn ra
ngoài hộp, bài kiểm tra báo đỏ và nói rõ hình nào, thân chiếm vùng nào, hộp nằm ở đâu.

**Xem kết quả mà không cần mở editor: `assets/_generated/previews/pieces_in_cells.png`.** Đó là một ảnh 1768×760
(phóng 4 lần, số nguyên, không làm mờ): bốn hàng, chín cột. Hàng là HERO (con tốt trắng của bạn), BLACK PAWN,
KNIGHT, BISHOP. Cột là AT REST (đứng yên) nhìn xuống, phải, lên, trái; ARMED (đang cầm vũ khí, hoặc con tốt
đang đâm bút chì) nhìn bốn hướng; ALERT (đang báo trước đòn đánh, vòng cảnh báo hiện ra). Mỗi ô vuông là một ô
game 32×32 có một dải trống 6 px bao quanh (để thấy nếu quân lấn ra ngoài ô): đường lưới xám là mép ô, **khung đỏ mờ là vạch
lề 2 px** (vẽ dưới quân, không bao giờ đè lên điểm ảnh của quân); quân phải nằm gọn trong khung đỏ. **Điểm ảnh nào của quân
nằm trong dải lề hoặc ngoài ô được tô hồng đậm (magenta)**, và công cụ in số lượng (`0 pixel(s) outside the margin` là
ổn). Ô ALERT của hero để trống vì con tốt của bạn không bao giờ báo đòn. **Ảnh thứ hai, `pieces_placed_in_rooms.png`,
có mỗi hàng là một enemy mà các phòng thật sự đặt** (7 hàng hiện nay, ghi tên phòng và tên node), vẽ đúng như phòng đặt,
kể cả khi một phòng chỉnh scale. Muốn thấy một lỗi trông ra sao: `-- --stretch=1.5` vẽ bốn nhân vật phóng to 1,5 lần vào
`overflow_demo.png`. Thư mục `assets/_generated/` không nằm trong git, nên
ảnh có sẵn sau `tools/bootstrap_worktree.sh`; vẽ lại bất cứ lúc nào (không cần cửa sổ, vài giây):

```bash
../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/render_actor_preview.gd
```

Ảnh này vẽ đúng chỗ game vẽ: công cụ chạy chính `ViewSyncSystem` thật lên chính cảnh actor thật rồi
đọc lại điểm ảnh, chứ không phải một bản vẽ tay của bố cục. Cổng kiểm thật là
`tests/architecture/test_pieces_inside_cell.gd`: nó đặt con tốt, ba cảnh enemy mỏng, **cả bảy enemy** của `content/enemies/` và **mọi enemy mà các phòng đặt** (đúng như
phòng đặt: một phòng kéo giãn một quân là báo đỏ, nêu tên phòng và tên node) lên cảnh actor, cho nhìn bốn hướng, cầm từng
loại vũ khí, đang báo đòn, bị đánh bật lùi, và lấy mẫu mọi clip animation (khoảng 600 tư thế); mọi điểm ảnh phải
cách mép ô ít nhất 2 px ở trạng thái đứng yên (hẹp nhất đo được đúng 2,0 px), và cú đánh bật chỉ được dùng hết lề đó
(chạm mép ô, không vượt qua). Ảnh thứ nhất chỉ có bốn hàng: một enemy mới chỉ có `definition` (không có cảnh riêng)
không có hàng riêng ở đó, nhưng bài kiểm vẫn đo nó, và nếu một phòng đặt nó thì nó có hàng trong ảnh thứ hai.

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
- Dải máu (pip) nằm sát lề trên của ô. Hậu và Vua cao tới mức không còn chỗ phía trên đầu trong ô, nên dải máu của
  chúng được vẽ đè lên vương miện; bài kiểm gọi tên hai loại đó, và một loại mới cao tới dải máu (một boss) sẽ báo đỏ cho
  tới khi bạn quyết định.
- Mã và Tượng đang cùng một bậc chiều cao trong bảng, và hình tạm của Tượng (22 px) thấp hơn Mã (24 px). Bộ cờ thật có
  Tượng cao hơn Mã; muốn vậy phải tách bậc trong bảng và vẽ lại, một quyết định của bạn.
- Vũ khí cầm tay được vẽ nhỏ (0,16 lần) để vừa ô 32 px; tầm đánh được thể hiện bằng lớp phủ trên bàn cờ, không phải
  bằng độ dài của hình vũ khí.

*EN: A piece is smaller than its 32 x 32 cell (owner, 2026-10-12): at least a 2 px margin on every side, never
cell-sized, never taller, heights as in a real chess set. The rule lives in the data: `content/feel/piece_sizes.tres`
has one row per kind with the largest body (`body_box`), the base line (`base_offset_y`, 14 px below the
cell's centre, so the bottom margin is 2 px) and a footprint in cells; `validate()` holds the margin and the height
order. Draw at scale 1 on the 32 x 32 canvas of `docs/assets` (base rim on row 30, two empty rows under it), the drawn
pixels inside the kind's box (pawn 18 x 22 at x 7-24, y 8-29): the canvas lands exactly on the cell and the scene needs
no edit; a smaller PNG that fits the box also runs in the game, its bottom edge on the base line. To see the result
without the editor open `assets/_generated/previews/pieces_in_cells.png` (made by `tools/bootstrap_worktree.sh`, or run
`tools/render_actor_preview.gd`): four rows (hero, black pawn, knight, bishop) by nine cells (at rest facing four
ways, armed facing four ways, alert), 4x, each cell with a 6 px gutter, the cell edge as a grey line and the 2 px margin
as a faint red frame, both under the pieces; any piece pixel in the margin band or outside the cell is magenta and
counted. `pieces_placed_in_rooms.png` has one row per actor the rooms place, as placed.
`tests/architecture/test_pieces_inside_cell.gd` is the real gate and measures the hero, the three thin enemy scenes, all seven enemies of `content/enemies/` and every actor a room places (as the room places it; a stretched piece fails by room and name), in every
facing, shoved by a hit and about 600 clip poses; an enemy that is only a `definition` is measured but is not a row of the first picture.
Not yet: rook, queen, king and boss pictures exist only as table rows; the four bodies are placeholders (the knight was
retraced on 15 rows to fit its box, an edit to an approved shape recorded in `THIRD_PARTY_NOTICES.md`).*

## 7. Lưu game, checkpoint và khi con tốt ngã (Save, checkpoints and death)

**Quy tắc trong một câu:** chết chỉ làm phòng bạn vừa ngã bắt đầu lại, và bạn đứng lại **ở ô vào của chính phòng đó**
(ô bạn bước vào khi đi qua cửa); phòng đã dọn thì giữ sạch; mọi thứ bạn đã kiếm được giữ nguyên. (Quyết định D-16 và
D-17; "Giữ sạch" là câu trả lời của bạn trong `docs/owner-decisions.md`.)

**Ba nơi khác nhau, đừng lẫn (bản build làm đúng như bảng này):**

| Việc | Đưa bạn tới đâu | Việc đi kèm |
|---|---|---|
| Chết, hoặc chọn **Restart Room** trong menu pause (`Esc`) | **ô vào của phòng bạn vừa ngã**, không bao giờ xa hơn. Chết trong phòng boss B1 thì đứng lại ở ô vào B1 | Courage đầy; phòng bắt đầu lại nguyên (địch đầy máu, vũ khí rơi về sàn); chết không lưu game |
| Checkpoint: bước qua cửa vào hub hoặc vào một phòng boss | không đưa bạn đi đâu: đó là nơi **Courage được hồi đầy** (Believe cũng thế, từ M10) | game ghi lại "checkpoint gần nhất" (hub hoặc phòng boss, kèm ô vào) rồi lưu; menu pause gọi tên nó khi bạn chọn Quit to Title. Chết **không** đưa bạn về đó |
| Mở game lại (Continue) | phòng và ô vào của **lần lưu cuối**, không phải phòng cuối cùng bạn đứng | game chỉ lưu khi có việc tốt vừa xảy ra, nên ngay sau khi bước vào checkpoint thì lần lưu cuối chính là checkpoint và bạn tiếp tục ở đó; sau khi dọn xong một phòng khác thì bạn tiếp tục ở phòng đó |

**Chơi thử (Owner can try).** Mọi bước dưới đây làm được trong các phòng hiện có, **theo đúng thứ tự, từ một file save
sạch**: mỗi bước làm tiếp từ chỗ bước trước dừng. Bài test `tests/bridge/test_owner_guide_steps.gd` đi đúng các bước này:
mọi bước chân là phím mũi tên qua các cửa, mọi con tốt bị hạ bằng **nhát kiếm thật** (đi tới sát nó, quay mặt về phía nó,
bấm đánh; một con tốt mà kiếm không với tới thì test đỏ), còn con tốt đen đánh gục bạn ở bước 1 và lính gác nhặt thước ở
bước 4 là AI địch thật. Chỗ duy nhất được thay bằng một yêu cầu sát thương là **vết thương một điểm ở bước 3** (để một
trong ba con tốt đang thức đánh trúng đúng một lần là chuyện canh giờ, không phải điều cần thử). Nên nếu một phòng đổi mà
bước không còn làm được thì test đỏ.
Các cửa đi được **hai chiều**: cửa đi tiếp nằm ở góc đông-bắc của
phòng, cửa quay lại nằm ở phía tây, sát tường, ngay cạnh ô vào (một bước sang trái từ ô vào là về phòng trước). Mở game
(F5), ở màn title chọn **New Game** (hoặc **Continue** để tiếp tục từ save), rồi:

0. *Chuẩn bị (một lần).* Từ T1 đi tới cửa góc đông-bắc để sang T2. Trong T2, đi sang phải tới thanh kiếm đang phát sáng và
   bước lên nó: bạn có kiếm gỗ (Space hoặc K) và game lưu. Đi tiếp cửa đông-bắc của T2 sang T3: trong T3 chỉ có một con tốt
   đen. Phòng T1 và T2 không có địch, nên chưa thể ngã ở đó.
1. *Chết và hồi sinh (T3).* Đứng yên ở ô vào của T3 thì không sao: con tốt đen không tự đi tìm bạn. Hãy đi tới sát nó
   (không đánh) rồi đứng yên cho nó đánh hết 3 Courage, chừng 4-6 giây. Sau khoảng một giây bạn đứng lại **ở ô vào của
   T3**, Courage đầy (các chấm trên HUD cũng đầy), con tốt đen đầy máu, kiếm gỗ vẫn trong tay. Menu pause (`Esc`) → **Restart Room** → xác nhận
   làm y như chết mà không cần ngã (`R` không còn làm việc này: nó là phím gọi đứa trẻ, D-18). (Ngã trong phòng boss B1 cho cùng kết quả: bạn đứng lại ở ô vào của B1, boss và hai lính đầy máu, vòng đầu của boss.)
2. *Phòng đã dọn thì giữ sạch, phòng chưa dọn thì làm lại.* Hạ con tốt đen của T3 bằng kiếm: cửa đông của T3 mở. Sang T4,
   rồi đi **cửa tây của T4** (một bước sang trái từ ô vào) để về T3: T3 vẫn trống. Restart Room từ menu pause trong T3: vẫn trống. Ngược lại
   T4 chưa dọn: vào T4, hạ một trong ba con, rồi về T3 bằng cửa tây và sang T4 lần nữa: địch về đủ 3 con và đủ máu.
3. *Checkpoint hồi Courage, cửa thường thì không.* Bạn đang ở T4 với cả ba con tốt còn sống (cuối bước 2). Để một con của
   T4 đánh trúng bạn **đúng một lần**: HUD mất một chấm (đừng để hết 3 Courage). Đi **cửa tây của T4** sang T3 (trống) rồi
   quay lại T4: số chấm vẫn y như vậy (đi qua cửa phòng thường không hồi, và T3, T4 không phải checkpoint), còn ba con tốt
   của T4 về đủ. Hạ cả ba con bằng kiếm để cửa đông mở, đi sang B1: các chấm Courage đầy lại, vì cửa phòng boss là
   checkpoint (hub H1 cũng vậy, nhưng cửa sang H1 chỉ mở khi hạ boss).
4. *Vũ khí rơi trên sàn thì về chỗ (B1).* Trong B1 có thanh thước (Ruler Blade) nằm trên sàn. Đứng yên ở ô vào, **chừng một giây**
   là đủ (nhanh hơn bạn nghĩ): một lính gác chưa cầm gì đi tới nhặt nó, thanh thước biến khỏi sàn và dòng trạng thái ghi
   `... picked up Ruler Blade`. Nếu bạn nhìn chỗ khác thì có thể đã bỏ lỡ, không sao: chọn Restart Room trong menu pause (hoặc để bị hạ) là phòng bắt
   đầu lại, thước lại nằm trên sàn và tay lính trống như cũ, rồi xem lại từ đầu. Đó
   là luật "vũ khí trên sàn thuộc về phòng" (D-16). Cây giáo bút chì ở T4 là một vũ khí rơi như vậy: nó nằm ở cuối phòng,
   ngay sau con tốt cầm giáo, cạnh cửa đông, và con tốt chưa cầm gì của T4 sẽ đi về phía nó khi bạn lại gần. Nhưng ở bước
   này T4 đã được dọn (bước 3), nên bước thước ở B1 là bước làm được; muốn thấy cây giáo thì làm trên save sạch và dừng ở T4
   trước khi hạ ba con. Bạn chưa nhặt được cây giáo: việc nhặt nó để mở phím Q thuộc M7 (D-11), bản build này chỉ có con tốt nhặt.
5. *Thoát game rồi mở lại.* Đang ở B1 sau bước 3, đi cửa tây của B1 về T4, cửa tây của T4 về T3 (hai chuyến qua phòng
   thường, không lưu), rồi thoát. Mở lại: game đang ở **B1**, đúng ô vào, Courage đầy, kiếm còn, T3 và T4 vẫn trống, vì
   lần lưu cuối là lúc bước vào B1 chứ không phải T3. (Muốn thấy "phòng đã dọn" làm điểm tiếp tục: hạ con tốt của T3 rồi
   thoát ngay, lần sau game mở ở T3, T3 trống.)

**Muốn làm lại một bước.** Phòng đã dọn thì trống mãi (D-17), nên các bước 1-3 chỉ làm được **một lần trên một file save**:
bước 1 cần con tốt của T3 còn sống, bước 2 hạ nó, bước 3 hạ ba con của T4. Muốn làm lại từ bước 0 (hoặc từ bước 1, 2, 3):
ở màn title chọn **New Game** (hoặc thoát game rồi **xoá `slot_0.cfg` và `slot_0.cfg.bak`**, xem "File save nằm ở đâu" ở dưới): game
bắt đầu ở T1, chưa có kiếm. Chừng nào chưa dọn T4 thì phần "địch về đủ 3 con" của bước 2 làm lại thoải mái (ra cửa tây rồi vào lại). Bước 4 và 5
làm lại tùy ý, không cần xoá save (Restart Room trong B1 đưa thước về sàn; bước 5 là thoát rồi mở lại).

**Game lưu khi nào.** Chỉ khi một việc tốt vừa xảy ra, không bao giờ khi chết, khi bị đánh hay khi chỉ đi sang phòng
khác: dọn xong một phòng, bước vào hub hoặc phòng boss (checkpoint), nhặt kiếm, lần đầu gặp một loại quân (ghi thêm một
trang Book), mở một cổng tắt (Stage 1 chưa có cổng nào), nhặt một vật thưởng giữ mãi. Nên nếu bạn đi sang hai phòng thường
rồi thoát luôn, lần sau game mở ở phòng của lần lưu trước đó, không phải phòng cuối cùng bạn đứng.

**Sau khi chết, cái gì còn và cái gì mất.**

| Còn nguyên (nằm trong lần chơi) | Về lại như ban đầu (thuộc về phòng) |
|---|---|
| kiếm và các kỹ năng đã mở, các cờ của truyện, phòng đã dọn, boss đã hạ, cổng tắt đã mở, giải cứu, trang Book, mảnh Courage, vật thưởng giữ mãi đã nhặt, checkpoint gần nhất | địch của phòng chưa dọn (đủ máu), vũ khí rơi trên sàn, vũ khí địch đang cầm, mọi bộ đếm giờ và vùng báo đòn, Courage (về đầy) |

**File save nằm ở đâu.** Trong thư mục user data của dự án, thư mục con `saves/`: `slot_0.cfg` và `slot_0.cfg.bak`
(bản lưu liền trước). Trên macOS: `~/Library/Application Support/Godot/app_userdata/The Unbound Pawn/saves/`.
Trong Godot: menu **Project → Open User Data Folder**. File `profile.cfg` nằm cạnh `saves/` (dấu "đã xem kết thúc") và
sống sót qua New Game. **Muốn bắt đầu sạch:** ở màn title chọn **New Game** (có save thì nó hỏi lại; sau khi bạn đồng ý, lần chơi mới được ghi đè
lên `slot_0.cfg` ngay, còn save cũ nằm lại ở `slot_0.cfg.bak` cho tới lần lưu tự động kế tiếp), hoặc thoát game rồi xoá
`slot_0.cfg` và `slot_0.cfg.bak` (nếu có thêm `world_state.cfg` từ bản cũ thì xoá luôn). Game không bao giờ tự xoá save của
bạn: file hỏng thì nó thử bản `.bak` và báo một dòng trên màn title (nút Continue vẫn có), file hỏng mà không có bản dự
phòng thì title báo và chỉ còn New Game (file hỏng được giữ lại với đuôi `.corrupt`), file của bản game mới hơn thì nó không
đọc, không ghi đè (New Game đổi tên nó thành `.newer_game`). **Continue** mở lại phòng và ô vào của lần lưu cuối (xem bảng
ở đầu mục này). **Thoát về title** (menu pause → Quit to Title, hỏi xác nhận và nêu tên checkpoint) không lưu gì: tiến trình sau lần lưu cuối sẽ mất, và Continue
đọc lại file.

**Một chỗ agent đã tự chọn, bạn có thể đảo lại.** Kế hoạch viết cả "về checkpoint gần nhất" lẫn "chỉ phòng đang chơi
bắt đầu lại". Nếu hiểu đúng từng chữ, chết ở T3 sẽ đưa bạn về đầu Stage 1, quá nặng so với "chết nhẹ nhàng". Agent chọn
cách nhẹ nhất, và bản build làm đúng như vậy: **chết đưa bạn về ô vào của phòng vừa ngã** (không bao giờ xa hơn). Còn
**checkpoint** (ô vào của hub và của phòng boss) là nơi Courage được hồi đầy (và sau này Believe), được ghi lại trong file
save và được menu pause nhắc tên. **Mở game lại** đưa bạn tới phòng và ô vào của lần lưu cuối, nên ngay sau khi
vào checkpoint thì đó cũng là checkpoint, nhưng game không có chỗ nào tự đưa bạn về checkpoint. Nếu bạn muốn chết (hoặc
Continue) đưa về hẳn checkpoint: nói với agent, việc sửa nhỏ (`docs/game-base-plan.md` mục 5.2 ghi đúng chỗ phải sửa).

**Chưa có:** bàn tay của đứa trẻ đặt con tốt lại (M8c), Believe (M10), boss nhiều pha với "pha
đã qua điểm lưu" (M8b; hiện phòng boss bắt đầu lại từ đầu).

*EN: Section 7 is what M3b added for you. One sentence: a death restarts only the room you fell in, and you stand
again on the ENTRY you came into it by (full Courage, enemies back at full health, floor weapons back on the floor, a
boss room starts over); cleared rooms stay cleared (your answer "Giữ sạch"); everything you earned stays. Three
places that are easy to confuse: a death (or Restart Room from the pause menu) sends you to the entry of the room you fell in, never farther back;
the CHECKPOINT (the entry of a hub or a boss room, reached through a door) is where Courage refills, it is recorded in
the save and the pause menu's Quit to Title question name it, but nothing sends you to it; a Continue opens the room and entry of the
LAST SAVE, which right after a checkpoint is the checkpoint, and after clearing another room is that room. The
"Chơi thử" steps are the ones the rooms allow today, in order, from a clean save (T1 and T2 have no enemy, Stage 1 has no
gate, and the floor-weapon step is done in B1 with the Ruler Blade because step 3 has already cleared T4);
`tests/bridge/test_owner_guide_steps.gd` walks them with the arrow keys and brings every pawn down with the real sword (walk
beside it, face it, press attack: a pawn the sword cannot reach fails the test), keeping one stand-in, the one point wound
of step 3. Steps 1-3 can be done once per save, because a cleared room is empty for good: to repeat them, delete the save
(below). T4's Backstep Pawn and Pencil Spear used to be parked on a wall cell, so T4 could never be cleared and its east
door never opened; they stand on floor now, and `tests/content/test_room_markers_on_floor.gd` boots every room and checks
that every pawn, pickup, unlock and gate is on ground the pawn can use. The game saves only on a success event (a
room cleared, a hub or boss door, the sword, a first meeting with a piece, an opened gate, a persistent pickup), never
on a death or a plain trip. The save file is `saves/slot_0.cfg` (+ `.bak`) in the project's user data folder (macOS:
`~/Library/Application Support/Godot/app_userdata/The Unbound Pawn/`; Godot: Project -> Open User Data Folder);
choose New Game on the title (it asks, then writes the clean run over the slot and keeps the old save as the `.bak`) or delete both to start clean. The plan says both "back to the latest checkpoint" and "only the current room resets"; the
least punishing reading was built, recorded in `docs/game-base-plan.md` 5.2, and flipping it is a small change if you
disagree. To make a room a checkpoint, tick Checkpoint On Entry on its root node; to make a floor pickup a reward that
never comes back, tick Persistent on its PickupSpawnPoint.*

## 8. Chữ trong game (.po) và font (The words of the game, and the fonts)

**Một câu tóm tắt.** Mọi chữ người chơi đọc nằm trong bốn file `.po` ở `content/story/text/en/` (tiếng Anh, bản gốc).
Scene, `.tres` và code chỉ giữ **mã** của dòng (ví dụ `UI_PAUSE_RESUME`), không giữ chữ. Muốn đổi một câu: sửa dòng đó
trong file `.po`, lưu, chạy game. Không cần import, không cần sửa code.

**Bốn file, mỗi file một mảng** (cùng tên trong `en/` và `vi/`):

| File | Chứa | Mã bắt đầu bằng |
|---|---|---|
| `ui.po` | màn title, menu pause, HUD, kết quả phòng, các câu trên dòng trạng thái ("The pawn is hit..."), tên ngôn ngữ | `UI_`, `MSG_`, `PROMPT_` |
| `rooms.po` | tên phòng (hiện trên thẻ save và khi hỏi thoát), câu khi bước vào phòng, câu của cửa đang khoá, câu khi nhặt kiếm | `ROOM_` |
| `skills.po` | tên kỹ năng (Wooden Sword, Pencil Thrust) và vũ khí (Pencil Spear, Ruler Blade) | `SKILL_`, `ITEM_` |
| `story.po` | Book of House Rules (nhãn và các trang), tên các quân, credits; sau này là thoại và truyện | `BOOK_`, `PAGE_`, `ENEMY_`, `CHAR_`, `CREDIT_`, `DLG_`... |

**Sửa một dòng và thấy nó trong game (từng bước):**

1. Mở file `.po` bằng trình soạn thảo văn bản bất kỳ (VS Code, hoặc TextEdit ở chế độ văn bản thuần). Mỗi dòng trông thế này:

   ```text
   #. surface=pause menu button; purpose=close the menu and go back to the room
   msgid "UI_PAUSE_RESUME"
   msgstr "Resume"
   ```

   Dòng `#.` là ghi chú nói dòng này hiện ở đâu và để làm gì (cho người viết). `msgid` là **mã**: đừng sửa, vì scene và
   code tìm chữ theo mã này. `msgstr` là **chữ hiện trong game**: sửa phần trong dấu ngoặc kép.
2. Tìm dòng cần sửa: gõ chữ tiếng Anh bạn thấy trong game ("Resume") hoặc mã (`UI_PAUSE_RESUME`) vào ô tìm kiếm của trình soạn thảo.
3. Sửa, ví dụ `msgstr "Back to the game"`. Giữ nguyên mọi phần trong ngoặc nhọn như `{room}`, `{attack}`: game tự điền chỗ đó.
   Xuống dòng trong một câu viết `\n`; dấu ngoặc kép trong câu viết `\"`.
4. Lưu file, rồi chạy game (F5). Godot đọc lại các file `.po` mỗi lần chạy. Mở đúng chỗ có dòng đó (ví dụ bấm `Esc` trong
   game để thấy menu pause) và xem.
5. Đừng xoá dòng `msgstr` hay để nó rỗng: một dòng rỗng làm game hiện **mã** thay vì chữ (bài test `test_po_domains_merge` đỏ).

**Thêm một câu mới.** Thêm một khối ba dòng (`#.`, `msgid`, `msgstr`) vào cuối đúng file (theo bảng trên), với mã viết hoa có gạch
dưới và bắt đầu bằng đúng tiền tố của file. Rồi điền mã đó vào ô chữ trong Inspector (ví dụ **Room Message** hay **Locked Message** của
một phòng, **Title** của một trang Book). Bài test `test_text_keys` đỏ nếu bạn gõ chữ thẳng vào scene, `.tres` hay code, hoặc điền một mã chưa có dòng.

**Tiếng Việt.** Thư mục `content/story/text/vi/` có đủ bốn file nhưng **trống có chủ đích**: dòng nào chưa dịch thì game dùng tiếng Anh
(quyết định D-25: chữ gốc là tiếng Anh, tiếng Việt sau). Để dịch một dòng: chép khối `#.` + `msgid` từ file `en/` sang file cùng tên trong `vi/`, viết tiếng Việt sau `msgstr`.
Để xem tiếng Việt: trong game mở **Settings → tab Screen → Language** và chọn `Tiếng Việt` (không cần sửa project). Khi đổi ngôn ngữ, mọi chữ
đang hiện cập nhật ngay, và lựa chọn được nhớ cho lần mở sau. Ngôn ngữ mặc định là English (D-25).

**Màn Settings (Esc → Settings, hoặc Settings ở màn title).** Bốn trang, mỗi dòng đổi là có tác dụng ngay, và được lưu vào file `profile.cfg`
trong thư mục user data (chung với dấu "đã xem kết thúc"; **New Game không xoá chúng**, vì chúng là của bạn chứ không phải của lần chơi). Nút
**Restore defaults** đưa tất cả về mặc định, nút **Controls** mở bảng phím.

| Trang | Dòng | Làm gì |
|---|---|---|
| Sound | Master, Music, Sound effects, Menu sounds | âm lượng của từng bus (0 = tắt tiếng, 100% = mức đã mix) |
| Screen | Fullscreen | toàn màn hình hay cửa sổ (`F11` làm cùng việc đó) |
| Screen | Language | ngôn ngữ chữ trong game, đổi ngay không cần mở lại |
| Screen | High-contrast menus | menu và hộp thoại có nền đặc, viền sáng, chữ trắng |
| Comfort | Screen shake | cường độ rung màn hình, từ 0 (không rung) đến 100% |
| Comfort | Reduce flashing | bỏ nháy đỏ trên màn hình khi trúng đòn, bỏ nháy khi đánh, bỏ chớp của con tốt khi đang bất khả xâm phạm (cảnh báo telegraph vẫn còn) |
| Comfort | High-contrast danger marks | ô sắp bị đánh vẽ bằng viền dày và sọc, không phụ thuộc màu hay nhịp nháy |
| Comfort | Turn / Guard / Focus: press to switch on and off | thay vì giữ phím, bấm một lần để bật và một lần nữa để tắt (Guard và Focus ghi **(coming later)**: hai phím đó chưa làm gì tới M8a) |
| Assists | Warning time, Enemy pace, Extra Courage, Input forgiveness | các tuỳ chọn làm game dễ hơn (D-22): tên trung tính, **không bao giờ tự bật**, đổi lúc nào cũng được; mặc định là game chuẩn. Mỗi dòng hôm nay ghi **(coming later)**: giá trị được lưu nhưng chưa hệ thống nào đọc nó |

Menu pause có thêm mục **Assist options** mở thẳng trang Assists, luôn có từ lần chơi đầu tiên (không phải thứ game chỉ đưa ra sau khi bạn chết nhiều lần).
Hôm nay các tuỳ chọn Assists đã chạm tới thế giới game (`world.tuning`) nhưng chưa hệ thống nào đọc chúng: kẻ địch chưa đổi nhịp và Courage chưa
tăng (đó là việc của M7b, M8a và M8c, ghi trong `ecs/components/tuning.gd`), nên mỗi dòng đó (và Guard, Focus) có chữ **(coming later)** bên cạnh, như bảng Controls làm
với một phím chưa làm gì; bài `test_settings_coming_later` bắt lỗi nếu chữ đó sai (một hệ thống đã đọc mà còn ghi, hoặc ghi cho thứ đã chạy). Nếu thấy dòng "These settings could not be saved" trên màn Settings: file `profile.cfg` là của một bản game mới hơn nên bản này không ghi đè; thay đổi chỉ sống tới khi tắt game. Âm lượng, rung, nháy, tương phản, ngôn ngữ, toàn màn hình và bật/tắt
giữ phím thì đã có tác dụng thật. "Giữ hay bật tắt" cho thao tác giải cứu sẽ có cùng với việc giải cứu (M6).

**Bảng Controls (Esc → Controls, hoặc nút Controls trong Settings).** Ba trang (Moving, Acting, Game), mỗi hàng một phím của game, hai cột Keyboard và
Gamepad. Bảng **đọc thẳng từ InputMap** mỗi lần mở: đổi một phím trong `project.godot` là bảng đổi theo, không phải sửa gì khác. Phím nào chưa làm gì thấy được
(ví dụ `R` gọi đứa trẻ) có chữ **(coming later)** bên cạnh; hai ô kỹ năng 3 và 4 (khai báo nhưng chưa dùng) bị ẩn.

**Hình phím và nút tay cầm (glyph).** Game chọn bộ hình theo thiết bị bạn vừa dùng (bàn phím hay tay cầm) và đổi ngay khi bạn chuyển. Hình là của bạn, không ai tải về hộ:
bạn tải bộ **Input Prompts Pixel** (Kenney, giấy phép CC0) về một thư mục ngoài dự án, chép từng tile 16x16 (bản sáng, không đổi màu hay phóng to) vào
`assets/ui/glyphs/keyboard/` hoặc `assets/ui/glyphs/gamepad/` với đúng tên file trong danh sách asset (nhóm `glyphs_kenney` ở `docs/assets/spec/ui_story.json` ghi sẵn
tile nào đặt tên gì). **Chưa có file thì game hiện chữ**: `[Space]`, `[W]`, `[A]`, `[LB]`, `[Left Stick Up]`, đọc được ngay. Chép file vào rồi mở dự án trong Godot một lần
cho nó import; chép đè là đổi hình. Khi thêm file, ghi bộ này vào `THIRD_PARTY_NOTICES.md` (mục "Input glyphs (owner-supplied)" ở đó nói cách làm).

**Thử độ dài chữ.** Có một "ngôn ngữ giả" `qps` làm mọi dòng dài hơn 40% và thêm dấu: bài test `test_layout_pseudo_locale` dùng nó để kiểm
không dòng nào tràn khỏi ô của nó ở HUD, title, menu pause, màn Settings và bảng Controls. Ngôn ngữ giả này cũng nằm trong danh sách ngôn ngữ của màn Settings (tên "Pseudo-language (test)"), nhưng chỉ khi chạy bằng editor hoặc bản debug, không có trong bản phát hành: chọn nó là thấy ngay chữ dài hơn và có dấu. Tiếng Việt chỉ hiện trong danh sách khi một trong bốn file `vi/*.po` đã có ít nhất một dòng `msgstr`. Bản dịch tiếng Việt thường dài hơn tiếng Anh, nên nếu bạn
thấy một câu dịch bị cắt, hộp chứa nó cần rộng hơn.

**Font chữ: đặt file ở đâu.** Bạn tự cung cấp font (quy tắc của dự án: không ai tải font về hộ). Đặt file vào thư mục `assets/fonts/` **đúng tên này**
(tên lấy từ danh sách asset, nhóm `fonts_ui`; ghi đè file cùng tên là đổi font):

| File | Dùng cho |
|---|---|
| `assets/fonts/ui_body_pixel.ttf` | font chính: menu, thoại, Book, chữ trên HUD (danh sách asset gợi ý VT323, giấy phép OFL) |
| `assets/fonts/ui_small_pixel.ttf` | số trên HUD, số đếm hồi chiêu (gợi ý Tiny5) |
| `assets/fonts/ui_title_pixel.ttf` | tiêu đề (không bắt buộc) |
| `assets/fonts/child_hand.ttf` | chữ viết tay của đứa trẻ, từ M6 (không bắt buộc) |

Chưa có file nào thì game dùng font mặc định của engine (đã kiểm: nó có đủ 134 chữ cái tiếng Việt có dấu). Sau khi đặt file:

1. Mở dự án trong Godot một lần để nó import font. Chọn file trong FileSystem, mở tab **Import**, với font pixel đặt *Antialiasing* = Disabled, *Hinting* = Disabled (hoặc Normal), *Subpixel Positioning* = Disabled,
   và dùng cỡ chữ là bội số nguyên của lưới font (VT323 vẽ trên lưới 16 px, nên dùng 16 hoặc 32); bấm **Reimport**.
2. Chạy game: font mới được dùng ngay. Không phải sửa gì khác (theme `content/ui/theme/theme.tres` đã ghi sẵn bốn đường dẫn trên).
3. **Kiểm tiếng Việt:** chạy `python3 tools/run_all_tests.py --only test_font_vietnamese_coverage`. Bài test đỏ nếu font bạn đặt thiếu dù chỉ một trong 134
   chữ cái tiếng Việt có dấu (kể cả các chữ chồng dấu như ệ, ẫ, ờ, ữ, ặ). Bước duy nhất không máy nào kiểm được là mắt bạn: nhìn xem
   chiều cao dòng và khoảng trống cho dấu chồng ở cỡ chữ thật có đẹp không.
4. Thêm giấy phép của font vào `THIRD_PARTY_NOTICES.md` (một mục `###` mới có dòng `- **License:**` và nguyên văn giấy phép trong khối `text`; mục "UI fonts (owner-supplied)" ở
   đó nói rõ), rồi chạy `godot --headless --path . -s tools/build_credits_licenses.gd` để credits hiện nó.

*EN: Section 8 also holds the Settings screen. It opens from the title and from the pause menu (which also has Controls and Assist
options) and has four pages: volumes per bus; fullscreen, language and high-contrast menus; screen-shake scale, reduce flashing, high-contrast danger
and hold-or-toggle for Turn, Guard and Focus; the four assists (neutral names, never switched on for you, D-22). Changes
act at once and are kept in `profile.cfg`, which a New Game keeps. Today the assists reach `world.tuning` and no system reads them
yet (M7b, M8a, M8c), so each assist, and press-to-switch Guard and Focus, says "(coming later)" beside its row. The screen can be walked with the arrow
keys or the stick alone (down and up visit the rows in order, then Controls, Restore defaults and Back). The language list holds English and the languages whose `.po` files
hold at least one row (the generated `qps` only in a debug build or the editor). The Controls panel is built from the InputMap each time it opens, says "(coming later)" beside a key that
does nothing yet (R, the child) and shows the glyph set of the device used last. The glyph pictures are yours: copy the light
16x16 tiles of Kenney's CC0 pack 'Input Prompts Pixel' to `assets/ui/glyphs/keyboard/` and `gamepad/` under the file names of the
asset list (group `glyphs_kenney`); with no file a prompt reads [Space] or [A].*

*EN: Section 8. Every word the player reads is a row of one of four `.po` files in `content/story/text/en/` (English is the
source language, D-25); scenes, `.tres` files and scripts hold only the row's KEY. To change a line: open the file in a text
editor, edit the text after `msgstr` (never the `msgid`, keep the `{placeholders}`), save and run the game: Godot reads the `.po`
files at every launch. A new line is a three-line block added to the file of its prefix (UI_/MSG_ in ui.po, ROOM_ in rooms.po,
SKILL_/ITEM_ in skills.po, the rest in story.po), then its key goes in the Inspector field; `test_text_keys` fails on a literal
sentence or an unknown key. `vi/` has the four files, empty on purpose: a line with no Vietnamese falls back to English (to preview
Vietnamese pick it in Settings, Screen, Language, once its files have a row). The generated `qps` language
makes every line 40 percent longer for `test_layout_pseudo_locale`. Fonts are the owner's: put up to four files at the exact paths
`assets/fonts/ui_body_pixel.ttf`, `ui_small_pixel.ttf`, `ui_title_pixel.ttf`, `child_hand.ttf`; with none the engine's default font is
used (it covers all 134 Vietnamese letters); a file you add is used with no other change, must cover Vietnamese
(`test_font_vietnamese_coverage` fails otherwise), needs its licence added to `THIRD_PARTY_NOTICES.md`, and the pixel-font import
options (antialiasing and hinting disabled, an integer size) are set in the editor's Import dock.*

## 9. OG1: chơi từ title tới credits qua các phòng stub (M5)

**OG1 là một điểm dừng dành cho bạn** (`docs/game-base-plan.md` §15 và `AGENTS.md`): sau M5, game chơi được từ màn title tới credits, nhưng **chỉ là bộ khung**. Việc của bạn: chơi một lượt (khoảng **10 phút**), rồi cho
chúng tôi biết bộ khung có "đúng" không. Chưa cần chấm art, nhạc hay chữ truyện: những thứ đó chưa có. Cần biết **tuyến đường, nhịp đi, và độ dài** có hợp lý không, trước khi chúng tôi làm đầy từng khu (M6 trở đi).

### "Stub" nghĩa là gì

Một phòng **stub** là phòng mới có **hình dáng**: đúng id, đúng kích thước (16×9 ô, các phòng boss và `ub2` rộng 18×9), đúng kiểu bố cục (`layout_archetype`: `winding`, `lanes`, `stairs`, `islands`...), các cửa nối đúng phòng, và quân cờ **đúng họ** của nó
(tốt, mã, tượng, xe, hậu, vua) theo bảng §7.4 của plan. Nó **chưa** có: art của bạn (sàn tường dùng bộ tile `greybox`, mỗi loại ô một ô phẳng, hình quân là hình tạm), chữ truyện, nhạc riêng, kỹ năng mới (cửa nào plan ghi "cần Rule Step / Chalk Path /
Eraser Guard" thì **vẫn mở**, và `world.tres` ghi lời hứa: mở thật ở M7c), boss thật (**năm boss là quân một ô**, Courage 8 tới 12, đánh bằng kiếm khoảng 8-12 nhát: M8b làm boss đúng), và những thứ phải thấy mới có (tàu đồ chơi của `tb3`, tiệc trà của `dh1`).

Mỗi phòng có một **trạng thái** (`content_status`) trên node gốc: `STUB` (hình dáng), `GREYBOX` (chơi được, địch thật), `DRESSED` (đã có art tạm), `FINAL` (**chỉ bạn** đặt). Hôm nay: **34 phòng, 28 STUB, 6 GREYBOX** (sáu phòng Stage 1: T1, T2, T3, T4, B1, H1). Số đếm này in ra bằng `tools/list_placeholders.gd`
(dòng `ROOMS: 34 rooms, 28 STUB, 6 GREYBOX, 0 DRESSED, 0 FINAL`).

### Cách chơi (khoảng 10 phút)

1. Mở game (F5) → **New Game**. Bạn bắt đầu ở **T1**. (Muốn chơi lại từ đầu: New Game; save cũ thành `.bak`, mục 7.)
2. **Stage 1** như cũ: T1 → T2 (nhặt kiếm ở giữa phòng) → T3 → T4 → **B1** (Black Pawn Captain) → **H1**, cái hub. Cửa phía đông của T3, T4, B1 chỉ mở khi bạn dọn hết địch.
3. **H1 có năm cửa vào năm quận.** Chỉ cửa **Toybox** (cửa trên) mở sau B1. Bốn cửa kia **đứng yên và nói vì sao** (dòng trạng thái ở đáy): mỗi cửa chờ **boss của quận trước** ngã xuống (D-21). Đứng trước cửa đóng là cách thử câu chữ.
4. Đi **từng quận theo thứ tự**, mỗi quận có 4 phòng và một boss:
   `Toybox` (tb1, tb2, tb3, **tbb** Knight Captain, tb4) → về H1 qua **lối tắt một chiều** ở cuối quận → `Bookshelf` (bs1 tới bs4, boss Bishop Oracle) → `Block Tower` (bt1 tới bt4, boss Rook Warden) → `Dollhouse` (dh1 tới dh4, boss Queen of Tricks) → `Under-Bed` (ub1, ub2, ub3, **ubb** Black King).
   Mỗi quận: phòng dạy (một họ quân mới, có quân đứng sẵn), phòng thử, phòng lạ (đổi nhịp), phòng boss (checkpoint: vào cửa là hồi đầy Courage), rồi lối tắt. Ba phòng ngách tuỳ chọn (`tbo`, `bso`, `bto`) nằm ngoài tuyến, đi từ lối tắt của quận.
5. **Boss giả**: một quân một ô, nhiều Courage. Đánh bằng kiếm tới khi ngã: cờ `boss.<id>` được đặt, game tự lưu (`boss_defeated`), và cửa hub của quận sau mở.
6. Hết **ubb**, cửa phòng boss dẫn sang **bàn học (Desk, `e1`)**: đi tới **cửa ở cuối bàn** (cửa kết thúc, không dẫn đi đâu). Bốn thẻ chữ hiện lần lượt (Enter bỏ qua từng thẻ), rồi **credits**, rồi về **title**, nơi một ô của bàn cờ để trống (bạn đã chơi xong).

Chết không mất gì ngoài phòng vừa ngã (mục 7); **Esc** → Restart Room chơi lại phòng. Phòng đã dọn giữ sạch cả lượt chơi (D-17).

Để biết bộ khung dài bao nhiêu **khi không có gì cản**, đọc `docs/route_times.md`: một con bot chơi cả game từ title tới credits (bằng phím bấm, kiếm thật, boss bằng một đòn sát thương, địch đứng yên) và ghi **thời gian ngắn nhất của từng phòng** cạnh ước lượng của plan. Hôm nay: **khoảng 3,5 phút** cả tuyến. Con số của bạn sẽ cao hơn vì bạn đọc, đi vòng, đánh nhau
thật, và vì địch đánh lại; đó là chuyện bình thường. (Bài test chạy lại bot mỗi lần: `tests/playthrough/test_full_route.gd`, dưới 90 giây; nó chỉ ghi lại file khi con số đổi.)

### Điều cần để ý, và cách báo lại

Khi chơi, thử trả lời ba câu này (ghi một dòng cho mỗi phòng nếu có chuyện gì; **gọi phòng bằng id**, ví dụ `tb2_l_jump_lanes`, id nằm ở bản đồ in ra bên dưới; mỗi phòng có một dòng chào riêng ở đáy màn hình khi bạn bước vào, bạn chép vài chữ của nó cũng đủ):

1. **Tuyến có hợp lý không?** Thứ tự quận, việc quay về hub sau mỗi quận, cửa hub đứng yên với một lý do, lối tắt một chiều. Có chỗ nào bạn **không biết đi đâu**, hay đi một vòng vô nghĩa?
2. **Mỗi hồi có khác nhau không, ngay cả khi chỉ là stub?** Thứ **có** khác: họ quân (tốt, mã, tượng, xe, hậu, vua), hình phòng và kiểu bố cục, kích thước (phòng boss rộng hơn), nhịp (phòng dạy, thử, lạ, boss, lối tắt), dòng chào mỗi phòng. Thứ **chưa** khác: tile (cùng bộ greybox), nhạc, art, chữ truyện. Bạn thấy năm quận **có vị riêng** không, hay chỉ là năm lần cùng một thứ?
3. **Có gì gây bối rối?** Cửa khoá không rõ vì sao, phòng quá dài hay quá ngắn, boss đánh lâu quá (8-12 nhát là chủ ý của stub, nhưng cảm giác ra sao?), thiếu chỗ thở, quân đứng chỗ khó chịu, một phòng nào đó cảm giác thừa.

Và hai câu hỏi dành riêng cho bạn:
- **Under-Bed không có lối tắt về** (cửa cuối của Black King kết thúc game): giữ như vậy? (bài `test_district_loops` ghi đây là ngoại lệ có chủ ý, và sẽ báo đỏ nếu một ngày nó có vòng lặp mà ngoại lệ vẫn còn.)
- **Plan bảo mỗi quận có một phòng "phá khuôn"** (tb3 đuổi tàu, bs3 trượt trang, bt2 giữ tuyến 30 giây, dh1 tiệc trà): hôm nay chúng mới chỉ là phòng có mục tiêu khác tên (`objective_kind`), chưa chơi khác. Bạn muốn phòng phá khuôn nào được làm trước?

**Báo lại bằng cách nào:** nói thẳng trong chat, hoặc điền `docs/owner-review-template.md` (mục *Fast Verdict* và *Gameplay Feel Review* là đủ); chúng tôi ghi nguyên văn câu trả lời vào `progress.md` (như đã làm với OG0) và sửa theo. Nếu bạn **không trả lời**, các mặc định ở `AGENTS.md` (mục "Gates and defaults") vẫn đứng, chúng tôi ghi giả định đó vào `progress.md` và làm tiếp M6.

### In bản đồ thế giới

```bash
../Godot.app/Contents/MacOS/Godot --headless --path . -s tools/print_world_map.gd
```

Nó in: **MAP** (lưới 8 cột × 10 hàng; `[t1]` là phòng, chữ cái trống là chỗ của một quận: c Chess Rug, t Toybox, b Bookshelf, k Block Tower, d Dollhouse, u Under-Bed, e Desk, w Window; `-` `|` cửa hai chiều, `>` `v` `<` `^` một chiều, `x` có khoá),
**ROOMS** (id, ô trên lưới, quận, hồi, vai trò, kiểu bố cục, trạng thái, kích thước, số cửa ra/vào), **EDGES** (mỗi cửa dẫn đâu), **LOCKS** (câu mỗi khoá nói), **ROUTE** (đi từ T1 theo thứ tự boss ngã) và một dòng cuối nói `WorldCheck` thấy gì sai (không thấy gì thì ghi sạch).
`tools/print_world_map.gd` chỉ đọc, không sửa gì.

### Thêm hoặc sửa một phòng bằng `build_room`

1. **Phòng mới:** chép bản vẽ của một phòng gần giống (`tools/layouts/tb2_l_jump_lanes.txt` chẳng hạn) thành `tools/layouts/<id_mới>.txt`. Đổi `[room]` (id **bằng tên file**, `act`, `district`, `archetype`, `recipe`, và từ M5 bước 3 các khoá của phòng: `objective`, `threat`, `shapes`, `intro`, `intensity`; `name` và `start` là chữ tiếng Anh), vẽ `[grid]` (mỗi ô một ký tự: `.` sàn, `#` tường, `o` hố, `+` khối nhảy qua được, `=` phấn, `~` sàn hỏng, chữ hoa là cửa/điểm vào/địch ghi ở `[objects]`), rồi liệt kê đồ vật ở `[objects]`.
   In bảng ký hiệu đầy đủ bằng `tools/build_room.gd -- --legend`.
2. `tools/build_room.gd -- --check` kiểm mọi bản vẽ (không dựng gì), rồi `tools/build_room.gd -- --room=<id_mới>` dựng `content/rooms/<id>/room.tscn` (chữ, có uid, tô từng tile từ `greybox`) và thêm các dòng chữ tiếng Anh vào `rooms.po`.
   Lệnh **từ chối ghi đè** một scene đã có: scene mà bạn đã sửa trong Godot là bản đúng. `--force` chỉ dựng lại scene mà **chính tool đã dựng và chưa ai sửa** (`tools/layouts/built_rooms.json` ghi mã băm), nên chỉnh bản vẽ rồi `--force` là cách sửa nhanh một stub chưa ai đụng.
3. Chạy import một lần (`../Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit`) và `tools/stamp_uids.gd -- --check` (phải ghi `STAMP UIDS: CLEAN`); commit scene, dòng `.po`, file `.import`/`.uid` mới và `built_rooms.json` cùng nhau.
4. **Nối phòng vào thế giới**: mở `content/world/world.tres` trong Godot, thêm một `WorldRoom` (id, scene, ô trên lưới `map_slot` nằm trong vùng của quận) và các `WorldEdge` cho **mỗi cửa** (cửa `from_room/door` dẫn tới `to_room/to_entry`); ở phòng bên cạnh, thêm node cửa (`ZoneExitMarker`) và điểm vào. `tests/content/test_world_graph.gd` đỏ và nêu đúng chỗ nếu thiếu, và `tools/print_world_map.gd` cho bạn thấy phòng mới nằm đâu.
5. **Sửa một phòng đã có:** mở `room.tscn` trong Godot và kéo node (từ lúc đó scene là bản đúng, bản vẽ không còn mô tả nó). Nếu phòng còn là stub chưa ai sửa, sửa bản vẽ rồi `--force` cũng được.
6. Chạy `/verify`. Bảy bài lint của M5 sẽ nói nếu phòng của bạn phá một luật của plan: ngân sách đe doạ (phòng dạy tối đa 3, phòng thử và phòng lạ từ 3 tới 6; phòng trước boss thấp hơn boss), quân mới phải được xem trước ở dạng "rào" (R27), mỗi quân phải có chỗ đứng (§5.3), hai phòng liền nhau trên tuyến không cùng kiểu bố cục, mỗi quận có vòng lặp hoặc lối tắt, mỗi sáu phút tuyến chính có một phần thưởng giữ mãi.
   Bài nào chưa thể kiểm trên phòng stub chỉ **in một dòng `REPORT`** và nói khi nào nó thành bắt buộc, chứ không đỏ.

*EN: Gate OG1 (section 9): play from the title to the credits through the stub rooms, about ten minutes, and tell us whether the skeleton feels right. A **stub** is a room that has only its shape: the plan's id, size, layout archetype, the doors to its neighbours and a piece of each family it should hold, in the flat greybox
tiles; it has no art, story text, music or new skills (a door that "needs Rule Step" is open until M7c) and the five bosses are one-cell stand-ins with 8 to 12 Courage. 34 rooms: 28 STUB and 6 GREYBOX (Stage 1). The route: Stage 1 to the hub, then the five districts in order (each hub door waits for the boss before it and says so), the Desk's last door, four cards, the credits, the title with an empty square.
`docs/route_times.md` is what a bot needs at the least (about 3.5 minutes; written by `tests/playthrough/test_full_route.gd` every run, only when it changed). We want three answers: does the route make sense, does each act feel distinct even as stubs (what differs is the family, the shape, the size and the beat; what does not is the tiles, the music and the words), and what is confusing
(and two questions of yours: keep the Under-Bed one-way, and which format-breaker first). Tell us in chat or in `docs/owner-review-template.md`; the answer is recorded verbatim in `progress.md`. To print the map: `tools/print_world_map.gd` (MAP, ROOMS, EDGES, LOCKS, ROUTE and the checks line). To add or edit a room: a layout in `tools/layouts/`,
`tools/build_room.gd -- --room=<id>` (never overwrites a scene that exists; `--force` only for a scene the tool built and nobody edited), the import pass, the stamp check, then a `WorldRoom` and its `WorldEdge`s in `content/world/world.tres` and the doors in the neighbouring scenes; `/verify` runs the seven lints.*

## 10. Từ điển nhỏ (Glossary)

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
| gate (OG0-OG4) | điểm dừng để bạn duyệt hoặc chơi thử trước khi làm tiếp (OG1 là mục 9) |
| stub | phòng mới có hình dáng (id, kích thước, kiểu bố cục, cửa, quân đúng họ), chưa có art, chữ truyện, nhạc hay kỹ năng; `content_status` của nó là `STUB` (mục 9) |
| lint | bài test kiểm một luật của plan trên bảng §7.4 (ngân sách đe doạ, xem quân trước khi bị đánh, thưởng đều...). Mỗi lint được chứng minh là **có thể đỏ**; bài nào chưa kiểm được trên stub chỉ in một dòng `REPORT` và nói khi nào nó bắt buộc |
| route bot | con bot trong `tests/playthrough/` chơi cả game từ title tới credits bằng phím bấm và ghi thời gian ngắn nhất của từng phòng vào `docs/route_times.md` |
| `threat_points` | điểm đe doạ một quân cộng vào ngân sách của phòng (tốt 1, mã và tượng 3, xe 4; boss: ngân sách pha 1 của nó), nằm trong `enemy.tres` |
| `ContentDb` | sổ đăng ký nội dung của game: tra mọi thứ trong `content/` theo id (tên thư mục), và có hai hàm kiểm tra (`validate()`, `validate_cross_refs()`) mà các bài test chạy để chắc mọi file hợp lệ và mọi tham chiếu trỏ tới một id có thật. Bạn không phải gọi nó |
| `actor_view_base.tscn` | **một** cảnh duy nhất vẽ mọi con tốt/enemy (`presentation/views/actors/`); enemy mới chỉ cần kéo cảnh này vào phòng rồi đặt `definition`. `player.tscn`, `black_pawn.tscn`, `knight_enemy.tscn`, `bishop_enemy.tscn` là cảnh mỏng kế thừa nó |
| `PlayerDefinition` | file `content/player/player.tres`: mọi con số của con tốt (Courage, thời gian bước, hồi chiêu...) |
| checkpoint | cửa hub hoặc phòng boss mà con tốt đi qua (bật **Checkpoint On Entry** trên phòng): hồi đầy Courage, game ghi lại và lưu. Chết **không** đưa bạn về đó, mà về ô vào của phòng vừa ngã (mục 7) |
| phòng đã dọn (cleared room) | phòng mà mục tiêu đã xong (mặc định: hết địch); nó giữ sạch cho tới hết lần chơi (D-17) |
| persistent pickup | vật nhặt là phần thưởng giữ mãi (**Persistent** bật trên `PickupSpawnPoint`); mọi vật nhặt khác là vũ khí rơi của phòng và về chỗ cũ khi phòng bắt đầu lại |
| base line / `body_box` | vạch đáy của quân (14 px dưới tâm ô) và hộp lớn nhất của hình, trong `content/feel/piece_sizes.tres` (mục 6) |
| key (mã chữ) | tên viết hoa có gạch dưới của một dòng chữ, ví dụ `UI_PAUSE_RESUME`. Scene, `.tres` và code giữ mã; chữ thật nằm trong file `.po` (mục 8) |
| `.po`, `msgid`, `msgstr` | file chữ kiểu gettext: `msgid` là mã (đừng sửa), `msgstr` là chữ hiện trong game (sửa ở đây). Dòng `#.` phía trên là ghi chú cho người viết |
| widget (mảnh HUD) | một phần của HUD có scene và script riêng trong `presentation/ui/hud/widgets/` (chấm Courage, ô kỹ năng, số địch...). Nó chỉ vẽ những gì `HudSnapshot` nói, và chỉ vẽ lại khi có gì đổi |
| dải trên, dải dưới (strip) | hai vùng của khung 640×360 dành cho HUD: y 0-32 và y 326-360. Bàn cờ nằm giữa (y 36-324 với bàn 18×9), nên HUD không bao giờ che ô nào. Bài `test_hud_safe_zone` giữ điều đó |
| chỗ để dành (reserved slot) | mảnh HUD đã có scene và đã có chỗ trong dải nhưng ẩn và chưa vẽ gì, để milestone sau điền vào mà không phải dời mảnh khác (Believe: M10, thanh boss: M8b) |
| debug readout | dòng số liệu cho người làm game (ô con tốt đang đứng, hướng nhìn, địch nào đánh tiếp), chỉ hiện sau khi bấm `F3` và thế chỗ dòng gợi ý phím |
| snap (đặt đúng pixel) | camera luôn đặt hình bắt đầu đúng trên một pixel của thế giới, và quân cờ đang trượt giữa hai ô luôn được vẽ trên pixel nguyên, để hình pixel art không bị nhoè giữa hai pixel khi camera đuổi theo, rung hay quân đi (`test_camera_snap`, `test_piece_slide_snap`) |
| `qps` | "ngôn ngữ giả" do game tự sinh: mọi dòng dài hơn 40% và có dấu, để thử xem chữ dài có tràn khỏi ô không (mục 8) |
