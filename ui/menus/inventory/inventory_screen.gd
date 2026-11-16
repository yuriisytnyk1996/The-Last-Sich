class_name InventoryScreen
extends MenuScreen
## The pause menu's inventory page. A kind row (charms, blades, keepsakes)
## picks which owned items are listed, with the slots in use. Choosing a
## charm or blade wears it or takes it off; a blade replaces the one
## worn. The focused item's description shows below the list.

const KINDS: Array[Item.Kind] = [Item.Kind.CHARM, Item.Kind.BLADE, Item.Kind.KEEPSAKE]
const LIST_WIDTH := 240.0

var _inventory: PlayerInventory
var _kind := Item.Kind.CHARM
var _slots: Label
var _list := VBoxContainer.new()
var _info: Label


func _init(inventory: PlayerInventory) -> void:
	_inventory = inventory


func _build() -> void:
	add_title("Inventory")
	var names := PackedStringArray()
	for kind in KINDS:
		names.append(Item.kind_name(kind) + "s")
	add_option("Show", names, 0, _on_kind_changed)
	_slots = add_text("")
	add_gap(2)
	_list.add_theme_constant_override("separation", 1)
	add_child(_list)
	add_gap()
	_info = add_text("")
	_info.custom_minimum_size.x = LIST_WIDTH
	add_gap()
	if OS.is_debug_build():
		add_button("Debug: get all items", _debug_add_all)
	add_button("Back", go_back)
	_refresh()


func _on_kind_changed(index: int) -> void:
	_kind = KINDS[index]
	_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var items := _inventory.owned_of(_kind)
	var slots := _inventory.slot_count(_kind)
	_slots.text = "Worn: %d / %d" % [_inventory.worn_of(_kind).size(), slots] if slots > 0 else " "
	if items.is_empty():
		var empty := Label.new()
		empty.text = "Nothing yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	for item in items:
		var row := Button.new()
		row.text = item.title + ("   [worn]" if _inventory.is_worn(item) else "")
		row.custom_minimum_size.x = LIST_WIDTH
		row.pressed.connect(_on_item_pressed.bind(item))
		row.focus_entered.connect(_show_info.bind(item))
		_list.add_child(row)
	_info.text = " "


func _show_info(item: Item, note := "") -> void:
	_info.text = item.description + ("\n" + note if note != "" else "")


func _on_item_pressed(item: Item) -> void:
	if not item.is_equipable():
		return
	var note := ""
	if _inventory.is_worn(item):
		_inventory.take_off(item)
	elif not _inventory.wear(item):
		note = "No free slot. Take another charm off first."
	var index := _inventory.owned_of(_kind).find(item)
	_refresh()
	var row := _list.get_child(index) as Button
	row.grab_focus()
	_show_info(item, note)


func _debug_add_all() -> void:
	_inventory.add_all()
	_refresh()
