class_name BelieveSlot
extends HudWidget

## RESERVED: the place of the Believe marks, the two chalk marks of the child's help (docs/game-base-plan.md D-29, 5.5).
## It draws nothing and reads nothing, and it is hidden: the child system arrives in M10 (the first-chain HUD must not
## show a meter before the system matters, docs/design/ui1-hud-scope-spec.md). It exists now so that its rectangle,
## next to the Courage pips in the top strip, is spoken for: the HUD safe zone test keeps every other widget out of it, and
## M10 fills this scene (and adds the snapshot fields it needs) without moving anything else.
