class_name ConsoleHints
extends RefCounted
## What the hint list under the debug console's command line shows for
## the text typed so far (only the part after the last `;`), as entries
## `{"text": shown line, "pick": word it puts in the line, or ""}`:
## - while the first word is typed, the commands whose name starts with
##   it, each with its summary; picking one puts in its name;
## - after it, that command's forms (only those of the subcommand once
##   one is typed: `item give ` shows the give form), which can't be
##   picked, then one row per value that may go where the cursor is (item
##   ids, rooms, flags), filtered by what is typed.
## Empty when nothing is typed or nothing matches.

const MAX_COMMANDS := 10
const MAX_VALUES := 8
## Starts each value row, so values read apart from the forms.
const VALUE_MARK := "› "


static func for_line(shell: ConsoleShell, line: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var part := line.substr(line.rfind(";") + 1).lstrip(" ")
	if part.is_empty():
		return entries
	var words := part.split(" ")
	if words.size() == 1:
		return _commands(shell, words[0].to_lower())
	var command := shell.command_named(words[0])
	if command == null:
		return entries
	for form in _forms(command, words):
		entries.append(_entry(form))
	var values := ConsoleShell.starting_with(shell.choices_for(words), words[-1])
	if values.is_empty() or values == PackedStringArray([words[-1]]):
		return entries
	for value in values.slice(0, MAX_VALUES):
		entries.append(_entry(VALUE_MARK + value, value))
	if values.size() > MAX_VALUES:
		entries.append(_entry("  … %d more" % (values.size() - MAX_VALUES)))
	return entries


## Each command with a name starting with `start`, shown by the name that
## matched: `sp` shows `speed (timescale)`.
static func _commands(shell: ConsoleShell, start: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for command in shell.commands:
		for name in command.names:
			if name.begins_with(start):
				var shown := (
					name if name == command.names[0] else "%s (%s)" % [name, command.names[0]]
				)
				entries.append(_entry("%-10s %s" % [shown, command.summary], name))
				break
	return entries.slice(0, MAX_COMMANDS)


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


static func _entry(text: String, pick := "") -> Dictionary:
	return {"text": text, "pick": pick}
