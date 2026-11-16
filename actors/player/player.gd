class_name Player
extends CharacterBody2D
## The player character. This script holds tuning values and shared
## helpers. The behaviour itself (what happens when idle, running,
## jumping...) lives in the state nodes under StateMachine, one per state.

## Physics layer of one-way platforms, off while dropping through or climbing.
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

@export_group("Landing")
## Falling at least this far (px) ends in a hard landing.
@export var hard_landing_height := 160.0
## Seconds without control after a hard landing.
@export var hard_landing_time := 0.5
## A dash cancels the hard landing once this fraction of it has passed.
@export_range(0.0, 1.0) var hard_landing_dash_cancel := 0.5

@export_group("Dash")
@export var dash_speed := 300.0
@export var dash_duration := 0.18

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

@onready var jump_velocity: float = -2.0 * jump_height / jump_time_to_peak
@onready var jump_gravity: float = 2.0 * jump_height / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = 2.0 * jump_height / (jump_time_to_fall * jump_time_to_fall)

@onready var visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: PlayerStats = $Stats
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var damage: PlayerDamage = $Damage
@onready var drop_through: PlayerDropThrough = $DropThrough
@onready var ladder_climb: PlayerLadderClimb = $LadderClimb
@onready var ledge_grab: PlayerLedgeGrab = $LedgeGrab
@onready var flasks: PlayerFlasks = $Flasks
@onready var parry: PlayerParry = $Parry
@onready var wallet: PlayerWallet = $Wallet
@onready var safe_ground: PlayerSafeGround = $SafeGround
@onready var spirit: PlayerSpirit = $Spirit
@onready var skills: PlayerSkills = $Skills
@onready var area_effects: PlayerAreaEffects = $AreaEffects
@onready var inventory: PlayerInventory = $Inventory


func _physics_process(delta: float) -> void:
	# A parent runs before its children, so the states always see fresh timers.
	if is_on_floor():
		_coyote_timer = coyote_time
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


## Runs or drifts toward the input. Zones change it: mud slows the run,
## wind adds its speed, so letting go carries the player along.
func move_horizontally(delta: float, accel: float, decel: float) -> void:
	var axis := get_move_axis()
	var wind := area_effects.wind_speed()
	if axis != 0.0:
		var target := axis * run_speed * area_effects.speed_factor() + wind
		velocity.x = move_toward(velocity.x, target, accel * delta)
		set_facing(axis)
	else:
		velocity.x = move_toward(velocity.x, wind, decel * delta)


## Launch speed of a jump. Mud lowers it.
func get_jump_velocity() -> float:
	return jump_velocity * sqrt(area_effects.jump_factor())


func wants_jump() -> bool:
	return _jump_buffer_timer > 0.0


func has_coyote_time() -> bool:
	return _coyote_timer > 0.0


func consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


## Collide with one-way platforms or pass through them.
func set_platforms_enabled(enabled: bool) -> void:
	set_collision_mask_value(PLATFORMS_LAYER, enabled)


## Dash is a ground move only: never in the air or on a ladder, and a jump
## pressed in the same frame wins.
func wants_dash() -> bool:
	return (
		Input.is_action_just_pressed("dash")
		and not Input.is_action_just_pressed("jump")
		and _dash_cooldown_timer <= 0.0
		and is_on_floor()
	)


func start_dash() -> void:
	_dash_cooldown_timer = stats.get_value(PlayerStats.DASH_COOLDOWN)


func wants_attack() -> bool:
	return _attack_buffer_timer > 0.0


func consume_attack() -> void:
	_attack_buffer_timer = 0.0


## Interact was just pressed while standing or running: use a door or rest point.
func can_interact() -> bool:
	var state := state_machine.state.name
	return (
		Input.is_action_just_pressed("interact")
		and is_on_floor()
		and (state == PlayerState.IDLE or state == PlayerState.RUN)
	)


func set_camera_limits(bounds: Rect2i) -> void:
	camera.limit_left = bounds.position.x
	camera.limit_top = bounds.position.y
	camera.limit_right = bounds.end.x
	camera.limit_bottom = bounds.end.y


func respawn(at: Vector2) -> void:
	global_position = at
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	drop_through.reset()
	ladder_climb.reset()
	# Presses made while dead don't carry over into the new life.
	consume_jump()
	consume_attack()
	camera.reset_smoothing.call_deferred()
	state_machine.transition_to(PlayerState.IDLE)
	# After the transition: leaving Hurt would start invincibility again.
	damage.reset()
	flasks.refill()
