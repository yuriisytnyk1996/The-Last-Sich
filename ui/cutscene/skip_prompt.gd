class_name SkipPrompt
extends FadingCard
## "[Esc] Skip" in the bottom right corner after a first press of pause
## in a skippable cutscene (`Events.cutscene_skip_offered`). It stays up
## for as long as a second press skips.

## Seconds to fade in and out.
@export var fade := 0.15

var _label := FadingCard.make_label(&"HeaderLabel")


func _build() -> void:
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.offset_right = -8.0
	_label.offset_bottom = -6.0
	add_child(_label)
	Events.cutscene_skip_offered.connect(_on_offered)


func _on_offered(binding: String, time: float) -> void:
	_label.text = tr("%s Skip") % binding
	# Gone by the time a press no longer skips.
	show_for(maxf(time - fade, 0.0), fade, 0.0)
