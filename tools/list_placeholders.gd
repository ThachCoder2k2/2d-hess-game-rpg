extends SceneTree

## Prints the owner's art and audio TODO (docs/game-base-plan.md section 12): every file that
## still stands in for something the owner will supply, grouped by kind. Read-only.
##
## A file is a placeholder if and only if its sha256 still equals the hash recorded in
## content/_placeholders.json when tools/seed_placeholders.gd seeded it. So the list shrinks by
## itself as the owner overwrites files (same name, same role); there is nothing to tick off.
##
##   godot --headless --path . -s tools/list_placeholders.gd
##
## Exit code: 0 = the list was printed, 1 = the manifest is missing or broken, or a listed
## file is gone (restore it or remove its entry).

const PlaceholderManifest := preload("res://tools/placeholder_manifest.gd")


func _init() -> void:
	var manifest := PlaceholderManifest.read_manifest()
	if not String(manifest["error"]).is_empty():
		printerr("LIST PLACEHOLDERS: %s" % manifest["error"])
		quit(1)
		return
	var entries: Array[Dictionary] = manifest["entries"]
	for line in PlaceholderManifest.todo_lines(entries):
		print(line)
	var missing_count := 0
	for entry in entries:
		if PlaceholderManifest.status_of(entry) == PlaceholderManifest.STATUS_MISSING:
			missing_count += 1
	quit(1 if missing_count > 0 else 0)
