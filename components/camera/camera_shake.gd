class_name CameraShake
extends Node
## Shakes its parent Camera2D when `Events.camera_shake_requested` fires.
##
## Each request adds "trauma" (0 to 1) that drains over time. The offset
## grows with trauma squared, so small hits barely move the camera and
## big hits shake hard. The offset is rounded to whole pixels.
## Requests are ignored while screen shake is off in the accessibility
## options.

## Offset at full trauma (px).
@export var max_offset := Vector2(8.0, 5.0)
## Trauma lost per second.
@export var decay := 2.5

var _trauma := 0.0

@onready var camera := get_parent() as Camera2D


func _ready() -> void:
	Events.camera_shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	if not AccessibilitySettings.screen_shake:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var power := _trauma * _trauma
	var shake := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	camera.offset = (shake * max_offset * power).round()
