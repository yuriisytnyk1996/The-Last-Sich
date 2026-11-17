extends BossAttack
## Crouches, leaps at the spot where the player stands and slams down.
## The landing hits all around the boss (`hitbox`) and sends a shockwave
## along the floor each way: jump over it. The active window starts on
## landing, however long the leap takes.

## A low `EnemyProjectile` sent each way on landing.
@export var shockwave_scene: PackedScene
## Seconds in the air.
@export var leap_time := 0.6
## The furthest it leaps (px).
@export var max_leap_distance := 220.0
## Camera trauma on landing (0 to 1).
@export var land_shake := 0.5
## Shockwaves start this far to each side and this high above the feet (px).
@export var wave_offset := Vector2(14, -7)

var _airborne := false
var _left_floor := false


func enter(previous_state: StringName) -> void:
	_airborne = false
	super(previous_state)


func physics_update(delta: float) -> void:
	if _airborne:
		_fly(delta)
	else:
		super(delta)


func _next_phase() -> void:
	if _phase == Phase.STARTUP:
		_leap()
	else:
		super()


## Ballistic jump that lands level with the take-off after `leap_time`.
func _leap() -> void:
	_show_telegraph(false)
	_airborne = true
	_left_floor = false
	var dx := enemy.target_point().x - enemy.global_position.x
	dx = clampf(dx, -max_leap_distance, max_leap_distance)
	enemy.velocity = Vector2(dx / leap_time, -0.5 * enemy.gravity * leap_time)


func _fly(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	if not enemy.is_on_floor():
		_left_floor = true
	elif _left_floor:
		_land()


func _land() -> void:
	_airborne = false
	enemy.velocity.x = 0.0
	_phase = Phase.ACTIVE
	_time_left = active * time_scale()
	_set_hitbox_active(true)
	Events.camera_shake_requested.emit(land_shake)
	if shockwave_scene:
		_send_wave(-1)
		_send_wave(1)


func _send_wave(direction: int) -> void:
	var wave := shockwave_scene.instantiate() as EnemyProjectile
	wave.attacker_stats = enemy.stats
	var offset := Vector2(wave_offset.x * direction, wave_offset.y)
	wave.launch(enemy.global_position + offset, Vector2(direction, 0))
	enemy.get_parent().add_child(wave)
