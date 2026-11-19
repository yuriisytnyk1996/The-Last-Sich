extends ConsoleCommand
## `upgrade`: adds permanent stat upgrades, as shrines, empty flasks and
## the flask healer do (`PlayerUpgrades`).


func _init() -> void:
	names = ["upgrade"]
	summary = "Add permanent upgrades: health, spirit, flasks, flask_heal"
	usage = ["upgrade: show the upgrades so far", "upgrade <kind> [times]: add one or more"]


func run(args: PackedStringArray) -> void:
	var upgrades := player().upgrades
	if args.is_empty():
		for kind_name: String in PlayerUpgrades.Kind.keys():
			write(
				"%-10s %d" % [kind_name.to_lower(), upgrades.count(PlayerUpgrades.Kind[kind_name])]
			)
		return
	var kind_name := args[0].to_upper()
	var times := args[1].to_int() if args.size() > 1 else 1
	if not PlayerUpgrades.Kind.has(kind_name) or times < 1:
		show_usage()
		return
	var kind: PlayerUpgrades.Kind = PlayerUpgrades.Kind[kind_name]
	for i in times:
		upgrades.upgrade(kind)
	write("%s upgrades: %d" % [args[0].to_lower(), upgrades.count(kind)])


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	var words := PackedStringArray()
	if index == 0:
		for kind_name: String in PlayerUpgrades.Kind.keys():
			words.append(kind_name.to_lower())
	return words
