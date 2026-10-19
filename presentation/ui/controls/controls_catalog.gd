class_name ControlsCatalog
extends RefCounted

## What the Controls panel calls each action, and in what order and page it lists them (docs/game-base-plan.md 9.2
## "Controls": a panel built from the live InputMap). The BINDINGS are not here: they are read from the InputMap when the
## panel opens, so a key the owner rebinds in project.godot (or a test adds) shows up with no change to this file. This
## is only the part the InputMap cannot say: a name in words, a page, an order, and which actions do nothing yet.
##
## An action the InputMap has and this table does not know is not lost: the panel lists it on the last page under its
## own name, and tests/input/test_controls_panel_from_inputmap.gd fails so the table gets a row.

## The pages of the panel, in tab order.
enum Group {
	MOVING,
	ACTING,
	GAME,
}

## group -> the text key of its tab.
const TAB_KEY_BY_GROUP := {
	Group.MOVING: "UI_CONTROLS_TAB_MOVING",
	Group.ACTING: "UI_CONTROLS_TAB_ACTING",
	Group.GAME: "UI_CONTROLS_TAB_GAME",
}

## The listed actions, in the order they are shown: the action, the text key of its name, and its page.
const ACTIONS: Array[Dictionary] = [
	{"action": &"move_up", "name_key": "UI_ACTION_MOVE_UP", "group": Group.MOVING},
	{"action": &"move_down", "name_key": "UI_ACTION_MOVE_DOWN", "group": Group.MOVING},
	{"action": &"move_left", "name_key": "UI_ACTION_MOVE_LEFT", "group": Group.MOVING},
	{"action": &"move_right", "name_key": "UI_ACTION_MOVE_RIGHT", "group": Group.MOVING},
	{"action": &"turn_mode", "name_key": "UI_ACTION_TURN_MODE", "group": Group.MOVING},
	{"action": &"free_step", "name_key": "UI_ACTION_FREE_STEP", "group": Group.MOVING},
	{"action": &"attack", "name_key": "UI_ACTION_ATTACK", "group": Group.ACTING},
	{"action": &"skill_slot_1", "name_key": "UI_ACTION_SKILL_SLOT_1", "group": Group.ACTING},
	{"action": &"skill_slot_2", "name_key": "UI_ACTION_SKILL_SLOT_2", "group": Group.ACTING},
	{"action": &"guard", "name_key": "UI_ACTION_GUARD", "group": Group.ACTING},
	{"action": &"focus", "name_key": "UI_ACTION_FOCUS", "group": Group.ACTING},
	{"action": &"call_child", "name_key": "UI_ACTION_CALL_CHILD", "group": Group.ACTING},
	{"action": &"help_next", "name_key": "UI_ACTION_HELP_NEXT", "group": Group.ACTING},
	{"action": &"interact", "name_key": "UI_ACTION_INTERACT", "group": Group.ACTING},
	{"action": &"pause", "name_key": "UI_ACTION_PAUSE", "group": Group.GAME},
	{"action": &"rule_book_toggle", "name_key": "UI_ACTION_RULE_BOOK_TOGGLE", "group": Group.GAME},
	{"action": &"dialogue_advance", "name_key": "UI_ACTION_DIALOGUE_ADVANCE", "group": Group.GAME},
	{"action": &"debug_view_toggle", "name_key": "UI_ACTION_DEBUG_VIEW_TOGGLE", "group": Group.GAME},
	{"action": &"fullscreen_toggle", "name_key": "UI_ACTION_FULLSCREEN_TOGGLE", "group": Group.GAME},
	{"action": &"skill_slot_3", "name_key": "UI_ACTION_SKILL_SLOT_3", "group": Group.ACTING},
	{"action": &"skill_slot_4", "name_key": "UI_ACTION_SKILL_SLOT_4", "group": Group.ACTING},
]

## Actions declared in the InputMap that the panel does not list: nothing uses them yet and the HUD hides an empty skill
## slot (9.4), so a row would only be noise.
const HIDDEN_ACTIONS: Array[StringName] = [&"skill_slot_3", &"skill_slot_4"]

## Actions whose key exists and does nothing the player can see yet. The panel says so beside them, so a press that
## seems to be ignored is not taken for a broken key. Each leaves the list when the milestone named gives it a job.
const COMING_LATER_ACTIONS: Array[StringName] = [
	&"call_child",  # M10: the child's help (D-18 moved it onto R)
	&"skill_slot_2",  # M7a: Rule Step
	&"guard",  # M8a
	&"focus",  # M8a
	&"help_next",  # M7a: the next help
	&"free_step",  # M7b: the diagonal modifier
	&"interact",  # M6: rescues and the story's objects
	&"dialogue_advance",  # M6: the story engine
]

## The text key of an action's name with the note that it does nothing yet: "{name} (coming later)".
const COMING_LATER_KEY := "UI_CONTROLS_ACTION_COMING_LATER"


## The listed rows of one page, in order. Each row: "action", "name_key", "group".
static func rows_of(group: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in ACTIONS:
		if int(row["group"]) == group and row["action"] not in HIDDEN_ACTIONS:
			rows.append(row)
	return rows


## The InputMap actions the panel should list but this table has no row for (the engine's own ui_ actions are not the
## game's controls and are never listed). Empty when the table is complete.
static func unlisted_actions() -> Array[StringName]:
	var known: Array[StringName] = []
	for row in ACTIONS:
		known.append(row["action"])
	var missing: Array[StringName] = []
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_") or action in known:
			continue
		missing.append(action)
	return missing


## Whether `action` does nothing the player can see yet.
static func is_coming_later(action: StringName) -> bool:
	return action in COMING_LATER_ACTIONS
