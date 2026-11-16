@tool
class_name AreaEffect
extends Area2D
## A zone that changes the player while they are inside it: wind, mud,
## poison. Only the player is affected; enemies ignore zones.
##
## The origin is the top left corner and the zone reaches `size` px right
## and down. The collision shape is built from `size` when the game runs,
## so a zone is resized with one value. It draws a placeholder tint, also
## in the editor. Put it in the room's `Layout`.
##
## Subclasses override the factor functions (read by `PlayerAreaEffects`)
## and the `_player_entered` / `_player_exited` hooks.

const PLAYER_LAYER := 2

@export var size := Vector2(64.0, 64.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()

## The player inside, or null.
var player: Player


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(PLAYER_LAYER, true)
	monitorable = false
	add_child(make_shape())
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## A new collision shape covering the zone.
func make_shape() -> CollisionShape2D:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = size / 2.0
	return shape


## Multiplies the run speed.
func speed_factor() -> float:
	return 1.0


## Multiplies the jump height.
func jump_factor() -> float:
	return 1.0


## Sideways speed added to running and drifting (px/s).
func wind_speed() -> float:
	return 0.0


## Placeholder tint of the zone.
func _get_color() -> Color:
	return Color(1.0, 1.0, 1.0, 0.15)


func _player_entered() -> void:
	pass


func _player_exited() -> void:
	pass


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _get_color())


func _on_body_entered(body: Node2D) -> void:
	var entered := body as Player
	if entered == null:
		return
	player = entered
	player.area_effects.enter(self)
	_player_entered()


func _on_body_exited(body: Node2D) -> void:
	if body != player:
		return
	player.area_effects.exit(self)
	player = null
	_player_exited()
