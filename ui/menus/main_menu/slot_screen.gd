class_name SlotScreen
extends MenuScreen
## One taken save slot. A loadable slot offers Continue; an old or damaged
## one offers a new game in its place (asked first). Both can be deleted.

var _summary: SlotSummary


func _init(summary: SlotSummary) -> void:
	_summary = summary


func _build() -> void:
	add_title("Slot %d" % (_summary.slot + 1))
	if _summary.state == SlotSummary.State.READY:
		add_text("%s, %s played" % [_summary.zone_name(), _summary.play_time_text()])
		add_gap()
		add_button("Continue", _continue)
	else:
		add_text("This save can't be loaded.")
		add_gap()
		add_button("New game here", _confirm_new_game)
	add_button("Delete", _confirm_delete)
	add_button("Back", go_back)


func _continue() -> void:
	SlotsScreen.play(get_tree(), _summary.slot, false)


func _confirm_new_game() -> void:
	var question := "Start a new game in slot %d? The old save will be lost." % (_summary.slot + 1)
	var start := func() -> void: SlotsScreen.play(get_tree(), _summary.slot, true)
	menu.push(ConfirmScreen.new(question, start))


func _confirm_delete() -> void:
	var question := "Delete slot %d? This can't be undone." % (_summary.slot + 1)
	menu.push(ConfirmScreen.new(question, _delete))


## Back past the question and this page, to the slot list.
func _delete() -> void:
	SaveManager.delete_save(_summary.slot)
	menu.pop()
	menu.pop()
