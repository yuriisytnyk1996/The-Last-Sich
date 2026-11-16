class_name PlayerAreaEffects
extends Node
## The zones (`AreaEffect`: wind, mud) the player is standing in, combined
## into the values movement reads: a run speed factor, a jump height
## factor and a wind speed.
##
## Zones add and remove themselves as the player enters and leaves them.
## A zone freed with its room is dropped the next time the values are read.

var _zones: Array[AreaEffect] = []


func enter(zone: AreaEffect) -> void:
	if not _zones.has(zone):
		_zones.append(zone)


func exit(zone: AreaEffect) -> void:
	_zones.erase(zone)


## Multiplies the run speed. 1 outside any zone.
func speed_factor() -> float:
	var factor := 1.0
	for zone in _active():
		factor *= zone.speed_factor()
	return factor


## Multiplies the jump height. 1 outside any zone.
func jump_factor() -> float:
	var factor := 1.0
	for zone in _active():
		factor *= zone.jump_factor()
	return factor


## Sideways speed added to running and drifting (px/s, positive is right).
func wind_speed() -> float:
	var speed := 0.0
	for zone in _active():
		speed += zone.wind_speed()
	return speed


func _active() -> Array[AreaEffect]:
	for i in range(_zones.size() - 1, -1, -1):
		var zone := _zones[i]
		if not is_instance_valid(zone) or not zone.is_inside_tree():
			_zones.remove_at(i)
	return _zones
