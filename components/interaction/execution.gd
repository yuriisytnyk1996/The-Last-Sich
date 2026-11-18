class_name Execution
extends InteractionArea
## A finisher waiting for the player: press interact in it, standing on the
## same floor, and the player plays an invincible finishing blow.
##
## An enemy brought to its knees spawns one over itself (the enemy's
## Executable state) and dies on `executed`. A fake execution is the same
## scene placed in a room with its own `Body`: no enemy behind it, for
## scripted finishers. It sets `persistent`, so once done it stays done.
##
## When it appears, the `Awareness` mark flashes so the player notices the
## chance. The `Prompt` shows while the player can use it.

## The finishing blow landed. The enemy behind it dies here.
signal executed

## Seconds after it appears before the awareness mark flashes.
@export var awareness_delay := 0.2
## Seconds the awareness mark takes to pop in and fade out.
@export var awareness_time := 0.6
## The player's feet must be within this height of its own (px).
@export var max_height_difference := 6.0
## Saved and gone for good once used. For fake executions placed in rooms.
@export var persistent := false
## Shown the first time a finisher appears (see `TipLog`).
@export var tip: Tip
## Seconds after it appears before the tip shows.
@export var tip_delay := 0.6

var _in_use := false
var _done := false

@onready var awareness: CanvasItem = get_node_or_null(^"Awareness")
@onready var body: CanvasItem = get_node_or_null(^"Body")


func _ready() -> void:
	super()
	if persistent:
		add_to_group(SaveManager.PERSISTENT_GROUP)
	_flash_awareness()
	if tip:
		get_tree().create_timer(tip_delay, false).timeout.connect(_request_tip)


## The player is playing the finisher: an enemy behind it waits for it.
func is_in_use() -> bool:
	return _in_use


## Called by the player's finisher at the moment of the blow.
func strike() -> void:
	_in_use = false
	_finish()
	executed.emit()


## The finisher stopped before the blow (a respawn): usable again.
func release() -> void:
	if not _in_use:
		return
	_in_use = false
	unblock()


func get_save_data() -> Dictionary:
	return {"done": _done}


func apply_save_data(data: Dictionary) -> void:
	if data.get("done", false):
		_finish()


func _activate(player: Node2D) -> void:
	if _done or absf(player.global_position.y - global_position.y) > max_height_difference:
		return
	_in_use = true
	block()
	player.call(&"start_execution", self)


func _request_tip() -> void:
	if not _done:
		Events.tip_requested.emit(tip)


func _finish() -> void:
	_done = true
	block()
	if body:
		body.hide()
	if awareness:
		awareness.hide()


func _flash_awareness() -> void:
	if awareness == null:
		return
	awareness.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(awareness_delay)
	tween.tween_property(awareness, ^"modulate:a", 1.0, awareness_time * 0.25)
	tween.parallel().tween_property(awareness, ^"scale", Vector2.ONE, awareness_time * 0.25).from(
		Vector2.ONE * 2.0
	)
	tween.tween_property(awareness, ^"modulate:a", 0.0, awareness_time * 0.75)
