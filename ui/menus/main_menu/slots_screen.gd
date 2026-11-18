class_name SlotsScreen
extends MenuScreen
## The slot-select page: one row per save slot. An empty slot starts a new
## game in it at once; a taken one opens `SlotScreen` (continue, delete).
## The rows are read again whenever the page comes back on top, so a
## deleted slot shows as empty.

const WORLD := "res://levels/world.tscn"

var _rows: Array[SlotRow] = []


func _build() -> void:
	add_title("Choose a slot")
	add_gap()
	for which in SaveManager.SLOT_COUNT:
		var row := SlotRow.new()
		row.pressed.connect(_on_row_pressed.bind(row))
		add_child(row)
		_rows.append(row)
	_refresh()
	visibility_changed.connect(_on_visibility_changed)


## Starts the world on `which`. A new game clears whatever the slot held.
static func play(tree: SceneTree, which: int, new_game: bool) -> void:
	if new_game:
		SaveManager.delete_save(which)
	SaveManager.slot = which
	tree.change_scene_to_file(WORLD)


func _on_row_pressed(row: SlotRow) -> void:
	if row.summary.is_empty():
		play(get_tree(), row.summary.slot, true)
	else:
		menu.push(SlotScreen.new(row.summary))


func _on_visibility_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	for which in _rows.size():
		_rows[which].show_summary(SlotSummary.read(which))
