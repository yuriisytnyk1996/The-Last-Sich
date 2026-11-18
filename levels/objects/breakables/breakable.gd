class_name Breakable
extends Node2D
## A prop the player breaks with attacks: a crate, a cracked wall, a secret
## wall drawn like the terrain. It breaks after `hits` hits and may drop
## currency.
##
## Children: `Hurtbox` (masks `player_attacks`, `rewards_attacker` off so
## it fills no spirit), `Visual`, and an optional `Body` (`StaticBody2D`
## on the `world` layer) that blocks the way until it breaks.
##
## `breakable_from` can limit hits to one side: from the other side the
## hurtbox is off, so hits pass through without a flash. A secret wall
## faces the way the player comes from, not the secret behind it.
##
## With `stays_broken` it is saved (a room object in the `persistent`
## group): hits taken so far, and broken for good once broken. Otherwise
## it is back whenever the room loads again.

## Broken by the player's hits (never when a save restores it), so a
## `StoryTrigger` can count it.
signal broken_by_player

## Which side the player has to stand on for hits to count.
enum Side { BOTH, LEFT, RIGHT }

@export var hits := 1
## Currency given when it breaks, scaled like an enemy's reward.
@export var currency := 0
@export var stays_broken := false
@export var breakable_from := Side.BOTH
## Seconds `Visual` takes to fade out when it breaks. 0 hides it at once.
@export var fade_time := 0.0
## A secret: until it breaks, the world map leaves out the cells, doors
## and marks inside this area (px, from the breakable's origin), the way
## a hidden passage stays off the map until found. Empty: not a secret.
@export var map_hides := Rect2()
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
	set_physics_process(breakable_from != Side.BOTH)


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var left := player != null and player.global_position.x < global_position.x
	hurtbox.monitoring = player != null and left == (breakable_from == Side.LEFT)


## True while this secret still hides `point` (global px) from the map.
func hides_on_map(point: Vector2) -> bool:
	return not broken and map_hides.has_area() and map_hides.has_point(to_local(point))


func get_save_data() -> Dictionary:
	return {"broken": broken, "hits_left": _hits_left}


func apply_save_data(data: Dictionary) -> void:
	_hits_left = clampi(int(data.get("hits_left", hits)), 1, hits)
	if data.get("broken", false):
		_break(true)


func _on_hurt(_hitbox: Hitbox) -> void:
	_hits_left -= 1
	if _hits_left > 0:
		return
	_break(false)
	broken_by_player.emit()
	if currency > 0:
		Events.currency_earned.emit(currency)
	Events.camera_shake_requested.emit(break_shake)


func _break(instant: bool) -> void:
	broken = true
	set_physics_process(false)
	if instant or fade_time <= 0.0:
		visual.visible = false
	else:
		create_tween().tween_property(visual, ^"modulate:a", 0.0, fade_time)
	# Deferred: collision can't change during a physics callback.
	hurtbox.set_deferred(&"monitoring", false)
	if body:
		for child in body.get_children():
			if child is CollisionShape2D:
				child.set_deferred(&"disabled", true)
