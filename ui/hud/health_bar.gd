class_name HealthBar
extends Control
## The player's health bar in the HUD.
##
## Grows wider with max health, so upgrades are visible at a glance.
## Damage drops the fill at once, and a pale "loss" segment shows what was
## just lost: it holds for `loss_delay`, then drains down to the fill.
## Healing does the opposite: the fill rises smoothly up to the new value.
## Driven by `Events.player_health_changed`, never by the player directly.

@export_group("Size")
## Bar width per point of max health (px).
@export var pixels_per_point := 12
@export var bar_height := 4
## Frame thickness around the bar (px).
@export var border := 1

@export_group("Animation")
## Seconds the loss segment holds still before draining.
@export var loss_delay := 0.4
## Drain speed of the loss segment, in health points per second.
@export var loss_drain_speed := 4.0
## Rise speed of the fill when healing, in health points per second.
@export var heal_fill_speed := 6.0

@export_group("Colors")
@export var frame_color := Color("1a1018")
@export var empty_color := Color("3b2730")
@export var loss_color := Color("e8d8b0")
@export var fill_color := Color("b8323a")

var _maximum := 1
var _target := 0.0
var _fill := 0.0
var _loss := 0.0
var _loss_hold := 0.0
var _has_value := false


func _ready() -> void:
	Events.player_health_changed.connect(_on_player_health_changed)
	set_process(false)


func _process(delta: float) -> void:
	if _fill < _target:
		_fill = minf(_fill + heal_fill_speed * delta, _target)
	if _loss_hold > 0.0:
		_loss_hold -= delta
	elif _loss > _target:
		_loss = maxf(_loss - loss_drain_speed * delta, _target)
	if _fill == _target and _loss == _target:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var inner := Vector2(_maximum * pixels_per_point, bar_height)
	draw_rect(Rect2(Vector2.ZERO, inner + Vector2.ONE * border * 2), frame_color)
	var origin := Vector2.ONE * border
	draw_rect(Rect2(origin, inner), empty_color)
	draw_rect(Rect2(origin, Vector2(_to_pixels(_loss), bar_height)), loss_color)
	draw_rect(Rect2(origin, Vector2(_to_pixels(_fill), bar_height)), fill_color)


func _on_player_health_changed(current: int, maximum: int) -> void:
	_maximum = maxi(maximum, 1)
	_target = float(current)
	if not _has_value:
		# First report: show it as is, no animation.
		_has_value = true
		_fill = _target
		_loss = _target
	elif _target < _fill:
		_fill = _target
		_loss_hold = loss_delay
	# While healing, the loss colour previews what the fill rises to.
	_loss = maxf(_loss, _target)
	var inner := Vector2(_maximum * pixels_per_point, bar_height)
	custom_minimum_size = inner + Vector2.ONE * border * 2
	set_process(true)
	queue_redraw()


## Whole pixels only, so the bar edge never blurs.
func _to_pixels(points: float) -> float:
	return floorf(points * pixels_per_point)
