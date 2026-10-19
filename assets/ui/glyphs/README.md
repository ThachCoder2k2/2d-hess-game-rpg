# assets/ui/glyphs: the owner's key and gamepad pictures

This folder is where the pictures of the control prompts go (the Controls panel and every prompt that shows a key or a
button). **Nothing is downloaded into it by the project:** the files are the owner's (docs/owner-decisions.md,
2026-10-12), copied from Kenney's CC0 pack "Input Prompts Pixel" (kenney.nl/assets/input-prompts-pixel). Until a file
is here the game shows the words instead (`[Space]`, `[W]`, `[A]`, `[LB]`, `[Left Stick Up]`), which are readable on
their own.

Put each file at exactly this path (the names are the asset list's: `docs/assets/spec/ui_story.json`, group
`glyphs_kenney`, whose `source` column says which tile of the pack to copy; use the LIGHT tiles, 16x16, no recolour, no
resize). Overwriting a file swaps the picture; deleting it gives the words back. After adding files open the project in
Godot once so it imports them, and add the pack to `THIRD_PARTY_NOTICES.md` (the entry "Input glyphs (owner-supplied)" says how).
`presentation/ui/input_glyphs/input_glyphs.gd` holds the table of which key or button uses which file, and
`tests/input/test_input_glyphs.gd` fails if it names a file the asset list does not.

| File | What it shows | Hình |
|---|---|---|
| `keyboard/key_w.png` | Keycap for the W key (move up) | Phím W |
| `keyboard/key_a.png` | Keycap for the A key (move left) | Phím A |
| `keyboard/key_s.png` | Keycap for the S key (move down) | Phím S |
| `keyboard/key_d.png` | Keycap for the D key (move right) | Phím D |
| `keyboard/key_q.png` | Keycap for the Q key (Pencil Thrust) | Phím Q |
| `keyboard/key_f.png` | Keycap for the F key (Rule Step) | Phím F |
| `keyboard/key_g.png` | Keycap for the G key (Guard) | Phím G |
| `keyboard/key_r.png` | Keycap for the R key (call the child) | Phím R |
| `keyboard/key_e.png` | Keycap for the E key (interact) | Phím E |
| `keyboard/key_b.png` | Keycap for the B key (open the Book) | Phím B |
| `keyboard/key_k.png` | Keycap for the K key (alternate attack) | Phím K |
| `keyboard/key_c.png` | Keycap for the C key (skill slot 3, declared but unused) | Phím C |
| `keyboard/key_v.png` | Keycap for the V key (skill slot 4, declared but unused) | Phím V |
| `keyboard/key_arrow_up.png` | Keycap with an up arrow (move up) | Phím mũi tên lên |
| `keyboard/key_arrow_down.png` | Keycap with a down arrow (move down) | Phím mũi tên xuống |
| `keyboard/key_arrow_left.png` | Keycap with a left arrow (move left) | Phím mũi tên trái |
| `keyboard/key_arrow_right.png` | Keycap with a right arrow (move right) | Phím mũi tên phải |
| `keyboard/key_tab.png` | Keycap for the Tab key (next help page) | Phím Tab |
| `keyboard/key_ctrl.png` | Keycap for the left Ctrl key (focus) | Phím Ctrl |
| `keyboard/key_alt.png` | Keycap for the left Alt key (the Free Step modifier) | Phím Alt |
| `keyboard/key_esc.png` | Keycap for the Esc key (pause) | Phím Esc |
| `keyboard/key_f3.png` | Keycap for the F3 key (debug overlay) | Phím F3 |
| `keyboard/key_f11.png` | Keycap for the F11 key (fullscreen) | Phím F11 |
| `keyboard/key_shift.png` | Keycap for the Shift key (turn mode), drawn as a hollow up arrow | Phím Shift |
| `keyboard/key_enter.png` | Keycap for the Enter key (advance dialogue), drawn as a return arrow | Phím Enter |
| `keyboard/key_space.png` | The Space bar keycap (attack, advance dialogue) | Phím cách |
| `gamepad/btn_a.png` | The A face button (confirm) | Nút A |
| `gamepad/btn_b.png` | The B face button (cancel) | Nút B |
| `gamepad/btn_x.png` | The X face button | Nút X |
| `gamepad/btn_y.png` | The Y face button | Nút Y |
| `gamepad/btn_lb.png` | The left bumper (LB) | Nút LB |
| `gamepad/btn_rb.png` | The right bumper (RB) | Nút RB |
| `gamepad/btn_lt.png` | The left trigger (LT) | Nút LT |
| `gamepad/btn_rt.png` | The right trigger (RT) | Nút RT |
| `gamepad/btn_l3.png` | The left stick click (L3) | Nhấn cần trái (L3) |
| `gamepad/btn_r3.png` | The right stick click (R3) | Nhấn cần phải (R3) |
| `gamepad/btn_start.png` | The Start (menu) button | Nút Start |
| `gamepad/btn_back.png` | The Back (view/select) button | Nút Back |
| `gamepad/dpad_up.png` | The D-pad with the up arm pressed | D-pad lên |
| `gamepad/dpad_down.png` | The D-pad with the down arm pressed | D-pad xuống |
| `gamepad/dpad_left.png` | The D-pad with the left arm pressed | D-pad trái |
| `gamepad/dpad_right.png` | The D-pad with the right arm pressed | D-pad phải |
| `gamepad/stick_left_up.png` | The left stick pushed up | Cần trái lên |
| `gamepad/stick_left_down.png` | The left stick pushed down | Cần trái xuống |
| `gamepad/stick_left_left.png` | The left stick pushed left | Cần trái trái |
| `gamepad/stick_left_right.png` | The left stick pushed right | Cần trái phải |
| `gamepad/stick_right_neutral.png` | The right stick, neutral | Cần phải |

The asset list names more files than the game uses today (blank caps, the plus and slash connectors, the device
icons, the neutral d-pad and the two sticks' move glyphs): they are for the prompts and screens of later steps, so the
table above lists only what the lookup can ask for now.

---

# assets/ui/glyphs: hình phím và nút tay cầm của chủ dự án

Thư mục này chứa hình phím và nút tay cầm hiện trong bảng Controls và các dòng gợi ý phím. **Dự án không tự tải hình nào về:** file là của
chủ dự án, chép từ bộ CC0 "Input Prompts Pixel" của Kenney. Chưa có file thì game hiện chữ (`[Space]`, `[A]`...), đọc được ngay. Đặt đúng
đường dẫn ở bảng trên (tile nào đặt tên gì: cột `source` của nhóm `glyphs_kenney` trong `docs/assets/spec/ui_story.json`), chép đè là đổi hình, xoá file là
trở về chữ. Chép xong mở dự án trong Godot một lần để nó import. Cách làm từng bước nằm trong `docs/OWNER_GUIDE.md` mục 8.
