extends PlayerComboStrike
## The released charged slash: a wide heavy slash. At level 3 of the
## charged line it also sends a wave along the ground.


func on_hitbox_on() -> void:
	player.skills.charged.fire_wave()
