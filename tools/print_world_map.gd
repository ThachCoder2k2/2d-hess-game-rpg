extends SceneTree

## Prints the world as ASCII (docs/game-base-plan.md 7.1): every room on its map slot, every door, every lock, and what
## the checks (WorldCheck) find wrong. The world map screen itself is deferred (req#121); this is the QA view of
## content/world/world.tres. The drawing lives in tools/world_map_printer.gd so a test can read the same text.
##
##   godot --headless --path . -s tools/print_world_map.gd
##   godot --headless --path . -s tools/print_world_map.gd -- --out=docs/world_map.txt
##
## Exit code 0 = printed and the checks are clean, 1 = printed and the checks found problems (or no world to print).

const WorldMapPrinter := preload("res://tools/world_map_printer.gd")


func _init() -> void:
	var graph := ContentDb.world()
	if graph == null:
		printerr("PRINT WORLD MAP: content/world/world.tres does not load")
		quit(1)
		return
	var text := WorldMapPrinter.map_text(graph, WorldMapPrinter.scans_of(graph))
	var arguments := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for argument in arguments:
		if argument.begins_with("--out="):
			var file := FileAccess.open(argument.trim_prefix("--out="), FileAccess.WRITE)
			if file == null:
				printerr("PRINT WORLD MAP: cannot write %s" % argument.trim_prefix("--out="))
				quit(1)
				return
			file.store_string(text)
			file.close()
			print("PRINT WORLD MAP: wrote %s" % argument.trim_prefix("--out="))
			quit(0)
			return
	print(text)
	quit(0 if text.contains("CHECKS  every door resolves") else 1)
