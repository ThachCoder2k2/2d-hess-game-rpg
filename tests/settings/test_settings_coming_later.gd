extends UnboundTest

## The settings screen does not offer a control that changes nothing without saying so (docs/game-base-plan.md 9.2, D-22;
## the review of M4 found four assists and two press-to-switch options that reached `world.tuning` or the input poller and
## that no system read, with no sign of it on screen). The rule held here:
##   1. THE MARK AND THE CODE AGREE. A setting that goes through the simulation (an assist, through a `world.tuning` field;
##      a press-to-switch, through an InputMap action) is marked `coming_later` exactly when no system under ecs/systems/
##      reads that field or that action. The day a system reads one, this suite fails until the mark is taken off.
##   2. NO MARK ON A SETTING THAT WORKS. Every other setting (the volumes, the window, the language, the shake, the flashing,
##      the danger look) is proved by its own `test_setting_*` suite, and none is marked.
##   3. THE SCREEN SAYS IT. A marked setting's row carries "(coming later)" at its end; an unmarked row carries nothing.
##      The Controls panel does the same for an action (ControlsCatalog.COMING_LATER_ACTIONS).

const SYSTEMS_FOLDER := "res://ecs/systems"
const SCREEN_SCENE := "res://shell/settings/settings_screen.tscn"


func _init() -> void:
	suite_title = "SETTINGS COMING LATER TEST"
	call_deferred("_run")


func _run() -> void:
	var system_sources := _sources_under(SYSTEMS_FOLDER)
	_expect(system_sources.length() > 10000, "setup: the systems' source was read (%d characters)" % system_sources.length())

	var neutral := Tuning.new()
	var through_the_simulation := {}
	for key: StringName in SettingsBridge.TUNING_KNOB_BY_ASSIST:
		var knob: StringName = SettingsBridge.TUNING_KNOB_BY_ASSIST[key]
		_expect(neutral.get(knob) != null, "%s sets world.tuning's %s, which exists" % [key, knob])
		through_the_simulation[key] = "tuning.%s" % knob
	for key: StringName in SettingsBridge.TOGGLED_ACTION_BY_SETTING:
		through_the_simulation[key] = "&\"%s\"" % SettingsBridge.TOGGLED_ACTION_BY_SETTING[key]

	for definition in GameSettings.definitions():
		if through_the_simulation.has(definition.key):
			var needle: String = through_the_simulation[definition.key]
			var has_reader := system_sources.contains(needle)
			_expect(definition.coming_later == not has_reader, "%s is %s and a system %s %s" % [definition.key, "marked coming later" if definition.coming_later else "not marked", "reads" if has_reader else "does not read", needle])
		else:
			_expect(not definition.coming_later, "%s is proved by its own suite and is not marked coming later" % definition.key)

	var screen := (load(SCREEN_SCENE) as PackedScene).instantiate() as SettingsScreen
	root.add_child(screen)
	screen.configure(GameSettings.new())
	screen.open()
	await process_frame
	var coming_later_text := TextService.t(SettingsScreen.COMING_LATER_KEY)
	_expect(coming_later_text == "(coming later)", "the note reads (coming later) (%s)" % coming_later_text)
	var marked_count := 0
	for definition in GameSettings.definitions():
		var row := screen.control_of(definition.key).get_parent()
		var notes: Array[String] = []
		for sibling in row.get_children():
			if sibling is Label and (sibling as Label).text == coming_later_text:
				notes.append((sibling as Label).text)
		_expect(notes.size() == (1 if definition.coming_later else 0), "%s: its row carries the note exactly when it is marked (%d)" % [definition.key, notes.size()])
		marked_count += 1 if definition.coming_later else 0
	_expect(marked_count == 6, "six settings are marked today: the four assists and press-to-switch Guard and Focus (%d)" % marked_count)
	screen.queue_free()
	await process_frame
	finish()


## Every .gd file under `folder`, one string.
func _sources_under(folder: String) -> String:
	var text := ""
	var directory := DirAccess.open(folder)
	if directory == null:
		return text
	for file_name in directory.get_files():
		if file_name.ends_with(".gd"):
			text += FileAccess.get_file_as_string(folder.path_join(file_name)) + "\n"
	for sub_folder in directory.get_directories():
		text += _sources_under(folder.path_join(sub_folder))
	return text
