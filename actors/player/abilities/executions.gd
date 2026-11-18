class_name PlayerExecutions
extends Node
## Executions: finishing an enemy brought to its knees.
##
## An `Execution` calls `Player.start_execution()` when interact is pressed
## in it, which lands here: the target is kept and the player enters the
## Execute state. That state steps up to the target, raises the blade for
## `windup`, strikes (`Execution.strike()`, then `reward()`) and recovers.
## The player is invincible throughout and for `PlayerParry.grace_time`
## after. The reward is spirit, lowered by death marks like any spirit gain.
##
## Kill counter: after a random number of kills (`min_kills` to
## `max_kills`), every player hitbox gets `Hitbox.executes`, so the next
## lethal HEAVY hit brings an enemy to its knees. Any execution rolls a
## new count and turns it off again.

@export_group("Finisher")
## Distance from the target the player strikes from (px).
@export var distance := 18.0
## Seconds with the blade raised before the blow.
@export var windup := 0.45
## Seconds after the blow before the player can act again.
@export var recovery := 0.4

@export_group("Kill counter")
## Fewest kills before a lethal heavy hit can bring an enemy down.
@export var min_kills := 3
## Most kills before a lethal heavy hit can bring an enemy down.
@export var max_kills := 6

@export_group("Reward")
## Spirit for every execution, before the death mark penalty.
@export var spirit_reward := 10.0

@export_group("Feedback")
## Freeze on the blow (s).
@export var hit_stop := 0.18
## Camera trauma on the blow (0 to 1).
@export var shake := 0.5
## Gamepad rumble on the blow (0 to 1).
@export var rumble := 0.8
@export var rumble_time := 0.25

var _target: Execution
var _kills_left := 0
var _hitboxes: Array[Hitbox] = []

@onready var player := owner as Player


func _ready() -> void:
	await owner.ready
	_hitboxes.assign(player.find_children("*", "Hitbox"))
	Events.enemy_killed.connect(_on_enemy_killed)
	_roll()


## A lethal heavy hit brings the next enemy down (the kill counter ran out).
func is_ready() -> bool:
	return _kills_left <= 0


func start(execution: Execution) -> void:
	_target = execution
	player.state_machine.transition_to(PlayerState.EXECUTE)


## The execution being played. Read once by the Execute state.
func take_target() -> Execution:
	var target := _target
	_target = null
	return target


## Spirit, freeze, shake and rumble for the blow.
func reward() -> void:
	player.spirit.add(spirit_reward * player.spirit.gain_factor)
	HitStop.freeze(hit_stop)
	Events.camera_shake_requested.emit(shake)
	Rumble.play(rumble, rumble_time)
	Events.enemy_executed.emit()
	_roll()


## A new count of kills before the next one, and the hitboxes back to normal.
func _roll() -> void:
	_kills_left = randi_range(min_kills, maxi(max_kills, min_kills))
	_set_executes(false)


func _on_enemy_killed() -> void:
	_kills_left -= 1
	if is_ready():
		_set_executes(true)


func _set_executes(on: bool) -> void:
	for hitbox in _hitboxes:
		hitbox.executes = on
