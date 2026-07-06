extends SceneTree

var weapon_change_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := GridWorld.new()
	root.add_child(world)
	var scene := load("res://objects/actors/enemy_base.tscn") as PackedScene
	var enemy := scene.instantiate() as EnemyActor
	enemy.weapon_changed.connect(func(_actor: FreeEnemy, _weapon: EnemyWeapon): weapon_change_count += 1)
	root.add_child(enemy)
	var setup_ok := enemy.setup(world, Vector2i(6, 6))
	var pickup := WeaponPickup.new()
	root.add_child(pickup)
	var pickup_ok := pickup.setup(world, Vector2i(6, 6), EnemyWeapon.pencil_spear())
	var collected := enemy.collect_weapon_pickup(pickup)
	await process_frame
	var succeeded := (
		setup_ok
		and pickup_ok
		and collected
		and weapon_change_count == 1
		and enemy.equipment_component.is_armed()
		and enemy.weapon == enemy.equipment_component.get_weapon()
		and enemy.get_attack_cells(Vector2i(6, 6), Vector2i.RIGHT).size() == 2
		and world.item_at(Vector2i(6, 6)) == null
	)
	print("COMPONENT EQUIPMENT TEST: %s" % ["PASS" if succeeded else "FAIL"])
	quit(0 if succeeded else 1)
