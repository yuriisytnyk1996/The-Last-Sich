class_name ElevatorCall
extends InteractionArea
## A lever next to an elevator stop. Press interact at it and the elevator
## comes to the stop nearest the lever. Place it in the same part as the
## elevator (`Layout`) and set `elevator`.

@export var elevator: Elevator


func _activate(_player: Node2D) -> void:
	if elevator:
		elevator.call_to(global_position)
