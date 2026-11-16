class_name SkillShrine
extends InteractionArea
## A shrine where the player learns skills. Pressing interact here pauses
## the game and opens the skill menu (`SkillsScreen`), which spends the
## player's currency. See `PlayerSkills`.


func _activate(player: Node2D) -> void:
	var visitor := player as Player
	visitor.velocity.x = 0.0
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(SkillsScreen.new(visitor.skills))
