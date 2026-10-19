extends RefCounted

## Reads a gettext `.po` file as TEXT, the way a translator edits it (docs/game-base-plan.md 8.9), so the text guards
## can check what the engine's own loader forgives: a key written twice, a row with no translator comment, an empty
## msgstr, a comment that is not attached to anything. No class_name on purpose: suites preload() it, which works on
## a fresh checkout before the import pass.
##
## parse(text) returns { "header": String (the msgstr of the empty msgid: Language, Content-Type...),
## "entries": Array of { "key": String, "text": String, "comments": PackedStringArray (the `#.` lines, without the
## marker), "line": int (1-based line of the msgid) }, "problems": PackedStringArray (one sentence each) }.
## Supported: `#`, `#.` and `#:` lines, `msgid`, `msgstr`, strings continued over several quoted lines, and the
## escapes \n \t \" \\ . `msgctxt` is reported as a problem: the game does not use contexts.

## Where the words live: `<folder>/<language>/<domain>.po`.
const TEXT_FOLDER := "res://content/story/text"

var _entries: Array[Dictionary] = []
var _problems := PackedStringArray()
var _header := ""
## The entry being read.
var _comments := PackedStringArray()
var _key := ""
var _text := ""
var _entry_line := 0
var _reading := ""  # "msgid", "msgstr" or "" between entries
var _has_entry := false


## The path of one language's file of one domain.
static func path_of(language: Variant, domain: Variant) -> String:
	return "%s/%s/%s.po" % [TEXT_FOLDER, language, domain]


static func parse(po_text: String) -> Dictionary:
	var reader := new()
	return reader._read(po_text)


## The value of a header field ("Language") from the header text, "" when absent.
static func header_field(header: String, field_name: String) -> String:
	for header_line in header.split("\n"):
		if header_line.begins_with(field_name + ":"):
			return header_line.substr(field_name.length() + 1).strip_edges()
	return ""


## The {name} placeholders of a text, in order.
static func placeholders_of(text: String) -> PackedStringArray:
	var found := PackedStringArray()
	var regex := RegEx.create_from_string("\\{[^{}]*\\}")
	for placeholder_match in regex.search_all(text):
		found.append(placeholder_match.get_string())
	return found


func _read(po_text: String) -> Dictionary:
	var line_number := 0
	for raw_line in po_text.split("\n"):
		line_number += 1
		var line := raw_line.strip_edges()
		if line.is_empty():
			_flush()
		elif line.begins_with("#."):
			if _has_entry:
				_flush()
			_comments.append(line.substr(2).strip_edges())
		elif line.begins_with("#"):
			continue
		elif line.begins_with("msgctxt"):
			_problems.append("line %d: msgctxt is not used by the game" % line_number)
		elif line.begins_with("msgid"):
			_flush()
			_key = _unquote(line.substr(5), line_number)
			_entry_line = line_number
			_reading = "msgid"
			_has_entry = true
		elif line.begins_with("msgstr"):
			_text = _unquote(line.substr(6), line_number)
			_reading = "msgstr"
		elif line.begins_with("\""):
			if _reading == "msgid":
				_key += _unquote(line, line_number)
			elif _reading == "msgstr":
				_text += _unquote(line, line_number)
			else:
				_problems.append("line %d: a quoted string with no msgid or msgstr before it" % line_number)
		else:
			_problems.append("line %d: not understood: %s" % [line_number, line.left(60)])
	_flush()
	return {"header": _header, "entries": _entries, "problems": _problems}


## Ends the entry being read (if any): the header when its msgid is empty, else an entry of the list.
func _flush() -> void:
	if not _has_entry:
		return
	if _key.is_empty():
		_header = _text
	else:
		_entries.append({"key": _key, "text": _text, "comments": _comments, "line": _entry_line})
	_comments = PackedStringArray()
	_key = ""
	_text = ""
	_reading = ""
	_has_entry = false


## The text inside the quotes of `quoted`, escapes undone.
func _unquote(quoted: String, line_number: int) -> String:
	var trimmed := quoted.strip_edges()
	if trimmed.length() < 2 or not trimmed.begins_with("\"") or not trimmed.ends_with("\""):
		_problems.append("line %d: expected a quoted string, found: %s" % [line_number, trimmed.left(60)])
		return ""
	var inner := trimmed.substr(1, trimmed.length() - 2)
	var result := ""
	var index := 0
	while index < inner.length():
		var character := inner[index]
		if character == "\\" and index + 1 < inner.length():
			index += 1
			match inner[index]:
				"n":
					result += "\n"
				"t":
					result += "\t"
				"\"":
					result += "\""
				"\\":
					result += "\\"
				_:
					_problems.append("line %d: unknown escape \\%s" % [line_number, inner[index]])
		else:
			result += character
		index += 1
	return result
