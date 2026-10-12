extends SceneTree

## Command line for the deterministic world dump (the logic lives in
## tools/world_dumper.gd, shared with tests/architecture/test_dump_baselines.gd).
## Boots a room headless, runs N manual ticks, prints sorted node paths, texture
## paths and every entity's cell and components. See docs/game-base-plan.md 13.7.
##
##   godot --headless --path . -s tools/dump_world.gd -- --room=t1
##   godot --headless --path . -s tools/dump_world.gd -- --room=h1 --ticks=60 --out=tests/baselines/dump_h1.txt
##   godot --headless --path . -s tools/dump_world.gd -- --write-baselines     rewrite all six baselines
##   godot --headless --path . -s tools/dump_world.gd -- --list                zone ids in the world graph
##
## Options (after "--", or directly after the script):
##   --room=ID           a short code (t1), a zone id (t1_white_kings_fall) or a res:// scene path
##   --ticks=N           manual ticks of 1/60 s (default 120)
##   --out=PATH          write the dump there instead of printing it (relative paths are project paths)
##   --write-baselines   dump every baseline room into tests/baselines/dump_<room>.txt
##   --list              print the zone ids and the baseline room codes
##
## Without --out the dump goes to stdout after Godot's own banner line. Exit code 0 = ok, 1 = error.

const WorldDumper := preload("res://tools/world_dumper.gd")


func _init() -> void:
	var options := _parse_options(OS.get_cmdline_user_args() + OS.get_cmdline_args())
	var dumper := WorldDumper.new()

	if options.has("list"):
		print("zone ids: %s" % ", ".join(dumper.list_zone_ids()))
		print("baseline room codes: %s" % ", ".join(WorldDumper.BASELINE_ROOM_IDS))
		quit(0)
		return

	var tick_count := int(options.get("ticks", WorldDumper.DEFAULT_TICK_COUNT))
	if options.has("write-baselines"):
		var written_count := 0
		for room_id in WorldDumper.BASELINE_ROOM_IDS:
			var baseline_text := dumper.dump_room(self, room_id, tick_count)
			if baseline_text.is_empty() or not _write_text(dumper.baseline_path(room_id), baseline_text):
				printerr("DUMP WORLD: failed for '%s': %s" % [room_id, dumper.last_error])
				quit(1)
				return
			written_count += 1
			print("DUMP WORLD: wrote %s (%d lines)" % [dumper.baseline_path(room_id), baseline_text.count("\n")])
		print("DUMP WORLD: %d baseline(s) written" % written_count)
		quit(0)
		return

	var room_id := String(options.get("room", ""))
	if room_id.is_empty():
		printerr("DUMP WORLD: pass --room=<id>, --write-baselines or --list (see the header of tools/dump_world.gd)")
		quit(1)
		return
	var text := dumper.dump_room(self, room_id, tick_count)
	if text.is_empty():
		printerr("DUMP WORLD: %s" % dumper.last_error)
		quit(1)
		return
	if options.has("out"):
		var out_path := String(options["out"])
		if not out_path.begins_with("res://") and not out_path.is_absolute_path():
			out_path = "res://" + out_path
		if not _write_text(out_path, text):
			printerr("DUMP WORLD: cannot write %s" % out_path)
			quit(1)
			return
		print("DUMP WORLD: wrote %s (%d lines)" % [out_path, text.count("\n")])
	else:
		print(text.trim_suffix("\n"))
	quit(0)


## "--key=value" and "--flag" arguments as { key: value-or-true }; other arguments are ignored.
func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {}
	for argument in arguments:
		if not argument.begins_with("--"):
			continue
		var body := argument.trim_prefix("--")
		var equals_index := body.find("=")
		if equals_index == -1:
			options[body] = true
		else:
			options[body.substr(0, equals_index)] = body.substr(equals_index + 1)
	return options


func _write_text(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true
