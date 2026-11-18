class_name PlayerRangedAttack
extends Node
## The ranged skill line (`ranged_1` to `ranged_3`).
##
## Letting go of the ranged button throws a bolt of spirit (`bolt_scene`)
## for `spirit_cost`, on the ground or in the air. Only one bolt flies at a
## time. Level 2 makes it come back; level 3 also bursts where it turns
## (`burst_scene`).

@export var spirit_cost := 6.0
@export var bolt_scene: PackedScene
@export var burst_scene: PackedScene
## Where the bolt starts, in front of the chest when facing right (px).
@export var bolt_offset := Vector2(12, -18)

var _bolt: PlayerProjectile
var _pressed := false

@onready var player := owner as Player


func _ready() -> void:
	Pool.prewarm(bolt_scene, 1)
	Pool.prewarm(burst_scene, 1)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ranged"):
		_pressed = true


func level() -> int:
	return player.skills.level(&"ranged")


## The button was pressed and is now let go, the skill is learned, no bolt
## is flying and there is enough spirit. Clears the press either way.
func wants() -> bool:
	if not (_pressed and Input.is_action_just_released("ranged")):
		return false
	_pressed = false
	return level() > 0 and not Pool.in_use(_bolt) and player.spirit.current >= spirit_cost


## Pays the spirit and throws the bolt.
func fire() -> void:
	if bolt_scene == null or not player.spirit.spend(spirit_cost):
		return
	_bolt = Pool.take(bolt_scene) as PlayerProjectile
	var offset := Vector2(bolt_offset.x * player.facing, bolt_offset.y)
	var burst := burst_scene if level() >= 3 else null
	_bolt.launch(player.global_position + offset, player.facing, player, level() >= 2, burst)
	player.get_parent().add_child(_bolt)
