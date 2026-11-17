class_name BlastRowEffect
extends ItemEffect
## Sets off a row of blasts (`PlayerBlast` scenes) along the ground from
## the player, one after another: pillars of fire marching forward, or a
## single blast on the player with `count` 1 and `offset` 0. For dumas.
##
## The first blast goes off `offset` px in front of the player's feet,
## the next ones `spacing` further each, spread evenly over `spread_time`.
## A wall ends the row. Damage is scaled by `PlayerDumas.strength()`.
## Blasts still waiting are dropped if the duma was cut short
## (`PlayerDumas.generation`: death, a new room) or the player is gone.

## Height above the feet the wall check runs at (px).
const WALL_CHECK_HEIGHT := 8.0

@export var blast_scene: PackedScene
@export var count := 8
## Distance from the player to the first blast (px).
@export var offset := 24.0
## Distance between blasts (px).
@export var spacing := 24.0
## Seconds from the first blast to the last.
@export var spread_time := 0.6
## One row forward and one behind instead of only forward.
@export var both_sides := false
## Camera shake when the row starts (0 to 1).
@export var shake := 0.3


func start(player: Player, _source: StringName) -> void:
	if blast_scene == null:
		return
	if shake > 0.0:
		Events.camera_shake_requested.emit(shake)
	var directions: Array[float] = [float(player.facing)]
	if both_sides:
		directions.append(float(-player.facing))
	for direction in directions:
		_start_row(player, direction)


func _start_row(player: Player, direction: float) -> void:
	var feet := player.global_position
	var parent := player.get_parent()
	var generation := player.dumas.generation
	for i in count:
		var point := feet + Vector2(direction * (offset + spacing * i), 0.0)
		if _blocked(player, feet, point):
			return
		var delay := spread_time * i / maxf(count - 1, 1)
		if delay <= 0.0:
			_spawn(player, parent, point)
		else:
			var timer := player.get_tree().create_timer(delay, false, true)
			timer.timeout.connect(
				_spawn_later.bind(weakref(player), weakref(parent), point, generation)
			)


func _blocked(player: Player, from: Vector2, to: Vector2) -> bool:
	if from.is_equal_approx(to):
		return false
	var lift := Vector2.UP * WALL_CHECK_HEIGHT
	var query := PhysicsRayQueryParameters2D.create(from + lift, to + lift, 1)
	return not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Timers hold weak references: a freed node can't be passed as a typed
## argument.
func _spawn_later(player_ref: WeakRef, parent_ref: WeakRef, at: Vector2, generation: int) -> void:
	var player := player_ref.get_ref() as Player
	var parent := parent_ref.get_ref() as Node
	if player and parent and player.dumas.generation == generation:
		_spawn(player, parent, at)


func _spawn(player: Player, parent: Node, at: Vector2) -> void:
	var blast := PlayerBlast.spawn(blast_scene, parent, at, player.stats)
	blast.damage = roundi(blast.damage * player.dumas.strength())
