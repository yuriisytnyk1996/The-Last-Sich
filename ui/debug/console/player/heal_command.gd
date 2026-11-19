extends ConsoleCommand
## `heal`: fills health, flasks and spirit.


func _init() -> void:
	names = ["heal"]
	summary = "Fill health, flasks and spirit"
	usage = ["heal"]


func run(_args: PackedStringArray) -> void:
	var target := player()
	if target.health.is_dead():
		error("The player is dead; wait for the respawn.")
		return
	target.health.heal(target.health.max_health)
	target.flasks.refill()
	target.spirit.fill()
	write("Health, flasks and spirit filled.")
