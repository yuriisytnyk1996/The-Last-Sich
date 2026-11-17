extends PlayerState
## Kneeling at a rest point, once the player can travel. The rest point has
## already healed them; the world keeps running while they go down on one
## knee, so the HUD shows the refill. Once down (`kneel_time`), the kneel
## prompt opens (`Events.travel_offered`) and pauses the game. When it
## closes, the player takes `rise_time` to get up. The hurtbox is off
## throughout: plain invincibility would blink the player, and the pause
## could freeze that blink with the player hidden.
##
## Placeholder animation: the visual squashes toward the feet and back.

## Seconds to go down on one knee; the prompt opens when this ends.
@export var kneel_time := 0.8
## Seconds to get back up after the prompt closes.
@export var rise_time := 0.3
## Height of the visual while kneeling, as a fraction of standing height.
@export_range(0.1, 1.0) var kneel_height := 0.65

var _time_left := 0.0
var _offered := false
var _tween: Tween


func enter(_previous_state: StringName) -> void:
	_time_left = kneel_time
	_offered = false
	player.hurtbox.set_deferred(&"monitoring", false)
	_squash_to(kneel_height, kneel_time, Tween.EASE_OUT)


func exit() -> void:
	# Back on, hitboxes it now overlaps (spikes) hit at once.
	player.hurtbox.set_deferred(&"monitoring", true)
	if _tween:
		_tween.kill()
	player.visual.scale.y = 1.0


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	_time_left -= delta
	if _time_left > 0.0:
		return
	if not _offered:
		# Pauses the tree: the next update runs once the prompt is closed.
		_offered = true
		_time_left = rise_time
		Events.travel_offered.emit()
		_squash_to(1.0, rise_time, Tween.EASE_IN_OUT)
	else:
		finished.emit(ground_state())


## Tweens the visual's height; its origin is at the feet, so it sinks down.
func _squash_to(height: float, duration: float, ease_type: Tween.EaseType) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(ease_type)
	_tween.tween_property(player.visual, ^"scale:y", height, duration)
