extends UnboundTest

## validate() and validate_cross_refs() really detect what they claim to (a mutation check
## kept as a test). test_validate_all.gd proves the real content is healthy; a validator
## that returns an empty list for everything would pass that too, so this suite points the
## registry at a throwaway tree under user:// that is broken in one named way per entry, and
## requires the exact complaint for each. A clean entry in the same tree must stay out of
## every complaint (the control).
##
## It also pins the lazy cache: a folder created after the first listing stays invisible
## until clear_cache(), and configure_root() puts the real content back at the end.

const FIXTURE_ROOT := "user://content_db_fixture"
const ENEMY_SCRIPT := "res://schema/entity/enemy_definition.gd"
const SHARED_ENEMY_PARTS := """[ext_resource type="Resource" path="res://content/enemies/_shared/movement/pawn_standard.tres" id="2"]
[ext_resource type="Resource" path="res://content/enemies/_shared/decisions/pawn_skirmisher.tres" id="3"]
[ext_resource type="Resource" path="res://content/enemies/_shared/attacks/pawn_diagonal.tres" id="4"]
[ext_resource type="Resource" path="res://content/enemies/_shared/visuals/pawn_compatibility.tres" id="5"]
[ext_resource type="Resource" path="user://content_db_fixture/difficulty/standard.tres" id="6"]
"""
const SHARED_ENEMY_FIELDS := """display_name = "Fixture"
piece_name = "Pawn"
movement = ExtResource("2")
decision = ExtResource("3")
unarmed_attack = ExtResource("4")
visual = ExtResource("5")
difficulty = ExtResource("6")
"""


func _init() -> void:
	suite_title = "TEST CONTENT DB DETECTS PROBLEMS"
	_remove_tree(FIXTURE_ROOT)
	_write_fixture_tree()
	ContentDb.configure_root(FIXTURE_ROOT)

	_expect(&"clean_pawn" in ContentDb.ids(&"enemies") and &"_shared" not in ContentDb.ids(&"enemies"),
		"the registry lists the fixture's enemy folders and skips the underscore one")

	var registry_problems := ContentDb.validate()
	var reference_problems := ContentDb.validate_cross_refs()
	for problem in registry_problems:
		print("  validate: %s" % problem)
	for problem in reference_problems:
		print("  cross ref: %s" % problem)

	# validate(): one complaint per broken entry.
	_expect_problem(registry_problems, "enemies/mislabeled: its id property says 'another_name' but its folder (the id) says 'mislabeled'", "an id property that differs from the folder is reported")
	_expect_problem(registry_problems, "enemies/Loud_Name: a name is the id, so it must be lowercase snake_case", "a name that is not lowercase snake_case is reported")
	_expect_problem(registry_problems, "enemies/no_main_file: the main file", "an id folder without its main file is reported")
	_expect_problem(registry_problems, "enemies/wrong_class: user://content_db_fixture/enemies/wrong_class/enemy.tres loads as RuleEntry, which is not the class this kind needs", "a main file of the wrong class is reported, naming the class it is")
	_expect_problem(registry_problems, "enemies/incomplete: Enemy definition requires MovementConfig", "a definition's own validate() warning is reported with its entry")
	_expect_problem(registry_problems, "enemies/twin_a: its id property says 'twin_b' but its folder (the id) says 'twin_a'", "the first of two entries claiming one id is reported")
	_expect_problem(registry_problems, "enemies/twin_b: the id 'twin_b' is already claimed by twin_a", "a duplicate id is reported")
	_expect_problem(registry_problems, "enemies/wrong_reference_class: in user://content_db_fixture/enemies/wrong_reference_class/enemy.tres the property 'default_weapon' names a resource, but it is empty", "a reference to a resource of the wrong class (a skill where a weapon belongs), which Godot drops without a word, is reported with the property")
	_expect_no_problem_about(registry_problems, "enemies/wrong_reference_class: in res://content", "...and only the broken property, not the shared parts the enemy names rightly")
	_expect_problem(registry_problems, "difficulty/Bad_Profile: a name is the id", "a flat kind checks the file name too")
	_expect_problem(registry_problems, "tilesets: the folder", "a kind whose folder is missing is reported")
	_expect_problem(registry_problems, "player: the folder", "a one-of-a-kind file whose folder is missing is reported")
	_expect_no_problem_about(registry_problems, "enemies/clean_pawn", "the clean fixture enemy raises no registry complaint")
	_expect_no_problem_about(registry_problems, "enemies/_shared", "the underscore folder raises no registry complaint")

	# validate_cross_refs(): one complaint per dangling reference.
	_expect_problem(reference_problems, "enemies/unknown_kind: its visual's piece_type 'dragon' is not a row of content/feel/piece_sizes.tres (rows: pawn)", "a visual naming a kind the size table lacks is reported, with the kinds it has")
	_expect_problem(reference_problems, "enemies/oversized_body: its body picture is 80 x 80 px but a pawn may be drawn at most 18 x 22 px", "a body picture larger than its kind's box is reported, with both sizes")
	_expect_problem(reference_problems, "rules/orphan: piece_id 'ghost_piece' is not an enemy", "a Book page naming a missing enemy is reported")
	_expect_problem(reference_problems, "enemies/ghost_hunter: weapon_preferences names 'ghost_weapon', which is not a pickup", "a weapon preference naming a missing pickup is reported")
	_expect_problem(reference_problems, "world/world: zone 'nowhere' has no folder content/rooms/nowhere/", "a world zone without a room folder is reported")
	_expect_problem(reference_problems, "rooms/lonely: no zone of content/world/world.tres leads here", "a room the graph never names is reported")
	_expect_problem(reference_problems, "rooms/nowhere: the root's zone_id is 'someone_else' but the zone is 'nowhere'", "a room whose zone_id differs from its zone is reported")
	_expect_problem(reference_problems, "a door leads to zone 'atlantis', which is not in content/world/world.tres", "a door to a missing zone is reported")
	_expect_no_problem_about(reference_problems, "enemies/clean_pawn", "the clean fixture enemy raises no cross-reference complaint")

	# The id cache is lazy and honest about it.
	_make_directory(FIXTURE_ROOT.path_join("enemies/late_arrival"))
	_write(FIXTURE_ROOT.path_join("enemies/late_arrival/enemy.tres"), _enemy_text("late_arrival", ""))
	_expect(&"late_arrival" not in ContentDb.ids(&"enemies"), "a folder created after the first listing is not seen yet (the id cache is lazy and kept)")
	ContentDb.clear_cache()
	_expect(&"late_arrival" in ContentDb.ids(&"enemies"), "clear_cache() makes the next listing see it")

	# Back to the real content: healthy again, so the checks above were about the fixture.
	ContentDb.configure_root(ContentDb.DEFAULT_CONTENT_ROOT)
	_expect(ContentDb.validate().is_empty() and ContentDb.validate_cross_refs().is_empty(), "configure_root(default) puts the real, healthy content back")
	_remove_tree(FIXTURE_ROOT)
	finish()


# --------------------------------------------------------------------------- assertions
func _expect_problem(problems: PackedStringArray, fragment: String, label: String) -> void:
	for problem in problems:
		if problem.contains(fragment):
			_expect(true, label)
			return
	_expect(false, "%s (no problem contains: %s)" % [label, fragment])


func _expect_no_problem_about(problems: PackedStringArray, fragment: String, label: String) -> void:
	var mentions: Array[String] = []
	for problem in problems:
		if problem.contains(fragment):
			mentions.append(problem)
	_expect(mentions.is_empty(), "%s (%s)" % [label, "; ".join(mentions)])


# --------------------------------------------------------------------------- the broken tree
func _write_fixture_tree() -> void:
	# difficulty: one good profile, one badly named.
	_write(FIXTURE_ROOT.path_join("difficulty/standard.tres"), _difficulty_text("standard"))
	_write(FIXTURE_ROOT.path_join("difficulty/Bad_Profile.tres"), _difficulty_text("Bad_Profile"))

	# enemies: a clean control and one defect each.
	_write(FIXTURE_ROOT.path_join("enemies/clean_pawn/enemy.tres"), _enemy_text("clean_pawn", ""))
	_write(FIXTURE_ROOT.path_join("enemies/wrong_reference_class/enemy.tres"), _enemy_text("wrong_reference_class", "default_weapon = ExtResource(\"7\")\n").replace("\n[resource]\n", "\n[ext_resource type=\"Resource\" path=\"res://content/skills/wooden_sword/wooden_sword.tres\" id=\"7\"]\n\n[resource]\n"))
	_write(FIXTURE_ROOT.path_join("enemies/ghost_hunter/enemy.tres"), _enemy_text("ghost_hunter", "weapon_preferences = {&\"ghost_weapon\": 1.0}\n"))
	_write(FIXTURE_ROOT.path_join("enemies/mislabeled/enemy.tres"), _enemy_text("another_name", ""))
	_write(FIXTURE_ROOT.path_join("enemies/Loud_Name/enemy.tres"), _enemy_text("Loud_Name", ""))
	_make_directory(FIXTURE_ROOT.path_join("enemies/no_main_file"))
	_write(FIXTURE_ROOT.path_join("enemies/no_main_file/notes.txt"), "an id folder with no enemy.tres\n")
	_write(FIXTURE_ROOT.path_join("enemies/wrong_class/enemy.tres"), _rule_page_text("pawn_recruit"))
	_write(FIXTURE_ROOT.path_join("enemies/incomplete/enemy.tres"), "[gd_resource type=\"Resource\" script_class=\"EnemyDefinition\" format=3]\n\n[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n\n[resource]\nscript = ExtResource(\"1\")\nid = &\"incomplete\"\n" % ENEMY_SCRIPT)
	_write(FIXTURE_ROOT.path_join("enemies/twin_a/enemy.tres"), _enemy_text("twin_b", ""))
	_write(FIXTURE_ROOT.path_join("enemies/twin_b/enemy.tres"), _enemy_text("twin_b", ""))
	_write(FIXTURE_ROOT.path_join("enemies/_shared/readme.txt"), "not an id\n")

	# the size table (one pawn row) and two enemies whose visuals break it: a picture bigger than
	# the pawn's box, and a kind the table has no row for. The clean pawn uses the real pawn visual.
	_write(FIXTURE_ROOT.path_join("feel/piece_sizes.tres"), _piece_sizes_text())
	_write(FIXTURE_ROOT.path_join("enemies/oversized_body/visual.tres"), _visual_text("oversized_body", "pawn", "res://assets/ui/actor_view/warning_aura.png"))
	_write(FIXTURE_ROOT.path_join("enemies/oversized_body/enemy.tres"), _enemy_text("oversized_body", "").replace("res://content/enemies/_shared/visuals/pawn_compatibility.tres", "user://content_db_fixture/enemies/oversized_body/visual.tres"))
	_write(FIXTURE_ROOT.path_join("enemies/unknown_kind/visual.tres"), _visual_text("unknown_kind", "dragon", "res://content/enemies/pawn_recruit/body.png"))
	_write(FIXTURE_ROOT.path_join("enemies/unknown_kind/enemy.tres"), _enemy_text("unknown_kind", "").replace("res://content/enemies/_shared/visuals/pawn_compatibility.tres", "user://content_db_fixture/enemies/unknown_kind/visual.tres"))

	# rules: a page whose piece does not exist.
	_write(FIXTURE_ROOT.path_join("rules/orphan/page.tres"), _rule_page_text("ghost_piece"))

	# rooms and world: a room that disagrees with its zone, a door to nowhere, and a zone with no folder.
	_write(FIXTURE_ROOT.path_join("rooms/lonely/room.tscn"), """[gd_scene format=3]

[ext_resource type="PackedScene" path="res://authoring/room_encounter.tscn" id="1"]
[ext_resource type="Script" path="res://authoring/markers/zone_exit_marker.gd" id="2"]

[node name="Lonely" instance=ExtResource("1")]
zone_id = &"someone_else"

[node name="Exit" type="Marker2D" parent="."]
script = ExtResource("2")
target_zone = &"atlantis"
target_entry = &"start"
""")
	_write(FIXTURE_ROOT.path_join("world/world.tres"), """[gd_resource type="Resource" script_class="WorldGraph" format=3]

[ext_resource type="Script" path="res://schema/world/world_graph.gd" id="1"]
[ext_resource type="PackedScene" path="user://content_db_fixture/rooms/lonely/room.tscn" id="2"]

[resource]
script = ExtResource("1")
zone_scene_by_id = Dictionary[StringName, PackedScene]({
&"nowhere": ExtResource("2")
})
""")


func _difficulty_text(id: String) -> String:
	return "[gd_resource type=\"Resource\" script_class=\"DifficultyProfile\" format=3]\n\n[ext_resource type=\"Script\" path=\"res://schema/feel/difficulty_profile.gd\" id=\"1\"]\n\n[resource]\nscript = ExtResource(\"1\")\nid = &\"%s\"\n" % id


func _enemy_text(claimed_id: String, extra_fields: String) -> String:
	return "[gd_resource type=\"Resource\" script_class=\"EnemyDefinition\" format=3]\n\n[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n%s\n[resource]\nscript = ExtResource(\"1\")\nid = &\"%s\"\n%s%s" % [ENEMY_SCRIPT, SHARED_ENEMY_PARTS, claimed_id, SHARED_ENEMY_FIELDS, extra_fields]


func _piece_sizes_text() -> String:
	return "[gd_resource type=\"Resource\" script_class=\"PieceSizeTable\" format=3]\n\n[ext_resource type=\"Script\" path=\"res://schema/feel/piece_size_table.gd\" id=\"1\"]\n[ext_resource type=\"Script\" path=\"res://schema/feel/piece_size.gd\" id=\"2\"]\n\n[sub_resource type=\"Resource\" id=\"Resource_pawn\"]\nscript = ExtResource(\"2\")\npiece_type = &\"pawn\"\nbody_box = Vector2i(18, 22)\nbase_offset_y = 14\n\n[resource]\nscript = ExtResource(\"1\")\nrows = Array[ExtResource(\"2\")]([SubResource(\"Resource_pawn\")])\n"


func _visual_text(id: String, piece_type: String, body_path: String) -> String:
	return "[gd_resource type=\"Resource\" script_class=\"VisualDefinition\" format=3]\n\n[ext_resource type=\"Script\" path=\"res://schema/entity/visual_definition.gd\" id=\"1\"]\n[ext_resource type=\"Texture2D\" path=\"%s\" id=\"2\"]\n\n[resource]\nscript = ExtResource(\"1\")\nid = &\"%s\"\npiece_type = &\"%s\"\nbody_texture = ExtResource(\"2\")\n" % [body_path, id, piece_type]


func _rule_page_text(piece_id: String) -> String:
	return "[gd_resource type=\"Resource\" script_class=\"RuleEntry\" format=3]\n\n[ext_resource type=\"Script\" path=\"res://schema/world/rule_entry.gd\" id=\"1\"]\n\n[resource]\nscript = ExtResource(\"1\")\npiece_id = &\"%s\"\ntitle = \"A page\"\noriginal_rule = \"A rule.\"\namendment = \"An amendment.\"\n" % piece_id


# --------------------------------------------------------------------------- file helpers
func _make_directory(directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)


func _write(path: String, text: String) -> void:
	_make_directory(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "the fixture file %s can be written (error %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(text)
	file.close()


func _remove_tree(directory: String) -> void:
	if not DirAccess.dir_exists_absolute(directory):
		return
	for sub_directory in DirAccess.get_directories_at(directory):
		_remove_tree(directory.path_join(sub_directory))
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
	DirAccess.remove_absolute(directory)
