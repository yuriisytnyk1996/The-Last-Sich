class_name BossBar
extends Control
## The boss's name and health at the bottom of the screen during a boss
## fight. Same feel as the player's bar: damage drops the fill at once and
## a pale loss segment drains after it. Fixed width, whatever the boss's
## health. Driven by `Events.boss_fight_started`, `boss_health_changed`
## and `boss_fight_ended`.

@export var bar_width := 240
@export var bar_height := 4
## Frame thickness around the bar (px).
@export var border := 1
## The bar is drawn this far below the top, under the name (px).
@export var bar_top := 10
## Seconds the loss segment holds still before draining.
@export var loss_delay := 0.4
## Drain speed of the loss segment, in fractions of the bar per second.
@export var loss_drain_speed := 0.5
## Seconds the bar stays after the fight ends.
@export var hide_delay := 1.0

@export_group("Colors")
@export var frame_color := Color("1a1018")
@export var empty_color := Color("3b2730")
@export var loss_color := Color("e8d8b0")
@export var fill_color := Color("c8a040")

var _fill := 1.0
var _loss := 1.0
var _loss_hold := 0.0
var _tween: Tween

@onready var name_label: Label = $Name


func _ready() -> void:
	Events.boss_fight_started.connect(_on_fight_started)
	Events.boss_health_changed.connect(_on_health_changed)
	Events.boss_fight_ended.connect(_on_fight_ended)
	hide()
	set_process(false)


func _process(delta: float) -> void:
	if _loss_hold > 0.0:
		_loss_hold -= delta
	else:
		_loss = maxf(_loss - loss_drain_speed * delta, _fill)
	if _loss == _fill:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var inner := Vector2(bar_width, bar_height)
	var top := Vector2(0, bar_top)
	draw_rect(Rect2(top, inner + Vector2.ONE * border * 2), frame_color)
	var origin := top + Vector2.ONE * border
	draw_rect(Rect2(origin, inner), empty_color)
	draw_rect(Rect2(origin, Vector2(floorf(_loss * bar_width), bar_height)), loss_color)
	draw_rect(Rect2(origin, Vector2(floorf(_fill * bar_width), bar_height)), fill_color)


func _on_fight_started(boss_name: String, current: int, maximum: int) -> void:
	if _tween:
		_tween.kill()
	name_label.text = tr(boss_name)
	_fill = float(current) / float(maxi(maximum, 1))
	_loss = _fill
	show()
	queue_redraw()


func _on_health_changed(current: int, maximum: int) -> void:
	var value := float(current) / float(maxi(maximum, 1))
	if value < _fill:
		_loss_hold = loss_delay
	_fill = value
	_loss = maxf(_loss, _fill)
	set_process(true)
	queue_redraw()


func _on_fight_ended() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(hide_delay)
	_tween.tween_callback(hide)
