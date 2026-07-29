# The Unbound Pawn — Soulslike World Plan

Research-backed plan for replacing the single-room structure with a Dark Souls
style interconnected world. Owner-scoped to THE MAP and BOSS FIGHTS only:
zones, shortcuts/loops, bosses, hand-authored world. No bonfire system, no
corpse run, no leveling (cut by owner decision — the research on them stays
below for reference). Death = the current behavior, zone reloads.
Written 2026-07-28; sources at the bottom.

## Part 1 — What the research says

### FromSoft world structure (DS1–3, Bloodborne)
- **DS1 is the gold standard because of loops, not size.** The whole early game
  spirals out of one hub (Firelink) and keeps folding back into it via unlocked
  shortcuts. The core trick, distilled by level-design writeups: *"a path that
  could be reached in a straight line is forcibly made into a circle."* The
  shortcut-open moment is narrative architecture — the world reveals itself as
  one coherent whole.
- **No early fast travel forced spatial mastery.** Players memorized the world
  because they had to walk it. Later games (DS3 linear-with-branches,
  Bloodborne hub-warping) traded the interconnection away for production speed;
  every retrospective calls that a loss.
- **Bloodborne's Central Yharnam = the formula in one zone**: essentially one
  path until the first lantern shortcut opens, then the level fans into three
  routes that all keep reconnecting to the same lantern. Loops double as
  difficulty pacing: a route that was lethal on first pass becomes the trivial
  commute later.

### Checkpoints (bonfires/lanterns)
- Resting resets: all normal enemies respawn, traps reset, healing refills.
- Persists forever: bosses dead, doors/shortcuts opened, items taken.
- Checkpoints are deliberately sparse; **shortcuts substitute for checkpoint
  density**. A shortcut effectively multiplies one checkpoint into several
  (Death's Door runs its whole structure on this).
- The checkpoint is the emotional safe-haven; distance from it is the tension
  dial (Blighttown works because Firelink feels far away).

### Shortcuts
- One-way until opened: gate unbars from the far side, ladder kicks down.
  On a top-down grid the equivalents are: locked gates operable from one side,
  levers, collapsed bridges, key doors.
- Pacing role: long tense push → shortcut opens → relief + mastery. Target
  rhythm from Death's Door critique: opening one "every couple of minutes" is
  almost too often; DS1 spaces them per-zone.

### Bosses
- Fog gate = commitment: arena seals, no escape, checkpoint-adjacent runback
  (bosses in Death's Door "almost always have a checkpoint right outside" —
  reviewers loved it; long runbacks are the single most criticized element of
  the whole genre).
- Boss death is the canonical permanent event: gates progress, stays dead.

### Enemy placement
- Every encounter is hand-placed and teaches something; ambush grammar (first
  one enemy, then the same corner with two), elite/normal rhythm, density
  matched to corridor width. No random spawns anywhere in the genre.

### Death loop (corpse run)
- Die → drop currency at death cell → one retrieval chance → lose it if you
  die again. Creates real stakes without destroying progress (progress = the
  world state, which never rolls back). Critics' caveat: if the run back is
  boring, players just sprint past everything — keep runbacks short and let
  shortcuts do the work.

### Landmarks + readability (top-down translation)
- FromSoft uses visible destinations (Anor Londo on the horizon) and vertical
  layering. Top-down games translate this as: distinct palette + tile
  vocabulary per zone (Hyper Light Drifter), landmark structures at junctions
  (Tunic), and small-but-distinctive layouts instead of maps (Death's Door —
  which got criticized for having *no* map once areas grew; Hollow Knight's
  purchasable map is the loved middle ground).

### The 8 rules we build by (map + bosses scope)
1. Zones loop back to their entrances; never pure corridors.
2. A shortcut is one-way until opened from the far side; open state is forever.
3. Re-entering a zone respawns normal enemies; bosses/gates/items never reset.
4. Boss arenas seal (fog gate) and sit close to a zone entrance or shortcut
   mouth — the runback must be short.
5. Every encounter hand-placed; encounters teach.
6. Each zone gets its own palette + a landmark readable from its junctions.
7. No fast travel (spatial mastery first; the map is small enough to walk).
8. World state is one store keyed by stable IDs; the world is one graph.

## Part 2 — Theme mapping (chess kingdom)

| Souls concept | The Unbound Pawn |
|---|---|
| Lordran / Yharnam | The Kingdom — one continuous chessboard-land, zones = districts |
| Fog gate | **The Black Line** — a rank of shadow sealing the boss arena |
| Bosses | Major pieces; **first boss = the Knight** (owner decision) |
| Road enemies | **Pawns with special powers** — every regular enemy is a pawn variant |
| Shortcut gate | Castle gates, drawbridges, rook-tunnels ("castling passages") |
| Item descriptions / lore | **The Book of House Rules** (see below) |
| Player death | "The child resets the board" — the zone reloads (kept as-is) |

(Cut by owner decision: White Shrine bonfires, Resolve corpse-run, Promotion
leveling. Revisit later if wanted — the research above still applies.)

## Part 2.5 — Content design (owner direction, 2026-07-28)

**Chess rules are the law of the world.** Every piece moves and captures the
way chess says it does — the existing data already enforces this (pawn
diagonal capture, knight L-jumps live in MovementConfig/AttackPattern .tres).
Drama comes from *amendments*: a pawn variant or a boss bends exactly ONE
rule, and every bend is written down.

**The Book of House Rules** — an in-game book (UI screen) listing rule
changes. Each entry is a `.tres` (`RuleEntry`: piece name, the original chess
rule, the amended rule, flavor line). An entry unlocks the first time the
player meets the piece that bends it (event-driven: the bridge sees the
encounter event, tells the book). The book doubles as the game's enemy
compendium, lore delivery, and tutorial — soulslike item-description
storytelling, chess-flavored.

**The road to the Knight: pawn variants.** Every regular enemy between the
start and the first boss is a pawn with one special power = one amendment.
Examples to author (all data-only via /new-enemy — definition + movement +
decision + attack .tres, zero script):
- *Pawn Recruit* (exists): the baseline — the book's first entry states the
  unbroken rule: forward march, diagonal capture.
- *Armed Pawn* (exists): "A pawn holding a weapon strikes as the weapon."
- *Backstep Pawn*: may retreat — "Pawns may move backward."
- *Charging Pawn*: always moves two squares — "The first-move charge never
  ends."
- *Passant Wraith*: captures the player when passed — "En passant applies to
  you."
- *Promoted Zealot* (elite, guards the boss door): a pawn one rank from
  promotion, faster and armed — "A pawn near the last rank forgets fear."

**First boss: the Knight (the Knight Errant).** Chess-legal L-jumps over any
piece and pit (terrifying on a grid — no corridor is safe), telegraphed
landing cells; its ONE amendment, revealed mid-fight and written to the book:
**"The Knight may move twice."** (chained double-jump in phase 2 of the
fight). Arena sealed by the Black Line; defeat is permanent; the reward gate
opens the road onward.

## Part 2.6 — Drawn design (locked 2026-07-28)

**The five boards, one loop:**

| Zone | Board | Palette | Landmark | Population |
|---|---|---|---|---|
| 1. The Toybox Yard (start) | 20×11 | warm amber | chess-clock tower | teach sequence below |
| 2. The Chalk Gardens | 24×12 | chalk green | giant inkwell | Charging Pawns in open lanes |
| 3. The Bookshelf Pass | 22×10 | book purple | leaning book monolith | Passant Wraiths in passages, optional treasure |
| 4. The Stable Approach | 14×9 | stable gray | knight statue | Promoted Zealot at the door |
| 5. The Knight's Stable (arena) | 11×9 | black/red | the Black Line | the Knight Errant |

Graph: 1→2 (north), 2→3 (east), **3→1 one-way gate (the loop home)**,
3→4 (north), 4→arena. Reward gate in the arena opens the road onward.
Short approach zone before the boss = short retries (anti-runback rule).

**Zone 1 teach sequence** (route S→N, drawn in the layout diagram):
① lone Pawn Recruit in the open → ② recruit pair behind a blind corner
(ambush grammar) → ③ Armed Pawn guarding the weapon pickup → ④ Backstep
Pawn in a corridor (retreat rule bend where it hurts). East-edge amber gate
stays locked until entered from Zone 3.

**Knight Errant numbers:** HP 12 (normals run 2–3), phase shift at 6.
Chess-legal L-jumps that ignore walls/pits; landing cell telegraphed 0.9s;
landing recovery 1.2s = the whole damage window. Phase 2 amendment
("The Knight may move twice") = chained jump pairs, second landing
telegraphed mid-flight; the book flashes the new entry mid-fight. Black
Line seals the entrance row on entry. Player HP stays 3.

**Book UI (drawn as mockup):** two-page spread — left = entry list
(check = read, lock = "unread ink"), right = open entry: piece name,
"first met in" line, Original rule (muted), Amendment (accent block),
flavor line in the serif voice. Counter: "N of M amendments known."

## Part 2.7 — World v2: the DS3 opening skeleton (owner direction, 2026-07-29)

The three-zone triangle was too simple. Rebuilt on Dark Souls 3's opening
structure (Cemetery of Ash → Iudex Gundyr → Firelink Shrine → High Wall):

| DS3 | Ours | Shape |
|---|---|---|
| Cemetery of Ash | The Toybox Yard, 24×13 | tutorial road: item BEHIND spawn (backtrack lesson), fountain landmark, soft west "hills" branch (backstep guard + ruler), warned east pocket (2 armed pawns + ruler) |
| Iudex Gundyr arena | The Stable Gate, 12×9 | boss-gate chamber between tutorial and hub; two armed Wardens hold it until the Knight moves in |
| Firelink Shrine | The White Court, 16×10 | safe hub, zero enemies, three doors (Stable, Gardens, gated Pass return) |
| High Wall of Lothric | The Chalk Gardens, 28×14 | four courts around a central spine, ambush behind the spine gap, internal one-way shortcut gate (gardens_lane_gate) folding the long way back to the entrance |
| Wall→settlement branch | The Bookshelf Pass, 24×11 | side level; its gated corridor loops one-way back to the hub (pass_home_gate) |

Graph: yard → stable_gate → white_court → {gardens ↔ pass}, pass → court
(one-way loop). Two shortcut gates, twelve doors, all CI-validated.

## Part 3 — Architecture (fits the ECS, all content stays data)

New pieces, following existing law (systems decide, scenes are data, .tres is
truth, presentation drains events):

1. **Zone scenes** — exactly today's room scenes, just bigger boards. A zone =
   tilemap + parked ActorViews + pickup markers + new `ExitMarker` nodes on
   edge cells + optional `ShrineMarker` / `GateMarker` / `BossArenaMarker`.
   EcsBoot already rebuilds the whole world from any such scene.
2. **World graph as data** — `resources/world/world_graph.tres`: zone id →
   scene path; exit id → (target zone, entry cell, one_way flag). The world is
   one `.tres`; adding a zone = one scene + one graph entry.
3. **`WorldState` autoload** (pure data + save/load, no gameplay decisions):
   defeated boss ids, opened gate ids, taken pickup ids, current shrine
   (zone + cell), dropped resolve (zone + cell + amount), resolve carried.
   Saved to `user://save.cfg` (ConfigFile). Stable ids come from marker
   exports, MetSys-style object-ID pattern.
4. **Zone travel** — player enters an exit cell → ZoneDirector (main.gd's new
   job) fades out, swaps the zone scene, reboots EcsBoot with WorldState
   filtering (dead bosses don't spawn, open gates spawn open, taken pickups
   skipped), places player at entry cell. Camera2D limits per zone (already
   supported by CameraRig.setup). Death keeps today's behavior: the zone
   reloads, normal enemies respawn, world state persists.
5. **Gates/shortcuts** — gate = blocker entity with a `GateComponent` (id,
   open_from_side). Opening emits an event; persistence write goes through
   WorldState. Grid just removes the block.
6. **Bosses** — an `EnemyDefinition` with `boss = true` + arena marker: on
   arena entry, seal exits (temporary blocks) + HUD boss bar (event-driven);
   on defeat, write WorldState, unseal, open the zone's reward gate.

**Dependency decision (needs the human):** the MetSys addon (KoBeWi's
Metroidvania System, Godot 4.5+, maintained) provides room transitions,
object-ID persistence, and a minimap for grid-room worlds. Recommendation:
**don't adopt for the core** — our ECS boot/persistence is bespoke and small —
but steal its object-ID and scrolling-transition patterns, and reconsider it
later purely for the in-game map screen.

## Part 4 — Build phases (each = one milestone, tests stay green)

1. **Two zones + travel** — world_graph.tres, ExitMarker, ZoneDirector swap
   with fade, WorldState autoload (pickup/visited persistence), camera limits
   per zone. Death = reload current zone (unchanged behavior, now
   zone-aware).
2. **Gates + the first loop** — GateComponent, lever/one-side opening,
   persistent open state; author zone 1 as a proper DS1 loop: long path out,
   shortcut gate back to the entrance. Populate with the first pawn variants
   (Backstep, Charging) via /new-enemy.
3. **The Book of House Rules** — RuleEntry .tres + book UI screen +
   event-driven unlocks (first encounter writes the entry). Seed it with
   entries for every variant authored so far.
4. **Boss framework + the Knight Errant** — Black Line arena seal, boss HUD
   bar, permanent defeat in WorldState, reward gate opens the road onward.
   Phase-2 double-jump amendment writes itself into the book mid-fight.
   Remaining pawn variants (Passant Wraith, Promoted Zealot) guard the
   approach.
5. **World art + landmarks + the map itself** — bigger boards, per-zone
   palettes, landmark structures at junctions, paint-tool extensions; author
   the 3-5 zone kingdom as one connected graph. Art direction human-owned.

Phase 1 is the next buildable slice. Zones after that are pure content:
scene + graph entry + hand-placed enemies. Cut phases (shrine, corpse run,
promotion) can slot back in later without rework — WorldState and the zone
graph are the substrate they'd need anyway.

## Sources

- GMTK / Mark Brown — "The World Design of Dark Souls" (Boss Keys)
- The Level Design Book — Undead Burg case study
- TheGamer — "Dark Souls 1: FromSoftware's Magnum Opus Of Interconnected
  Level Design"; "Bloodborne's Central Yharnam Is An Example Of Perfect
  Level Design"
- James Roha (Medium) — "World Design lessons from FromSoftware"
- Bramasole (Medium) — "The Ultimate Methodology of creating Souls-like Level"
- Fextralife wikis — Bonfire mechanics (what resets/persists)
- Game Developer — "9 Things We can Learn about Game Design from Dark Souls"
- PC Gamer / Nintendo Life / The Gemsbok — Death's Door reviews (shortcut
  density, checkpoint criticism, no-map debate)
- KoBeWi — Metroidvania System (MetSys) repo + wiki (Godot 4 room/persistence
  patterns)
