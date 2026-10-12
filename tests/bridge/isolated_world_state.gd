extends "res://shell/save/world_state.gd"

## Test double for the WorldState autoload used by the test_bridge_* suites.
## scripts/main.gd calls save_state() with no argument, so the real autoload
## would write the player's own save file (user://world_state.cfg) every time
## a bridge test travels, dies or picks something up. This subclass redirects
## every default-path save and load to a throwaway file instead. The bridge
## and WorldState logic under test stay the real code (super is called).

## Absolute path of the throwaway save file for this test process.
var isolated_save_path := ""


func save_state(path := "") -> void:
	super(path if not path.is_empty() else isolated_save_path)


func load_state(path := "") -> void:
	super(path if not path.is_empty() else isolated_save_path)
