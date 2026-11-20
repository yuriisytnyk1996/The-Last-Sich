extends PlayerState
## Guard up, planted on the ground. Tuning lives in `PlayerParry`.
##
## GUARD: the hurtbox is parrying for `parry_window()`. A parryable hit
## switches to SUCCESS: the player turns to face the hit (against its
## push), is invincible and can press attack for a Riposte within
## `riposte_window()`. A guard that
## caught nothing ends in FAILED, stuck in place for `fail_recovery`.
## A heavy hit that isn't parryable (`Hitbox.can_guard_slide()`) is taken
## as a GuardSlide instead. Other unparryable hits (contact, hazards)
## still land and interrupt it.

enum Phase { GUARD, SUCCESS, FAILED }

## Placeholder shown while the guard is up, flashed on a parry.
@export var guard: CanvasItem

var _phase := Phase.GUARD
var _time_left := 0.0
var _flash: Tween


func _ready() -> void:
	await owner.ready
	player.hurtbox.parried.connect(_on_parried)
	player.hurtbox.guard_slid.connect(_on_guard_slid)


func enter(_previous_state: StringName) -> void:
	_phase = Phase.GUARD
	_time_left = player.parry.parry_window()
	player.hurtbox.parrying = true
	guard.visible = true
	guard.modulate = Color.WHITE


func exit() -> void:
	player.hurtbox.parrying = false
	guard.visible = false
	if _flash:
		_flash.kill()
	if _phase == Phase.SUCCESS:
		# A Riposte entered next holds invincibility on its own.
		player.hurtbox.set_invincible_for(player.parry.grace_time)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALL)
		return
	if _phase == Phase.SUCCESS and player.wants_attack():
		finished.emit(RIPOSTE)
		return

	_time_left -= delta
	if _time_left > 0.0:
		return
	if _phase == Phase.GUARD:
		player.hurtbox.parrying = false
		guard.visible = false
		_phase = Phase.FAILED
		_time_left = player.parry.fail_recovery
	else:
		finished.emit(ground_state())


func _on_parried(hitbox: Hitbox) -> void:
	if _phase != Phase.GUARD:
		return
	_phase = Phase.SUCCESS
	_time_left = player.parry.riposte_window()
	player.hurtbox.parrying = false
	player.hurtbox.set_invincible_for(INF)
	player.consume_attack()
	# Face against the push, not towards the hitbox centre: an attacker
	# pressed up close swings a hitbox that reaches past the player, and
	# its centre would turn them away from the attacker.
	var direction := hitbox.push_direction(player.global_position)
	if direction != 0.0:
		player.set_facing(-direction)
	player.parry.play_feedback()
	_flash_guard()


## A heavy hit caught on the guard: slide back instead of parrying.
func _on_guard_slid(hitbox: Hitbox) -> void:
	if _phase != Phase.GUARD:
		return
	player.guard_slide.start(hitbox)
	finished.emit(GUARD_SLIDE)


func _flash_guard() -> void:
	guard.modulate = Color(3.0, 3.0, 3.0)
	_flash = create_tween()
	_flash.tween_property(guard, ^"modulate", Color.WHITE, player.parry.riposte_window())
