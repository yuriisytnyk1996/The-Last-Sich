class_name Enemy
extends CharacterBody2D
## Base for every enemy: shared tuning and the helpers its states use
## (gravity, walking, turning, ledge checks, finding the player).
##
## Behaviour lives in the state nodes under StateMachine, hit reactions in
## the Damage node. Enemies join the "enemies" group, and the room calls
## `reset()` on all of them when the player respawns.

@export_enum("Left:-1", "Right:1") var start_facing := 1

@export_group("Movement")
@export var patrol_speed := 30.0
@export var chase_speed := 70.0
@export var acceleration := 600.0
@export var friction := 800.0
@export var gravity := 900.0
@export var max_fall_speed := 360.0
## Seconds a patrolling enemy waits at a wall or ledge before turning.
@export var turn_pause := 0.6

@export_group("Senses")
## How far ahead the enemy notices the player (px). It can't see behind.
@export var sight_range := 140.0
## How far above or below the player can be and still count (px).
@export var sight_height := 40.0
## A chasing enemy gives up when the player gets this far away (px).
@export var lose_range := 220.0
## The player must be this far to one side before the enemy turns (px).
@export var turn_dead_zone := 4.0

@export_group("Attack")
## Horizontal distance to the player at which an attack starts (px).
@export var attack_range := 30.0

var facing := 1

var _target: Node2D
var _target_alive := true
var _attack_cooldown := 0.0
var _spawn_position := Vector2.ZERO

@onready var visual: Node2D = $Visual
@onready var floor_probe: RayCast2D = $Visual/FloorProbe
@onready var state_machine: StateMachine = $StateMachine
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact: Hitbox = $Contact
@onready var damage: EnemyDamage = $Damage


func _ready() -> void:
	add_to_group(&"enemies")
	_spawn_position = global_position
	set_facing(start_facing)
	Events.player_health_changed.connect(_on_player_health_changed)


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)


# --- Movement helpers ---


func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func walk(delta: float, speed: float) -> void:
	velocity.x = move_toward(velocity.x, facing * speed, acceleration * delta)


func stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func set_facing(direction: float) -> void:
	facing = 1 if direction > 0.0 else -1
	visual.scale.x = facing


func turn_around() -> void:
	set_facing(-facing)


## A wall or a drop right in front. Enemies never walk off ledges.
func is_path_blocked() -> bool:
	if is_on_wall() and signf(get_wall_normal().x) == -facing:
		return true
	return is_on_floor() and not floor_probe.is_colliding()


# --- Senses ---


## The player is alive, in front and within sight.
func can_see_target() -> bool:
	if not _has_live_target():
		return false
	var offset := _target_offset()
	return offset.x * facing >= 0.0 and absf(offset.x) <= sight_range and _target_level(offset)


## A chasing enemy keeps chasing while this is true.
func can_track_target() -> bool:
	return _has_live_target() and _target_offset().length() <= lose_range


func is_target_in_attack_range() -> bool:
	if not _has_live_target():
		return false
	var offset := _target_offset()
	return absf(offset.x) <= attack_range and _target_level(offset)


func face_target() -> void:
	if not _has_live_target():
		return
	var dx := _target_offset().x
	if absf(dx) > turn_dead_zone:
		set_facing(dx)


# --- Attack and lifecycle ---


func can_attack() -> bool:
	return _attack_cooldown <= 0.0


func start_attack_cooldown(seconds: float) -> void:
	_attack_cooldown = seconds


## Turns the hurtbox and contact damage on or off (off while dead).
func set_combat_enabled(enabled: bool) -> void:
	# Deferred: this can run inside a physics callback.
	hurtbox.set_deferred(&"monitoring", enabled)
	contact.set_active(enabled)


## Back to the spawn point, alive and patrolling.
func reset() -> void:
	global_position = _spawn_position
	velocity = Vector2.ZERO
	set_facing(start_facing)
	_attack_cooldown = 0.0
	damage.reset()
	state_machine.transition_to(EnemyState.PATROL)


func _has_live_target() -> bool:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(&"player") as Node2D
	return _target != null and _target_alive


func _target_offset() -> Vector2:
	return _target.global_position - global_position


func _target_level(offset: Vector2) -> bool:
	return absf(offset.y) <= sight_height


func _on_player_health_changed(current: int, _maximum: int) -> void:
	_target_alive = current > 0
