extends SceneTree

var resolved_attacks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var world := GridWorld.new()
	stage.add_child(world)
	var board := PrototypeBoard.new()
	stage.add_child(board)
	board.setup(world)
	var director := EncounterDirector.new()
	stage.add_child(director)
	var hero := PawnHero.new()
	stage.add_child(hero)
	hero.setup(world, Vector2i(5, 5))
	hero.control_enabled = false
	var enemy := (load("res://objects/actors/black_pawn.tscn") as PackedScene).instantiate() as EnemyActor
	stage.add_child(enemy)
	enemy.setup(world, Vector2i(4, 4))
	enemy.facing = Vector2i.DOWN
	enemy.telegraph_started.connect(board.set_telegraph)
	enemy.telegraph_finished.connect(board.clear_telegraph)
	enemy.attack_resolved.connect(_on_attack_resolved.bind(board, director))
	enemy.intent_changed.connect(board.set_enemy_intent)
	enemy.activate(hero, director)

	await create_timer(4.0).timeout
	var succeeded := resolved_attacks > 0 and hero.courage < 3 and board.telegraphs.is_empty()
	print("ATTACK RUNTIME TEST: %s (%d resolved)" % ["PASS" if succeeded else "FAIL", resolved_attacks])
	quit(0 if succeeded else 1)


func _on_attack_resolved(cells: Array[Vector2i], board: PrototypeBoard, director: EncounterDirector) -> void:
	resolved_attacks += 1
	board.show_enemy_attack(cells)
	director.set_paused(true)
