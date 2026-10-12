extends RefCounted

## The one place that knows what content/_placeholders.json is and how to read it
## (docs/game-base-plan.md section 12). Shared by tools/seed_placeholders.gd (writes it),
## tools/list_placeholders.gd (prints the owner's TODO from it) and
## tests/content/test_placeholders_manifest.gd (proves it parses and every file exists).
## There is no class_name on purpose: callers preload() this script, which keeps it usable
## on a fresh checkout before the editor import pass has run.
##
## The rule, in one sentence: a file is a placeholder if and only if its sha256 still equals
## the hash recorded here when it was seeded. The owner overwrites the file (same name, same
## role) and the flag clears by itself; a flag kept anywhere else would go stale.
##
## Manifest shape (one entry per line so a diff shows exactly which file changed):
##   { "format": 1, "about": "...", "placeholders": [
##       { "path": "res://...", "kind": "body", "id": "pawn_recruit", "sha256": "...", "origin": "..." }, ... ] }

const MANIFEST_PATH := "res://content/_placeholders.json"
const FORMAT_VERSION := 1

const STATUS_PLACEHOLDER := "placeholder"
const STATUS_REPLACED := "replaced"
const STATUS_MISSING := "missing"

const SHA256_HEX_LENGTH := 64
## Keys every entry must carry, all strings.
const REQUIRED_ENTRY_KEYS: Array[String] = ["path", "kind", "id", "sha256", "origin"]

## What each kind of placeholder is, in the order the owner's TODO lists them. A kind that is
## not here is still listed, after these, so a new kind never hides. Plan section 12 names the
## file each kind is replaced by.
const KIND_ORDER: Array[String] = ["body", "icon", "pickup", "background", "tileset", "ui", "sfx", "music"]
const KIND_LABEL_BY_KIND := {
	"body": "character and enemy pictures (content/<kind>/<id>/body.png)",
	"icon": "skill, item and project icons (icon.png)",
	"pickup": "pickup pictures (pickup.png)",
	"background": "room art (content/rooms/<id>/background.png)",
	"tileset": "tile atlases (assets/tiles/<district>/atlas.*)",
	"ui": "shared interface pictures (assets/ui/)",
	"sfx": "sound effects (assets/sfx/)",
	"music": "music (assets/music/)",
}

const MANIFEST_ABOUT := "Every file listed here stands in for art or audio the owner will supply. A file is a placeholder while its sha256 still equals the hash recorded here; overwrite the file (same name, same role) and it leaves the list by itself. tools/list_placeholders.gd prints what is left. Written by tools/seed_placeholders.gd; do not edit a hash by hand."


## Reads and checks the manifest. Returns { "entries": Array[Dictionary], "error": String }.
## `error` is empty when the file exists, parses, has the right format and every entry is
## well formed (see `entry_problem`); otherwise it says what is wrong and `entries` is empty.
static func read_manifest(manifest_path: String = MANIFEST_PATH) -> Dictionary:
	var no_entries: Array[Dictionary] = []
	if not FileAccess.file_exists(manifest_path):
		return {"entries": no_entries, "error": "%s does not exist (run tools/seed_placeholders.gd)" % manifest_path}
	var manifest_text := FileAccess.get_file_as_string(manifest_path)
	if manifest_text.strip_edges().is_empty():
		return {"entries": no_entries, "error": "%s is empty" % manifest_path}
	var parser := JSON.new()
	if parser.parse(manifest_text) != OK:
		return {"entries": no_entries, "error": "%s does not parse as JSON (line %d: %s)" % [manifest_path, parser.get_error_line(), parser.get_error_message()]}
	if not (parser.data is Dictionary):
		return {"entries": no_entries, "error": "%s: the top level must be an object" % manifest_path}
	var manifest: Dictionary = parser.data
	if int(manifest.get("format", -1)) != FORMAT_VERSION:
		return {"entries": no_entries, "error": "%s: format must be %d" % [manifest_path, FORMAT_VERSION]}
	if not (manifest.get("placeholders") is Array):
		return {"entries": no_entries, "error": "%s: \"placeholders\" must be an array" % manifest_path}
	var entries: Array[Dictionary] = []
	var seen_paths := {}
	for raw_entry: Variant in manifest["placeholders"]:
		if not (raw_entry is Dictionary):
			return {"entries": no_entries, "error": "%s: every placeholder must be an object" % manifest_path}
		var entry: Dictionary = raw_entry
		var problem := entry_problem(entry)
		if not problem.is_empty():
			return {"entries": no_entries, "error": "%s: %s" % [manifest_path, problem]}
		if seen_paths.has(entry["path"]):
			return {"entries": no_entries, "error": "%s: %s is listed twice" % [manifest_path, entry["path"]]}
		seen_paths[entry["path"]] = true
		entries.append(entry)
	return {"entries": entries, "error": ""}


## "" when the entry is well formed, otherwise one sentence naming what is wrong with it.
static func entry_problem(entry: Dictionary) -> String:
	for key in REQUIRED_ENTRY_KEYS:
		if not (entry.get(key) is String) or String(entry[key]).strip_edges().is_empty():
			return "an entry has no text for \"%s\" (%s)" % [key, JSON.stringify(entry)]
	var path := String(entry["path"])
	if not path.begins_with("res://"):
		return "%s: path must start with res://" % path
	var recorded_hash := String(entry["sha256"])
	if recorded_hash.length() != SHA256_HEX_LENGTH or not recorded_hash.is_valid_hex_number(false) or recorded_hash != recorded_hash.to_lower():
		return "%s: sha256 must be %d lowercase hex characters" % [path, SHA256_HEX_LENGTH]
	return ""


## STATUS_PLACEHOLDER while the file's sha256 equals the recorded one, STATUS_REPLACED once
## it differs (the owner overwrote it), STATUS_MISSING when the file is gone.
static func status_of(entry: Dictionary) -> String:
	var path := String(entry["path"])
	if not FileAccess.file_exists(path):
		return STATUS_MISSING
	if FileAccess.get_sha256(path) == String(entry["sha256"]):
		return STATUS_PLACEHOLDER
	return STATUS_REPLACED


## The entries sorted for the manifest and for the TODO: by KIND_ORDER (unknown kinds after,
## alphabetically), then by path.
static func sorted_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var sorted: Array[Dictionary] = entries.duplicate()
	sorted.sort_custom(_is_listed_before)
	return sorted


## The manifest file's text for these entries (already sorted by the caller or not: this sorts).
static func manifest_text(entries: Array[Dictionary]) -> String:
	var text := "{\n"
	text += "\t\"format\": %d,\n" % FORMAT_VERSION
	text += "\t\"about\": %s,\n" % JSON.stringify(MANIFEST_ABOUT)
	text += "\t\"placeholders\": [\n"
	var sorted := sorted_entries(entries)
	for index in range(sorted.size()):
		var entry := sorted[index]
		# One object per line, keys in a fixed order, so a diff names the file that changed.
		var ordered_entry := {}
		for key in REQUIRED_ENTRY_KEYS:
			ordered_entry[key] = entry[key]
		text += "\t\t%s%s\n" % [JSON.stringify(ordered_entry, "", false), "," if index < sorted.size() - 1 else ""]
	text += "\t]\n}\n"
	return text


## The owner's TODO as printable lines: a summary, then one block per kind listing only the
## files that are still placeholders (and, separately, any listed file that has gone missing).
static func todo_lines(entries: Array[Dictionary]) -> PackedStringArray:
	var still_placeholder: Array[Dictionary] = []
	var missing: Array[Dictionary] = []
	var replaced_count := 0
	for entry in sorted_entries(entries):
		match status_of(entry):
			STATUS_PLACEHOLDER:
				still_placeholder.append(entry)
			STATUS_MISSING:
				missing.append(entry)
			_:
				replaced_count += 1

	var lines := PackedStringArray()
	lines.append("PLACEHOLDERS: %d recorded, %d still to replace, %d replaced by you, %d missing" % [entries.size(), still_placeholder.size(), replaced_count, missing.size()])
	var kinds_in_order: Array[String] = []
	for entry in still_placeholder:
		if not kinds_in_order.has(String(entry["kind"])):
			kinds_in_order.append(String(entry["kind"]))
	for kind in kinds_in_order:
		lines.append("")
		var kind_entries: Array[Dictionary] = []
		for entry in still_placeholder:
			if String(entry["kind"]) == kind:
				kind_entries.append(entry)
		lines.append("%s (%d) - %s" % [kind, kind_entries.size(), KIND_LABEL_BY_KIND.get(kind, "")])
		for entry in kind_entries:
			lines.append("  %s   [%s]" % [String(entry["path"]).trim_prefix("res://"), entry["id"]])
	if not missing.is_empty():
		lines.append("")
		lines.append("MISSING (listed in %s but the file is gone; restore it or remove its entry):" % MANIFEST_PATH.trim_prefix("res://"))
		for entry in missing:
			lines.append("  %s   [%s]" % [String(entry["path"]).trim_prefix("res://"), entry["id"]])
	if still_placeholder.is_empty() and missing.is_empty():
		lines.append("")
		lines.append("Nothing left to replace.")
	return lines


static func _is_listed_before(left: Dictionary, right: Dictionary) -> bool:
	var left_rank := _kind_rank(String(left["kind"]))
	var right_rank := _kind_rank(String(right["kind"]))
	if left_rank != right_rank:
		return left_rank < right_rank
	if left["kind"] != right["kind"]:
		return String(left["kind"]) < String(right["kind"])
	return String(left["path"]) < String(right["path"])


static func _kind_rank(kind: String) -> int:
	var rank := KIND_ORDER.find(kind)
	return rank if rank >= 0 else KIND_ORDER.size()
