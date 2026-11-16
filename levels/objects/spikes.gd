class_name Spikes
extends Area2D
## Spikes kill the player instantly, like a pit, but only when the player
## really steps into them. Brushing a corner or the side mid-jump doesn't
## count, so they can always be jumped over.
##
## The player dies when their feet are inside the spikes: centre within
## the shape's width and feet at least `sink_depth` below its top. The
## shape must be a `RectangleShape2D` child named `Shape`. Put the area on
## the `hazards` layer (so safe ground keeps away from it) and mask
## `player`.

## How far the feet must be below the top of the spikes (px).
@export var sink_depth := 2.0

@onready var shape := $Shape as CollisionShape2D


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var player := body as Player
		if player and not player.health.is_dead() and _feet_inside(player.global_position):
			player.velocity = Vector2.ZERO
			# Deferred: never change physics state inside a physics step.
			player.health.kill.call_deferred()


func _feet_inside(feet: Vector2) -> bool:
	var size := (shape.shape as RectangleShape2D).size
	var local := shape.to_local(feet)
	return absf(local.x) <= size.x * 0.5 and local.y >= -size.y * 0.5 + sink_depth
