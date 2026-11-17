extends Node
## The mouse cursor (autoload "Cursor"). The game is played with keyboard
## or gamepad, menus included, so the cursor is hidden from the start.
## In debug builds F10 shows or hides it, for debug buttons that only
## take a click.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if OS.is_debug_build() and key and key.pressed and not key.echo:
		if key.physical_keycode == KEY_F10:
			var hidden := Input.mouse_mode == Input.MOUSE_MODE_HIDDEN
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if hidden else Input.MOUSE_MODE_HIDDEN
			get_viewport().set_input_as_handled()
