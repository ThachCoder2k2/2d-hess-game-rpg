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
- File nào còn là hình/tiếng tạm: `tools/list_placeholders.gd` in ra, dựa trên `_placeholders.json`.
  *Which files are still stand-ins: `tools/list_placeholders.gd` prints them, from `_placeholders.json`.*

## Muốn đổi X thì mở Y (I want to change X, open Y)

| Bạn muốn... (You want to...) | Mở (Open) |
|---|---|
| Chỉnh máu, tốc độ, AI hoặc đòn đánh của một enemy | `enemies/<id>/enemy.tres` và các `.tres` cạnh nó (`movement`, `decision`, `unarmed_attack`, `visual`); dùng chung: `enemies/_shared/` |
| Đổi hình của con tốt hoặc một enemy | ghi đè `player/body.png` hoặc `enemies/<id>/body.png` |
| Đổi icon kiếm, bút chì, vũ khí | ghi đè `skills/<id>/icon.png` hoặc `pickups/<id>/icon.png` |
| Chỉnh bố cục phòng, chỗ đứng enemy, cửa | mở `rooms/<id>/room.tscn` trong Godot và kéo node |
| Đổi hình nền phòng T1/T2 | ghi đè `rooms/<id>/background.png` |
| Sửa một trang của Book of House Rules | `rules/<id>/page.tres` (danh sách: `rules/rule_book.tres`) |
| Chỉnh độ khó toàn cục | `difficulty/standard.tres` |
| Đổi phòng nào nối phòng nào | `world/world.tres` |
| Đổi bộ tile | `tilesets/<bộ>/tileset.tres`, atlas ở `../assets/tiles/<bộ>/` (đừng sửa tay `tile_map_data`) |
| Đổi tiếng động, nhạc | ghi đè file trong `../assets/sfx/` hoặc `../assets/music/` (cùng tên) |

*EN: Enemy stats, AI and attacks: `enemies/<id>/enemy.tres` and the `.tres` beside it (shared pieces in
`enemies/_shared/`). Pictures: overwrite `player/body.png`, `enemies/<id>/body.png`, `skills/<id>/icon.png`,
`pickups/<id>/icon.png`, `rooms/<id>/background.png`. Room layout: open `rooms/<id>/room.tscn`. Book pages:
`rules/<id>/page.tres`. Difficulty: `difficulty/standard.tres`. Which room connects to which:
`world/world.tres`. Tile kits: `tilesets/<kit>/`. Sounds and music: overwrite the same-named file in
`../assets/sfx/` or `../assets/music/`.*

Bảng đầy đủ hơn, kèm những việc sẽ có ở các milestone sau (kỹ năng, truyện, boss, ngôn ngữ), nằm trong
`../docs/OWNER_GUIDE.md` mục 5. Các thư mục trong kế hoạch mà chưa có ở đây (`story/`, `audio/`, `feel/`,
`progression/`, `ui/`, `bosses/`, `props/`) sẽ xuất hiện cùng milestone cần chúng.
*The fuller table, including what later milestones add (skills, story, bosses, languages), is
`../docs/OWNER_GUIDE.md` section 5. Folders the plan names that do not exist yet (`story/`, `audio/`,
`feel/`, `progression/`, `ui/`, `bosses/`, `props/`) appear with the milestones that need them.*
