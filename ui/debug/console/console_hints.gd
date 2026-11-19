class_name ConsoleHints
extends RefCounted
## What the hint list under the debug console's command line shows for
## the text typed so far (only the part after the last `;`):
## - while the first word is typed, the commands whose name starts with
##   it, each with its summary;
## - after it, that command's forms (only those of the subcommand once
##   one is typed: `item give ` shows the give form), then the values that
##   may go where the cursor is (item ids, rooms, flags), filtered by what
##   is typed.
## Empty when nothing is typed or nothing matches.

const MAX_LINES := 8
const MAX_VALUES := 12
## Starts the line of values, so it reads apart from the forms.
const VALUES_MARK := "› "


static func for_line(shell: ConsoleShell, line: String) -> PackedStringArray:
	var part := line.substr(line.rfind(";") + 1).lstrip(" ")
	if part.is_empty():
		return []
	var words := part.split(" ")
	if words.size() == 1:
		return _commands(shell, words[0].to_lower())
	var command := shell.command_named(words[0])
	if command == null:
		return []
	var hints := _forms(command, words)
	var values := ConsoleShell.starting_with(shell.choices_for(words), words[-1])
	if not values.is_empty() and values != PackedStringArray([words[-1]]):
		hints.append(VALUES_MARK + _join_some(values))
	return hints.slice(-MAX_LINES)


## Each command with a name starting with `start`, shown by the name that
## matched: `sp` shows `speed (timescale)`.
static func _commands(shell: ConsoleShell, start: String) -> PackedStringArray:
	var hints := PackedStringArray()
	for command in shell.commands:
		for name in command.names:
			if name.begins_with(start):
				var shown := (
					name if name == command.names[0] else "%s (%s)" % [name, command.names[0]]
				)
				hints.append("%-10s %s" % [shown, command.summary])
				break
	return hints.slice(0, MAX_LINES)


## The command's forms, narrowed to the typed subcommand when its word is
## done (a space follows it) and some forms start with it.
static func _forms(command: ConsoleCommand, words: PackedStringArray) -> PackedStringArray:
	if words.size() < 3:
		return command.usage.duplicate()
	var start := "%s %s" % [command.names[0], words[1]]
	var narrowed := PackedStringArray()
	for form in command.usage:
		if form.begins_with(start + " ") or form.begins_with(start + ":"):
			narrowed.append(form)
	return narrowed if not narrowed.is_empty() else command.usage.duplicate()


static func _join_some(values: PackedStringArray) -> String:
	var shown := "  ".join(values.slice(0, MAX_VALUES))
	if values.size() > MAX_VALUES:
		shown += "  … %d more" % (values.size() - MAX_VALUES)
	return shown
