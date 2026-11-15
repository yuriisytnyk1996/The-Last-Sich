class_name HurtFeedback
extends Node
## Makes a hit felt: flashes a visual, freezes the game and shakes the
## camera whenever a Hurtbox accepts a hit.
##
## Values are per receiver, so each actor decides how much a hit on it
## should shake things. Light hits scale them down, heavy hits up
## (see `Hitbox.feedback_scale()`).

@export var hurtbox: Hurtbox
## Node that flashes. Colours above 1 overbrighten thanks to 2D HDR.
@export var flash_target: CanvasItem
@export var flash_color := Color(3.0, 3.0, 3.0)
@export var flash_time := 0.12
## Freeze length (s). 0 turns it off.
@export var hit_stop := 0.0
## Camera trauma added (0 to 1). 0 turns it off.
@export var shake := 0.0

var _tween: Tween


func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)


func _on_hurt(hitbox: Hitbox) -> void:
	var scale := hitbox.feedback_scale()
	_flash()
	HitStop.freeze(hit_stop * scale)
	if shake > 0.0:
		Events.camera_shake_requested.emit(shake * scale)


func _flash() -> void:
	if flash_target == null:
		return
	if _tween:
		_tween.kill()
	flash_target.modulate = flash_color
	_tween = create_tween()
	_tween.tween_property(flash_target, "modulate", Color.WHITE, flash_time)
