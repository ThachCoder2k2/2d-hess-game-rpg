class_name PauseSummary
extends RefCounted

## What the pause menu says about the run, worked out when it opens (docs/game-base-plan.md 9.2 "Pause"): the
## room restart question, and the Quit to Title question, which NAMES THE LAST CHECKPOINT and says that the progress
## since the last save is lost (a quit is not a success event, so nothing is written, R17). Pure reading of the
## SaveService's run in memory; it writes nothing. The sentences are rows of content/story/text/en/ui.po
## (docs/game-base-plan.md 8.9): the constants below are their KEYS.

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

## The Restart Room question: it is a death without the defeat (D-16), and it saves nothing.
const RESTART_QUESTION_KEY := "UI_PAUSE_CONFIRM_RESTART"
const RESTART_YES_KEY := "UI_PAUSE_CONFIRM_RESTART_YES"
const RESTART_NO_KEY := "UI_PAUSE_KEEP_PLAYING"
## The Quit to Title question. {checkpoint} is the checkpoint's name.
const QUIT_QUESTION_KEY := "UI_PAUSE_CONFIRM_QUIT"
const QUIT_YES_KEY := "UI_PAUSE_CONFIRM_QUIT_YES"
const QUIT_NO_KEY := "UI_PAUSE_KEEP_PLAYING"
## What the checkpoint line says before the pawn has reached any checkpoint.
const NO_CHECKPOINT_NAME_KEY := "UI_PAUSE_NO_CHECKPOINT"

## The zone of the latest checkpoint, &"" before the first one.
var checkpoint_zone_id: StringName = &""


## The summary of the run `save_service` holds. With no service (a flow driven alone) there is no checkpoint.
static func from_run(save_service: SaveServiceScript) -> PauseSummary:
	var summary := PauseSummary.new()
	if save_service != null and save_service.state.has_checkpoint():
		summary.checkpoint_zone_id = save_service.state.checkpoint_zone_id
	return summary


## The checkpoint as a name the player knows: the room's title, or the "none yet" line.
func checkpoint_name() -> TextKey:
	if checkpoint_zone_id == &"":
		return TextKey.of(NO_CHECKPOINT_NAME_KEY)
	return TitleSummary.room_name(checkpoint_zone_id)


## The values of the Quit to Title question's {name}s, naming the last checkpoint.
func quit_question_params() -> Dictionary:
	return {"checkpoint": checkpoint_name()}
