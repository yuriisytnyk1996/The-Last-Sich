extends BossAttack
## Three sabre swings in a row, stepping forward with each blade. The first
## wind-up is long, the next ones short, and the boss turns to the player
## before each. Only the last swing's hitbox is `parryable`: guard the
## first two, parry the last for a riposte.

## One hitbox per swing, in order.
@export var swing_hitboxes: Array[Hitbox] = []
## Wind-up of every swing after the first (s).
@export var chain_startup := 0.22
## Forward speed while a blade is out (px/s).
@export var step_speed := 90.0

var _swing := 0


func _ready() -> void:
	for swing in swing_hitboxes:
		swing.parried.connect(_on_parried)


func enter(previous_state: StringName) -> void:
	_swing = 0
	hitbox = swing_hitboxes[0]
	super(previous_state)


func move(delta: float) -> void:
	if _phase == Phase.ACTIVE and not enemy.is_path_blocked():
		enemy.velocity.x = enemy.facing * step_speed
	else:
		enemy.stop(delta)


## After every swing but the last, wind up the next one instead of
## recovering.
func _next_phase() -> void:
	if _phase != Phase.ACTIVE or _swing >= swing_hitboxes.size() - 1:
		super()
		return
	_set_hitbox_active(false)
	_swing += 1
	hitbox = swing_hitboxes[_swing]
	_phase = Phase.STARTUP
	_time_left = chain_startup * time_scale()
	enemy.face_target()
	_show_telegraph(true)
