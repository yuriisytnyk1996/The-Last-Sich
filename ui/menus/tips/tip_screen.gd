class_name TipScreen
extends MenuScreen
## A "how to play" card: the tip's title, picture (when it has one) and
## text in a framed box. The action names in the text follow the device
## the player uses, even while the card is open.
##
## In play (`TipLog` shows a new tip) it fades in over the paused game,
## slightly see-through, with one "Got it" button, and fades out when
## closed. Browsing (Pause > Tips) it is opaque and has a page row,
## "2 / 5", that left and right turn through the listed tips, and "Back".

const BOX_WIDTH := 320.0
const BOX_COLOR := Color(0.06, 0.04, 0.07, 0.95)
const BORDER_COLOR := Color(0.72, 0.6, 0.4)
## Seconds the card takes to fade in and out during play.
const FADE_IN_TIME := 1.0
const FADE_OUT_TIME := 0.5
## Opacity of the card during play, so the paused game shows through.
const PLAY_ALPHA := 0.8

var _tips: Array[Tip]
var _index: int
var _gamepad: bool
var _browsing: bool
var _closing := false
var _title := Label.new()
var _image := TextureRect.new()
var _text := Label.new()


func _init(tips: Array[Tip], index: int, gamepad: bool, browsing: bool) -> void:
	_tips = tips
	_index = index
	_gamepad = gamepad
	_browsing = browsing


func _build() -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override(&"panel", _box_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_image.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = BOX_WIDTH - 16.0
	for child: Control in [_title, _image, _text]:
		column.add_child(child)
	box.add_child(column)
	add_child(box)
	add_gap()
	if _browsing:
		add_option(tr("Tip"), _page_names(), _index, _show)
		add_button(tr("Back"), go_back)
	else:
		add_button(tr("Got it"), go_back)
		_fade(0.0, PLAY_ALPHA, FADE_IN_TIME)
	_show(_index)


## In play: fades out, then closes. Browsing: back one page.
func go_back() -> void:
	if _browsing:
		super()
	elif not _closing:
		_closing = true
		_fade(modulate.a, 0.0, FADE_OUT_TIME).finished.connect(menu.close)


func _input(event: InputEvent) -> void:
	var device := Tip.device_of(event)
	if device >= 0 and (device == 1) != _gamepad:
		_gamepad = device == 1
		_show(_index)


func _show(index: int) -> void:
	_index = index
	var tip := _tips[index]
	_title.text = tr(tip.title)
	_image.texture = tip.image
	_image.visible = tip.image != null
	_text.text = tip.formatted_text(_gamepad)


func _page_names() -> PackedStringArray:
	var names := PackedStringArray()
	for i in _tips.size():
		names.append("%d / %d" % [i + 1, _tips.size()])
	return names


func _fade(from: float, to: float, time: float) -> Tween:
	modulate.a = from
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, ^"modulate:a", to, time)
	return tween


func _box_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	style.set_content_margin_all(8.0)
	return style
