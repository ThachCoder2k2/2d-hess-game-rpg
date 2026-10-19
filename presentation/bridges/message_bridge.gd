class_name MessageBridge
extends EventBridge

## The status line's responsibility: the words the game says to the player when something happens.
## The line is the HUD's objective label (GameHud.set_status); every sentence that appears there
## because of an event is written here and nowhere else, and the scene and the other bridges say
## theirs through say(), so one place decides which words are on screen. M4 moves the sentences to
## text keys (docs/game-base-plan.md 8.9); until then they are the constants below.
## Reads: events. Writes: the HUD's status line. Decides: nothing about the game.

## The attack key pressed before the sword was found.
const NO_WEAPON_YET := "The pawn has no weapon yet. Find the fallen sword."
## A swing that struck something; %s is the attack's display name.
const ATTACK_CONNECTS_FORMAT := "%s connects. Keep pressing the broken line."
## The hero was hit and has one Courage left.
const ONE_COURAGE_LEFT := "One courage left. Wait for the warning, then cut through."
## The hero was hit and has more than one Courage left.
const PAWN_IS_HIT := "The pawn is hit. Move out before the next strike."
## An enemy took a floor weapon; %s are the piece's name and the weapon's display name.
const ENEMY_PICKED_UP_FORMAT := "%s picked up %s. Its chess attack has been replaced."
## The hero stepped on a door that needs its room cleared first.
const DOOR_IS_LOCKED := "The captain still holds the rug edge. Break the black line first."
## A shortcut gate was unbarred.
const GATE_UNBARS := "The gate unbars. It will never close again."
## A verb was unlocked and its marker carries no line of its own.
const UNLOCK_FALLBACK := "The pawn grips the sword. The rules crack."

var hud: GameHud


func attach(hud_node: GameHud) -> void:
	hud = hud_node


func register(router: EventRouter) -> void:
	router.on(Events.ATTACK_LOCKED, _on_attack_locked)
	router.on(Events.ATTACK_LANDED, _on_player_attack_landed)
	router.on(Events.DAMAGED, _on_damaged)
	router.on(Events.WEAPON_CHANGED, _on_enemy_weapon_changed)
	router.on(Events.PLAYER_UNLOCK, _on_player_unlock)
	router.on(Events.GATE_OPENED, _on_gate_opened)
	router.on(Events.ZONE_EXIT_LOCKED, _on_zone_exit_locked)


## Puts `text` on the status line. The scene and the other bridges (the room's own opening and ending
## lines, the debug switch, the Book's new pages) say their words through here.
func say(text: String) -> void:
	if hud != null:
		hud.set_status(text)


func _on_attack_locked(_event: Dictionary) -> void:
	say(NO_WEAPON_YET)


func _on_player_attack_landed(event: Dictionary) -> void:
	var profile := event.get("profile") as AttackProfile
	if int(event.get("hit_count", 0)) > 0 and profile != null:
		say(ATTACK_CONNECTS_FORMAT % profile.display_name)


func _on_damaged(event: Dictionary) -> void:
	if not is_player(int(event.get("entity", 0))):
		return
	var remaining := int(event.get("remaining", 0))
	if remaining == 1:
		say(ONE_COURAGE_LEFT)
	elif remaining > 1:
		say(PAWN_IS_HIT)


func _on_enemy_weapon_changed(event: Dictionary) -> void:
	var weapon := event.get("weapon") as EnemyWeapon
	if weapon != null:
		say(ENEMY_PICKED_UP_FORMAT % [piece_name_of(int(event.get("entity", 0))), weapon.display_name])


## The unlock's own line, from the marker that was stepped on. An unlock with no id says nothing.
func _on_player_unlock(event: Dictionary) -> void:
	if StringName(event.get("id", &"")) == &"":
		return
	var message := String(event.get("message", ""))
	say(message if not message.is_empty() else UNLOCK_FALLBACK)


func _on_gate_opened(_event: Dictionary) -> void:
	say(GATE_UNBARS)


func _on_zone_exit_locked(_event: Dictionary) -> void:
	say(DOOR_IS_LOCKED)
