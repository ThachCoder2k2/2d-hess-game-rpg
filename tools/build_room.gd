extends SceneTree

## Builds a room scene from an ASCII layout (docs/game-base-plan.md 7.5, 15 M5): the greybox tool. Agents cannot
## hand-edit a TileMap blob, so the room's tiles are painted by tools/cell_kind_painter.gd from the layout, and the
## scene is written as TEXT with uids (never re-saved by ResourceSaver, which drops them).
##
##   godot --headless --path . -s tools/build_room.gd -- --room=tb1_toybox_gate
##   godot --headless --path . -s tools/build_room.gd -- --room=tb1_toybox_gate --force
##   godot --headless --path . -s tools/build_room.gd -- --layout=res://tests/fixtures/layouts/t4_broken_rule_yard.txt --out=user://scratch/room.tscn --manifest=user://scratch/built.json
##   godot --headless --path . -s tools/build_room.gd -- --check           validate every layout in tools/layouts/, build nothing
##   godot --headless --path . -s tools/build_room.gd -- --legend          print the layout format
##
## Options (after "--"):
##   --room=ID            build tools/layouts/ID.txt into content/rooms/ID/room.tscn
##   --layout=PATH        build this layout file instead (the room id must equal the file name)
##   --out=PATH           write the scene here instead of content/rooms/<id>/room.tscn (a scratch build)
##   --force              rebuild a scene this tool built and nobody edited since (see tools/built_rooms_manifest.gd);
##                        a scene it did not build, or that was edited, is NEVER overwritten
##   --manifest=PATH      the record of built scenes (default tools/layouts/built_rooms.json)
##   --no-text-rows       do not add the room's English rows to content/story/text/en/rooms.po
##   --check              parse and validate every layout in tools/layouts/ (or the one named), write nothing
##   --legend             print the layout format and exit
##
## After a build under res://: run the editor import pass (`--headless --editor --quit`) so Godot registers the new
## scene, then `tools/stamp_uids.gd -- --check` (it must say CLEAN), and commit the scene, the .po rows and the manifest.
## Exit code 0 = built (or all layouts valid), 1 = refused or failed.

const RoomLayout := preload("res://tools/room_layout.gd")
const RoomBuilder := preload("res://tools/room_builder.gd")
const LAYOUTS_FOLDER := "res://tools/layouts"


func _init() -> void:
	var options := _parse_options(OS.get_cmdline_user_args() + OS.get_cmdline_args())
	if options.has("legend"):
		print(RoomLayout.legend_text())
		quit(0)
		return
	if options.has("check"):
		quit(_check_layouts(String(options.get("room", ""))))
		return
	var layout_path := String(options.get("layout", ""))
	if layout_path.is_empty() and options.has("room"):
		layout_path = "%s/%s.txt" % [LAYOUTS_FOLDER, options["room"]]
	if layout_path.is_empty():
		printerr("BUILD ROOM: pass --room=<id>, --layout=<path>, --check or --legend (see the header of tools/build_room.gd)")
		quit(1)
		return
	if not FileAccess.file_exists(layout_path):
		printerr("BUILD ROOM: no layout at %s" % layout_path)
		quit(1)
		return
	var room_id := layout_path.get_file().get_basename()
	var scene_path := String(options.get("out", "res://content/rooms/%s/room.tscn" % room_id))
	var build_options := {
		"layout_text": FileAccess.get_file_as_string(layout_path),
		"layout_label": layout_path,
		"expected_id": room_id,
		"scene_path": scene_path,
		"force": options.has("force"),
		"stamp": scene_path.begins_with("res://"),
		"text_rows_path": RoomBuilder.ENGLISH_ROOMS_PO if scene_path.begins_with("res://content/rooms/") and not options.has("no-text-rows") else "",
	}
	if options.has("manifest"):
		build_options["manifest_path"] = String(options["manifest"])
	var answer := RoomBuilder.build(build_options)
	for note: String in answer["notes"]:
		print("BUILD ROOM: %s" % note)
	if not bool(answer["ok"]):
		for problem: String in answer["problems"]:
			printerr("BUILD ROOM: %s" % problem)
		printerr("BUILD ROOM: refused or failed; nothing was left changed")
		quit(1)
		return
	print("BUILD ROOM: OK %s" % scene_path)
	if scene_path.begins_with("res://"):
		print("BUILD ROOM: now run the import pass, then tools/stamp_uids.gd -- --check")
	quit(0)


## Validates the layouts without building. Returns the exit code.
func _check_layouts(only_room: String) -> int:
	var failed := false
	var checked := 0
	for file_name in DirAccess.get_files_at(LAYOUTS_FOLDER):
		if not file_name.ends_with(".txt") or (not only_room.is_empty() and file_name.get_basename() != only_room):
			continue
		checked += 1
		var layout: RefCounted = RoomLayout.parse(FileAccess.get_file_as_string("%s/%s" % [LAYOUTS_FOLDER, file_name]), file_name.get_basename(), "%s/%s" % [LAYOUTS_FOLDER, file_name])
		for problem: String in layout.problems:
			printerr("BUILD ROOM: %s" % problem)
			failed = true
	print("BUILD ROOM: %d layout(s) checked, %s" % [checked, "PROBLEMS FOUND" if failed else "all valid"])
	return 1 if failed or checked == 0 else 0


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	for argument in arguments:
		if not argument.begins_with("--"):
			continue
		var body := argument.trim_prefix("--")
		if body.contains("="):
			parsed[body.get_slice("=", 0)] = body.substr(body.find("=") + 1)
		else:
			parsed[body] = true
	return parsed
