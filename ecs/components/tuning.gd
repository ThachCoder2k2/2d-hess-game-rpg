class_name Tuning
extends RefCounted

## The assist and settings knobs that change how the simulation plays, in one place so a setting
## never edits a system (docs/game-base-plan.md 5.8, 5.10, D-38). Pure data: the world holds ONE
## instance, EcsWorld.tuning; presentation changes it only through the `tuning_set` command. Every
## default is the neutral value, so a world that never touches it plays exactly as before M3a.
##
## Nothing reads these yet; the milestone that makes a knob do something is named on it.

## Every component carries its store key (docs/coding-standards.md). Tuning is the one component
## the world holds directly, as EcsWorld.tuning, instead of on an entity.
const KEY := &"tuning"

## How long enemy telegraphs last, as a multiple of their authored time (1.0 standard, 1.25 and
## 1.5 are the assist offers). The telegraph floor of 0.45 s still applies. Read by EnemyAISystem from M8a.
var telegraph_time_scale := 1.0

## How fast enemies act while the pawn stands still, as a multiple of standard (1.0 standard, 0.85 and
## 0.70 are the assist offers). Read by EnemyAISystem from M8a.
var enemy_pace_scale := 1.0

## Seconds a step pressed during another step stays buffered before it is forgotten. 0.0 means it
## never expires, which is how the game plays today; M7b sets the real window (0.12 s, 0.20 s with
## the Input Forgiveness assist) and makes PlayerInputSystem read it.
var input_buffer_window := 0.0

## Courage added to the pawn's maximum by the Extra Courage assist (0, 1 or 2). Read when the
## player is spawned and at checkpoint refills (M3b, M8c).
var extra_courage := 0
