class_name PlayerBlast
extends Hitbox
## A short burst that hits everything inside it once, then frees itself:
## the returning bolt's burst and the dive's shockwave.

## Seconds the blast stays on.
@export var duration := 0.15
## Camera shake when it goes off (0 for none).
@export var shake := 0.0

var _time_left := 0.0


## Adds a blast from `scene` under `parent` at `at` (global) and sets it off.
static func spawn(scene: PackedScene, parent: Node, at: Vector2) -> PlayerBlast:
	var blast := scene.instantiate() as PlayerBlast
	parent.add_child(blast)
	blast.global_position = at
	blast.reset_physics_interpolation()
	return blast


func _ready() -> void:
	super()
	set_active(true)
	_time_left = duration
	if shake > 0.0:
		Events.camera_shake_requested.emit(shake)


func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
