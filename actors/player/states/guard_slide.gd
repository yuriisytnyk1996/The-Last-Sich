extends PlayerState
## Slid back by a heavy hit caught on the guard. Tuning lives in
## `PlayerGuardSlide`.
##
## Invincible and without control. The hit-stop plays first (the clock is
## frozen, so the slide waits), then the player slides away from the hit,
## still facing it, slowing down. A wall or the end of the slide stops it;
## running off a ledge drops into Fall. In the last `recover_window` the
## guard drops and holding dash cancels into a dash towards the attacker.

## Placeholder shown while the guard is up (shared with the Parry state).
@export var guard: CanvasItem

var _elapsed := 0.0


func enter(_previous_state: StringName) -> void:
	_elapsed = 0.0
	player.hurtbox.set_invincible_for(INF)
	player.consume_attack()
	player.set_facing(-player.guard_slide.direction)
	player.velocity = Vector2.ZERO
	guard.visible = true
	guard.modulate = Color(3.0, 3.0, 3.0)
	player.guard_slide.play_feedback()


func exit() -> void:
	guard.visible = false
	guard.modulate = Color.WHITE
	player.hurtbox.set_invincible_for(player.guard_slide.grace_time)


func physics_update(delta: float) -> void:
	if delta <= 0.0:
		return
	var slide := player.guard_slide
	var before := _progress()
	_elapsed = minf(_elapsed + delta, slide.slide_time)
	var step := (_progress() - before) * slide.distance
	player.velocity.x = slide.direction * step / delta
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		player.velocity.x = 0.0
		finished.emit(FALL)
		return
	var left := slide.slide_time - _elapsed
	if left <= slide.recover_window:
		guard.visible = false
		if Input.is_action_pressed("dash") and player.dash_ready():
			finished.emit(DASH)
			return
	if left <= 0.0 or player.is_on_wall():
		player.velocity.x = 0.0
		finished.emit(ground_state())


## How far along the slide is, from 0 to 1, eased.
func _progress() -> float:
	var slide := player.guard_slide
	return ease(_elapsed / slide.slide_time, slide.slide_ease)
