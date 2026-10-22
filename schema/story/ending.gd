class_name Ending
extends Resource

## The ending as data (docs/game-base-plan.md 8.8, D-33): what the player sees between the last boss and the credits.
## One file, `content/story/endings/ending.tres`, edited in the Inspector by the owner. In M5 it is a sequence of
## cards (EndingCard) that the ending screen (shell/ending/ending_screen.tscn) shows one after the other; M13 makes
## the Desk a board the pawn plays on (the four promotion tokens, the walk past them and off the board's edge, the
## ten-second hold) and adds the variants keyed to the rescues, and this resource grows those fields beside the cards.
##
## How the ending is reached: the pawn steps on the one door of the Desk room (e1_morning_desk) that ends the run
## (ZoneExitMarker.ends_run); MovementSystem says `ending_reached`, the EndingBridge asks GameFlow to reach the ending,
## AppRoot shows this sequence, then the credits, then the title with the completed mark.

## The cards, in the order they are shown. At least one.
@export var cards: Array[EndingCard] = []
## The room Continue loads on a game that was finished (docs/game-base-plan.md 8.8: the hub in its fifth state, the Desk
## reachable). A room id of content/world/world.tres. Nothing reads it before M13 (a Continue loads the room of the last
## save); it is written now so the room is named in one place.
@export var post_game_zone: StringName = &"h1_chess_rug_hub"


## The seconds the whole sequence takes if nobody skips a card.
func total_seconds() -> float:
	var total := 0.0
	for card in cards:
		if card != null:
			total += card.total_seconds()
	return total


## Problems with the ending, one sentence each (empty = healthy). Whether the room named by post_game_zone exists is
## ContentDb.validate_cross_refs()'s question: only it can read the world graph.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if cards.is_empty():
		problems.append("The ending has no cards.")
	for card in cards:
		if card == null:
			problems.append("The ending has an empty card slot.")
		else:
			problems.append_array(card.validate())
	if RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(String(post_game_zone)) == null:
		problems.append("The ending's post_game_zone '%s' must be a room id (lowercase snake_case)." % post_game_zone)
	return problems
