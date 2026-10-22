class_name TestPaths
extends RefCounted

## The only place a new test names a `res://` path (docs/game-base-plan.md §13.7).
##
## Why: a stale path must make a suite FAIL, never pass by accident. Without this,
## `FileAccess.get_file_as_string()` on a moved file returns "" and a check such as
## "actor views hold no logic at all" (tests/run_tests.gd:103) still prints PASS,
## and the first `load()` of a moved scene raises a script error that hangs the
## process. Every accessor here asserts the file exists; every read helper also
## asserts the content is not empty; every directory listing asserts a minimum
## file count, so a lint over zero files cannot pass.
##
## Usage inside a suite that extends `UnboundTest`:
##
##     var paths := TestPaths.new(self)
##     var source := paths.read_text(paths.actor_view_script())
##     _expect(not source.contains("func _process"), "actor views hold no logic")
##
## The folder migration (M1b) edits the strings in this file and nowhere else.
## Add an accessor here when a new test needs a file that has none. Existence
## checks go through `UnboundTest.require`, so a passing lookup prints nothing and
## a failing one prints `FAIL: file exists: <path>` and fails the suite.

var _suite: UnboundTest


func _init(suite: UnboundTest) -> void:
	_suite = suite


# --- Documents and test data ---

func requirements_json() -> String:
	return _existing_file("res://docs/requirements.json")


func requirements_ledger() -> String:
	return _existing_file("res://docs/requirements_ledger.md")


func game_base_plan() -> String:
	return _existing_file("res://docs/game-base-plan.md")


func baseline_labels() -> String:
	return _existing_file("res://tests/baseline_labels.txt")


func label_renames() -> String:
	return _existing_file("res://tests/label_renames.txt")


# --- Project configuration ---

func project_settings() -> String:
	return _existing_file("res://project.godot")


func default_bus_layout() -> String:
	return _existing_resource("res://default_bus_layout.tres")


# --- Scripts that tests read as text or inspect ---

func main_script() -> String:
	return _existing_file("res://shell/game_root.gd")


## GameFlow (starts the room again after a death or the pause menu's Restart Room).
func game_flow_script() -> String:
	return _existing_file("res://shell/game_flow.gd")


## The bridge that decides how a room ends, a death included.
func room_outcome_bridge_script() -> String:
	return _existing_file("res://shell/bridges/room_outcome_bridge.gd")


## The game's own keys (restart, the debug layer, fullscreen, the Book).
func shell_keys_script() -> String:
	return _existing_file("res://shell/shell_keys.gd")


## The helper that builds the in-game scene's world node (and so calls Schedule.populate()).
func zone_stage_script() -> String:
	return _existing_file("res://shell/zone_stage.gd")


func save_service_script() -> String:
	return _existing_file("res://shell/save/save_service.gd")


func actor_view_script() -> String:
	return _existing_file("res://presentation/views/actor_view.gd")


## The deterministic dump's shared logic (it boots a world the way game_root.gd does).
func world_dumper_script() -> String:
	return _existing_file("res://tools/world_dumper.gd")


# --- Scenes ---

## The project's main scene: AppRoot, which owns the flow, the music and the screens (M4).
func main_scene() -> String:
	return _existing_resource("res://shell/app_root.tscn")


## The in-game scene (GameRoot): the room, the hero, the HUD. AppRoot adds it on New Game and Continue; a bridge
## suite boots it alone.
func game_scene() -> String:
	return _existing_resource("res://shell/game_root.tscn")


## The title screen.
func title_scene() -> String:
	return _existing_resource("res://shell/title/title_screen.tscn")


## The credits roll.
func credits_scene() -> String:
	return _existing_resource("res://shell/credits/credits_screen.tscn")


## The pause menu (AppRoot lays it in its menu layer).
func pause_menu_scene() -> String:
	return _existing_resource("res://shell/pause/pause_menu.tscn")


## The Book of House Rules screen (the game scene instances it).
func rule_book_scene() -> String:
	return _existing_resource("res://presentation/ui/codex/rule_book.tscn")


## The 72x40 kingdom: a test fixture, not game content (plan D-02).
func kingdom_scene() -> String:
	return _existing_resource("res://tests/fixtures/the_kingdom.tscn")


## The kingdom fixture's TileSet: a test fixture like the scene above, with the same custom-data layers
## (`solid`, `kind`) as the game's own kingdom TileSet in content/tilesets/kingdom/.
func kingdom_fixture_tileset() -> String:
	return _existing_resource("res://tests/fixtures/the_kingdom/tileset.tres")


## Every room the world graph lists plus the 72x40 kingdom fixture, as id -> scene (the kingdom's id is `kingdom`):
## what a suite walks when its claim must hold for every kind of board the engine boots, 16x9 rooms and the scrolling
## 72x40 one alike. The kingdom left the graph at M5 (plan D-02), so it is added here by its fixture path.
func shipped_rooms_and_kingdom() -> Dictionary[StringName, PackedScene]:
	var scenes: Dictionary[StringName, PackedScene] = {}
	var graph := ContentDb.world()
	if _suite.require(graph != null, "the world graph loads"):
		for room_id in graph.room_ids():
			scenes[room_id] = graph.get_zone_scene(room_id)
	var kingdom := load_scene(kingdom_scene())
	if kingdom != null:
		scenes[&"kingdom"] = kingdom
	return scenes


## The first-encounter demo room: a test fixture, not game content (plan D-02).
func first_encounter_scene() -> String:
	return _existing_resource("res://tests/fixtures/first_encounter.tscn")


## `room_id` is the room's folder name (its id), for example
## `t1_white_kings_fall` or `h1_chess_rug_hub`; the scene is `room.tscn` inside it.
func room_scene(room_id: StringName) -> String:
	return _existing_resource("res://content/rooms/%s/room.tscn" % room_id)


## `actor_id` is the actor scene's file name without extension, for example
## `player`, `black_pawn` or `knight_enemy`.
func actor_scene(actor_id: StringName) -> String:
	return _existing_resource("res://presentation/views/actors/%s.tscn" % actor_id)


## The one base every actor scene inherits (M2): the nodes, the clips and the animation graph.
func actor_view_base_scene() -> String:
	return _existing_resource("res://presentation/views/actors/actor_view_base.tscn")


## The SfxManager autoload's scene (its player pool is built in code).
func sfx_manager_scene() -> String:
	return _existing_resource("res://presentation/audio/sfx_manager.tscn")


## The HUD scene (GameHud: courage, skill slot, status line, result panel).
func hud_scene() -> String:
	return _existing_resource("res://presentation/ui/hud/hud.tscn")


# --- Directories (list them with `list_files`) ---

## The room folders (one per room id, each holding `room.tscn`): list the scenes
## with `list_files(rooms_directory(), "tscn", 6, true)`.
func rooms_directory() -> String:
	return _existing_directory("res://content/rooms")


## The whole project, for scans that must see every scene or script wherever the
## folder migration puts it (M1b moved scenes out of `scenes/` and `objects/`
## into the code folders): list from here with `recursive` true.
func project_directory() -> String:
	return _existing_directory("res://")


## The actor scenes: player, pawns, knight, bishop, and so on.
func actors_directory() -> String:
	return _existing_directory("res://presentation/views/actors")


## The folders whose code may emit events or queue damage: the simulation, the baker, the views and the shell.
func event_producer_directories() -> Array[String]:
	return [
		_existing_directory("res://ecs"),
		_existing_directory("res://authoring"),
		_existing_directory("res://presentation"),
		_existing_directory("res://shell"),
	]


## The one file that declares every event (and builds the damage and heal requests).
func events_script() -> String:
	return _existing_file("res://ecs/events/events.gd")


## The system scripts of the simulation, one sub-folder per area (input, decide, move, ...).
func ecs_systems_directory() -> String:
	return _existing_directory("res://ecs/systems")


## The schedule: one file per stage plus schedule.gd and schedule_phase.gd.
func ecs_schedule_directory() -> String:
	return _existing_directory("res://ecs/schedule")


## The enemy folders (one per enemy id, each holding `enemy.tres`; `_shared` is not an enemy).
func enemy_definitions_directory() -> String:
	return _existing_directory("res://content/enemies")


# --- Test fixtures (tests/fixtures is never discovered as a suite) ---

## A deliberately misbehaving suite used to test the harness itself, for example
## `pass_fixture` or `hang_fixture`. See tests/support/test_unbound_test.gd.
func harness_fixture(fixture_name: String) -> String:
	return _existing_file("res://tests/fixtures/harness/%s.gd" % fixture_name)


## The project folder as an operating-system path, for tests that start a second
## Godot process with `--path`.
func project_directory_on_disk() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/")


# --- Readers (pass them the output of an accessor above) ---

## The file's text. Fails the suite when the file is missing or blank, and
## returns "" in that case.
func read_text(path: String) -> String:
	if not _suite.require(FileAccess.file_exists(path), "file exists: %s" % path):
		return ""
	var text := FileAccess.get_file_as_string(path)
	_suite.require(not text.strip_edges().is_empty(), "file has content: %s" % path)
	return text


## The parsed JSON value (a Dictionary or an Array). Fails the suite on a missing
## or blank file or on a parse error, and returns null in those cases.
func read_json(path: String) -> Variant:
	var text := read_text(path)
	if text.is_empty():
		return null
	var parser := JSON.new()
	if not _suite.require(parser.parse(text) == OK, "JSON parses: %s (line %d: %s)" % [path, parser.get_error_line(), parser.get_error_message()]):
		return null
	return parser.data


## A scene resource. Fails the suite when the scene is missing or is not a
## PackedScene, and returns null in that case; it never calls `load()` on a path
## that does not exist, because that raises a script error.
func load_scene(path: String) -> PackedScene:
	if not _suite.require(ResourceLoader.exists(path), "scene exists: %s" % path):
		return null
	var scene := load(path) as PackedScene
	_suite.require(scene != null, "scene loads as a PackedScene: %s" % path)
	return scene


## Any resource, with the same missing-path protection as `load_scene`.
func load_resource(path: String) -> Resource:
	if not _suite.require(ResourceLoader.exists(path), "resource exists: %s" % path):
		return null
	var resource := load(path)
	_suite.require(resource != null, "resource loads: %s" % path)
	return resource


## Sorted `res://` paths of the files whose extension is `extension` (without the
## dot, for example "gd"), asserting that there are at least `minimum_count` of
## them. Hidden folders (names starting with a dot) are skipped.
func list_files(directory: String, extension: String, minimum_count: int = 1, recursive: bool = false) -> PackedStringArray:
	var found := PackedStringArray()
	if not _suite.require(DirAccess.dir_exists_absolute(directory), "directory exists: %s" % directory):
		return found
	_collect_files(directory, extension, recursive, found)
	found.sort()
	_suite.require(found.size() >= minimum_count, "at least %d .%s file(s) under %s (found %d)" % [minimum_count, extension, directory, found.size()])
	return found


func _existing_file(path: String) -> String:
	_suite.require(FileAccess.file_exists(path), "file exists: %s" % path)
	return path


func _existing_resource(path: String) -> String:
	_suite.require(ResourceLoader.exists(path), "resource exists: %s" % path)
	return path


func _existing_directory(path: String) -> String:
	_suite.require(DirAccess.dir_exists_absolute(path), "directory exists: %s" % path)
	return path


func _collect_files(directory: String, extension: String, recursive: bool, found: PackedStringArray) -> void:
	var access := DirAccess.open(directory)
	if access == null:
		return
	for file_name in access.get_files():
		if file_name.get_extension() == extension:
			found.append(directory.path_join(file_name))
	if not recursive:
		return
	for sub_directory in access.get_directories():
		if not sub_directory.begins_with("."):
			_collect_files(directory.path_join(sub_directory), extension, recursive, found)
