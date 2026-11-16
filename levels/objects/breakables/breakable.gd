class_name Breakable
extends Node2D
## A prop the player breaks with attacks: a crate, a jar, a cracked wall
## hiding a passage. It breaks after `hits` hits and may drop currency.
##
## Children: `Hurtbox` (masks `player_attacks`, `rewards_attacker` off so
## it fills no spirit), `Visual`, and an optional `Body` (`StaticBody2D`
## on the `world` layer) that blocks the way until it breaks.
##
## With `stays_broken` it is saved (a room object in the `persistent`
## group) and stays broken for good. Otherwise it is back whenever the
## room loads again.

@export var hits := 1
## Currency given when it breaks, scaled like an enemy's reward.
@export var currency := 0
@export var stays_broken := false
## Camera trauma when it breaks (0 to 1).
@export var break_shake := 0.15

var broken := false
var _hits_left := 0

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: CanvasItem = $Visual
@onready var body: StaticBody2D = get_node_or_null(^"Body")


func _ready() -> void:
	_hits_left = hits
	hurtbox.hurt.connect(_on_hurt)
	if stays_broken:
		add_to_group(SaveManager.PERSISTENT_GROUP)


func get_save_data() -> Dictionary:
	return {"broken": broken}


func apply_save_data(data: Dictionary) -> void:
	if data.get("broken", false):
		_break()


func _on_hurt(_hitbox: Hitbox) -> void:
	_hits_left -= 1
	if _hits_left > 0:
		return
	_break()
	if currency > 0:
		Events.currency_earned.emit(currency)
	Events.camera_shake_requested.emit(break_shake)


func _break() -> void:
	broken = true
	visual.visible = false
	# Deferred: collision can't change during a physics callback.
	hurtbox.set_deferred(&"monitoring", false)
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.set_deferred(&"disabled", true)
