class_name RestoreEffect
extends ItemEffect
## Gives the player health, spirit or currency once, when the trigger
## fires (heal a little on a kill). Meant for event triggers.

enum Target { HEALTH, SPIRIT, CURRENCY }

@export var what := Target.HEALTH
@export var amount := 5


func start(player: Player, _source: StringName) -> void:
	match what:
		Target.HEALTH:
			if not player.health.is_dead():
				player.health.heal(amount)
		Target.SPIRIT:
			player.spirit.add(amount)
		Target.CURRENCY:
			player.wallet.add(amount)
