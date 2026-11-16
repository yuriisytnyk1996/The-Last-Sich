class_name SpiritBar
extends Control
## The player's spirit in the HUD, under the health bar.
##
## The bar is as wide as spirit without death marks. The part death marks
## take away is drawn as locked at the right end, so each death visibly
## shortens what can be filled. Driven by `Events.player_spirit_changed`,
## never by the player directly.

@export_group("Size")
## Bar width per point of spirit (px).
@export var pixels_per_point := 2.0
@export var bar_height := 3
## Frame thickness around the bar (px).
@export var border := 1

@export_group("Colors")
@export var frame_color := Color("1a1018")
@export var empty_color := Color("2a2440")
@export var fill_color := Color("6f7fd8")
@export var locked_color := Color("4a2050")

var _current := 0.0
var _maximum := 0.0
var _full := 0.0


func _ready() -> void:
	Events.player_spirit_changed.connect(_on_player_spirit_changed)


func _draw() -> void:
	var width := floorf(_full * pixels_per_point)
	var inner := Rect2(Vector2.ONE * border, Vector2(width, bar_height))
	draw_rect(Rect2(Vector2.ZERO, inner.size + Vector2.ONE * border * 2), frame_color)
	draw_rect(inner, empty_color)
	var open_width := floorf(_maximum * pixels_per_point)
	var locked := Rect2(
		inner.position + Vector2(open_width, 0.0), Vector2(width - open_width, bar_height)
	)
	draw_rect(locked, locked_color)
	var fill_width := floorf(_current * pixels_per_point)
	draw_rect(Rect2(inner.position, Vector2(fill_width, bar_height)), fill_color)


func _on_player_spirit_changed(current: float, maximum: float, full_maximum: float) -> void:
	_current = current
	_maximum = maximum
	_full = full_maximum
	custom_minimum_size = Vector2(
		floorf(_full * pixels_per_point) + border * 2, bar_height + border * 2
	)
	queue_redraw()
