class_name Turret
extends Node2D
## A fixed shooter built into the level. It fires a bolt along its facing
## (local +x) every `fire_interval`, and its `Warning` child shows for
## `warn_time` before each shot. It can't be destroyed, and its bolts
## can't be parried. Rotate the node to aim it.
##
## With `trigger_range` above 0 it only fires while the player is that
## close, so it stays quiet in a distant corner of a big room.

@export var projectile_scene: PackedScene
@export var fire_interval := 2.0
@export var warn_time := 0.4
## Seconds the firing cycle is shifted by, to fire out of step.
@export var offset := 0.0
## Only fire while the player is within this distance (px). 0: always.
@export var trigger_range := 0.0

var _time := 0.0

@onready var muzzle: Marker2D = $Muzzle
@onready var warning: CanvasItem = $Warning


func _ready() -> void:
	_time = fposmod(offset, fire_interval)
	warning.visible = false


func _physics_process(delta: float) -> void:
	_time += delta
	var armed := _player_in_range()
	warning.visible = armed and _time >= fire_interval - warn_time
	if _time >= fire_interval:
		_time -= fire_interval
		if armed:
			_fire()


func _fire() -> void:
	if projectile_scene == null:
		return
	var bolt := projectile_scene.instantiate() as EnemyProjectile
	var parent := get_parent()
	bolt.launch(parent.to_local(muzzle.global_position), global_transform.x)
	parent.add_child(bolt)


func _player_in_range() -> bool:
	if trigger_range <= 0.0:
		return true
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	return player != null and player.global_position.distance_to(global_position) <= trigger_range
