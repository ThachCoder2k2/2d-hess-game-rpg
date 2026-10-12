# Hướng dẫn cho chủ dự án (Owner Guide)

> **Trạng thái (Status): STUB.** Tạo ở milestone M1a (2026-10-12). Các milestone M1b-M14 của
> `docs/game-base-plan.md` sẽ điền dần vào bảng ở mục 5; M14 viết bản đầy đủ.
>
> **Ngôn ngữ:** tiếng Việt đứng trước, thuật ngữ tiếng Anh giữ nguyên. Nếu hai bản khác nhau thì
> **bản tiếng Anh là bản chuẩn** (plan D19). Phần tiếng Việt do agent viết, chưa có người bản ngữ
> rà lại; bạn cứ sửa thẳng vào file nếu thấy sai.
>
> *EN: A stub for the owner. Vietnamese first, English authoritative where they differ. The
> "how to change X" table in section 5 is a placeholder that milestones M1b-M14 fill in.*

## 1. Chơi bản build hiện tại (How to play the current build)

1. Cần Godot 4.6. Mở `project.godot` trong Godot rồi bấm **F5** (cảnh chính là `scenes/main.tscn`).
   Hoặc, trong terminal tại thư mục dự án (Godot nằm ở thư mục cha của dự án):
   `../Godot.app/Contents/MacOS/Godot --path .`
2. **Clone mới:** art sinh bằng script không có sẵn trong repo, nên Godot sẽ báo thiếu texture. Làm
   theo mục "First run after a fresh clone" trong `README.md` (4 lệnh generator và một lần import).
   M1a thêm `tools/bootstrap_worktree.sh` để làm cả chuỗi đó bằng một lệnh.
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

*EN: Open `project.godot` in Godot 4.6 and press F5, or run the binary with `--path .`. On a fresh
clone, build the generated art first (README, "First run"). Delete `world_state.cfg` in the user
data folder to restart the run. No title, pause, settings or gamepad yet (milestone M4).*

## 2. Trạng thái nằm ở đâu (Where status lives)

| File | Dùng để làm gì |
|---|---|
| `docs/where-we-are.md` | **Trạng thái thật**: mỗi mảng đang ở bước nào, rủi ro, lộ trình, và các quyết định chỉ bạn chốt được |
| `docs/game-base-plan.md` | **Kế hoạch xây bản base hoàn chỉnh**: các quyết định đã chọn, milestone M1a-M14, các cổng OG0-OG4 |
| `docs/claude-md-diff.md` | Những dòng của `CLAUDE.md` sẽ đổi (cũ → mới), chờ bạn duyệt ở cổng OG0 |
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
| OG0 | cuối M1a, trước M1b | đọc `docs/claude-md-diff.md`, bảng luật đứng (plan §2.3), kế hoạch di chuyển thư mục |
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

Trong Claude Code, tại thư mục dự án, gõ **`/verify`**. Nó chạy: bộ test logic, sáu runtime test,
bước import của editor và `git diff --check` (chi tiết trong `.claude/commands/verify.md`).

Kết quả đúng là:

- `TESTS COMPLETE: 0 failure(s)`;
- mỗi runtime test in dòng `... TEST: PASS` (`ecs_runtime`, `ecs_combat`, `ecs_enemy`,
  `room_encounter_runtime`, `encounter_hud_runtime`, `zone_travel_runtime`);
- bước import không có dòng `ERROR` hay `Parse`;
- `git diff --check` không in gì.

Từ M1a có một lệnh duy nhất, chạy mọi suite, mỗi suite một tiến trình có giới hạn thời gian và báo
lỗi nếu có `SCRIPT ERROR`:

```bash
python3 tools/run_all_tests.py          # thêm --strict để cảnh báo mềm thành lỗi
```

Chạy tay một suite (Godot nằm ở thư mục cha, đường dẫn dự án có dấu cách nên phải để trong ngoặc kép):

```bash
HOME=/tmp/unbound-pawn-godot ../Godot.app/Contents/MacOS/Godot --headless --path . -s tests/run_tests.gd
```

*EN: Type `/verify` in Claude Code. Expect `TESTS COMPLETE: 0 failure(s)`, `PASS` from the six
runtime tests, a clean import and a silent `git diff --check`. `python3 tools/run_all_tests.py` is the
one-command runner from M1a.*

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
- **Khi M1b chạy** (di chuyển toàn bộ thư mục), hãy tránh sửa `.tscn`/`.tres` trong editor, hoặc báo
  trước. M1b chạy trong một worktree riêng; nếu bạn vẫn sửa, các file đã đổi của bạn được rewrite
  đường dẫn bằng script chứ không merge tay (plan §13.6).
- Mọi thứ trong tương lai ở thư mục `content/` là **của bạn**: dữ liệu, art, âm thanh, lời thoại, và
  không có file `.gd` nào ở đó.

## 5. Bảng "Muốn đổi X thì sửa Y" (How do I change X?) — placeholder

**Hôm nay (trước M1b)**, các việc hay làm nằm ở đây:

| Bạn muốn... | Hôm nay sửa ở đâu |
|---|---|
| Chỉnh một enemy (máu, tốc độ, AI, kiểu tấn công) | `resources/enemies/<id>.tres` và các `.tres` nó trỏ tới trong `resources/movement/`, `decisions/`, `attacks/` |
| Thêm một enemy mới không cần code | lệnh `/new-enemy` (xem `.claude/commands/new-enemy.md`) |
| Đổi bố cục phòng hoặc chỗ đứng của enemy | mở `scenes/rooms/<phòng>.tscn`, kéo node (enemy là node `ActorView` đậu trên một ô) |
| Chỉnh cảm giác con tốt (bước, courage, invulnerability, kiếm) | các node `MovementComponent`, `InputComponent`, `CombatComponent`, `HealthComponent` trong `objects/actors/player.tscn`, và `resources/attacks/wooden_sword.tres`, `pencil_thrust.tres` |
| Đổi sprite | thay file PNG trong `assets/sprites/generated/` (các sprite gốc được track) hoặc vẽ tay vào `assets/art/pieces/` |
| Đổi âm thanh sự kiện / âm thanh chuyển động | `objects/audio/sfx_manager.tscn` (mục `streams` trong Inspector) / track âm thanh trong clip của actor |
| Đổi phím | `project.godot`, mục `[input]` (hoặc Project Settings → Input Map) |
| Đổi chữ (thoại, thông báo) | còn nằm rải rác: `RoomEncounter` trong scene phòng, `.tres` của `RoomObjective`, `scripts/main.gd`, `scripts/ui/hud.gd`. Hệ thống `.po` đến ở M4 |

**Bảng đích** (từ `docs/game-base-plan.md` §13.5). Đường dẫn `content/...` **chưa tồn tại** cho tới
khi M1b (di chuyển thư mục) và M2 (registry) xong. Cột cuối ("available after Mx") là milestone sau đó hàng ấy mới đúng. Plan
không ghi milestone cho từng hàng, nên cột này là cách đọc của docs lane từ §15 và sẽ được kiểm lại ở
mỗi milestone. Khi một milestone xong, nó phải kiểm đường dẫn thật của các hàng thuộc về mình và xoá
chữ "available after Mx" ở hàng đó.

| Bạn muốn... (You want to...) | Sửa file này (Edit this) | Số file (Files) | Cần code? (Code?) | Trạng thái (Status) |
|---|---|---|---|---|
| Thêm một biến thể enemy (đổi skin, máu, tốc độ hoặc vũ khí) (Add a variant enemy (re-skin, new health, speed or weapon)) | `content/enemies/<id>/enemy.tres` (reusing `_shared` sub-resources), `body.png`; in a room, instance `actor_view_base.tscn` and set `definition`; the `ENEMY_<ID>_NAME` row in `story/text/<locale>/story.po`. | 4 | no | available after M2 (dòng tên trong `.po`: M4) |
| Thêm enemy có hành vi mới (Add an enemy with new behaviour) | `enemy.tres` + one `EntityComponent` or `AttackBase` script + one system file + one line in `ecs/schedule/<phase>.gd`; plus `events.gd` if it emits a new event and `ViewSyncSystem` if its visuals are new. | 4 new, up to 3 existing edited | yes | available after M3a (kiểu tấn công mới: M8a) |
| Chỉnh (retune) một enemy hoặc boss (Retune an enemy or boss) | its `.tres` | 1 | no | available after M2 (enemy), M8b (boss) |
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
| Đổi enemy hoặc bố cục của một phòng (Change a room's enemies or layout) | that `room.tscn` | 1 | no | available after M1b |
| Đổi một khoá (lock) hoặc thêm lối tắt (shortcut) (Change a lock or add a shortcut) | the exit or gate marker in `room.tscn` + the `locked_message` row | 2 | no | available after M5 |
| Thêm một prop chỉ xuất hiện khi đủ điều kiện (Add a prop that appears after a condition) | a `StateVariantMarker` on the prop in `room.tscn` | 1 | no | available after M6 |
| Đổi cách hub tiến hoá hoặc các biến thể ending (Change the hub evolution or ending variants) | `StateVariantMarker` props in H1's `room.tscn`, `ending.tres` | 1-2 | no | available after M6 (hub), M13 (ending) |
| Thêm pickup, shard hoặc keepsake (Add a pickup, shard or keepsake) | `pickup.tres`, `pickup.png`, a spawn in `room.tscn`, a `.po` row (+ a milestone row if it grants) | 4-5 | no | available after M7c |
| Thêm NPC hoặc cuộc giải cứu (rescue) (Add an NPC or rescue) | a prop with an `InteractComponent`, a beat, a flag in `flags.tres`, `room.tscn`, `.po` rows | 5 | no | available after M6 |
| Thêm một boss (Add a boss) | `boss.tres`, `enemy.tres`, `body.png`, the arena `room.tscn`, beats + `.po` rows, a milestone row, a `music_cues` row | 7-10 | no, if its attacks use existing kinds | available after M8b |
| Thêm hoặc chỉnh một phase của boss (Add or retune a boss phase) | `boss.tres` (a new windup clip also edits the boss's actor scene) | 1-2 | no | available after M8b |
| Đổi sprite (Swap a sprite) | overwrite `body.png` (+ `VisualDefinition.anchor_offset` if the frame size changes); the placeholder flag clears by hash | 1-2 | no | available after M2 |
| Đổi art nền của một phòng (Swap a room's art) | overwrite `background.png` | 1 | no | available after M1b |
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

*EN: The first table lists today's real locations. The second is the target Owner Change Table from
plan §13.5; each row says which milestone makes it true. Until then the `content/` paths do not exist.*

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
| placeholder | nội dung tạm do agent làm (art, lời, nhạc, số liệu) để bạn thay bằng tay |
| gate (OG0-OG4) | điểm dừng để bạn duyệt hoặc chơi thử trước khi làm tiếp |
