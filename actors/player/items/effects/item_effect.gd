class_name ItemEffect
extends Resource
## One thing an `Item` does, and when. `PlayerItemEffects` runs it.
##
## Lasting triggers (OWNED, EQUIPPED) start the effect while the item is
## carried or worn and stop it when that ends. Event triggers (ON_HIT,
## ON_KILL, ON_HURT) start it each time the event happens to a worn item;
## with a `duration` it stops again after that many seconds (a new event
## restarts the clock instead of stacking). ON_USE starts it when the
## item is used: a duma being sung (`PlayerItemEffects.use()`), stopped
## after `duration` plus `PlayerStats.DUMA_DURATION`.
##
## Subclasses override `start()` and `stop()`.

## Saved as numbers in `.tres` files, so new triggers go at the end.
enum Trigger { OWNED, EQUIPPED, ON_HIT, ON_KILL, ON_HURT, ON_USE }

@export var trigger := Trigger.EQUIPPED
## Only while health is below this fraction of the maximum. 1 is always.
@export_range(0.0, 1.0) var below_health := 1.0
## Event triggers only: chance that the event sets the effect off.
@export_range(0.0, 1.0) var chance := 1.0
## Event and use triggers only: seconds until `stop()`. 0 never stops
## (for one-shot effects such as healing or a blast).
@export var duration := 0.0


func is_lasting() -> bool:
	return trigger == Trigger.OWNED or trigger == Trigger.EQUIPPED


## Applies the effect. `source` is unique to this item and effect, so stat
## modifiers can be removed by it.
func start(_player: Player, _source: StringName) -> void:
	pass


func stop(_player: Player, _source: StringName) -> void:
	pass
