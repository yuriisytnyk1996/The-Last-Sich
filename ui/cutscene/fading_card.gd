class_name FadingCard
extends Control
## Base for the cutscene cards (`TitleCard`, `QuoteCard`, `SkipPrompt`):
## fades in, stays, fades out, and vanishes at once when a cutscene is
## skipped or ends. Builds its own controls in `_build()`.

var _tween: Tween


func _ready() -> void:
	theme = Menu.THEME
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0
	_build()
	Events.cutscene_skipped.connect(vanish)
	Events.cutscene_ended.connect(vanish)


func vanish() -> void:
	if _tween:
		_tween.kill()
	modulate.a = 0.0


## Fades in over `fade` seconds, stays `hold` seconds, fades out over `fade_out`.
func show_for(hold: float, fade: float, fade_out := -1.0) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 1.0, fade)
	_tween.tween_interval(hold)
	_tween.tween_property(self, ^"modulate:a", 0.0, fade if fade_out < 0.0 else fade_out)


func _build() -> void:
	pass


## A label that ignores the mouse, with the given theme type.
static func make_label(type := &"") -> Label:
	var label := Label.new()
	label.theme_type_variation = type
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
