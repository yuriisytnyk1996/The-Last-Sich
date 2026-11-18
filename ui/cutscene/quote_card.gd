class_name QuoteCard
extends FadingCard
## A quote in the middle of the screen, its author under it. Drawn above
## the black screen fade, so a cutscene can fade out and show it on black.
## Shown by `Events.quote_shown`.

@export var width := 360.0

var _text := FadingCard.make_label()
var _author := FadingCard.make_label(&"HeaderLabel")


func _build() -> void:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 8)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(width, 0.0)
	column.add_child(_text)
	column.add_child(_author)
	center.add_child(column)
	add_child(center)
	Events.quote_shown.connect(_on_shown)


func _on_shown(text: String, author: String, hold: float, fade: float) -> void:
	_text.text = text
	_author.text = "- %s" % author
	_author.visible = author != ""
	show_for(hold, fade)
