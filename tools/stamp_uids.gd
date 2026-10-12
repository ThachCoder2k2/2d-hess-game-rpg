extends SceneTree

## Stamps UIDs into scenes and resources AT THE TEXT LEVEL. It never loads a
## scene and never calls ResourceSaver: a load+save round trip rewrites the whole
## file (format=4 becomes format=3, header uids vanish, uid references turn back
## into plain paths), which is exactly the damage this tool exists to avoid
## (docs/game-base-plan.md section 13.7).
##
## Pass 1  every .tscn / .tres whose header has no uid="..." gets a new one
##         (ResourceUID.create_id() -> id_to_text), appended inside the header.
## Pass 2  every path-only [ext_resource] line gets uid="..." inserted before its
##         path="...", taking the uid from the TARGET: its header (.tscn/.tres,
##         including one pass 1 just added), its <file>.uid sidecar (.gd, .gdshader,
##         .cs) or the uid= field of its <file>.import (png, wav, svg, ...).
##
## Only header lines and [ext_resource] lines are ever edited, so the diff is one
## changed line per stamped line and nothing else. Running it twice changes
## nothing (idempotent).
##
## Usage (project root; the user args after "--" or directly after the script):
##   godot --headless --path . -s tools/stamp_uids.gd              stamp, then report
##   godot --headless --path . -s tools/stamp_uids.gd -- --check   report only; exit 1 if anything would change
##   ... --verbose                                                 also print every changed line
##
## Exit code: apply mode 0 = fully stamped, 2 = some references could not be
## resolved (target not imported yet, or no uid source); check mode 0 = nothing to
## do, 1 = something would change or is unresolved.
##
## Skipped: .godot/, .git/, .claude/, addons/ (third-party), and any folder that
## holds a .gdignore file. Absent folders are fine. tests/fixtures is NOT skipped:
## the kingdom fixture is a real scene that needs real uids. Run the editor import
## pass (--headless --editor --quit) afterwards so Godot registers the new uids.

## Folder names never entered, wherever they appear in the tree.
const SKIPPED_DIRECTORY_NAMES: Array[String] = [".godot", ".git", ".claude", "addons"]
## Text resource types whose header can carry a uid.
const TEXT_RESOURCE_EXTENSIONS: Array[String] = ["tscn", "tres"]
## Script types whose uid lives in a "<file>.uid" sidecar.
const SIDECAR_UID_EXTENSIONS: Array[String] = ["gd", "gdshader", "cs"]
const UID_PREFIX := "uid://"
const PROJECT_ROOT := "res://"

var is_check_mode := false
var is_verbose := false

## res:// path of a .tscn/.tres -> its uid text, from its header (existing or new).
var uid_text_by_resource_path: Dictionary = {}
## uid text -> true, for every uid seen in a header or generated here (collision guard).
var claimed_uid_texts: Dictionary = {}
## res:// path -> full file text, for the text resources scanned.
var text_by_resource_path: Dictionary = {}
## res:// path -> new file text, only for files that change.
var changed_text_by_resource_path: Dictionary = {}
## target file extension -> count of ext_resource lines stamped (png: 31, ...).
var stamped_line_count_by_target_extension: Dictionary = {}
## "res://file:line -> res://target" lines for references nothing could resolve.
var unresolved_lines: PackedStringArray = PackedStringArray()
## Verbose change log lines.
var change_log_lines: PackedStringArray = PackedStringArray()
## Lines that already carry a uid that differs from the target's current uid. Reported only.
var stale_uid_lines: PackedStringArray = PackedStringArray()

var scanned_file_count := 0
var headers_stamped_count := 0
var ext_resource_total_count := 0
var ext_resource_path_only_count := 0
var ext_resource_stamped_count := 0

var header_regex := RegEx.new()
var uid_in_text_regex := RegEx.new()
var path_attribute_regex := RegEx.new()
var import_uid_regex := RegEx.new()


func _init() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	is_check_mode = "--check" in arguments
	is_verbose = "--verbose" in arguments

	header_regex.compile("^\\[(gd_scene|gd_resource)\\b[^\\]]*\\]")
	uid_in_text_regex.compile("uid=\"(uid://[^\"]+)\"")
	path_attribute_regex.compile("\\bpath=\"(res://[^\"]+)\"")
	import_uid_regex.compile("(?m)^uid=\"(uid://[^\"]+)\"")

	var resource_paths: Array[String] = []
	_collect_text_resources(PROJECT_ROOT, resource_paths)
	resource_paths.sort()
	scanned_file_count = resource_paths.size()

	for resource_path in resource_paths:
		text_by_resource_path[resource_path] = FileAccess.get_file_as_string(resource_path)
	_read_existing_header_uids(resource_paths)
	_stamp_missing_headers(resource_paths)
	_stamp_path_only_references(resource_paths)

	_print_report()
	var has_work := not changed_text_by_resource_path.is_empty()
	if is_check_mode:
		quit(1 if (has_work or not unresolved_lines.is_empty()) else 0)
		return
	if not _write_changed_files():
		quit(3)
		return
	quit(2 if not unresolved_lines.is_empty() else 0)


## Recursively gathers every .tscn/.tres under directory_path, in sorted order.
func _collect_text_resources(directory_path: String, found_paths: Array[String]) -> void:
	if FileAccess.file_exists(directory_path.path_join(".gdignore")):
		return
	var file_names := Array(DirAccess.get_files_at(directory_path))
	file_names.sort()
	for file_name: String in file_names:
		if file_name.get_extension() in TEXT_RESOURCE_EXTENSIONS:
			found_paths.append(directory_path.path_join(file_name))
	var directory_names := Array(DirAccess.get_directories_at(directory_path))
	directory_names.sort()
	for directory_name: String in directory_names:
		if directory_name in SKIPPED_DIRECTORY_NAMES:
			continue
		_collect_text_resources(directory_path.path_join(directory_name), found_paths)


func _read_existing_header_uids(resource_paths: Array[String]) -> void:
	for resource_path in resource_paths:
		var header_line := _header_line_of(text_by_resource_path[resource_path])
		var uid_match := uid_in_text_regex.search(header_line)
		if uid_match != null:
			var uid_text := uid_match.get_string(1)
			uid_text_by_resource_path[resource_path] = uid_text
			claimed_uid_texts[uid_text] = true


## Pass 1: give every uid-less header a fresh uid, appended inside the brackets.
func _stamp_missing_headers(resource_paths: Array[String]) -> void:
	for resource_path in resource_paths:
		if uid_text_by_resource_path.has(resource_path):
			continue
		var file_text: String = text_by_resource_path[resource_path]
		var header_line := _header_line_of(file_text)
		var header_match := header_regex.search(header_line)
		if header_match == null:
			unresolved_lines.append("%s:1 -> header is not [gd_scene ...] or [gd_resource ...]; no uid added" % resource_path)
			continue
		var new_uid_text := _create_unclaimed_uid_text()
		var matched_header := header_match.get_string()
		var stamped_header := matched_header.substr(0, matched_header.length() - 1) + " uid=\"%s\"]" % new_uid_text
		var new_header_line := header_line.replace(matched_header, stamped_header)
		var new_text := new_header_line + file_text.substr(header_line.length())
		uid_text_by_resource_path[resource_path] = new_uid_text
		changed_text_by_resource_path[resource_path] = new_text
		headers_stamped_count += 1
		change_log_lines.append("%s:1 header +%s" % [resource_path, new_uid_text])


## Pass 2: add uid= to every path-only [ext_resource] line.
func _stamp_path_only_references(resource_paths: Array[String]) -> void:
	for resource_path in resource_paths:
		var file_text: String = changed_text_by_resource_path.get(resource_path, text_by_resource_path[resource_path])
		var lines := file_text.split("\n")
		var file_changed := false
		for line_index in range(lines.size()):
			var line := lines[line_index]
			if not line.begins_with("[ext_resource "):
				continue
			ext_resource_total_count += 1
			var path_match := path_attribute_regex.search(line)
			if path_match == null:
				continue
			var target_path := path_match.get_string(1)
			var existing_uid_match := uid_in_text_regex.search(line)
			if existing_uid_match != null:
				var current_uid_text := _resolve_target_uid_text(target_path)
				if not current_uid_text.is_empty() and current_uid_text != existing_uid_match.get_string(1):
					stale_uid_lines.append("%s:%d has %s but %s is %s" % [resource_path, line_index + 1, existing_uid_match.get_string(1), target_path, current_uid_text])
				continue
			ext_resource_path_only_count += 1
			var target_uid_text := _resolve_target_uid_text(target_path)
			if target_uid_text.is_empty():
				unresolved_lines.append("%s:%d -> %s (no header uid, .uid sidecar or .import uid)" % [resource_path, line_index + 1, target_path])
				continue
			lines[line_index] = line.replace(" path=\"%s\"" % target_path, " uid=\"%s\" path=\"%s\"" % [target_uid_text, target_path])
			file_changed = true
			ext_resource_stamped_count += 1
			var target_extension := target_path.get_extension()
			stamped_line_count_by_target_extension[target_extension] = int(stamped_line_count_by_target_extension.get(target_extension, 0)) + 1
			change_log_lines.append("%s:%d +%s (%s)" % [resource_path, line_index + 1, target_uid_text, target_path])
		if file_changed:
			changed_text_by_resource_path[resource_path] = "\n".join(lines)


## The uid of any referenced file, or "" when it has none yet.
func _resolve_target_uid_text(target_path: String) -> String:
	if uid_text_by_resource_path.has(target_path):
		return uid_text_by_resource_path[target_path]
	var target_extension := target_path.get_extension()
	if target_extension in SIDECAR_UID_EXTENSIONS:
		var sidecar_text := FileAccess.get_file_as_string(target_path + ".uid").strip_edges()
		return sidecar_text if sidecar_text.begins_with(UID_PREFIX) else ""
	if target_extension in TEXT_RESOURCE_EXTENSIONS:
		# A scene or resource outside the scanned folders (a skipped folder): read its header.
		var header_match := uid_in_text_regex.search(_header_line_of(FileAccess.get_file_as_string(target_path)))
		return header_match.get_string(1) if header_match != null else ""
	var import_match := import_uid_regex.search(FileAccess.get_file_as_string(target_path + ".import"))
	return import_match.get_string(1) if import_match != null else ""


## A uid that no header in the project and no registered resource already uses.
## Random 64-bit ids collide with probability ~0, so the retry loop is a formality.
func _create_unclaimed_uid_text() -> String:
	var uid_text := ""
	for _attempt in range(100):
		var uid_id := ResourceUID.create_id()
		uid_text = ResourceUID.id_to_text(uid_id)
		if not claimed_uid_texts.has(uid_text) and not ResourceUID.has_id(uid_id):
			break
	claimed_uid_texts[uid_text] = true
	return uid_text


## The first line of a file, without its newline (and keeping a trailing \r if present).
func _header_line_of(file_text: String) -> String:
	var first_newline := file_text.find("\n")
	return file_text if first_newline == -1 else file_text.substr(0, first_newline)


func _write_changed_files() -> bool:
	var resource_paths: Array = changed_text_by_resource_path.keys()
	resource_paths.sort()
	for resource_path: String in resource_paths:
		var file := FileAccess.open(resource_path, FileAccess.WRITE)
		if file == null:
			printerr("STAMP UIDS: cannot write %s (error %d)" % [resource_path, FileAccess.get_open_error()])
			return false
		file.store_string(changed_text_by_resource_path[resource_path])
		file.close()
	return true


func _print_report() -> void:
	print("STAMP UIDS (%s): scanned %d scene/resource file(s)" % ["check, nothing written" if is_check_mode else "apply", scanned_file_count])
	print("  headers without uid : %d %s" % [headers_stamped_count, "would be stamped" if is_check_mode else "stamped"])
	print("  ext_resource lines  : %d total, %d path-only, %d %s" % [ext_resource_total_count, ext_resource_path_only_count, ext_resource_stamped_count, "would be stamped" if is_check_mode else "stamped"])
	var extensions: Array = stamped_line_count_by_target_extension.keys()
	extensions.sort()
	var kind_parts := PackedStringArray()
	for extension: String in extensions:
		kind_parts.append("%s %d" % [extension, stamped_line_count_by_target_extension[extension]])
	if not kind_parts.is_empty():
		print("  stamped by target   : %s" % ", ".join(kind_parts))
	print("  files changed       : %d" % changed_text_by_resource_path.size())
	print("  unresolved (missing): %d" % unresolved_lines.size())
	for line in unresolved_lines:
		print("    MISSING %s" % line)
	print("  stale uids (warning): %d" % stale_uid_lines.size())
	for line in stale_uid_lines:
		print("    STALE %s" % line)
	if is_verbose:
		for line in change_log_lines:
			print("  CHANGE %s" % line)
	var verdict := "CLEAN" if (changed_text_by_resource_path.is_empty() and unresolved_lines.is_empty()) else ("PENDING" if is_check_mode else "DONE")
	print("STAMP UIDS: %s" % verdict)
