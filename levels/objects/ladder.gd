@tool
class_name Ladder
extends Node2D
## A ladder the player can climb. The origin is the top centre and the
## ladder reaches `height` px down. Put a one-way plank tile at the top so
## the player can stand on it and climb down with down.
##
## No physics: the player finds ladders through the "ladders" group by
## position, which also works the frame a room is loaded.

const WIDTH := 16.0
const RAIL_COLOR := Color(0.45, 0.3, 0.16)
const RUNG_COLOR := Color(0.6, 0.42, 0.22)
const RUNG_SPACING := 8.0

@export var height := 64.0:
	set(value):
		height = maxf(value, RUNG_SPACING)
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"ladders")


func top() -> float:
	return global_position.y


func bottom() -> float:
	return global_position.y + height


## The ladder `feet` are on: within `reach` of its centre and between its
## top and bottom. With `body_height`, a ladder that ends above the feet
## still counts while it reaches that far up the body.
static func find_at(tree: SceneTree, feet: Vector2, reach: float, body_height := 0.0) -> Ladder:
	for node in tree.get_nodes_in_group(&"ladders"):
		var ladder := node as Ladder
		if (
			absf(feet.x - ladder.global_position.x) <= reach
			and feet.y >= ladder.top() - 1.0
			and feet.y - body_height <= ladder.bottom() + 1.0
		):
			return ladder
	return null


## The ladder whose top `feet` stand on.
static func find_top_at(tree: SceneTree, feet: Vector2, reach: float) -> Ladder:
	var ladder := find_at(tree, feet, reach)
	if ladder and absf(feet.y - ladder.top()) <= 2.0:
		return ladder
	return null


func _draw() -> void:
	var half := WIDTH / 2.0
	draw_rect(Rect2(-half, 0.0, 2.0, height), RAIL_COLOR)
	draw_rect(Rect2(half - 2.0, 0.0, 2.0, height), RAIL_COLOR)
	var y := RUNG_SPACING / 2.0
	while y < height:
		draw_rect(Rect2(-half + 2.0, y, WIDTH - 4.0, 2.0), RUNG_COLOR)
		y += RUNG_SPACING
