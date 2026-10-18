# Owner decisions — the verbatim record

Every decision the owner takes, quoted as typed (Vietnamese), with the meaning the
build follows. Agents add a row here whenever the owner decides something; nothing
counts as owner-approved unless it is quoted here or in `progress.md`.

Newest first.

---

## 2026-10-13 — pixel density and boss size

Picked in chat after viewing the M2 preview (`assets/_generated/previews/pieces_in_cells.png`):

| Question | Owner's answer | What the build does |
| --- | --- | --- |
| Pixel density: pieces were placeholdered at 1x1 pixels while the asset list asked for all world art (pieces, tiles, props) in chunky 2x2 blocks | "Tất cả 1×1" (all 1x1) | **Everything is drawn at 1x1 pixels** at the native 640x360: pieces, tiles, props, world effects, UI, icons, portraits. No 2x2 chunky art anywhere. The asset request style block and every prompt change to match; the placeholder generators that still draw 2x2 blocks (kingdom tiles, Stage 1 room art) are brought to 1x1 when next touched. |
| Does a boss fit in one cell like an ordinary piece? | "tuỳ boss" (it depends on the boss) | **Per boss**, chosen by role (agent proposal, the owner may change any row — one data row each): Black Pawn Captain 1 cell · Knight Captain 1 cell · Bishop Oracle 1 cell · Rook Warden **2x2 cells in phases 1-2, 1 cell in phase 3** (the fortress shrinks when it breaks its own throne) · Queen of Tricks 1 cell · Black King 1 cell, with the Rule Engine machine behind him **3x3 cells**. A multi-cell piece still follows "smaller than its cells": its body stays inside its footprint with a 2 px margin. The engine gains multi-cell footprints (occupancy, movement, hits on any covered cell, telegraph origin) in M8b, the boss framework. |

---

## 2026-10-12 — asset delivery and the size of a piece

**Assets are the owner's, one file per thing.**

> "à, có một cái, bạn đang làm logic thôi chứ nếu mà cần asset gì thì bảo để tôi cấp cho bạn nhé, phải có prompt đầy đủ với mỗi thứ bạn cần, vẽ từng thứ 1 chứ không phải là 1 cái gì đó quá lớn để sau này tôi còn thay assets chuẩn vào nhé"

> "số lượng phải nhiều chứ nhỉ, vì nó là cả game mà"

Meaning: agents build logic only. Every art and audio asset the game needs is
requested from the owner with a complete prompt, one file per thing (one tile, one
prop, one icon, one animation frame, one sound) — never sheets, atlases or painted
rooms. Tools assemble atlases and rooms from the single files. The request list
covers the whole game. Placeholders stand in until the owner's file lands at the
same path. Built as `docs/assets/` (spec + generator + requests).

**Answers to the asset questions (picked or typed in chat):**

| Question | Owner's answer | What the build does |
| --- | --- | --- |
| Pawn sprite: keep 32x40 with a 26x32 body, or widen to 36x40? | "quân cờ phải nhỏ hơn ô chứ nhỉ? không vừa cũng chẳng to hơn và dĩ nhiên là phải sửa scene" | **A piece is smaller than its cell.** Every chess piece is drawn inside its 32x32 cell with a margin — never exactly cell-sized, never taller than the cell. Relative heights follow a real chess set (pawn lowest, king tallest). This reverses the 2026-07 convention (task_plan phase 66: pieces 1.5 cells tall overlapping the row above). The actor scenes (sprite offset, health pips, facing arrow, weapon anchor), the chess sprite generator and the asset size table change to match; the scene work lands in M2 (one shared actor view). Assumed to include bosses (they are chess pieces too) until the owner says otherwise. **Built (M2 step 2):** the sizes are `content/feel/piece_sizes.tres` (pawn 18 x 22, knight, bishop and rook 20 x 24, queen 22 x 26, king 22 x 28; every base line 14 px below the cell centre; 2 px margin on the 32 px cell; bosses are a row with a bigger footprint when the first one exists); the generator draws to that table, on the 32 x 32 canvas of the art spec (the knight was retraced on 15 rows to fit, the black pawn and the bishop were added); a body picture is the canvas with its drawn pixels inside the kind's box, or a tight picture no larger than the box; `actor_view_base.tscn` places everything an actor draws within 14 px of the cell centre; `test_pieces_inside_cell` measures it and `tools/render_actor_preview.gd` draws it. |
| Keyboard and gamepad glyphs | "Dùng Kenney CC0" | Use Kenney's CC0 pixel input-prompt pack as the long-term placeholder; the owner downloads it; any glyph can later be overwritten by a hand-drawn file at the same path. |
| Audio format and music | "SFX WAV, nhạc OGG, 1 bài/khu" | SFX are WAV; music and ambience are OGG; one track per area (no stems in the base). |
| The 319 deferred "could" files (291 enemy variants, 28 fallen-piece remains) | "Để sau" | They stay in the list at priority could, ordered last. |

---

## 2026-10-12 — gate OG0 and the base plan

Recorded in full in `progress.md` ("Owner directions and gate OG0 — 2026-10-12").
In short:

> "game không phải mỗi gameplay mà phải kể 1 câu chuyện ... tôi chỉ muốn bạn dựng 1 cái base đẩy đủ tất cả, còn lại tôi sẽ vẽ và nâng cấp story ... nghiên cứu về cảm xúc con người khi chơi game nữa nhé, tôi tin bạn"

> "gameplay cũng phải có lộ trình tăng tiến rồi kĩ năng đàng hoàng nhé, sau đó nhớ là sắp xếp code và folder một cách mà tôi có thể nhảy vào xử lý mà không phải thay đổi quá nhiều trước hết là dựa theo ecs design pattern"

| Question | Owner's answer |
| --- | --- |
| Move all code and folders to the ECS tree and amend CLAUDE.md to match | "Đồng ý" |
| Controls and rules of plan §2.3 (R = call child, Q locked until T4, swing movement lock, buffer expiry; drop aim time-slow, Gentle Nudge, Rest Squares) | "Đồng ý hết" |
| Source language of the story | "Tiếng Anh, Việt sau" |
| Cleared rooms on return | "Giữ sạch" |

Plan: `docs/game-base-plan.md` v1.1. Tag `pre-restructure` marks the last commit
before the restructure.
