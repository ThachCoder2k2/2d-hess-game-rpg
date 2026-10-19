class_name CreditsDefinition
extends Resource

## The credits roll as data (docs/game-base-plan.md 8.8, 9.2): the game's title, the blocks under it and how
## fast they scroll. One file, `content/story/credits.tres`, edited in the Inspector by the owner; the credits
## scene (shell/credits/credits_screen.tscn) only lays it out and scrolls it. The licence block is generated
## from THIRD_PARTY_NOTICES.md (tools/build_credits_licenses.gd), so the notices and the credits cannot drift apart.

## Text key: the title shown at the top of the roll.
@export var game_title := "CREDIT_GAME_TITLE"
## The blocks, top to bottom. Typically: who made the game, what it is made with, the licences.
@export var sections: Array[CreditsSection] = []
## Text key: the line shown last, after the final block.
@export var closing_line := ""
## How fast the roll moves, in pixels of the 640 x 360 screen per second.
@export_range(8.0, 120.0, 1.0, "suffix:px/s") var scroll_pixels_per_second := 24.0


## Problems with the roll, one sentence each (empty = healthy): a title, at least one block, every block valid.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if game_title.strip_edges().is_empty():
		problems.append("The credits have no game title.")
	if sections.is_empty():
		problems.append("The credits have no sections.")
	for section in sections:
		if section == null:
			problems.append("The credits have an empty section slot.")
		else:
			problems.append_array(section.validate())
	if scroll_pixels_per_second <= 0.0:
		problems.append("The credits scroll speed must be above zero.")
	return problems
