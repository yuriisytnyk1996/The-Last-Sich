extends PlayerState
## The dive (see `PlayerDiveAttack`), in four phases:
## - HANG: stops in the air for `hang_time`.
## - PLUNGE: straight down at `plunge_speed`, `plunge_hitbox` on.
## - LAND: `landing_hitbox` (or `wide_landing_hitbox` from level 2) on for
##   `land_time`, with a shake and rumble. At level 3 a dive started high
##   enough adds a shockwave.
## - RECOVER: planted for `recover_time`.
## Invincible from start to landing. Never ends in a hard landing.

enum Phase { HANG, PLUNGE, LAND, RECOVER }

@export var plunge_hitbox: Hitbox
@export var landing_hitbox: Hitbox
@export var wide_landing_hitbox: Hitbox
@export var hang_time := 0.12
@export var plunge_speed := 480.0
@export var land_time := 0.1
@export var recover_time := 0.25
@export var land_shake := 0.6

var _phase := Phase.HANG
var _time_left := 0.0
var _high := false
var _landing: Hitbox


func enter(_previous_state: StringName) -> void:
	var dive := player.skills.dive
	_high = dive.level() >= 3 and dive.height_above_ground() >= dive.shockwave_height
	_phase = Phase.HANG
	_time_left = hang_time
	player.velocity = Vector2.ZERO
	player.consume_attack()
	player.hurtbox.set_invincible_for(INF)


func exit() -> void:
	plunge_hitbox.set_active(false)
	landing_hitbox.set_active(false)
	wide_landing_hitbox.set_active(false)
	player.hurtbox.clear_invincibility()


func physics_update(delta: float) -> void:
	_time_left -= delta
	match _phase:
		Phase.HANG:
			player.velocity = Vector2.ZERO
			if _time_left <= 0.0:
				_phase = Phase.PLUNGE
				plunge_hitbox.set_active(true)
		Phase.PLUNGE:
			player.velocity = Vector2(0.0, plunge_speed)
			player.move_and_slide()
			if player.is_on_floor():
				_land()
		Phase.LAND, Phase.RECOVER:
			_settle(delta)


func _land() -> void:
	plunge_hitbox.set_active(false)
	var dive := player.skills.dive
	_landing = wide_landing_hitbox if dive.level() >= 2 else landing_hitbox
	_landing.set_active(true)
	Events.camera_shake_requested.emit(land_shake)
	Rumble.play(0.6, 0.2)
	if _high:
		dive.spawn_shockwave()
	player.hurtbox.clear_invincibility()
	_phase = Phase.LAND
	_time_left = land_time


func _settle(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()
	if _phase == Phase.LAND and _time_left <= 0.0:
		_landing.set_active(false)
		_phase = Phase.RECOVER
		_time_left = recover_time
	elif _phase == Phase.RECOVER and _time_left <= 0.0:
		finished.emit(ground_state() if player.is_on_floor() else FALL)
