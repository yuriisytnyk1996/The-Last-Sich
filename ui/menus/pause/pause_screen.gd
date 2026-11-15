class_name PauseScreen
extends MenuScreen
## First page of the pause menu.

const MAIN_MENU := "res://ui/menus/main_menu/main_menu.tscn"


func _build() -> void:
	add_title("Paused")
	add_button("Resume", go_back)
	add_button("Options", func() -> void: menu.push(OptionsScreen.new()))
	add_button("Quit to main menu", _confirm_quit)


func _confirm_quit() -> void:
	var question := "Quit to the main menu? You will continue from the last rest point."
	menu.push(ConfirmScreen.new(question, _quit))


func _quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
