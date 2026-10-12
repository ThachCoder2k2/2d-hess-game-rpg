extends UnboundTest

## Architecture guard (ENFORCING since M1b moved the content): the `content` row of
## the dependency table in docs/game-base-plan.md 13.1. A scene or resource under
## content/ may name only content/, schema/ (its Resource classes), authoring/
## (markers, entity components, the room root), presentation/views/ (base actor and
## pickup scenes) and assets/ (shared raw art and audio). It must not reach into
## ecs/, shell/ or the rest of presentation/, or into tests/.
##
## Two lists carry every reference the table does not cover, each with its reason:
##   DOCUMENTED_EXCEPTIONS  decided, kept until the milestone named in the reason.
##   UNDECIDED_REFERENCES   the owner has not decided yet; report-only, printed on
##                          every run so they cannot be forgotten.
## Both lists are exact: an entry nothing uses any more fails the suite, so a fixed
## reference is deleted from the list instead of rotting there. No agent adds an
## entry ad hoc (plan 13.1: "every exception is a line with a comment").
##
## The scan reads `[ext_resource ... path="res://..."]` lines of every .tscn and
## .tres under content/, the same lines tools/stamp_uids.gd and
## test_no_path_only_ext_resource.gd read.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const CONTENT_DIRECTORY := "res://content"
## A content file may name files under these prefixes (13.1: schema, authoring,
## presentation/views base scenes; plus itself and the shared raw assets).
const ALLOWED_TARGET_PREFIXES: Array[String] = [
	"res://content/",
	"res://schema/",
	"res://authoring/",
	"res://presentation/views/",
	"res://assets/",
]
## "<content file> -> <target>" pairs the table does not allow but the plan keeps on purpose.
const DOCUMENTED_EXCEPTIONS: Array[String] = [
	# The H1 exit to the kingdom must keep resolving, so the graph still names the 72x40
	# fixture. M5 ports the world-graph assertions and drops the kingdom from the graph.
	"res://content/world/world.tres -> res://tests/fixtures/the_kingdom.tscn",
]
## "<content file> -> <target>" pairs nobody has decided. Report-only.
const UNDECIDED_REFERENCES: Array[String] = [
	# Every Stage 1 room carries a GridLinesOverlay node whose script lives in
	# presentation/board/ (a decorative _draw() overlay), not in presentation/views/.
	# Open question for the owner: allow presentation/board/ for room overlays, or let the
	# game root add the overlay so rooms stop naming it (M3b).
	"res://content/rooms/t1_white_kings_fall/room.tscn -> res://presentation/board/grid_lines_overlay.gd",
	"res://content/rooms/t2_fallen_sword_tile/room.tscn -> res://presentation/board/grid_lines_overlay.gd",
	"res://content/rooms/t3_first_pawn_clash/room.tscn -> res://presentation/board/grid_lines_overlay.gd",
	"res://content/rooms/t4_broken_rule_yard/room.tscn -> res://presentation/board/grid_lines_overlay.gd",
	"res://content/rooms/b1_black_pawn_captain/room.tscn -> res://presentation/board/grid_lines_overlay.gd",
	"res://content/rooms/h1_chess_rug_hub/room.tscn -> res://presentation/board/grid_lines_overlay.gd",
]
## Fewer files than this means the walk is broken, not that content/ is clean.
const MINIMUM_FILES_SCANNED := 40
const MINIMUM_REFERENCES_SCANNED := 80

var reference_path_regex := RegEx.new()


func _init() -> void:
	suite_title = "ARCHITECTURE CONTENT REFERENCES TEST"
	reference_path_regex.compile("^\\[ext_resource [^\\]]*path=\"(res://[^\"]+)\"")

	var scanned_file_count := 0
	var scanned_reference_count := 0
	var violation_lines: Array[String] = []
	var used_exceptions: Dictionary = {}
	var used_undecided: Dictionary = {}
	for content_path in ProjectFiles.collect_files(["tscn", "tres"], CONTENT_DIRECTORY):
		var file_text := ProjectFiles.read_text(content_path)
		if file_text.is_empty():
			_expect(false, "cannot read %s" % content_path)
			finish()
			return
		scanned_file_count += 1
		for line in file_text.split("\n"):
			var reference_match := reference_path_regex.search(line)
			if reference_match == null:
				continue
			scanned_reference_count += 1
			var target_path := reference_match.get_string(1)
			if _is_allowed_target(target_path):
				continue
			var pair := "%s -> %s" % [content_path, target_path]
			if pair in DOCUMENTED_EXCEPTIONS:
				used_exceptions[pair] = true
			elif pair in UNDECIDED_REFERENCES:
				used_undecided[pair] = true
			else:
				violation_lines.append(pair)

	_expect(scanned_file_count >= MINIMUM_FILES_SCANNED and scanned_reference_count >= MINIMUM_REFERENCES_SCANNED,
		"the scan read %d content scene/resource files and %d ext_resource lines (at least %d and %d)" % [scanned_file_count, scanned_reference_count, MINIMUM_FILES_SCANNED, MINIMUM_REFERENCES_SCANNED])

	violation_lines.sort()
	for violation_line in violation_lines:
		print("REPORT   NOT ALLOWED  %s" % violation_line)
	for pair: String in used_exceptions:
		print("REPORT   EXCEPTION    %s  [documented exception]" % pair)
	var undecided_pairs: Array = used_undecided.keys()
	undecided_pairs.sort()
	for pair: String in undecided_pairs:
		print("REPORT   UNDECIDED    %s  [report-only until the owner decides]" % pair)
	print("REPORT content references: %d not allowed, %d documented exception(s), %d undecided (report-only)" % [violation_lines.size(), used_exceptions.size(), used_undecided.size()])

	_expect(violation_lines.is_empty(), "content/ names only content, schema, authoring, presentation/views and assets (%d reference(s) break the 13.1 content row)" % violation_lines.size())
	var stale_exceptions: Array[String] = []
	for pair in DOCUMENTED_EXCEPTIONS:
		if not used_exceptions.has(pair):
			stale_exceptions.append(pair)
	for pair in UNDECIDED_REFERENCES:
		if not used_undecided.has(pair):
			stale_exceptions.append(pair)
	_expect(stale_exceptions.is_empty(), "every documented exception and undecided reference is still used (stale, delete the line: %s)" % "; ".join(stale_exceptions))
	finish()


func _is_allowed_target(target_path: String) -> bool:
	for allowed_prefix in ALLOWED_TARGET_PREFIXES:
		if target_path.begins_with(allowed_prefix):
			return true
	return false
