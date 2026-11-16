extends PlayerState
## Throwing a spirit bolt (see `PlayerRangedAttack`). On the ground the
## player stops; in the air they hang still until the bolt is out, then
## fall. The bolt leaves after `fire_delay`; the throw ends after
## `cast_time`.

@export var fire_delay := 0.1
@export var cast_time := 0.3

var _time := 0.0
var _fired := false


func enter(_previous_state: StringName) -> void:
	_time = 0.0
	_fired = false
	player.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	_time += delta
	player.velocity.x = 0.0
	if _fired or player.is_on_floor():
		player.apply_gravity(delta)
	else:
		player.velocity.y = 0.0
	player.move_and_slide()

	if not _fired and _time >= fire_delay:
		_fired = true
		player.skills.ranged.fire()
	if _time >= cast_time:
		finished.emit(ground_state() if player.is_on_floor() else FALL)
