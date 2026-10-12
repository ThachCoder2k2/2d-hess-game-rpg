extends RefCounted

## Shared by every tool that calls ResourceSaver (a helper, not a command; no
## class_name, preload it: `const SaveKeepingUids := preload("res://tools/save_keeping_uids.gd")`).
##
## Why: ResourceSaver.save() on an existing .tscn/.tres writes a file with NO
## uid in its header and NO uid on its [ext_resource] lines (measured on
## tools/paint_kingdom_tilemap.gd: the header uid and the TileSet reference's uid
## both vanished). Seven room scenes name objects/world/kingdom_tilemap.tscn by
## that header uid, so a plain re-save leaves them pointing at an id that no
## longer exists. Stamping afterwards would invent a NEW header uid, which does
## not help. So the contract (docs/game-base-plan.md 13.7) is two steps:
##
##   1. save_keeping_uid()  saves, then puts the file's previous header uid back
##                          (text-level, via ResourceSaver.set_uid()).
##   2. stamp_uids_last()   runs tools/stamp_uids.gd over the tree, which adds the
##                          missing uid="..." to every path-only [ext_resource]
##                          line, taking it from the target. Call it once, last.
##
## ResourceSaver also writes a fresh random unique_id on each node, so a re-save of
## a tracked scene always shows those lines in the diff. They are harmless.

const STAMPER_SCRIPT_PATH := "res://tools/stamp_uids.gd"
const UID_IN_HEADER_PATTERN := "uid=\"(uid://[^\"]+)\""


## Saves resource to resource_path and keeps the uid the file at that path already
## had (a brand-new file has none yet; stamp_uids_last() gives it one).
static func save_keeping_uid(resource: Resource, resource_path: String, save_flags: int = ResourceSaver.FLAG_NONE) -> Error:
	var previous_uid_text := _header_uid_text_of(resource_path)
	var save_error := ResourceSaver.save(resource, resource_path, save_flags)
	if save_error != OK or previous_uid_text.is_empty():
		return save_error
	return ResourceSaver.set_uid(resource_path, ResourceUID.text_to_id(previous_uid_text))


## Runs tools/stamp_uids.gd in a child Godot process (the stamper ends with quit(),
## so it cannot run inside the calling tool) and returns true when it exits 0, which
## means every scene and resource in the tree is fully stamped. Its report is printed.
## Run the editor import pass afterwards so Godot registers any new uid.
static func stamp_uids_last() -> bool:
	var stamper_output: Array = []
	var stamper_arguments := PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", STAMPER_SCRIPT_PATH,
	])
	var exit_code := OS.execute(OS.get_executable_path(), stamper_arguments, stamper_output, true)
	for output_text: String in stamper_output:
		print(output_text.strip_edges())
	if exit_code != 0:
		printerr("SAVE KEEPING UIDS: tools/stamp_uids.gd exited %d, some references are unstamped" % exit_code)
	return exit_code == 0


## The uid text ("uid://...") in the first line of a .tscn/.tres, or "" when the
## file does not exist yet or has no uid.
static func _header_uid_text_of(resource_path: String) -> String:
	if not FileAccess.file_exists(resource_path):
		return ""
	var file_text := FileAccess.get_file_as_string(resource_path)
	var header_line := file_text.get_slice("\n", 0)
	var uid_regex := RegEx.create_from_string(UID_IN_HEADER_PATTERN)
	var uid_match := uid_regex.search(header_line)
	return uid_match.get_string(1) if uid_match != null else ""
