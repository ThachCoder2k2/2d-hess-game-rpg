class_name PauseSummary
extends RefCounted

## What the pause menu says about the run, worked out when it opens (docs/game-base-plan.md 9.2 "Pause"): the
## room restart question, and the Quit to Title question, which NAMES THE LAST CHECKPOINT and says that the progress
## since the last save is lost (a quit is not a success event, so nothing is written, R17). Pure reading of the
## SaveService's run in memory; it writes nothing. The English sentences are constants until the text pipeline
## (M4) moves them to `UI_` keys.

## The SaveService autoload has no class_name (an autoload's name is a global), so its script is the type.
const SaveServiceScript := preload("res://shell/save/save_service.gd")

## The Restart Room question: it is a death without the defeat (D-16), and it saves nothing.
const RESTART_QUESTION := "Restart this room? You start again at its entrance with full Courage, and its pieces and weapons are put back."
const RESTART_YES := "Restart room"
const RESTART_NO := "Keep playing"
## The Quit to Title question. %s is the checkpoint's name.
const QUIT_QUESTION := "Quit to the title? Progress since your last save is lost.\nLast checkpoint: %s."
const QUIT_YES := "Quit to title"
const QUIT_NO := "Keep playing"
## What the checkpoint line says before the pawn has reached any checkpoint.
const NO_CHECKPOINT_NAME := "none yet"

## The zone of the latest checkpoint, &"" before the first one.
var checkpoint_zone_id: StringName = &""


## The summary of the run `save_service` holds. With no service (a flow driven alone) there is no checkpoint.
static func from_run(save_service: SaveServiceScript) -> PauseSummary:
	var summary := PauseSummary.new()
	if save_service != null and save_service.state.has_checkpoint():
		summary.checkpoint_zone_id = save_service.state.checkpoint_zone_id
	return summary


## The checkpoint as a name the player knows: the room's title, or NO_CHECKPOINT_NAME.
func checkpoint_name() -> String:
	if checkpoint_zone_id == &"":
		return NO_CHECKPOINT_NAME
	return TitleSummary.room_title(checkpoint_zone_id)


## The text of the Quit to Title question, naming the last checkpoint.
func quit_question() -> String:
	return QUIT_QUESTION % checkpoint_name()
