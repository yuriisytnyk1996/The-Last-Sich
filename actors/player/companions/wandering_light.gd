class_name WanderingLight
extends Companion
## A small light that follows the wearer of the wandering candle (a relic,
## `SummonEffect` while worn) and leads them to captives.
##
## It floats at `offset` behind the player's shoulder, wobbling. Once it
## has been in a room for `notice_delay`, it looks for a captive still
## caged there (a `Breakable` in the `captives` group, not broken) and
## drifts over to hover above the nearest one at `seek_speed`, until that
## captive is freed or the room changes. Then it comes back to the player.

const CAPTIVES_GROUP := &"captives"

## Where it floats, from the player's feet, when they face right (px).
@export var offset := Vector2(-14.0, -30.0)
@export var follow_speed := 5.0
## Speed while drifting to a captive (px/s).
@export var seek_speed := 120.0
## Height above a captive's feet where it hovers (px).
@export var hover_height := 40.0
## Seconds in a room (or since it came back) before it looks for captives.
@export var notice_delay := 2.0
## Seconds between looks while there is none.
@export var search_interval := 0.5
@export var wobble := Vector2(4.0, 2.0)
@export var wobble_speed := Vector2(1.3, 2.6)

## The captive it is hovering over. Untyped: its room may be freed under it.
var _captive: Variant = null
var _notice := 0.0
var _time := 0.0


func follow(summoner: Player) -> void:
	super(summoner)
	position = _player_spot()
	_notice = notice_delay


func _physics_process(delta: float) -> void:
	if lost_player():
		return
	_time += delta
	if _captive != null and not _still_caged(_captive):
		_captive = null
		_notice = notice_delay
	if _captive == null and not is_dismissed():
		_notice -= delta
		if _notice <= 0.0:
			_captive = _find_captive()
			_notice = search_interval
	var drift := Vector2(
		sin(_time * wobble_speed.x) * wobble.x, cos(_time * wobble_speed.y) * wobble.y
	)
	if _captive != null:
		var hover: Vector2 = _captive.global_position + Vector2.UP * hover_height + drift
		global_position = global_position.move_toward(hover, seek_speed * delta)
	elif glide_to(_player_spot() + drift, follow_speed, delta):
		# Jumped to the player: a new room.
		_notice = notice_delay


func _player_spot() -> Vector2:
	return player.global_position + Vector2(offset.x * player.facing, offset.y)


func _find_captive() -> Breakable:
	var best: Breakable
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(CAPTIVES_GROUP):
		var cage := node as Breakable
		if cage == null or not _still_caged(cage):
			continue
		var distance := player.global_position.distance_to(cage.global_position)
		if distance < best_distance:
			best = cage
			best_distance = distance
	return best


func _still_caged(cage: Variant) -> bool:
	if not is_instance_valid(cage):
		return false
	var breakable := cage as Breakable
	return breakable.is_inside_tree() and not breakable.broken
