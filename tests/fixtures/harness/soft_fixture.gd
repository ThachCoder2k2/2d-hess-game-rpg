extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). Only a soft check fails. Expected: exit 0, a WARN line
## and a PASS verdict; the runner promotes the WARN line to a failure in --strict.


func _init() -> void:
	_expect(true, "a passing hard check")
	soft_expect(false, "this soft check fails on purpose")
	finish()
