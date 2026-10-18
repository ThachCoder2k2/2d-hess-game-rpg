# Danh sách yêu cầu asset — The Unbound Pawn

> File này và mọi file trong `requests/` được **tự sinh** bởi `tools/asset_requests/build_requests.py` từ các file spec (`style.json`, `characters.json`, `world.json`, `ui_story.json`, `vfx.json`, `audio.json`). Đừng sửa tay; sửa spec rồi chạy lại.

> Repo chỉ giữ spec, script, README này, `STYLE.md` và `by-milestone.md`. Thư mục `requests/` (khoảng 100 MB prompt) và `asset-manifest.json` không được commit — tạo lại bằng một lệnh: `python3 tools/asset_requests/build_requests.py`.

Tổng cộng **8300 file** trong **856 nhóm**: 6758 ảnh (trong đó 3730 khung hoạt ảnh), 1477 âm thanh (SFX và giọng là `.wav`, nhạc và ambience là `.ogg`), 4 font và 61 glyph phím/tay cầm chép từ bộ CC0 của Kenney (không vẽ).

## 1. Cách hoạt động

- **Một file = một vật.** Một tile 32x32, một vật cảnh, một biểu tượng, một phần giao diện, một cảm xúc chân dung, một KHUNG HÌNH hoạt ảnh, một âm thanh. Không gộp sheet, atlas, dải, ảnh nhiều vật hay tranh cả căn phòng.
- **Mỗi mục có một prompt đầy đủ, tự đủ ý.** Chép nguyên khối trong ô `text` vào công cụ vẽ hoặc thu âm; không cần ghép thêm gì (khối phong cách đã nằm sẵn trong prompt).
- **Đặt file đúng đường dẫn ghi ở mục `File`.** Ghi đè lên file placeholder cùng đường dẫn thì game tự dùng, không cần sửa code. Ghi đè là cách thay asset thật cho placeholder.
- **Công cụ lo phần ghép.** Atlas, sprite sheet, tileset, cảnh phòng và vista đều do tool dựng từ các file đơn; anh chỉ giao từng mảnh nhỏ.
- **Asset không bao giờ chặn việc build.** Chưa có file thật thì game dùng placeholder; thứ tự làm theo mốc `Cần từ` và ưu tiên must, should, could.
- **Hoạt ảnh** lưu từng khung ở `<thư mục>/anim/<clip>/NN.png`, NN bắt đầu từ 01. Mọi khung của một clip cùng canvas, cùng điểm neo, cùng bảng màu.
- **Thứ tự vẽ hoạt ảnh (quan trọng với công cụ vẽ chỉ nhận chữ):** vẽ file tham chiếu TRƯỚC (ảnh tĩnh `body.png`, `prop.png`... hoặc khung 01 của nhóm, prompt của từng khung ghi rõ đường dẫn), duyệt nó, rồi ĐÍNH KÈM chính file đó làm ảnh tham chiếu khi tạo mọi khung còn lại. Công cụ chỉ nhận chữ không mở được đường dẫn nên sẽ vẽ lệch nhân vật nếu thiếu bước đính kèm này.
- **Dòng `DO NOT` có biến thể theo loại file.** Mặc định dành cho MỘT vật đứng riêng trên nền trong suốt. Tile, nền bản đồ và mảnh vista đặc dùng biến thể `surface` (vẽ kín canvas, mặt sàn/tường chính là vật cần vẽ); UI, 9-patch, khung, hàng rào dùng biến thể `frame` (khung/viền chính là vật cần vẽ); nhóm âm thanh người của bé và nền buổi sáng có chim dùng biến thể âm thanh riêng. Xem `STYLE.md`.
- **Mỗi mục có dòng `Kiểm tra`**: tiêu chí nghiệm thu tự động (kích thước đúng, RGBA có alpha, lưới pixel, điểm neo; với âm thanh: định dạng, thời lượng ±10%, đỉnh, điểm lặp).
- **Mọi ảnh vẽ pixel 1x1 (quyết định của anh, 2026-10-13: "Tất cả 1×1").** Quân cờ, boss, tile, vật cảnh, hiệu ứng thế giới, giao diện, icon, chân dung và bàn tay của bé đều là một pixel vẽ = một pixel game ở độ phân giải gốc 640x360: không vẽ trên lưới nhỏ rồi phóng to, không có khối pixel lớn hơn ở đâu cả. Canvas 32x32 nghĩa là có đủ 32x32 pixel thật để vẽ chi tiết (đinh tán, mũi khâu, thớ gỗ, điểm sáng một pixel).
- **Quân cờ nhỏ hơn ô (quyết định của anh, 2026-10-12).** Mọi quân cờ (pawn của anh, mọi kẻ địch và biến thể, quân trắng được cứu, Vua trắng đã ngã, sáu boss) vẽ trên canvas 32x32 = đúng một ô, thân quân nằm gọn bên trong và chừa ít nhất 2 px trống mỗi cạnh: không bằng ô, không cao hơn ô. Chiều cao theo bộ cờ thật: Tốt thấp nhất, rồi Mã/Tượng/Xe, rồi Hậu, Vua cao nhất. Bảng cỡ ở mục 4 ghi từng hạng quân.
- **Nhạc: một bài cho mỗi khu, không tách stem.** Mỗi vùng (title, Act 1, hub, năm khu, cảnh kết) và mỗi boss có đúng một bản phối hoàn chỉnh `.ogg`; đổi giai đoạn boss dùng thêm một tiếng 'phase sting' `.wav`. SFX và tiếng blip giọng là `.wav`.
- **Glyph phím/tay cầm không vẽ.** Nhóm `glyphs_kenney` chỉ ghi file nào của bộ CC0 'Input Prompts Pixel' (Kenney) cần chép vào đường dẫn nào; file vẽ tay đặt đúng đường dẫn ấy sẽ thay được bất cứ lúc nào.

## 2. Cách duyệt danh sách

- [`by-milestone.md`](by-milestone.md): tất cả id và đường dẫn theo mốc M2 đến M14, `must` trước.
- [`requests/INDEX.md`](requests/INDEX.md): mục lục 5 danh mục và 856 nhóm, mỗi nhóm một file.
- `requests/<danh mục>/<nhóm>.md`: đầu trang là mô tả nhóm (ghi chú, nơi dùng, file tham chiếu, placeholder), tiếp theo là từng mục với prompt.
- [`STYLE.md`](STYLE.md): khối phong cách, điều cấm, bản tóm tắt âm thanh, bảng kích thước, quy tắc giao file.
- [`asset-manifest.json`](asset-manifest.json): toàn bộ mục ở dạng máy đọc được (kèm prompt).

- Quyết định thẩm mỹ và các câu hỏi còn mở: [`spec/direction.md`](spec/direction.md) (mục 8).

## 3. Danh sách kiểm tra khi giao file

1. File đúng đường dẫn và đúng tên ghi ở mục `File` (chữ thường, không dấu cách).
2. Ảnh: PNG RGBA 8-bit, đúng kích thước canvas, nền trong suốt (tile, nền bản đồ và mảnh vista đặc thì đặc hoàn toàn), không làm mờ, không răng cưa.
3. Mọi ảnh vẽ pixel 1x1 (quyết định của anh, 2026-10-13): quân cờ, boss, tile, vật cảnh, hiệu ứng thế giới, giao diện, icon, chân dung và bàn tay của bé đều là một pixel vẽ = một pixel game ở độ phân giải gốc 640x360, không phóng to, không khối pixel lớn hơn.
4. Điểm neo (chân/đế) đúng toạ độ ghi trong `Spec`; các khung của một clip không lệch ngang quá 3 px. Mọi khung sau được tạo từ ảnh tham chiếu đã duyệt (xem mục 1), không vẽ rời từng khung.
5. Không có chữ hoặc số trong ảnh (trừ logo và phím); đỏ san hô chỉ cho sát thương sắp xảy ra.
6. Âm thanh: SFX và giọng là WAV 44.1 kHz 16-bit (mono hoặc stereo theo `Spec`), đỉnh -1 dBFS, không clip, không click; SFX lặp có smpl loop chunk liền mạch. Nhạc và ambience là OGG Vorbis 44.1 kHz stereo (chất lượng khoảng 6), một bản phối hoàn chỉnh cho mỗi khu/boss, bản lặp có mẫu đầu và cuối liên tục, KHÔNG nhúng thẻ loop (game bật cờ lặp khi nhập). Các biến thể `_01`, `_02`... nghe như cùng một vật.
7. Font: file `.ttf` hoặc `.otf` giấy phép OFL/CC0. Chạy `python3 tools/asset_requests/build_requests.py --check-font <file>` (đọc bảng cmap giống `FontFile.has_char`, báo mọi chữ tiếng Việt còn thiếu, kể cả dấu chồng) trước khi chốt; độ cao dòng và khoảng trống cho dấu ở cỡ chữ thật vẫn là bước nhìn bằng mắt.
7b. Glyph phím/tay cầm: chép đúng tile của bộ Kenney 'Input Prompts Pixel' (CC0) vào đường dẫn ghi ở mục `File`, thêm bộ này vào THIRD_PARTY_NOTICES.md; không vẽ lại, không đổi cỡ.
8. Không đặt file trong thư mục bị gitignore (`assets/_generated/`, `build/`, `.godot/`): mọi thứ trong đó có thể bị máy ghi đè.
9. Giao theo mốc: xong hết `must` của một mốc rồi mới sang `should`; mốc nhỏ trước.
10. Phần trăm trong mô tả (ví dụ 'vòng 88 px ở 70%') là ĐỘ ĐỤC của phần tử, không phải kích thước hay tiến độ, trừ khi câu chữ nói rõ nó đo cái gì; vẽ bằng một màu phẳng với một giá trị alpha (alpha = % x 255), viền cứng. Tile đặc dùng lưới caro 1 pixel hoặc trộn màu sẵn. Không dùng gradient (xem đoạn PERCENTAGES AND TRANSLUCENCY trong `STYLE.md`).

## 4. Bảng kích thước

| Lớp | Loại | Canvas | Lưới | Điểm neo | Dùng cho |
|---|---|---|---|---|---|
| `tile_32` | tile | 32x32 | 1x1 | none (fills the cell edge to edge, seamless where a group says so) | every floor, wall, gap, cover, exit and seam tile |
| `piece_pawn_32` | sprite | 32x32 | 1x1 | base-bottom centre at (16,30); body box 18x22 px, top at y=8, 2 px margin on every side; the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and the body box is centred 3 px below the cell centre | CHESS PIECE, pawn class: the hero pawn, every pawn-family enemy (recruit, armed, backstep, charging, commanded, toy blocker, veteran, desperate, passant wraith), the Crayon Target standee, the white pawn soldier, the hub's gathered white pawns |
| `piece_knight_32` | sprite | 32x32 | 1x1 | pedestal base-bottom centre at (16,30); body box 20x24 px, top at y=6, 2 px margin; the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and the body box is centred 2 px below the cell centre | CHESS PIECE, knight class: Knight Tracker, Guard Knight, rescued Pebble |
| `piece_bishop_32` | sprite | 32x32 | 1x1 | base-bottom centre at (16,30); body box 20x24 px, top at y=6, 2 px margin; the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and the body box is centred 2 px below the cell centre | CHESS PIECE, bishop class: Bishop Zoner, Mirror Bishop, Torn Bishop, rescued Slant |
| `piece_rook_32` | sprite | 32x32 | 1x1 | base-bottom centre at (16,30); body box 20x24 px, top at y=6, 2 px margin; the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and the body box is centred 2 px below the cell centre | CHESS PIECE, rook class: Wooden Rook, Iron Rook, rescued Stout, and the minor-height deferred variants (Promoted Zealot, Marble Launcher, Wind-Up Hammer) |
| `piece_queen_32` | sprite | 32x32 | 1x1 | base-bottom centre at (16,30); body box 22x26 px, top at y=4, 2 px margin; the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and the body box is centred 1 px below the cell centre | CHESS PIECE, queen class: reserved for a standing queen (the base game has none: the Queen of Tricks uses the boss row, and the white queen appears only lying down or as a promotion token) |
| `piece_king_32` | sprite | 32x32 | 1x1 | base-bottom centre at (16,30); body box 22x28 px, top at y=2, 2 px margin; the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and the body box is centred 0 px below the cell centre | CHESS PIECE, king class: the standing white King of the ending (the tallest piece) |
| `piece_boss_32` | sprite | 32x32 | 1x1 | base-bottom centre at (16,30); body box at most 24x28 px: Captain 24x22, Knight Captain 24x24, Bishop Oracle 22x24, Rook Warden 24x24, Queen of Tricks 24x26, Black King 24x28 (pawn lowest, king tallest); the base-bottom centre (16,30) is 14 px below the cell centre (16,16), and a boss box is centred 0 to 3 px below it (Captain 3, Knight Captain 2, Bishop Oracle 2, Rook Warden 2, Queen 1, King 0) | CHESS PIECE, boss: the six bosses (they are chess pieces too, smaller than the cell like every piece; they read as bosses through crown, silhouette details, colour and their aura and burst effect files, not through size) |
| `piece_fallen_32` | prop | 32x32 | 1x1 | centre of the floor-contact line at (16,30); a lying piece is its standing box turned 90 degrees (pawn 22x18, knight/bishop/rook 24x20, queen 26x22, king 28x22), 2 px margin on every side | fallen white pieces, the fallen white King, fragments of broken pieces, the toys the six bosses become, remains of defeated enemies |
| `piece_mixed_32` | prop | 32x32 | 1x1 | base centre at (16,30); every piece inside obeys its own class box above | props that hold or cover chess pieces: the three rescue traps, the Act-6 memory figures and crayon outlines, the four promotion tokens (piece plus disc at most 24x28), the ending's white pieces |
| `weapon_overlay_32x32` | sprite | 32x32 | 1x1 | grip pivot at (16,26), blade pointing north (the WeaponPivot rotates it); the weapon spans y=2..28, at most 26 px long and 8 px wide | held weapon overlays (hero and enemy): they fit the cell like the pieces that hold them |
| `boss_engine_96x80` | sprite | 96x80 | 1x1 | base centre at (48,76) | Rule Engine (a machine in a chess box, not a chess piece, so it is the one boss larger than a cell) |
| `child_hand_192x144` | sprite | 192x144 | 1x1 | contact point at (44,112) in every frame | the child's hand and its shadow (192x144 is large only because the hand is huge next to a pawn; it is drawn at the same 1x1 pixels as everything else) |
| `prop_decal_32` | prop | 32x32 | 1x1 | none (a flat decal fills its cell, centre (16,16)) | floor decals, marks, lines, litter |
| `prop_low_32` | prop | 32x32 | 1x1 | feet/base centre at (16,30) | low props, pickups, blocks, small toys |
| `prop_32x40` | prop | 32x40 | 1x1 | feet/base centre at (16,36) | standing props one cell wide, up to 40 px tall |
| `prop_32x48` | prop | 32x48 | 1x1 | feet/base centre at (16,44) | tall props and furniture parts one cell wide |
| `prop_40x40` | prop | 40x40 | 1x1 | feet/base centre at (20,36) | toy train engine |
| `prop_48x32` | prop | 48x32 | 1x1 | feet/base centre at (24,30) | wide flat props that are not pieces: the open second chess board and the captured-piece tray on the desk |
| `prop_48x40` | prop | 48x40 | 1x1 | feet/base centre at (24,36) | book, small wide props |
| `prop_48x48` | prop | 48x48 | 1x1 | feet/base centre at (24,44) | the Under-Bed memory wall, medium props |
| `prop_64x40` | prop | 64x40 | 1x1 | feet/base centre at (32,36) | two-cell-wide low props (big book, open book) |
| `prop_64x48` | prop | 64x48 | 1x1 | feet/base centre at (32,44) | two-cell-wide props, gates, the chess box |
| `prop_64x64` | prop | 64x64 | 1x1 | feet/base centre at (32,60); vista parts: none for seamless tiles, (32,60) for objects | large props, throne break, vista parts |
| `prop_64x64_light` | prop | 64x64 | 1x1 | centre of the light at (32,32) | small light pools (overlay) |
| `prop_96x40` | prop | 96x40 | 1x1 | feet/base centre at (48,36) | the under-bed silhouette strip |
| `prop_light_128x96` | prop | 128x96 | 1x1 | centre of the light at (64,48) | large light pools (overlay) |
| `vfx_8x8` | vfx | 8x8 | 1x1 | cell/centred effects (4,4); ground contact under an actor (4,6); feet-anchored (4,6); a lane tile or full-cell fill uses none | particles and chips (centred) |
| `vfx_12x12` | vfx | 12x12 | 1x1 | cell/centred effects (6,6); ground contact under an actor (6,10); feet-anchored (6,10); a lane tile or full-cell fill uses none | sparkles and the lane order badge |
| `vfx_16x16` | vfx | 16x16 | 1x1 | cell/centred effects (8,8); ground contact under an actor (8,14); feet-anchored (8,14); a lane tile or full-cell fill uses none | small marks, smoke, status icons, death glyphs, facing arrows |
| `vfx_24x16` | vfx | 24x16 | 1x1 | cell/centred effects (12,8); ground contact under an actor (12,14); feet-anchored (12,14); a lane tile or full-cell fill uses none | step dust and crumbs |
| `vfx_24x24` | vfx | 24x24 | 1x1 | cell/centred effects (12,12); ground contact under an actor (12,22); feet-anchored (12,22); a lane tile or full-cell fill uses none | status icons |
| `vfx_24x32` | vfx | 24x32 | 1x1 | cell/centred effects (12,16); ground contact under an actor (12,20); feet-anchored (12,30); a lane tile or full-cell fill uses none | rule cards |
| `vfx_32x16` | vfx | 32x16 | 1x1 | cell/centred effects (16,8); ground contact under an actor (16,14); feet-anchored (16,14); a lane tile or full-cell fill uses none | stun and status bars, flight shadow, small actor shadow |
| `vfx_32x24` | vfx | 32x24 | 1x1 | cell/centred effects (16,12); ground contact under an actor (16,22); feet-anchored (16,22); a lane tile or full-cell fill uses none | takeoff and landing dust |
| `vfx_32x32` | vfx | 32x32 | 1x1 | cell/centred effects (16,16); ground contact under an actor (16,20); feet-anchored (16,30); a lane tile or full-cell fill uses none | every telegraph cell marker, hit spark, dust burst and one-cell effect; lane tiles meet their neighbours at the cell edges (anchor none) |
| `vfx_32x40` | vfx | 32x40 | 1x1 | cell/centred effects (16,20); ground contact under an actor (16,24); feet-anchored (16,36); a lane tile or full-cell fill uses none | boss toybox-shake dust |
| `vfx_40x40` | vfx | 40x40 | 1x1 | cell/centred effects (20,20); ground contact under an actor (20,24); feet-anchored (20,36); a lane tile or full-cell fill uses none | small telegraph aura |
| `vfx_48x32` | vfx | 48x32 | 1x1 | cell/centred effects (24,16); ground contact under an actor (24,20); feet-anchored (24,30); a lane tile or full-cell fill uses none | hand placement dust |
| `vfx_48x48` | vfx | 48x48 | 1x1 | cell/centred effects (24,24); ground contact under an actor (24,30); feet-anchored (24,44); a lane tile or full-cell fill uses none | heavy hit, medium poof and ground rings |
| `vfx_56x56` | vfx | 56x56 | 1x1 | cell/centred effects (28,28); ground contact under an actor (28,34); feet-anchored (28,52); a lane tile or full-cell fill uses none | medium telegraph aura |
| `vfx_64x24` | vfx | 64x24 | 1x1 | cell/centred effects (32,12); ground contact under an actor (32,22); feet-anchored (32,22); a lane tile or full-cell fill uses none | large actor shadow, stun bar |
| `vfx_64x32` | vfx | 64x32 | 1x1 | cell/centred effects (32,16); ground contact under an actor (32,20); feet-anchored (32,30); a lane tile or full-cell fill uses none | amendment scribbles |
| `vfx_64x40` | vfx | 64x40 | 1x1 | cell/centred effects (32,20); ground contact under an actor (32,24); feet-anchored (32,36); a lane tile or full-cell fill uses none | large landing ring |
| `vfx_64x64` | vfx | 64x64 | 1x1 | cell/centred effects (32,32); ground contact under an actor (32,40); feet-anchored (32,60); a lane tile or full-cell fill uses none | large collect burst, shockwave, rescue burst |
| `vfx_96x24` | vfx | 96x24 | 1x1 | cell/centred effects (48,12); ground contact under an actor (48,22); feet-anchored (48,22); a lane tile or full-cell fill uses none | boss actor shadow |
| `vfx_96x64` | vfx | 96x64 | 1x1 | cell/centred effects (48,32); ground contact under an actor (48,40); feet-anchored (48,60); a lane tile or full-cell fill uses none | box opening light |
| `vfx_96x96` | vfx | 96x96 | 1x1 | cell/centred effects (48,48); ground contact under an actor (48,60); feet-anchored (48,92); a lane tile or full-cell fill uses none | boss bursts, boss auras, boss defeat and phase changes |
| `ui_free` | ui | tự do, cạnh chẵn từ 4 đến 384 px | 1x1 | 9-patch corner size or alignment is written in each group anchor | every UI element: panels, plates, bars, glyphs, cards, HUD effects, vista-free overlays |
| `icon_16` | icon | 16x16 | 1x1 | none (centred) | skill, page, lore, pickup, menu, settings, telegraph-legend icons |
| `icon_24` | icon | 24x24 | 1x1 | bubble tail tip noted in the group | pawn emote bubbles |
| `icon_32` | icon | 32x32 | 1x1 | none (centred) | act emblems |
| `icon_small` | icon | 8x8 | 1x1 | none (centred) | tiny ink swatches |
| `portrait_64` | portrait | 64x64 | 1x1 | bust, bottom edge cut, shoulders cut by the canvas | dialogue portraits, one per emotion |
| `font_ttf` | font | file, không có canvas | - | none | owner-supplied OFL pixel fonts (files, no canvas) |

## 5. Số lượng

### Theo danh mục

| Danh mục | Nhóm | File | must | should | could |
|---|---:|---:|---:|---:|---:|
| characters | 57 | 1774 | 1229 | 166 | 379 |
| world | 275 | 2370 | 1294 | 661 | 415 |
| ui_story | 144 | 835 | 252 | 472 | 111 |
| vfx | 265 | 1844 | 795 | 466 | 583 |
| audio | 115 | 1477 | 680 | 495 | 302 |
| **Tổng** | 856 | 8300 | 4250 | 2260 | 1790 |

### Theo loại (kind)

| Loại | File | must | should | could |
|---|---:|---:|---:|---:|
| sprite | 1807 | 1264 | 156 | 387 |
| vfx | 1765 | 758 | 428 | 579 |
| prop | 1401 | 517 | 625 | 259 |
| sfx | 1196 | 624 | 355 | 217 |
| tile | 1012 | 799 | 192 | 21 |
| ui | 522 | 148 | 209 | 165 |
| icon | 185 | 25 | 111 | 49 |
| voice_blip | 116 | 16 | 100 | 0 |
| ambience | 103 | 8 | 12 | 83 |
| portrait | 66 | 12 | 36 | 18 |
| music | 62 | 32 | 28 | 2 |
| sourcing | 61 | 46 | 6 | 9 |
| font | 4 | 1 | 2 | 1 |

### Theo ưu tiên

| Ưu tiên | File |
|---|---:|
| must | 4250 |
| should | 2260 |
| could | 1790 |

### Theo mốc (milestone)

| Mốc | File | must | should | could |
|---|---:|---:|---:|---:|
| M2 | 3 | 3 | 0 | 0 |
| M3b | 23 | 8 | 15 | 0 |
| M4 | 293 | 138 | 103 | 52 |
| M5 | 248 | 117 | 95 | 36 |
| M6 | 1117 | 609 | 377 | 131 |
| M7a | 97 | 73 | 11 | 13 |
| M7b | 111 | 48 | 59 | 4 |
| M7c | 151 | 50 | 95 | 6 |
| M8a | 223 | 114 | 35 | 74 |
| M8b | 412 | 309 | 87 | 16 |
| M8c | 218 | 75 | 110 | 33 |
| M9 | 771 | 427 | 218 | 126 |
| M10 | 893 | 502 | 231 | 160 |
| M11 | 992 | 639 | 250 | 103 |
| M12 | 697 | 399 | 188 | 110 |
| M13 | 1296 | 739 | 385 | 172 |
| M14 | 755 | 0 | 1 | 754 |

Gộp theo mốc lớn (M8a, M8b, M8c thành M8...):

| Mốc lớn | File | must | should | could |
|---|---:|---:|---:|---:|
| M2 | 3 | 3 | 0 | 0 |
| M3 | 23 | 8 | 15 | 0 |
| M4 | 293 | 138 | 103 | 52 |
| M5 | 248 | 117 | 95 | 36 |
| M6 | 1117 | 609 | 377 | 131 |
| M7 | 359 | 171 | 165 | 23 |
| M8 | 853 | 498 | 232 | 123 |
| M9 | 771 | 427 | 218 | 126 |
| M10 | 893 | 502 | 231 | 160 |
| M11 | 992 | 639 | 250 | 103 |
| M12 | 697 | 399 | 188 | 110 |
| M13 | 1296 | 739 | 385 | 172 |
| M14 | 755 | 0 | 1 | 754 |

### Theo danh mục và mốc

| Mốc | characters | world | ui_story | vfx | audio | Tổng |
|---|---:|---:|---:|---:|---:|---:|
| M2 | 3 | 0 | 0 | 0 | 0 | 3 |
| M3b | 0 | 6 | 0 | 14 | 3 | 23 |
| M4 | 0 | 1 | 208 | 30 | 54 | 293 |
| M5 | 0 | 186 | 8 | 38 | 16 | 248 |
| M6 | 237 | 212 | 187 | 202 | 279 | 1117 |
| M7a | 27 | 0 | 8 | 43 | 19 | 97 |
| M7b | 42 | 0 | 1 | 50 | 18 | 111 |
| M7c | 0 | 16 | 72 | 36 | 27 | 151 |
| M8a | 50 | 0 | 0 | 155 | 18 | 223 |
| M8b | 160 | 32 | 23 | 98 | 99 | 412 |
| M8c | 14 | 0 | 36 | 117 | 51 | 218 |
| M9 | 142 | 347 | 32 | 106 | 144 | 771 |
| M10 | 152 | 314 | 40 | 246 | 141 | 893 |
| M11 | 267 | 280 | 67 | 202 | 176 | 992 |
| M12 | 152 | 285 | 30 | 127 | 103 | 697 |
| M13 | 245 | 556 | 75 | 216 | 204 | 1296 |
| M14 | 283 | 135 | 48 | 164 | 125 | 755 |

## 6. Cấu trúc thư mục đầu ra

```text
README.md                  file này
STYLE.md                   khối phong cách, điều cấm, bản tóm tắt âm thanh, bảng kích thước, quy tắc giao file
by-milestone.md            id và đường dẫn theo mốc, must trước
asset-manifest.json        toàn bộ mục (kèm prompt) cho công cụ
requests/INDEX.md          mục lục các nhóm
requests/<danh mục>/<nhóm>.md   các mục của một nhóm
```

## 7. Tạo lại danh sách

```bash
python3 tools/asset_requests/build_requests.py
# hoặc chỉ định thư mục:
python3 tools/asset_requests/build_requests.py --spec docs/assets/spec --out docs/assets
# kiểm tra font có đủ tiếng Việt (không cần spec):
python3 tools/asset_requests/build_requests.py --check-font assets/fonts/ui_body_pixel.ttf
# hoặc kiểm tra mọi font đã giao khi sinh danh sách (font chưa giao thì bỏ qua):
python3 tools/asset_requests/build_requests.py --check-fonts .
```

Script chỉ dùng thư viện chuẩn của Python 3, kiểm tra spec (xem mục 8) và thoát với mã 1 nếu có lỗi, khi đó không ghi gì. Kết quả giống hệt nhau giữa các lần chạy (không có dấu thời gian). Mỗi prompt lặp lại khối phong cách nên toàn bộ đầu ra rất nặng (hơn 100 MB); thêm `--slim-manifest` để `asset-manifest.json` không chứa prompt (nhẹ hơn nhiều).

## 8. Kiểm tra tự động khi sinh danh sách

- Đường dẫn là duy nhất (kể cả khi bỏ phân biệt chữ hoa thường) và id là duy nhất.
- Mọi mục ảnh có kích thước hợp lệ, có đuôi `.png`; SFX và giọng có đuôi `.wav`, nhạc và ambience có đuôi `.ogg`.
- Mọi ảnh vẽ pixel 1x1: khối phong cách còn đoạn RESOLUTION AND PIXEL SCALE, mọi hàng bảng cỡ có `block_px` 1, mọi dòng CANVAS ghi '1 art pixel = 1 game pixel', và không prompt ảnh nào còn nhắc khối pixel 2x2, chữ 'chunky', vẽ nửa kích thước hoặc nửa độ phân giải, 'upscale', 'art pixel' làm đơn vị riêng hay hai thang pixel 'world' và 'fine' (build thất bại, nêu nhóm và cụm từ). `python3 tools/asset_requests/build_requests.py --self-test` chứng minh luật bắt được những cụm đó và bỏ qua số ô như '2x2 cells'.
- Mọi quân cờ (nhóm có `piece_class`) vẽ trên canvas 32x32, có đoạn CELL FIT trong mô tả và đúng một hàng trong bảng cỡ; không sprite nào của lane nhân vật lớn hơn một ô trừ bàn tay của bé và Cỗ máy Luật (không phải quân cờ).
- Prompt tự đủ ý: không prompt nào nêu tên nhóm khác (id kiểu `ten_nhom`); thứ cần từ nhóm khác phải được viết thẳng vào prompt (màu thì dùng `{palette:<id>}`).
- Prompt cũng không được chỉ tới một file anh em bằng tên ('giống gate_closed_h', 'y hệt prop_closed.png', 'như path_pink_h', 'khung 1 của clip idle'): hình dạng, kích thước và màu cần có phải được mô tả thẳng trong prompt. Script bắt tên file có đuôi, tên file/thư mục/clip của mục khác đứng sau từ so sánh (same/identical/matches/as/like/than...) và kiểu '<clip> frame N' của một clip khác; chỉ gọi tên như nhãn ('lane_channel là vòng lặp khi vệt mọc') thì được.
- Nhạc là một bản hoàn chỉnh cho mỗi khu/boss: không còn chữ stem, lớp (layer) hay smpl trong nhóm nhạc/ambience; nhóm nhạc và ambience khai định dạng `ogg`, nhóm SFX và blip khai `wav`.
- Nhóm `sourcing` (glyph Kenney) mỗi file có `source` và mức chắc chắn `coverage` (tile / locate / compose); thư mục `assets/ui/glyphs` không còn nhóm vẽ tay.
- Mỗi clip có đúng `frames` tư thế (pose) mô tả.
- Mọi prompt chứa nguyên khối phong cách (ảnh) hoặc bản tóm tắt âm thanh (âm thanh).
- Không có đường dẫn nào nằm trong thư mục bị `.gitignore`.
- Tile phải có `tile_data`; mốc `needed_by` và `priority` hợp lệ.
- `avoid_profile` của nhóm/file phải là một biến thể có trong `style.json`; mọi biến thể `DO NOT` vẫn trỏ tới đoạn PERCENTAGES AND TRANSLUCENCY và giữ nguyên các điều cấm không liên quan (chữ, xanh crayon, đỏ san hô, trắng/đen tuyền); `reference_image` của nhóm phải là một ảnh tĩnh có thật.
- Bảng màu của nhóm tile không nêu quá 10 màu; khối phong cách còn đoạn PERCENTAGES AND TRANSLUCENCY và danh sách cấm trỏ tới nó.
- Nhóm blip giọng nói khai đúng số bản thu của từng bộ (`variations_by_event`) và `details_en` mô tả mọi bộ phụ.
- Dòng `PALETTE` của mọi prompt tự đủ ý: nhóm không được ghi 'xem bảng màu của khu' hay 'giống nhóm khác'. Khi một nhóm dùng màu của nhóm khác, spec ghi `{palette:<group_id>}` và script chép nguyên danh sách màu (kèm mã hex) của nhóm đó vào từng prompt; file có thể có `palette_en` riêng.
- Prompt không được dẫn tới tài liệu mà công cụ vẽ không mở được ('plan 10', 'fx1', 'pixel-art bible 7', 'gdd', 'docs/...', 'section 6.10', mã yêu cầu R<n>, mã quyết định D-<nn>, mã cảnh S<nn>): luật phải được viết thẳng trong prompt, nếu không build thất bại.
- Cảnh báo (không chặn): tên file kiểu cặp đôi (`pair`, `both`...), mô tả một đống/nhóm vật rời (`pile`, `scatter`, `heap`...; vật ghép mà chính nó là MỘT vật, ví dụ đống đổ nát, thì đánh dấu `compound_ok` kèm lý do) hoặc ảnh lớn hơn 128x96 (trừ logo, icon ứng dụng, bàn tay của bé).
- Khi dùng `--check-fonts <thư mục gốc repo>`: font đã giao trong `assets/fonts` phải phủ đủ bộ ký tự tiếng Việt, nếu không build thất bại.

### Ngoại lệ của kiểm tra

- Font (loại `font`, 4 mục): font do anh cung cấp, không có gì để vẽ, nên prompt của chúng là bản hướng dẫn tìm file. Các mục này được miễn quy tắc 'prompt chứa khối phong cách', quy tắc 'mục ảnh có kích thước' và kiểm tra PNG (thay bằng: đuôi phải là `.ttf` hoặc `.otf`).
- Dòng CANVAS trong prompt ảnh: mọi ảnh ghi 'một pixel vẽ = một pixel game' (quyết định của anh, 2026-10-13: tất cả 1x1, không còn ngoại lệ pixel to hơn cho tranh thế giới). Chỉ các file đánh dấu đặc (ô nền bản đồ, ô giấy, mảnh tile_ của vista, tile) ghi 'đặc hoàn toàn' thay cho 'nền trong suốt'.
- Dòng DO NOT: dòng chung viết cho MỘT vật đứng riêng trên nền trong suốt. Tile và ô nền đặc dùng biến thể `surface`, UI/9-patch/khung/hàng rào dùng biến thể `frame` (style.json, global_avoid_variants_en) để sàn, tường, bảng, hàng rào không bị chính dòng cấm đi kèm cấm vẽ. Mỗi biến thể giữ nguyên mọi điều cấm mà nó không nới.
- Glyph phím và tay cầm (loại `sourcing`): không vẽ, chỉ chép và đổi tên file từ bộ CC0 'Input Prompts Pixel' của Kenney. Prompt của chúng là bản hướng dẫn lấy file nên được miễn quy tắc 'prompt chứa khối phong cách'; đuôi phải là `.png`, canvas 16x16 như bộ gốc.
