class_name PauseMenu
extends Menu
## The in-game pause menu. `World` opens it on "pause" (Escape / Start).
## Pauses the tree while open. "pause" again closes it from any screen.


func open() -> void:
	if is_open():
		return
	get_tree().paused = true
	push(PauseScreen.new())


func _ready() -> void:
	super()
	closed.connect(_on_closed)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
		return
	super(event)


func _on_closed() -> void:
	# Wait a frame so the press that closed the menu isn't also read as a
	# jump or an attack.
	await get_tree().process_frame
	get_tree().paused = false
