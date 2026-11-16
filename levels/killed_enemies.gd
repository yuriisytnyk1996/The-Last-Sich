class_name KilledEnemies
extends RefCounted
## Remembers which enemies the player has killed, so a cleared room stays
## cleared when the player leaves and comes back.
##
## Kept in memory only and never saved: the `World` clears it whenever the
## player rests or dies, which brings every enemy back. The game only saves
## when the player rests or dies, so a saved game never has killed enemies
## to remember.

## "room scene path::node path inside the room" -> true
var _killed := {}


## Lays the room's remembered enemies dead, and starts remembering the
## ones killed from now on. Call it once each time a room is loaded.
func watch(room: Room) -> void:
	for enemy in room.get_enemies():
		var key := _key(room, enemy)
		if enemy.damage.stays_dead and _killed.has(key):
			enemy.damage.lie_dead()
		enemy.health.died.connect(_on_enemy_died.bind(key))


## Forgets every kill, so all enemies come back.
func clear() -> void:
	_killed.clear()


func _on_enemy_died(key: String) -> void:
	_killed[key] = true


func _key(room: Room, enemy: Enemy) -> String:
	return "%s::%s" % [room.scene_file_path, room.get_path_to(enemy)]
