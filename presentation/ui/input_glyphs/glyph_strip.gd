class_name GlyphStrip
extends HBoxContainer

## A row of control glyphs: for each InputGlyph the owner's 16x16 picture when the file is there, and its words
## ("[Space]") when it is not. The Controls panel puts one in each cell of its keyboard and gamepad columns; an
## ActionPrompt puts one beside its words. It decides nothing: it shows what it is handed.
##
## The pictures are drawn at their own size with the nearest-pixel filter (all art is 1x1 pixels, CLAUDE.md), never
## scaled. A control the device has no binding for shows PROMPT_NOT_BOUND.

## The text key of what an empty cell says.
const NOT_BOUND_KEY := "PROMPT_NOT_BOUND"
## The size of the words of a glyph that has no picture: a little smaller than a menu button's.
const WORDS_FONT_SIZE := 10

## The glyphs on show, in order.
var glyphs_on_show: Array[InputGlyph] = []

## Keeps the words of an empty cell in the player's language. Made on first use.
var _live_text: LiveText = null


func _init() -> void:
	add_theme_constant_override("separation", 4)


## Replaces what the strip shows.
func show_glyphs(glyphs: Array[InputGlyph]) -> void:
	for child in get_children():
		if child is LiveText:
			continue
		remove_child(child)
		child.queue_free()
	glyphs_on_show = glyphs
	if glyphs.is_empty():
		var empty_label := _words_label()
		_live().set_text(empty_label, NOT_BOUND_KEY)
		add_child(empty_label)
		return
	for glyph in glyphs:
		if glyph.has_picture():
			add_child(_picture_of(glyph))
		else:
			var words_label := _words_label()
			words_label.text = glyph.text
			add_child(words_label)


## How many cells of the strip are pictures (a test counts them).
func picture_count() -> int:
	var count := 0
	for child in get_children():
		if child is TextureRect:
			count += 1
	return count


## The words on show, joined by a space: what a player without the pictures reads.
func words_on_show() -> String:
	var words := PackedStringArray()
	for child in get_children():
		if child is Label:
			words.append((child as Label).text)
	return " ".join(words)


func _picture_of(glyph: InputGlyph) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = glyph.texture
	picture.custom_minimum_size = glyph.texture.get_size()
	picture.stretch_mode = TextureRect.STRETCH_KEEP
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


func _words_label() -> Label:
	var words := Label.new()
	words.add_theme_font_size_override(&"font_size", WORDS_FONT_SIZE)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return words


func _live() -> LiveText:
	if _live_text == null:
		_live_text = LiveText.new()
		add_child(_live_text)
	return _live_text
