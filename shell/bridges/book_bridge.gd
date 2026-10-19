class_name BookBridge
extends ShellBridge

## The Book of House Rules' responsibility (docs/game-base-plan.md 9.2): the Book screen is pure
## presentation (RuleBookUI renders pages and reacts to the list); this bridge is what makes it part
## of the game.
##   - Meeting a piece writes its page. Every definition present in a freshly booted zone is "met":
##     its page is written into the run, once, forever, and the Book is refreshed with the run's pages.
##   - The B key opens and closes the Book. While it is open the hero's keys are off (the Book blocks
##     the controls), and it cannot be opened during a zone trip. It does NOT pause the simulation:
##     that is M4's pause (tests/bridge/test_bridge_book.gd pins today's behaviour, both ways).
## Reads: the booted zone's pieces, the run's pages. Writes: the run (through the SaveBridge), the
## Book node's visibility, the hero's control flag.

## What the status line says when a room brought a piece the Book has no page for yet.
const NEW_PAGES_MESSAGE := "New pieces on the board. The book writes their rules. [B]"
## Where the Book screen sits in the in-game scene.
const BOOK_NODE_PATH := ^"RuleBookUI"


## After a room booted: writes the page of every piece standing in it, and refreshes the Book. The
## words "New pieces" go to the status line, which the room's opening line replaces a moment later.
func meet_pieces() -> void:
	if root.current_room != null:
		var met_piece_ids: Array[String] = []
		for child in root.current_room.get_children():
			var view := child as ActorView
			if view != null and view.definition != null:
				met_piece_ids.append(String(view.definition.id))
		if root.save_bridge.record_rule_pages(met_piece_ids):
			root.message_bridge.say(NEW_PAGES_MESSAGE)
	var book := _book()
	if book != null:
		book.refresh(root.save_bridge.rule_page_ids())


## The B key. Opening refreshes the pages and switches the hero's control off; closing gives it back.
func toggle() -> void:
	var book := _book()
	if book == null or root.travel_in_progress:
		return
	book.visible = not book.visible
	if book.visible:
		book.refresh(root.save_bridge.rule_page_ids())
	root.set_player_control(not book.visible)


func _book() -> RuleBookUI:
	return root.get_node_or_null(BOOK_NODE_PATH) as RuleBookUI
