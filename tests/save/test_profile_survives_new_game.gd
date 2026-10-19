extends UnboundTest

## The profile (`<root>/profile.cfg`, docs/game-base-plan.md 8.8, 9.1) holds what outlives a slot: today the
## `completed` mark that keeps the title's post-game board after a New Game. It is a separate file from
## the slot, written by the same safe writer (a .bak, a temp file, an integrity footer), and a New Game,
## a slot save or a slot load never touches it.

const SaveSupport := preload("res://tests/support/save_test_support.gd")

var roots_to_remove: Array[String] = []


func _init() -> void:
	suite_title = "PROFILE SURVIVES NEW GAME TEST"
	var root_directory := SaveSupport.make_root("profile")
	roots_to_remove.append(root_directory)
	var service := SaveSupport.new_service(root_directory)
	_expect(not service.is_completed() and service.read_profile().is_empty() and not FileAccess.file_exists(service.profile_path()), "a player who has not finished the game has no profile file")

	_expect(service.profile_path() == root_directory + "/profile.cfg", "the profile is <root>/profile.cfg, next to the saves folder and not in it")
	service.new_game(0)
	service.state.taken_pickup_ids["a/b"] = true
	service.request_save(&"pickup_taken")
	_expect(not FileAccess.file_exists(service.profile_path()), "saving a slot does not write the profile")

	_expect(service.mark_completed() == OK and service.is_completed(), "reaching the ending writes the completed mark")
	var plain := ConfigFile.new()
	_expect(plain.load(service.profile_path()) == OK and plain.get_value("profile", "completed", false) == true and int(plain.get_value("meta", "version", 0)) == 1, "as a ConfigFile with a versioned [meta] and a [profile] section")
	_expect(SaveFile.read(service.profile_path()).is_readable(), "with the same integrity footer as a slot")

	service.new_game(0)
	service.state.taken_pickup_ids["c/d"] = true
	service.request_save(&"pickup_taken")
	_expect(service.is_completed(), "a New Game over the used slot leaves the completed mark")
	var after_restart := SaveSupport.new_service(root_directory)
	after_restart.load_slot(0)
	_expect(after_restart.is_completed() and not after_restart.state.taken_pickup_ids.has("a/b") and after_restart.state.taken_pickup_ids.has("c/d"), "and a relaunch reads the new run with the mark still set")

	_expect(service.set_profile_value(&"first_run_done", true) == OK and service.read_profile().get("first_run_done") == true and service.is_completed(), "another profile value is added beside it")
	_expect(FileAccess.file_exists(service.profile_path() + ".bak"), "every profile write keeps the one before it as a .bak")

	var newer := ConfigFile.new()
	newer.set_value("meta", "version", 7)
	newer.set_value("profile", "completed", true)
	newer.set_value("profile", "a_future_thing", 1)
	var newer_text := SaveFile.encode(newer)
	var newer_root := SaveSupport.make_root("profile_newer")
	roots_to_remove.append(newer_root)
	SaveSupport.plant(newer_root + "/profile.cfg", newer_text)
	var newer_service := SaveSupport.new_service(newer_root)
	_expect(newer_service.set_profile_value(&"completed", true) == ERR_LOCKED and SaveSupport.text_of(newer_root + "/profile.cfg") == newer_text, "a profile from a newer game is never overwritten")

	for root_to_remove in roots_to_remove:
		SaveSupport.remove_root(root_to_remove)
	finish()
