# Đề xuất sửa CLAUDE.md cho cổng OG0 (CLAUDE.md amendment proposal for gate OG0)

> **Trạng thái (Status): ĐÃ ÁP DỤNG (APPLIED) — M1b bước 4, 2026-10-12.** Bạn đã duyệt ở cổng **OG0**
> ("Đồng ý", ghi nguyên văn trong `progress.md`, mục "Owner directions and gate OG0"): chuyển toàn bộ code và
> thư mục sang cây ECS và sửa "Folder ownership" của `CLAUDE.md` cho khớp. Khi M1b đã tạo các đường dẫn mới,
> A-1 đến A-9 được áp dụng vào `CLAUDE.md`. Tài liệu này giữ lại phần "Cũ / Mới" như một bản ghi.
>
> *EN: **APPLIED in M1b step 4, 2026-10-12.** The owner approved at gate OG0 ("Đồng ý", recorded verbatim in
> `progress.md`, section "Owner directions and gate OG0"): move all code and folders to the ECS tree and amend
> `CLAUDE.md` "Folder ownership" to match. Once M1b had created the new paths, A-1 to A-9 were applied to
> `CLAUDE.md`. This file keeps the Old / New text below as a record.*
>
> **Điều chỉnh khi áp dụng (How the text differs from the proposal, English is canonical):**
> - A-1 is the proposed sentence plus two short additions: a folder name inside `content/` is the id (a leading
>   underscore is not an id), and the layer table lives in `docs/ARCHITECTURE.md`, enforced by
>   `tests/architecture/test_dependency_edges.gd`.
> - A-2, A-5 and A-9 keep the proposed text but say which part does not exist yet, so an agent does not hunt
>   for it: `HudSnapshot` and `world.commands` (M3a), `ecs/schedule/<phase>.gd` and `test_schedule_complete`
>   (M3a; until then the tick order is the list in `shell/game_root.gd`, mirrored in `tools/world_dumper.gd`),
>   `content/audio/sound_bank.tres` (not built yet).
> - A-6 is the runner, the import pass, the stamper check and `git diff --check`; `/verify` adds the two
>   `--self-test`s. The command lines were fixed once M1a had landed the tools.
> - A-7 adds four bullets: stamp before moving, move only with `tools/move_res.py`, commit the sidecars, never
>   let a headless `ResourceSaver` resave a scene (use `tools/save_keeping_uids.gd`); plus one on
>   `assets/_generated/` and the placeholder tools.
> - A-8: `/verify` and `/new-enemy` are rewritten for the new tree and `/new-sound` is listed. `/new-skill`,
>   `/new-room` and `/new-beat` are named as "still to come" with their milestones (M7a, M14, M14) because
>   the content kinds they scaffold do not exist yet.
> - Two paths in untouched rules had to follow the move: `scripts/ecs/` in the first rule is `ecs/`, and "the
>   main.gd bridge" in the sound rule is "the `shell/game_root.gd` bridge".
> - Not changed (the optional note at the end of this file): "Read first, every session" still does not list
>   `docs/where-we-are.md` or `docs/game-base-plan.md`.

Ngôn ngữ: tiếng Việt trước, tiếng Anh sau; thuật ngữ và đường dẫn giữ nguyên. **Bản tiếng Anh là bản
chuẩn.** Phần tiếng Việt do agent viết, bạn cứ sửa nếu thấy chưa đúng.

## Cách duyệt (How to approve)

Trả lời theo từng dòng, ví dụ: `duyệt A-1 đến A-9`, hoặc `duyệt A-1..A-5, A-7..A-9; sửa A-6: ...`, hoặc
`bỏ A-3`. Mỗi dòng độc lập nhau, trừ A-1, A-3, A-4, A-5 và A-9 cùng dựa vào cây thư mục mới (§13 của plan),
nên nên duyệt hoặc bỏ cùng nhau. Agent sẽ dán nguyên văn câu trả lời của bạn (kèm ngày) vào `progress.md`;
không có câu của bạn thì không có chữ "đã duyệt".

Nếu bạn không trả lời, plan quy định agent tiếp tục theo các giá trị mặc định đã nêu và ghi giả định vào
`progress.md` (plan §15, D-35). Cách đảo lại: tag `pre-restructure` và `git revert` từng commit thư mục.

*EN: Reply per row (approve, change, or drop). A-1, A-3, A-4, A-5 and A-9 depend on the new folder
tree (plan §13) and are best approved or dropped together. Agents paste your exact words and the date into
`progress.md`. With no reply, agents continue on the stated defaults and log the assumption (plan §15,
D-35). Revert path: the `pre-restructure` tag, or reverting the per-folder commits.*

**Những dòng của `CLAUDE.md` giữ nguyên (Rules that stay as they are):** "Editor-first, ECS runtime";
"parked ActorViews become entities at boot"; "a node on an instance beats the definition"; "never
duplicate a value"; "self-documenting names"; "no `_draw()` for actors"; "research before building";
"one logical change per commit".

Phần "Cũ (Old)" dưới đây là trích **nguyên văn** từ `CLAUDE.md` trước khi sửa (kèm số dòng của bản đó). Phần
"Mới (New)" là nguyên văn từ plan §2.4.

---

## A-1 — Quyền sở hữu thư mục (Folder ownership)

**Cũ (Old)** — `CLAUDE.md` lines 59-61:

~~~~text
- **Folder ownership:** `scenes/` = entry/rooms/ui only · `objects/` = reusable prefabs
  · `resources/` = `.tres` data · `scripts/` = behavior · `assets/` = raw art ·
  `tools/` = build scripts.
~~~~

**Mới (New):**

> `content/` = the owner's data, art, audio and words (zero `.gd`) · `schema/` = Resource classes · `ecs/` = simulation · `authoring/` = things dragged into scenes · `presentation/` = views and UI · `shell/` = app, save, flow · `assets/` = shared raw art and audio · `tools/` · `tests/`.

**Vì sao (Why):** cây thư mục mới đặt dữ liệu, art, âm thanh và lời của bạn vào `content/` (không có file `.gd`) để bạn sửa mà không đụng code (hướng dẫn #2b của bạn, plan D-27).
*EN: The new tree puts your data, art, audio and words in `content/` with no `.gd` files, so you can change them without touching code (your direction #2b, plan D-27).*

## A-2 — Phần hiển thị và mô phỏng (Presentation and the simulation)

**Cũ (Old)** — `CLAUDE.md` lines 33-34:

~~~~text
  - Presentation (HUD/board/camera/main.gd) consumes `drain_events()` only;
	it never reaches into the simulation.
~~~~

**Mới (New):**

> Presentation consumes `drain_events()` and the read-only `HudSnapshot`. It writes the simulation only by pushing typed requests on `world.commands`, never by setting components.

**Vì sao (Why):** hôm nay `main.gd` và bảng overlay đọc và ghi component trực tiếp; một hàng đợi lệnh có kiểu (vào) và một snapshot chỉ-đọc (ra) giữ mọi quyết định trong các system (plan D-38, milestone M3a).
*EN: Today `main.gd` and the board overlay read and write components directly; a typed command queue in and a read-only snapshot out keep every decision inside systems (plan D-38, milestone M3a).*

## A-3 — Nơi đặt EntityComponent (Editor-draggable components)

**Cũ (Old)** — `CLAUDE.md` lines 24-26:

~~~~text
  - New editor-draggable component → extend `EntityComponent` in
	`scripts/ecs/components/` (Inspector data + one `apply()`; `EcsBoot` bakes
	it at spawn; a node on an instance beats the definition; zero logic).
~~~~

**Mới (New):**

> New editor-draggable component → extend `EntityComponent` in `authoring/entity_components/`. Runtime data classes live in `ecs/components/`.

**Vì sao (Why):** hôm nay chữ "component" chỉ hai thứ khác nhau (dữ liệu runtime và node trong editor) nằm gần nhau; thư mục mới tách hai loại ra để không ai mở nhầm.
*EN: Today "component" means two different things (runtime data and editor nodes) and they sit side by side; the new folders separate them so nobody opens the wrong one.*

## A-4 — Nơi đặt state mới (New state)

**Cũ (Old)** — `CLAUDE.md` line 20:

~~~~text
  - New state → pure-data class + key const in `scripts/ecs/ecs_components.gd`.
~~~~

**Mới (New):**

> New state → a pure-data class with a `KEY` const in its own file under `ecs/components/`. `ecs_components.gd` is frozen except for edits to existing classes.

**Vì sao (Why):** khi nhiều lane làm song song, một file chứa mọi component là điểm xung đột; mỗi component mới một file thì không đụng nhau (plan §13.3, rủi ro 27).
*EN: One file holding every component is a merge hot spot for parallel lanes; one file per new component avoids it (plan §13.3, risk 27).*

## A-5 — Nơi đặt system mới (New decision or behavior)

**Cũ (Old)** — `CLAUDE.md` lines 21-23:

~~~~text
  - New decision/behavior → a system in `scripts/ecs/systems/` ticked by the
	world; ONLY `ViewSyncSystem` may touch nodes. Systems talk via components
	and the event/damage queues, never by calling each other or presentation.
~~~~

**Mới (New):**

> ... a system in `ecs/systems/<phase>/` plus one line in `ecs/schedule/<phase>.gd`. `test_schedule_complete` fails if a system file is unlisted.

(Dấu "..." thay cho phần đầu câu cũ: "New decision/behavior → ". *The leading "..." stands for the unchanged start of the sentence: "New decision/behavior → ".*)

**Vì sao (Why):** thứ tự chạy của các system hôm nay được viết cứng trong `main.gd`; đưa nó thành dữ liệu theo từng phase, kèm một test báo lỗi nếu quên đăng ký, để không system nào bị bỏ sót hay đứng sai chỗ (plan §13.4).
*EN: Today the system order is hard-coded in `main.gd`; making it per-phase data with a test that fails on an unlisted system stops systems being forgotten or misplaced (plan §13.4).*

## A-6 — Lệnh kiểm tra trước khi commit (Verify before you commit)

**Cũ (Old)** — `CLAUDE.md` lines 78-88:

~~~~text
## Verify before you commit (run from project root)
```bash
G="../Godot.app/Contents/MacOS/Godot"
HOME=/tmp/unbound-pawn-godot "$G" --headless --path . -s tests/run_tests.gd
for t in ecs_runtime ecs_combat ecs_enemy room_encounter_runtime encounter_hud_runtime zone_travel_runtime; do
  HOME=/tmp/unbound-pawn-godot "$G" --headless --path . -s tests/${t}_test.gd
done
HOME=/tmp/unbound-pawn-godot "$G" --headless --path . --editor --quit   # import clean
git diff --check                                                        # whitespace
```
Expect `TESTS COMPLETE: 0 failure(s)` + each runtime test `PASS`.
~~~~

**Mới (New):**

> `python3 tools/run_all_tests.py --strict`, then `godot --headless --path . --editor --quit`, `git diff --check`, `tools/stamp_uids.gd --check`.

(Cú pháp lệnh chính xác sẽ được chốt khi M1a thêm các công cụ này. *The exact command lines are fixed when M1a lands the tools.*)

**Vì sao (Why):** một lệnh runner thay cho vòng lặp shell, bắt `SCRIPT ERROR` và test treo, và kiểm tra không có tham chiếu chỉ-theo-đường-dẫn (path-only) làm hỏng việc di chuyển file (plan D-39, §13.7).
*EN: One runner replaces the shell loop, catches script errors and hangs, and the stamper check guards against path-only references that break file moves (plan D-39, §13.7).*

## A-7 — Lưu ý môi trường (Environment gotchas)

**Cũ (Old)** — `CLAUDE.md` lines 68-76:

~~~~text
## Environment gotchas (learned the hard way)
- The project path contains a space (`.../Personal /Games/...`). Quote paths.
- Godot binary: `../Godot.app/Contents/MacOS/Godot` (parent dir). Run headless with an
  isolated writable home: `HOME=/tmp/unbound-pawn-godot`.
- **A new `class_name` (global class) needs one `--editor --quit` import pass** before
  strict-typed scripts referencing it will parse headlessly. Run import, then tests.
- TileMap `tile_map_data` is a binary blob — do not hand-edit; use a `tools/` paint
  script (see `tools/paint_kingdom_tilemap.gd`).
- Headless `--write-movie` capture leaks RIDs at exit — that error is cosmetic.
~~~~

**Mới (New):**

> Add: stamp UIDs before moving files; move files only with `tools/move_res.py`; new `.gd` and PNG files need their `.gd.uid` and `.import` sidecars committed; headless `ResourceSaver` resaves drop UIDs.

(Các lưu ý cũ giữ nguyên; đây là phần **thêm vào**. *The existing gotchas stay; this is an addition.*)

**Vì sao (Why):** thử nghiệm cho thấy lưu lại scene bằng `ResourceSaver` trong chế độ headless làm mất UID của mọi tham chiếu (từ 213 lên 251 trên 251 dòng chỉ còn đường dẫn), nên cần ghi thành luật (plan §13.7, rủi ro 2).
*EN: A prototype showed a headless `ResourceSaver` resave strips UIDs from references (path-only references went from 213 to 251 of 251 lines), so it has to be written down as a rule (plan §13.7, risk 2).*

## A-8 — Danh sách workflow (Workflows)

**Cũ (Old)** — `CLAUDE.md` lines 90-95:

~~~~text
## Workflows
Reusable slash-command workflows live in `.claude/commands/`:
- `/verify` — run the full check above.
- `/new-enemy` — scaffold a data-only enemy (the Bishop recipe, zero new script).
- `/milestone` — the phase-gate loop (read docs → smallest slice → build → verify →
  update planning docs → commit).
~~~~

**Mới (New):**

> Add `/new-skill`, `/new-room`, `/new-beat`; rewrite `/new-enemy` and `/verify`.

**Vì sao (Why):** thêm lệnh cho các loại nội dung mới (skill, phòng, beat truyện) để mỗi thứ chỉ cần sửa dữ liệu; `/new-enemy` và `/verify` viết lại cho khớp cây thư mục và runner mới (plan §15, M2, M7a, M5, M6).
*EN: New slash commands for the new content kinds (skill, room, story beat) so each is a data edit; `/new-enemy` and `/verify` are rewritten for the new tree and runner (plan §15).*

## A-9 — Âm thanh (Sound: three layers, one owner each)

**Cũ (Old)** — `CLAUDE.md` lines 35-40:

~~~~text
  - Sound (three layers, one owner each): motion sounds → audio tracks inside
	the actor's clips (keying its `AudioPlayer`, bus `SFX`); mixing →
	`default_bus_layout.tres` (Master ← SFX/Music/UI); event sounds with no
	clip (pickups, room clear, jingles, UI) → the `SfxManager` autoload's
	Inspector stream registry, played ONLY by the main.gd bridge from drained
	events. Systems never play audio. Recipe: `/new-sound`.
~~~~

**Mới (New):**

> Unchanged, plus: the `Sfx` autoload registry is keyed from `content/audio/sound_bank.tres`.

**Vì sao (Why):** ba lớp âm thanh và chủ sở hữu của từng lớp giữ nguyên; chỉ có nơi lưu bảng âm thanh sự kiện chuyển vào `content/` để bạn thêm tiếng bằng cách thả file và thêm một dòng dữ liệu (plan D-26, §11).
*EN: The three layers and their owners are unchanged; only the event-sound registry moves into `content/` so you add a sound by dropping a file and adding one data row (plan D-26, §11).*

---

## Ghi chú thêm của docs lane (không thuộc plan §2.4, tuỳ chọn)

Một chỗ trong `CLAUDE.md` mà plan §2.4 không liệt kê, bạn có thể muốn xem cùng lúc (docs lane không tự
sửa): mục "Read first, every session" (dòng 7-11) chưa nhắc `docs/where-we-are.md` (trang trạng thái) và
`docs/game-base-plan.md` (kế hoạch xây). `AGENTS.md` bản viết lại đã trỏ tới cả hai.

*EN: One spot in `CLAUDE.md` that plan §2.4 does not list, which you may want to look at at the same time
(the docs lane did not change it): "Read first, every session" (lines 7-11) does not yet mention
`docs/where-we-are.md` (status) or `docs/game-base-plan.md` (the build plan). The rewritten `AGENTS.md`
points to both.*
