extends RefCounted

## The record of the room scenes tools/build_room.gd wrote (a helper, not a command; no class_name, preload it).
## It exists for one rule: THE BUILDER NEVER OVERWRITES A SCENE THAT IS NOT PROVABLY ITS OWN UNEDITED OUTPUT. A scene
## is the truth once it exists: the owner opens it in the editor and moves things, and a layout file that rebuilt it
## would silently throw that work away. So `--force` is allowed only for a scene this tool built (it has a row here)
## whose bytes are still the ones it wrote (the recorded sha256 equals the file's). Anything else is refused with
## the reason, and the owner's edits are safe.
##
## The manifest is JSON at tools/layouts/built_rooms.json (tests point it at a throwaway file). One row per scene
## path: { "room_id", "layout_sha256" (the layout it was built from), "scene_sha256" (the bytes that were written) }.

const DEFAULT_PATH := "res://tools/layouts/built_rooms.json"
const FORMAT_VERSION := 1
const ABOUT := "Written by tools/build_room.gd. A row says: this scene was built from that layout and has not been edited since (its sha256 still equals scene_sha256). --force may rebuild only such a scene. Do not edit a hash by hand."


## Reads the manifest. Returns { "scenes": Dictionary (scene path -> row), "error": String }. A missing file is an
## empty manifest, not an error.
static func read_manifest(path: String = DEFAULT_PATH) -> Dictionary:
	var answer := {"scenes": {}, "error": ""}
	if not FileAccess.file_exists(path):
		return answer
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("scenes") or not ((parsed as Dictionary)["scenes"] is Dictionary):
		answer["error"] = "%s is not a manifest (expected a JSON object with \"scenes\")" % path
		return answer
	answer["scenes"] = (parsed as Dictionary)["scenes"]
	return answer


static func write_manifest(scenes: Dictionary, path: String = DEFAULT_PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"format": FORMAT_VERSION, "about": ABOUT, "scenes": scenes}, "\t", true) + "\n")
	file.close()
	return OK


static func sha256_of_file(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""


static func sha256_of_text(text: String) -> String:
	return text.sha256_text()


## "" when the builder may write `scene_path`, else the reason it may not. `scenes` is read_manifest()["scenes"].
static func refusal_for(scene_path: String, scenes: Dictionary, force: bool) -> String:
	if not FileAccess.file_exists(scene_path):
		return ""
	if not force:
		return "%s already exists. A scene is the truth once it exists (the owner may have edited it), so the builder does not overwrite it. To rebuild a scene this tool built and nobody edited, pass --force." % scene_path
	if not scenes.has(scene_path):
		return "%s exists and the manifest has no row for it, so this tool did not build it: --force only rebuilds a scene the tool built itself. Edit the scene in the editor, or delete it by hand first." % scene_path
	var recorded_hash := String((scenes[scene_path] as Dictionary).get("scene_sha256", ""))
	if recorded_hash != sha256_of_file(scene_path):
		return "%s was edited after the tool built it (its sha256 no longer matches the manifest), so a rebuild would throw the edits away. The scene is the truth now; change it in the editor." % scene_path
	return ""


## The row to record after a successful build.
static func row_for(room_id: String, layout_text: String, scene_path: String) -> Dictionary:
	return {"room_id": room_id, "layout_sha256": sha256_of_text(layout_text), "scene_sha256": sha256_of_file(scene_path)}
