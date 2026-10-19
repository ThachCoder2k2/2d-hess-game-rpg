extends SceneTree

## Writes the Licenses block of the credits (content/story/credits_licenses.tres) from THIRD_PARTY_NOTICES.md, so the
## notices and the credits are one fact in two places and cannot drift apart (docs/game-base-plan.md 9.2). The rules
## for which entry of the notices is credited live in tools/credits_licenses.gd.
##
## Usage (project root; the options go after "--"):
##   godot --headless --path . -s tools/build_credits_licenses.gd             write the file (only if it changed)
##   godot --headless --path . -s tools/build_credits_licenses.gd -- --check   change nothing; exit 1 if the file is stale
##
## The file's uid is kept when it exists and made once when it does not. The block is plain text written as a
## .tres by hand (never ResourceSaver, which would drop uids). Run the editor import pass afterwards, then
## tools/stamp_uids.gd -- --check, as for any new resource.

const Licenses := preload("res://tools/credits_licenses.gd")

var is_check_mode := false


func _init() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	is_check_mode = "--check" in arguments

	var notices_text := FileAccess.get_file_as_string(Licenses.NOTICES_PATH)
	if notices_text.is_empty():
		printerr("build_credits_licenses: cannot read %s" % Licenses.NOTICES_PATH)
		quit(2)
		return
	var entries := Licenses.entries_from(notices_text)
	if entries.is_empty():
		printerr("build_credits_licenses: %s has no entry with a License bullet, so there is nothing to credit" % Licenses.NOTICES_PATH)
		quit(2)
		return
	var script_uid_text := FileAccess.get_file_as_string(Licenses.SECTION_SCRIPT_PATH + ".uid").strip_edges()
	if script_uid_text.is_empty():
		printerr("build_credits_licenses: %s.uid does not exist yet; run the editor import pass first" % Licenses.SECTION_SCRIPT_PATH)
		quit(2)
		return

	var existing_text := FileAccess.get_file_as_string(Licenses.OUTPUT_PATH)
	var resource_uid_text := Licenses.header_uid_of(existing_text)
	if resource_uid_text.is_empty():
		resource_uid_text = ResourceUID.id_to_text(ResourceUID.create_id())
	var new_text := Licenses.resource_text(Licenses.lines_for(entries), resource_uid_text, script_uid_text)

	if new_text == existing_text:
		print("build_credits_licenses: %s is current (%d entries)" % [Licenses.OUTPUT_PATH, entries.size()])
		quit(0)
		return
	if is_check_mode:
		print("build_credits_licenses: %s is STALE; run tools/build_credits_licenses.gd to rewrite it" % Licenses.OUTPUT_PATH)
		quit(1)
		return
	var file := FileAccess.open(Licenses.OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("build_credits_licenses: cannot write %s (error %d)" % [Licenses.OUTPUT_PATH, FileAccess.get_open_error()])
		quit(2)
		return
	file.store_string(new_text)
	file.close()
	print("build_credits_licenses: wrote %s (%d entries)" % [Licenses.OUTPUT_PATH, entries.size()])
	quit(0)
