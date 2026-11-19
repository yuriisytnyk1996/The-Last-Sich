extends ConsoleCommand
## `help`: lists every command, or shows how to use one.


func _init() -> void:
	names = ["help", "?"]
	summary = "List the commands, or show how to use one"
	usage = ["help: list every command", "help <command>: show its forms"]
	needs_game = false


func run(args: PackedStringArray) -> void:
	if args.is_empty():
		for command in shell.commands:
			write("%-10s %s" % [command.names[0], command.summary])
		shell.write(
			"Tab completes, Up and Down repeat earlier lines, ; runs several.",
			ConsoleShell.DIM_COLOR
		)
		return
	var command := shell.find(args[0])
	if command:
		write(command.summary)
		for line in command.usage:
			write("  " + line)


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	var words := PackedStringArray()
	if index == 0:
		for command in shell.commands:
			words.append(command.names[0])
	return words
