extends BossState
## Waits for the fight: stands still and can't hurt or be hurt, so the
## player can't wear it down before the arena closes. `Boss.awaken()`
## leaves this state.


func enter(_previous_state: StringName) -> void:
	boss.set_combat_enabled(false)


func exit() -> void:
	boss.set_combat_enabled(true)


func physics_update(delta: float) -> void:
	boss.apply_gravity(delta)
	boss.stop(delta)
	boss.move_and_slide()
