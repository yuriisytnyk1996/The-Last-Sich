class_name PlatformSequence
extends Node2D
## Shows its `TimedPlatform` children one step after another on a loop.
##
## Every `step_time` the next step comes up and its platforms show for
## `show_time`; the last `warn_time` of that they blink, then they fade
## out. With `show_time` longer than `step_time` the next step is already
## there when one vanishes, so the player hops along the steps in order.
## After the last step the loop starts again from step 0. `offset` shifts
## the loop, like a timed trap's. Driven by one clock, so the steps never
## drift apart. Not saved.

## Seconds between one step and the next.
@export var step_time := 0.8
## Seconds each step stays, warning included.
@export var show_time := 1.6
## Seconds a step blinks before it vanishes.
@export var warn_time := 0.4
## Seconds a platform takes to fade in or out.
@export var fade_time := 0.15
## Seconds the loop is shifted by.
@export var offset := 0.0

var _platforms: Array[TimedPlatform] = []
var _steps := 1
var _time := 0.0


func _ready() -> void:
	for child in get_children():
		if child is TimedPlatform:
			_platforms.append(child)
			_steps = maxi(_steps, child.step + 1)
	_time = fposmod(offset, _cycle_time())
	_update(0.0)


func _physics_process(delta: float) -> void:
	_time = fmod(_time + delta, _cycle_time())
	_update(fade_time)


func _update(fade: float) -> void:
	var cycle := _cycle_time()
	for platform in _platforms:
		var since := fposmod(_time - platform.step * step_time, cycle)
		var on := since < show_time
		var warning := on and since >= show_time - warn_time
		platform.set_state(on, warning, fade)


func _cycle_time() -> float:
	return maxf(_steps * step_time, 0.01)
