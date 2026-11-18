class_name PlayerProjectile
extends Hitbox
## A player attack that flies: the ranged bolt and the charged wave.
##
## Flies straight, speeding up to `max_speed`. After `lifetime` it vanishes,
## or, when launched as returning, slows to a stop, can burst there
## (`burst_scene`), then flies back to the player and vanishes on reaching
## them. It hits every enemy it passes once per flight. A wall (`world`
## layer, set as the mask) or a shield ends it. A room change removes it.
## Spawn it with `Pool.take()`; ending it parks it back in the `Pool`.

enum Flight { OUT, TURN, BACK }

@export var start_speed := 120.0
@export var max_speed := 280.0
@export var acceleration := 900.0
## Seconds flying out before it vanishes or turns around.
@export var lifetime := 0.4
## Seconds to slow down when turning around.
@export var turn_time := 0.15
## How close to the player's chest a returning projectile is caught (px).
@export var catch_distance := 12.0
## Height of the player's chest above the feet, where it flies back to (px).
@export var catch_height := 16.0

var _speed := 0.0
var _time := 0.0
var _direction := 1.0
var _flight := Flight.OUT
var _returns := false
var _burst_scene: PackedScene
var _thrower: Node2D


func _ready() -> void:
	super()
	monitoring = true
	body_entered.connect(_on_body_entered)
	blocked.connect(_on_blocked)
	Events.room_change_requested.connect(_on_room_change_requested)


## Call before adding it to the tree. A `Player` thrower's stats scale the
## damage.
func launch(
	from: Vector2, direction: float, thrower: Node2D, returns := false, burst: PackedScene = null
) -> void:
	position = from
	_direction = signf(direction)
	scale.x = _direction
	_thrower = thrower
	if thrower is Player:
		attacker_stats = (thrower as Player).stats
	_returns = returns
	_burst_scene = burst
	_speed = start_speed
	_time = 0.0
	_flight = Flight.OUT


func _physics_process(delta: float) -> void:
	_time += delta
	match _flight:
		Flight.OUT:
			_speed = minf(_speed + acceleration * delta, max_speed)
			position.x += _direction * _speed * delta
			if _time >= lifetime:
				_end_flight_out()
		Flight.TURN:
			_speed = move_toward(_speed, 0.0, max_speed / turn_time * delta)
			position.x += _direction * _speed * delta
			if _speed <= 0.0:
				_fly_back()
		Flight.BACK:
			_fly_toward_thrower(delta)


func _end_flight_out() -> void:
	if _returns and is_instance_valid(_thrower):
		_flight = Flight.TURN
	else:
		Pool.release(self)


func _fly_back() -> void:
	if _burst_scene:
		PlayerBlast.spawn(_burst_scene, get_parent(), global_position, attacker_stats)
	_flight = Flight.BACK
	scale.x = -_direction
	# A new activation, so enemies hit on the way out can be hit again.
	set_active(true)


func _fly_toward_thrower(delta: float) -> void:
	if not is_instance_valid(_thrower):
		Pool.release(self)
		return
	_speed = minf(_speed + acceleration * delta, max_speed)
	var to_thrower := _thrower.global_position + Vector2.UP * catch_height - global_position
	if to_thrower.length() <= catch_distance:
		Pool.release(self)
		return
	global_position += to_thrower.normalized() * _speed * delta


func _on_body_entered(_body: Node2D) -> void:
	Pool.release(self)


## A shield turned it away.
func _on_blocked(_hurtbox: Hurtbox) -> void:
	Pool.release(self)


func _on_room_change_requested(_room_path: String, _exit_name: StringName) -> void:
	Pool.release(self)
