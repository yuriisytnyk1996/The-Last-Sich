class_name TitleScreen
extends MenuScreen
## First page of the main menu. Continue only shows when there is a save.
## Quit is hidden on phones, where apps aren't closed from inside.

const WORLD := "res://levels/world.tscn"


func _build() -> void:
	add_title("The Last Sich")
	add_gap(12)
	if SaveManager.has_save():
		add_button("Continue", _start)
	add_button("New game", _new_game)
	add_button("Options", func() -> void: menu.push(OptionsScreen.new()))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		add_button("Quit", get_tree().quit)


## The root screen stays put on back.
func go_back() -> void:
	pass


func _new_game() -> void:
	if not SaveManager.has_save():
		_start()
		return
	var question := "Start a new game? Your saved progress will be lost."
	menu.push(ConfirmScreen.new(question, _start_over))


func _start_over() -> void:
	SaveManager.delete_save()
	_start()


func _start() -> void:
	get_tree().change_scene_to_file(WORLD)
