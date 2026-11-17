class_name SpiritBar
extends Control
## The player's spirit in the HUD, under the health bar.
##
## The bar is as wide as spirit without death marks. The part death marks
## take away is drawn as locked at the right end, so each death visibly
## shortens what can be filled. While a duma runs, a line under the bar
## shrinks with its time left (`Events.duma_time_changed`). Pressing the
## duma button without enough spirit flashes the bar (`Events.spirit_short`).
## Driven by events, never by the player directly.

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
@export var duma_color := Color("c8d0ff")
@export var short_color := Color("ff5a5a")

@export_group("Duma")
## Height of the duma time line under the bar (px).
@export var duma_height := 1
## Seconds the bar flashes when spirit is short.
@export var short_flash_time := 0.3

var _current := 0.0
var _maximum := 0.0
var _full := 0.0
var _duma_left := 0.0
var _flash := 0.0
var _flash_tween: Tween


func _ready() -> void:
	Events.player_spirit_changed.connect(_on_player_spirit_changed)
	Events.duma_time_changed.connect(_on_duma_time_changed)
	Events.spirit_short.connect(_on_spirit_short)


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
	if _flash > 0.0:
		draw_rect(inner, Color(short_color, short_color.a * _flash))
	if _duma_left > 0.0:
		var line := Vector2(floorf(width * _duma_left), duma_height)
		draw_rect(Rect2(Vector2(border, inner.end.y + border), line), duma_color)


func _on_player_spirit_changed(current: float, maximum: float, full_maximum: float) -> void:
	_current = current
	_maximum = maximum
	_full = full_maximum
	custom_minimum_size = Vector2(
		floorf(_full * pixels_per_point) + border * 2, bar_height + border * 2 + duma_height
	)
	queue_redraw()


func _on_duma_time_changed(fraction_left: float) -> void:
	_duma_left = fraction_left
	queue_redraw()


func _on_spirit_short() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash = 1.0
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, short_flash_time)


func _set_flash(value: float) -> void:
	_flash = value
	queue_redraw()
