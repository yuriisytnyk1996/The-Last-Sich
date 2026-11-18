class_name GhostPage
extends Node2D
## A loose page blown up by a `GhostTrap`, as if by something unseen. It
## takes one of a few flights at random, at a random pace, sways and spins
## on the way, fades out and goes back to the `Pool`. Only for show: it
## touches nothing. Spawn it with `Pool.take()`, then `launch()`, then add
## it to the room.

## Start velocity of each flight (px/s), picked at random.
const FLIGHTS: Array[Vector2] = [Vector2(-34, -52), Vector2(4, -64), Vector2(38, -48)]

## Seconds a flight lasts at full pace.
@export var flight_time := 1.0
## Slowest and fastest pace (the flight time is divided by it).
@export var pace_range := Vector2(0.5, 1.0)
## Sideways sway (px) and its speed (sways per second).
@export var sway := 6.0
@export var sway_rate := 2.5
## Fastest spin (radians per second).
@export var spin := 6.0
## How fast the page slows down (fraction of speed lost per second).
@export var drag := 1.2
## Part of the flight, at the end, spent fading out.
@export_range(0.0, 1.0) var fade_part := 0.4

var _velocity := Vector2.ZERO
var _spin := 0.0
var _pace := 1.0
var _time := 0.0
var _sway_phase := 0.0
var _base_x := 0.0


func _ready() -> void:
	Events.room_change_requested.connect(_on_room_change_requested)


## Call before adding it to the tree.
func launch(from: Vector2) -> void:
	position = from
	_base_x = from.x
	_pace = randf_range(pace_range.x, pace_range.y)
	_velocity = FLIGHTS.pick_random() * _pace
	_spin = randf_range(-spin, spin) * _pace
	_sway_phase = randf() * TAU
	_time = 0.0
	rotation = randf() * TAU
	modulate.a = 1.0


func _physics_process(delta: float) -> void:
	_time += delta
	var length := flight_time / _pace
	_velocity *= maxf(1.0 - drag * delta, 0.0)
	_base_x += _velocity.x * delta
	position.y += _velocity.y * delta
	position.x = _base_x + sin(_sway_phase + _time * sway_rate * TAU * _pace) * sway
	rotation += _spin * delta
	var fade_start := length * (1.0 - fade_part)
	if _time > fade_start:
		modulate.a = 1.0 - clampf((_time - fade_start) / (length - fade_start), 0.0, 1.0)
	if _time >= length:
		Pool.release(self)


func _on_room_change_requested(_room_path: String, _exit_name: StringName) -> void:
	Pool.release(self)
