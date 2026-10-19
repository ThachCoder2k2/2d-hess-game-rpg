class_name RoomObjective
extends Resource

## What a room asks of the pawn and what it says when that is done or the pawn falls. The lines are TEXT KEYS, not
## words (docs/game-base-plan.md 8.9): the words are rows of `content/story/text/<language>/rooms.po` (or `ui.po`
## for the stock lines below), so a line is rewritten there and never in this resource.

enum WinCondition { DEFEAT_ALL_ENEMIES, DEFEAT_COUNT }

## The keys a room says when its RoomObjective names no line of its own. The clear subtitle names no key of the
## keyboard: a room is restarted from the pause menu (D-18) and the pause key is Esc on a keyboard and Start on a pad.
const STOCK_START_KEY := "MSG_ROOM_START_DEFAULT"
const STOCK_CLEAR_KEY := "UI_RESULT_CLEARED"
const STOCK_CLEAR_SUBTITLE_KEY := "UI_RESULT_CLEARED_SUBTITLE"
const STOCK_DEFEAT_KEY := "UI_RESULT_DEFEATED"
const STOCK_DEFEAT_SUBTITLE_KEY := "UI_RESULT_DEFEATED_SUBTITLE"

@export var id: StringName = &"room_objective"
## Text key: the line the status bar says when the pawn comes in.
@export var start_message := STOCK_START_KEY
## Text key: the big line of the result panel when the room is won.
@export var clear_message := STOCK_CLEAR_KEY
## Text key: the line under it.
@export var clear_subtitle := STOCK_CLEAR_SUBTITLE_KEY
## Text key: the big line of the result panel when the pawn falls.
@export var defeat_message := STOCK_DEFEAT_KEY
## Text key: the line under it.
@export var defeat_subtitle := STOCK_DEFEAT_SUBTITLE_KEY
@export var win_condition := WinCondition.DEFEAT_ALL_ENEMIES
@export_range(1, 20) var required_defeats := 1


func is_complete(defeated_count: int, total_count: int, remaining_count: int) -> bool:
	match win_condition:
		WinCondition.DEFEAT_COUNT:
			return defeated_count >= required_defeats
		_:
			return total_count > 0 and remaining_count <= 0
