class_name ReturnEffect
extends ItemEffect
## Takes the player back to the last rest point they used, as a fade
## (`Events.return_requested`, handled by `World`). Health, flasks and
## spirit stay as they are: it is a way home, not a rest. For dumas.
##
## It can't start during a boss fight (`BossArena.FIGHT_GROUP`), so the
## duma isn't sung and no spirit is spent there.


func can_start(player: Player) -> bool:
	return not player.get_tree().has_group(BossArena.FIGHT_GROUP)


func start(_player: Player, _source: StringName) -> void:
	Events.return_requested.emit()
