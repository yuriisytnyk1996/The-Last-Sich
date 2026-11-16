class_name InventoryTabs
extends HBoxContainer
## The tab bar of the inventory page: one tab per item kind between the
## keys that step through them (`menu_tab_prev`, `menu_tab_next`). The
## open tab is lit and underlined. Tabs can also be clicked.

signal tab_chosen(index: int)

const TAB_WIDTH := 72.0
const ON := Color(1, 0.88, 0.6)
const OFF := Color(0.45, 0.42, 0.4)

var _tabs: Array[Button] = []
var _current := 0


func _init(names: PackedStringArray) -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 2)
	add_child(_hint("< " + _key_name(&"menu_tab_prev")))
	for i in names.size():
		var tab := Button.new()
		tab.text = names[i]
		tab.focus_mode = Control.FOCUS_NONE
		tab.custom_minimum_size.x = TAB_WIDTH
		tab.pressed.connect(tab_chosen.emit.bind(i))
		tab.draw.connect(_underline.bind(tab))
		_tabs.append(tab)
		add_child(tab)
	add_child(_hint(_key_name(&"menu_tab_next") + " >"))


func select(index: int) -> void:
	_current = index
	for i in _tabs.size():
		var color := ON if i == index else OFF
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
			_tabs[i].add_theme_color_override(state, color)
		_tabs[i].queue_redraw()


func _underline(tab: Button) -> void:
	if _tabs.find(tab) == _current:
		tab.draw_line(Vector2(6, tab.size.y - 1), Vector2(tab.size.x - 6, tab.size.y - 1), ON, 1.0)


func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"HeaderLabel"
	return label


func _key_name(action: StringName) -> String:
	return BindingButton.key_name(InputSettings.get_key(action))
