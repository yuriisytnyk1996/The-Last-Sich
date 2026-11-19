class_name ConsoleCommand
extends RefCounted
## One command of the debug console (see `ConsoleShell`). A subclass sets
## `names`, `summary` and `usage` in `_init()` and does its work in
## `run()`. Arguments arrive split on spaces, with their case kept: story
## flags and item ids are matched as typed.

## What is typed to run it. The first one is listed by `help`.
var names: PackedStringArray = []
## One line for the `help` list.
var summary := ""
## One line per form, shown by `help <name>` and after a wrong call.
var usage: PackedStringArray = []
## Off for commands that also work outside the game (help, clear).
var needs_game := true
## Set by the shell when the command is added.
var shell: ConsoleShell


func run(_args: PackedStringArray) -> void:
	pass


## Tab completion: the words that may go at argument `index` (0 is the
## first word after the name). `args` holds the words typed before it.
func complete(_index: int, _args: PackedStringArray) -> PackedStringArray:
	return []


func write(text: String) -> void:
	shell.write(text)


## Writes `text` in red: something went wrong or wasn't found.
func error(text: String) -> void:
	shell.error(text)


func show_usage() -> void:
	for line in usage:
		shell.write(line, ConsoleShell.DIM_COLOR)


## The running game, or null outside it (the main menu).
func world() -> World:
	return shell.world()


func player() -> Player:
	return shell.world().player


static func on_off(value: bool) -> String:
	return "on" if value else "off"
