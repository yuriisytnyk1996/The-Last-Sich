extends Node
## Freezes the game for a moment so hits feel heavy (autoload "HitStop").
##
## Sets Engine.time_scale to 0 and restores it once `duration` real
## seconds have passed. Overlapping freezes don't stack: the one that ends
## last wins. A freeze ends at `normal_scale`, which the debug console's
## `timescale` command changes. Real time is checked every frame because
## timers driven by the frozen clock would never fire.

## The game speed outside a freeze.
var normal_scale := 1.0:
	set(value):
		normal_scale = maxf(value, 0.0)
		if not is_processing():
			Engine.time_scale = normal_scale

var _until_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func freeze(duration: float) -> void:
	if duration <= 0.0:
		return
	_until_msec = maxi(_until_msec, Time.get_ticks_msec() + int(duration * 1000.0))
	Engine.time_scale = 0.0
	set_process(true)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() < _until_msec:
		return
	Engine.time_scale = normal_scale
	set_process(false)
