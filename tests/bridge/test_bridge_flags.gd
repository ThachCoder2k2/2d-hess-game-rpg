extends UnboundTest

## The world flags (WorldFlags, docs/game-base-plan.md 14.2) outlive the room that set them (M3b step 1).
## Every room is a new EcsWorld with fresh, empty flags, so the shell carries them: the SaveBridge loads the
## run's saved flags into the world it boots, copies the live world's flags into the run just before the
## SaveService writes (the service's `saving` signal), and a relaunch reads them from the file. This suite
## drives it through the real bridge: a flag set through the commands channel in T1 is still set in T2, is
## in the save file under [flags] with its type, and is still set after a relaunch.

const Support := preload("res://tests/bridge/bridge_support.gd")
const SUITE_NAME := "flags"

const T1 := &"t1_white_kings_fall"
const T2 := &"t2_fallen_sword_tile"

var save_service: Node


func _init() -> void:
	suite_title = "BRIDGE FLAGS TEST"
	call_deferred("_run")


func _run() -> void:
	save_service = Support.install_isolated_save_service(self, SUITE_NAME)
	var main := await Support.boot_main(self)

	var ecs := Support.ecs_of(main)
	_expect(ecs.flags.value_by_flag_id.is_empty(), "a new run boots a world with no flags")
	ecs.push_command(Commands.set_flag(&"beat.intro seen", true))
	ecs.push_command(Commands.set_flag(&"child.trust", 2))
	Support.pump(main, 0.1)
	_expect(ecs.flags.get_flag(&"beat.intro seen") == true and ecs.flags.get_flag(&"child.trust") == 2, "setup: the commands channel set a switch and a counter in the live world")
	_expect(Support.run_of(save_service).player.flags.is_empty(), "the run holds no flags yet: the live world is where they change")

	# The trip's save (a success event) asks the shell for the live flags first.
	_expect(await Support.walk_through_exit(self, main, T2, Vector2i.RIGHT), "the hero travels T1 -> T2")
	var next_ecs := Support.ecs_of(main)
	_expect(next_ecs != ecs and next_ecs.flags.get_flag(&"beat.intro seen") == true and next_ecs.flags.get_flag(&"child.trust") == 2, "the flags are set in the next room's world: the shell carried them")
	_expect(typeof(next_ecs.flags.get_flag(&"child.trust")) == TYPE_INT and typeof(next_ecs.flags.get_flag(&"beat.intro seen")) == TYPE_BOOL, "with their types")
	var saved := Support.read_save_file(save_service)
	_expect(saved.get_value("flags", "beat.intro seen", false) == true and saved.get_value("flags", "child.trust", 0) == 2, "and the save file holds them under [flags]")

	# A flag set in T2 reaches the file at the next success event (a taken pickup stands in for any).
	next_ecs.push_command(Commands.set_flag(&"child.trust", 3))
	Support.pump(main, 0.1)
	_expect(Support.read_save_file(save_service).get_value("flags", "child.trust", 0) == 2, "a flag changed since the last save is not on disk yet: saves happen at success events only")
	Support.run_of(save_service).taken_pickup_ids["t2_fallen_sword_tile/Something"] = true
	_expect(save_service.call("request_save", &"pickup_taken"), "setup: a success event asks for a save")
	_expect(Support.read_save_file(save_service).get_value("flags", "child.trust", 0) == 3, "the save written at that event holds the new value")

	# A relaunch continues the run and its flags.
	var last_flags := Support.ecs_of(main).flags.to_dictionary()
	main.free()
	Support.forget_the_run(save_service)
	var relaunched := await Support.boot_main(self)
	var relaunched_flags := Support.ecs_of(relaunched).flags
	_expect(relaunched_flags.to_dictionary() == last_flags and relaunched_flags.get_flag(&"child.trust") == 3, "after a relaunch the world has the saved flags")

	# A room boot never loses the flags it did not touch: a bare re-boot starts from the run, not from nothing.
	Support.reboot_zone(relaunched, &"west_entry")
	_expect(Support.ecs_of(relaunched).flags.get_flag(&"beat.intro seen") == true, "a re-boot of the room keeps the run's flags")

	Support.end_suite(self, save_service)
