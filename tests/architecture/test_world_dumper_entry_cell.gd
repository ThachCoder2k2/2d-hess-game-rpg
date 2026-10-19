extends UnboundTest

## The deterministic world dump reads the room's entry marker the way shell/game_root.gd does: with the
## room's own grid origin (EcsBoot.shape_grid), because a marker's position is turned into a cell with
## it. Until this suite existed the dumper turned it into a cell with the grid's default origin first, so
## the "entry_cell:" line of any board that is not 16x9 was off by one (an 18x9 arena starts at x 32, not
## 64). Every baseline room is 16x9, which is why no baseline showed it.
##
## The room under test is built in code and saved under user:// (never a tracked scene): an 18x9 board with
## its entry marker standing exactly on cell (2, 4) of that board.

const WorldDumper := preload("res://tools/world_dumper.gd")

const WIDE_BOARD := Vector2i(18, 9)
const ENTRY_CELL := Vector2i(2, 4)
const ROOM_PATH := "user://test_world_dumper_wide_room.tscn"


func _init() -> void:
	suite_title = "WORLD DUMPER ENTRY CELL TEST"
	var wide_room := _build_wide_room()
	_expect(wide_room != null and ResourceSaver.save(wide_room, ROOM_PATH) == OK, "setup: an 18x9 room with its entry marker on cell (2, 4) is saved")

	var dumper := WorldDumper.new()
	var dump_text := dumper.dump_room(self, ROOM_PATH)
	_expect(not dump_text.is_empty(), "the 18x9 room boots in the dumper%s" % ("" if dumper.last_error.is_empty() else " (" + dumper.last_error + ")"))
	_expect(dump_text.contains("\nentry_cell: (%d, %d)\n" % [ENTRY_CELL.x, ENTRY_CELL.y]), "the dump names the entry cell the marker stands on, not the cell the default origin would give")
	_expect(dump_text.contains("\ngrid_origin: (32.00,36.00)\n"), "the dump shows the room's own origin, so the entry cell above was read with it")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOM_PATH))
	finish()


## A RoomEncounter of WIDE_BOARD cells whose "start" entry marker is placed from the shaped grid, so the
## marker sits on ENTRY_CELL whatever origin the shaping picks.
func _build_wide_room() -> PackedScene:
	var room := RoomEncounter.new()
	room.name = "WideRoom"
	room.board_size = WIDE_BOARD
	var placing_world := EcsWorld.new()
	EcsBoot.shape_grid(placing_world, room)
	var entry := ZoneEntryMarker.new()
	entry.name = "Entry"
	entry.entry_id = &"start"
	entry.position = placing_world.grid.cell_to_world(ENTRY_CELL)
	room.add_child(entry)
	entry.owner = room
	var packed := PackedScene.new()
	var packed_ok := packed.pack(room) == OK
	room.free()
	placing_world.free()
	return packed if packed_ok else null
