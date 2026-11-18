extends PlayerState
## A cutscene has the player (see `PlayerScripted`): input is ignored and
## they stand, or walk to the spot the cutscene asked for. A wall in the
## way ends the walk there. The hurtbox is off throughout, like kneeling:
## plain invincibility would blink the player.


func enter(_previous_state: StringName) -> void:
	player.hurtbox.set_deferred(&"monitoring", false)


func exit() -> void:
	# Back on, hitboxes it now overlaps (spikes) hit at once.
	player.hurtbox.set_deferred(&"monitoring", true)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var scripted := player.scripted
	if scripted.is_walking():
		_walk(delta, scripted)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()


func _walk(delta: float, scripted: PlayerScripted) -> void:
	var offset := scripted.target_x - player.global_position.x
	var blocked := player.is_on_wall() and player.get_wall_normal().x * offset < 0.0
	if absf(offset) <= scripted.arrive_distance or blocked:
		player.velocity.x = 0.0
		scripted.arrive()
		return
	player.set_facing(offset)
	var speed := player.get_run_speed() * scripted.walk_speed_factor
	# Never past the spot in one frame.
	player.velocity.x = signf(offset) * minf(speed, absf(offset) / delta)
