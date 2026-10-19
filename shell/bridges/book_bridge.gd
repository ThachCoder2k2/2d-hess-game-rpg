class_name BookBridge
extends ShellBridge

## The Book of House Rules' responsibility (docs/game-base-plan.md 4.7, 9.2): the Book screen is pure
## presentation (RuleBookUI renders pages and reacts to the list); this bridge is what makes it part
## of the game.
##   - Meeting a piece writes its page. Every definition present in a freshly booted zone is "met":
##     its page is written into the run, once, forever, and the Book is refreshed with the run's pages.
##   - The B key (or L3) opens and closes the Book, and so does Esc or Start while it is open. While it is
##     open the hero's keys are off AND THE WORLD IS FROZEN (M4): the bridge asks for it with a
##     freeze_requested command, and an unfreeze_requested one when the Book closes, so a step in flight,
##     an enemy's telegraph and the hero's invulnerability all wait for the player to finish reading
##     (tests/bridge/test_bridge_book.gd and test_pause_freezes_tick). It cannot be opened during a zone trip.
##   - The pause menu's Book entry closes the menu and opens the Book here (`open()`).
## Reads: the booted zone's pieces, the run's pages. Writes: the run (through the SaveBridge), the
## Book node's visibility, the hero's control flag, and the freeze on the world's commands.

## The text key of what the status line says when a room brought a piece the Book has no page for yet.
const NEW_PAGES_KEY := "MSG_NEW_PAGES"
## Where the Book screen sits in the in-game scene.
const BOOK_NODE_PATH := ^"RuleBookUI"
## The `reason` of the freeze the open Book asks for.
const FREEZE_REASON := &"book"


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
			root.message_bridge.say(NEW_PAGES_KEY)
	var book := _book()
	if book != null:
		book.refresh(root.save_bridge.rule_page_ids())


## Whether the Book is on screen.
func is_open() -> bool:
	var book := _book()
	return book != null and book.visible


## The B key. Opens the Book when it is closed and closes it when it is open.
func toggle() -> void:
	if root.zone_travel_bridge.travel_in_progress:
		return
	if is_open():
		dismiss()
	else:
		open()


## Opens the Book: refreshes the pages, switches the hero's control off and freezes the world. Nothing happens
## when it is already open, during a zone trip, or in a scene that has no Book.
func open() -> void:
	var book := _book()
	if book == null or book.visible or root.zone_travel_bridge.travel_in_progress:
		return
	book.visible = true
	book.refresh(root.save_bridge.rule_page_ids())
	root.set_player_control(false)
	root.ecs.push_command(Commands.freeze_requested(FREEZE_REASON))


## Closes the Book: gives the hero's control back and lets the world run again.
func dismiss() -> void:
	var book := _book()
	if book == null or not book.visible:
		return
	book.visible = false
	root.set_player_control(true)
	root.ecs.push_command(Commands.unfreeze_requested(FREEZE_REASON))


## Shuts the Book without touching the hero's control or the world (the room is being rebuilt: the new hero is
## born with control on and the new world is not frozen).
func close() -> void:
	var book := _book()
	if book != null:
		book.visible = false


func _book() -> RuleBookUI:
	return root.get_node_or_null(BOOK_NODE_PATH) as RuleBookUI
