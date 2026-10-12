extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). It awaits a timer that will not fire within the test
## and never reaches finish(). Expected: the watchdog quits it with exit 1 after
## about 1.5 s instead of hanging the process.


func _init() -> void:
	arm_watchdog(1.5)
	_expect(true, "the suite started")
	await create_timer(3600.0).timeout
	finish()
