class_name RuleBook
extends Resource

## The Book of House Rules as data: an ordered list of RuleEntry pages.
## Adding a rule bend to the game = author one entry .tres and append it
## here. The UI renders it; WorldState remembers which pages are read.

@export var entries: Array[RuleEntry] = []


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if entries.is_empty():
		warnings.append("The book has no entries.")
	for entry in entries:
		if entry == null:
			warnings.append("The book has an empty page slot.")
		else:
			warnings.append_array(entry.validate())
	return warnings
