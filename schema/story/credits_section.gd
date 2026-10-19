class_name CreditsSection
extends Resource

## One block of the credits roll: a heading and the lines under it (docs/game-base-plan.md 8.8, 9.2). The
## credits scene shows the heading large and the lines below it, in the order they are written; an empty line
## is a gap. Plain text for now: the text pipeline (M4) moves the words to `CREDIT_` keys.

## The block's heading ("Made with", "Licenses").
@export var heading := ""
## The lines under the heading, one per entry. An empty string is a gap between two groups.
@export var lines := PackedStringArray()
## Draw the lines small, as fine print (the licence texts), instead of as credit lines.
@export var fine_print := false


## Problems with this block, one sentence each (empty = healthy).
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if heading.strip_edges().is_empty():
		problems.append("A credits section has no heading.")
	var has_text := false
	for line in lines:
		if not line.strip_edges().is_empty():
			has_text = true
	if not has_text:
		problems.append("The credits section '%s' has no lines." % heading)
	return problems
