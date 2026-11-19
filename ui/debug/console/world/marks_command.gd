extends ConsoleCommand
## `marks`: shows or clears the death marks (`DeathPenalty`), lifting the
## penalty as a cleanse point does, for free.


func _init() -> void:
	names = ["marks"]
	summary = "Show or clear the death marks"
	usage = ["marks: how many are waiting", "marks clear: remove them all and lift the penalty"]


func run(args: PackedStringArray) -> void:
	var penalty := world().death_penalty
	if args.size() == 1 and args[0] == "clear":
		penalty.clear()
	elif not args.is_empty():
		show_usage()
		return
	write("Death marks: %d" % penalty.count())


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return PackedStringArray(["clear"]) if index == 0 else PackedStringArray()
