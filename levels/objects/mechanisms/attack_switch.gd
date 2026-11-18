class_name AttackSwitch
extends Node2D
## A switch flipped by hitting it: any player attack, the ranged bolt
## included, so a switch out of reach is thrown from a distance. Like a
## `Lever`, it calls a method on each node in `targets`, chosen by
## `action`:
##
## - TOGGLE: `toggle()` on every hit (a `Gate` opens, then closes).
## - UNLOCK: `unlock()` (a locked gate can then be opened by something else).
## - TIMED: `set_open(true)`, then `set_open(false)` after `open_time`. The
##   switch ignores hits until it springs back. Makes a gate the player
##   has to run through.
##
## With `one_shot` it stays on after the first hit and takes no more.
##
## Children: `Hurtbox` (masks `player_attacks`, `rewards_attacker` off so
## it fills no spirit; its `invincibility_time` keeps one swing from
## flipping it twice), `Head` (turns and lights when on) and
## `HurtFeedback`. The origin is the bottom centre: put it in the room's
## `Logic`. Saved (`persistent` group), except in TIMED mode, which owns
## its targets and shuts them when the room loads.

enum Action { TOGGLE, UNLOCK, TIMED }

## Nodes to drive. Each needs the method `action` calls.
@export var targets: Array[Node] = []
@export var action := Action.TOGGLE
## Stays on after the first hit, which suits shortcuts.
@export var one_shot := false
## TIMED only: seconds the targets stay open.
@export var open_time := 3.0
## Head angle and colour when off and on.
@export var off_angle := 0.0
@export var on_angle := PI / 4.0
@export var off_color := Color(0.45, 0.45, 0.5)
@export var on_color := Color(0.95, 0.75, 0.3)

var on := false

var _timer: SceneTreeTimer

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var head: Node2D = $Head
@onready var gem: CanvasItem = $Head/Gem


func _ready() -> void:
	hurtbox.hurt.connect(_on_hurt)
	if action == Action.TIMED:
		# Deferred: runs after the room has restored its targets' state.
		_drive_open.call_deferred(false, true)
	else:
		add_to_group(SaveManager.PERSISTENT_GROUP)
	_show()


func get_save_data() -> Dictionary:
	return {"on": on}


func apply_save_data(data: Dictionary) -> void:
	on = bool(data.get("on", false))
	_show()
	if on and one_shot:
		_disable()


func _on_hurt(_hitbox: Hitbox) -> void:
	if action == Action.TIMED:
		_open_for_time()
		return
	on = not on
	_show()
	_call_targets(&"toggle" if action == Action.TOGGLE else &"unlock")
	if one_shot:
		_disable()


func _open_for_time() -> void:
	if _timer:
		return
	on = true
	_show()
	_drive_open(true)
	_timer = get_tree().create_timer(open_time, false)
	await _timer.timeout
	_timer = null
	# The room unloaded while the timer ran.
	if not is_inside_tree():
		return
	on = false
	_show()
	_drive_open(false)


func _drive_open(open: bool, instant := false) -> void:
	_call_targets(&"set_open", [open, instant])


func _call_targets(method: StringName, args := []) -> void:
	for target in targets:
		if target and target.has_method(method):
			target.callv(method, args)
		else:
			push_warning("AttackSwitch %s: target %s has no %s()" % [name, target, method])


func _disable() -> void:
	# Deferred: collision can't change during a physics callback.
	hurtbox.set_deferred(&"monitoring", false)


func _show() -> void:
	head.rotation = on_angle if on else off_angle
	gem.self_modulate = on_color if on else off_color
