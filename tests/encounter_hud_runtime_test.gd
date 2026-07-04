extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_script := load("res://scripts/main.gd")
	var game: Node = main_script.new()
	root.add_child(game)
	await process_frame
	var director := game.get("director") as EncounterDirector
	director.set_paused(true)
	var encounter_label := game.get("encounter_label") as Label
	var skill_fill := game.get("skill_fill") as ColorRect
	var damage_flash := game.get("damage_flash") as ColorRect
	var result_label := game.get("result_label") as Label
	var initial_ok: bool = (
		game.get("remaining_enemies") == 3
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
	var damage_feedback_ok: bool = damage_flash.visible and game.get("shake_time") > 0.0
	var enemies: Array = game.get("enemies")
	var first_enemy := enemies[0] as FreeEnemy
	game.call("_on_enemy_defeated", first_enemy)
	var defeat_update_ok: bool = (
		game.get("remaining_enemies") == 2
		and encounter_label.text == "ENEMIES 2/3"
		and not result_label.visible
	)
	print("ENCOUNTER HUD TEST: %s" % ["PASS" if initial_ok and damage_feedback_ok and defeat_update_ok else "FAIL"])
	quit(0 if initial_ok and damage_feedback_ok and defeat_update_ok else 1)
