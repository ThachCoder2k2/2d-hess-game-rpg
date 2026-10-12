# content/ — thư mục của bạn (your folder)

> Tiếng Việt trước, tiếng Anh sau. Nếu khác nhau thì **bản tiếng Anh là bản chuẩn**.
> *Vietnamese first, English second; the English is authoritative where they differ.*

Đây là nơi chứa dữ liệu, art, âm thanh và lời của game. **Không có file `.gd` nào ở đây** (một test
kiểm điều đó), nên bạn đổi gì ở đây cũng không phải đụng code.
*This folder holds the game's data, art, audio and words. It contains no `.gd` file (a test checks), so
nothing you change here touches code.*

## Quy ước (Conventions)

- **Tên thư mục là id.** `content/enemies/knight_tracker/` là enemy có id `knight_tracker`; id chỉ viết
  ở một chỗ. Thư mục bắt đầu bằng `_` (như `_shared`) không phải id.
  *A folder name is the id, spelled in one place. A folder starting with `_` is not an id.*
- **Tên file là vai trò.** `enemy.tres`, `room.tscn`, `page.tres`, `body.png`, `icon.png`,
  `background.png`. Thay art = **ghi đè file cùng tên**, không sửa gì khác.
  *File names are roles. To swap art, overwrite the file with the same name; nothing else changes.*
- **Mỗi thứ một file.** Một PNG cho một tile, một prop, một icon, một khung hình; không gộp sheet.
  *One file per thing: one PNG per tile, prop, icon or animation frame; no sheets or atlases.*
- Mọi thứ trong đây tra theo id qua `ContentDb` (sổ đăng ký, `shell/content/content_db.gd`; mười loại: `player`,
  `world`, `piece_sizes`, `enemies`, `rooms`, `rules`, `skills`, `pickups`, `difficulty`, `tilesets`). Thêm một thư mục
  `enemies/<id>/` có `enemy.tres` là xong, **không phải đăng ký ở đâu**: `ContentDb` tìm thấy nó theo tên. Thêm hoặc
  sửa xong, `tests/content/test_validate_all.gd` kiểm mọi file có hợp lệ (`validate()`), tên thư mục có bằng `id` trong
  file, và mọi tham chiếu có trỏ tới một id có thật không (kể cả hình lớn hơn hộp của loại quân).
  *Everything here is looked up by id through `ContentDb` (the registry, ten kinds). A folder `enemies/<id>/` with an
  `enemy.tres` is all it takes: nothing is registered, `ContentDb` finds it by name. After an edit,
  `tests/content/test_validate_all.gd` checks that every file is valid (`validate()`), the folder name equals the
  `id` inside, and every reference points at an id that exists, a picture larger than its kind's box included.*
- `_shared/` (như `enemies/_shared/`) chứa mảnh nhiều thứ dùng chung: sửa một file ở đó là đổi **tất cả** thứ trỏ tới nó.
  *`_shared/` holds pieces many things share: editing a file there changes everything that points at it.*
- File nào còn là hình/tiếng tạm: `tools/list_placeholders.gd` in ra, dựa trên `_placeholders.json`.
  *Which files are still stand-ins: `tools/list_placeholders.gd` prints them, from `_placeholders.json`.*

## Muốn đổi X thì mở Y (I want to change X, open Y)

| Bạn muốn... (You want to...) | Mở (Open) |
|---|---|
| Chỉnh máu, tốc độ, AI hoặc đòn đánh của một enemy | `enemies/<id>/enemy.tres` và các `.tres` cạnh nó (`movement`, `decision`, `unarmed_attack`, `visual`); dùng chung: `enemies/_shared/` |
| Chỉnh cảm giác con tốt (thời gian bước, courage, invulnerability, hồi chiêu kỹ năng) | `player/player.tres` (một file) |
| Thêm một biến thể enemy (máu, vũ khí, tốc độ khác) | **1 file**: chép `enemies/pawn_recruit/enemy.tres` thành `enemies/<id>/enemy.tres`, sửa `id` (bằng tên thư mục), `display_name`, `max_health`; nó dùng lại phần còn lại ở `enemies/_shared/`. Thêm hình riêng: **+2 file** (`visual.tres`, `body.png`). Đặt vào phòng: kéo `presentation/views/actors/actor_view_base.tscn` vào `rooms/<id>/room.tscn`, đặt `Definition`. Từng bước đã chạy thử thật: `.claude/commands/new-enemy.md` |
| Đổi hình của con tốt hoặc một enemy | ghi đè `player/body.png` hoặc `enemies/<id>/body.png` (vẽ ở tỉ lệ 1:1, không lớn hơn hộp của loại quân trong `feel/piece_sizes.tres`; mục 6 của `../docs/OWNER_GUIDE.md`; ảnh xem trước: `../assets/_generated/previews/pieces_in_cells.png`) |
| Đổi quân cờ to nhỏ thế nào trong ô (quân phải nhỏ hơn ô) | `feel/piece_sizes.tres` (hộp, vạch đứng và cỡ chân đế của từng loại quân) |
| Đổi icon kiếm, bút chì, vũ khí | ghi đè `skills/<id>/icon.png` hoặc `pickups/<id>/icon.png` |
| Chỉnh bố cục phòng, chỗ đứng enemy, cửa | mở `rooms/<id>/room.tscn` trong Godot và kéo node |
| Đổi hình nền phòng T1/T2 | ghi đè `rooms/<id>/background.png` |
| Sửa một trang của Book of House Rules | `rules/<id>/page.tres` (danh sách: `rules/rule_book.tres`) |
| Chỉnh độ khó toàn cục | `difficulty/standard.tres` |
| Đổi phòng nào nối phòng nào | `world/world.tres` |
| Đổi bộ tile | `tilesets/<bộ>/tileset.tres`, atlas ở `../assets/tiles/<bộ>/` (đừng sửa tay `tile_map_data`) |
| Đổi tiếng động, nhạc | ghi đè file trong `../assets/sfx/` hoặc `../assets/music/` (cùng tên) |

*EN: A variant enemy (other health, weapon or speed) is one file, `enemies/<id>/enemy.tres` (copy `pawn_recruit`'s,
change `id`, `display_name`, `max_health`); a picture of its own adds `visual.tres` and `body.png`; to place it,
instance `presentation/views/actors/actor_view_base.tscn` in a room and set `definition` (walked once for real:
`.claude/commands/new-enemy.md`). The pawn's feel (step time, Courage, invulnerability, skill cooldown): `player/player.tres`, one file.
Enemy stats, AI and attacks: `enemies/<id>/enemy.tres` and the `.tres` beside it (shared pieces in
`enemies/_shared/`). Pictures: overwrite `player/body.png`, `enemies/<id>/body.png`, `skills/<id>/icon.png`,
`pickups/<id>/icon.png`, `rooms/<id>/background.png`. How big each kind of piece is inside its 32 px cell (a piece
is smaller than its cell; a picture may be no larger than the box of its kind): `feel/piece_sizes.tres`. Room layout: open `rooms/<id>/room.tscn`. Book pages:
`rules/<id>/page.tres`. Difficulty: `difficulty/standard.tres`. Which room connects to which:
`world/world.tres`. Tile kits: `tilesets/<kit>/`. Sounds and music: overwrite the same-named file in
`../assets/sfx/` or `../assets/music/`.*

Bảng đầy đủ hơn, kèm những việc sẽ có ở các milestone sau (kỹ năng, truyện, boss, ngôn ngữ), nằm trong
`../docs/OWNER_GUIDE.md` mục 5. Các thư mục trong kế hoạch mà chưa có ở đây (`story/`, `audio/`,
`progression/`, `ui/`, `bosses/`, `props/`; `feel/` mới có bảng cỡ quân) sẽ xuất hiện cùng milestone cần chúng.
*The fuller table, including what later milestones add (skills, story, bosses, languages), is
`../docs/OWNER_GUIDE.md` section 5. Folders the plan names that do not exist yet (`story/`, `audio/`,
`progression/`, `ui/`, `bosses/`, `props/`; `feel/` has only the piece size table so far) appear with the milestones that need them.*
