class_name ItemToast
extends Label
## Names a newly obtained item for a moment ("Found: Wolf fang"), then
## fades out. Driven by `Events.item_obtained`.

## Seconds the name stays fully visible.
@export var show_time := 2.0
## Seconds it takes to fade out after that.
@export var fade_time := 0.5

var _tween: Tween


func _ready() -> void:
	Events.item_obtained.connect(_on_item_obtained)
	modulate.a = 0.0


func _on_item_obtained(item: Item) -> void:
	text = "Found: %s" % item.title
	modulate.a = 1.0
	if _tween:
		_tween.kill()
	# Keeps running while a shop menu pauses the game.
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_interval(show_time)
	_tween.tween_property(self, ^"modulate:a", 0.0, fade_time)
