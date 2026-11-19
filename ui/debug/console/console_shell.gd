class_name ConsoleShell
extends Node
## Runs the lines typed into the debug console: finds the command by its
## name, or by the start of a name when only one command has it
## (`he` runs `heal` only if no other name starts with "he"), and hands it
## the rest of the words. Several commands can share a line, split by
## `;`. Also completes a half-typed word on Tab.
## A child of the `DebugConsole` autoload, which shows what it prints. A
## node, so the commands' references back to it make no cycle.

signal printed(text: String, color: Color)
signal cleared
## A command is about to move the game on (a room change) and needs the
## console closed and the game running first.
signal close_requested

const TEXT_COLOR := Color(0.9, 0.9, 0.9)
const ERROR_COLOR := Color(1.0, 0.45, 0.4)
const DIM_COLOR := Color(0.6, 0.6, 0.65)
const COMMANDS: Array[GDScript] = [
	preload("res://ui/debug/console/help_command.gd"),
	preload("res://ui/debug/console/clear_command.gd"),
	preload("res://ui/debug/console/player/god_command.gd"),
	preload("res://ui/debug/console/player/heal_command.gd"),
	preload("res://ui/debug/console/player/money_command.gd"),
	preload("res://ui/debug/console/player/item_command.gd"),
	preload("res://ui/debug/console/player/skill_command.gd"),
	preload("res://ui/debug/console/player/upgrade_command.gd"),
	preload("res://ui/debug/console/world/room_command.gd"),
	preload("res://ui/debug/console/world/kill_command.gd"),
	preload("res://ui/debug/console/world/flag_command.gd"),
	preload("res://ui/debug/console/world/counter_command.gd"),
	preload("res://ui/debug/console/world/map_command.gd"),
	preload("res://ui/debug/console/world/marks_command.gd"),
	preload("res://ui/debug/console/world/tips_command.gd"),
	preload("res://ui/debug/console/world/save_command.gd"),
	preload("res://ui/debug/console/world/timescale_command.gd"),
]

var commands: Array[ConsoleCommand] = []


func _init() -> void:
	for script in COMMANDS:
		var command: ConsoleCommand = script.new()
		command.shell = self
		commands.append(command)


func write(text: String, color := TEXT_COLOR) -> void:
	printed.emit(text, color)


func error(text: String) -> void:
	write(text, ERROR_COLOR)


func world() -> World:
	return get_tree().current_scene as World


## Runs every `;`-separated command of `line` in turn.
func run_line(line: String) -> void:
	for part in line.split(";", false):
		_run_one(part)


func _run_one(part: String) -> void:
	var words := part.strip_edges().split(" ", false)
	if words.is_empty():
		return
	var command := find(words[0])
	if command == null:
		return
	if command.needs_game and world() == null:
		error("Only while playing, not in the menus.")
		return
	command.run(words.slice(1))


## The command called `word`, or the only one with a name starting with
## it. Writes why when there is none.
func find(word: String) -> ConsoleCommand:
	word = word.to_lower()
	var matches: Array[ConsoleCommand] = []
	for command in commands:
		if word in command.names:
			return command
		if Array(command.names).any(func(name: String) -> bool: return name.begins_with(word)):
			matches.append(command)
	if matches.size() == 1:
		return matches[0]
	if matches.is_empty():
		error('Unknown command "%s". Type help for the list.' % word)
	else:
		error('"%s" could be: %s' % [word, ", ".join(matches.map(_first_name))])
	return null


## `line` with its last word completed as far as it goes. Only the part
## after the last `;` is looked at. Prints the choices when there are
## several.
func complete(line: String) -> String:
	var cut := line.rfind(";") + 1
	var part := line.substr(cut)
	var before := line.left(cut) + " ".repeat(part.length() - part.lstrip(" ").length())
	var words := part.lstrip(" ").split(" ")
	var head := " ".join(words.slice(0, -1))
	var choices := starting_with(choices_for(words), words[-1])
	if choices.is_empty():
		return line
	var done := _common_start(choices)
	if choices.size() > 1:
		write("  ".join(choices), DIM_COLOR)
	elif not done.is_empty():
		done += " "
	return before + (done if head.is_empty() else head + " " + done)


## Every word that may go last in `words` (the words of one command, the
## last one being typed): command names first, then the command's own.
func choices_for(words: PackedStringArray) -> PackedStringArray:
	var choices := PackedStringArray()
	if words.size() == 1:
		for command in commands:
			choices.append(command.names[0])
		return choices
	var command := command_named(words[0])
	if command == null or (command.needs_game and world() == null):
		return choices
	return command.complete(words.size() - 2, words.slice(1, -1))


## The command with exactly this name, or null. Silent, unlike `find()`.
func command_named(word: String) -> ConsoleCommand:
	for command in commands:
		if word.to_lower() in command.names:
			return command
	return null


## `line` with its last word (the one being typed, after the last space or
## `;`) replaced by `word` and a space, ready for the next one.
static func with_last_word(line: String, word: String) -> String:
	var cut := maxi(line.rfind(" "), line.rfind(";"))
	var head := line.left(cut + 1)
	if head.ends_with(";"):
		head += " "
	return head + word + " "


## The words of `words` that start with `start`.
static func starting_with(words: PackedStringArray, start: String) -> PackedStringArray:
	var found := PackedStringArray()
	for word in words:
		if word.begins_with(start):
			found.append(word)
	return found


static func _first_name(command: ConsoleCommand) -> String:
	return command.names[0]


static func _common_start(words: PackedStringArray) -> String:
	var start := words[0]
	for word in words:
		while not word.begins_with(start):
			start = start.left(-1)
	return start
