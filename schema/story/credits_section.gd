class_name CreditsSection
extends Resource

## One block of the credits roll: a heading and the lines under it (docs/game-base-plan.md 8.8, 9.2). The
## credits scene shows the heading large and the lines below it, in the order they are written; an empty line
## is a gap. The heading and the credit lines are TEXT KEYS (`CREDIT_` rows of story.po, docs/game-base-plan.md 8.9);
## the lines of a fine-print block are legal text, shown exactly as written in every language.

## Text key: the block's heading ("Made with", "Licenses").
@export var heading := ""
## The lines under the heading, one per entry: text keys, or the legal text itself when `fine_print`. An empty string
## is a gap between two groups.
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
