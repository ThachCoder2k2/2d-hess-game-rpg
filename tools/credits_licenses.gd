extends RefCounted

## The logic behind the credits' Licenses block (docs/game-base-plan.md 9.2: "the credits include a Licenses section
## generated from THIRD_PARTY_NOTICES.md"), shared by tools/build_credits_licenses.gd (which writes the block) and
## tests/shell/test_credits_licenses_current.gd (which fails when the written block is stale). A helper, not a
## command; no class_name (preload it).
##
## What counts as a credited entry in THIRD_PARTY_NOTICES.md: a `###` heading that has a `- **License:**` bullet
## under it. The entry's name is the heading, its licence is that bullet, and its licence text is the first
## fenced ```text block after the bullet. A `###` entry without a License bullet (a provenance question, a slot
## the owner has not filled yet) is not a credit, so it never reaches a player's screen; neither is any entry
## under a `##` section whose title says "(not shipped)" (build-time tools). The block is flat text, so the
## hard-wrapped paragraphs of the markdown are joined and the label wraps them to its own width.

const NOTICES_PATH := "res://THIRD_PARTY_NOTICES.md"
const OUTPUT_PATH := "res://content/story/credits_licenses.tres"
const SECTION_SCRIPT_PATH := "res://schema/story/credits_section.gd"
## The block's heading is a text key (the row CREDIT_LICENSES_HEADING of story.po); the licence texts below it are
## legal text, drawn as fine print and shown as written in every language.
const SECTION_HEADING_KEY := "CREDIT_LICENSES_HEADING"

const ENTRY_PREFIX := "### "
const SECTION_PREFIX := "## "
const LICENSE_BULLET_PREFIX := "- **License:**"
const FENCE_PREFIX := "```"
## A `##` section title with this in it holds things that are not in the game: nothing under it is credited.
const NOT_SHIPPED_MARKER := "(not shipped)"


## The credited entries of the notices text, in file order: [{"name": String, "license": String, "text": String}],
## where `text` is the licence text, paragraphs separated by one blank line ("" when the entry has none).
static func entries_from(notices_text: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var current: Dictionary = {}
	var in_fence := false
	var fence_taken := false
	var section_is_shipped := true
	var paragraphs: Array[String] = []
	var paragraph_lines: Array[String] = []
	for raw_line in notices_text.split("\n"):
		var line := raw_line.trim_suffix("\r")
		if not in_fence and (line.begins_with(ENTRY_PREFIX) or line.begins_with(SECTION_PREFIX)):
			_finish_entry(entries, current, paragraphs, paragraph_lines)
			current = {}
			paragraphs = []
			paragraph_lines = []
			fence_taken = false
			if line.begins_with(ENTRY_PREFIX):
				if section_is_shipped:
					current = {"name": line.trim_prefix(ENTRY_PREFIX).strip_edges(), "license": "", "text": ""}
			else:
				section_is_shipped = not line.contains(NOT_SHIPPED_MARKER)
			continue
		if current.is_empty():
			continue
		if line.begins_with(FENCE_PREFIX):
			if in_fence:
				in_fence = false
				fence_taken = true
			elif not fence_taken and String(current["license"]) != "":
				in_fence = true
			continue
		if in_fence:
			if line.strip_edges().is_empty():
				_close_paragraph(paragraphs, paragraph_lines)
			else:
				paragraph_lines.append(line.strip_edges())
			continue
		if line.begins_with(LICENSE_BULLET_PREFIX):
			current["license"] = line.trim_prefix(LICENSE_BULLET_PREFIX).strip_edges().trim_suffix(".")
	_finish_entry(entries, current, paragraphs, paragraph_lines)
	return entries


## The lines of the Licenses block for these entries: "<name> - <licence>", the licence text paragraphs, a gap.
static func lines_for(entries: Array[Dictionary]) -> PackedStringArray:
	var lines := PackedStringArray()
	for entry in entries:
		if not lines.is_empty():
			lines.append("")
		lines.append("%s - %s" % [entry["name"], entry["license"]])
		var text := String(entry["text"])
		if not text.is_empty():
			for paragraph in text.split("\n\n"):
				lines.append(paragraph)
	return lines


## The text of the block's .tres. `resource_uid_text` and `script_uid_text` are uid:// strings (the file's own and the
## CreditsSection script's).
static func resource_text(lines: PackedStringArray, resource_uid_text: String, script_uid_text: String) -> String:
	var quoted_lines := PackedStringArray()
	for line in lines:
		quoted_lines.append(_quote(line))
	return "\n".join(PackedStringArray([
		"[gd_resource type=\"Resource\" script_class=\"CreditsSection\" load_steps=2 format=3 uid=\"%s\"]" % resource_uid_text,
		"",
		"[ext_resource type=\"Script\" uid=\"%s\" path=\"%s\" id=\"1\"]" % [script_uid_text, SECTION_SCRIPT_PATH],
		"",
		"[resource]",
		"script = ExtResource(\"1\")",
		"heading = %s" % _quote(SECTION_HEADING_KEY),
		"lines = PackedStringArray(%s)" % ", ".join(quoted_lines),
		"fine_print = true",
		"",
	]))


## The uid:// text in a .tres header, "" when the text has none.
static func header_uid_of(resource_text_value: String) -> String:
	var header := resource_text_value.get_slice("\n", 0)
	var start := header.find("uid=\"")
	if start == -1:
		return ""
	return header.substr(start + 5).get_slice("\"", 0)


static func _finish_entry(entries: Array[Dictionary], current: Dictionary, paragraphs: Array[String], paragraph_lines: Array[String]) -> void:
	if current.is_empty() or String(current["license"]).is_empty():
		return
	_close_paragraph(paragraphs, paragraph_lines)
	current["text"] = "\n\n".join(PackedStringArray(paragraphs))
	entries.append(current)


static func _close_paragraph(paragraphs: Array[String], paragraph_lines: Array[String]) -> void:
	if paragraph_lines.is_empty():
		return
	paragraphs.append(" ".join(PackedStringArray(paragraph_lines)))
	paragraph_lines.clear()


## A string as a .tres literal: quoted, with the backslash, the quote and the line break escaped.
static func _quote(text: String) -> String:
	return "\"%s\"" % text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
