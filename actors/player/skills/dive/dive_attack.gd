class_name PlayerDiveAttack
extends Node
## The dive skill line (`dive_1` to `dive_3`).
##
## In the air, not rising, with down held and attack held for `hold_time`,
## the player dives: a short hang, a fast plunge that hits what it passes,
## and a landing that hits everything around. Only when the ground is at
## least `min_height` below. Level 2 widens the landing; level 3 adds a
## shockwave (`shockwave_scene`) when the dive started `shockwave_height`
## or more above the ground.

## Seconds attack must be held (with down) to dive.
@export var hold_time := 0.18
## The ground must be at least this far below the feet (px).
@export var min_height := 40.0
## Level 3: dives from at least this high end in a shockwave (px).
@export var shockwave_height := 96.0
@export var shockwave_scene: PackedScene

var _held := 0.0

@onready var player := owner as Player


func _ready() -> void:
	Pool.prewarm(shockwave_scene, 1)


func _physics_process(delta: float) -> void:
	_held = _held + delta if Input.is_action_pressed("attack") else 0.0


func level() -> int:
	return player.skills.level(&"dive")


func wants() -> bool:
	return (
		level() > 0
		and not player.is_on_floor()
		and player.velocity.y >= 0.0
		and player.get_vertical_axis() >= player.attack_vertical_threshold
		and _held >= hold_time
		and height_above_ground() >= min_height
	)


## Distance from the feet down to solid ground or a platform, up to
## `shockwave_height` + 1 (px).
func height_above_ground() -> float:
	var reach := shockwave_height + 1.0
	var probe := player.global_transform
	var collision := KinematicCollision2D.new()
	if player.test_move(probe, Vector2(0.0, reach), collision):
		return collision.get_travel().y
	return reach


func spawn_shockwave() -> void:
	if shockwave_scene:
		PlayerBlast.spawn(
			shockwave_scene, player.get_parent(), player.global_position, player.stats
		)
