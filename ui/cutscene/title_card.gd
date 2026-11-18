class_name TitleCard
extends FadingCard
## A title in the middle of the screen, a line and a subtitle under it:
## a zone's name, a boss's name. Shown by `Events.title_card_shown`.

## Gap between the top of the screen and the title, as a share of the height.
@export_range(0.0, 1.0) var height := 0.32
@export var line_color := Color(0.72, 0.6, 0.4)
@export var line_width := 120.0

var _title := FadingCard.make_label(&"TitleLabel")
var _subtitle := FadingCard.make_label(&"HeaderLabel")


func _build() -> void:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	column.anchor_top = height
	column.anchor_bottom = height
	column.add_theme_constant_override(&"separation", 3)
	var line := ColorRect.new()
	line.color = line_color
	line.custom_minimum_size = Vector2(line_width, 1.0)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Control in [_title, line, _subtitle]:
		column.add_child(child)
	add_child(column)
	Events.title_card_shown.connect(_on_shown)


func _on_shown(title: String, subtitle: String, hold: float, fade: float) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_subtitle.visible = subtitle != ""
	show_for(hold, fade)
