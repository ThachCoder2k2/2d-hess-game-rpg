# Owner decisions — the verbatim record

Every decision the owner takes, quoted as typed (Vietnamese), with the meaning the
build follows. Agents add a row here whenever the owner decides something; nothing
counts as owner-approved unless it is quoted here or in `progress.md`.

Newest first.

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
| Pawn sprite: keep 32x40 with a 26x32 body, or widen to 36x40? | "quân cờ phải nhỏ hơn ô chứ nhỉ? không vừa cũng chẳng to hơn và dĩ nhiên là phải sửa scene" | **A piece is smaller than its cell.** Every chess piece is drawn inside its 32x32 cell with a margin — never exactly cell-sized, never taller than the cell. Relative heights follow a real chess set (pawn lowest, king tallest). This reverses the 2026-07 convention (task_plan phase 66: pieces 1.5 cells tall overlapping the row above). The actor scenes (sprite offset, health pips, facing arrow, weapon anchor), the chess sprite generator and the asset size table change to match; the scene work lands in M2 (one shared actor view). Assumed to include bosses (they are chess pieces too) until the owner says otherwise. |
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
