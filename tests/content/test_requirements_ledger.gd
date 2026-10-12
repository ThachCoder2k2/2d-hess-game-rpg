extends UnboundTest

## docs/requirements_ledger.md must account for every entry of
## docs/requirements.json exactly once, and every must-priority entry must say
## where the plan answers it, which milestone delivers it, and which test proves
## it (or which owner-waivable deferral replaced it). See docs/game-base-plan.md
## §1.5 and decision D25. Staleness of the quoted text is a soft check, so an
## owner rewrite of requirements.json never turns the suite red.

## How many requirements requirements.json held when the ledger was written
## (M1a). The file may only grow; fewer entries means requirements were lost.
const MINIMUM_REQUIREMENT_COUNT := 249

## req#, P, System, Requirement, Plan section, Milestone, Verified by, Status.
const LEDGER_COLUMN_COUNT := 8

## Splitting "| a | b |" on "|" yields an empty first and last part.
const SPLIT_PARTS_PER_ROW := LEDGER_COLUMN_COUNT + 2

const NOT_APPLICABLE := "n/a"
const WAIVER_STATUS_PREFIX := "deferred W"
const VALID_STATUS_PREFIXES: Array[String] = ["covered", "amended", WAIVER_STATUS_PREFIX]

## requirements.json priority word -> the one-letter code the ledger uses.
const PRIORITY_LETTER_BY_WORD := {"must": "m", "should": "s", "could": "c"}

## How much of a requirement's wording a ledger row must still quote.
const QUOTED_WORDING_LENGTH := 30

## Ledger lines that start like a row but do not have exactly eight columns.
var _malformed_row_lines := PackedStringArray()


func _init() -> void:
	var paths := TestPaths.new(self)
	var requirements_document: Variant = paths.read_json(paths.requirements_json())
	var ledger_text := paths.read_text(paths.requirements_ledger())

	var requirements := _requirements_array(requirements_document)
	if not _expect(not requirements.is_empty(), "requirements.json holds a non-empty 'requirements' array"):
		finish()
		return
	_expect(requirements.size() >= MINIMUM_REQUIREMENT_COUNT, "requirements.json still holds at least the %d requirements the ledger was written for" % MINIMUM_REQUIREMENT_COUNT)

	var rows_by_index := _parse_ledger_rows(ledger_text)
	_expect(rows_by_index.size() >= MINIMUM_REQUIREMENT_COUNT, "the ledger table was found and holds at least %d rows" % MINIMUM_REQUIREMENT_COUNT)
	_expect(_malformed_row_lines.is_empty(), "every ledger row has exactly %d columns and no '|' inside a cell" % LEDGER_COLUMN_COUNT)
	_report(_malformed_row_lines)

	var coverage_problems := _coverage_problems(requirements.size(), rows_by_index)
	_expect(coverage_problems.is_empty(), "every requirement index appears exactly once in the ledger")
	_report(coverage_problems)

	var must_problems := _must_row_problems(requirements, rows_by_index)
	_expect(must_problems.is_empty(), "every must requirement has a plan section, a milestone, and a test or a waiver")
	_report(must_problems)

	var status_problems := _status_problems(rows_by_index)
	_expect(status_problems.is_empty(), "every ledger status is covered, amended or deferred W")
	_report(status_problems)

	var stale_problems := _stale_row_problems(requirements, rows_by_index)
	soft_expect(stale_problems.is_empty(), "ledger rows still match requirements.json in priority, system and wording")
	_report(stale_problems)

	finish()


func _requirements_array(requirements_document: Variant) -> Array:
	if requirements_document is Dictionary:
		var document: Dictionary = requirements_document
		var requirements: Variant = document.get("requirements")
		if requirements is Array:
			return requirements
	return []


## Returns req# (int) -> Array of row Dictionaries, so a repeated index shows up
## as an array of two. Rows are the table lines whose first cell is an integer.
func _parse_ledger_rows(ledger_text: String) -> Dictionary:
	var rows_by_index := {}
	_malformed_row_lines = PackedStringArray()
	for line in ledger_text.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.begins_with("|"):
			continue
		var parts := trimmed.split("|")
		if parts.size() < 2 or not parts[1].strip_edges().is_valid_int():
			continue  # the header row, the divider row or prose
		if parts.size() != SPLIT_PARTS_PER_ROW:
			_malformed_row_lines.append("malformed ledger row: %s" % trimmed.left(80))
			continue
		var index := parts[1].strip_edges().to_int()
		var row := {
			"index": index,
			"priority": parts[2].strip_edges(),
			"system": parts[3].strip_edges(),
			"requirement": parts[4].strip_edges(),
			"section": parts[5].strip_edges(),
			"milestone": parts[6].strip_edges(),
			"verified_by": parts[7].strip_edges(),
			"status": parts[8].strip_edges(),
		}
		if not rows_by_index.has(index):
			rows_by_index[index] = []
		(rows_by_index[index] as Array).append(row)
	return rows_by_index


func _coverage_problems(requirement_count: int, rows_by_index: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for index in range(requirement_count):
		var row_count := (rows_by_index[index] as Array).size() if rows_by_index.has(index) else 0
		if row_count == 0:
			problems.append("req#%d has no ledger row" % index)
		elif row_count > 1:
			problems.append("req#%d has %d ledger rows" % [index, row_count])
	for key: int in rows_by_index:
		if key < 0 or key >= requirement_count:
			problems.append("ledger row req#%d has no entry in requirements.json" % key)
	return problems


func _must_row_problems(requirements: Array, rows_by_index: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for index in range(requirements.size()):
		var requirement := requirements[index] as Dictionary
		if requirement.get("priority") != "must" or not rows_by_index.has(index):
			continue
		var row := (rows_by_index[index] as Array)[0] as Dictionary
		if _is_blank(row["section"]):
			problems.append("must req#%d has no plan section" % index)
		if _is_blank(row["milestone"]):
			problems.append("must req#%d has no milestone" % index)
		if _is_blank(row["verified_by"]) and not String(row["status"]).begins_with(WAIVER_STATUS_PREFIX):
			problems.append("must req#%d has neither a verifying test nor a waiver" % index)
	return problems


func _status_problems(rows_by_index: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for key: int in rows_by_index:
		for row: Dictionary in rows_by_index[key]:
			var status := String(row["status"])
			var recognised := false
			for prefix in VALID_STATUS_PREFIXES:
				recognised = recognised or status.begins_with(prefix)
			if not recognised:
				problems.append("req#%d has the unknown status '%s'" % [key, status])
	return problems


func _stale_row_problems(requirements: Array, rows_by_index: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for index in range(requirements.size()):
		if not rows_by_index.has(index):
			continue
		var requirement := requirements[index] as Dictionary
		var row := (rows_by_index[index] as Array)[0] as Dictionary
		var expected_letter: String = PRIORITY_LETTER_BY_WORD.get(requirement.get("priority", ""), "?")
		if row["priority"] != expected_letter:
			problems.append("req#%d: ledger priority '%s' but requirements.json says '%s'" % [index, row["priority"], requirement.get("priority", "")])
		if row["system"] != String(requirement.get("system", "")):
			problems.append("req#%d: ledger system '%s' but requirements.json says '%s'" % [index, row["system"], requirement.get("system", "")])
		var wording := _one_line(String(requirement.get("requirement", ""))).replace("|", "/")
		var quoted := String(row["requirement"]).left(QUOTED_WORDING_LENGTH)
		if not wording.begins_with(quoted):
			problems.append("req#%d: the ledger quotes '%s' but requirements.json starts '%s'" % [index, quoted, wording.left(QUOTED_WORDING_LENGTH)])
	return problems


func _is_blank(cell: Variant) -> bool:
	var text := String(cell)
	return text.is_empty() or text == NOT_APPLICABLE


func _one_line(text: String) -> String:
	return " ".join(text.replace("\n", " ").split(" ", false))


func _report(problems: PackedStringArray) -> void:
	for problem in problems:
		printerr("  %s" % problem)
