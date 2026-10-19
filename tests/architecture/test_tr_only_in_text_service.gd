extends UnboundTest

## Architecture guard (docs/game-base-plan.md 8.9, D-24): TextService is the ONLY code that asks the engine to
## translate. A script that called tr() or TranslationServer.translate() itself would show a string the language
## files and the text guards know nothing about, and would not follow a language switch the way a LiveText does.
## Scenes that hold a key in a Label's `text` are translated by the engine and need no script; that is not a call.
##
## A call counts when the name appears in code, with comments and string literals removed: tr, atr, tr_n, atr_n
## (on self or on another object) and TranslationServer.translate / translate_plural. Tests and tools are not
## sources (a test may switch languages and add translations; it does not translate).

const ProjectFiles := preload("res://tests/architecture/project_files.gd")

const TEXT_SERVICE_PATH := "res://presentation/text/text_service.gd"
## Fewer source files than this means the walk is broken, not clean.
const MINIMUM_SOURCE_FILES := 20


func _init() -> void:
	suite_title = "TR ONLY IN TEXT SERVICE TEST"
	var string_literal_regex := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'")
	var comment_regex := RegEx.create_from_string("#[^\\n]*")
	var triple_quoted_regex := RegEx.create_from_string("\"\"\"[\\s\\S]*?\"\"\"")
	var translate_call_regex := RegEx.create_from_string("(?<![A-Za-z0-9_])(?:atr_n|tr_n|atr|tr)\\(|TranslationServer\\s*\\.\\s*translate(?:_plural)?\\(")

	var source_count := 0
	var callers: Array[String] = []
	for script_path in ProjectFiles.collect_files(["gd"]):
		if script_path.begins_with("res://tests/") or script_path.begins_with("res://tools/"):
			continue
		source_count += 1
		var code := ProjectFiles.read_text(script_path)
		code = triple_quoted_regex.sub(code, "", true)
		code = string_literal_regex.sub(code, "\"\"", true)
		code = comment_regex.sub(code, "", true)
		if translate_call_regex.search(code) != null:
			callers.append(script_path)

	_expect(source_count >= MINIMUM_SOURCE_FILES, "the walk found %d source scripts (at least %d)" % [source_count, MINIMUM_SOURCE_FILES])
	_expect(callers == [TEXT_SERVICE_PATH], "the engine is asked to translate in %s and nowhere else (found: %s)" % [TEXT_SERVICE_PATH, ", ".join(PackedStringArray(callers))])

	# The check must be able to fail: the same pattern on code that does translate from elsewhere.
	for offender in ["label.text = tr(\"UI_X\")", "var words := atr(text)", "return tr_n(a, b, 2)", "TranslationServer.translate(key)", "TranslationServer.translate_plural(a, b, 2)", "node.tr(\"K\")"]:
		_expect(translate_call_regex.search(offender) != null, "the lint's pattern catches: %s" % offender)
	for innocent in ["var entry(", "str(value)", "var translated := 1", "TranslationServer.set_locale(code)", "TranslationServer.add_translation(t)"]:
		_expect(translate_call_regex.search(innocent) == null, "and does not mistake: %s" % innocent)
	finish()
