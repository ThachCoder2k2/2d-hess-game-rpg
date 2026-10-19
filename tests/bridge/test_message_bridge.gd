extends UnboundTest

## MessageBridge (presentation/bridges/message_bridge.gd, M3b step 2): the words on the status line
## that events cause. The sentences are the ones game_root.gd wrote before the split; this suite pins
## each of them, and the cases where an event says nothing (a hit on an enemy, a swing that struck
## nothing, an unlock with no id), through a real router and the real HUD scene, with a snapshot and
## no world behind it.

const HERO := 1
const PAWN := 7


func _init() -> void:
	suite_title = "MESSAGE BRIDGE TEST"
	await process_frame
	_check_the_events_that_speak()
	_check_the_hero_hurt_speaks_by_courage_left()
	_check_a_swing_speaks_only_when_it_connects()
	_check_an_unlock_speaks_with_its_own_line_or_the_fallback()
	_check_the_enemy_weapon_line_names_the_piece()
	_check_say_and_a_scene_without_a_hud()
	finish()


func _make_bridge() -> Array:
	var paths := TestPaths.new(self)
	var hud := paths.load_scene(paths.hud_scene()).instantiate() as GameHud
	root.add_child(hud)
	var snapshot := HudSnapshot.new()
	snapshot.player_entity = HERO
	var bridge := MessageBridge.new()
	bridge.attach(hud)
	bridge.bind_world(snapshot, {"piece_name_by_entity": {PAWN: "Black Pawn", HERO: "Pawn"}})
	var router := EventRouter.new()
	bridge.register(router)
	return [bridge, hud, router]


func _check_the_events_that_speak() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	router.route([{"type": Events.ATTACK_LOCKED, "entity": HERO}])
	_expect(hud.objective_label.text == "The pawn has no weapon yet. Find the fallen sword.", "pressing attack before the sword says where the sword is")
	router.route([{"type": Events.GATE_OPENED, "entity": HERO, "gate": &"g", "cell": Vector2i.ZERO}])
	_expect(hud.objective_label.text == "The gate unbars. It will never close again.", "a gate opening says it is for good")
	router.route([{"type": Events.ZONE_EXIT_LOCKED, "entity": HERO, "zone": &"t4", "entry": &"start", "cell": Vector2i.ZERO}])
	_expect(hud.objective_label.text == "The captain still holds the rug edge. Break the black line first.", "a locked door says what holds it")


func _check_the_hero_hurt_speaks_by_courage_left() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	hud.set_status("sentinel")
	router.route([{"type": Events.DAMAGED, "entity": HERO, "amount": 1, "remaining": 2, "direction": Vector2i.LEFT, "source": PAWN, "tags": []}])
	_expect(hud.objective_label.text == "The pawn is hit. Move out before the next strike.", "a hit with courage to spare says to move out")
	router.route([{"type": Events.DAMAGED, "entity": HERO, "amount": 1, "remaining": 1, "direction": Vector2i.LEFT, "source": PAWN, "tags": []}])
	_expect(hud.objective_label.text == "One courage left. Wait for the warning, then cut through.", "a hit that leaves one courage says to wait for the warning")
	hud.set_status("sentinel")
	router.route([{"type": Events.DAMAGED, "entity": HERO, "amount": 1, "remaining": 0, "direction": Vector2i.LEFT, "source": PAWN, "tags": []}])
	_expect(hud.objective_label.text == "sentinel", "the fatal hit says nothing (the room outcome has the last word)")
	router.route([{"type": Events.DAMAGED, "entity": PAWN, "amount": 2, "remaining": 1, "direction": Vector2i.UP, "source": HERO, "tags": []}])
	_expect(hud.objective_label.text == "sentinel", "an enemy being hurt says nothing")


func _check_a_swing_speaks_only_when_it_connects() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	var profile := AttackProfile.new()
	profile.display_name = "Wooden Sword"
	var cells: Array[Vector2i] = [Vector2i(2, 2)]
	hud.set_status("sentinel")
	router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 0, "profile": profile}])
	_expect(hud.objective_label.text == "sentinel", "a swing that struck nothing says nothing")
	router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 2, "profile": profile}])
	_expect(hud.objective_label.text == "Wooden Sword connects. Keep pressing the broken line.", "a swing that connects names the attack")
	hud.set_status("sentinel")
	router.route([{"type": Events.ATTACK_LANDED, "entity": HERO, "cells": cells, "hit_count": 2, "profile": null}])
	_expect(hud.objective_label.text == "sentinel", "a connecting swing with no attack to name says nothing")


func _check_an_unlock_speaks_with_its_own_line_or_the_fallback() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	router.route([{"type": Events.PLAYER_UNLOCK, "entity": HERO, "id": &"wooden_sword", "message": "The child whispers."}])
	_expect(hud.objective_label.text == "The child whispers.", "an unlock says the line its marker carries")
	router.route([{"type": Events.PLAYER_UNLOCK, "entity": HERO, "id": &"wooden_sword", "message": ""}])
	_expect(hud.objective_label.text == "The pawn grips the sword. The rules crack.", "an unlock whose marker has no line says the fallback")
	hud.set_status("sentinel")
	router.route([{"type": Events.PLAYER_UNLOCK, "entity": HERO, "id": &"", "message": "ignored"}])
	_expect(hud.objective_label.text == "sentinel", "an unlock with no id says nothing")


func _check_the_enemy_weapon_line_names_the_piece() -> void:
	var parts := _make_bridge()
	var hud: GameHud = parts[1]
	var router: EventRouter = parts[2]
	var weapon := EnemyWeapon.new()
	weapon.display_name = "Pencil Spear"
	router.route([{"type": Events.WEAPON_CHANGED, "entity": PAWN, "weapon": weapon}])
	_expect(hud.objective_label.text == "Black Pawn picked up Pencil Spear. Its chess attack has been replaced.", "an enemy taking a weapon names the piece and the weapon")
	router.route([{"type": Events.WEAPON_CHANGED, "entity": 99, "weapon": weapon}])
	_expect(hud.objective_label.text == "Enemy picked up Pencil Spear. Its chess attack has been replaced.", "a piece the cast does not know is called Enemy")


func _check_say_and_a_scene_without_a_hud() -> void:
	var parts := _make_bridge()
	var bridge: MessageBridge = parts[0]
	var hud: GameHud = parts[1]
	bridge.say("ROOM CLEARED")
	_expect(hud.objective_label.text == "ROOM CLEARED", "say() puts any line on the status line, for the scene and the other bridges")
	var silent := MessageBridge.new()
	silent.say("nobody hears this")
	_expect(true, "a scene without a HUD says nothing and complains of nothing")
