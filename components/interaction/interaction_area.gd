class_name InteractionArea
extends Area2D
## An area the player sets off, either by touching it or by pressing up
## while standing inside it (doors, rest points).
##
## Put it on no layer and mask only `player`. A child named `Prompt`, if
## present, is shown while the player stands in a press-up area.
## Subclasses override `_activate()`.

## Off: touching the area sets it off. On: the player has to stand inside
## and press up (see `Player.can_interact()`).
@export var press_up := false

var _body: Node2D

@onready var prompt: CanvasItem = get_node_or_null(^"Prompt")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_show_prompt(false)


func _physics_process(_delta: float) -> void:
	if press_up and _body and _body.call(&"can_interact"):
		_activate(_body)


## What happens when the player sets the area off.
func _activate(_player: Node2D) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method(&"can_interact"):
		return
	if press_up:
		_body = body
		_show_prompt(true)
	else:
		_activate(body)


func _on_body_exited(body: Node2D) -> void:
	if body == _body:
		_body = null
		_show_prompt(false)


func _show_prompt(shown: bool) -> void:
	if prompt:
		prompt.visible = shown
