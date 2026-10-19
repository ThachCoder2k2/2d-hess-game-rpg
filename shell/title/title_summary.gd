class_name TitleSummary
extends RefCounted

## What the title screen shows about the saved run, worked out from the slot on the disk (docs/game-base-plan.md
## 9.2 "Save slot", "Corrupt or newer save"): whether Continue is offered, the one-line notice when the loader
## had to fall back or give up, the slot card (the room, the time played, the day saved), whether the game was
## ever finished (the title then shows its post-game board), and the build's version string. Pure reading: it
## uses SaveService.read_slot(), which writes nothing and prints nothing, and decides nothing the player can
## see beyond these fields. Until the text pipeline (M4) moves the words to `UI_` keys, the English sentences are
## the constants below.
##
## Continue is offered exactly when the slot holds readable progress. A damaged slot with no usable backup, a
## save too old to migrate and a save from a newer game are not progress: the title says why (the notice) and
## offers New Game only. A newer game's file is never overwritten (SaveService.new_game sets it aside).

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

## The English sentence for each SaveLoadResult notice key.
const NOTICE_TEXT_BY_KEY := {
	SaveLoadResult.NOTICE_BACKUP_USED: "Your latest save was damaged. The save before it is loaded instead.",
	SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE: "Your save was damaged and cannot be read. Choosing New Game starts over.",
	SaveLoadResult.NOTICE_OBSOLETE_SAVE: "Your save is from a much older version and cannot be read. Choosing New Game starts over.",
	SaveLoadResult.NOTICE_NEWER_GAME: "This save needs a newer game.",
}
## The slot card: the room, the time played, the day saved. %s are filled in order.
const CARD_FORMAT := "%s  |  %s played"
const CARD_WITH_DATE_FORMAT := "%s  |  %s played  |  %s"
## What the card says for a run that has not entered any room yet.
const FIRST_ROOM_NAME := "The beginning"
const VERSION_FORMAT := "v%s"

## Whether the Continue button is offered.
var can_continue := false
## The text key of the notice (a SaveLoadResult.NOTICE_*), "" when there is none.
var notice_key: StringName = &""
## The notice as a sentence, "" when there is none.
var notice_text := ""
## The slot card, "" when there is no readable save to describe.
var card_text := ""
## Whether the player has seen the ending (the profile's mark, which a New Game keeps).
var completed := false
## The build's version, "v0.4.0", "" when the project sets none.
var version_text := ""


## The summary of `save_service`'s slot. `version` is the project's application/config/version. With no
## service (a flow driven alone) nothing is saved: no Continue, no notice.
static func from_save(save_service: SaveServiceScript, version: String, slot := SaveServiceScript.SINGLE_SLOT) -> TitleSummary:
	var summary := TitleSummary.new()
	if not version.is_empty():
		summary.version_text = VERSION_FORMAT % version
	if save_service == null:
		return summary
	summary.completed = save_service.is_completed()
	if not save_service.has_save(slot):
		return summary
	var result := save_service.read_slot(slot)
	summary.can_continue = result.found_progress()
	summary.notice_key = result.notice_key
	summary.notice_text = String(NOTICE_TEXT_BY_KEY.get(result.notice_key, ""))
	if summary.can_continue:
		summary.card_text = card_for(result.data)
	return summary


## The slot card for a run: "Broken Rule Yard  |  1h 05m played  |  2026-10-19".
static func card_for(data: SaveData) -> String:
	var room_name := room_title(data.room_id)
	var played := play_time_text(data.play_time_seconds)
	if data.saved_at_unix <= 0:
		return CARD_FORMAT % [room_name, played]
	return CARD_WITH_DATE_FORMAT % [room_name, played, day_text(data.saved_at_unix)]


## A room id as a title: the act-and-number prefix ("t4", "b1", "tb3") is dropped and the words are capitalised:
## `t4_broken_rule_yard` is "Broken Rule Yard". An empty id (a run that has not left the first room) is
## FIRST_ROOM_NAME. A stand-in until rooms carry a title key (`ROOM_`, M6).
static func room_title(room_id: StringName) -> String:
	if room_id == &"":
		return FIRST_ROOM_NAME
	var words := String(room_id).split("_", false)
	if words.size() > 1 and RegEx.create_from_string("^[a-z]{1,3}[0-9]+[a-z]?$").search(words[0]) != null:
		words.remove_at(0)
	var titled := PackedStringArray()
	for word in words:
		titled.append(word.capitalize())
	return " ".join(titled)


## Seconds played as "42m" under an hour and "1h 05m" from an hour on.
static func play_time_text(seconds: float) -> String:
	var total_minutes := int(seconds / 60.0)
	if total_minutes < 60:
		return "%dm" % total_minutes
	return "%dh %02dm" % [floori(total_minutes / 60.0), total_minutes % 60]


## The local calendar day of a Unix time as "2026-10-19".
static func day_text(unix_seconds: int) -> String:
	var bias_minutes := int(Time.get_time_zone_from_system().get("bias", 0))
	var day := Time.get_datetime_dict_from_unix_time(unix_seconds + bias_minutes * 60)
	return "%04d-%02d-%02d" % [day["year"], day["month"], day["day"]]
