extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). A runtime script error aborts _init() before finish(),
## which leaves a bare SceneTree suite running forever. Expected: the engine
## prints the script error and the watchdog that the base class arms after
## _init() (here with a shortened limit) quits with exit 1 after about 1.5 s.


func _init() -> void:
	watchdog_seconds = 1.5
	_expect(true, "the suite started")
	var nothing: Node = null
	nothing.queue_free()
	finish()
