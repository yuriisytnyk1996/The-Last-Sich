class_name VolleyEffect
extends ItemEffect
## Fires a few shots (`PlayerProjectile` scenes) forward from the
## player's chest, one after another, each a little higher or lower than
## the last at random. For dumas. Damage is scaled by
## `PlayerDumas.strength()`. Shots still waiting are dropped if the duma
## was cut short (`PlayerDumas.generation`: death, a new room) or the
## player is gone.

@export var projectile_scene: PackedScene
@export var shots := 3
## Seconds between shots.
@export var interval := 0.15
## Shots after the first start up to this far above or below it (px).
@export var spread := 6.0
## Where the shots start, in front of the chest when facing right (px).
@export var muzzle := Vector2(12, -18)


func start(player: Player, _source: StringName) -> void:
	if projectile_scene == null:
		return
	var direction := float(player.facing)
	var from := player.global_position + Vector2(muzzle.x * direction, muzzle.y)
	var parent := player.get_parent()
	var generation := player.dumas.generation
	_fire(player, parent, from, direction)
	for i in range(1, shots):
		var jitter := Vector2(0.0, randf_range(-spread, spread))
		var timer := player.get_tree().create_timer(interval * i, false, true)
		timer.timeout.connect(
			_fire_later.bind(weakref(player), weakref(parent), from + jitter, direction, generation)
		)


## Timers hold weak references: a freed node can't be passed as a typed
## argument.
func _fire_later(
	player_ref: WeakRef, parent_ref: WeakRef, from: Vector2, direction: float, generation: int
) -> void:
	var player := player_ref.get_ref() as Player
	var parent := parent_ref.get_ref() as Node
	if player and parent and player.dumas.generation == generation:
		_fire(player, parent, from, direction)


func _fire(player: Player, parent: Node, from: Vector2, direction: float) -> void:
	var shot := projectile_scene.instantiate() as PlayerProjectile
	shot.launch(from, direction, player)
	shot.damage = roundi(shot.damage * player.dumas.strength())
	parent.add_child(shot)
