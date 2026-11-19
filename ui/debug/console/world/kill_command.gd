extends ConsoleCommand
## `kill`: kills every enemy in the room (bosses too, which ends the fight
## as a win), or the player.


func _init() -> void:
	names = ["kill"]
	summary = "Kill every enemy in the room, or the player"
	usage = ["kill: every enemy in the room", "kill player: the player"]


func run(args: PackedStringArray) -> void:
	if args.size() == 1 and args[0] == "player":
		player().health.kill()
		write("Killed the player.")
		return
	if not args.is_empty():
		show_usage()
		return
	var count := 0
	for enemy in world().room.get_enemies():
		if not enemy.health.is_dead():
			enemy.health.kill()
			count += 1
	write("Killed %d enemies." % count)


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return PackedStringArray(["player"]) if index == 0 else PackedStringArray()
