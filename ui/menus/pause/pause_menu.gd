class_name PauseMenu
extends PausingMenu
## The in-game pause menu. `World` opens it on "pause" (Escape / Start).
## "pause" again closes it from any screen.


func open() -> void:
	open_screen(PauseScreen.new())


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
		return
	super(event)
