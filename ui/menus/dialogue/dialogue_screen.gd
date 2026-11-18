class_name DialogueScreen
extends MenuScreen
## A text box at the bottom of the view that plays a `Dialogue`: the
## speaker's name, the line typed out letter by letter, and the buttons.
## Accept on "Next" while a line is still typing shows all of it first.
## The last line shows the answers the player may pick (greyed out while
## they can't pay); picking one applies its outcome and goes on to its
## `next` conversation or closes the box. Back works like "Next" but never
## picks an answer.
##
## Opened in a `PausingMenu` (see `Npc`), so the game waits meanwhile.

## Letters typed per second.
const TYPE_SPEED := 60.0
const BOX_WIDTH := 400.0
## The screen is this tall, with the box at its bottom edge.
const SCREEN_HEIGHT := 340.0
const BOX_COLOR := Color(0.06, 0.04, 0.07, 0.92)
const BORDER_COLOR := Color(0.72, 0.6, 0.4)

var _dialogue: Dialogue
var _player: Player
var _default_speaker: String
var _line := 0
var _speaker := Label.new()
var _text := Label.new()
var _buttons := VBoxContainer.new()
var _tween: Tween
var _next: Button


func _init(dialogue: Dialogue, player: Player, default_speaker: String) -> void:
	_dialogue = dialogue
	_player = player
	_default_speaker = default_speaker
	backdrop = false


func _build() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	custom_minimum_size = Vector2(BOX_WIDTH, SCREEN_HEIGHT)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override(&"panel", _box_style())
	var column := VBoxContainer.new()
	_speaker.theme_type_variation = &"TitleLabel"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(BOX_WIDTH - 16.0, 36.0)
	for child: Control in [_speaker, _text, _buttons]:
		column.add_child(child)
	box.add_child(column)
	add_child(box)
	_start(_dialogue)


func go_back() -> void:
	if _next:
		_next.pressed.emit()


func _start(dialogue: Dialogue) -> void:
	_dialogue = dialogue
	_line = 0
	_speaker.text = dialogue.speaker if dialogue.speaker != "" else _default_speaker
	_show_line()


func _show_line() -> void:
	var lines := _dialogue.lines
	_text.text = lines[_line] if _line < lines.size() else ""
	_text.visible_ratio = 0.0
	_set_buttons([_make_next(_finish_typing)])
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, ^"visible_ratio", 1.0, _text.text.length() / TYPE_SPEED)
	_tween.finished.connect(_on_typed)


func _finish_typing() -> void:
	_tween.kill()
	_text.visible_ratio = 1.0
	_on_typed()


func _on_typed() -> void:
	if _line < _dialogue.lines.size() - 1:
		_set_buttons([_make_next(_next_line)])
		return
	if _dialogue.outcome:
		_dialogue.outcome.apply(_player)
	var choices := _dialogue.choices_for(_player)
	if choices.is_empty():
		_set_buttons([_make_next(menu.close)])
		return
	var buttons: Array[Button] = []
	for choice in choices:
		var button := Button.new()
		button.text = choice.label()
		button.disabled = not choice.can_pick(_player)
		button.pressed.connect(_pick.bind(choice))
		buttons.append(button)
	_set_buttons(buttons)


func _next_line() -> void:
	_line += 1
	_show_line()


func _pick(choice: DialogueChoice) -> void:
	if choice.outcome and not choice.outcome.apply(_player):
		return
	if choice.next:
		_start(choice.next)
	else:
		menu.close()


func _make_next(on_pressed: Callable) -> Button:
	_next = Button.new()
	_next.text = "Next"
	_next.pressed.connect(on_pressed)
	return _next


## Swaps the buttons and focuses the first one that can be pressed.
func _set_buttons(buttons: Array[Button]) -> void:
	for old in _buttons.get_children():
		old.queue_free()
	if not _next in buttons:
		_next = null
	for button in buttons:
		_buttons.add_child(button)
	for button in buttons:
		if not button.disabled:
			_focus.call_deferred(button)
			return


## Deferred, so the button may be gone by then (a quick double press).
func _focus(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree():
		button.grab_focus()


func _box_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	style.set_content_margin_all(6.0)
	return style
