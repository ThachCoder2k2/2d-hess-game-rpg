class_name RoomObjective
extends Resource

enum WinCondition { DEFEAT_ALL_ENEMIES, DEFEAT_COUNT }

## What the result panel says under "ROOM CLEARED" when a room names no line of its own. It names no key: a room
## is restarted from the pause menu (D-18) and the pause key is Esc on a keyboard and Start on a pad.
const STOCK_CLEAR_SUBTITLE := "OPEN THE PAUSE MENU TO RESTART THE ROOM"

@export var id: StringName = &"room_objective"
@export_multiline var start_message := "Break the black line."
@export_multiline var clear_message := "ROOM CLEARED"
@export_multiline var clear_subtitle := STOCK_CLEAR_SUBTITLE
@export_multiline var defeat_message := "THE PAWN FALLS"
@export_multiline var defeat_subtitle := "THE CHILD RESETS THE BOARD"
@export var win_condition := WinCondition.DEFEAT_ALL_ENEMIES
@export_range(1, 20) var required_defeats := 1


func is_complete(defeated_count: int, total_count: int, remaining_count: int) -> bool:
	match win_condition:
		WinCondition.DEFEAT_COUNT:
			return defeated_count >= required_defeats
		_:
			return total_count > 0 and remaining_count <= 0
