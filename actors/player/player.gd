class_name Player
extends CharacterBody2D
## The player character.
##
## This script holds tuning values and shared helpers. The behaviour itself
## (what happens when idle, running, jumping...) lives in the state nodes
## under StateMachine, one small script per state.

## Physics layer of one-way platforms, switched off while dropping through.
const PLATFORMS_LAYER := 7

@export_group("Run")
@export var run_speed := 140.0
@export var acceleration := 1200.0
@export var friction := 1400.0
@export var air_acceleration := 900.0

@export_group("Jump")
## Jump is defined by height and timing instead of raw gravity numbers,
## which makes it much easier to tune by feel.
@export var jump_height := 52.0
@export var jump_time_to_peak := 0.36
@export var jump_time_to_fall := 0.28
## How much upward speed is kept when the jump button is released early.
@export_range(0.0, 1.0) var jump_cut_multiplier := 0.45
@export var max_fall_speed := 360.0
## Grace period to still jump after walking off a ledge.
@export var coyote_time := 0.1
## A jump pressed slightly before landing still counts.
@export var jump_buffer_time := 0.12

## Down + jump on a one-way platform drops through it. The platforms layer
## stays off for this long, enough to fall clear of the plank.
@export var drop_through_time := 0.25

@export_group("Dash")
@export var dash_speed := 300.0
@export var dash_duration := 0.18
@export var dash_cooldown := 0.4

@export_group("Attack")
## The swing is split into wind-up, hitbox-on and recovery windows (s).
@export var attack_startup := 0.05
@export var attack_active := 0.1
@export var attack_recovery := 0.15
## An attack pressed slightly before the current action ends still counts.
@export var attack_buffer_time := 0.12
## How far up or down the stick must be held for an up or crouch attack.
## Diagonals below this give a side attack.
@export_range(0.0, 1.0) var attack_vertical_threshold := 0.75

var facing := 1

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _attack_buffer_timer := 0.0
var _dash_cooldown_timer := 0.0
var _air_dash_available := true
var _drop_through_timer := 0.0

@onready var jump_velocity: float = -2.0 * jump_height / jump_time_to_peak
@onready var jump_gravity: float = 2.0 * jump_height / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = 2.0 * jump_height / (jump_time_to_fall * jump_time_to_fall)

@onready var visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var state_machine: StateMachine = $StateMachine
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var damage: PlayerDamage = $Damage


func _physics_process(delta: float) -> void:
	# A parent runs before its children, so the states always see fresh timers.
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_dash_available = true
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if Input.is_action_just_pressed("attack"):
		_attack_buffer_timer = attack_buffer_time
	else:
		_attack_buffer_timer = maxf(_attack_buffer_timer - delta, 0.0)

	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)

	if _drop_through_timer > 0.0:
		_drop_through_timer -= delta
		if _drop_through_timer <= 0.0:
			set_collision_mask_value(PLATFORMS_LAYER, true)


# --- Helpers used by the states ---


func get_move_axis() -> float:
	return Input.get_axis("move_left", "move_right")


## Up is negative, matching screen coordinates.
func get_vertical_axis() -> float:
	return Input.get_axis("move_up", "move_down")


func set_facing(direction: float) -> void:
	facing = 1 if direction > 0.0 else -1
	visual.scale.x = facing


func apply_gravity(delta: float) -> void:
	var gravity := jump_gravity if velocity.y < 0.0 else fall_gravity
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func move_horizontally(delta: float, accel: float, decel: float) -> void:
	var axis := get_move_axis()
	if axis != 0.0:
		velocity.x = move_toward(velocity.x, axis * run_speed, accel * delta)
		set_facing(axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func wants_jump() -> bool:
	return _jump_buffer_timer > 0.0


func has_coyote_time() -> bool:
	return _coyote_timer > 0.0


func consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


## Down + jump while standing only on one-way platforms (no solid floor below).
func wants_drop_through() -> bool:
	if not (wants_jump() and is_on_floor()):
		return false
	if get_vertical_axis() < attack_vertical_threshold:
		return false
	set_collision_mask_value(PLATFORMS_LAYER, false)
	var on_solid := test_move(global_transform, Vector2(0.0, 1.0))
	set_collision_mask_value(PLATFORMS_LAYER, true)
	return not on_solid


func start_drop_through() -> void:
	consume_jump()
	set_collision_mask_value(PLATFORMS_LAYER, false)
	_drop_through_timer = drop_through_time


func wants_dash() -> bool:
	return (
		Input.is_action_just_pressed("dash")
		and _dash_cooldown_timer <= 0.0
		and (is_on_floor() or _air_dash_available)
	)


func start_dash() -> void:
	_dash_cooldown_timer = dash_cooldown
	if not is_on_floor():
		_air_dash_available = false


func wants_attack() -> bool:
	return _attack_buffer_timer > 0.0


func consume_attack() -> void:
	_attack_buffer_timer = 0.0


func set_camera_limits(bounds: Rect2i) -> void:
	camera.limit_left = bounds.position.x
	camera.limit_top = bounds.position.y
	camera.limit_right = bounds.end.x
	camera.limit_bottom = bounds.end.y


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	_drop_through_timer = 0.0
	set_collision_mask_value(PLATFORMS_LAYER, true)
	camera.reset_smoothing.call_deferred()
	state_machine.transition_to(PlayerState.IDLE)
	# After the transition: leaving Hurt would start invincibility again.
	damage.reset()
