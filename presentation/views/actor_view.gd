class_name ActorView
extends Node2D

## A puppet + spawn marker. The scene holds two kinds of editor-authored data:
## spawn data (parked position -> start cell, definition / attack profiles ->
## component values) and appearance knobs the ViewSyncSystem reads while
## driving the sprites. No logic, no input, no state — systems own all of it
## (docs/ecs-conversion-plan.md).

## Enemy spawn data (null on the player view).
@export var definition: EnemyDefinition
## Player spawn data (null on enemy views): the pawn's tuning, content/player/player.tres.
## EcsBoot bakes it first; a HealthComponent / MovementComponent / InputComponent /
## CombatComponent child node placed on this view still beats it, field by field.
@export var player_definition: PlayerDefinition

@export_group("Appearance")
@export var hurt_modulate := Color("#ff8170")
@export var telegraph_modulate := Color("#d14a52")
@export var show_facing_mark := true
@export var show_health := true
## How big each kind of piece is inside its cell (content/feel/piece_sizes.tres). The view reads
## it to stand a body picture on its base line; the base scene names the shipped table.
@export var piece_sizes: PieceSizeTable

@export_group("In the cell")
## Everything below keeps a piece inside its own cell (the owner's decision of 2026-10-12): the
## body is placed from the size table, and these three place what a piece holds and shows.
## Pixels from the cell's centre to the facing arrow, in the direction the piece faces.
@export_range(0.0, 16.0, 0.5) var facing_mark_distance := 10.0
## Where the hand is, pixels from the cell's centre; the held weapon is drawn from here, a few
## pixels toward the facing side, so it stays inside the cell whichever way the piece faces.
@export var weapon_anchor := Vector2.ZERO
## Pixels from the hand to the middle of the held weapon (longer for a weapon that reaches farther).
@export_range(1.0, 16.0, 0.5) var weapon_rest_length := 3.0
## Scale of the held weapon's picture. The weapons' icons are 24 x 56 to 28 x 64 pixels, so this
## shrinks them to something a 32 px cell can hold.
@export_range(0.05, 1.0, 0.01) var weapon_held_scale := 0.16

@export_group("Pictures")
## Shown when the active attack / equipped weapon has no texture of its own.
@export var default_weapon_texture: Texture2D
@export var pip_full_texture: Texture2D
@export var pip_empty_texture: Texture2D
