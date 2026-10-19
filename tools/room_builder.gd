extends RefCounted

## One build of one room, start to finish (a helper, not a command; no class_name, preload it). The command line is
## tools/build_room.gd; tests/tools/test_build_room.gd calls this directly with scratch paths, so what the tool does and
## what the test proves are the same code.
##
## A build: read the layout -> ask the manifest whether the target scene may be written -> write the scene text
## (tools/room_scene_writer.gd) -> boot the written scene and compare its grid with the layout -> only then keep it,
## add the English rows its text keys need to content/story/text/en/rooms.po, and record it in the manifest. A build
## that fails any step leaves the target as it was (a new scene is removed, a rebuilt one is put back).
##
## The options (a Dictionary):
##   layout_text         the layout file's text                                                    [required]
##   layout_label        what to call the layout in a sentence (its path)                          [default: the id]
##   expected_id         the file name of the layout without .txt; its room id must equal it       [default: skip]
##   scene_path          where to write the scene                                                  [required]
##   force               rebuild a scene this tool built and nobody edited                         [default false]
##   manifest_path       the manifest file                                                         [default the tracked one]
##   text_rows_path      the English rooms.po to add missing rows to; "" = add none                [default ""]
##   stamp               run tools/stamp_uids.gd afterwards (only for a scene under res://)       [default false]
##
## The answer: { "ok": bool, "problems": PackedStringArray, "notes": PackedStringArray, "scene_path": String,
## "added_text_keys": Array[String] }.

const RoomLayout := preload("res://tools/room_layout.gd")
const RoomSceneWriter := preload("res://tools/room_scene_writer.gd")
const BuiltRoomsManifest := preload("res://tools/built_rooms_manifest.gd")
const SaveKeepingUids := preload("res://tools/save_keeping_uids.gd")

const ENGLISH_ROOMS_PO := "res://content/story/text/en/rooms.po"


static func build(options: Dictionary) -> Dictionary:
	var answer := {"ok": false, "problems": PackedStringArray(), "notes": PackedStringArray(), "scene_path": String(options.get("scene_path", "")), "added_text_keys": [] as Array[String]}
	var problems := PackedStringArray()
	var notes := PackedStringArray()
	var layout_text := String(options.get("layout_text", ""))
	var scene_path := String(options.get("scene_path", ""))
	var manifest_path := String(options.get("manifest_path", BuiltRoomsManifest.DEFAULT_PATH))

	var layout: RefCounted = RoomLayout.parse(layout_text, String(options.get("expected_id", "")), String(options.get("layout_label", "")))
	if not (layout.problems as PackedStringArray).is_empty():
		answer["problems"] = layout.problems
		return answer

	var manifest := BuiltRoomsManifest.read_manifest(manifest_path)
	if not String(manifest["error"]).is_empty():
		problems.append(String(manifest["error"]))
		answer["problems"] = problems
		return answer
	var refusal := BuiltRoomsManifest.refusal_for(scene_path, manifest["scenes"], bool(options.get("force", false)))
	if not refusal.is_empty():
		problems.append(refusal)
		answer["problems"] = problems
		return answer

	var previous_text := FileAccess.get_file_as_string(scene_path) if FileAccess.file_exists(scene_path) else ""
	var existed_before := FileAccess.file_exists(scene_path)
	var kept_uid_text := ""
	if existed_before:
		var uid_match := RegEx.create_from_string("uid=\"(uid://[^\"]+)\"").search(previous_text.get_slice("\n", 0))
		kept_uid_text = uid_match.get_string(1) if uid_match != null else ""

	var written := RoomSceneWriter.scene_text(layout, kept_uid_text)
	if not (written["problems"] as PackedStringArray).is_empty():
		answer["problems"] = written["problems"]
		return answer

	DirAccess.make_dir_recursive_absolute(scene_path.get_base_dir())
	var file := FileAccess.open(scene_path, FileAccess.WRITE)
	if file == null:
		problems.append("cannot write %s (error %d)" % [scene_path, FileAccess.get_open_error()])
		answer["problems"] = problems
		return answer
	file.store_string(String(written["text"]))
	file.close()

	if bool(options.get("stamp", false)) and not SaveKeepingUids.stamp_uids_last():
		problems.append("tools/stamp_uids.gd could not stamp every reference of %s" % scene_path)

	var verify_problems := RoomSceneWriter.verify_scene(scene_path, layout)
	for sentence in verify_problems:
		problems.append("the scene it wrote does not match the layout: %s" % sentence)
	if not problems.is_empty():
		_put_back(scene_path, existed_before, previous_text)
		answer["problems"] = problems
		return answer

	var text_rows_path := String(options.get("text_rows_path", ""))
	if not text_rows_path.is_empty():
		var added_keys := _add_missing_text_rows(text_rows_path, written["text_rows"], layout.room_id)
		answer["added_text_keys"] = added_keys
		for key in added_keys:
			notes.append("added the English row %s to %s" % [key, text_rows_path])

	var scenes: Dictionary = manifest["scenes"]
	scenes[scene_path] = BuiltRoomsManifest.row_for(layout.room_id, layout_text, scene_path)
	var manifest_error := BuiltRoomsManifest.write_manifest(scenes, manifest_path)
	if manifest_error != OK:
		problems.append("cannot write the manifest %s (error %d)" % [manifest_path, manifest_error])
		answer["problems"] = problems
		return answer

	notes.append("built %s from the layout of %s" % [scene_path, layout.room_id])
	answer["ok"] = true
	answer["notes"] = notes
	return answer


## Undoes a write that did not check out: a scene that did not exist is removed, a rebuilt one gets its old text back.
static func _put_back(scene_path: String, existed_before: bool, previous_text: String) -> void:
	if existed_before:
		var file := FileAccess.open(scene_path, FileAccess.WRITE)
		if file != null:
			file.store_string(previous_text)
			file.close()
	else:
		DirAccess.remove_absolute(scene_path)


## Appends a row to the English rooms file for every key the scene names that the file does not have yet, each with
## the translator comment the text lint asks for. A row that exists is left alone, whoever wrote it. Returns the keys added.
static func _add_missing_text_rows(po_path: String, text_rows: Array, room_id: String) -> Array[String]:
	var added: Array[String] = []
	var po_text := FileAccess.get_file_as_string(po_path)
	if po_text.is_empty():
		return added
	var appended := ""
	for row: Dictionary in text_rows:
		var key := String(row["key"])
		if po_text.contains("msgid \"%s\"" % key) or appended.contains("msgid \"%s\"" % key):
			continue
		appended += "\n#. room=%s; surface=%s; purpose=%s; placeholder; written by tools/build_room.gd from tools/layouts/%s.txt\n" % [room_id, _surface_of(key), String(row["purpose"]), room_id]
		appended += "msgid \"%s\"\nmsgstr \"%s\"\n" % [key, _escaped(String(row["text"]))]
		added.append(key)
	if appended.is_empty():
		return added
	var file := FileAccess.open(po_path, FileAccess.WRITE)
	if file == null:
		return [] as Array[String]
	file.store_string(po_text.rstrip("\n") + "\n" + appended)
	file.close()
	return added


## Where a key's words are shown, for the translator comment.
static func _surface_of(key: String) -> String:
	if key.ends_with("_NAME"):
		return "save card, title card, pause menu"
	if key.contains("_LOCKED"):
		return "status line when the pawn steps on the shut door"
	if key.contains("_UNLOCK_"):
		return "status line when the pawn steps on the unlock cell"
	return "status line on arrival"


static func _escaped(text: String) -> String:
	return text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
