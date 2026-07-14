# Presentation

Everything you *see*. These nodes **mirror** game state — they never drive logic.
Gameplay truth is [[Grid World|cells]]; presentation is paint.

Back to [[Home]] · related: [[Enemy Composition]] · [[Player]] · [[World and Rooms]] · [[Combat and Telegraph]]

## Actor visuals
- `scripts/visuals/piece_visual.gd` — `PieceVisual`: a `Sprite2D` body + `AnimationPlayer`
  (clips: idle, step, attack, hurt, telegraph). The hero/enemy calls `sync_from_hero` /
  `sync_from_enemy` each frame to push state in: facing, weapon texture, health pips,
  modulate, which clip to play. **Never `_draw()`s the body** (that's a hard rule).
- `scripts/visuals/pickup_visual.gd` — `PickupVisual`: the pickup sprite + float/glow.
- Visual scenes: `objects/visuals/{pawn_hero,black_pawn,knight_enemy,weapon_pickup}_visual.tscn`.
  Textures are assigned in the scene, not loaded in code.

## Board overlay
`scripts/world/prototype_board.gd` — `PrototypeBoard`. The one place `_draw()` is
allowed for gameplay: telegraph danger cells ([[Combat and Telegraph]]), hit flashes,
and the F3 debug view (AI paths, boundaries, labels). It's a combat overlay, not floor art.

## Floor + grid
- `objects/world/kingdom_tilemap.tscn` — the throne-room `TileMapLayer` floor (marble
  checker + carpet + walls/thrones/banners). Painted by the build tool
  `tools/paint_kingdom_tilemap.gd`, not by hand (`tile_map_data` is a binary blob).
  `playground_tilemap.tscn` is the old alternate floor.
- `scripts/world/grid_lines_overlay.gd` — `GridLinesOverlay`: one `@tool` node that draws
  the cell grid from exported dims (replaced 27 hand-placed line nodes).

## HUD
`scripts/ui/hud.gd` — `GameHud` (a `CanvasLayer`). Owns courage pips, the skill-cooldown
bar, enemy count, status text, damage flash, and the result panel — and **all** their
formatting. [[World and Rooms|Main]] just calls `hud.set_courage(...)` etc.; the HUD owns
how it looks.
