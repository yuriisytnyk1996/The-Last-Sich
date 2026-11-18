class_name PlayerBlast
extends Hitbox
## A short burst that hits everything inside it once, then ends: the
## returning bolt's burst, the dive's shockwave and duma blasts. A room
## change ends it at once. Taken from and parked back in the `Pool`.

## Seconds the blast stays on.
@export var duration := 0.15
## Camera shake when it goes off (0 for none).
@export var shake := 0.0

var _time_left := 0.0


## Adds a blast from `scene` under `parent` at `at` (global) and sets it
## off. `stats` scale its damage, see `Hitbox.attacker_stats`.
static func spawn(scene: PackedScene, parent: Node, at: Vector2, stats: Stats) -> PlayerBlast:
	var blast := Pool.take(scene) as PlayerBlast
	blast.attacker_stats = stats
	parent.add_child(blast)
	blast.global_position = at
	blast.reset_physics_interpolation()
	blast._go_off()
	return blast


func _ready() -> void:
	super()
	Events.room_change_requested.connect(_on_room_change_requested)


func _go_off() -> void:
	set_active(true)
	_time_left = duration
	if shake > 0.0:
		Events.camera_shake_requested.emit(shake)


func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		Pool.release(self)


func _on_room_change_requested(_room_path: String, _exit_name: StringName) -> void:
	Pool.release(self)
