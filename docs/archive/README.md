# Archive

Documents kept for history only. They describe a design or a code base that no longer
exists, or a plan that a newer plan replaced. Do not follow them; every file here carries a
banner saying what superseded it. Moved with `git mv` on 2026-10-12 (M1a, docs lane); the
content is unchanged apart from that banner.

| Archived file | Why it was archived | Read instead |
|---|---|---|
| `restructure-plan.md` | A "not scheduled" blueprint for a feature-based folder layout whose target tree (`features/enemies/components/grid_movement`, ...) names node-era files that were deleted in the ECS conversion. | `docs/game-base-plan.md` section 13 (target tree, change table, safe migration) |
| `vault/` (12 Obsidian notes: Home, Grid World, Movement, Player, Data Resources, Enemy AI, Enemy Composition, Combat and Telegraph, World and Rooms, Presentation, Glossary, Script Index) | Every note explains the node-era code (`GridWorld`, `FreeEnemy`, `PawnHero`, `EnemyActor`, `EncounterDirector`, component nodes, `scripts/core`, `scripts/actors`, `scripts/entities`, `scripts/components`). None of that code exists any more. The one note that still lists real schemas (`Data Resources`) also names `FreeEnemy._apply_definition()` and a `visual_scene` field that are gone, so it was archived with the rest. | `docs/ARCHITECTURE.md` (the code as built) |

The vault's Obsidian settings folder (`vault/.obsidian/`) stays gitignored.
