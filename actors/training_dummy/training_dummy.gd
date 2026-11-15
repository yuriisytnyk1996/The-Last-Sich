class_name TrainingDummy
extends Node2D
## A stationary target for testing attacks.
##
## Tilts away from each hit (the flash, hit-stop and shake come from its
## HurtFeedback node), breaks at zero health and rebuilds
## itself after `respawn_delay`. It has no behaviour of its own, so it has
## no state machine.

@export var respawn_delay := 1.5
@export var hit_tilt_degrees := 14.0

var _tween: Tween
var _bar_width := 0.0

@onready var visual: Node2D = $Visual
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var health_bar: Node2D = $HealthBar
@onready var health_fill: ColorRect = $HealthBar/Fill


func _ready() -> void:
	_bar_width = health_fill.size.x
	hurtbox.hurt.connect(_on_hurt)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	_on_health_changed(health.current, health.max_health)


func _on_hurt(hitbox: Hitbox) -> void:
	var direction := signf(hitbox.get_knockback().x)
	if _tween:
		_tween.kill()
	visual.rotation_degrees = direction * hit_tilt_degrees
	_tween = create_tween()
	(
		_tween
		. tween_property(visual, "rotation_degrees", 0.0, 0.4)
		. set_trans(Tween.TRANS_ELASTIC)
		. set_ease(Tween.EASE_OUT)
	)


func _on_health_changed(current: int, maximum: int) -> void:
	health_fill.size.x = _bar_width * current / maxi(maximum, 1)


func _on_died() -> void:
	_set_broken(true)
	await get_tree().create_timer(respawn_delay).timeout
	health.reset()
	_set_broken(false)


func _set_broken(broken: bool) -> void:
	visual.visible = not broken
	health_bar.visible = not broken
	# Deferred: this can run inside a physics callback.
	hurtbox.set_deferred(&"monitoring", not broken)
