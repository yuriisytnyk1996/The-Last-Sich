@tool
class_name ClimbWall
extends Area2D
## Marks a wall the player can cling to and kick off (see
## `PlayerWallJump`). Walls without one can't be climbed,
## so level design decides where the move works.
##
## Lay it over the wall tiles: the origin is the top left corner and it
## covers `size` px. The area reaches `MARGIN` px further on both sides,
## into the air the player clings in. The collision shape is built from
## `size` when the game runs. It draws placeholder grip marks, also in the
## editor. Put it in the room's `Layout`.

const PLAYER_LAYER := 2
## How far the area reaches past the wall on each side (px).
const MARGIN := 8.0
const COLOR := Color(0.75, 0.7, 0.55, 0.5)
const MARK_SPACING := 8.0

@export var size := Vector2(32.0, 128.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(PLAYER_LAYER, true)
	monitorable = false
	var rect := RectangleShape2D.new()
	rect.size = size + Vector2(2.0 * MARGIN, 0.0)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = size / 2.0
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Short horizontal notches down both faces of the wall.
func _draw() -> void:
	var y := MARK_SPACING / 2.0
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(3.0, y), COLOR)
		draw_line(Vector2(size.x - 3.0, y), Vector2(size.x, y), COLOR)
		y += MARK_SPACING


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).wall_jump.enter(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).wall_jump.exit(self)
