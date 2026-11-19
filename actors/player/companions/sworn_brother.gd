class_name SwornBrother
extends Companion
## A ghostly sworn brother summoned by a duma (`SummonEffect`). He floats
## behind the player's shoulder and fights alongside them.
##
## FOLLOW: eases to `offset` behind the player, bobbing. When the player
## starts a swing (`STRIKE_STATES`) he lunges `strike_distance` past them
## with a HEAVY cut (STRIKE); when they raise the parry guard he steps
## `guard_distance` in front of them and holds up his shield (GUARD),
## warding the player for `guard_time` (`Hurtbox.set_ward()`). Either one
## starts `cooldown`. His cut and his shield destroy enemy shots. Damage
## is scaled by `PlayerDumas.strength()`.

enum Phase { FOLLOW, STRIKE, GUARD }

const WARD := &"sworn_brother"
const STRIKE_STATES: Array[StringName] = [
	PlayerState.SIDE_ATTACK,
	PlayerState.UP_ATTACK,
	PlayerState.CROUCH_ATTACK,
	PlayerState.COMBO_HEAVY,
	PlayerState.COMBO_FINISHER,
	PlayerState.COMBO_FINISHER_UP,
	PlayerState.COMBO_FINISHER_DOWN,
	PlayerState.CHARGED_SLASH,
	PlayerState.RIPOSTE,
]

## Where he floats, from the player's feet, when they face right (px).
@export var offset := Vector2(-18.0, -6.0)
@export var follow_speed := 8.0
@export var bob_height := 2.0
@export var bob_speed := 3.0
## How far past the player the lunge ends (px).
@export var strike_distance := 36.0
@export var strike_time := 0.18
## Seconds the cut stays out after the lunge.
@export var strike_hold := 0.08
## How far in front of the player he guards (px).
@export var guard_distance := 14.0
@export var guard_time := 0.5
## Seconds after a strike or a guard before the next one.
@export var cooldown := 0.6

var _phase := Phase.FOLLOW
var _phase_time := 0.0
var _cooldown := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _time := 0.0

@onready var visual: Node2D = $Visual
@onready var sabre: Hitbox = $Visual/Sabre
@onready var shield: Area2D = $Visual/Shield


func _ready() -> void:
	sabre.attacker_stats = player.stats
	sabre.damage = roundi(sabre.damage * player.dumas.strength())
	sabre.monitoring = true
	sabre.area_entered.connect(_on_shot_touched)
	shield.area_entered.connect(_on_shot_touched)
	_set_shield(false)
	player.state_machine.state_changed.connect(_on_player_state_changed)
	visual.scale.x = player.facing


func _physics_process(delta: float) -> void:
	if lost_player():
		return
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	match _phase:
		Phase.FOLLOW:
			_follow(delta)
		Phase.STRIKE:
			_move_through(delta, strike_time, strike_time + strike_hold)
		Phase.GUARD:
			_move_through(delta, 0.1, guard_time)


func _follow(delta: float) -> void:
	var bob := Vector2.UP * sin(_time * bob_speed) * bob_height
	var target := player.global_position + Vector2(offset.x * player.facing, offset.y) + bob
	glide_to(target, follow_speed, delta)
	visual.scale.x = player.facing


## Eases from `_from` to `_to` over `move_time`, holds there until
## `total`, then goes back to following.
func _move_through(delta: float, move_time: float, total: float) -> void:
	_phase_time += delta
	var t := ease(minf(_phase_time / move_time, 1.0), 0.4)
	global_position = _from.lerp(_to, t)
	if _phase_time >= total:
		_end_action()


func _start(phase: Phase, distance: float) -> void:
	_phase = phase
	_phase_time = 0.0
	_from = global_position
	_to = Vector2(player.global_position.x + player.facing * distance, global_position.y)
	visual.scale.x = player.facing


func _end_action() -> void:
	sabre.set_active(false)
	_set_shield(false)
	_phase = Phase.FOLLOW
	_cooldown = cooldown


func _on_player_state_changed(_from_state: StringName, to: StringName) -> void:
	if is_dismissed() or _phase != Phase.FOLLOW or _cooldown > 0.0:
		return
	if to in STRIKE_STATES:
		_start(Phase.STRIKE, strike_distance)
		sabre.set_active(true)
	elif to == PlayerState.PARRY:
		_start(Phase.GUARD, guard_distance)
		_set_shield(true)


func _set_shield(on: bool) -> void:
	shield.visible = on
	shield.set_deferred(&"monitoring", on)
	if is_instance_valid(player):
		player.hurtbox.set_ward(WARD, on)


func _on_shot_touched(area: Area2D) -> void:
	if area is EnemyProjectile:
		Pool.release(area)


func _on_dismiss() -> void:
	sabre.set_active(false)
	_set_shield(false)
	_phase = Phase.FOLLOW


func _exit_tree() -> void:
	if is_instance_valid(player):
		player.hurtbox.set_ward(WARD, false)
