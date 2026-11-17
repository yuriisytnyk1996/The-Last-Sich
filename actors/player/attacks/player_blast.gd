class_name PlayerBlast
extends Hitbox
## A short burst that hits everything inside it once, then frees itself:
## the returning bolt's burst, the dive's shockwave and duma blasts. A
## room change frees it at once.

## Seconds the blast stays on.
@export var duration := 0.15
## Camera shake when it goes off (0 for none).
@export var shake := 0.0

var _time_left := 0.0


## Adds a blast from `scene` under `parent` at `at` (global) and sets it
## off. `stats` scale its damage, see `Hitbox.attacker_stats`.
static func spawn(scene: PackedScene, parent: Node, at: Vector2, stats: Stats) -> PlayerBlast:
	var blast := scene.instantiate() as PlayerBlast
	blast.attacker_stats = stats
	parent.add_child(blast)
	blast.global_position = at
	blast.reset_physics_interpolation()
	return blast


func _ready() -> void:
	super()
	set_active(true)
	_time_left = duration
	Events.room_change_requested.connect(func(_p: String, _e: StringName) -> void: queue_free())
	if shake > 0.0:
		Events.camera_shake_requested.emit(shake)


func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
