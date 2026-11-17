extends PlayerJumpState
## Kicking off a climb wall: a normal jump with a small nudge away from the
## wall, turned to face away from it. The input steers as in any jump:
## holding away crosses to the far wall, holding toward the wall turns back
## and, with attack held, grabs the same wall again higher up.


func enter(previous_state: StringName) -> void:
	super(previous_state)
	var wall := player.wall_jump
	player.velocity.x = -wall.side * wall.kick_push
	player.set_facing(-wall.side)
	wall.let_go()
