class_name LiveText
extends Node

## Keeps the words a script put on screen in the language the player chose (docs/game-base-plan.md 8.9: a language
## switch redraws live). TextService handles the language; this node handles the screen: it is a child of the
## screen, HUD or menu that shows the text, it remembers WHICH KEY and WHICH PARAMS each control shows, and when the
## engine says the language changed (NOTIFICATION_TRANSLATION_CHANGED reaches every node in the tree) it asks
## TextService again for each of them.
##
## Text a scene authored (a Label whose `text` is a key) needs none of this: the engine translates it and redraws
## it by itself. LiveText is for what a script sets: a line with numbers in it, a sentence a bridge picked, a
## list built from data. Two ways to use it:
##   - set_text(control, key, params): the control's `text` is the key's words now and after every language change;
##   - on_language_change(redraw): a Callable called after every language change, for a screen that builds its
##     contents from data (an ItemList, the credits roll) and rebuilds them.
##
## Add it as a child in the presenter's _ready(): `live_text = LiveText.new(); add_child(live_text)`.

## Called with no arguments after the language changed and the bound texts were resolved again.
var _redraws: Array[Callable] = []
## control -> { "key": String, "params": Dictionary }. A control freed since is dropped on the next refresh.
var _binding_by_control: Dictionary = {}


## Puts the words of `key` on `control` (any control with a `text`: Label, Button, RichTextLabel...) and keeps them
## there through language changes. Setting it again replaces what the control was bound to.
func set_text(control: Control, key: String, params: Dictionary = {}) -> void:
	_binding_by_control[control] = {"key": key, "params": params}
	control.set(&"text", TextService.t(key, params))


## Stops following `control` and leaves its text as it is.
func release(control: Control) -> void:
	_binding_by_control.erase(control)


## Calls `redraw` after every language change, once the bound texts are resolved again.
func on_language_change(redraw: Callable) -> void:
	_redraws.append(redraw)


## The key `control` is bound to, "" when it is not bound.
func key_of(control: Control) -> String:
	return String(_binding_by_control.get(control, {}).get("key", ""))


## Resolves every bound text again and calls the redraw callables. The engine's notification calls it; a screen
## that is not in the tree (a test) calls it itself.
func refresh() -> void:
	for bound_control: Variant in _binding_by_control.keys():
		if not is_instance_valid(bound_control):
			_binding_by_control.erase(bound_control)
			continue
		var binding: Dictionary = _binding_by_control[bound_control]
		(bound_control as Control).set(&"text", TextService.t(binding["key"], binding["params"]))
	for redraw in _redraws:
		if redraw.is_valid():
			redraw.call()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh()
