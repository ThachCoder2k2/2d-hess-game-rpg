extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	var game: Node = main_scene.instantiate()
	root.add_child(game)
	await process_frame
	var director := game.get("director") as EncounterDirector
	director.set_paused(true)
	var room := game.get_node_or_null("FirstEncounter")
	var hero := game.get("hero") as PawnHero
	var hero_start_cell := Vector2i.ZERO
	if room != null and room.has_method("get_hero_start_cell"):
		hero_start_cell = room.call("get_hero_start_cell")
	var hud := game.get("hud") as Node
	var encounter_label := hud.get_node_or_null("EncounterLabel") as Label
	var skill_fill := hud.get_node_or_null("SkillFill") as ColorRect
	var damage_flash := hud.get_node_or_null("DamageFlash") as ColorRect
	var result_label := hud.get_node_or_null("ResultLabel") as Label
	var editor_binding_ok: bool = (
		game.get("grid_world") == game.get_node_or_null("GridWorld")
		and game.get("director") == game.get_node_or_null("EncounterDirector")
		and game.get("board") == game.get_node_or_null("PrototypeBoard")
		and game.get("hero") == game.get_node_or_null("PawnHero")
		and game.get("hud") == game.get_node_or_null("HUD")
	)
	var initial_ok: bool = (
		editor_binding_ok
		and game.get_node_or_null("FirstEncounter") != null
		and hero != null
		and hero.current_cell == hero_start_cell
		and game.get("remaining_enemies") == 3
		and game.get("total_enemies") == 3
		and encounter_label != null
		and encounter_label.text == "ENEMIES 3/3"
		and skill_fill != null
		and is_equal_approx(skill_fill.size.x, 92.0)
		and damage_flash != null
		and not damage_flash.visible
		and result_label != null
		and not result_label.visible
	)
	game.call("_on_hero_damaged", 1, 2)
	var hero_camera := hero.get_node_or_null("Camera2D")
	var damage_feedback_ok: bool = damage_flash.visible and hero_camera != null and hero_camera.get("shake_time_left") > 0.0
	var enemies: Array = game.get("enemies")
	var first_enemy := enemies[0] as FreeEnemy
	game.call("_on_enemy_defeated", first_enemy)
	var defeat_update_ok: bool = (
		game.get("remaining_enemies") == 2
		and encounter_label.text == "ENEMIES 2/3"
		and not result_label.visible
	)
	var succeeded := initial_ok and damage_feedback_ok and defeat_update_ok
	game.free()
	await process_frame
	print("ENCOUNTER HUD TEST: %s" % ["PASS" if succeeded else "FAIL"])
	quit(0 if succeeded else 1)
