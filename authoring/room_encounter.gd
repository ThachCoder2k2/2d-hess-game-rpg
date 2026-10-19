@tool
class_name RoomEncounter
extends Node2D

## Editor-authored room data + view container. The simulation boots through
## EcsBoot (docs/ecs-conversion-plan.md): parked ActorView children become
## entities, painted solid tiles become blocks, pickup markers become item
## entities. This script only carries the room's prose and objective, and since M5 the room's META: where it
## sits in the story and the world, what it is for, and how finished it is (docs/game-base-plan.md 7.5). The prose is
## TEXT KEYS (docs/game-base-plan.md 8.9): the words are rows of content/story/text/<language>/rooms.po, resolved by
## TextService where they are shown.
##
## Every meta field has a doc and a check: a mistake shows in the editor's Inspector as a configuration warning, and
## `configuration_problems()` is the same list for tests and tools. The checks are the ones a single room can make
## by itself; that rooms agree with each other and with content/world/world.tres is tests/content/test_world_graph.gd.

## How finished a room is (docs/game-base-plan.md 1.3). The list only grows at the end: a saved scene stores the number.
enum ContentStatus {
	## A placeholder shape that is reachable: doors and entries are real, the rest is a stand-in.
	STUB,
	## A playable layout with real enemies and beats.
	GREYBOX,
	## Placeholder art is in place.
	DRESSED,
	## The owner's art. Only the owner marks a room FINAL.
	FINAL,
}

## When in the one night the room happens (D-31): inert data until the tint is applied (Tier B), and when it is,
## it tints the background and the tiles, never the telegraphs, the HUD or the dialogue. Append only.
enum TimeOfNight { DUSK, EVENING, NIGHT, SMALL_HOURS, DAWN, MORNING }

## What the room is for in the formula of docs/game-base-plan.md 7.5 (the Role column of 7.4). Append only.
enum Recipe { REST, TEACH, TEST, TWIST, BOSS, SHORTCUT, OPTIONAL, ENDING, DEV }

## The acts are 1 to 6; the Ending ("Morning") is act 7 (D-06). Zero means the room is no part of the story.
const LAST_ACT := 7
## A room fits one screen: at most this many cells wide and high (D-02: 16x9 by default, arenas up to 18x9).
const LARGEST_BOARD := Vector2i(18, 9)
## ... and at least this many (the arena floor the world-graph assertions of Stage 1 always asked for).
const SMALLEST_BOARD := Vector2i(8, 7)
## Scenes under this folder are shipped rooms: their zone_id is their folder name.
const ROOMS_FOLDER := "res://content/rooms/"
const TEXT_KEY_PATTERN := "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$"
const SNAKE_CASE_PATTERN := "^[a-z][a-z0-9_]*$"

## Text key (ROOM_<ID>_START in rooms.po): the line the status bar says when the pawn comes in.
@export var room_message := ""
@export var objective: Resource
## World-map identity: the room's id, which is its folder name under content/rooms/ (empty = standalone room
## outside the world graph).
@export var zone_id: StringName = &""
## True when stepping into this room through a door is a checkpoint (D-16): a hub, and every boss room.
## The pawn's Courage is refilled and the run remembers the entry it came by (the checkpoint). Death does not
## move the pawn to the checkpoint; it starts the room it fell in again from its own entry (docs/game-base-plan.md 5.2).
@export var checkpoint_on_entry := false
## Board cells this room spans; EcsBoot sizes the grid from it.
@export var board_size := Vector2i(16, 9)

@export_group("World meta")
## Which act the room belongs to: 1 to 6, and 7 for the Ending (D-06). 0 = not part of the story.
@export_range(0, 7) var act := 0
## The district of the bedroom the room is in (one of WorldGraph.DISTRICT_IDS). The room's map slot in
## content/world/world.tres lies inside this district's region.
@export var district: StringName = &""
## The shape family of the layout: `winding`, `yard`, `fence`, `arena`, `hub`... (docs/game-base-plan.md 7.4, second
## item of Size / archetype). Lowercase snake_case. No two consecutive rooms of the critical path share one (D-02).
@export var layout_archetype: StringName = &""
## What the room is for: rest, teach, test, twist, boss, shortcut, optional, ending or dev.
@export var recipe := Recipe.REST
## How finished the room is. Only the owner sets FINAL.
@export var content_status := ContentStatus.STUB
## When in the one night the room happens (inert data until the tint is applied).
@export var time_of_night := TimeOfNight.DUSK


## The text key of the line to say on arrival: the objective's, else the room's own.
func get_start_message() -> String:
	if objective != null and not String(objective.get("start_message")).is_empty():
		return String(objective.get("start_message"))
	return room_message


func get_clear_message() -> String:
	return _objective_text("clear_message", RoomObjective.STOCK_CLEAR_KEY)


func get_clear_subtitle() -> String:
	return _objective_text("clear_subtitle", RoomObjective.STOCK_CLEAR_SUBTITLE_KEY)


func get_defeat_message() -> String:
	return _objective_text("defeat_message", RoomObjective.STOCK_DEFEAT_KEY)


func get_defeat_subtitle() -> String:
	return _objective_text("defeat_subtitle", RoomObjective.STOCK_DEFEAT_SUBTITLE_KEY)


func _objective_text(property: StringName, fallback_key: String) -> String:
	if objective == null:
		return fallback_key
	var value := String(objective.get(property))
	return value if not value.is_empty() else fallback_key


## The name of a status, a time of night or a recipe as the layout files and the tools spell it (lowercase).
static func status_name(status: ContentStatus) -> String:
	return ContentStatus.keys()[status].to_lower()


static func time_of_night_name(time: TimeOfNight) -> String:
	return TimeOfNight.keys()[time].to_lower()


static func recipe_name(room_recipe: Recipe) -> String:
	return Recipe.keys()[room_recipe].to_lower()


## What is wrong with this room's meta, one sentence each (empty = nothing). The same list the editor shows
## as configuration warnings. A room under content/rooms/ is a shipped room and is held to the shipped rules
## (an id equal to its folder, a start line, an act and a district); a scene anywhere else (a test fixture, a
## room being sketched) is only held to the rules that never change.
func configuration_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	var is_shipped_room := scene_file_path.begins_with(ROOMS_FOLDER)
	var snake_case := RegEx.create_from_string(SNAKE_CASE_PATTERN)

	if board_size.x < SMALLEST_BOARD.x or board_size.y < SMALLEST_BOARD.y or board_size.x > LARGEST_BOARD.x or board_size.y > LARGEST_BOARD.y:
		problems.append("board_size %s must be between %s and %s: a room is one screen (16x9, arenas up to 18x9)." % [board_size, SMALLEST_BOARD, LARGEST_BOARD])
	if act < 0 or act > LAST_ACT:
		problems.append("act %d is not an act: use 1 to 6, 7 for the Ending, 0 for none." % act)
	if district != &"" and district not in WorldGraph.DISTRICT_IDS:
		problems.append("district '%s' is not a district (use one of: %s)." % [district, WorldGraph.district_ids_text()])
	if layout_archetype != &"" and snake_case.search(String(layout_archetype)) == null:
		problems.append("layout_archetype '%s' must be lowercase snake_case (winding, yard, fence...)." % layout_archetype)
	if not room_message.is_empty() and RegEx.create_from_string(TEXT_KEY_PATTERN).search(room_message) == null:
		problems.append("room_message must be a text key (ROOM_<ID>_START), not words: '%s'." % room_message)
	if recipe == Recipe.BOSS and not checkpoint_on_entry:
		problems.append("A boss room is a checkpoint (D-16): tick checkpoint_on_entry.")
	if layout_archetype == &"hub" and not checkpoint_on_entry:
		problems.append("A hub is a checkpoint (D-16): tick checkpoint_on_entry.")

	if is_shipped_room:
		var folder_id := scene_file_path.trim_prefix(ROOMS_FOLDER).get_slice("/", 0)
		if zone_id != StringName(folder_id):
			problems.append("zone_id is '%s' but the room lives in content/rooms/%s/: they must be equal." % [zone_id, folder_id])
		if room_message.is_empty():
			problems.append("A shipped room needs a room_message (ROOM_<ID>_START): the line the status bar says when the pawn comes in.")
		if act == 0:
			problems.append("A shipped room belongs to an act: set act (1 to 6, 7 for the Ending).")
		if district == &"":
			problems.append("A shipped room belongs to a district: set district.")
		if layout_archetype == &"":
			problems.append("A shipped room has a layout archetype: set layout_archetype.")
	return problems


func _get_configuration_warnings() -> PackedStringArray:
	return configuration_problems()
