class_name WagonFort
extends Companion
## A warding circle set down where its duma is sung (`SummonEffect`).
##
## It stays where it was set down. While the player's chest is within
## `radius` of its centre, their hurtbox is warded (`Hurtbox.set_ward()`):
## hits are blocked, enemy shots stop on them, and parries still work.
## Pits and spikes still kill. It opens over `open_time` and fades on
## `dismiss()`. While the duma runs it goes along with the player: after a
## room exit, travel or the Road Home (`Events.player_arrived`) it opens
## again where the player arrives.

const WARD := &"wagon_fort"

## Radius of the circle when open (px).
@export var radius := 40.0
@export var open_time := 0.3
## Height of the player's chest above the feet, measured against the
## circle (px).
@export var chest_height := 16.0
@export var fill := Color(1.0, 0.82, 0.45, 0.18)
@export var rim := Color(1.0, 0.85, 0.5, 0.8)

var _radius := 0.0
var _warding := false
var _tween: Tween


func _ready() -> void:
	_open()
	Events.player_arrived.connect(_on_player_arrived)


func _physics_process(_delta: float) -> void:
	if lost_player():
		return
	var chest := player.global_position + Vector2.UP * chest_height
	_set_warding(not is_dismissed() and chest.distance_to(global_position) <= _radius)
	queue_redraw()


## Drawn as a dome on the ground: the upper half of the circle.
func _draw() -> void:
	if _radius <= 0.0:
		return
	var points := PackedVector2Array()
	for i in 25:
		points.append(Vector2.from_angle(PI + PI * i / 24.0) * _radius)
	draw_colored_polygon(points, fill)
	draw_polyline(points, rim, 1.0)


func _exit_tree() -> void:
	_set_warding(false)


func _on_dismiss() -> void:
	_set_warding(false)


func _set_warding(on: bool) -> void:
	if on == _warding or not is_instance_valid(player):
		return
	_warding = on
	player.hurtbox.set_ward(WARD, on)


func _open() -> void:
	if _tween:
		_tween.kill()
	_radius = 0.0
	_tween = create_tween()
	_tween.tween_property(self, ^"_radius", radius, open_time)


## Set down again at the player's feet in the new place.
func _on_player_arrived() -> void:
	if is_dismissed() or not is_instance_valid(player):
		return
	_set_warding(false)
	global_position = player.global_position
	reset_physics_interpolation()
	_open()
