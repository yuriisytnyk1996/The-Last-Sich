extends ConsoleCommand
## `clear`: empties the console's output.


func _init() -> void:
	names = ["clear", "cls"]
	summary = "Empty the console"
	usage = ["clear"]
	needs_game = false


func run(_args: PackedStringArray) -> void:
	shell.cleared.emit()
