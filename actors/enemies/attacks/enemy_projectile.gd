class_name EnemyProjectile
extends Hitbox
## An enemy attack that flies: a shot fired in a straight line.
##
## Flies at `speed` in the direction it was launched, turned to face it.
## It ends on the first hit, on a wall (`world` layer, set as the mask; it
## passes one-way platforms), after `lifetime`, or on a room change. Put it
## on the `enemy_attacks` layer. Spawn it with `Pool.take()`; ending it
## parks it back in the `Pool`.

@export var speed := 260.0
## Seconds before it vanishes if it hits nothing.
@export var lifetime := 1.5

var _velocity := Vector2.ZERO
var _time_left := 0.0


func _ready() -> void:
	super()
	monitoring = true
	body_entered.connect(_on_body_entered)
	hit_landed.connect(_on_hit_landed)
	guard_slid.connect(_on_hit_landed)
	# A ward on the player (a duma) stops it like a hit.
	blocked.connect(_on_hit_landed)
	Events.room_change_requested.connect(_on_room_change_requested)


## Call before adding it to the tree.
func launch(from: Vector2, direction: Vector2) -> void:
	position = from
	rotation = direction.angle()
	_velocity = direction.normalized() * speed
	_time_left = lifetime


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		Pool.release(self)


func _on_body_entered(_body: Node2D) -> void:
	Pool.release(self)


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	Pool.release(self)


func _on_room_change_requested(_room_path: String, _exit_name: StringName) -> void:
	Pool.release(self)
