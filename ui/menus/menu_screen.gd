class_name MenuScreen
extends VBoxContainer
## One page of a `Menu`: a title and a column of rows. Subclasses add
## their rows in `_build()` with the `add_*` helpers.

const ON_OFF: PackedStringArray = ["Off", "On"]

var menu: Menu
## Off: the menu's tint stays hidden while this screen is on top, so the
## game shows through (a small prompt over the game).
var backdrop := true
var _last_focus: Control


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 1)
	_build()


## Override to add the rows.
func _build() -> void:
	pass


## Back (Escape / B). Goes to the previous screen unless overridden.
func go_back() -> void:
	menu.pop()


func add_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"TitleLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


## Plain text, wrapped to the column width.
func add_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 240
	add_child(label)
	return label


func add_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(on_pressed)
	add_child(button)
	return button


## A row whose value changes with left and right. `on_changed` gets the
## new index. Lists wrap around unless `wraps` is false.
func add_option(
	title: String, values: PackedStringArray, index: int, on_changed: Callable, wraps := true
) -> OptionRow:
	var row := OptionRow.new(title, values, index, wraps)
	row.changed.connect(on_changed)
	add_child(row)
	return row


func add_gap(height := 6.0) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	add_child(gap)


## "0%", "10%" ... "100%" (or another range).
static func percent_values(from: int, to: int, step: int) -> PackedStringArray:
	var values := PackedStringArray()
	for percent in range(from, to + 1, step):
		values.append("%d%%" % percent)
	return values


func focus_first() -> void:
	var first := _first_focusable(self)
	if first:
		first.grab_focus()


func remember_focus() -> void:
	_last_focus = get_viewport().gui_get_focus_owner()


func restore_focus() -> void:
	if (
		is_instance_valid(_last_focus)
		and is_ancestor_of(_last_focus)
		and _last_focus.is_visible_in_tree()
	):
		_last_focus.grab_focus()
	else:
		focus_first()


func _first_focusable(node: Node) -> Control:
	for child in node.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		if control.focus_mode != Control.FOCUS_NONE:
			return control
		var nested := _first_focusable(control)
		if nested:
			return nested
	return null
