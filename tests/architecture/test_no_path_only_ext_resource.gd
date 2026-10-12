extends SceneTree

## Architecture guard (REPORT-ONLY until M1b stamps the tree): counts [ext_resource]
## lines that name a file by path only. A scene or resource that references a file
## by path alone breaks the moment that file moves; one that also carries its
## uid="..." keeps resolving (docs/game-base-plan.md 13.6, 13.7, risk 2).
##
## Today the count is high on purpose: M1b runs tools/stamp_uids.gd over the whole
## tree and flips ENFORCING to true, after which a single path-only line fails.
## tools/stamp_uids.gd --check is the same measurement from the command line.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## false = print REPORT lines and pass. true = fail while any path-only line remains.
const ENFORCING := false
## Fewer files than this means the walk is broken (a stale path), not that the tree is clean.
const MINIMUM_FILES_SCANNED := 20
const MAX_FILES_LISTED := 15


func _init() -> void:
	var resource_paths := ProjectFiles.collect_files(["tscn", "tres"])
	var path_only_count_by_file: Dictionary = {}
	var total_reference_count := 0
	var path_only_total := 0
	var headers_without_uid := 0
	for resource_path in resource_paths:
		var file_text := ProjectFiles.read_text(resource_path)
		if file_text.is_empty():
			printerr("FAIL: cannot read %s" % resource_path)
			quit(1)
			return
		var lines := file_text.split("\n")
		if not lines[0].contains(" uid=\"uid://"):
			headers_without_uid += 1
		for line in lines:
			if not line.begins_with("[ext_resource "):
				continue
			total_reference_count += 1
			if not line.contains(" uid=\"uid://"):
				path_only_total += 1
				path_only_count_by_file[resource_path] = int(path_only_count_by_file.get(resource_path, 0)) + 1

	var failures := 0
	if resource_paths.size() < MINIMUM_FILES_SCANNED:
		printerr("FAIL: only %d scene/resource files found (expected at least %d); the walk is broken" % [resource_paths.size(), MINIMUM_FILES_SCANNED])
		failures += 1
	else:
		print("PASS: the scan read %d scene/resource files (at least %d) and %d ext_resource lines" % [resource_paths.size(), MINIMUM_FILES_SCANNED, total_reference_count])

	print("REPORT path-only ext_resource lines: %d of %d in %d of %d scene/resource files" % [path_only_total, total_reference_count, path_only_count_by_file.size(), resource_paths.size()])
	print("REPORT scene/resource headers without uid: %d of %d" % [headers_without_uid, resource_paths.size()])
	var listed_paths: Array = path_only_count_by_file.keys()
	listed_paths.sort_custom(func(a: String, b: String) -> bool:
		return path_only_count_by_file[a] > path_only_count_by_file[b] or (path_only_count_by_file[a] == path_only_count_by_file[b] and a < b))
	for index in range(mini(listed_paths.size(), MAX_FILES_LISTED)):
		print("REPORT   %3d  %s" % [path_only_count_by_file[listed_paths[index]], listed_paths[index]])
	if listed_paths.size() > MAX_FILES_LISTED:
		print("REPORT   ... and %d more file(s)" % (listed_paths.size() - MAX_FILES_LISTED))
	print("REPORT fix: run tools/stamp_uids.gd (M1b stamps; M1a only ships the tool). Mode: %s" % ("ENFORCING" if ENFORCING else "report-only"))

	if ENFORCING:
		if path_only_total == 0:
			print("PASS: no ext_resource line names a file by path only")
		else:
			printerr("FAIL: %d path-only ext_resource line(s) remain" % path_only_total)
			failures += 1
	print("ARCHITECTURE NO PATH-ONLY EXT_RESOURCE TEST: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)
