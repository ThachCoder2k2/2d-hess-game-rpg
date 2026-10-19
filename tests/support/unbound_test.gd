class_name UnboundTest
extends SceneTree

## Base class for every suite written from M1a on (docs/game-base-plan.md §13.7).
## The runner (tools/run_all_tests.py) starts each suite as its own Godot process.
##
## A suite extends this class, runs its checks in `_init()` (awaiting frames is
## fine) and ends with `finish()`:
##
##     extends UnboundTest
##
##     func _init() -> void:
##         _expect(1 + 1 == 2, "arithmetic still works")
##         await wait_frames(2)
##         finish()
##
## What this gives a suite that a bare `extends SceneTree` suite does not have:
##  - It cannot hang. A script error inside `_init()` leaves the Godot process
##    running forever; the watchdog fails the suite with exit code 1 instead.
##  - It cannot pass vacuously. `finish()` fails a suite that asserted nothing.
##  - Output that matches the older suites line for line: `PASS: <label>` on
##    stdout, `FAIL: <label>` on stderr, a verdict line, and exit code 0 or 1.
##    The runner's baseline-label manifest therefore treats old and new suites alike.
##
## Two rules for the subclass. Put the checks in `_init()` and do not define
## `_initialize()` (the base class uses it). The subclass `_init()` does not need
## `super()`: GDScript does not run a base `_init()` once the subclass defines its
## own, so everything the base needs happens in `_initialize()` instead, which the
## engine calls after `_init()` returns, even when `_init()` died on a script error.

## Every suite runs in the source language, English (D-25), because this machine's own locale resolves to `en_VN`
## and an owner machine may be set to Vietnamese once the `vi` files have rows. This initialiser runs when the
## script is loaded, before the first line of any suite's `_init()`; a suite that tests another language
## switches itself and switches back.
static var source_language_is_set := _set_source_language()

## Seconds a suite may run before the watchdog fails it, unless the suite sets
## `watchdog_seconds`.
const DEFAULT_WATCHDOG_SECONDS := 30.0

## The watchdog limit armed once `_init()` has returned. A suite that legitimately
## needs longer sets it at the top of `_init()`, keeping the runner's 60 s process
## timeout in mind.
var watchdog_seconds := DEFAULT_WATCHDOG_SECONDS

## Heading of the verdict line (`<heading>: PASS`). Leave it empty to use the
## suite's file name in capitals, for example `TEST REQUIREMENTS LEDGER`; set it
## in `_init()` to choose another.
var suite_title := ""

## Hard failures so far; any of them makes the suite exit 1.
var failures := 0

## Soft failures so far (`soft_expect`). They print `WARN:` and do not fail the
## suite on their own; the runner turns them into failures under `--strict`.
var soft_warnings := 0

## Checks run so far, passing or failing. Zero at `finish()` fails the suite.
var assertion_count := 0

var _is_finished := false

## Bumped by every `arm_watchdog` call so that only the latest timer can fire.
var _watchdog_generation := 0


static func _set_source_language() -> bool:
	return TextService.set_language(TextService.SOURCE_LANGUAGE)


## Called by the engine once the subclass `_init()` has returned or aborted.
## Arms the watchdog with `watchdog_seconds` unless `_init()` already armed one.
func _initialize() -> void:
	if _watchdog_generation == 0 and not _is_finished:
		arm_watchdog(watchdog_seconds)


## Hard check. A false condition prints `FAIL: <label>` and fails the suite.
## Returns the condition so callers can skip dependent checks.
func _expect(condition: bool, label: String) -> bool:
	assertion_count += 1
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)
	return condition


## Soft check for content quality that the owner's rewrites must never turn red
## (word counts, emotion fields, budgets). A false condition prints
## `WARN: <label>`; a true one prints `PASS: <label>` like a hard check.
func soft_expect(condition: bool, label: String) -> bool:
	assertion_count += 1
	if condition:
		print("PASS: %s" % label)
	else:
		soft_warnings += 1
		print("WARN: %s" % label)
	return condition


## Hard precondition that stays silent when it holds, so helpers such as
## `TestPaths` can assert on every call without flooding the output (and the
## baseline manifest) with PASS lines. A false condition fails like `_expect`.
func require(condition: bool, label: String) -> bool:
	assertion_count += 1
	if not condition:
		failures += 1
		printerr("FAIL: %s" % label)
	return condition


## Waits `frame_count` process frames (default one), the usual way for a suite
## to let queued frees, deferred calls and signals settle. Use as
## `await wait_frames(3)`.
func wait_frames(frame_count: int = 1) -> void:
	for _frame in range(frame_count):
		await process_frame


## Starts the watchdog now with a new limit, replacing any earlier one. The engine
## hook above arms it for you; call this only to restart the clock between long phases.
func arm_watchdog(seconds: float) -> void:
	_watchdog_generation += 1
	var generation := _watchdog_generation
	# process_always and ignore_time_scale: neither a paused tree nor a test that
	# sets Engine.time_scale may stall the watchdog.
	create_timer(seconds, true, false, true).timeout.connect(_on_watchdog_expired.bind(generation, seconds))


## Prints the verdict and quits: exit 0 when every hard check passed, else 1.
## Only the first call counts, so a late watchdog or a second call is harmless.
func finish() -> void:
	if _is_finished:
		return
	_is_finished = true
	if assertion_count == 0:
		failures += 1
		printerr("FAIL: the suite made no assertions, so it proves nothing")
	var succeeded := failures == 0
	print("%s: %s" % [_verdict_heading(), "PASS" if succeeded else "FAIL (%d)" % failures])
	quit(0 if succeeded else 1)


func _on_watchdog_expired(generation: int, seconds: float) -> void:
	if _is_finished or generation != _watchdog_generation:
		return
	_is_finished = true
	failures += 1
	printerr("FAIL: watchdog expired after %.1f s; %s never reached finish() (a script error or a stuck await)" % [seconds, _verdict_heading()])
	print("%s: FAIL (%d)" % [_verdict_heading(), failures])
	quit(1)


func _verdict_heading() -> String:
	if not suite_title.is_empty():
		return suite_title
	var suite_script := get_script() as Script
	if suite_script == null or suite_script.resource_path.is_empty():
		return "UNBOUND TEST"
	return suite_script.resource_path.get_file().get_basename().replace("_", " ").to_upper()
