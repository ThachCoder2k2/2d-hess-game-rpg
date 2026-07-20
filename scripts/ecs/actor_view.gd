class_name ActorView
extends Node2D

## A puppet + spawn marker. The scene holds two kinds of editor-authored data:
## spawn data (parked position -> start cell, definition / attack profiles ->
## component values) and appearance knobs the ViewSyncSystem reads while
## driving the sprites. No logic, no input, no state — systems own all of it
## (docs/ecs-conversion-plan.md).

## Enemy spawn data (null on the player view; the player's kit lives on its
## CombatComponent / HealthComponent / MovementComponent / InputComponent
## child nodes instead).
@export var definition: EnemyDefinition

@export_group("Appearance")
@export var hurt_modulate := Color("#ff8170")
@export var telegraph_modulate := Color("#d14a52")
@export var show_facing_mark := true
@export var show_health := true
@export var weapon_anchor := Vector2(5, -14)
@export_range(1.0, 64.0, 0.5) var weapon_rest_length := 18.0
## Shown when the active attack / equipped weapon has no texture of its own.
@export var default_weapon_texture: Texture2D
@export var pip_full_texture: Texture2D
@export var pip_empty_texture: Texture2D
