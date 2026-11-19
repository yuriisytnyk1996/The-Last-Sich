extends ConsoleCommand
## `counter`: shows story counters and raises one (`PlayerStory`).
## Counters only grow, as in play (currency donated, letters handed in).


func _init() -> void:
	names = ["counter"]
	summary = "Show story counters, or raise one"
	usage = ["counter: every counter", "counter <name> [amount]: show it, or raise it by amount"]


func run(args: PackedStringArray) -> void:
	var story := player().story
	if args.is_empty():
		var counters: Dictionary = story.get_save_data().counters
		for counter_name: StringName in counters:
			write("%-20s %d" % [counter_name, counters[counter_name]])
		if counters.is_empty():
			write("No counters yet.")
		return
	var counter_name := StringName(args[0])
	if args.size() == 2:
		if not args[1].is_valid_int() or args[1].to_int() <= 0:
			error("Counters only grow: give a positive amount.")
			return
		story.add_counter(counter_name, args[1].to_int())
	write("%s: %d" % [counter_name, story.counter(counter_name)])


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	var words := PackedStringArray()
	if index == 0:
		for counter_name: StringName in player().story.get_save_data().counters:
			words.append(String(counter_name))
	return words
