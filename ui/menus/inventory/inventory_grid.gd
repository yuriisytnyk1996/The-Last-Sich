class_name InventoryGrid
extends VBoxContainer
## The left side of the inventory page for one item kind.
##
## On top, the worn slots in a row: every slot there can ever be, the
## ones not opened yet locked. They only show what is worn and can't be
## focused. Below, a grid of the owned items in `all` order, padded with
## empty cells to full rows (at least `MIN_ROWS`). Focusing a grid item
## lights its copy in the worn row.

signal item_focused(item: Item)
signal item_pressed(item: Item)

const COLUMNS := 8
const MIN_ROWS := 3
const GAP := 3

var _inventory: PlayerInventory
var _kind := Item.Kind.CHARM
var _slots_title := _header(tr("Worn"))
var _slots := HBoxContainer.new()
var _grid := GridContainer.new()


func _init(inventory: PlayerInventory) -> void:
	_inventory = inventory
	add_theme_constant_override(&"separation", 3)
	_slots.add_theme_constant_override(&"separation", GAP)
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", GAP)
	_grid.add_theme_constant_override(&"v_separation", GAP)
	add_child(_slots_title)
	add_child(_slots)
	add_child(_header(tr("Carried")))
	add_child(_grid)


## Rebuilds both parts for `kind`.
func show_kind(kind: Item.Kind) -> void:
	_kind = kind
	_clear(_slots)
	_clear(_grid)
	var max_slots := _inventory.max_slots(kind)
	_slots_title.visible = max_slots > 0
	_slots.visible = max_slots > 0
	for i in max_slots:
		var slot := ItemCell.new()
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots.add_child(slot)
	var owned := _inventory.owned_of(kind)
	var rows := maxi(MIN_ROWS, ceili(owned.size() / float(COLUMNS)))
	for i in rows * COLUMNS:
		var cell := ItemCell.new()
		cell.item = owned[i] if i < owned.size() else null
		cell.focus_entered.connect(_on_cell_focused.bind(cell))
		cell.pressed.connect(func() -> void: item_pressed.emit(cell.item))
		_grid.add_child(cell)
	refresh()


## Updates worn marks and slots after an item was worn or taken off.
func refresh() -> void:
	var worn := _inventory.worn_of(_kind)
	var open := _inventory.slot_count(_kind)
	var focused := focused_item()
	for i in _slots.get_child_count():
		var slot := _slots.get_child(i) as ItemCell
		slot.item = worn[i] if i < worn.size() else null
		slot.locked = i >= open
		slot.highlighted = slot.item != null and slot.item == focused
	for cell: ItemCell in _grid.get_children():
		cell.worn = cell.item != null and _inventory.is_worn(cell.item)


func focus_cell(index: int) -> void:
	var count := _grid.get_child_count()
	if count > 0:
		(_grid.get_child(clampi(index, 0, count - 1)) as Control).grab_focus()


func focused_index() -> int:
	var owner_control := get_viewport().gui_get_focus_owner()
	return (
		owner_control.get_index() if owner_control and owner_control.get_parent() == _grid else -1
	)


func focused_item() -> Item:
	var index := focused_index()
	return (_grid.get_child(index) as ItemCell).item if index >= 0 else null


## Grid position of `item`, or -1 when it isn't in this kind's grid.
func index_of(item: Item) -> int:
	return _inventory.owned_of(_kind).find(item)


func _on_cell_focused(cell: ItemCell) -> void:
	refresh()
	item_focused.emit(cell.item)


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"HeaderLabel"
	return label
