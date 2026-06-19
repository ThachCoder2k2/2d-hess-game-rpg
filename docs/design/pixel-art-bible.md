# The Unbound Pawn - Pixel Art Bible

**Version:** 1.0  
**Engine:** Godot 4.6  
**Rendering:** Native 2D  
**Visual target:** A warm playground action game with the combat clarity and animation energy associated with *Enter the Gungeon*

## 1. Visual Thesis

The game should look like a child's chess war rendered with confident, readable pixel art. The room must communicate danger before decoration. Toys and bedroom objects create charm around the battlefield, while the pieces and telegraphs remain unmistakable during fast combat.

The goal is not to reproduce *Enter the Gungeon*. We borrow its strong silhouettes, authored combat rooms, economical animation, environmental interaction, and disciplined effects. Our identity comes from chess geometry, handmade playground materials, warm bedroom light, and the contrast between a tiny pawn and the child's enormous hand.

## 2. Technical Canvas

- Internal resolution: 640x360.
- Aspect ratio: 16:9.
- Display scaling: integer scaling with nearest-neighbor filtering.
- Tile size: 32x32 pixels.
- Smallest supported combat room: 12x7 cells.
- Typical combat room: 16x9 cells.
- Boss room: up to 18x10 cells, framed without hiding active threats.
- Camera movement snaps to whole pixels.
- Gameplay collision always uses grid coordinates, not sprite bounds.

At 640x360, one tile is large enough to read while allowing a useful number of cells on screen. The room may contain decorative borders beyond the playable grid.

## 3. Perspective

- Floors are viewed from directly above.
- Walls and tall objects show a short front face to create depth.
- Characters are drawn from a high three-quarter angle.
- The playable cell remains visible beneath every actor.
- Tall decoration may overlap a character only at its upper edge.
- Shadows establish height but never hide telegraphs.

This creates the visual richness of a top-down dungeon without turning the project into 3D.

## 4. Shape Language

### White Kingdom

- Warm ivory, pale blue shadows, repaired seams, cloth ties, and crayon markings.
- Rounded silhouettes communicate vulnerability and community.
- The hero's sword adds one sharp diagonal shape.

### Black Kingdom

- Charcoal, cool blue-black shadows, red magical seams, and polished edges.
- Strong geometric silhouettes communicate authority.
- Elite pieces are taller and more symmetrical.

### The Child

- The hand is rendered at roughly twice the pixel density of the chess world.
- Motion is smoother and slower than combat animation.
- Blue crayon marks identify helpful interventions.
- The hand never resembles a cursor or divine beam.

## 5. Palette

Each region uses a compact local palette while preserving shared gameplay colors:

- Immediate danger: coral red.
- Anticipation: dark orange.
- Child intervention: crayon blue.
- Interactable toy: golden yellow.
- Healing and safe state: mint green.
- White pieces: warm ivory, not pure white.
- Black pieces: charcoal, not pure black.

Pure white and pure black are reserved for brief impact frames and maximum contrast.

## 6. Sprite Scale

| Asset | Canvas target |
|---|---:|
| Pawn hero | 32x40 |
| Common pawn | 32x40 |
| Knight | 48x48 |
| Bishop | 40x48 |
| Rook | 40x48 |
| Queen | 64x64 |
| King | 64x64 |
| Child hand | 160x120 or larger |
| Sword effect | 32x32 |
| Block intervention | 32x40 |

Sprites may extend beyond their logical cell. Their feet, base, or shadow remain anchored to the cell center.

## 7. Animation Budget

### Hero Pawn

- Idle: 4 frames per direction.
- Step: 4 frames per direction.
- Sword attack: 5 frames per direction.
- Turn: 1 anticipation frame plus the new directional idle.
- Pencil Thrust: 6 frames per direction with a two-cell straight effect.
- Hurt: 3 frames.
- Defeat: 6 frames.
- Victory or resolve: 6 frames.

The base of the pawn tilts, compresses, and hops slightly. The piece does not need arms or a humanoid body.

### Common Enemies

- Idle: 2-4 frames.
- Move or attack: 4-6 frames.
- Telegraph: 2-4 frames plus shader or overlay.
- Hit: 2 frames.
- Defeat: 4-6 frames.

### Animation Principles

- Anticipation is longer than impact.
- Impacts use one bright frame, a short freeze, particles, and slight camera shake.
- A Knight's shadow shows its destination before the sprite lands.
- Rook motion stretches subtly along its charge axis.
- The Queen should animate less often but with greater authority.

## 8. Environment Kits

### Shared Kit

- Chessboard floor variants.
- Cracked, repaired, painted, and paper-covered cells.
- Low block walls.
- Crayons, pencils, stickers, paper scraps, thread, and tape.
- Toy-object shadows.

### Knight Region

- Train tracks, signals, tunnels, wind-up keys, and block ramps.

### Bishop Region

- Folded pages, book spines, paper windows, bookmark ribbons, and mirrored stickers.

### Rook Region

- Wooden block battlements, gates, towers, and destructible rows.

### Queen Region

- Dollhouse wallpaper, toy furniture, hinges, doors, carpets, and miniature lamps.

### King Region

- Chess-box felt, clasps, rule cards, springs, gears, and red magical cracks.

## 9. Telegraph Rules

- A cell changes color only when the threat is spatially relevant.
- Anticipation begins with shape and motion; red appears near resolution.
- Diagonal attacks use corner-to-corner marks.
- Rook attacks use centered arrows along a row or column.
- Knight destinations use an outlined landing cell and a visible L-shaped path cue.
- Boss patterns never use decorative particles that resemble damage.
- Safe cells are not permanently highlighted; Focus and accessibility settings may reveal them.

## 10. Effects

- Sword swing: pale yellow arc with two or three pixel fragments.
- Pencil Thrust: graphite-gray shaft, pale blue speed line, and a sharp two-cell impact.
- Successful hit: white flash, four-direction chips, 50-80 ms hit stop.
- Child help: blue crayon stroke, paper dust, and a soft room-light shift.
- Enemy magic: red cracks and dark smoke used sparingly.
- Defeat: piece tips, cracks, or returns to an ordinary toy. No gore.

Effects disappear quickly so the next grid state is readable.

## 11. Lighting

- Use a warm global bedroom tone.
- Region lighting comes primarily from painted tiles and overlays.
- `PointLight2D` is reserved for lamps, magical items, and interventions.
- Normal maps are optional and should be tested on one room before production.
- Avoid bloom-heavy effects that soften pixel edges.

## 12. UI

- UI uses a pixel font at integer sizes.
- Courage resembles three small ivory chess bases.
- Believe uses two blue crayon marks.
- Intervention icons resemble physical toys.
- Dialogue portraits may use larger pixel art than gameplay sprites.
- The HUD occupies corners and never covers the combat grid.

## 13. Asset Acceptance Checklist

An asset is ready when:

1. Its gameplay role is recognizable at 1x internal resolution.
2. Its silhouette remains clear against both light and dark floor tiles.
3. It aligns to the 32x32 grid.
4. Animation does not move the logical cell anchor.
5. It uses the correct gameplay colors.
6. It does not introduce subpixel motion or filtered edges.
7. It remains readable in a grayscale screenshot.

## 14. Vertical Slice Art List

- Hero pawn sprite set.
- Black pawn sprite set.
- Knight Captain sprite set.
- Sword effects.
- Damage and defeat effects.
- Block intervention and child hand.
- Toy-track tileset.
- Shared chessboard tiles.
- Two room decoration sets.
- Telegraph tiles and overlays.
- Courage, Believe, and intervention HUD.
- One dialogue portrait for the pawn and one child dialogue treatment.

This list is the complete art scope for the first playable slice.
