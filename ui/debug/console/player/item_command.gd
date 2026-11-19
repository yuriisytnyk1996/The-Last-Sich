extends ConsoleCommand
## `item`: lists, gives and takes away items by id (`PlayerInventory`).
## Giving goes through `PlayerInventory.add()`, so the item toast and the
## first-of-a-kind tips show as for a pickup.

const ACTIONS: PackedStringArray = ["list", "give", "take"]


func _init() -> void:
	names = ["item"]
	summary = "List, give or take items"
	usage = [
		"item list [kind]: every item, * marks owned (kinds: charm, blade, relic...)",
		"item give <id|all>: give one item or all of them",
		"item take <id>: take an item away",
	]


func run(args: PackedStringArray) -> void:
	var inventory := player().inventory
	var action := args[0] if args.size() > 0 else ""
	if action == "list":
		_list(inventory, args[1].to_upper() if args.size() > 1 else "")
	elif action == "give" and args.size() == 2 and args[1] == "all":
		inventory.add_all()
		write("Gave every item.")
	elif action in ["give", "take"] and args.size() == 2:
		var item := inventory.find(StringName(args[1]))
		if item == null:
			error('No item "%s". Try item list.' % args[1])
		elif action == "give":
			write(("Gave %s." if inventory.add(item) else "Already owns %s.") % item.id)
		else:
			write(("Took %s." if inventory.remove(item) else "Doesn't own %s.") % item.id)
	else:
		show_usage()


func complete(index: int, args: PackedStringArray) -> PackedStringArray:
	if index == 0:
		return ACTIONS
	var words := PackedStringArray()
	if index == 1 and args[0] == "list":
		for kind_name: String in Item.Kind.keys():
			words.append(kind_name.to_lower())
	elif index == 1 and args[0] in ["give", "take"]:
		for item in player().inventory.all:
			words.append(String(item.id))
		if args[0] == "give":
			words.append("all")
	return words


func _list(inventory: PlayerInventory, kind_name: String) -> void:
	if kind_name != "" and not Item.Kind.has(kind_name):
		error('No kind "%s".' % kind_name.to_lower())
		return
	for item in inventory.all:
		if kind_name == "" or item.kind == Item.Kind[kind_name]:
			var owned := "*" if inventory.owns(item) else " "
			var kind: String = Item.Kind.keys()[item.kind]
			write("%s %-22s %s" % [owned, item.id, kind.to_lower()])
