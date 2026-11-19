class_name Falcon
extends Node2D
## One falcon of a `FalconFlock`. It hovers by the player until the flock
## sends it at an enemy (`launch()`): then it flies at the enemy's body,
## speeding up to `max_speed`, with its `Talons` hitbox out. It is gone
## after its first hit, on reaching where the enemy was, after
## `lifetime`, or on a room change.

@export var start_speed := 120.0
@export var max_speed := 340.0
@export var acceleration := 900.0
## Seconds in flight before it gives up.
@export var lifetime := 1.5
## How close to the target point counts as reaching it (px).
@export var reach_distance := 4.0
@export var fade_time := 0.15

var _target: Enemy
var _target_point := Vector2.ZERO
var _speed := 0.0
var _time := 0.0
var _flying := false

@onready var talons: Hitbox = $Talons


func _ready() -> void:
	talons.hit_landed.connect(func(_hurtbox: Hurtbox) -> void: _vanish())


## Sends it at `enemy`. `player` scales the damage, with `strength`. Call
## once it is under the room's parent, so it outlives the flock.
func launch(enemy: Enemy, player: Player, strength: float) -> void:
	_target = enemy
	_target_point = body_point(enemy)
	talons.attacker_stats = player.stats
	talons.damage = roundi(talons.damage * strength)
	talons.set_active(true)
	_speed = start_speed
	_flying = true
	Events.room_change_requested.connect(func(_r: String, _e: StringName) -> void: queue_free())


## The centre of `enemy`'s hurtbox shape, where falcons aim.
static func body_point(enemy: Enemy) -> Vector2:
	for child in enemy.hurtbox.get_children():
		if child is CollisionShape2D:
			return (child as Node2D).global_position
	return enemy.hurtbox.global_position


func is_flying() -> bool:
	return _flying


func _physics_process(delta: float) -> void:
	if not _flying:
		return
	_time += delta
	if is_instance_valid(_target) and not _target.health.is_dead():
		_target_point = body_point(_target)
	_speed = minf(_speed + acceleration * delta, max_speed)
	var to_target := _target_point - global_position
	scale.x = 1.0 if to_target.x >= 0.0 else -1.0
	if to_target.length() <= reach_distance or _time >= lifetime:
		_vanish()
		return
	global_position += to_target.normalized() * minf(_speed * delta, to_target.length())


func _vanish() -> void:
	if not _flying:
		return
	_flying = false
	talons.set_active(false)
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
