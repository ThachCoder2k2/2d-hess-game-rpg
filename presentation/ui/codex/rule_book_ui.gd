class_name RuleBookUI
extends CanvasLayer

## The Book of House Rules screen: pure presentation. The bridge toggles
## visibility (B key) and feeds it the unlocked piece ids; this script only
## renders pages and reacts to list selection. No gameplay decisions.
##
## A page (RuleEntry) holds text keys; the words come from TextService when the page is shown, and the list and the
## open page are drawn again when the language changes. The labels the scene authored hold their key and are
## translated by the engine.

@export var rule_book: RuleBook

var entry_list: ItemList
var count_label: Label
var title_label: Label
var original_label: Label
var amendment_label: Label
var flavor_label: Label

var unlocked_piece_ids: Array = []


func _ready() -> void:
	refresh([])


## Node lookups are lazy (not @onready) so headless tests that never start
## the frame loop can still drive refresh() right after instantiating.
func _bind_nodes() -> void:
	if entry_list != null:
		return
	entry_list = %EntryList
	count_label = %CountLabel
	title_label = %TitleLabel
	original_label = %OriginalLabel
	amendment_label = %AmendmentLabel
	flavor_label = %FlavorLabel
	entry_list.item_selected.connect(_show_entry)
	var live_text := LiveText.new()
	add_child(live_text)
	live_text.on_language_change(func() -> void: refresh(unlocked_piece_ids))


## Rebuilds the list against the given unlocked ids, keeping the selection.
func refresh(new_unlocked_piece_ids: Array) -> void:
	_bind_nodes()
	unlocked_piece_ids = new_unlocked_piece_ids
	var selected := entry_list.get_selected_items()
	var selected_index: int = selected[0] if not selected.is_empty() else 0
	entry_list.clear()
	if rule_book == null:
		return
	var known := 0
	for entry in rule_book.entries:
		if entry.piece_id in unlocked_piece_ids:
			entry_list.add_item(TextService.t(entry.title))
			known += 1
		else:
			entry_list.add_item(TextService.t("BOOK_UNREAD_INK"))
	count_label.text = TextService.t("BOOK_COUNT", {"known": known, "total": rule_book.entries.size()})
	if entry_list.item_count > 0:
		selected_index = clampi(selected_index, 0, entry_list.item_count - 1)
		entry_list.select(selected_index)
		_show_entry(selected_index)


func _show_entry(index: int) -> void:
	if rule_book == null or index < 0 or index >= rule_book.entries.size():
		return
	var entry: RuleEntry = rule_book.entries[index]
	if entry.piece_id in unlocked_piece_ids:
		title_label.text = TextService.t(entry.title)
		original_label.text = TextService.t(entry.original_rule)
		amendment_label.text = TextService.t(entry.amendment)
		flavor_label.text = TextService.t("BOOK_FLAVOR_QUOTED", {"flavor": TextKey.of(entry.flavor)})
	else:
		title_label.text = TextService.t("BOOK_UNREAD_INK")
		original_label.text = TextService.t("BOOK_PAGE_WAITS")
		amendment_label.text = "..."
		flavor_label.text = ""
