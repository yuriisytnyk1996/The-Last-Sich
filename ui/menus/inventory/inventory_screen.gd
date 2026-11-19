class_name InventoryScreen
extends MenuScreen
## The inventory page. A tab per item kind (stepped with `menu_tab_prev`
## and `menu_tab_next`), the worn slots and a grid of owned items on the
## left (`InventoryGrid`), the focused item on the right (`ItemDetails`),
## the player's currency and the button hints at the bottom.
##
## Accept on a charm, duma, blade or relic wears it in the first free slot
## or takes it off; a blade or duma replaces the one worn. `menu_lore` (R / Y) opens
## the focused item's `LoreScreen`. The page opens on the newest item
## when there is one, else on the tab and cell used last.

const KINDS: Array[Item.Kind] = [
	Item.Kind.CHARM,
	Item.Kind.DUMA,
	Item.Kind.BLADE,
	Item.Kind.RELIC,
	Item.Kind.KEEPSAKE,
	Item.Kind.QUEST,
]
## The page is drawn on its own backdrop, this far around its content (px).
const MARGIN := Vector2(16, 10)
const BACKDROP := Color(0.06, 0.05, 0.06, 0.97)
const BACKDROP_BORDER := Color(0.35, 0.3, 0.26)

## Tab and grid cell to come back to, kept between openings.
static var _last_tab := 0
static var _last_cell := 0

var _inventory: PlayerInventory
var _tab := 0
var _tabs: InventoryTabs
var _title: Label
var _grid: InventoryGrid
var _details: ItemDetails
var _currency: Label
var _hints: Label


func _init(inventory: PlayerInventory) -> void:
	_inventory = inventory


func _build() -> void:
	add_theme_constant_override(&"separation", 4)
	_title = add_title("")
	_details = ItemDetails.new()
	_currency = Label.new()
	_hints = Label.new()
	var names := PackedStringArray()
	for kind in KINDS:
		names.append(Item.kind_plural(kind))
	_tabs = InventoryTabs.new(names)
	_tabs.tab_chosen.connect(_switch_tab)
	add_child(_tabs)
	add_gap(2)
	var body := HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 12)
	_grid = InventoryGrid.new(_inventory)
	_grid.item_focused.connect(_on_item_focused)
	_grid.item_pressed.connect(_on_item_pressed)
	body.add_child(_grid)
	body.add_child(_details)
	add_child(body)
	add_gap(2)
	add_child(_footer())
	var newest := _inventory.take_newest()
	if newest:
		_last_tab = KINDS.find(newest.kind)
		_open_tab(_last_tab)
		_last_cell = _grid.index_of(newest)
	else:
		_open_tab(_last_tab)
	_currency.text = tr("Currency  %d") % _inventory.player.wallet.amount


func _draw() -> void:
	var rect := Rect2(-MARGIN, size + MARGIN * 2.0)
	draw_rect(rect, BACKDROP)
	draw_rect(rect.grow(-0.5), BACKDROP_BORDER, false, 1.0)


func focus_first() -> void:
	_grid.focus_cell(_last_cell)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("menu_lore"):
		var item := _grid.focused_item()
		if item and item.lore != "":
			menu.push(LoreScreen.new(item))
		get_viewport().set_input_as_handled()
		return
	var step := 0
	if event.is_action_pressed("menu_tab_prev"):
		step = -1
	elif event.is_action_pressed("menu_tab_next"):
		step = 1
	if step != 0:
		_switch_tab(wrapi(_tab + step, 0, KINDS.size()))
		get_viewport().set_input_as_handled()


func _switch_tab(index: int) -> void:
	_open_tab(index)
	_grid.focus_cell(0)


func _open_tab(index: int) -> void:
	_tab = index
	_last_tab = index
	_title.text = Item.kind_plural(KINDS[index])
	_tabs.select(index)
	_grid.show_kind(KINDS[index])
	_details.show_item(null, false)
	_update_hints(null)


func _on_item_focused(item: Item) -> void:
	_last_cell = _grid.focused_index()
	_details.show_item(item, item != null and _inventory.is_worn(item))
	_update_hints(item)


func _on_item_pressed(item: Item) -> void:
	if item == null or not item.is_equipable():
		return
	if _inventory.is_worn(item):
		_inventory.take_off(item)
	elif not _inventory.wear(item):
		_hints.text = tr("No free slot. Take one off first.")
		return
	_grid.refresh()
	_on_item_focused(item)


func _update_hints(item: Item) -> void:
	var action := ""
	if item and item.is_equipable():
		if _inventory.is_worn(item):
			action = tr("Accept: Take off") + "    "
		elif (
			not item.kind in PlayerInventory.SWAPPED_KINDS
			and not _inventory.has_free_slot(item.kind)
		):
			action = tr("No free slot") + "    "
		else:
			action = tr("Accept: Wear") + "    "
	var lore := tr("Lore: Read") + "    " if item and item.lore != "" else ""
	_hints.text = action + lore + tr("Back: Close")


func _footer() -> HBoxContainer:
	var row := HBoxContainer.new()
	_currency.theme_type_variation = &"HeaderLabel"
	_currency.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hints.theme_type_variation = &"HeaderLabel"
	_hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_currency)
	if OS.is_debug_build():
		var debug := Button.new()
		debug.text = "Debug: get all"  # NO_TRANSLATE
		debug.focus_mode = Control.FOCUS_NONE
		debug.theme_type_variation = &"HeaderLabel"
		debug.add_theme_font_size_override(&"font_size", 8)
		debug.pressed.connect(_debug_add_all)
		row.add_child(debug)
	row.add_child(_hints)
	return row


func _debug_add_all() -> void:
	_inventory.add_all()
	_open_tab(_tab)
