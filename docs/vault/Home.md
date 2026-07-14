# 🏰 The Unbound Pawn — Code Vault

Open this folder (`docs/vault/`) as an Obsidian vault. Every note links to related
ones — use the graph view to see how the code connects. Each note explains a system
and points at the real script files (`scripts/...`).

> Guiding idea: **code is reusable behavior; content is data.** A script defines *how*
> something works; a `.tres` Resource or `.tscn` scene defines the *specific* enemy,
> weapon, or room. See [[Data Resources]].

## Read in this order

1. [[Grid World]] — the board. Everything sits on this.
2. [[Movement]] — how a body steps cell → cell.
3. [[Player]] — the pawn you control.
4. [[Data Resources]] — how enemies/weapons/attacks are defined (just fields).
5. [[Enemy AI]] — the decision engine (the hard, rewarding part).
6. [[Enemy Composition]] — how a modern enemy is assembled from components.
7. [[Combat and Telegraph]] — attack lifecycle, the token, the dodge.
8. [[World and Rooms]] — markers, rooms, the Main coordinator.
9. [[Presentation]] — sprites, overlays, HUD, tilemaps.

Reference notes: [[Glossary]] · [[Script Index]]

## The whole game in one paragraph

A white pawn fights on a 32px grid. [[Grid World]] is the single source of truth for
who/what is on each cell. The [[Player]] and enemies are [[Movement|grid actors]] that
reserve a destination, tween to it, then commit. Enemies run a scored state machine
([[Enemy AI]]) that telegraphs an attack, then resolves it — you [[Combat and
Telegraph|dodge]] by stepping out of the telegraphed cells before it lands. A room-wide
attack token stops enemies ganging up. Everything an enemy *is* comes from [[Data
Resources|.tres data]], so new content needs no new code.

## Systems map

```
[[Grid World]] ──used by──> [[Movement]], [[Enemy AI]], [[World and Rooms]]
[[Player]] ──attacks with──> [[Data Resources|AttackProfile]]
[[Enemy AI]] ──reads──> [[Data Resources|DecisionConfig]] ──scores──> [[Combat and Telegraph]]
[[Enemy Composition]] ──hosts──> Movement / Health / Equipment / Brain components
[[World and Rooms]] ──spawns from──> markers ──instances──> [[Enemy Composition]]
[[Presentation]] ──mirrors state of──> everything above (never drives logic)
```
