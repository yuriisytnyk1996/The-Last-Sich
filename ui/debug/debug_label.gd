extends Label
## Shows the player's current state while you tune movement.
## Hide or remove it for release builds.

@export var player: Player


func _process(_delta: float) -> void:
	if player == null or player.state_machine.state == null:
		return
	text = (
		"State: %s\nVelocity: %d, %d\nOn floor: %s\nHealth: %d/%d"
		% [
			player.state_machine.state.name,
			player.velocity.x,
			player.velocity.y,
			player.is_on_floor(),
			player.health.current,
			player.health.max_health,
		]
	)
