extends ConsoleCommand
## `timescale`: slows the game down or speeds it up
## (`HitStop.normal_scale`, so hit-stop freezes end at that speed).
## Lasts until changed back or the game quits.

const MIN_SCALE := 0.05
const MAX_SCALE := 4.0


func _init() -> void:
	names = ["timescale", "speed"]
	summary = "Slow the game down or speed it up"
	usage = ["timescale: show the speed", "timescale <speed>: 0.05 to 4, 1 is normal"]
	needs_game = false


func run(args: PackedStringArray) -> void:
	if args.size() == 1:
		if not args[0].is_valid_float():
			show_usage()
			return
		HitStop.normal_scale = clampf(args[0].to_float(), MIN_SCALE, MAX_SCALE)
	elif not args.is_empty():
		show_usage()
		return
	write("Speed: %.2f" % HitStop.normal_scale)


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return PackedStringArray(["0.25", "0.5", "1", "2"]) if index == 0 else PackedStringArray()
