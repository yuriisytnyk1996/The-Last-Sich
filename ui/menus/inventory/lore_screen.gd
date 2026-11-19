class_name LoreScreen
extends MenuScreen
## The lore page of one item, opened from the inventory with `menu_lore`
## (R / Y): the item drawn large, its name and its `Item.lore`. Back or
## `menu_lore` again returns to the inventory.

const ICON_SIZE := Vector2(48, 48)
const TEXT_WIDTH := 320.0

var _item: Item


func _init(item: Item) -> void:
	_item = item


func _build() -> void:
	add_theme_constant_override(&"separation", 6)
	var icon := ItemIcon.new()
	icon.item = _item
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(icon)
	add_title(tr(_item.title))
	var text := add_text(tr(_item.lore))
	text.custom_minimum_size.x = TEXT_WIDTH
	add_gap(4)
	add_text(tr("Lore / Back: Return")).theme_type_variation = &"HeaderLabel"


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("menu_lore"):
		# Handled first: going back takes this screen out of the tree.
		get_viewport().set_input_as_handled()
		go_back()
