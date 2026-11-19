extends ConsoleCommand
## `flag`: lists, sets, clears and tests story flags (`PlayerStory`).
## Changes go through `Events.story_changed`, so NPCs and toggles react
## and the story autosave writes them.

const ACTIONS: PackedStringArray = ["list", "set", "clear", "test"]


func _init() -> void:
	names = ["flag"]
	summary = "List, set, clear or test story flags"
	usage = [
		"flag list [start]: the set flags, or those starting with start",
		"flag set <flag>",
		"flag clear <flag>",
		"flag test <flag>: is it set?",
	]


func run(args: PackedStringArray) -> void:
	var story := player().story
	var action := args[0] if args.size() > 0 else ""
	if action == "list" and args.size() <= 2:
		var start := args[1] if args.size() == 2 else ""
		var shown := ConsoleShell.starting_with(set_flags(story), start)
		write(", ".join(shown) if not shown.is_empty() else "No flags set.")
		return
	if not action in ["set", "clear", "test"] or args.size() != 2:
		show_usage()
		return
	var flag := StringName(args[1])
	if action == "set":
		story.set_flag(flag)
	elif action == "clear":
		story.clear_flag(flag)
	write("%s is %s" % [flag, "set" if story.has(flag) else "not set"])


func complete(index: int, args: PackedStringArray) -> PackedStringArray:
	if index == 0:
		return ACTIONS
	if index == 1 and args[0] in ["clear", "test"]:
		return set_flags(player().story)
	return PackedStringArray()


static func set_flags(story: PlayerStory) -> PackedStringArray:
	var flags := PackedStringArray(story.get_save_data().flags)
	flags.sort()
	return flags
