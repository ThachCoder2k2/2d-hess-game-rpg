extends UnboundTest

## Harness fixture, run only by tests/support/test_unbound_test.gd (never
## discovered as a suite). It deliberately names paths that are stale or blank,
## which is the one reason a test may spell a res:// path outside paths.gd.
## Expected: every lookup fails the suite (exit 1, "FAIL (4)") instead of
## returning an empty string that a content check would then accept.


func _init() -> void:
	var paths := TestPaths.new(self)
	paths.read_text("res://docs/a_file_that_was_moved.md")
	paths.read_text("res://tests/fixtures/harness/empty.txt")
	paths.list_files("res://tests/fixtures/harness", "an_extension_nothing_has")
	paths.load_scene("res://scenes/a_scene_that_was_moved.tscn")
	finish()
