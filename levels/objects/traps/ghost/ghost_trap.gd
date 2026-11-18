@tool
class_name GhostTrap
extends AreaEffect
## A haunted spot that stirs as the player passes: loose pages
## (`GhostPage`) lift and flutter around their feet, as if blown by
## something unseen. Only for show: it does no harm.
##
## When the player enters, one to `max_pages` pages fly up where they
## stand. While they stay inside, more fly up every `trigger_interval`,
## but only once they have moved `move_threshold` px from the last burst,
## so standing still stirs nothing. Bursts stay inside the zone sideways:
## the player's x is clamped to it. Lay the zone's bottom edge on the floor.

## Kept between a burst and the zone's side edges (px).
const EDGE_MARGIN := 3.0
## Pages kept ready per possible page in a burst.
const PREWARM_PER_PAGE := 5

@export var page_scene: PackedScene
## Most pages in one burst (at least one).
@export var max_pages := 3
## Burst point, from the player's feet (px).
@export var burst_offset := Vector2(0, -4)
## Seconds between bursts while the player moves inside.
@export var trigger_interval := 0.1
## Distance the player has to move for the next burst (px).
@export var move_threshold := 10.0

var _wait := 0.0
var _last_burst := Vector2.ZERO


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		Pool.prewarm(page_scene, max_pages * PREWARM_PER_PAGE)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or player == null:
		return
	_wait -= delta
	var at := _burst_point()
	if _wait <= 0.0 and at.distance_to(_last_burst) > move_threshold:
		_burst(at)


func _player_entered() -> void:
	_burst(_burst_point())


## The player's feet, kept inside the zone sideways (global).
func _burst_point() -> Vector2:
	var local := to_local(player.global_position)
	local.x = clampf(local.x, EDGE_MARGIN, size.x - EDGE_MARGIN)
	return to_global(local)


func _burst(at: Vector2) -> void:
	_last_burst = at
	_wait = trigger_interval
	if page_scene == null:
		return
	var parent := get_parent()
	for i in randi_range(1, maxi(max_pages, 1)):
		var page := Pool.take(page_scene) as GhostPage
		page.launch(parent.to_local(at + burst_offset))
		parent.add_child(page)


func _get_color() -> Color:
	return Color(0.55, 0.5, 0.9, 0.08)
