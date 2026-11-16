@tool
class_name PoisonZone
extends AreaEffect
## Poisoned air: hurts the player a little every `tick_time` while they
## stay inside. Passing through quickly costs nothing (`grace_time`).
##
## The damage is a light hit (flash, no stagger) from a `Hitbox` the zone
## builds on the `hazards` layer, so it goes through the player's normal
## hurt path: invincibility, HUD and death all work as for any hit.

const HAZARDS_LAYER := 6
## How long each tick's hitbox stays out (s).
const PULSE_TIME := 0.05

@export var damage := 1
## Seconds between hits while inside.
@export var tick_time := 1.2
## Seconds inside before the first hit.
@export var grace_time := 0.6

var _hitbox: Hitbox
var _tick_left := 0.0
var _pulse_left := 0.0


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_hitbox = Hitbox.new()
	_hitbox.damage = damage
	_hitbox.reaction = Hitbox.Reaction.LIGHT
	_hitbox.knockback_force = 0.0
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 0
	_hitbox.set_collision_layer_value(HAZARDS_LAYER, true)
	_hitbox.add_child(make_shape())
	add_child(_hitbox)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _pulse_left > 0.0:
		_pulse_left -= delta
		if _pulse_left <= 0.0:
			_hitbox.set_active(false)
	if player == null:
		return
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left = tick_time
		_pulse_left = PULSE_TIME
		_hitbox.set_active(true)


func _player_entered() -> void:
	_tick_left = grace_time


func _get_color() -> Color:
	return Color(0.45, 0.85, 0.25, 0.22)
