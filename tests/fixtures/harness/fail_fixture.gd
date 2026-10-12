extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). One hard check fails. Expected: exit 1, a FAIL line on
## stderr and a "FAIL (1)" verdict.


func _init() -> void:
	_expect(true, "a passing check")
	_expect(false, "this hard check fails on purpose")
	finish()
