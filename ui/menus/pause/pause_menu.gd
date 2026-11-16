class_name PauseMenu
extends PausingMenu
## The in-game pause menu. `World` opens it on "pause" (Escape / Start).
## "pause" again closes it from any screen. `World` also opens it straight
## on the map page on "map" (M / Back) and on the inventory page on
## "inventory" (I); the same action closes that page again.

@export var world_map: WorldMap
@export var inventory: PlayerInventory


func open() -> void:
	open_screen(PauseScreen.new(world_map, inventory))


func open_map() -> void:
	open_screen(MapScreen.new(world_map))


func open_inventory() -> void:
	open_screen(InventoryScreen.new(inventory))


func _unhandled_input(event: InputEvent) -> void:
	var map_pressed := event.is_action_pressed("map") and top_screen() is MapScreen
	var inventory_pressed := (
		event.is_action_pressed("inventory") and top_screen() is InventoryScreen
	)
	if is_open() and (event.is_action_pressed("pause") or map_pressed or inventory_pressed):
		close()
		get_viewport().set_input_as_handled()
		return
	super(event)
