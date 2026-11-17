class_name SabreRing
extends Node2D
## Sabres circling the player, summoned by a duma (`SummonEffect`).
##
## Follows the player's chest. The ring opens from nothing to `radius`
## over `open_time` and spins `turns_per_second`. Each sabre is a `Hitbox`
## child that hits enemies it passes and is switched off and on again
## every `rehit_time`, so an enemy that stays in the ring is hit again. Enemy
## shots (`EnemyProjectile`) that touch a sabre are destroyed. `dismiss()`
## closes the ring over `close_time`, then frees it. A room change frees
## it at once. Damage is scaled by `PlayerDumas.strength()`.

@export var radius := 28.0
@export var open_time := 0.5
@export var close_time := 0.4
@export var turns_per_second := 0.8
@export var rehit_time := 0.5
## Height of the ring's centre above the player's feet (px).
@export var height := 16.0
## How fast the ring catches up with the player (higher is tighter).
@export var follow_speed := 12.0

var _player: Player
var _sabres: Array[Hitbox] = []
var _radius := 0.0
var _angle := 0.0
var _rehit := 0.0
var _closing := false
## The sabres were switched off last frame and go back on this one.
var _rearm := false


## Call before adding it to the tree.
func follow(player: Player) -> void:
	_player = player
	position = player.global_position + Vector2.UP * height


func _ready() -> void:
	Events.room_change_requested.connect(func(_p: String, _e: StringName) -> void: queue_free())
	for child in get_children():
		if child is Hitbox:
			var sabre := child as Hitbox
			sabre.attacker_stats = _player.stats
			sabre.damage = roundi(sabre.damage * _player.dumas.strength())
			sabre.monitoring = true
			sabre.area_entered.connect(_on_sabre_touched)
			sabre.set_active(true)
			_sabres.append(sabre)
	_rehit = rehit_time
	var tween := create_tween()
	tween.tween_property(self, ^"_radius", radius, open_time)


func dismiss() -> void:
	if _closing:
		return
	_closing = true
	var tween := create_tween()
	tween.tween_property(self, ^"_radius", 0.0, close_time)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		queue_free()
		return
	var target := _player.global_position + Vector2.UP * height
	global_position = global_position.lerp(target, minf(follow_speed * delta, 1.0))
	_angle = wrapf(_angle + TAU * turns_per_second * delta, 0.0, TAU)
	for i in _sabres.size():
		var angle := _angle + TAU * i / _sabres.size()
		_sabres[i].position = Vector2.from_angle(angle) * _radius
	_rehit -= delta
	if _rearm or _rehit <= 0.0:
		# Off for one frame so the hurtboxes inside see a new hit.
		_rearm = not _rearm
		_rehit = rehit_time
		for sabre in _sabres:
			sabre.set_active(not _rearm)


func _on_sabre_touched(area: Area2D) -> void:
	if area is EnemyProjectile:
		area.queue_free()
