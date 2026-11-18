class_name CutsceneTrigger
extends InteractionArea
## Starts its parent `Cutscene` when the player walks in or, with
## `press_interact` on, presses interact standing in it (an idol, a
## grave). Its `Prompt` shows only while the cutscene can still play, so
## it hides while any cutscene runs and for good once this one's flag is set.
## Put it on no layer and mask only `player`, like any interaction area.

@onready var cutscene := get_parent() as Cutscene


func _ready() -> void:
	super()
	Events.cutscene_started.connect(_refresh_prompt.unbind(1))
	Events.cutscene_ended.connect(_refresh_prompt)
	Events.story_changed.connect(_refresh_prompt.unbind(1))


func _activate(_player: Node2D) -> void:
	cutscene.play()


func _show_prompt(shown: bool) -> void:
	super(shown and cutscene.can_play())


func _refresh_prompt() -> void:
	_show_prompt(_body != null and not is_blocked())
