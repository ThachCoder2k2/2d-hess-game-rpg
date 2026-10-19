class_name InputGlyph
extends RefCounted

## What a prompt shows for ONE control (a key, a pad button, a stick direction): the owner's picture when the file is
## there, and always the words that stand for it ("[Space]", "[A]"). A picture is optional on purpose: the glyph files
## are sourced by the owner (docs/assets/spec/ui_story.json, group `glyphs_kenney`) and may be missing; the prompt then
## shows `text`, which is readable on its own. InputGlyphs makes them.

## The 16x16 picture, or null when the file is not at `file_path`.
var texture: Texture2D = null
## The words that stand for the control when there is no picture: "[Space]", "[A]", "[D-pad Up]".
var text := ""
## The path the owner's file belongs at, or "" for a control the asset list has no file for.
var file_path := ""


## Whether the owner's picture is there.
func has_picture() -> bool:
	return texture != null
