class_name PlayerParry
extends Node
## Parry and riposte: when to parry, the timing windows and the feedback.
##
## The Parry state raises the guard for `parry_window()`. A `parryable`
## enemy swing that reaches the hurtbox in that window is deflected: no
## damage, the attacker is stunned, and the player gets `riposte_window()`
## to press attack for a Riposte. Both windows are the player's stats
## (`PlayerStats.PARRY_WINDOW`, `RIPOSTE_WINDOW`). A guard that catches nothing leaves the
## player open for `fail_recovery`.

@export_group("Timing")
## Seconds stuck in place after a guard that caught nothing (s).
@export var fail_recovery := 0.35
## Invincibility after a parry or riposte ends (s).
@export var grace_time := 0.3

@export_group("Feedback")
## Freeze on a successful parry (s).
@export var hit_stop := 0.12
## Camera trauma on a successful parry (0 to 1).
@export var shake := 0.35
## Gamepad rumble on a successful parry (0 to 1).
@export var rumble := 0.6
@export var rumble_time := 0.15

@onready var player := owner as Player


## Parry was just pressed on the ground. A jump pressed in the same frame wins.
func wants() -> bool:
	return (
		Input.is_action_just_pressed("parry")
		and not Input.is_action_just_pressed("jump")
		and player.is_on_floor()
	)


## Seconds the guard is up after the press.
func parry_window() -> float:
	return player.stats.get_value(PlayerStats.PARRY_WINDOW)


## After a parry, seconds to press attack for a riposte.
func riposte_window() -> float:
	return player.stats.get_value(PlayerStats.RIPOSTE_WINDOW)


## Freeze, shake and rumble for a successful parry.
func play_feedback() -> void:
	HitStop.freeze(hit_stop)
	Events.camera_shake_requested.emit(shake)
	Rumble.play(rumble, rumble_time)
