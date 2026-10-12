# M1b migration notes

What moved where during M1b ("Folder migration", `docs/game-base-plan.md` section 15), and every place where the
plan's table (section 13.6) met something it did not expect and a call had to be made. Written by the agents doing
the moves; the owner can overrule any line here with one more `tools/move_res.py` move.

How to read this file: paths are written from the project root and never with the `res://` prefix on purpose,
because `tools/move_res.py` rewrites every `res://` string it finds in a `.md` file and this file describes
moves that already happened. The exact move list, oldest first, is `tools/move_res_log.tsv`.

## Step 2: the code (this section)

Rule for the whole step: only `tools/move_res.py` moves a file (git mv, sidecars, `res://` rewrite). No script
was split or rewritten, no `class_name` was renamed, no scene changed except the `path=` text of an
`ext_resource` line (its `uid=` is untouched). `scripts/main.gd` stays one file; its split is M3b.

### Decisions where the plan's table needed a call

| Case | Plan says | What was done | Why |
|---|---|---|---|
| `DifficultyProfile` | the schema tree lists it on a shared line, `feel/ audio/` | `schema/feel/difficulty_profile.gd` | it is tuning of how hard the game feels; `schema/audio/` is for `SoundBank` and `MusicCues` |
| `EnemyIntent` | `scripts/ai/*` goes to `schema/*` | `ecs/systems/decide/enemy_intent.gd` (its sibling `AttackPattern` does go to `schema/attacks/`) | `EnemyIntent` is not a Resource: it is the plain `RefCounted` that `EnemyAISystem` builds while it decides, and nothing else names it. `schema/` is "one Resource class per file"; the decide phase is where its only reader lives |
| `RuleEntry`, `RuleBook` | `RulePage` lives in `schema/world/` | `schema/world/rule_entry.gd`, `schema/world/rule_book.gd`, names unchanged | the rename to `RulePage` is M7c; a rename now would break serialized references |
