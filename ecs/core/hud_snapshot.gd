class_name HudSnapshot
extends RefCounted

## The read-only picture of the simulation that the HUD and the board overlay draw from
## (docs/game-base-plan.md 14.3, D-38): HudSnapshotSystem rebuilds it at the end of every tick, so
## presentation reads this data object and never reaches into components (the dependency test
## forbids presentation -> ecs/components; HudSnapshot is the one ecs/core class it may name).
## Presentation never writes it; it asks the simulation for changes with commands.
##
## Pure data: no method here decides anything or reads the world. EcsWorld.hud_snapshot holds the one
## instance of a world, rebuilt IN PLACE, so a widget that kept the reference sees every rebuild.
## A field is added here when a widget needs it (one line here, one in HudSnapshotSystem.build()),
## never by letting the widget read a component.

## How many times HudSnapshotSystem has rebuilt this snapshot; 0 means it was never built. A widget
## can compare it with the revision it last drew to know whether anything may have changed.
var revision := 0

## --- The hero ---

## Entity id of the hero, 0 when the world has none. The fields below mean nothing while it is 0.
var player_entity := 0

## Courage the hero has left, and the most it can have (Health.current / max_value).
var player_courage_current := 0
var player_courage_max := 0

## The cell the hero stands on, and the cell direction it faces (Vector2i.UP is "N").
var player_cell := Vector2i.ZERO
var player_facing := Vector2i.ZERO

## False until the pawn finds the sword: the skill slot then reads "find sword" (PlayerCombat.sword_unlocked).
var sword_unlocked := false

## Seconds until the skill can be used again (0.0 when it is ready), and how long a full cooldown is.
## The duration is 1.0 while the hero has no combat component, the value the HUD always showed then.
var skill_cooldown_left := 0.0
var skill_cooldown_duration := 1.0

## --- The story tally ---

## The Rank label the badge draws as blue tally marks, 2 to 8 (docs/game-base-plan.md 6.1: a story label that reads
## defeated-boss flags and that nothing else reads), or 0 while the game has no label to show. Nothing fills it yet:
## M7c's ProgressionSystem copies the label here, and until then the badge stays hidden, so the first minutes of
## the game do not show a tally of a system that has not started.
var rank_label := 0

## --- The room ---

## Entity id of the enemy that holds the room's one attack token (EcsWorld.attack_token_owner); 0 when it is free.
var attack_token_owner := 0

## How many enemies the room began with and how many still stand (RoomObjectiveState, kept true by
## ObjectiveSystem); both 0 in a world that has no room entity, and in a room whose enemies are not
## spawned because the run cleared it earlier. The HUD's "ENEMIES n/m" line reads them.
var room_enemies_total := 0
var room_enemies_remaining := 0

## --- The enemies (the board overlay's telegraph progress and F3 intent paths) ---

## What the board needs to know about one enemy.
class EnemyBrief:
	## The cell the enemy stands on.
	var cell := Vector2i.ZERO
	## The cell the enemy has committed to walk toward (EnemyAI.committed_goal); the AI's "no goal"
	## marker lies outside every board, so the overlay's inside-the-board test rejects it.
	var committed_goal := Vector2i.ZERO
	## How far through its telegraph the enemy is, 0.0 to 1.0; 0.0 when it is not telegraphing.
	var telegraph_progress := 0.0


## enemy entity id (int) -> its EnemyBrief. Holds every entity that has an EnemyAI and a cell
## (defeated enemies stay until the entity is destroyed); an entity missing from it has no AI.
var enemy_brief_by_entity: Dictionary = {}


## --- The doors (the board overlay draws them; without a mark a door cell is plain floor) ---

## What the board needs to know about one door cell.
class DoorBrief:
	## True while the door does not let the hero through: it waits for the room to be cleared or for a world flag
	## (DoorRules.is_shut, the same rule MovementSystem uses when the hero lands on it).
	var is_shut := false
	## True for the door that ends the run instead of leading to another room (the Desk's last door).
	var ends_run := false


## door cell (Vector2i) -> its DoorBrief, one per ZoneExitMarker of the room (EcsGrid.exit_by_cell). The doors of a
## room never move, only open: the briefs are made once and their is_shut follows the world every tick.
var door_brief_by_cell: Dictionary = {}
