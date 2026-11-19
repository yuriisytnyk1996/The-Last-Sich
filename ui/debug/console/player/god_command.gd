extends ConsoleCommand
## `god`: no hit lands on the player while it is on (`Hurtbox.immune`).
## Pits still kill. Lasts until turned off or the game is left.


func _init() -> void:
	names = ["god"]
	summary = "Toggle god mode: no hit lands on the player"
	usage = ["god: turn it on or off (pits still kill)"]


func run(_args: PackedStringArray) -> void:
	var hurtbox := player().hurtbox
	hurtbox.immune = not hurtbox.immune
	write("God mode " + on_off(hurtbox.immune))
