class_name HudWidget
extends Control

## One piece of the production HUD (docs/game-base-plan.md D-29): a scene of its own with a script of its own, instanced
## by hud.tscn, so six milestones can add a skill slot, a boss bar or a Believe mark without editing the same file. A
## widget decides nothing about the game: it draws what the HudSnapshot says, and it draws again only when that changed.
## The words on it are text keys; a widget whose text a script sets keeps it in the player's language with a LiveText.
##
## Where a widget sits is the scene's business (its offsets in hud.tscn): the HUD safe zone (tests/presentation/test_hud_safe_zone.gd)
## holds every widget, shown or reserved, inside the top strip (y 0 to 32, at most 28 px tall) or the bottom strip (y 326
## to 360), so none can cover a row of the board.
##
## A widget never takes the mouse: the HUD is a picture over the game, not a surface.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Draws what `snapshot` says. GameHud calls it every frame, so a widget compares with what it drew last and does
## nothing when nothing changed.
func refresh(_snapshot: HudSnapshot) -> void:
	pass


## Forgets what it last drew, so the next refresh() draws it again (a room that just booted shows its own picture,
## not whatever the last room left).
func forget_drawn() -> void:
	pass
