class_name SlotScreen
extends MenuScreen
## One taken save slot. A loadable slot offers Continue; an old or damaged
## one offers a new game in its place (asked first). Both can be deleted.

var _summary: SlotSummary


func _init(summary: SlotSummary) -> void:
	_summary = summary


func _build() -> void:
	add_title(tr("Slot %d") % (_summary.slot + 1))
	if _summary.state == SlotSummary.State.READY:
		add_text(tr("%s, %s played") % [_summary.zone_name(), _summary.play_time_text()])
		add_gap()
		add_button(tr("Continue"), _continue)
	else:
		add_text(tr("This save can't be loaded."))
		add_gap()
		add_button(tr("New game here"), _confirm_new_game)
	add_button(tr("Delete"), _confirm_delete)
	add_button(tr("Back"), go_back)


func _continue() -> void:
	SlotsScreen.play(get_tree(), _summary.slot, false)


func _confirm_new_game() -> void:
	var question := (
		tr("Start a new game in slot %d? The old save will be lost.") % (_summary.slot + 1)
	)
	var start := func() -> void: SlotsScreen.play(get_tree(), _summary.slot, true)
	menu.push(ConfirmScreen.new(question, start))


func _confirm_delete() -> void:
	var question := tr("Delete slot %d? This can't be undone.") % (_summary.slot + 1)
	menu.push(ConfirmScreen.new(question, _delete))


## Back past the question and this page, to the slot list.
func _delete() -> void:
	SaveManager.delete_save(_summary.slot)
	menu.pop()
	menu.pop()
