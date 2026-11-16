class_name PauseMenu
extends PausingMenu
## The in-game pause menu. `World` opens it on "pause" (Escape / Start).
## "pause" again closes it from any screen. `World` also opens it straight
## on the map page on "map" (M / Back), and "map" closes that page again.

@export var world_map: WorldMap


func open() -> void:
	open_screen(PauseScreen.new(world_map))


func open_map() -> void:
	open_screen(MapScreen.new(world_map))


func _unhandled_input(event: InputEvent) -> void:
	var map_pressed := event.is_action_pressed("map") and top_screen() is MapScreen
	if is_open() and (event.is_action_pressed("pause") or map_pressed):
		close()
		get_viewport().set_input_as_handled()
		return
	super(event)
