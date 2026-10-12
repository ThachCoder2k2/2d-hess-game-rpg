extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). It asserts nothing. Expected: exit 1, because a suite
## that checks nothing proves nothing.


func _init() -> void:
	finish()
