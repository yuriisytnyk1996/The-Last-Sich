class_name LiquidDrop
extends EnemyProjectile
## A drop of liquid from a `DripTrap`. It starts still and falls with
## gravity, then bursts on the first thing it touches: the player, a
## wall, the floor or a one-way plank (mask `world` and `platforms`).

@export var fall_acceleration := 700.0
@export var max_fall_speed := 380.0


func _physics_process(delta: float) -> void:
	_velocity.y = minf(_velocity.y + fall_acceleration * delta, max_fall_speed)
	super(delta)
