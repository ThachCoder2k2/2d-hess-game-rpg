extends UnboundTest

## The art-swap contract (docs/game-base-plan.md section 12, D15): content/_placeholders.json
## records the sha256 of every file that stands in for art or audio the owner will supply, and a
## file is a placeholder if and only if its hash still equals the recorded one.
##
## This suite proves, without ever failing because the owner did the right thing:
##  1. the manifest parses, is well formed, and lists at least a minimum number of files (a
##     broken path or an empty list cannot pass);
##  2. every listed file exists (a rename that forgot the manifest fails here, and the owner
##     overwriting a file does NOT: a changed hash is "replaced", never a failure);
##  3. overwriting a listed file clears its flag by itself, and deleting it shows as missing
##     (checked on a probe file under user://, never on the working tree);
##  3b. the seed tool may replace an earlier stand-in with a better one, but never the owner's art:
##     PlaceholderManifest.seed_decision is checked for every case (also on a probe under user://);
##  4. every row of tools/seed_placeholders.gd is recorded, so a new stand-in cannot be added
##     to the seed lists and forgotten in the manifest;
##  5. tools/list_placeholders.gd runs and prints the TODO;
##  6. no tracked scene or resource names assets/_generated/ (gitignored generator output): a
##     stand-in picture reaches the game only as a tracked copy in content/, so a fresh clone
##     has it and the owner can overwrite it.

const PlaceholderManifest := preload("res://tools/placeholder_manifest.gd")
const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## content/_placeholders.json lists 25 files at M1b. Fewer means entries were lost.
const MINIMUM_PLACEHOLDERS := 20
const SEED_SCRIPT_PATH := "res://tools/seed_placeholders.gd"
const LIST_SCRIPT_PATH := "res://tools/list_placeholders.gd"
const PROBE_PATH := "user://placeholder_probe.bin"
const GENERATED_PREFIX := "res://assets/_generated/"
## A walk that finds fewer scenes and resources than this is broken, not clean.
const MINIMUM_SCENES_AND_RESOURCES := 60


func _init() -> void:
	suite_title = "TEST PLACEHOLDERS MANIFEST"
	var paths := TestPaths.new(self)
	paths.read_json(PlaceholderManifest.MANIFEST_PATH)  # fails the suite on a missing, blank or unparsable file

	var manifest := PlaceholderManifest.read_manifest()
	var read_error := String(manifest["error"])
	if not _expect(read_error.is_empty(), "the manifest is well formed (%s)" % ("ok" if read_error.is_empty() else read_error)):
		finish()
		return
	var entries: Array[Dictionary] = manifest["entries"]
	_expect(entries.size() >= MINIMUM_PLACEHOLDERS, "the manifest lists %d placeholders (at least %d, so an empty list cannot pass)" % [entries.size(), MINIMUM_PLACEHOLDERS])

	_check_listed_files_exist(entries)
	_check_overwriting_clears_the_flag()
	_check_seed_decisions()
	_check_seed_rows_are_recorded(entries)
	_check_list_tool_prints_the_todo(paths, entries)
	_check_no_scene_names_generated_art()
	finish()


func _check_listed_files_exist(entries: Array[Dictionary]) -> void:
	var missing_paths: Array[String] = []
	var unknown_kinds: Array[String] = []
	for entry in entries:
		if PlaceholderManifest.status_of(entry) == PlaceholderManifest.STATUS_MISSING:
			missing_paths.append(String(entry["path"]))
		if not PlaceholderManifest.KIND_ORDER.has(String(entry["kind"])):
			unknown_kinds.append("%s (%s)" % [entry["path"], entry["kind"]])
	_expect(missing_paths.is_empty(), "every listed placeholder file exists (missing: %s)" % ", ".join(missing_paths))
	_expect(unknown_kinds.is_empty(), "every entry has a kind the TODO knows how to order (unknown: %s)" % ", ".join(unknown_kinds))
	var listed_roots_ok := true
	for entry in entries:
		var path := String(entry["path"])
		if not (path.begins_with("res://content/") or path.begins_with("res://assets/")):
			listed_roots_ok = false
	_expect(listed_roots_ok, "placeholders live under content/ or assets/, never under a generated or ignored folder")


## Overwriting a file must clear its flag with no other edit; deleting it must show as missing.
func _check_overwriting_clears_the_flag() -> void:
	var probe_original := PackedByteArray([1, 2, 3, 4, 5, 6, 7, 8])
	_write_probe(probe_original)
	var probe_entry := {
		"path": PROBE_PATH,
		"kind": "body",
		"id": "probe",
		"sha256": FileAccess.get_sha256(PROBE_PATH),
		"origin": "test",
	}
	var res_path_entry := probe_entry.duplicate()
	res_path_entry["path"] = PlaceholderManifest.MANIFEST_PATH
	_expect(PlaceholderManifest.entry_problem(res_path_entry).is_empty(), "an entry with a res:// path, a kind, an id, a real hash and an origin is well formed")
	_expect(not PlaceholderManifest.entry_problem(probe_entry).is_empty(), "an entry whose path is not a res:// path is rejected (the probe lives under user://)")
	_expect(PlaceholderManifest.status_of(probe_entry) == PlaceholderManifest.STATUS_PLACEHOLDER, "an untouched stand-in is a placeholder (its hash equals the recorded one)")
	var probe_entries: Array[Dictionary] = [probe_entry]
	var todo_before := "\n".join(PlaceholderManifest.todo_lines(probe_entries))
	_expect(todo_before.contains("1 still to replace") and todo_before.contains("placeholder_probe.bin"), "the TODO lists the untouched stand-in")

	_write_probe(PackedByteArray([9, 9, 9]))
	_expect(PlaceholderManifest.status_of(probe_entry) == PlaceholderManifest.STATUS_REPLACED, "overwriting the file clears the flag with no other edit")
	var todo_after := "\n".join(PlaceholderManifest.todo_lines(probe_entries))
	_expect(todo_after.contains("0 still to replace") and todo_after.contains("1 replaced by you") and not todo_after.contains("placeholder_probe.bin"), "the TODO drops a file the owner replaced")

	# Putting the very same bytes back is a placeholder again: the hash is the whole definition.
	_write_probe(probe_original)
	_expect(PlaceholderManifest.status_of(probe_entry) == PlaceholderManifest.STATUS_PLACEHOLDER, "the same bytes again make it a placeholder again")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROBE_PATH))
	_expect(PlaceholderManifest.status_of(probe_entry) == PlaceholderManifest.STATUS_MISSING, "a deleted file shows as missing, not as replaced")

	var bad_hash_entry := res_path_entry.duplicate()
	bad_hash_entry["sha256"] = "not-a-hash"
	_expect(not PlaceholderManifest.entry_problem(bad_hash_entry).is_empty(), "an entry whose sha256 is not 64 lowercase hex characters is rejected")
	var no_origin_entry := res_path_entry.duplicate()
	no_origin_entry.erase("origin")
	_expect(not PlaceholderManifest.entry_problem(no_origin_entry).is_empty(), "an entry with a missing field is rejected")


## What tools/seed_placeholders.gd may do to a file, case by case. The cases that matter most are
## the two "nothing": a file the owner replaced, and a file the row already seeded.
func _check_seed_decisions() -> void:
	var plain_row := {"source": "res://assets/_generated/chess/pawn_idle.png", "target": PROBE_PATH, "kind": "body", "id": "probe"}
	var superseding_row := plain_row.duplicate()
	superseding_row["supersedes_stand_in"] = true
	_write_probe(PackedByteArray([1, 2, 3]))
	var earlier_stand_in := {
		"path": PROBE_PATH, "kind": "body", "id": "probe",
		"sha256": FileAccess.get_sha256(PROBE_PATH), "origin": "tracked sprite adopted at M1b",
	}
	_expect(PlaceholderManifest.seed_decision(plain_row, false, {}) == PlaceholderManifest.SEED_COPY, "seeding: a missing file is copied")
	_expect(PlaceholderManifest.seed_decision(plain_row, true, {}) == PlaceholderManifest.SEED_OWNERS_FILE, "seeding: a file the manifest does not list is the owner's and is left alone")
	_expect(PlaceholderManifest.seed_decision(superseding_row, true, {}) == PlaceholderManifest.SEED_OWNERS_FILE, "seeding: even a superseding row leaves an unlisted file alone")
	_expect(PlaceholderManifest.seed_decision(plain_row, true, earlier_stand_in) == PlaceholderManifest.SEED_NOTHING, "seeding: a row that does not say it supersedes never overwrites a listed file")
	_expect(PlaceholderManifest.seed_decision(superseding_row, true, earlier_stand_in) == PlaceholderManifest.SEED_REPLACE_STAND_IN, "seeding: a superseding row replaces a listed stand-in that is still unchanged")
	var already_seeded := earlier_stand_in.duplicate()
	already_seeded["origin"] = PlaceholderManifest.seed_origin(superseding_row)
	_expect(PlaceholderManifest.seed_decision(superseding_row, true, already_seeded) == PlaceholderManifest.SEED_NOTHING, "seeding: a stand-in this row already seeded is not replaced again")
	var revised_row := superseding_row.duplicate()
	revised_row["revision"] = "on the 32 x 32 cell canvas"
	_expect(PlaceholderManifest.seed_origin(revised_row) != PlaceholderManifest.seed_origin(superseding_row), "seeding: a revision changes the recorded origin")
	_expect(PlaceholderManifest.seed_decision(revised_row, true, already_seeded) == PlaceholderManifest.SEED_REPLACE_STAND_IN, "seeding: a stand-in the row seeded before its revision is replaced by the revised drawing")
	var revised_seeded := earlier_stand_in.duplicate()
	revised_seeded["origin"] = PlaceholderManifest.seed_origin(revised_row)
	_expect(PlaceholderManifest.seed_decision(revised_row, true, revised_seeded) == PlaceholderManifest.SEED_NOTHING, "seeding: ...and not replaced again once the revised drawing is in")
	_write_probe(PackedByteArray([7, 7, 7, 7]))
	_expect(PlaceholderManifest.seed_decision(revised_row, true, earlier_stand_in) == PlaceholderManifest.SEED_NOTHING, "seeding: a revised row never replaces a file the owner overwrote")
	_expect(PlaceholderManifest.status_of(earlier_stand_in) == PlaceholderManifest.STATUS_REPLACED, "seeding: the probe now differs from its recorded hash, as if the owner overwrote it")
	_expect(PlaceholderManifest.seed_decision(superseding_row, true, earlier_stand_in) == PlaceholderManifest.SEED_NOTHING, "seeding: a file the owner overwrote is never replaced, even by a superseding row")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROBE_PATH))


func _check_seed_rows_are_recorded(entries: Array[Dictionary]) -> void:
	var recorded_paths := {}
	for entry in entries:
		recorded_paths[entry["path"]] = true
	# The seed script is a SceneTree script that runs in _init, so it is read, never instantiated.
	var seed_script := load(SEED_SCRIPT_PATH) as GDScript
	if not _expect(seed_script != null, "tools/seed_placeholders.gd loads"):
		return
	var seed_constants := seed_script.get_script_constant_map()
	var seed_rows: Array[String] = []
	for generated_row: Dictionary in seed_constants.get("GENERATED_SEEDS", []):
		seed_rows.append(String(generated_row["target"]))
	for adopted_row: Dictionary in seed_constants.get("ADOPTED_PLACEHOLDERS", []):
		seed_rows.append(String(adopted_row["path"]))
	_expect(seed_rows.size() >= MINIMUM_PLACEHOLDERS, "the seed script lists %d rows (at least %d)" % [seed_rows.size(), MINIMUM_PLACEHOLDERS])
	var unrecorded_rows: Array[String] = []
	for row_path in seed_rows:
		if not recorded_paths.has(row_path):
			unrecorded_rows.append(row_path)
	_expect(unrecorded_rows.is_empty(), "every row of tools/seed_placeholders.gd is recorded in the manifest (run the tool: %s)" % ", ".join(unrecorded_rows))


func _check_list_tool_prints_the_todo(paths: TestPaths, entries: Array[Dictionary]) -> void:
	_expect(FileAccess.file_exists(LIST_SCRIPT_PATH), "tools/list_placeholders.gd exists")
	var output: Array = []
	var arguments := PackedStringArray(["--headless", "--path", paths.project_directory_on_disk(), "-s", LIST_SCRIPT_PATH])
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var printed := "".join(PackedStringArray(output))
	_expect(exit_code == 0, "tools/list_placeholders.gd exits 0 (got %d)" % exit_code)
	_expect(printed.contains("PLACEHOLDERS: %d recorded" % entries.size()), "tools/list_placeholders.gd prints the summary line for %d recorded files" % entries.size())
	_expect(printed.contains("ROOMS: 34 rooms, ") and printed.contains(" STUB, ") and printed.contains(" GREYBOX, ") and printed.contains(" DRESSED, ") and printed.contains(" FINAL "), "tools/list_placeholders.gd also prints how many rooms are STUB, GREYBOX, DRESSED and FINAL")


func _check_no_scene_names_generated_art() -> void:
	var scene_and_resource_paths := ProjectFiles.collect_files(["tscn", "tres"])
	_expect(scene_and_resource_paths.size() >= MINIMUM_SCENES_AND_RESOURCES, "the scan read %d scenes and resources (at least %d)" % [scene_and_resource_paths.size(), MINIMUM_SCENES_AND_RESOURCES])
	var naming_paths: Array[String] = []
	for scene_path in scene_and_resource_paths:
		if ProjectFiles.read_text(scene_path).contains(GENERATED_PREFIX):
			naming_paths.append(scene_path)
	_expect(naming_paths.is_empty(), "no scene or resource names %s (seed the picture into content/ instead): %s" % [GENERATED_PREFIX, ", ".join(naming_paths)])


func _write_probe(bytes: PackedByteArray) -> void:
	var probe_file := FileAccess.open(PROBE_PATH, FileAccess.WRITE)
	if probe_file == null:
		require(false, "the probe file under user:// is writable (error %d)" % FileAccess.get_open_error())
		return
	probe_file.store_buffer(bytes)
	probe_file.close()
