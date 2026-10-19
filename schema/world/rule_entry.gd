class_name RuleEntry
extends Resource

## One page of the Book of House Rules: a chess rule and the amendment some
## piece made to it. Pure editor data — unlocking is keyed on piece_id (the
## EnemyDefinition id) the first time the player shares a zone with it.
## The four texts are TEXT KEYS (PAGE_<ID>_TITLE, _RULE, _AMENDMENT, _FLAVOR in story.po, docs/game-base-plan.md
## 8.9): a page is rewritten in the .po file, not here.

## EnemyDefinition.id that reveals this page when first met.
@export var piece_id: StringName = &""
@export var title := ""
@export_multiline var original_rule := ""
@export_multiline var amendment := ""
@export_multiline var flavor := ""


func validate() -> PackedStringArray:
	var warnings := PackedStringArray()
	if piece_id == &"":
		warnings.append("Entry needs the piece_id that unlocks it.")
	if title.is_empty() or original_rule.is_empty() or amendment.is_empty():
		warnings.append("Entry '%s' is missing text." % title)
	return warnings
