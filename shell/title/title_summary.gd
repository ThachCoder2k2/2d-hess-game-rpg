class_name TitleSummary
extends RefCounted

## What the title screen shows about the saved run, worked out from the slot on the disk (docs/game-base-plan.md
## 9.2 "Save slot", "Corrupt or newer save"): whether Continue is offered, the one-line notice when the loader
## had to fall back or give up, the slot card (the room, the time played, the day saved), whether the game was
## ever finished (the title then shows its post-game board), and the build's version string. Pure reading: it
## uses SaveService.read_slot(), which writes nothing and prints nothing, and decides nothing the player can
## see beyond these fields. The words are rows of content/story/text/en/ui.po (docs/game-base-plan.md 8.9); the
## text fields hold them in the language of the moment, and refresh_texts() writes them again after a language change.
##
## Continue is offered exactly when the slot holds readable progress. A damaged slot with no usable backup, a
## save too old to migrate and a save from a newer game are not progress: the title says why (the notice) and
## offers New Game only. A newer game's file is never overwritten (SaveService.new_game sets it aside).

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

## SaveLoadResult notice key -> the text key of its sentence.
const NOTICE_TEXT_KEY_BY_KEY := {
	SaveLoadResult.NOTICE_BACKUP_USED: "UI_NOTICE_BACKUP_USED",
	SaveLoadResult.NOTICE_NEW_GAME_AFTER_DAMAGE: "UI_NOTICE_NEW_GAME_AFTER_DAMAGE",
	SaveLoadResult.NOTICE_OBSOLETE_SAVE: "UI_NOTICE_OBSOLETE_SAVE",
	SaveLoadResult.NOTICE_NEWER_GAME: "UI_NOTICE_NEWER_GAME",
}
## The slot card: the room, the time played, the day saved (the last one only when the save has a date).
const CARD_KEY := "UI_CARD_PLAYED"
const CARD_WITH_DATE_KEY := "UI_CARD_PLAYED_ON"
## What the card says for a run that has not entered any room yet.
const FIRST_ROOM_NAME_KEY := "UI_CARD_FIRST_ROOM"
const VERSION_KEY := "UI_VERSION"
## The time played, under an hour and from an hour on.
const MINUTES_KEY := "UI_TIME_MINUTES"
const HOURS_MINUTES_KEY := "UI_TIME_HOURS_MINUTES"
## A room's name is the row ROOM_<ID>_NAME of rooms.po.
const ROOM_NAME_KEY_FORMAT := "ROOM_%s_NAME"

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

## The save the card describes, null when there is none; kept so the card can be written again.
var _card_data: SaveData = null
## The project's version number, kept for the same reason.
var _version := ""


## The summary of `save_service`'s slot. `version` is the project's application/config/version. With no
## service (a flow driven alone) nothing is saved: no Continue, no notice.
static func from_save(save_service: SaveServiceScript, version: String, slot := SaveServiceScript.SINGLE_SLOT) -> TitleSummary:
	var summary := TitleSummary.new()
	summary._version = version
	if save_service != null:
		summary.completed = save_service.is_completed()
		if save_service.has_save(slot):
			var result := save_service.read_slot(slot)
			summary.can_continue = result.found_progress()
			summary.notice_key = result.notice_key
			if summary.can_continue:
				summary._card_data = result.data
	summary.refresh_texts()
	return summary


## Writes the version, the notice and the card again in the current language (after a language change).
func refresh_texts() -> void:
	version_text = TextService.t(VERSION_KEY, {"version": _version}) if not _version.is_empty() else ""
	var notice_text_key: String = NOTICE_TEXT_KEY_BY_KEY.get(notice_key, "")
	notice_text = TextService.t(notice_text_key) if not notice_text_key.is_empty() else ""
	card_text = card_for(_card_data) if _card_data != null else ""


## The slot card for a run: "Broken Rule Yard  |  1h 05m played  |  2026-10-19".
static func card_for(data: SaveData) -> String:
	var params := {"room": room_name(data.room_id), "time": play_time(data.play_time_seconds)}
	if data.saved_at_unix <= 0:
		return TextService.t(CARD_KEY, params)
	params["day"] = day_text(data.saved_at_unix)
	return TextService.t(CARD_WITH_DATE_KEY, params)


## A room's name as a TextKey: its row ROOM_<ID>_NAME when rooms.po has one, else the id as a title (the act-and-number
## prefix ("t4", "b1", "tb3") dropped and the words capitalised: `t4_broken_rule_yard` is "Broken Rule Yard"; a save
## can name a room the game no longer has). An empty id (a run that has not left the first room) is the
## FIRST_ROOM_NAME_KEY line.
static func room_name(room_id: StringName) -> TextKey:
	if room_id == &"":
		return TextKey.of(FIRST_ROOM_NAME_KEY)
	var name_key := ROOM_NAME_KEY_FORMAT % String(room_id).to_upper()
	if TextService.has_key(name_key):
		return TextKey.of(name_key)
	var words := String(room_id).split("_", false)
	if words.size() > 1 and RegEx.create_from_string("^[a-z]{1,3}[0-9]+[a-z]?$").search(words[0]) != null:
		words.remove_at(0)
	var titled := PackedStringArray()
	for word in words:
		titled.append(word.capitalize())
	return TextKey.of(" ".join(titled))


## A room's name in the current language.
static func room_title(room_id: StringName) -> String:
	return room_name(room_id).resolve()


## The time played as a TextKey: "42m" under an hour and "1h 05m" from an hour on.
static func play_time(seconds: float) -> TextKey:
	var total_minutes := int(seconds / 60.0)
	if total_minutes < 60:
		return TextKey.of(MINUTES_KEY, {"minutes": total_minutes})
	return TextKey.of(HOURS_MINUTES_KEY, {"hours": floori(total_minutes / 60.0), "minutes": "%02d" % (total_minutes % 60)})


## The time played in the current language.
static func play_time_text(seconds: float) -> String:
	return play_time(seconds).resolve()


## The local calendar day of a Unix time as "2026-10-19" (a date written in numbers reads the same in every language).
static func day_text(unix_seconds: int) -> String:
	var bias_minutes := int(Time.get_time_zone_from_system().get("bias", 0))
	var day := Time.get_datetime_dict_from_unix_time(unix_seconds + bias_minutes * 60)
	return "%04d-%02d-%02d" % [day["year"], day["month"], day["day"]]
