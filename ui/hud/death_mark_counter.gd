class_name DeathMarkCounter
extends Control
## The death marks waiting to be recovered, one small dark pip each, next
## to the spirit bar. Hidden while there are none. Driven by
## `Events.death_marks_changed`.

## Size of one pip (px).
@export var pip_size := Vector2i(3, 5)
## Gap between pips (px).
@export var spacing := 1
@export var pip_color := Color("8a3a90")
@export var frame_color := Color("1a1018")

var _count := 0


func _ready() -> void:
	Events.death_marks_changed.connect(_on_death_marks_changed)


func _draw() -> void:
	var outer := Vector2(pip_size) + Vector2.ONE * 2.0
	for i in _count:
		var origin := Vector2(i * (outer.x + spacing), 0.0)
		draw_rect(Rect2(origin, outer), frame_color)
		draw_rect(Rect2(origin + Vector2.ONE, Vector2(pip_size)), pip_color)


func _on_death_marks_changed(count: int) -> void:
	_count = maxi(count, 0)
	var outer := Vector2(pip_size) + Vector2.ONE * 2.0
	custom_minimum_size = Vector2(maxf(_count * (outer.x + spacing) - spacing, 0.0), outer.y)
	queue_redraw()
