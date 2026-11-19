extends ConsoleCommand
## `money`: shows, adds or takes away the currency the player carries.


func _init() -> void:
	names = ["money", "currency"]
	summary = "Show, add or take away currency"
	usage = ["money: show how much the player carries", "money <amount>: add it (negative takes)"]


func run(args: PackedStringArray) -> void:
	var wallet := player().wallet
	if args.is_empty():
		write("Currency: %d" % wallet.amount)
		return
	if not args[0].is_valid_int():
		show_usage()
		return
	var amount := args[0].to_int()
	if amount >= 0:
		wallet.add(amount)
	else:
		wallet.spend(mini(-amount, wallet.amount))
	write("Currency: %d" % wallet.amount)
