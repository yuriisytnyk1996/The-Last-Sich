extends ConsoleCommand
## `tips`: forgets which tips were seen (`TipLog`), so each shows again
## the next time it comes up.


func _init() -> void:
	names = ["tips"]
	summary = "Forget the seen tips"
	usage = ["tips reset: every tip shows again the next time it comes up"]


func run(args: PackedStringArray) -> void:
	var tip_log := world().get_node_or_null(^"TipLog") as TipLog
	if args.size() != 1 or args[0] != "reset" or tip_log == null:
		show_usage()
		return
	tip_log.apply_save_data({})
	write("Seen tips forgotten.")


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return PackedStringArray(["reset"]) if index == 0 else PackedStringArray()
