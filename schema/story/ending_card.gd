class_name EndingCard
extends Resource

## One card of the ending (docs/game-base-plan.md 8.8): a line on a plain screen that fades in, holds and fades out.
## The ending is a sequence of these cards in M5 (the playable Desk of M13 replaces the cards with a board the pawn walks
## off); the cards are the skeleton the player sees between the last boss and the credits.

## The text key of the line (an `END_` row of content/story/text/<language>/story.po, docs/game-base-plan.md 8.9).
@export var text_key := ""
## Seconds the line stays fully shown once it has faded in. Confirm moves a card on before then.
@export_range(1.0, 30.0, 0.5, "suffix:s") var hold_seconds := 4.0
## Seconds the line takes to fade in, and again to fade out.
@export_range(0.0, 3.0, 0.1, "suffix:s") var fade_seconds := 0.8


## How long the card is on screen from its first fade-in frame to the last fade-out frame.
func total_seconds() -> float:
	return fade_seconds * 2.0 + hold_seconds


## Problems with this card, one sentence each (empty = healthy).
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if RegEx.create_from_string("^END_[A-Z0-9]+(_[A-Z0-9]+)*$").search(text_key) == null:
		problems.append("An ending card needs a text key that starts with END_ (an END_ row of story.po); '%s' is not one." % text_key)
	if hold_seconds < 1.0:
		problems.append("The ending card '%s' holds for %.1f s: a card is on screen at least a second." % [text_key, hold_seconds])
	return problems
