class_name ItemDetails
extends PanelContainer
## The right side of the inventory page: the focused item drawn large,
## its name, its kind and whether it is worn (with a duma's spirit cost),
## and its description.
## Empty when the focused cell holds nothing.

const WIDTH := 176.0
const ICON_SIZE := Vector2(40, 40)
const BACK := Color(0.08, 0.07, 0.08, 0.9)
const BORDER := Color(0.3, 0.27, 0.25)
const NAME_COLOR := Color(0.95, 0.85, 0.65)

var _icon := ItemIcon.new()
var _name := Label.new()
var _state := Label.new()
var _description := Label.new()


func _init() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = BACK
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	add_child(column)
	_icon.custom_minimum_size = ICON_SIZE
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_icon)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_color_override(&"font_color", NAME_COLOR)
	column.add_child(_name)
	_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state.theme_type_variation = &"HeaderLabel"
	column.add_child(_state)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.x = WIDTH - 16
	column.add_child(_description)


func show_item(item: Item, worn: bool) -> void:
	_icon.item = item
	_name.text = item.title if item else " "
	_description.text = item.description if item else " "
	if item == null:
		_state.text = " "
	else:
		_state.text = Item.kind_name(item.kind)
		if item.kind == Item.Kind.DUMA:
			_state.text += "  ·  Spirit %d" % roundi(item.spirit_cost)
		if worn:
			_state.text += "  ·  Worn"
