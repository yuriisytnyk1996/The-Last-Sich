class_name DeathPenalty
extends Node
## The death penalty. Every death leaves a death mark on the last safe
## ground the player stood on (see `PlayerSafeGround`), up to `max_marks`.
## Pits and spikes count like any other death.
##
## Each mark lowers max spirit, spirit gain and currency gain: the factor
## tables are indexed by the number of marks. Pressing interact at a mark
## recovers it and every mark linked to it (see `DeathMarkList`), restores
## the stats and gives a bonus: some health and some spirit.
##
## A child of the `World`, which calls `drop()` on death and `place_in()`
## on every room load. A global save system (see `SaveManager`).

const MARK_SCENE := preload("res://levels/objects/death_mark.tscn")

@export var player: Player

@export_group("Marks")
@export var max_marks := 5
## A new mark this close to an older one in the same room links to it (px).
@export var link_distance := 64.0

@export_group("Penalty")
## Each table is indexed by the number of marks. Past its end, the last
## value is used.
@export var spirit_max_factor := PackedFloat32Array([1.0, 0.9, 0.8, 0.7, 0.6, 0.5])
@export var spirit_gain_factor := PackedFloat32Array([1.0, 0.85, 0.7, 0.55, 0.4, 0.25])
@export var currency_gain_factor := PackedFloat32Array([1.0, 0.9, 0.8, 0.7, 0.6, 0.5])

@export_group("Recovery")
## Part of max health healed when a mark is recovered.
@export_range(0.0, 1.0) var recover_heal := 0.33
## Part of max spirit given when a mark is recovered.
@export_range(0.0, 1.0) var recover_spirit := 0.5

var save_id := &"death_penalty"

var _marks := DeathMarkList.new()
var _markers: Array[DeathMark] = []


func _ready() -> void:
	SaveManager.register(self)
	_apply.call_deferred()


## Leaves a mark for a death in `current_room`. Call it before the respawn.
func drop(current_room: Room) -> void:
	if _marks.count() < max_marks:
		var ground := player.safe_ground
		if ground.room != "":
			_marks.add(ground.room, ground.spot, link_distance)
		else:
			var spot := current_room.get_respawn_position()
			_marks.add(current_room.scene_file_path, spot, link_distance)
	_apply()


## Removes every mark at once (a paid cleanse, later).
func clear() -> void:
	_marks.clear()
	_remove_markers()
	_apply()


## Spawns a marker for each mark shown in `room`.
func place_in(room: Room) -> void:
	_remove_markers()
	for mark in _marks.shown_in(room.scene_file_path):
		var marker := MARK_SCENE.instantiate() as DeathMark
		marker.mark_id = mark["id"]
		marker.position = room.to_local(DeathMarkList.spot_of(mark))
		marker.recovered.connect(_on_recovered)
		room.add_child(marker)
		_markers.append(marker)


func get_save_data() -> Dictionary:
	return _marks.to_data()


func apply_save_data(data: Dictionary) -> void:
	_marks.from_data(data)
	_apply()


func _on_recovered(mark_id: int, _player: Player) -> void:
	_marks.recover(mark_id)
	_apply()
	var health := player.health
	health.heal(maxi(roundi(health.max_health * recover_heal), 1))
	player.spirit.add(player.spirit.get_max() * recover_spirit)


## Sets the player's stats for the current number of marks.
func _apply() -> void:
	var marks := _marks.count()
	player.spirit.max_factor = _factor(spirit_max_factor, marks)
	player.spirit.gain_factor = _factor(spirit_gain_factor, marks)
	player.wallet.gain_factor = _factor(currency_gain_factor, marks)
	Events.death_marks_changed.emit(_marks.count())


func _factor(table: PackedFloat32Array, marks: int) -> float:
	if table.is_empty():
		return 1.0
	return table[mini(marks, table.size() - 1)]


func _remove_markers() -> void:
	for marker in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()
