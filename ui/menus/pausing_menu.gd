class_name PausingMenu
extends Menu
## A `Menu` that pauses the game while it is open: the pause menu and the
## skill shrine menu.

## Frees the menu once it closes, for menus made on the spot.
@export var free_on_close := false


func _ready() -> void:
	super()
	closed.connect(_on_closed)


## Pauses the game and shows `screen`. Does nothing if already open.
func open_screen(screen: MenuScreen) -> void:
	if is_open():
		return
	get_tree().paused = true
	push(screen)


func _on_closed() -> void:
	# Wait a frame so the press that closed the menu isn't also read as a
	# jump or an attack.
	await get_tree().process_frame
	get_tree().paused = false
	if free_on_close:
		queue_free()
