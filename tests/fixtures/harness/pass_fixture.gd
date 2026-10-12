extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). Everything passes. Expected: exit 0, PASS lines, a
## PASS verdict, no WARN and no FAIL.


func _init() -> void:
	_expect(true, "a hard check passes")
	soft_expect(true, "a soft check passes")
	await wait_frames(2)
	_expect(true, "a check after awaited frames still counts")
	finish()
