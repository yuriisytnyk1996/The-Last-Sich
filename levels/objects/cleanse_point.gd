class_name CleansePoint
extends InteractionArea
## A place to pay currency to clear every death mark at once, without
## walking back to them. Pressing interact pauses the game and opens a
## `CleanseScreen` with the number of marks, the price and the player's
## currency. The price grows with the number of marks.
##
## Usable any number of times. Finds the `DeathPenalty` through its group.

## Price for each death mark cleared.
@export var price_per_mark := 150


func get_price(marks: int) -> int:
	return price_per_mark * marks


func _activate(player: Node2D) -> void:
	var penalty := get_tree().get_first_node_in_group(DeathPenalty.GROUP) as DeathPenalty
	if penalty == null:
		push_warning("CleansePoint: no DeathPenalty in the tree")
		return
	var payer := player as Player
	payer.velocity.x = 0.0
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(CleanseScreen.new(penalty, get_price(penalty.count()), payer))
