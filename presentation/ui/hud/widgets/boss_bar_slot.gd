class_name BossBarSlot
extends HudWidget

## RESERVED: the place of the boss bar (docs/game-base-plan.md D-29, 10). It draws nothing and reads nothing, and it is
## hidden: a boss and its phases arrive in M8b. The asset list's bar frame is 96 x 20 px "so the whole boss bar stays
## inside the 28 px strip", which is the size of this rectangle; the HUD safe zone test keeps every other widget out of it
## and keeps it inside the top strip, so a boss room cannot cover a row of the board. M8b fills this scene and adds the
## snapshot fields it needs (the boss's name, its Courage and its phase marks) without moving anything else.
