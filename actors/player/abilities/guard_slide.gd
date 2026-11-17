class_name PlayerGuardSlide
extends Node
## Guard slide: a heavy hit caught by the parry guard pushes the player
## back instead of hurting them. Tuning and the hit's resolved slide.
##
## The Parry state calls `start()` with the hit, then enters GuardSlide.
## The slide covers `knockback_force × distance_per_force` pixels over
## `slide_time`, eased out, away from the hit. See the GuardSlide state.

@export_group("Slide")
## Pixels slid per point of the hit's `knockback_force`.
@export var distance_per_force := 0.35
## Seconds the slide takes, not counting the hit-stop.
@export var slide_time := 0.5
## Ease of the slide (below 1 starts fast and slows down). See `ease()`.
@export var slide_ease := 0.4
## The last part of the slide (s): the guard drops and holding dash
## cancels into a dash.
@export var recover_window := 0.35
## Invincibility after the slide ends (s).
@export var grace_time := 0.1

@export_group("Feedback")
## Freeze when the hit is caught, before the slide starts (s).
@export var hit_stop := 0.1
## Camera trauma when the hit is caught (0 to 1).
@export var shake := 0.4
## Gamepad rumble when the hit is caught (0 to 1).
@export var rumble := 0.7
@export var rumble_time := 0.2

## Resolved for the current hit, read by the GuardSlide state.
## 1 slides right, -1 left.
var direction := 0.0
## Pixels to slide.
var distance := 0.0

@onready var player := owner as Player


## Resolves the slide for `hitbox`: away from the hit, as far as its force.
func start(hitbox: Hitbox) -> void:
	direction = hitbox.push_direction(player.global_position)
	if direction == 0.0:
		direction = float(-player.facing)
	distance = hitbox.knockback_force * distance_per_force


## Freeze, shake and rumble when the hit is caught.
func play_feedback() -> void:
	HitStop.freeze(hit_stop)
	Events.camera_shake_requested.emit(shake)
	Rumble.play(rumble, rumble_time)
