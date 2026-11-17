extends BossState
## A pause that can't be hurt: at the start of the fight and at every new
## phase. The boss faces the player, shows `mark` and shakes the camera,
## then picks its first attack. Gives the player a breather to heal.

## Shown while roaring. Optional.
@export var mark: CanvasItem
## Seconds the roar lasts.
@export var duration := 1.0
## Camera trauma when it starts (0 to 1).
@export var shake := 0.5

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	boss.enter_pending_phase()
	boss.face_target()
	boss.hurtbox.set_invincible_for(duration)
	_time_left = duration
	Events.camera_shake_requested.emit(shake)
	if mark:
		mark.visible = true


func exit() -> void:
	if mark:
		mark.visible = false


func physics_update(delta: float) -> void:
	boss.apply_gravity(delta)
	boss.stop(delta)
	boss.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0:
		finished.emit(DECIDE)
