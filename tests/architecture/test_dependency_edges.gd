extends UnboundTest

## Architecture guard (REPORT-ONLY in M1a): derives the real class_name dependency
## graph from the code and prints every edge that crosses a layer of
## docs/game-base-plan.md 13.1, marking the ones the starting-point table does not
## allow. M1a only measures; the allowed edges are then frozen as
## tests/architecture/allowed_edges.txt and this test starts enforcing (set ENFORCING).
##
## An edge is "file A names class B": A's code (comments and string literals removed)
## contains the identifier of a class_name or autoload defined in file B, or
## preload()/load()s B's .gd by path. Layers come from the folder: the target layout
## (schema/, ecs/core|components|systems|events, authoring/, presentation/, shell/) once
## M1b has moved the code, and TODAY'S layout (scripts/...) mapped by LEGACY_LAYER_RULES
## following the 13.6 migration table. Tests and tools are not sources.

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

## false = print REPORT lines and pass. true = fail on any edge the table does not allow.
const ENFORCING := false
## Fewer source files than this means the walk is broken (a stale path), not a clean graph.
const MINIMUM_SOURCE_FILES := 20
const MINIMUM_SYMBOLS := 10

const TARGET_LAYER_FOLDERS: Array[String] = ["schema", "authoring", "presentation", "shell", "content"]
const TARGET_ECS_SUBLAYERS: Array[String] = ["core", "components", "systems", "events", "schedule"]
## [res:// path prefix or exact file, layer], first match wins. Today's folders -> 13.6 targets.
const LEGACY_LAYER_RULES: Array = [
	["res://scripts/data/", "schema"],
	["res://scripts/combat/", "schema"],
	["res://scripts/ai/", "schema"],
	["res://scripts/ecs/systems/", "ecs/systems"],
	["res://authoring/entity_components/", "authoring"],
	["res://ecs/components/ecs_components.gd", "ecs/components"],
	["res://ecs/core/ecs_world.gd", "ecs/core"],
	["res://ecs/core/ecs_grid.gd", "ecs/core"],
	["res://ecs/core/ecs_system.gd", "ecs/core"],
	["res://authoring/ecs_boot.gd", "authoring"],
	["res://authoring/ecs_actor_factory.gd", "authoring"],
	["res://presentation/views/actor_view.gd", "presentation"],
	["res://scripts/ui/", "presentation"],
	["res://scripts/visuals/", "presentation"],
	["res://scripts/audio/", "presentation"],
	["res://scripts/world/camera_rig.gd", "presentation"],
	["res://scripts/world/prototype_board.gd", "presentation"],
	["res://scripts/world/grid_lines_overlay.gd", "presentation"],
	["res://scripts/world/weapon_pickup.gd", "presentation"],
	["res://scripts/world/world_state.gd", "shell"],
	["res://scripts/main.gd", "shell"],
	["res://scripts/world/", "authoring"],
]
## source layer -> target layers it may depend on, besides itself (13.1 starting point).
## Every "ecs/*" sublayer may use every other ecs sublayer; the shell may use everything.
const ALLOWED_TARGET_LAYERS := {
	"schema": [],
	"ecs/core": ["ecs/components", "ecs/systems", "ecs/events", "ecs/schedule", "schema"],
	"ecs/components": ["ecs/core", "ecs/systems", "ecs/events", "ecs/schedule", "schema"],
	"ecs/systems": ["ecs/core", "ecs/components", "ecs/events", "ecs/schedule", "schema"],
	"ecs/events": ["ecs/core", "ecs/components", "ecs/systems", "ecs/schedule", "schema"],
	"ecs/schedule": ["ecs/core", "ecs/components", "ecs/systems", "ecs/events", "schema"],
	"authoring": ["ecs/core", "ecs/components", "schema"],
	"presentation": ["ecs/events", "schema"],
}
## Edges 13.1 documents as exceptions: "<source file basename> -> <target class>".
const DOCUMENTED_EXCEPTIONS: Array[String] = ["view_sync_system.gd -> ActorView"]
const SHELL_LAYER := "shell"

var symbol_file_by_name: Dictionary = {}
var layer_by_file: Dictionary = {}
## "from layer -> to layer" -> Array of "file -> Class" edge descriptions.
var edge_lines_by_layer_pair: Dictionary = {}
var violation_lines: Array[String] = []
var documented_exception_lines: Array[String] = []

var class_name_regex := RegEx.new()
var identifier_regex := RegEx.new()
var triple_quoted_regex := RegEx.new()
var string_literal_regex := RegEx.new()
var comment_regex := RegEx.new()
var load_path_regex := RegEx.new()


func _init() -> void:
	suite_title = "ARCHITECTURE DEPENDENCY EDGES TEST"
	class_name_regex.compile("(?m)^class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	identifier_regex.compile("[A-Za-z_][A-Za-z0-9_]*")
	triple_quoted_regex.compile("\"\"\"[\\s\\S]*?\"\"\"")
	string_literal_regex.compile("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'")
	comment_regex.compile("#[^\\n]*")
	load_path_regex.compile("(?:preload|load)\\(\\s*\"(res://[^\"]+\\.gd)\"")

	var source_paths: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"]):
		if not (script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/")):
			source_paths.append(script_path)
	var code_by_path: Dictionary = {}
	var load_paths_by_path: Dictionary = {}
	for script_path in source_paths:
		var script_text := ProjectFiles.read_text(script_path)
		if script_text.is_empty():
			_expect(false, "cannot read %s" % script_path)
			finish()
			return
		for class_match in class_name_regex.search_all(script_text):
			symbol_file_by_name[class_match.get_string(1)] = script_path
		layer_by_file[script_path] = _layer_of(script_path)
		var without_docstrings := triple_quoted_regex.sub(script_text, "", true)
		var load_paths: Array[String] = []
		for load_match in load_path_regex.search_all(without_docstrings):
			load_paths.append(load_match.get_string(1))
		load_paths_by_path[script_path] = load_paths
		var without_strings := string_literal_regex.sub(without_docstrings, "\"\"", true)
		code_by_path[script_path] = comment_regex.sub(without_strings, "", true)
	_add_autoload_symbols()

	_expect(
		source_paths.size() >= MINIMUM_SOURCE_FILES and symbol_file_by_name.size() >= MINIMUM_SYMBOLS,
		"the walk found %d source files and %d class_name/autoload symbols (at least %d and %d)" % [source_paths.size(), symbol_file_by_name.size(), MINIMUM_SOURCE_FILES, MINIMUM_SYMBOLS])

	var unmapped_files: Array[String] = []
	for script_path in source_paths:
		if layer_by_file[script_path] == "unmapped":
			unmapped_files.append(script_path)
		_collect_edges(script_path, String(code_by_path[script_path]), load_paths_by_path[script_path])

	_print_report(source_paths.size(), unmapped_files)
	if ENFORCING:
		_expect(violation_lines.is_empty(), "every cross-layer edge is allowed by the 13.1 table (%d are not)" % violation_lines.size())
	finish()


## project.godot [autoload] entries: the autoload name is a symbol too (WorldState, SfxManager).
func _add_autoload_symbols() -> void:
	var in_autoload_section := false
	for line in ProjectFiles.read_text("res://project.godot").split("\n"):
		if line.begins_with("["):
			in_autoload_section = line.strip_edges() == "[autoload]"
			continue
		if not in_autoload_section or not line.contains("="):
			continue
		var autoload_name := line.get_slice("=", 0).strip_edges()
		var autoload_path := line.get_slice("=", 1).strip_edges().trim_prefix("\"").trim_suffix("\"").trim_prefix("*")
		if autoload_path.ends_with(".tscn"):
			autoload_path = _first_script_of_scene(autoload_path)
		if autoload_path.ends_with(".gd") and layer_by_file.has(autoload_path):
			symbol_file_by_name[autoload_name] = autoload_path


func _first_script_of_scene(scene_path: String) -> String:
	for line in ProjectFiles.read_text(scene_path).split("\n"):
		if line.begins_with("[ext_resource") and line.contains("type=\"Script\""):
			var path_start := line.find("path=\"")
			if path_start != -1:
				return line.substr(path_start + 6).get_slice("\"", 0)
	return ""


func _layer_of(script_path: String) -> String:
	var relative_path := script_path.trim_prefix("res://")
	var first_segment := relative_path.get_slice("/", 0)
	if first_segment in TARGET_LAYER_FOLDERS:
		return first_segment
	if first_segment == "ecs":
		var sublayer := relative_path.get_slice("/", 1)
		return "ecs/" + sublayer if sublayer in TARGET_ECS_SUBLAYERS else "ecs/core"
	for rule: Array in LEGACY_LAYER_RULES:
		var rule_path := String(rule[0])
		if script_path == rule_path or (rule_path.ends_with("/") and script_path.begins_with(rule_path)):
			return String(rule[1])
	return "unmapped"


func _collect_edges(script_path: String, code: String, load_paths: Array) -> void:
	var own_layer: String = layer_by_file[script_path]
	var seen_targets: Dictionary = {}
	for identifier_match in identifier_regex.search_all(code):
		var symbol := identifier_match.get_string()
		if not symbol_file_by_name.has(symbol):
			continue
		var target_path: String = symbol_file_by_name[symbol]
		if target_path != script_path:
			seen_targets["%s|%s" % [symbol, target_path]] = true
	for load_path: String in load_paths:
		if layer_by_file.has(load_path) and load_path != script_path:
			seen_targets["%s|%s" % [load_path.get_file(), load_path]] = true
	for target_key: String in seen_targets:
		var symbol := target_key.get_slice("|", 0)
		var target_path := target_key.get_slice("|", 1)
		var target_layer: String = layer_by_file[target_path]
		if target_layer == own_layer:
			continue
		var pair_key := "%s -> %s" % [own_layer, target_layer]
		var edge_line := "%s -> %s (%s)" % [script_path.get_file(), symbol, target_path.get_file()]
		if not edge_lines_by_layer_pair.has(pair_key):
			edge_lines_by_layer_pair[pair_key] = []
		edge_lines_by_layer_pair[pair_key].append(edge_line)
		if not _is_allowed(own_layer, target_layer):
			var exception_key := "%s -> %s" % [script_path.get_file(), symbol]
			if exception_key in DOCUMENTED_EXCEPTIONS:
				documented_exception_lines.append("%s  %s  [documented exception]" % [pair_key, edge_line])
			else:
				violation_lines.append("%s  %s" % [pair_key, edge_line])


func _is_allowed(from_layer: String, to_layer: String) -> bool:
	if from_layer == SHELL_LAYER or from_layer == "unmapped" or to_layer == "unmapped":
		return true
	return to_layer in ALLOWED_TARGET_LAYERS.get(from_layer, [])


func _print_report(source_file_count: int, unmapped_files: Array[String]) -> void:
	print("REPORT dependency graph: %d source files, %d class_name/autoload symbols, layers from today's folders (13.6) or the target folders" % [source_file_count, symbol_file_by_name.size()])
	for unmapped_file in unmapped_files:
		print("REPORT   UNMAPPED file (add it to LEGACY_LAYER_RULES): %s" % unmapped_file)
	var layer_pairs: Array = edge_lines_by_layer_pair.keys()
	layer_pairs.sort()
	print("REPORT layer-to-layer edges (unique file -> class pairs), %d layer pair(s) cross a layer:" % layer_pairs.size())
	for layer_pair: String in layer_pairs:
		var edge_lines: Array = edge_lines_by_layer_pair[layer_pair]
		var from_layer := layer_pair.get_slice(" -> ", 0)
		var to_layer := layer_pair.get_slice(" -> ", 1)
		print("REPORT   %-34s %3d edge(s)  %s" % [layer_pair, edge_lines.size(), "allowed by 13.1" if _is_allowed(from_layer, to_layer) else "NOT ALLOWED by 13.1 (see below)"])
	print("REPORT edges the 13.1 starting-point table does NOT allow: %d (+%d documented exception(s))" % [violation_lines.size(), documented_exception_lines.size()])
	violation_lines.sort()
	for violation_line in violation_lines:
		print("REPORT   NOT ALLOWED  %s" % violation_line)
	for exception_line in documented_exception_lines:
		print("REPORT   EXCEPTION    %s" % exception_line)
	print("REPORT next: freeze the edges you accept as tests/architecture/allowed_edges.txt (one 'from -> to  # why' line each), then set ENFORCING. Mode: %s" % ("ENFORCING" if ENFORCING else "report-only"))
