class_name HiddenArea
extends Area2D
## A secret passage behind a false wall. Its `Cover` child is art drawn
## like the terrain, above the player, hiding what is behind it. When the
## player walks in, the cover fades out for good.
##
## The terrain behind the cover is open: the cover only hides it. Give
## the area the same shape as the cover, mask only `player`, and put it in
## the room's `Logic`. Saved (`persistent` group), so a found secret
## stays open.

## Seconds the cover takes to fade out.
@export var fade_time := 0.6

var found := false

@onready var cover: CanvasItem = $Cover


func _ready() -> void:
	add_to_group(SaveManager.PERSISTENT_GROUP)
	body_entered.connect(_on_body_entered)


func get_save_data() -> Dictionary:
	return {"found": found}


func apply_save_data(data: Dictionary) -> void:
	if data.get("found", false):
		_reveal(0.0)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not found:
		_reveal(fade_time)


func _reveal(time: float) -> void:
	found = true
	# Deferred: monitoring can't change during a physics callback.
	set_deferred(&"monitoring", false)
	if time <= 0.0:
		cover.modulate.a = 0.0
	else:
		create_tween().tween_property(cover, ^"modulate:a", 0.0, time)
