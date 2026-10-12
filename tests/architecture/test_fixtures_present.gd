extends UnboundTest

## Architecture guard (ledger requirement 116, plan decision D-02): the 72x40
## kingdom and the first_encounter demo room are TEST FIXTURES, not game content.
## They are the only coverage for gates, the aggro leash, large-board A*, floor
## pickups and the Knight and Armed spawns, so they must stay loadable under
## tests/fixtures/ with every part they need, and must never reappear under
## content/ (where the content registry and the room lints would pick them up).
##
## A fixture scene X.tscn keeps its own parts in a folder X/ beside it.

const CONTENT_DIRECTORY := "res://content"
const WORLD_GRAPH_PATH := "res://content/world/world.tres"
const KINGDOM_ZONE_ID := &"kingdom"
## Fixture parts that must exist beside the two scenes.
const FIXTURE_PART_PATHS: Array[String] = [
	"res://tests/fixtures/the_kingdom/tilemap.tscn",
	"res://tests/fixtures/the_kingdom/tileset.tres",
	"res://tests/fixtures/the_kingdom/tiles.svg",
	"res://tests/fixtures/first_encounter/objective.tres",
]
const FIXTURE_SCENE_NAMES: Array[String] = ["the_kingdom.tscn", "first_encounter.tscn"]


func _init() -> void:
	suite_title = "ARCHITECTURE FIXTURES PRESENT TEST"
	var paths := TestPaths.new(self)

	var kingdom_path := paths.kingdom_scene()
	var first_encounter_path := paths.first_encounter_scene()
	for fixture_path in [kingdom_path, first_encounter_path]:
		var scene := paths.load_scene(fixture_path)
		_expect(scene != null and scene.can_instantiate(), "%s loads and can be instantiated" % fixture_path)
	for part_path in FIXTURE_PART_PATHS:
		_expect(ResourceLoader.exists(part_path), "fixture part exists: %s" % part_path)

	var strays: Array[String] = []
	for scene_name in FIXTURE_SCENE_NAMES:
		for stray_path in _find_named_files(CONTENT_DIRECTORY, scene_name):
			strays.append(stray_path)
	_expect(strays.is_empty(), "no fixture scene is filed under content/ (found: %s)" % ", ".join(strays))

	# The H1 exit that targets the kingdom keeps resolving: the graph still names the
	# fixture scene until M5 ports the world-graph assertions (plan 7.1).
	var world_graph := paths.load_resource(WORLD_GRAPH_PATH) as WorldGraph
	_expect(world_graph != null and world_graph.has_zone(KINGDOM_ZONE_ID), "the world graph still lists the kingdom zone, so the H1 exit to it resolves")
	if world_graph != null and world_graph.has_zone(KINGDOM_ZONE_ID):
		var graph_scene := world_graph.get_zone_scene(KINGDOM_ZONE_ID)
		_expect(graph_scene != null and graph_scene.resource_path == kingdom_path, "the kingdom zone in the world graph is the fixture scene (%s)" % kingdom_path)
	finish()


## Every file called `file_name` anywhere under `directory_path` (res:// paths).
func _find_named_files(directory_path: String, file_name: String) -> Array[String]:
	var found: Array[String] = []
	var access := DirAccess.open(directory_path)
	if access == null:
		return found
	if access.file_exists(file_name):
		found.append(directory_path.path_join(file_name))
	for sub_directory in access.get_directories():
		found.append_array(_find_named_files(directory_path.path_join(sub_directory), file_name))
	return found
