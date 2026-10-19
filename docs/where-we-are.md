# Bạn đang ở đâu — The Unbound Pawn

**Kiểm tra ngày:** 2026-10-12, trên cây làm việc hiện tại (branch `room-at-pawn-scale`
và khoảng 130 file chưa commit).
**Cách kiểm:** 22 agent đọc lại toàn bộ docs, sau đó đối chiếu từng mục với code,
scene, resource và asset thật. Mỗi kết luận được một agent thứ hai cố bác bỏ, và
một agent cuối đi tìm phần còn sót. Không file nào bị sửa trong lúc kiểm.

Trang này trả lời hai câu: **làm việc theo quy trình nào**, và **mỗi mảng của game
đang ở bước nào**. Các doc khác giữ chi tiết; trạng thái đọc ở đây.

> **Ghi chú cuối M1b (2026-10-12):** các mục dưới đây là ảnh chụp trạng thái ngày 2026-10-12 trước khi
> dựng bản base, và không đổi về gameplay. Chỉ có **đường dẫn** là đã đổi: cây thư mục mới
> (`content/`, `schema/`, `ecs/`, `authoring/`, `presentation/`, `shell/`) nằm trong
> `docs/ARCHITECTURE.md`; cảnh chính nay là `shell/game_root.tscn` (trước đây `main.tscn`); bảng cũ → mới
> nằm trong `docs/migration-notes.md`. Tiến độ xây bản base: `docs/game-base-plan.md` và `task_plan.md`.
>
> **Ghi chú M4 bước 1 (2026-10-19):** cảnh chính nay là `shell/app_root.tscn` (không còn `shell/game_root.tscn`): game mở
> bằng **màn title** (New Game, Continue khi có save đọc được, Credits, Quit; Settings tạm xám), có credits đọc
> `content/story/credits.tres`, dấu tick nhỏ mỗi khi game tự lưu, số phiên bản, và một dòng báo khi save bị hỏng hoặc của
> bản game mới hơn. Chọn New Game thì lần chơi mới được ghi đè lên save ngay (có hỏi trước). Xem `docs/OWNER_GUIDE.md` mục 1 và 7.
>
> **Ghi chú M4 bước 2 và 3 (2026-10-19):** có menu pause (`Esc`/`Start`; Restart Room hỏi xác nhận; `R` là phím gọi đứa trẻ, chưa
> làm gì thấy được) và, ở bước 3, **mọi chữ trong game nằm trong file `.po`** (`content/story/text/en/`; sửa một dòng rồi chạy
> lại là thấy), **chỗ đặt font** (`assets/fonts/`) và **chỗ đặt glyph phím** (`assets/ui/glyphs/`) của bạn, **màn Settings** (title và menu pause: âm lượng,
> rung màn hình, nháy, tương phản, toàn màn hình, ngôn ngữ, assists, bật/tắt thay vì giữ phím) và **bảng Controls** đọc từ InputMap. HUD mới là bước 4. Xem
> `docs/OWNER_GUIDE.md` mục 8.
>
> **Ghi chú cuối M2 (2026-10-13):** M2 cũng không đổi luật chơi. Đổi ở phần hiển thị và dữ liệu: **quân cờ giờ nhỏ
> hơn ô** theo quyết định của bạn ngày 2026-10-12 (bảng kích thước `content/feel/piece_sizes.tres`; thay phase 66, quân
> cao 1,5 ô), chỉ còn **một** cảnh actor (`presentation/views/actors/actor_view_base.tscn`) thay cho bốn bản chép,
> con số của con tốt nằm ở `content/player/player.tres`, và có sổ đăng ký nội dung `ContentDb`. Xem kết quả:
> `assets/_generated/previews/pieces_in_cells.png`; cách đọc nó và cách đổi cỡ: `docs/OWNER_GUIDE.md` mục 6. Số bộ test
> bây giờ là 35 (không còn "7 bộ" như bên dưới).

---

## 1. Tóm tắt trong 30 giây

```text
Concept ─ Prototype ─ [ BẠN Ở ĐÂY ] ─ Vertical slice ─ Production ─ Alpha ─ Beta ─ Release
                         │
                         └─ Stage 1 (T1→T2→T3→T4→B1→H1) đã dựng dạng greybox,
                            agent đã tự kiểm, NHƯNG bạn chưa chơi duyệt lần nào,
                            và toàn bộ chưa được commit.
```

- **Prototype cơ chế lõi: xong và đã commit** (đến 2026-08-04): ECS, đi 1 ô, kiếm gỗ,
  Pencil Thrust, họ quân Tốt, lưu game, Sách Luật Nhà, âm thanh tạm, một bản build macOS.
- **Stage 1 chạy được trên máy bạn**: 7 bộ test xanh (235 PASS, 0 lỗi), `main.tscn` khởi
  động vào T1. Tuy vậy các phòng T3→H1 mới là blockout, art là đồ tạm, và **chưa ai đi
  hết T1→H1 rồi ghi lại kết quả**.
- **Vertical slice chưa tới.** Toybox, boss Mã, Rule Step, can thiệp của đứa trẻ và
  boss nhiều phase đều chưa có.
- **77 việc trong 13 mảng: 0 việc được chấp nhận.** Bạn chưa duyệt kết quả build nào.

### Theo đúng quy tắc 6 bước của bạn

```text
1 lên kế hoạch → 2 bạn duyệt → 3 build → 4 verify → 5 bạn chơi duyệt → 6 chấp nhận
```

| Bước | Số việc đang dừng ở đây |
| --- | --- |
| 1 · spec nháp, chờ bạn duyệt | 31 |
| 2 · spec đã duyệt, chưa build | 3 (LD.1, ART.1, NAR.1) |
| 3 · build dở | 39 — **phần lớn được build trước khi spec được duyệt** |
| 4 · build xong, agent đã verify, chưa ai duyệt | 3 (GP.2, GP.3, TOOL.5) |
| 5 · chờ bạn chơi duyệt | 1 (LD.2 = chuỗi Stage 1) |
| 6 · chấp nhận | **0** |

**Bước 5 chưa từng chạy.** Form `docs/owner-review-template.md` chưa được điền lần
nào. Đây là chỗ cả dự án đang kẹt.

---

## 2. Quy trình làm việc — một vòng cho mỗi việc

Quy tắc của bạn đúng. Kiểm tra cho thấy ba khâu bị thiếu khi chạy thật: **commit**,
**ghi lại nguyên văn câu duyệt của bạn**, và **bước bạn chơi duyệt**. Vòng dưới đây
giữ quy tắc cũ và thêm đúng ba khâu đó.

| # | Bước | Ai làm | Bằng chứng là đã xong |
| --- | --- | --- | --- |
| 0 | Mở phiên: đọc trang này và chạy `git status` | agent | không có file lạ chưa commit |
| 1 | Chọn **một** việc nhỏ ở mục 5 (lộ trình) | bạn chọn, agent đề xuất | tên việc + ID |
| 2 | Viết spec tối đa một trang: mục tiêu, phạm vi, **"xong khi…"** | agent | file spec có dòng `Status: draft` |
| 3 | Bạn duyệt bằng một câu: `duyệt GP.2` hoặc `sửa GP.2: …` | **bạn** | agent dán **nguyên văn** câu đó kèm ngày vào spec và vào trang này |
| 4 | Build đúng phần đã duyệt, không hơn | agent | scene / `.tres` / code |
| 5 | Verify: `/verify` xanh, có thêm test cho phần mới | agent | bảng pass/fail |
| 6 | **Commit và push ngay**, mỗi commit một thay đổi logic | agent (bạn cho phép) | hash commit; `git status` sạch |
| 7 | Bạn mở Godot, chơi thử, điền form review | **bạn** | form đã điền: duyệt / duyệt kèm sửa nhỏ / sửa lại / chặn |
| 8 | Sửa cho tới khi bạn nói **"chấp nhận"**, rồi cập nhật trang này | cả hai | dòng của việc đó trong trang này ghi `6 · chấp nhận` |

Ba luật đi kèm:

- **Không để qua đêm mà chưa commit.** Hiện có hơn một tháng việc chỉ nằm trên một ổ đĩa.
- **Agent tự kiểm không thay được bước 7.** Ngày 2026-10-05 agent chạy bốn vòng
  "self-review" rồi ghi "review loop complete". Bốn vòng đó không phải là bạn duyệt.
- **Trạng thái chỉ ghi ở một chỗ** (đề xuất là trang này — xem quyết định số 9). Hiện
  cùng một trạng thái đang được ghi ở 7 nơi, dùng 5 bộ từ vựng và 8 cách đánh số khác
  nhau, và các nơi đó mâu thuẫn với nhau.

---

## 3. Từng mảng đang ở đâu

"Thực tế" nghĩa là đã mở file ra kiểm, không phải đọc dòng trạng thái trong docs.
Trạng thái từng việc (77 ID) nằm ở phụ lục cuối trang.

| Mảng | Thực tế đang có | Thiếu lớn nhất | Bước tiếp — ai làm |
| --- | --- | --- | --- |
| **Gameplay** (GP) | Đi 1 ô (giữ phím lặp, buffer, Shift xoay tại chỗ), kiếm gỗ, Pencil Thrust, chết thì reset phòng, nhặt kiếm ở T2 mới chém được | khoá di chuyển khi chém, Rule Step và skill khác, can thiệp của đứa trẻ (chỉ có spec), checkpoint thật | **Bạn** chơi T1→T3 khoảng 5 phút rồi chốt cảm giác: 0.18 s/bước, 0.22 s lặp, chém có khoá chân không |
| **Level / World** (LD) | 6 phòng Stage 1 nối trong `world_graph.tres`, game khởi động vào T1 | T3→H1 chỉ là blockout; H1 chưa có tuyến bị khoá; **ba mô hình thế giới đang chạy song song** (mục 4, quyết định 2) | **Bạn** chốt mô hình thế giới, sau đó chơi duyệt S1.1→S1.5 |
| **Enemy / Boss** (EN) | Họ Tốt (Recruit, cầm vũ khí, Backstep, Charging, Captain) có trong phòng | Mã và Tượng chỉ là data, không phòng nào dùng, không có test hành vi; chưa có Xe, Hậu, Vua; chưa boss nào có phase | **Bạn** chốt Mã và Tượng đi theo luật cờ (như code) hay đi 1 ô (như spec) |
| **Art** (ART) | Nhân vật đang dùng sprite tạm từ tháng 7. T1/T2 có nền PNG do script vẽ. T3→H1 dùng tile cẩm thạch và polygon | Bộ quân cờ v13 bạn đã duyệt (tháng 8) và bộ 47 vật liệu tile **chưa được gắn vào scene nào**. Pipeline vẽ tay: bạn chưa vẽ món nào | **Bạn** chọn một look, và một cách làm cho mỗi loại asset (vẽ tay / generator / lai) |
| **Animation** (AN) | AnimationTree trên 5 actor; hero gần đủ clip; clip "wake" chờ duyệt từ tháng 7 | Clip là tween transform, chưa có animation theo frame. Enemy không bao giờ vào được state attack (thiếu cạnh telegraph→attack). Chưa có animation cho boss, vũ khí, can thiệp | **Bạn** mở `player.tscn` xem các clip, chốt phase 78 và AN.1 |
| **VFX** (FX) | Ô cảnh báo đỏ, rung camera, nháy khi trúng đòn, clip gục ngã | Chưa có particle, hit-stop hay tuỳ chọn tắt rung. Ánh sáng của vật nhặt được đang dùng màu đỏ, trùng màu nguy hiểm | **Bạn** xem telegraph của Tốt ở T3 rồi duyệt hoặc sửa FX.1 |
| **Audio** (AU) | 10 SFX chiptune và 1 bản nhạc march (script Python sinh), SfxManager, bus layout | Bus SFX có thể đang bị gộp vào Master (chưa kiểm khi chạy); chưa có âm thanh can thiệp | **Bạn** nghe ở T2/T3, chốt hướng: giữ chiptune tạm hay chuyển sang âm chất liệu đồ chơi |
| **UI / UX** (UI) | HUD, Sách Luật Nhà (phím B) | Game vẫn chạy khi đang mở sách. **Chưa có menu tiêu đề, pause, thoát, settings hay tay cầm** | **Bạn** quyết có kéo pause/settings (UI.4) lên sớm không, vì người chơi thử hiện không pause hay thoát được |
| **Narrative** (NAR) | NAR.1 (cốt truyện) duyệt trên giấy; mỗi phòng có một câu thoại viết cứng trong scene | Câu "đứa trẻ thì thầm: take it" ở T2 trái với flow map đã duyệt (theo flow map, đứa trẻ chỉ xuất hiện sau B1) | **Bạn** chốt giữ, sửa hay cắt câu ở T2, và khoảnh khắc đứa trẻ xuất hiện lần đầu |
| **Technical** (TECH) | ECS chạy tốt; chuyển phòng chạy; tự lưu game (WorldState) | Save khác spec: spec nói chết thì đồ nhặt được reset, code thì giữ lại. Chưa có sandbox, chưa đo hiệu năng, chưa có test đi hết T1→H1 | **Bạn** trả lời 4 câu về checkpoint và save; **agent** gộp test về một runner duy nhất |
| **Tools** (TOOL) | Generator cho quân cờ, tile, map phòng ngủ, nền Stage 1, SFX và nhạc | **Clone mới không chạy được** (mục 4). Hướng dẫn dựng phòng đã lỗi thời | **Agent** sửa — bước 2 của lộ trình |
| **QA** | 7 bộ test tự động | Chưa có checklist, chưa có nơi ghi bug, và **từ tháng 6 tới nay chưa có buổi chơi thử nào được ghi lại** | **Bạn** chơi duyệt Stage 1 — đó cũng là buổi QA.3 đầu tiên |
| **Release** (REL) | Một bản build macOS ngày 2026-07-28 | Bản build đó có trước cả thế giới lẫn Stage 1 nên đã cũ. Chưa có ảnh, trailer hay trang store | **Agent** export lại, sau khi đã commit |

---

## 4. Rủi ro ngay lúc này

| Mức | Rủi ro | Vì sao |
| --- | --- | --- |
| **Cao** | **Mất việc.** Toàn bộ Stage 1, test, khoảng 80 spec và các doc duyệt **chưa được commit** (20 file sửa + khoảng 111 file mới, làm từ 2026-09-29 đến 10-05) | chỉ nằm trên một ổ đĩa; không có stash hay bản sao nào khác |
| **Cao** | Hai branch chưa push: `room-at-pawn-scale` (hơn origin 6 commit, chưa có upstream) và `main` (hơn 1 commit) | chỉ có ở máy này |
| **Cao** | **Clone mới không chạy được.** Commit `a4613b9` (do tôi làm, tháng 9) đã bỏ track `assets/sprites/generated/` với lý do "script build lại được". Lý do đó sai với 12 sprite gốc (`hero_pawn`, `toy_sword`, `black_pawn`, `black_knight`, `pencil_spear`, `ruler_blade`, `health_pip_*`, `facing_arrow`, `warning_aura`, `toy_weapon_pickup`, `hero_pawn_unarmed`): không script nào sinh ra chúng | trên branch này git track 0 file ở đó. Một bản sao thử trong `/tmp` lỗi ngay ở `Resource file not found: …toy_sword.png` |
| **Cao** | `hero_pawn_unarmed.png` (Stage 1 đang dùng) **chưa từng có trong commit nào** và không có generator | mất đĩa là mất file |
| Trung bình | Nền T1/T2 phụ thuộc vào output bị gitignore của một tool chưa commit (`tools/generate_stage1_room_art.gd`) | README không có lệnh build lại |
| Trung bình | **Ba mô hình thế giới, hai tỉ lệ:** (a) kingdom 72×40 trên `main` — cửa ra của H1 vẫn dẫn về đây; (b) Stage 1: 16×9 ô, 32 px; (c) phòng ngủ pawn-scale 128×96 ô, 1 ô = 1.5 inch — **không scene nào dùng** | chưa doc nào nối ba mô hình với nhau |
| Thấp | File save trong máy có thể làm game khởi động sang phòng khác thay vì T1 | muốn test từ đầu thì xoá `user://saves/slot_0.cfg` (từ M3b; trước đó là `user://world_state.cfg`) |

---

## 5. Lộ trình tới vertical slice — làm theo thứ tự

| # | Việc | Ai | Xong khi |
| --- | --- | --- | --- |
| 1 | **Cất việc vào nơi an toàn**: chọn chiến lược branch (Stage 1 không nên nằm trong `room-at-pawn-scale`), commit theo nhóm logic (doc tách riêng code, không đưa `.mcp.json`), rồi push | cả hai — **cần bạn cho phép** | `git status` sạch; branch nào cũng có upstream |
| 2 | **Clone mới phải chạy được**: track lại 12 sprite gốc (hoặc viết generator), commit tool vẽ nền Stage 1, bổ sung README cho đủ, gộp test về một runner | agent | giải nén một bản clone vào thư mục trống, chạy `tests/run_tests.gd` ra `0 failure(s)` |
| 3 | **Một buổi chốt quyết định**, ghi bằng lời của bạn: các mục 1→9 ở mục 6 | **bạn** | file quyết định có câu nguyên văn của bạn cho từng mục, hoặc ghi "hoãn" kèm lý do |
| 4 | **Chơi duyệt Stage 1** trong editor: xoá save trước, đi T1→H1, chết một lần, bấm R một lần; điền form cho S1.1→S1.5 và các câu về cảm giác GP.2/GP.3 | **bạn** | 5 form đã điền, mỗi form có kết luận |
| 5 | Gộp các doc kế hoạch về một trang trạng thái; sửa AGENTS.md (đang ghi "không dùng ECS" và nhắc tới file đã xoá) | agent | grep chỉ ra đúng một nguồn trạng thái |
| 6 | Sửa các lỗi Stage 1 không phụ thuộc vào gu, mỗi lỗi có test: thông báo riêng cho từng cửa bị khoá, tuyến khoá ở H1, đóng băng game khi mở sách, test đi hết T1→H1 | agent | mỗi lỗi có một test đỏ trước khi sửa và xanh sau khi sửa |
| 7 | Bạn duyệt hoặc sửa Batch 2 (cảm giác chơi), Batch 3 (luật dựng phòng) và phần cần thiết của Batch 4 | **bạn** | mỗi batch có câu duyệt nguyên văn kèm ngày |
| 8 | Viết spec rồi xin duyệt cho phần còn thiếu: hub H1 kèm bảng khoá, Toybox, phase của boss Mã, Rule Step, **một** kiểu can thiệp | cả hai | spec nào cũng có `Implementation allowed: yes` |
| 9 | Làm art cho chuỗi đầu theo cách bạn đã chọn; chụp ảnh kiểm độ dễ đọc ở 640×360 | **bạn** (+ agent) | không actor nào còn dùng sprite tạm tháng 7 |
| 10 | Dựng nội dung slice còn thiếu, từng phòng một, theo vòng ở mục 2 | agent | đi được hub → Toybox → boss Mã → Rule Step → về hub |
| 11 | Hoàn thiện phản hồi hình và tiếng: màu cảnh báo, âm riêng cho từng họ quân, enemy vào được state attack | cả hai | bạn đã nghe và xem thử ở T3 và phòng boss |
| 12 | Vỏ game đủ cho người khác chơi thử: pause, thoát, chỉnh âm lượng, tắt rung, bảng phím, màn hình kết thúc slice | cả hai | người chưa từng xem code tự chơi được từ đầu đến cuối |
| 13 | QA: smoke checklist, nơi ghi bug, kịch bản QA.5 kèm tiêu chí đạt/không đạt | cả hai | chạy hết kịch bản một lần, không còn bug chặn |
| 14 | Export, rồi cho **ít nhất 3 người ngoài** chơi thử | cả hai | 3 bản nhận xét đã được lưu |
| 15 | Bạn chơi bản export từ đầu đến cuối và chấp nhận slice | **bạn** | trang này ghi slice `6 · chấp nhận`; commit được gắn tag |

Bước 1 và 2 không cần bàn về gu, chỉ cần bạn cho phép. Bước 3 và 4 là việc của bạn,
agent không làm thay được. Mọi bước sau đều chờ hai bước đó.

---

## 6. Quyết định chỉ bạn chốt được

Xếp theo thứ tự nên chốt trước. Mỗi quyết định đang chặn những việc ghi ở cột cuối.

| # | Câu hỏi | Lựa chọn | Đang chặn |
| --- | --- | --- | --- |
| 1 | Cho commit + push không, và Stage 1 nằm ở branch nào? | branch mới tách từ `main`, hoặc giữ trên `room-at-pawn-scale` | mọi thứ |
| 2 | **Thế giới có hình dạng gì?** | (a) các phòng 16×9 ô như Stage 1; (b) một phòng ngủ pawn-scale liền mạch; (c) lai: phòng ngủ làm overworld/phông nền, phòng 16×9 làm chỗ đánh. Kèm theo: bỏ hay giữ kingdom 72×40 | Level, Art, Tech |
| 3 | Vertical slice kết thúc ở đâu? | Act 1 (T1→H1, 8–12 phút), hoặc Act 1 + Toybox + boss Mã (12–18 phút). Boss nào được tính, có cần phase không | QA.5, REL, lộ trình bước 8–15 |
| 4 | Art làm bằng cách nào, cho từng loại asset? | vẽ tay / generator / lai, áp cho phòng, đạo cụ, nhân vật, tile. Có thay sprite tạm bằng bộ v13 bạn đã duyệt không | toàn bộ mảng Art |
| 5 | T2→H1 đã được build trước khi duyệt — xử lý thế nào? | hợp thức hoá bằng một câu, hoặc rollback một phần. Có còn bắt buộc mỗi phòng một spec không. Có gộp Batch 2–5 thành ít quyết định hơn không | quy trình |
| 6 | Code đúng hay spec đúng? | khoá chân khi chém; buffer theo thời gian; Pencil Thrust dùng được từ T2; chết thì đồ nhặt được có reset không; giữ phím R không | Gameplay, Tech |
| 7 | Mã và Tượng đi thế nào? | theo luật cờ (như code, đúng hướng bạn đưa tháng 7) hay đi 1 ô (spec tháng 9) | Enemy |
| 8 | Can thiệp của đứa trẻ | chọn **một** kiểu cho slice, hoặc hoãn sau slice. Kèm theo: câu thì thầm ở T2 và nút bấm (đang trùng phím R) | GP.5, AN.5, AU.4 |
| 9 | Lấy trang này làm nguồn trạng thái duy nhất, và cho agent viết lại AGENTS.md theo đúng thực tế? | có / không | quy trình cho mọi phiên agent sau |

---

## 7. Những khía cạnh chưa mảng nào phụ trách

13 mảng hiện có chưa bao quát những thứ dưới đây:

| Khía cạnh | Hiện trạng |
| --- | --- |
| Trụ cột thiết kế, một nguồn thiết kế duy nhất | `gdd.md` (6/2026) và `full-gameplay-design-v2.md` (bản đề xuất) chưa được hợp nhất |
| Phạm vi, lịch, cut list | không có. Độ dài game ghi khác nhau giữa các doc: 90–120 phút, 12–18 phút, 8–12 phút |
| Nền tảng và thiết bị điều khiển | chỉ bàn phím, chỉ macOS (ký ad-hoc, chưa notarize nên máy Mac khác sẽ chặn) |
| New Game / Continue | game tự lưu nhưng chưa có cách bắt đầu lại sạch |
| Menu tiêu đề, pause, thoát, credits, màn hình kết thúc | chưa có màn nào |
| Settings, accessibility | chỉ có spec |
| Bản địa hoá | chuỗi chữ viết cứng trong code và scene |
| Hiệu năng | chưa đo lần nào |
| Dạy người chơi (onboarding) | chưa có gì dạy Shift-xoay, phím Q hay phím chém |
| Độ khó, cân bằng | `standard.tres` chưa chỉnh thông số nào |
| Bản quyền asset, font, credits | chưa có LICENSE; silhouette quân Mã được trace từ glyph của font hệ thống |
| Kỷ luật commit, backup | xem mục 4 |
| Người ngoài chơi thử | chưa có lần nào |
| CI | chưa có; 3 doc liệt kê 3 bộ test khác nhau |
| Phát hành, trang store | chưa chốt itch.io hay Steam |

---

## 8. Những gì chưa kiểm chắc

- **Mọi chữ "owner approved" trong docs đều do agent viết.** Không doc nào có câu
  nguyên văn của bạn. Batch 1 (2026-09-30) có thể đúng là bạn đã duyệt, nhưng repo
  không chứng minh được — xác nhận lại giúp.
- **Quyết định tự vẽ art của bạn là thật** (bạn nói trong chat ngày 2026-09-03),
  nhưng **chưa ghi vào doc nào** ngoài commit message.
- Kết quả test (235 PASS) do một agent chạy trên máy này, nơi vẫn còn các sprite bị
  gitignore. Chưa chạy bước import `--editor --quit`.
- Mọi con số độ dài chơi (8–12, 12–18, 90–120 phút) đều là mục tiêu, chưa ai đo.
- T1/T2 có thể có tường tàng hình nằm dưới nền PNG. Điều này mới suy ra từ việc đọc
  dữ liệu tile, chưa ai thấy trong game.

---

## Phụ lục — trạng thái thật của 77 việc

Bước theo quy tắc của bạn: 1 spec nháp · 2 spec đã duyệt · 3 build dở ·
4 build xong, chưa duyệt · 5 chờ bạn duyệt · 6 chấp nhận.
Chi tiết từng việc nằm trong spec cùng tên ở `docs/design/<id>-*-spec.md`.

### Gameplay

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| GP.1 | Core loop approval (paired with LD.2 first room chain) | 3 · build dở | bạn |
| GP.2 | Player movement feel | 4 · build xong, chưa ai duyệt | bạn |
| GP.3 | Basic sword combat | 4 · build xong, chưa ai duyệt | bạn |
| GP.4 | Skill system | 3 · build dở | bạn |
| GP.5 | Child intervention system | 1 · spec nháp, chờ duyệt | bạn |
| GP.6 | Failure / checkpoint rules | 3 · build dở | bạn |
| GP.7 | Progression pacing | 3 · build dở | bạn |

### Level / World

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| LD.1 | Bedroom world layout | 2 · spec duyệt trên giấy, chưa build | bạn |
| LD.2 | First room chain | 5 · chờ bạn chơi duyệt | bạn |
| LD.3 | Room template | 3 · build dở | bạn |
| LD.4 | Room formula | 1 · spec nháp, chờ duyệt | bạn |
| LD.5 | Hub design (Chess Rug Hub) | 3 · build dở | agent |
| LD.6 | District layout plans | 1 · spec nháp, chờ duyệt | agent |
| LD.7 | Shortcuts and locks | 3 · build dở | agent |

### Enemy / Boss

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| EN.1 | Pawn behavior spec | 3 · build dở | cả hai |
| EN.2 | Knight behavior spec | 3 · build dở | bạn |
| EN.3 | Bishop behavior spec | 3 · build dở | bạn |
| EN.4 | Rook behavior spec | 1 · spec nháp, chờ duyệt | bạn |
| EN.5 | Queen behavior spec | 1 · spec nháp, chờ duyệt | bạn |
| EN.6 | King behavior spec | 1 · spec nháp, chờ duyệt | bạn |
| EN.7 | Encounter recipes | 3 · build dở | cả hai |

### Art

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| ART.1 | Visual target lock | 2 · spec duyệt trên giấy, chưa build | cả hai |
| ART.2 | Tile palette list | 3 · build dở | bạn |
| ART.3 | Bedroom district art targets | 1 · spec nháp, chờ duyệt | bạn |
| ART.4 | Character sprite list | 3 · build dở | cả hai |
| ART.5 | Prop list | 3 · build dở | cả hai |
| ART.6 | Readability audit | 1 · spec nháp, chờ duyệt | bạn |
| ART.7 | Final polish pass | 1 · spec nháp, chờ duyệt | bạn |

### Animation

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| AN.1 | Player animation set | 3 · build dở | bạn |
| AN.2 | Enemy animation set | 3 · build dở | bạn |
| AN.3 | Boss animation plans | 1 · spec nháp, chờ duyệt | agent |
| AN.4 | Weapon animation set | 3 · build dở | bạn |
| AN.5 | Child intervention animation | 1 · spec nháp, chờ duyệt | bạn |
| AN.6 | AnimationTree QA | 3 · build dở | cả hai |

### VFX + Audio

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| FX.1 | Telegraph language | 3 · build dở | bạn |
| FX.2 | Hit feedback | 3 · build dở | bạn |
| FX.3 | Pickup feedback | 3 · build dở | bạn |
| FX.4 | Defeat feedback | 3 · build dở | bạn |
| FX.5 | Boss phase feedback | 1 · spec nháp, chờ duyệt | bạn |
| FX.6 | Accessibility/readability pass | 1 · spec nháp, chờ duyệt | agent |
| AU.1 | Audio identity | 3 · build dở | bạn |
| AU.2 | Movement/attack SFX | 3 · build dở | bạn |
| AU.3 | Enemy telegraph SFX | 3 · build dở | bạn |
| AU.4 | Child intervention SFX | 1 · spec nháp, chờ duyệt | bạn |
| AU.5 | Music plan | 3 · build dở | bạn |
| AU.6 | Mix pass | 3 · build dở | cả hai |

### UI + Narrative

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| UI.1 | HUD scope | 3 · build dở | cả hai |
| UI.2 | Tutorial prompt style | 3 · build dở | cả hai |
| UI.3 | Rule Book design | 3 · build dở | cả hai |
| UI.4 | Pause/settings | 1 · spec nháp, chờ duyệt | bạn |
| UI.5 | Input remap/controller plan | 3 · build dở | bạn |
| UI.6 | Accessibility options | 1 · spec nháp, chờ duyệt | bạn |
| NAR.1 | Story outline approval | 2 · spec duyệt trên giấy, chưa build | agent |
| NAR.2 | Opening script | 3 · build dở | bạn |
| NAR.3 | Child voice rules | 1 · spec nháp, chờ duyệt | bạn |
| NAR.4 | District story beats | 1 · spec nháp, chờ duyệt | agent |
| NAR.5 | Boss dialogue/behavior beats | 1 · spec nháp, chờ duyệt | agent |
| NAR.6 | Ending script | 1 · spec nháp, chờ duyệt | cả hai |

### Technical + Tools

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| TECH.2 | Room transition system | 3 · build dở | cả hai |
| TECH.3 | Save/checkpoint system | 3 · build dở | bạn |
| TECH.4 | Gameplay sandbox | 1 · spec nháp, chờ duyệt | cả hai |
| TECH.5 | Automated tests | 3 · build dở | agent |
| TECH.6 | Performance budget | 1 · spec nháp, chờ duyệt | agent |
| TOOL.2 | Room authoring guide update | 3 · build dở | agent |
| TOOL.3 | Asset import rules | 3 · build dở | agent |
| TOOL.4 | Tile editing workflow | 3 · build dở | agent |
| TOOL.5 | Review checklist template | 4 · build xong, chưa ai duyệt | bạn |

### QA + Release

| ID | Việc | Đang ở bước | Bước tiếp do |
| --- | --- | --- | --- |
| QA.1 | Smoke test checklist | 1 · spec nháp, chờ duyệt | cả hai |
| QA.2 | Room QA checklist | 1 · spec nháp, chờ duyệt | cả hai |
| QA.3 | Combat feel tests | 1 · spec nháp, chờ duyệt | bạn |
| QA.4 | Bug tracking format | 1 · spec nháp, chờ duyệt | cả hai |
| QA.5 | Vertical slice test plan | 1 · spec nháp, chờ duyệt | cả hai |
| REL.1 | Vertical slice package | 3 · build dở | agent |
| REL.2 | Screenshot plan | 1 · spec nháp, chờ duyệt | agent |
| REL.3 | Trailer capture plan | 1 · spec nháp, chờ duyệt | agent |
| REL.4 | Store/page description | 1 · spec nháp, chờ duyệt | cả hai |
| REL.5 | Final build checklist | 1 · spec nháp, chờ duyệt | agent |
