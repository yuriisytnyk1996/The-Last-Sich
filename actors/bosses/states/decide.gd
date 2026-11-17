extends BossState
## Between attacks: faces the player and walks towards them, then picks the
## next attack. Waits at least `think_time` (scaled by phase) so attacks
## don't run into each other, and only picks on the floor, off cooldown.
## Goes to `Roar` first when a new phase is waiting.

## Seconds before it can pick an attack.
@export var think_time := 0.4
## It stops walking this close to the player (px).
@export var keep_distance := 40.0

var _wait := 0.0
var _attacks: Array[BossAttack] = []


func _ready() -> void:
	for child in get_parent().get_children():
		if child is BossAttack:
			_attacks.append(child)


func enter(_previous_state: StringName) -> void:
	_wait = think_time * boss.time_scale()


func physics_update(delta: float) -> void:
	if boss.has_pending_phase():
		finished.emit(ROAR)
		return
	boss.apply_gravity(delta)
	boss.face_target()
	if boss.distance_to_target() > keep_distance and not boss.is_path_blocked():
		boss.walk(delta, boss.chase_speed)
	else:
		boss.stop(delta)
	boss.move_and_slide()

	_wait -= delta
	if _wait > 0.0 or not boss.is_on_floor() or not boss.can_attack():
		return
	var attack := _pick()
	if attack:
		finished.emit(attack.name)


## A random usable attack, weighted. Null when none fits right now.
func _pick() -> BossAttack:
	var usable: Array[BossAttack] = []
	var total := 0.0
	for attack in _attacks:
		if attack.can_use():
			usable.append(attack)
			total += attack.weight
	var roll := randf() * total
	for attack in usable:
		roll -= attack.weight
		if roll <= 0.0:
			return attack
	return null
