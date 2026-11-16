class_name InteractionArea
extends Area2D
## An area the player sets off, either by touching it or by pressing
## interact while standing inside it (doors, rest points).
##
## Put it on no layer and mask only `player`. A child named `Prompt`, if
## present, is shown while the player stands in an interact area.
## Subclasses override `_activate()`.
##
## Another area on the same spot can `block()` this one so it goes first
## (a death mark on a door): while blocked, the prompt is hidden and
## interact is ignored. The press that removes the blocker never reaches
## this area too.

const GROUP := &"interaction_areas"

## Off: touching the area sets it off. On: the player has to stand inside
## and press interact (see `Player.can_interact()`).
@export var press_interact := false

var _body: Node2D
var _blockers := 0
## Physics frame of the last `unblock()`: the press that freed this area
## doesn't count for it.
var _unblocked_frame := -1

@onready var prompt: CanvasItem = get_node_or_null(^"Prompt")


func _ready() -> void:
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_show_prompt(false)


func _physics_process(_delta: float) -> void:
	if not press_interact or _body == null or is_blocked():
		return
	if Engine.get_physics_frames() != _unblocked_frame and _body.call(&"can_interact"):
		_activate(_body)


func block() -> void:
	_blockers += 1
	_show_prompt(false)


func unblock() -> void:
	_blockers = maxi(_blockers - 1, 0)
	_unblocked_frame = Engine.get_physics_frames()
	_show_prompt(_body != null and not is_blocked())


func is_blocked() -> bool:
	return _blockers > 0


## The area's first rectangle shape, in global coordinates.
func get_bounds() -> Rect2:
	for child in get_children():
		var shape := child as CollisionShape2D
		if shape and shape.shape:
			var rect := shape.shape.get_rect()
			return Rect2(shape.to_global(rect.position), rect.size * shape.global_scale.abs())
	return Rect2(global_position, Vector2.ZERO)


## What happens when the player sets the area off.
func _activate(_player: Node2D) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"can_interact"):
		return
	if press_interact:
		_body = body
		_show_prompt(not is_blocked())
	else:
		_activate(body)


func _on_body_exited(body: Node2D) -> void:
	if body == _body:
		_body = null
		_show_prompt(false)


func _show_prompt(shown: bool) -> void:
	if prompt:
		prompt.visible = shown
