class_name PlayerChargedAttack
extends Node
## The charged slash skill line (`charged_1` to `charged_3`).
##
## Holding attack through a ground side slash goes into the Charge state
## when it ends. Charging takes `charge_time` (level 1) or
## `swift_charge_time` (level 2 and up); letting go when it is full gives
## the ChargedSlash, letting go earlier cancels it. Level 3 also sends a
## wave along the ground (`wave_scene`) as the slash comes out.

@export var charge_time := 1.5
@export var swift_charge_time := 0.75
@export var wave_scene: PackedScene
## Where the wave starts, in front of the feet when facing right (px).
@export var wave_offset := Vector2(16, -10)

@onready var player := owner as Player


func _ready() -> void:
	Pool.prewarm(wave_scene, 1)


func level() -> int:
	return player.skills.level(&"charged")


## The skill is learned, attack is still held and the player is on the
## ground.
func wants() -> bool:
	return level() > 0 and Input.is_action_pressed("attack") and player.is_on_floor()


func full_charge_time() -> float:
	return charge_time if level() == 1 else swift_charge_time


func fire_wave() -> void:
	if level() < 3 or wave_scene == null:
		return
	var wave := Pool.take(wave_scene) as PlayerProjectile
	var offset := Vector2(wave_offset.x * player.facing, wave_offset.y)
	wave.launch(player.global_position + offset, player.facing, player)
	player.get_parent().add_child(wave)
