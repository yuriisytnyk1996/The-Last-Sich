class_name MapTravel
extends Node
## The `MapView`'s travel mode, opened by kneeling at a rest point (see
## `KneelScreen`). The cursor never moves freely: it only stops on rest
## points. A push of move picks the nearest revealed rest point in that
## direction and glides the view there, while the cursor swells and
## shrinks back. Travel is possible when the cursor is on a rest point
## other than the one the player kneels at.
##
## A child of the `MapView`, which passes it the move input every frame
## and asks it to draw the cursor.

const CURSOR_COLOR := Color(0.95, 0.8, 0.35)
const CURSOR_OFF_COLOR := Color(0.55, 0.5, 0.4)

## Half-angles (degrees) searched in turn around the pushed direction.
## The nearest rest point in the narrowest cone that has one wins.
@export var cones: Array[float] = [30.0, 40.0, 60.0]
## Stick push (0 to 1) needed to move.
@export var dead_zone := 0.2
## Glide speed of the view (screen px/s).
@export var speed := 400.0
## Side of the cursor square (px) at rest. It doubles mid-glide.
@export var cursor_size := 8.0

## Revealed map cells with a rest point.
var targets: Array[Vector2i] = []
var moving := false

var _view: MapView
var _player_cell: Vector2i
var _pulse := 1.0


func setup(view: MapView, map: WorldMap, player_cell: Vector2i) -> void:
	_view = view
	_player_cell = player_cell
	view.center = Vector2(player_cell) + Vector2(0.5, 0.5)
	for cell in map.revealed:
		var map_room := map.room_at(cell)
		if map_room and MapRoom.Mark.REST_POINT in map_room.marks.get(cell, []):
			targets.append(cell)


## The cell under the cursor.
func cell() -> Vector2i:
	return Vector2i(_view.center.floor())


## True when the cursor rests on a rest point the player can travel to.
func can_travel() -> bool:
	return not moving and cell() != _player_cell and cell() in targets


## Starts a glide when `input` (a move vector) is pushed far enough.
## Input is ignored while a glide runs.
func handle_move(input: Vector2) -> void:
	if moving or input.length() < dead_zone:
		return
	var target := _nearest(input.normalized())
	if target != cell():
		_glide(target)


## The square cursor in the middle of the view: bright where travel is
## possible, dim elsewhere.
func draw_cursor(canvas: CanvasItem, mid: Vector2) -> void:
	var side := roundf(cursor_size * _pulse)
	var rect := Rect2((mid - Vector2(side, side) * 0.5).floor(), Vector2(side, side))
	var color := CURSOR_COLOR if can_travel() or moving else CURSOR_OFF_COLOR
	canvas.draw_rect(rect, color, false, 1.0)


## The nearest target within the narrowest cone around `direction`, or
## the current cell when there is none.
func _nearest(direction: Vector2) -> Vector2i:
	var here := cell()
	for cone in cones:
		var best := here
		var best_distance := INF
		for target in targets:
			var offset := Vector2(target - here)
			if target == here or rad_to_deg(absf(direction.angle_to(offset))) > cone:
				continue
			if offset.length_squared() < best_distance:
				best_distance = offset.length_squared()
				best = target
		if best != here:
			return best
	return here


func _glide(target: Vector2i) -> void:
	moving = true
	var to := Vector2(target) + Vector2(0.5, 0.5)
	var time := maxf(((to - _view.center) * _view.cell_pixels()).length() / speed, 0.01)
	var glide := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	glide.tween_property(_view, ^"center", to, time)
	glide.finished.connect(func() -> void: moving = false)
	var pulse := create_tween()
	pulse.tween_property(self, ^"_pulse", 2.0, time * 0.5)
	pulse.tween_property(self, ^"_pulse", 1.0, time * 0.5)
