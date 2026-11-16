extends PlayerState
## Charging the charged slash (see `PlayerChargedAttack`): planted, attack
## held. Full after `full_charge_time()`, when `glow` lights up. Letting go
## when full releases the ChargedSlash; letting go earlier cancels it.

## Shown while the charge is full.
@export var glow: CanvasItem

var _time := 0.0


func enter(_previous_state: StringName) -> void:
	_time = 0.0
	player.velocity.x = 0.0
	glow.hide()


func exit() -> void:
	glow.hide()


func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()

	_time += delta
	var full := _time >= player.skills.charged.full_charge_time()
	glow.visible = full
	if not player.is_on_floor():
		finished.emit(FALL)
	elif not Input.is_action_pressed("attack"):
		player.consume_attack()
		finished.emit(CHARGED_SLASH if full else ground_state())
