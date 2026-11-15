class_name Hitbox
extends Area2D
## The damaging part of an attack or hazard.
##
## A hitbox does no detection itself: Hurtboxes detect it. Turning it off
## disables its collision shapes, so turning it on again counts as a new hit
## on everything it overlaps. While inactive it is also hidden, so a child
## placeholder graphic shows exactly when the hitbox is live.

@export var damage := 1
@export var knockback_force := 120.0
## Direction when the hitbox faces right. Mirrored when a parent is flipped
## with a negative scale.x.
@export var knockback_direction := Vector2.RIGHT
@export var active_on_start := false

var _active := false


func _ready() -> void:
	monitoring = false
	set_active(active_on_start)


func set_active(value: bool) -> void:
	_active = value
	visible = value
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			# Deferred: shapes can't change during a physics callback.
			child.set_deferred(&"disabled", not value)


func is_active() -> bool:
	return _active


func get_knockback() -> Vector2:
	var direction := knockback_direction.normalized()
	if global_transform.x.x < 0.0:
		direction.x = -direction.x
	return direction * knockback_force
