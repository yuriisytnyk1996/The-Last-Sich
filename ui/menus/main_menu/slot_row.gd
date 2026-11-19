class_name SlotRow
extends Button
## One save slot on the slot-select screen: the slot number and zone on
## the left, play time, map explored and currency on the right, or
## "Empty".

const WIDTH := 300.0

var summary: SlotSummary

var _details := Label.new()


func _init() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size.x = WIDTH
	_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_details.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_details.offset_right = -6.0
	add_child(_details)


func show_summary(new_summary: SlotSummary) -> void:
	summary = new_summary
	var number := summary.slot + 1
	match summary.state:
		SlotSummary.State.EMPTY:
			text = "%d" % number
			_details.text = tr("Empty")
		SlotSummary.State.OLD:
			text = "%d  %s" % [number, tr("Old save")]
			_details.text = tr("Can't be loaded")
		SlotSummary.State.DAMAGED:
			text = "%d  %s" % [number, tr("Damaged save")]
			_details.text = tr("Can't be loaded")
		_:
			text = "%d  %s" % [number, summary.zone_name()]
			var coins := tr_n("%d coin", "%d coins", summary.currency) % summary.currency
			_details.text = (
				"%s   %s   %s" % [summary.play_time_text(), summary.explored_text(), coins]
			)
