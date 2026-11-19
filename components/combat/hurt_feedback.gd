class_name HurtFeedback
extends Node
## Makes a hit felt: flashes a visual, freezes the game, shakes the
## camera and rumbles the gamepad whenever a Hurtbox accepts a hit.
##
## Values are per receiver, so each actor decides how much a hit on it
## should shake things. Light hits scale them down, heavy hits up
## (see `Hitbox.feedback_scale()`).

@export var hurtbox: Hurtbox
## Node that flashes. Colours above 1 overbrighten thanks to 2D HDR.
@export var flash_target: CanvasItem
@export var flash_color := Color(3.0, 3.0, 3.0)
## Flash colour of a critical hit.
@export var crit_flash_color := Color(3.0, 2.2, 0.6)
@export var flash_time := 0.12
## Freeze length (s). 0 turns it off.
@export var hit_stop := 0.0
## Camera trauma added (0 to 1). 0 turns it off.
@export var shake := 0.0
## Gamepad rumble strength (0 to 1). 0 turns it off.
@export var rumble := 0.0
## Rumble length (s) for a normal hit.
@export var rumble_time := 0.15
@export_group("Sounds")
## Cues played at the hurtbox (`Audio.play_at()`). Empty: silent.
@export var hurt_sound := &"hit"
## Played on top of `hurt_sound` for a critical hit.
@export var crit_sound := &"hit_critical"
## Only a parrying or guarding hurtbox ever plays these.
@export var parry_sound := &"parry"
@export var block_sound := &"block"
@export var guard_slide_sound := &"guard_slide"

var _tween: Tween


func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)
	hurtbox.parried.connect(_sound.bind(parry_sound).unbind(1))
	hurtbox.blocked.connect(_sound.bind(block_sound).unbind(1))
	hurtbox.guard_slid.connect(_sound.bind(guard_slide_sound).unbind(1))


func _on_hurt(hitbox: Hitbox) -> void:
	var scale := hitbox.feedback_scale()
	_sound(hurt_sound)
	if hitbox.critical:
		_sound(crit_sound)
	_flash(crit_flash_color if hitbox.critical else flash_color)
	HitStop.freeze(hit_stop * scale)
	if shake > 0.0:
		Events.camera_shake_requested.emit(shake * scale)
	Rumble.play(rumble * scale, rumble_time * scale)


func _flash(color: Color) -> void:
	if flash_target == null:
		return
	if _tween:
		_tween.kill()
	flash_target.modulate = color
	_tween = create_tween()
	_tween.tween_property(flash_target, "modulate", Color.WHITE, flash_time)


func _sound(cue: StringName) -> void:
	Audio.play_at(cue, hurtbox.global_position)
