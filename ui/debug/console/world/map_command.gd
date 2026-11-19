extends ConsoleCommand
## `map`: reveals every map cell of every room in the catalog
## (`WorldMap.revealed`). Rooms never entered are drawn only once the map
## has scanned them (on a first visit), and cells behind an unbroken
## secret stay hidden; every cell counts toward the completion at once.


func _init() -> void:
	names = ["map"]
	summary = "Reveal the whole map"
	usage = ["map reveal: every cell of every room"]


func run(args: PackedStringArray) -> void:
	if args.size() != 1 or args[0] != "reveal":
		show_usage()
		return
	var world_map := world().world_map
	for cell in world_map.catalog.cells():
		world_map.revealed[cell] = true
	write("Map revealed: %d%% explored." % roundi(world_map.completion() * 100.0))


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return PackedStringArray(["reveal"]) if index == 0 else PackedStringArray()
