extends UnboundTest

## Tests the test harness itself (UnboundTest and TestPaths). Each fixture under
## tests/fixtures/harness/ is a tiny suite that misbehaves in exactly one way. It
## runs in a child Godot process, the way the runner runs every suite, and this
## suite checks what the runner would see: the exit code and the printed lines.
## If the watchdog stops firing, an empty suite starts passing, or a stale path
## stops failing, this suite goes red.

## A fixture with a watchdog of about 1.5 s must be gone well before this.
const WATCHDOG_FIXTURE_LIMIT_SECONDS := 20.0


func _init() -> void:
	suite_title = "HARNESS SELF-TEST"
	var paths := TestPaths.new(self)

	var passing := _run_fixture(paths, "pass_fixture")
	_expect(passing["exit_code"] == 0, "a suite whose checks all pass exits 0")
	_expect(_has_line(passing, "PASS: a hard check passes"), "a passing hard check prints 'PASS: <label>'")
	_expect(_has_line(passing, "PASS: a soft check passes"), "a passing soft check prints 'PASS: <label>' too")
	_expect(_has_line(passing, "PASS: a check after awaited frames still counts"), "wait_frames lets a suite continue after awaiting")
	_expect(_has_line(passing, "PASS FIXTURE: PASS"), "the verdict line is '<TITLE FROM FILE NAME>: PASS'")
	_expect(not _has_line_starting(passing, "FAIL:") and not _has_line_starting(passing, "WARN:"), "a clean suite prints no FAIL or WARN line")

	var failing := _run_fixture(paths, "fail_fixture")
	_expect(failing["exit_code"] == 1, "a failing hard check makes the suite exit 1")
	_expect(_has_line(failing, "FAIL: this hard check fails on purpose"), "a failing hard check prints 'FAIL: <label>'")
	_expect(_has_line(failing, "FAIL FIXTURE: FAIL (1)"), "the verdict line counts the failures")

	var soft := _run_fixture(paths, "soft_fixture")
	_expect(soft["exit_code"] == 0, "a failing soft check alone leaves the exit code 0")
	_expect(_has_line(soft, "WARN: this soft check fails on purpose"), "a failing soft check prints 'WARN: <label>' for the runner's --strict")
	_expect(_has_line(soft, "SOFT FIXTURE: PASS"), "a soft failure does not change the verdict")

	var empty := _run_fixture(paths, "empty_fixture")
	_expect(empty["exit_code"] == 1, "a suite that asserts nothing fails instead of passing vacuously")
	_expect(_has_line_starting(empty, "FAIL: the suite made no assertions"), "the empty suite says why it failed")

	var hanging := _run_fixture(paths, "hang_fixture")
	_expect(hanging["exit_code"] == 1, "a suite stuck on an await is quit by the watchdog with exit 1")
	_expect(hanging["seconds"] < WATCHDOG_FIXTURE_LIMIT_SECONDS, "the watchdog fires on time, not at the runner's timeout")
	_expect(_has_line_starting(hanging, "FAIL: watchdog expired"), "the watchdog says it fired")
	_expect(_has_line(hanging, "HANG FIXTURE: FAIL (1)"), "the watchdog still prints a verdict line")

	var broken := _run_fixture(paths, "broken_init_fixture")
	_expect(broken["exit_code"] == 1, "a runtime script error in _init() ends in exit 1 through the watchdog")
	_expect(String(broken["output"]).contains("SCRIPT ERROR"), "the engine reported the runtime error the runner searches for")
	_expect(_has_line_starting(broken, "FAIL: watchdog expired"), "the watchdog, not luck, ended the process")

	var stale := _run_fixture(paths, "stale_paths_fixture")
	_expect(stale["exit_code"] == 1, "stale, blank and unlisted paths fail the suite")
	_expect(_has_line(stale, "FAIL: file exists: res://docs/a_file_that_was_moved.md"), "reading a moved file fails instead of returning an empty string")
	_expect(_has_line(stale, "FAIL: file has content: res://tests/fixtures/harness/empty.txt"), "reading a blank file fails")
	_expect(_has_line_starting(stale, "FAIL: at least 1 .an_extension_nothing_has file(s)"), "a listing that finds fewer files than the minimum fails")
	_expect(_has_line(stale, "FAIL: scene exists: res://scenes/a_scene_that_was_moved.tscn"), "loading a moved scene fails without calling load()")
	_expect(_has_line(stale, "STALE PATHS FIXTURE: FAIL (4)"), "each stale lookup is exactly one failure")

	_expect(paths.list_files(paths.rooms_directory(), "tscn", 6).size() >= 6, "list_files finds the Stage 1 room scenes")
	_expect(not paths.read_text(paths.requirements_json()).is_empty(), "read_text returns the content of a real file")

	finish()


## Runs one fixture suite in a child Godot process and returns
## {"exit_code": int, "output": String, "seconds": float}. Stdout and stderr are
## merged, as the runner reads them. The child inherits this process's HOME.
func _run_fixture(paths: TestPaths, fixture_name: String) -> Dictionary:
	var output: Array = []
	var started_msec := Time.get_ticks_msec()
	var arguments := PackedStringArray(["--headless", "--path", paths.project_directory_on_disk(), "-s", paths.harness_fixture(fixture_name)])
	var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true)
	var combined := "".join(PackedStringArray(output))
	return {
		"exit_code": exit_code,
		"output": combined,
		"seconds": float(Time.get_ticks_msec() - started_msec) / 1000.0,
	}


func _output_lines(result: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	for line in String(result["output"]).split("\n"):
		lines.append(line.strip_edges())
	return lines


func _has_line(result: Dictionary, wanted_line: String) -> bool:
	return _output_lines(result).has(wanted_line)


func _has_line_starting(result: Dictionary, prefix: String) -> bool:
	for line in _output_lines(result):
		if line.begins_with(prefix):
			return true
	return false
