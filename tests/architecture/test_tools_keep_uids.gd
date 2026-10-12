extends UnboundTest

## Architecture guard (ENFORCING): a tool that saves a scene or resource must not
## drop its uids. ResourceSaver.save() on an existing .tscn/.tres writes a file
## with no header uid and no uid on its [ext_resource] lines, which breaks every
## scene that names the file by uid (seven room scenes name kingdom_tilemap.tscn
## that way). So (docs/game-base-plan.md 13.7):
##
##  1. no script under tools/ calls ResourceSaver.save() itself; they go through
##     tools/save_keeping_uids.gd, which puts the previous header uid back;
##  2. every script that saves that way also calls stamp_uids_last() so the
##     [ext_resource] lines get their uids from the stamper;
##  3. the helper really keeps the header uid across a re-save (probe file under
##     .godot/, which is gitignored and never scanned by the stamper).
##
## If this fails after you wrote a new tool, replace its ResourceSaver.save(x, p)
## with SaveKeepingUids.save_keeping_uid(x, p) and call
## SaveKeepingUids.stamp_uids_last() once, last (see paint_kingdom_tilemap.gd).

const ProjectFiles := preload("res://tests/architecture/project_files.gd")
const SaveKeepingUids := preload("res://tools/save_keeping_uids.gd")

const HELPER_SCRIPT_PATH := "res://tools/save_keeping_uids.gd"
## Fewer tool scripts than this means the walk is broken, not that the tools are clean.
const MINIMUM_TOOL_SCRIPTS := 10
## Under .godot/ so the probe is never tracked and never stamped.
const PROBE_SCENE_PATH := "res://.godot/save_keeping_uids_probe.tscn"


func _init() -> void:
	suite_title = "ARCHITECTURE TOOLS KEEP UIDS TEST"
	_check_tools_go_through_the_helper()
	_check_helper_keeps_header_uid()
	finish()


func _check_tools_go_through_the_helper() -> void:
	var tool_paths := ProjectFiles.collect_files(["gd"], "res://tools")
	_expect(tool_paths.size() >= MINIMUM_TOOL_SCRIPTS, "the walk found %d tool scripts (at least %d)" % [tool_paths.size(), MINIMUM_TOOL_SCRIPTS])
	var direct_savers: Array[String] = []
	var savers_without_stamp: Array[String] = []
	var helper_user_count := 0
	for tool_path in tool_paths:
		if tool_path == HELPER_SCRIPT_PATH:
			continue
		var code_text := _code_without_comments(ProjectFiles.read_text(tool_path))
		if code_text.contains("ResourceSaver.save("):
			direct_savers.append(tool_path)
		if code_text.contains("save_keeping_uid("):
			helper_user_count += 1
			if not code_text.contains("stamp_uids_last()"):
				savers_without_stamp.append(tool_path)
	_expect(direct_savers.is_empty(), "no tool calls ResourceSaver.save() directly%s" % _named(direct_savers))
	_expect(savers_without_stamp.is_empty(), "every tool that saves through the helper also stamps uids last%s" % _named(savers_without_stamp))
	_expect(helper_user_count >= 3, "the three ResourceSaver tools (kingdom, zone, playground) use the helper (found %d)" % helper_user_count)


func _check_helper_keeps_header_uid() -> void:
	var remembered_uid_id := ResourceUID.create_id()
	var remembered_uid_text := ResourceUID.id_to_text(remembered_uid_id)

	# A first save has no uid; give the file one the way an existing tracked scene has one.
	_expect(ResourceSaver.save(_packed_node(), PROBE_SCENE_PATH) == OK, "the probe scene saves")
	_expect(ResourceSaver.set_uid(PROBE_SCENE_PATH, remembered_uid_id) == OK, "the probe scene accepts a header uid")
	_expect(_header_of(PROBE_SCENE_PATH).contains(remembered_uid_text), "the probe scene header carries the remembered uid before the re-save")

	_expect(SaveKeepingUids.save_keeping_uid(_packed_node(), PROBE_SCENE_PATH) == OK, "save_keeping_uid() re-saves the probe scene")
	_expect(_header_of(PROBE_SCENE_PATH).contains(remembered_uid_text), "the header uid survives a re-save through the helper")

	# A file that never had a uid stays uid-less: giving it one is stamp_uids_last()'s job.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROBE_SCENE_PATH))
	_expect(SaveKeepingUids.save_keeping_uid(_packed_node(), PROBE_SCENE_PATH) == OK, "save_keeping_uid() creates a new file")
	_expect(not _header_of(PROBE_SCENE_PATH).contains("uid://"), "a brand-new file gets no invented uid from the helper")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROBE_SCENE_PATH))
	_expect(not FileAccess.file_exists(PROBE_SCENE_PATH), "the probe scene is removed again")


func _packed_node() -> PackedScene:
	var root_node := Node2D.new()
	var packed_scene := PackedScene.new()
	packed_scene.pack(root_node)
	root_node.free()
	return packed_scene


func _header_of(resource_path: String) -> String:
	return FileAccess.get_file_as_string(resource_path).get_slice("\n", 0)


## The script text without full-line comments, so prose that names ResourceSaver does not count.
func _code_without_comments(script_text: String) -> String:
	var code_lines := PackedStringArray()
	for line in script_text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			code_lines.append(line)
	return "\n".join(code_lines)


func _named(paths: Array[String]) -> String:
	return "" if paths.is_empty() else " (offenders: %s)" % ", ".join(PackedStringArray(paths))
