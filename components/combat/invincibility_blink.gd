class_name InvincibilityBlink
extends Node
## Blinks a visual while a Hurtbox is invincible.
##
## Drop it next to a Hurtbox and point it at the node to blink. Works for
## any actor that has invincibility frames.

@export var hurtbox: Hurtbox
@export var target: CanvasItem
## Seconds per on/off step.
@export var interval := 0.06

var _time := 0.0


func _process(delta: float) -> void:
	if hurtbox == null or target == null:
		return
	if not hurtbox.is_invincible():
		_time = 0.0
		target.visible = true
		return
	_time += delta
	target.visible = int(_time / interval) % 2 == 0
