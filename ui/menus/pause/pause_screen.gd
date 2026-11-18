class_name PauseScreen
extends MenuScreen
## First page of the pause menu. "Tips" shows once a tip has been seen.

const MAIN_MENU := "res://ui/menus/main_menu/main_menu.tscn"

var _map: WorldMap
var _inventory: PlayerInventory
var _tip_log: TipLog


func _init(map: WorldMap, inventory: PlayerInventory, tip_log: TipLog) -> void:
	_map = map
	_inventory = inventory
	_tip_log = tip_log


func _build() -> void:
	add_title("Paused")
	add_button("Resume", go_back)
	add_button("Inventory", func() -> void: menu.push(InventoryScreen.new(_inventory)))
	add_button("Map", func() -> void: menu.push(MapScreen.new(_map)))
	if _tip_log and not _tip_log.seen_tips().is_empty():
		add_button("Tips", _open_tips)
	add_button("Options", func() -> void: menu.push(OptionsScreen.new()))
	add_button("Quit to main menu", _confirm_quit)


## Seen tips, to read again. Only listed once there is one.
func _open_tips() -> void:
	menu.push(TipScreen.new(_tip_log.seen_tips(), 0, _tip_log.gamepad, true))


func _confirm_quit() -> void:
	var question := "Quit to the main menu? You will continue from the last rest point."
	menu.push(ConfirmScreen.new(question, _quit))


func _quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
