class_name VolleyEffect
extends ItemEffect
## Fires a few shots (`PlayerProjectile` scenes) forward from the
## player's chest, one after another, each a little higher or lower than
## the last at random. For dumas. Damage is scaled by
## `PlayerDumas.strength()`.

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
	_fire(player, parent, from, direction)
	for i in range(1, shots):
		var jitter := Vector2(0.0, randf_range(-spread, spread))
		var timer := player.get_tree().create_timer(interval * i, false, true)
		timer.timeout.connect(_fire.bind(player, parent, from + jitter, direction))


func _fire(player: Player, parent: Node, from: Vector2, direction: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(parent):
		return
	var shot := projectile_scene.instantiate() as PlayerProjectile
	shot.launch(from, direction, player)
	shot.damage = roundi(shot.damage * player.dumas.strength())
	parent.add_child(shot)
