class_name CinematicBars
extends Control
## Letterbox bars that slide in from the top and bottom edges while a
## cutscene plays, with the HUD hidden meanwhile (`Events.cutscene_started`
## and `Events.cutscene_ended`).

## Hidden while a cutscene plays.
@export var hud: CanvasLayer
## Height of each bar (px) once in.
@export var bar_height := 30.0
## Seconds the bars take to slide in or out.
@export var slide_time := 0.4

var _amount := 0.0
var _top := ColorRect.new()
var _bottom := ColorRect.new()
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for bar in [_top, _bottom]:
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_set_amount(0.0)
	Events.cutscene_started.connect(_on_cutscene_started)
	Events.cutscene_ended.connect(_on_cutscene_ended)


func _on_cutscene_started(letterbox: bool) -> void:
	if hud:
		hud.hide()
	if letterbox:
		_slide(1.0)


func _on_cutscene_ended() -> void:
	_slide(0.0)
	if hud:
		hud.show()


func _slide(to: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_amount, _amount, to, slide_time * absf(to - _amount))


func _set_amount(amount: float) -> void:
	_amount = amount
	var height := bar_height * amount
	_top.offset_top = 0.0
	_top.offset_bottom = height
	_bottom.offset_top = -height
	_bottom.offset_bottom = 0.0
	visible = amount > 0.0
