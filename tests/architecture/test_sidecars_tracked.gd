extends SceneTree

## Architecture guard (REPORT-ONLY in M1a): every tracked .gd must have a tracked
## .gd.uid, and every tracked imported asset (png, wav, svg, ...) must have a
## tracked .import (docs/game-base-plan.md 13.3 "Sidecars"). A missing sidecar means
## a fresh clone invents a new uid for the file, and every scene that references the
## old uid silently falls back to the path, which a folder move then breaks.
##
## "Tracked" comes from `git ls-files`, not from the disk: a sidecar that exists
## locally but was never committed is exactly the bug this guard catches.
## Ignored generated art (assets/sprites/generated/{chess,tiles,maps,rooms}) is not
## tracked at all, so it is not expected to carry tracked sidecars.
## Flip ENFORCING to true when the tree is clean (M1b).

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const ENFORCING := false
## Extensions Godot imports and therefore writes "<file>.<ext>.import" for.
const IMPORTED_EXTENSIONS: Array[String] = ["png", "jpg", "jpeg", "webp", "svg", "wav", "ogg", "mp3", "ttf", "otf"]
## A repository with fewer tracked files than this is not the project (the git call is broken).
const MINIMUM_TRACKED_FILES := 100
const MAX_LISTED := 25


func _init() -> void:
	var tracked_result := ProjectFiles.git_tracked_files()
	if not String(tracked_result["error"]).is_empty():
		print("REPORT skipped: %s" % tracked_result["error"])
		print("ARCHITECTURE SIDECARS TRACKED TEST: PASS (skipped)")
		quit(0)
		return
	var tracked_files: Array[String] = []
	tracked_files.assign(tracked_result["files"])
	var tracked_set: Dictionary = {}
	for tracked_file in tracked_files:
		tracked_set[tracked_file] = true

	var failures := 0
	if tracked_files.size() < MINIMUM_TRACKED_FILES:
		printerr("FAIL: git lists only %d tracked files (expected at least %d)" % [tracked_files.size(), MINIMUM_TRACKED_FILES])
		failures += 1

	var tracked_gd_count := 0
	var tracked_imported_count := 0
	var gd_missing_uid: Array[String] = []
	var imported_missing_import: Array[String] = []
	var orphan_sidecars: Array[String] = []
	for tracked_file in tracked_files:
		var extension := tracked_file.get_extension()
		if extension == "gd":
			tracked_gd_count += 1
			if not tracked_set.has(tracked_file + ".uid"):
				gd_missing_uid.append(tracked_file)
		elif extension in IMPORTED_EXTENSIONS:
			tracked_imported_count += 1
			if not tracked_set.has(tracked_file + ".import"):
				imported_missing_import.append(tracked_file)
		elif extension == "uid" and not tracked_set.has(tracked_file.trim_suffix(".uid")):
			orphan_sidecars.append(tracked_file)
		elif extension == "import" and not tracked_set.has(tracked_file.trim_suffix(".import")):
			orphan_sidecars.append(tracked_file)

	print("REPORT tracked .gd files: %d, missing a tracked .gd.uid: %d" % [tracked_gd_count, gd_missing_uid.size()])
	_list("  .gd without .gd.uid", gd_missing_uid)
	print("REPORT tracked imported assets: %d, missing a tracked .import: %d" % [tracked_imported_count, imported_missing_import.size()])
	_list("  asset without .import", imported_missing_import)
	print("REPORT tracked sidecars whose source file is not tracked: %d" % orphan_sidecars.size())
	_list("  orphan sidecar", orphan_sidecars)
	print("REPORT fix: run the import pass (godot --headless --editor --quit) and commit the new sidecars. Mode: %s" % ("ENFORCING" if ENFORCING else "report-only"))

	if ENFORCING and (not gd_missing_uid.is_empty() or not imported_missing_import.is_empty()):
		printerr("FAIL: %d .gd and %d asset(s) lack a tracked sidecar" % [gd_missing_uid.size(), imported_missing_import.size()])
		failures += 1
	print("ARCHITECTURE SIDECARS TRACKED TEST: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)


func _list(label: String, entries: Array[String]) -> void:
	for index in range(mini(entries.size(), MAX_LISTED)):
		print("REPORT %s: %s" % [label, entries[index]])
	if entries.size() > MAX_LISTED:
		print("REPORT %s: ... and %d more" % [label, entries.size() - MAX_LISTED])
