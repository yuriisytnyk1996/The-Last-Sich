class_name FalconFlock
extends Companion
## Falcons summoned by a duma (`SummonEffect`). They hover around the
## player's head, and every `check_interval` the flock sends one at the
## nearest enemy within `attack_range` that it can see (no solid terrain
## in between). Each falcon strikes once and is gone (`Falcon`). Once the
## last one flies the duma ends (`PlayerDumas.end()`); when its time runs
## out first, the falcons left fly away.
##
## Enemies already dying, turned off (a dormant boss) or on their knees
## (an execution waits for the player) are left alone.

## Physics layer of solid terrain, which blocks the falcons' sight.
const WORLD_MASK := 1

@export var attack_range := 160.0
## Seconds between looks for a target.
@export var check_interval := 0.6
## Height of the flock's centre above the player's feet (px).
@export var height := 34.0
@export var follow_speed := 7.0
## Distance of each falcon from the flock's centre (px).
@export var spread := 14.0
@export var bob_height := 2.0
@export var bob_speed := 4.0

var _falcons: Array[Falcon] = []
var _check := 0.0
var _time := 0.0


func _ready() -> void:
	for child in get_children():
		if child is Falcon:
			_falcons.append(child)
	_check = check_interval


func _physics_process(delta: float) -> void:
	if lost_player():
		return
	_time += delta
	glide_to(player.global_position + Vector2.UP * height, follow_speed, delta)
	_place_falcons()
	if is_dismissed():
		return
	_check -= delta
	if _check <= 0.0:
		_check = check_interval
		_send_one()


## The waiting falcons spread evenly in an arc over the player's head.
func _place_falcons() -> void:
	for i in _falcons.size():
		var angle := PI + PI * (i + 1) / (_falcons.size() + 1)
		var bob := sin(_time * bob_speed + i) * bob_height
		_falcons[i].position = Vector2.from_angle(angle) * spread + Vector2.UP * bob
		_falcons[i].scale.x = player.facing


func _send_one() -> void:
	var enemy := _pick_target()
	if enemy == null or _falcons.is_empty():
		return
	var falcon: Falcon = _falcons.pop_back()
	falcon.reparent(get_parent())
	falcon.launch(enemy, player, player.dumas.strength())
	if _falcons.is_empty():
		player.dumas.end()


func _pick_target() -> Enemy:
	var best: Enemy
	var best_distance := attack_range
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy == null or not _can_attack(enemy):
			continue
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance < best_distance and _can_see(enemy):
			best = enemy
			best_distance = distance
	return best


func _can_attack(enemy: Enemy) -> bool:
	if enemy.health.is_dead() or not enemy.hurtbox.monitoring:
		return false
	var state := enemy.state_machine.state
	return state != null and state.name != EnemyState.EXECUTABLE


func _can_see(enemy: Enemy) -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		global_position, Falcon.body_point(enemy), WORLD_MASK
	)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
