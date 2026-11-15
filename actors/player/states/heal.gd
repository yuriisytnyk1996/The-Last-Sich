extends PlayerState
## Drinking a healing flask. The flask is used and the health restored as
## soon as this starts; then the player stands still for `drink_time`
## while the aura glows and fades. A hit interrupts it like any other
## state, but the health stays healed.

## Placeholder glow behind the body, shown while drinking.
@export var aura: CanvasItem

var _time_left := 0.0
var _fade: Tween


func enter(_previous_state: StringName) -> void:
	player.flasks.drink()
	_time_left = player.flasks.drink_time
	aura.visible = true
	aura.modulate.a = 1.0
	_fade = create_tween()
	_fade.tween_property(aura, ^"modulate:a", 0.0, _time_left).set_ease(Tween.EASE_IN)


func exit() -> void:
	if _fade:
		_fade.kill()
	aura.visible = false


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	_time_left -= delta
	if not player.is_on_floor():
		finished.emit(FALL)
	elif _time_left <= 0.0:
		finished.emit(ground_state())
