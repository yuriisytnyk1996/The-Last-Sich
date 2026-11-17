extends PlayerState
## Singing the worn duma (see `PlayerDumas`). Planted on the ground with
## no control: the aura rises for `cast_point`, then the spirit is paid
## and the duma's effects start (`PlayerDumas.begin()`), then the player
## holds the pose for `recovery`. A hit before the cast point interrupts
## it with nothing spent; walking off a ledge drops into Fall.

## Placeholder glow behind the body while singing.
@export var aura: CanvasItem
## Seconds from the press to the cast point.
@export var cast_point := 0.4
## Seconds held after the cast point.
@export var recovery := 0.35

var _time := 0.0
var _cast := false
var _glow: Tween


func enter(_previous_state: StringName) -> void:
	_time = 0.0
	_cast = false
	player.consume_attack()
	aura.visible = true
	aura.modulate.a = 0.0
	_glow = create_tween()
	_glow.tween_property(aura, ^"modulate:a", 1.0, cast_point)


func exit() -> void:
	if _glow:
		_glow.kill()
	aura.visible = false


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()
	if not player.is_on_floor():
		finished.emit(FALL)
		return

	_time += delta
	if not _cast and _time >= cast_point:
		_cast = true
		player.dumas.begin()
		_fade_aura()
	if _time >= cast_point + recovery:
		finished.emit(ground_state())


func _fade_aura() -> void:
	aura.modulate = Color(2.0, 2.0, 2.0)
	_glow = create_tween()
	_glow.tween_property(aura, ^"modulate", Color(1, 1, 1, 0), recovery)
