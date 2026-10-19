class_name CameraBridge
extends EventBridge

## The camera's responsibility: which events shake the screen, and framing every room that boots. A
## hit the hero lands gives a short, light shake; a hit the hero takes gives a longer, heavier one that
## grows with the damage. The rig does the shaking (CameraRig.start_shake) and the clamping to the
## board; this bridge only decides when the picture is kicked.
## Reads: events. Writes: the camera rig. Decides: nothing about the game.

## The shake of a swing that struck something: seconds and pixels.
const HIT_LANDED_SHAKE_SECONDS := 0.10
const HIT_LANDED_SHAKE_STRENGTH := 2.6
## The shake of a hit the hero takes: seconds, and pixels at 0 damage (each point of damage adds one).
const HIT_TAKEN_SHAKE_SECONDS := 0.16
const HIT_TAKEN_SHAKE_BASE_STRENGTH := 4.2

var camera_rig: CameraRig


## The rig is a child of the hero's view, so a scene that swaps the view hands the new rig over.
func attach(rig: CameraRig) -> void:
	camera_rig = rig


func register(router: EventRouter) -> void:
	router.on(Events.ATTACK_LANDED, _on_player_attack_landed)
	router.on(Events.DAMAGED, _on_damaged)


## Frames the room that just booted: the rig clamps to its grid and becomes the current camera.
func show_room(grid) -> void:
	if camera_rig != null:
		camera_rig.setup(grid)


func shake(duration: float, strength: float) -> void:
	if camera_rig != null:
		camera_rig.start_shake(duration, strength)


func _on_player_attack_landed(event: Dictionary) -> void:
	if int(event.get("hit_count", 0)) > 0:
		shake(HIT_LANDED_SHAKE_SECONDS, HIT_LANDED_SHAKE_STRENGTH)


func _on_damaged(event: Dictionary) -> void:
	if is_player(int(event.get("entity", 0))):
		shake(HIT_TAKEN_SHAKE_SECONDS, HIT_TAKEN_SHAKE_BASE_STRENGTH + float(event.get("amount", 1)))
