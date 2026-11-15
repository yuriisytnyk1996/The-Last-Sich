class_name RestPoint
extends InteractionArea
## A checkpoint. Pressing up here heals the player to full, resets the
## enemies in the room and makes this the place the player comes back to
## after dying, even from another room.
##
## The world remembers the last rest point used (`Events.rested`) and
## lights it whenever its room is loaded.

@onready var flame: CanvasItem = $Visual/Flame


func _ready() -> void:
	super()
	set_lit(false)
	Events.rested.connect(_on_rested)


func set_lit(lit: bool) -> void:
	flame.visible = lit


func _activate(player: Node2D) -> void:
	var resting := player as Player
	resting.health.reset()
	resting.velocity.x = 0.0
	get_tree().call_group(&"enemies", &"reset")
	Events.rested.emit(self)


func _on_rested(rest_point: Node2D) -> void:
	set_lit(rest_point == self)
