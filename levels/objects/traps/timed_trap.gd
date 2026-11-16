class_name TimedTrap
extends Node2D
## A hazard that strikes on a fixed cycle: spikes that shoot out of the
## floor, a fire jet. It warns before each strike.
##
## Each cycle: off for `off_time`, then the `Warning` child shows for
## `warn_time`, then the `Hitbox` child is active for `on_time`. The
## hitbox is continuous, so standing in it keeps hurting. `offset` shifts
## the cycle, so a row of traps can strike in a wave. Rotate the node to
## point it another way (a fire jet from a wall or the ceiling).

enum Phase { OFF, WARN, ON }

@export var off_time := 1.4
@export var warn_time := 0.5
@export var on_time := 0.8
## Seconds the cycle is shifted by.
@export var offset := 0.0

var _time := 0.0

@onready var hitbox: Hitbox = $Hitbox
@onready var warning: CanvasItem = $Warning


func _ready() -> void:
	_time = fposmod(offset, _cycle_time())
	warning.visible = false


func _physics_process(delta: float) -> void:
	_time = fmod(_time + delta, _cycle_time())
	var phase := _phase()
	warning.visible = phase == Phase.WARN
	var on := phase == Phase.ON
	if on != hitbox.is_active():
		hitbox.set_active(on)


func _cycle_time() -> float:
	return maxf(off_time + warn_time + on_time, 0.01)


func _phase() -> Phase:
	if _time < off_time:
		return Phase.OFF
	if _time < off_time + warn_time:
		return Phase.WARN
	return Phase.ON
