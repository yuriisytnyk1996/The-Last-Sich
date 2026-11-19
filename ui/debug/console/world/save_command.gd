extends ConsoleCommand
## `save`: writes the slot now, as a rest does, without healing or moving
## the respawn point (`SaveManager.save_game()`).


func _init() -> void:
	names = ["save"]
	summary = "Write the save slot now"
	usage = ["save"]


func run(_args: PackedStringArray) -> void:
	SaveManager.save_game(world().room)
	write("Saved to slot %d." % (SaveManager.slot + 1))
