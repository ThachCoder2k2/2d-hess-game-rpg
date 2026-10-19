# assets/fonts: the owner's fonts

This folder is where the owner's UI fonts go. **Nothing is downloaded into it by the project:** the files are the
owner's (docs/owner-decisions.md, 2026-10-12). Until a file is here the game uses the engine's default font.

Put each file at exactly this name (they are the names the asset list gives, `docs/assets/spec/ui_story.json`,
group `fonts_ui`; the Theme `content/ui/theme/theme.tres` names them):

| File | Used for |
|---|---|
| `ui_body_pixel.ttf` | the main font: menus, dialogue, the Book, the HUD's words |
| `ui_small_pixel.ttf` | HUD numerals, cooldown digits, timers (Labels with the theme type variation `HudNumeral`) |
| `ui_title_pixel.ttf` | headings (theme type variation `MenuTitle`) |
| `child_hand.ttf` | the child's lines, from M6 (theme type variation `ChildLine`) |

Overwriting a file swaps the font; deleting it gives the engine's font back. A font must be able to write every
Vietnamese letter: `tests/text/test_font_vietnamese_coverage.gd` fails if it cannot. Add the font's licence to
`THIRD_PARTY_NOTICES.md` (an entry with a `- **License:**` bullet) and run
`godot --headless --path . -s tools/build_credits_licenses.gd` so the credits show it. How to do all of this, step
by step, is in `docs/OWNER_GUIDE.md` (Vietnamese).

---

# assets/fonts: font của chủ dự án

Thư mục này chứa các font giao diện do chủ dự án cung cấp. **Dự án không tự tải font nào về:** các file là của chủ
dự án. Khi chưa có file, game dùng font mặc định của engine. Đặt đúng tên file như bảng trên, chép đè là đổi font,
xoá file là trở về font của engine. Hướng dẫn từng bước nằm trong `docs/OWNER_GUIDE.md`.
