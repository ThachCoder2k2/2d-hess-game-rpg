class_name MessageBridge
extends EventBridge

## The status line's responsibility: the words the game says to the player when something happens.
## The line is the HUD's objective label (GameHud.set_status); every sentence that appears there
## because of an event is chosen here and nowhere else, and the scene and the other bridges say
## theirs through say(), so one place decides which words are on screen. The sentences are rows of
## content/story/text/en/ui.po (docs/game-base-plan.md 8.9): the constants below are their KEYS, and the
## HUD keeps the line in the player's language.
## Reads: events. Writes: the HUD's status line. Decides: nothing about the game.

## The attack key pressed before the sword was found.
const NO_WEAPON_YET_KEY := "MSG_NO_WEAPON_YET"
## A swing that struck something; {attack} is the attack's name.
const ATTACK_CONNECTS_KEY := "MSG_ATTACK_CONNECTS"
## The hero was hit and has one Courage left.
const ONE_COURAGE_LEFT_KEY := "MSG_ONE_COURAGE_LEFT"
## The hero was hit and has more than one Courage left.
const PAWN_IS_HIT_KEY := "MSG_PAWN_IS_HIT"
## An enemy took a floor weapon; {piece} and {weapon} are the piece's name and the weapon's name.
const ENEMY_PICKED_UP_KEY := "MSG_ENEMY_PICKED_UP"
## The hero stepped on a door that needs its room cleared first and the door carries no line of its own
## (ZoneExitMarker.locked_message). It names no piece, because the door may be in any room.
const DOOR_IS_LOCKED_KEY := "MSG_DOOR_IS_LOCKED"
## A shortcut gate was unbarred.
const GATE_UNBARS_KEY := "MSG_GATE_UNBARS"
## A verb was unlocked and its marker carries no line of its own.
const UNLOCK_FALLBACK_KEY := "MSG_UNLOCK_FALLBACK"

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


## Puts the words of the text key `key` on the status line, `params` filling its {name}s. The scene and the other
## bridges (the room's own opening and ending lines, the debug switch, the Book's new pages) say their words
## through here.
func say(key: String, params: Dictionary = {}) -> void:
	if hud != null:
		hud.set_status(key, params)


func _on_attack_locked(_event: Dictionary) -> void:
	say(NO_WEAPON_YET_KEY)


func _on_player_attack_landed(event: Dictionary) -> void:
	var profile := event.get("profile") as AttackProfile
	if int(event.get("hit_count", 0)) > 0 and profile != null:
		say(ATTACK_CONNECTS_KEY, {"attack": TextKey.of(profile.display_name)})


func _on_damaged(event: Dictionary) -> void:
	if not is_player(int(event.get("entity", 0))):
		return
	var remaining := int(event.get("remaining", 0))
	if remaining == 1:
		say(ONE_COURAGE_LEFT_KEY)
	elif remaining > 1:
		say(PAWN_IS_HIT_KEY)


func _on_enemy_weapon_changed(event: Dictionary) -> void:
	var weapon := event.get("weapon") as EnemyWeapon
	if weapon != null:
		say(ENEMY_PICKED_UP_KEY, {"piece": piece_name_of(int(event.get("entity", 0))), "weapon": TextKey.of(weapon.display_name)})


## The unlock's own line (a text key), from the marker that was stepped on. An unlock with no id says nothing.
func _on_player_unlock(event: Dictionary) -> void:
	if StringName(event.get("id", &"")) == &"":
		return
	var message_key := String(event.get("message", ""))
	say(message_key if not message_key.is_empty() else UNLOCK_FALLBACK_KEY)


func _on_gate_opened(_event: Dictionary) -> void:
	say(GATE_UNBARS_KEY)


## The door's own line (a text key), from the marker that was stepped on, else the generic one.
func _on_zone_exit_locked(event: Dictionary) -> void:
	var message_key := String(event.get("message", ""))
	say(message_key if not message_key.is_empty() else DOOR_IS_LOCKED_KEY)
