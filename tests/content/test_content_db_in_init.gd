extends UnboundTest

## The registry works where autoloads do not exist (docs/game-base-plan.md risk 7).
##
## An autoload is added to the tree after a main-loop script's `_init()` has returned, so a
## suite that does its work inside `_init()` runs with no SfxManager and no SaveService. A
## registry that depended on either (a signal, a node lookup) would fail here, or worse, be
## skipped silently. ContentDb is a static class, so everything below happens inside
## `_init()` with no `await` before it.
##
## The first check is the premise itself: if a Godot upgrade ever starts autoloads earlier,
## this suite says so instead of quietly proving nothing.


func _init() -> void:
	suite_title = "TEST CONTENT DB IN INIT"
	_expect(not root.has_node("SfxManager") and not root.has_node("SaveService"),
		"no autoload exists yet while _init() runs, which is the situation under test")

	ContentDb.clear_cache()
	var kind_names := ContentDb.kinds()
	_expect(kind_names.size() >= 9, "the registry knows its %d kinds with no autoload present" % kind_names.size())
	for kind_name in [&"player", &"world", &"enemies", &"rooms", &"rules", &"skills", &"pickups", &"difficulty", &"tilesets"]:
		_expect(ContentDb.has_kind(kind_name), "kind '%s' is registered" % kind_name)

	var enemy_ids := ContentDb.ids(&"enemies")
	_expect(&"pawn_recruit" in enemy_ids and &"knight_tracker" in enemy_ids and enemy_ids.size() >= 7,
		"ids(enemies) lists the folders of content/enemies/ (%d found)" % enemy_ids.size())
	_expect(&"_shared" not in enemy_ids, "the underscore folder _shared is not an id")
	_expect(ContentDb.ids(&"no_such_kind").is_empty(), "an unknown kind has no ids and prints no error")

	var pawn := ContentDb.fetch(&"enemies", &"pawn_recruit") as EnemyDefinition
	_expect(pawn != null and pawn.id == &"pawn_recruit", "fetch(enemies, pawn_recruit) loads its EnemyDefinition")
	_expect(ContentDb.fetch(&"enemies", &"no_such_enemy") == null, "fetch of an unknown id is null, not an error")
	_expect(ContentDb.fetch(&"no_such_kind", &"x") == null, "fetch of an unknown kind is null, not an error")

	var rule_pages := ContentDb.all(&"rules")
	_expect(rule_pages.size() == ContentDb.ids(&"rules").size() and rule_pages.size() >= 5,
		"all(rules) loads every page (%d)" % rule_pages.size())
	var first_page := rule_pages.values()[0] as RuleEntry
	_expect(first_page != null, "all(rules) values are RuleEntry resources")

	var room_scene := ContentDb.fetch(&"rooms", &"t1_white_kings_fall") as PackedScene
	_expect(room_scene != null and room_scene.can_instantiate(), "a room folder loads as a scene")

	var player := ContentDb.player()
	_expect(player != null and player.validate().is_empty(), "ContentDb.player() is the PlayerDefinition of content/player/player.tres")
	var graph := ContentDb.world()
	_expect(graph != null and graph.has_zone(&"t1_white_kings_fall"), "ContentDb.world() is the world graph of content/world/world.tres")

	var problems := ContentDb.validate()
	for problem in problems:
		printerr("  problem: %s" % problem)
	_expect(problems.is_empty(), "validate() finds nothing wrong (%d problem(s))" % problems.size())
	var reference_problems := ContentDb.validate_cross_refs()
	for problem in reference_problems:
		printerr("  problem: %s" % problem)
	_expect(reference_problems.is_empty(), "validate_cross_refs() finds nothing wrong (%d problem(s))" % reference_problems.size())

	_expect(not root.has_node("SfxManager") and not root.has_node("SaveService"),
		"the registry created no autoload on the way (still none)")
	finish()
