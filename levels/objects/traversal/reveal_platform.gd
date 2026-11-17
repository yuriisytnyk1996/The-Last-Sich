@tool
class_name RevealPlatform
extends StaticBody2D
## A platform that is only there for a player who can see it. With the
## `PlayerUnlocks.REVEAL_PLATFORMS` unlock it is drawn and solid; without
## it, it is a faint outline the player falls through.
##
## The origin is the top centre. One-way by default (on the `platforms`
## layer, like planks); turn `one_way` off for a solid block on `world`.
## The collision shape is built from `size` when the game runs. It checks
## the player again on `Events.player_unlocks_changed`. Put it in the
## room's `Layout`.

const WORLD_LAYER := 1
const PLATFORMS_LAYER := 7
const COLOR := Color(0.55, 0.75, 0.95)
## Alpha of the outline while hidden.
const HIDDEN_ALPHA := 0.15

@export var size := Vector2(32.0, 8.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()
@export var one_way := true
## Seconds to fade in or out.
@export var fade_time := 0.4

var shown := false
var _shape: CollisionShape2D
var _tween: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PLATFORMS_LAYER if one_way else WORLD_LAYER, true)
	_shape = _make_shape()
	add_child(_shape)
	Events.player_unlocks_changed.connect(_refresh)
	_set_shown(false, true)
	# Deferred: the player may still be getting its unlocks this frame.
	_refresh.call_deferred()


func _refresh() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var can_see := player != null and player.unlocks.has(PlayerUnlocks.REVEAL_PLATFORMS)
	if can_see != shown:
		_set_shown(can_see, false)


func _set_shown(value: bool, instant: bool) -> void:
	shown = value
	_shape.set_deferred(&"disabled", not value)
	var alpha := 1.0 if value else HIDDEN_ALPHA
	if _tween:
		_tween.kill()
	if instant:
		modulate.a = alpha
	else:
		_tween = create_tween()
		_tween.tween_property(self, ^"modulate:a", alpha, fade_time)


func _make_shape() -> CollisionShape2D:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0.0, size.y / 2.0)
	shape.one_way_collision = one_way
	return shape


func _draw() -> void:
	draw_rect(Rect2(-size.x / 2.0, 0.0, size.x, size.y), COLOR)
