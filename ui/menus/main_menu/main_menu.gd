extends Node
## The main scene: shows the main menu. Starting or continuing a game
## switches to the world scene, which loads the save itself.

## Colour behind the title screen.
@export var background := Color(0.06, 0.05, 0.08, 1.0)


func _ready() -> void:
	var menu := Menu.new()
	menu.background = background
	add_child(menu)
	menu.push(TitleScreen.new())
