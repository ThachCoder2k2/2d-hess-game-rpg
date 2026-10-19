extends UnboundTest

## The credits and THIRD_PARTY_NOTICES.md are one fact in two places (docs/game-base-plan.md 9.2: "the credits include
## a Licenses section generated from THIRD_PARTY_NOTICES.md"). tools/build_credits_licenses.gd writes the block
## (content/story/credits_licenses.tres) with the rules of tools/credits_licenses.gd; this suite proves
##   - the rules, on sample notices (which entry is credited, how its text is joined, what is ignored);
##   - the written block is exactly what the tool would write now, so editing the notices without running the tool
##     fails here ("stale"), and the file's text, not only its lines, is current;
##   - every credited entry of the real notices is in the roll the credits scene shows, next to the owner and the engine.

const Licenses := preload("res://tools/credits_licenses.gd")

const SAMPLE := """# Third-Party Notices

## Needs the owner's check

### A question about provenance

- **What:** something with no licence bullet.

## Third-party software that ships or is required

### Alpha Engine

- **What:** the engine.
- **License:** MIT.

```text
Copyright (c) 2020 Alpha.
Second line of the same paragraph.

Permission is granted. "As is".
```

```text
A second fence is not the licence text.
```

- **TODO:** nothing.

### Beta Font

- **License:** SIL OFL 1.1

### Gamma Tool
- **What:** no licence bullet either.

## Build-time tools (not shipped)

### Delta Builder
- **License:** BSD
```text
Delta text.
```
"""


func _init() -> void:
	suite_title = "CREDITS LICENSES CURRENT TEST"
	_the_rules_on_a_sample()
	_the_written_block_is_current()
	_every_credited_entry_is_in_the_roll()
	finish()


func _the_rules_on_a_sample() -> void:
	var entries := Licenses.entries_from(SAMPLE)
	var names: Array[String] = []
	for entry in entries:
		names.append(String(entry["name"]))
	_expect(names == ["Alpha Engine", "Beta Font"], "an entry with a License bullet is credited, one without is not, and nothing under a (not shipped) section is (%s)" % ", ".join(PackedStringArray(names)))
	_expect(entries.size() == 2 and entries[0]["license"] == "MIT" and entries[1]["license"] == "SIL OFL 1.1", "the licence is the bullet's text without its closing full stop")
	_expect(entries[0]["text"] == "Copyright (c) 2020 Alpha. Second line of the same paragraph.\n\nPermission is granted. \"As is\".", "the licence text is the first fenced block, hard-wrapped lines joined into paragraphs")
	_expect(entries[1]["text"] == "", "an entry with no fenced text has no text")
	var lines := Licenses.lines_for(entries)
	_expect(lines == PackedStringArray(["Alpha Engine - MIT", "Copyright (c) 2020 Alpha. Second line of the same paragraph.", "Permission is granted. \"As is\".", "", "Beta Font - SIL OFL 1.1"]), "the block's lines: name and licence, the paragraphs, a gap between entries (%s)" % str(lines))
	var text := Licenses.resource_text(PackedStringArray(["a \"quoted\" line", "back\\slash"]), "uid://aaa", "uid://bbb")
	_expect(text.contains("lines = PackedStringArray(\"a \\\"quoted\\\" line\", \"back\\\\slash\")") and text.contains("script_class=\"CreditsSection\"") and text.contains("uid=\"uid://aaa\"") and text.contains("fine_print = true"), "the .tres escapes quotes and backslashes and carries both uids")
	_expect(Licenses.header_uid_of(text) == "uid://aaa" and Licenses.header_uid_of("no header here") == "", "the file's own uid is read back from its header")
	_expect(Licenses.entries_from("").is_empty() and Licenses.entries_from("### Only a heading\n").is_empty(), "no notices, no credits")


func _the_written_block_is_current() -> void:
	var notices_text := FileAccess.get_file_as_string(Licenses.NOTICES_PATH)
	_expect(not notices_text.is_empty(), "THIRD_PARTY_NOTICES.md is readable")
	var entries := Licenses.entries_from(notices_text)
	_expect(entries.size() >= 1 and "Godot Engine" in entries.map(func(entry: Dictionary) -> String: return entry["name"]), "the real notices credit at least the engine (%d entries)" % entries.size())
	var expected_lines := Licenses.lines_for(entries)
	var block := load(Licenses.OUTPUT_PATH) as CreditsSection
	_expect(block != null, "content/story/credits_licenses.tres loads as a CreditsSection")
	if block == null:
		return
	_expect(block.heading == Licenses.SECTION_HEADING and block.fine_print, "it is the Licenses block, drawn as fine print")
	_expect(block.lines == expected_lines, "its lines are exactly what THIRD_PARTY_NOTICES.md says now (stale? run tools/build_credits_licenses.gd)")
	var written_text := FileAccess.get_file_as_string(Licenses.OUTPUT_PATH)
	var script_uid_text := FileAccess.get_file_as_string(Licenses.SECTION_SCRIPT_PATH + ".uid").strip_edges()
	var expected_text := Licenses.resource_text(expected_lines, Licenses.header_uid_of(written_text), script_uid_text)
	_expect(written_text == expected_text, "and the file's text is byte for byte what the tool writes, so its --check is clean")
	_expect(block.validate().is_empty(), "the block passes its own validate()")


func _every_credited_entry_is_in_the_roll() -> void:
	var credits := ContentDb.credits()
	_expect(credits != null and credits.validate().is_empty(), "content/story/credits.tres loads and passes its own validate() (%s)" % ("" if credits == null else "; ".join(credits.validate())))
	if credits == null:
		return
	var all_lines: Array[String] = []
	var headings: Array[String] = []
	for section in credits.sections:
		headings.append(section.heading)
		all_lines.append_array(Array(section.lines))
	_expect("Design, story and art" in headings and "Made with" in headings and "Licenses" in headings, "the roll has the owner's block, the engine's block and the licences (%s)" % ", ".join(PackedStringArray(headings)))
	_expect("The owner" in all_lines, "the owner is credited")
	_expect("Godot Engine 4.6" in all_lines, "the engine is credited")
	var every_entry_credited := true
	for entry in Licenses.entries_from(FileAccess.get_file_as_string(Licenses.NOTICES_PATH)):
		every_entry_credited = every_entry_credited and ("%s - %s" % [entry["name"], entry["license"]]) in all_lines
	_expect(every_entry_credited, "every credited entry of THIRD_PARTY_NOTICES.md is in the roll")
	_expect(credits.sections[credits.sections.size() - 1].heading == "Licenses", "and the licences come last")
