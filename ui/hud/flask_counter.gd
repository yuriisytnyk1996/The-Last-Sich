class_name FlaskCounter
extends Control
## The player's healing flasks in the HUD: one pip per flask, filled while
## it's full and dim once it's used. Each flask healing level has its own
## pip colour (`level_colors`), and from level 1 a bright cap on top of
## every pip, full or not, so the level shows even with no flasks left.
##
## A flask that was just drunk flashes before going dim. Pressing heal with
## none left shakes the pips and flashes their frames. Driven by
## `Events.player_flasks_changed` and `Events.player_flasks_empty`, never
## by the player directly.

@export_group("Size")
## Size of one pip (px).
@export var pip_size := Vector2i(5, 7)
## Gap between pips (px).
@export var spacing := 2
## Frame thickness around each pip (px).
@export var border := 1

@export_group("Feedback")
## Seconds a just-drunk flask flashes.
@export var drink_flash_time := 0.25
## Seconds the pips shake when heal is pressed with none left.
@export var empty_shake_time := 0.3
## How far the pips shake sideways (px).
@export var empty_shake_distance := 2

@export_group("Colors")
@export var frame_color := Color("1a1018")
@export var empty_color := Color("3b2730")
@export var full_color := Color("d89a3a")
## Full pip colour per flask healing level, from level 1. Level 0 uses
## `full_color`; levels past the end use the last one.
@export var level_colors := PackedColorArray(
	[Color("e0a848"), Color("e6bd5a"), Color("d8d27a"), Color("a8dcc4"), Color("cfeef5")]
)
## How much of the level colour tints a used pip.
@export_range(0.0, 1.0) var empty_tint := 0.2
@export var flash_color := Color("fff2c8")
@export var warning_color := Color("b8323a")

var _current := 0
var _maximum := 0
var _level := 0
var _drink_flash := 0.0
var _shake := 0.0


func _ready() -> void:
	Events.player_flasks_changed.connect(_on_player_flasks_changed)
	Events.player_flasks_empty.connect(_on_player_flasks_empty)
	set_process(false)


func _process(delta: float) -> void:
	_drink_flash = maxf(_drink_flash - delta, 0.0)
	_shake = maxf(_shake - delta, 0.0)
	if _drink_flash == 0.0 and _shake == 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var outer := Vector2(pip_size) + Vector2.ONE * border * 2
	var frame := warning_color if _shake > 0.0 else frame_color
	var offset := _shake_offset()
	for i in _maximum:
		var origin := Vector2(i * (outer.x + spacing) + offset, 0.0)
		draw_rect(Rect2(origin, outer), frame)
		var inner := Rect2(origin + Vector2.ONE * border, Vector2(pip_size))
		draw_rect(inner, _pip_color(i))
		if _level > 0:
			draw_rect(
				Rect2(inner.position, Vector2(inner.size.x, 1)), _level_color().lightened(0.5)
			)


func _pip_color(index: int) -> Color:
	if index < _current:
		return _level_color()
	if index == _current and _drink_flash > 0.0:
		return flash_color
	return empty_color.lerp(_level_color(), empty_tint if _level > 0 else 0.0)


func _level_color() -> Color:
	if _level <= 0 or level_colors.is_empty():
		return full_color
	return level_colors[mini(_level, level_colors.size()) - 1]


## Whole pixels, flipping side every 0.05 s while shaking.
func _shake_offset() -> float:
	if _shake <= 0.0:
		return 0.0
	return float(empty_shake_distance if int(_shake * 20.0) % 2 == 0 else -empty_shake_distance)


func _on_player_flasks_changed(current: int, maximum: int, level: int) -> void:
	if current == _current - 1:
		_drink_flash = drink_flash_time
		set_process(true)
	_current = current
	_level = level
	_maximum = maxi(maximum, 0)
	var outer := Vector2(pip_size) + Vector2.ONE * border * 2
	custom_minimum_size = Vector2(_maximum * (outer.x + spacing) - spacing, outer.y)
	queue_redraw()


func _on_player_flasks_empty() -> void:
	_shake = empty_shake_time
	set_process(true)
