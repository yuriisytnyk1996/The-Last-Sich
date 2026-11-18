@tool
class_name ShockwaveArea
extends AreaEffect
## A stretch of floor that quakes on a cycle. Quiet for `off_time`, then
## the ground trembles for `warn_time` (the band flickers), then a
## shockwave runs through it: for `on_time` a HEAVY hit covers the whole
## zone. A player in the air when it strikes is safe; one on the guard
## takes it as a guard slide. `offset` shifts the cycle, so neighbouring
## stretches can quake in turn.
##
## The zone is the band that hurts: lay it on the floor, as tall as the
## shockwave should reach (12 to 16 px keeps a short hop clear of it).
## The hit is built in code on the `hazards` layer and only hurts the
## player.

enum Phase { OFF, WARN, ON }

const HAZARDS_LAYER := 6
## Seconds per flicker step while warning.
const FLICKER_TIME := 0.07

@export var off_time := 1.8
@export var warn_time := 0.7
@export var on_time := 0.2
## Seconds the cycle is shifted by.
@export var offset := 0.0
@export var damage := 30
@export var knockback_force := 180.0
## Camera trauma when it strikes with the player inside or near.
@export var shake := 0.3
## How close the player has to be for the shake (px from the zone).
@export var shake_range := 160.0

var _hitbox: Hitbox
var _time := 0.0
var _phase := Phase.OFF


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	_hitbox = Hitbox.new()
	_hitbox.damage = damage
	_hitbox.reaction = Hitbox.Reaction.HEAVY
	_hitbox.knockback_force = knockback_force
	_hitbox.knockback_direction = Vector2.UP
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 0
	_hitbox.set_collision_layer_value(HAZARDS_LAYER, true)
	_hitbox.add_child(make_shape())
	add_child(_hitbox)
	_time = fposmod(offset, _cycle_time())


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time = fmod(_time + delta, _cycle_time())
	var phase := _phase_at(_time)
	if phase != _phase:
		_phase = phase
		_hitbox.set_active(phase == Phase.ON)
		if phase == Phase.ON:
			_strike_feedback()
	queue_redraw()


func _cycle_time() -> float:
	return maxf(off_time + warn_time + on_time, 0.01)


func _phase_at(time: float) -> Phase:
	if time < off_time:
		return Phase.OFF
	if time < off_time + warn_time:
		return Phase.WARN
	return Phase.ON


func _strike_feedback() -> void:
	var target := get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null:
		return
	var area := Rect2(global_position, size).grow(shake_range)
	if area.has_point(target.global_position):
		Events.camera_shake_requested.emit(shake)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, _get_color())
	if Engine.is_editor_hint():
		return
	if _phase == Phase.WARN and int((_time - off_time) / FLICKER_TIME) % 2 == 0:
		draw_rect(rect, Color(1.0, 0.75, 0.4, 0.3))
	elif _phase == Phase.ON:
		draw_rect(rect, Color(1.6, 1.2, 0.7, 0.75))


func _get_color() -> Color:
	return Color(0.8, 0.55, 0.3, 0.15)
