extends BossAttack
## Draws a pistol and fires `shots` balls at the player, aiming each one
## afresh, then a long reload. The balls can't be parried. Set `active`
## to about `shots` × `shot_interval`.

## The ball fired on each shot.
@export var projectile_scene: PackedScene
## Where the balls leave the barrel. Under Visual, so it flips with facing.
@export var muzzle: Node2D
@export var shots := 3
## Seconds between shots (scaled by phase).
@export var shot_interval := 0.3

var _shots_left := 0
var _next_shot := 0.0


func enter(previous_state: StringName) -> void:
	_shots_left = 0
	super(previous_state)


func physics_update(delta: float) -> void:
	super(delta)
	if _phase != Phase.ACTIVE or _shots_left <= 0:
		return
	_next_shot -= delta
	if _next_shot <= 0.0:
		_fire()


func _on_active() -> void:
	_shots_left = shots
	_fire()


func _fire() -> void:
	_shots_left -= 1
	_next_shot = shot_interval * time_scale()
	if projectile_scene == null or not enemy.can_track_target():
		return
	enemy.face_target()
	var ball := projectile_scene.instantiate() as EnemyProjectile
	ball.attacker_stats = enemy.stats
	var direction := enemy.target_point() - muzzle.global_position
	ball.launch(muzzle.global_position, direction)
	enemy.get_parent().add_child(ball)
