extends PlayerState
## Drinking a healing flask. The flask is used and the health restored as
## soon as this starts; then the player stands still for `drink_time`
## while the aura glows and fades. Any hit stops the drink, but the
## health stays healed: a normal or heavy hit through the Hurt state, a
## light hit (which doesn't stagger) by ending the drink here.

## Placeholder glow behind the body, shown while drinking.
@export var aura: CanvasItem

var _time_left := 0.0
var _fade: Tween


func enter(_previous_state: StringName) -> void:
	player.hurtbox.hurt.connect(_on_hurt)
	player.flasks.drink()
	_time_left = player.flasks.drink_time
	aura.visible = true
	aura.modulate.a = 1.0
	_fade = create_tween()
	_fade.tween_property(aura, ^"modulate:a", 0.0, _time_left).set_ease(Tween.EASE_IN)


func exit() -> void:
	player.hurtbox.hurt.disconnect(_on_hurt)
	if _fade:
		_fade.kill()
	aura.visible = false


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	_time_left -= delta
	if not player.is_on_floor():
		finished.emit(FALL)
	elif _time_left <= 0.0:
		finished.emit(ground_state())


## Normal and heavy hits already move to Hurt (`PlayerDamage`).
func _on_hurt(hitbox: Hitbox) -> void:
	if hitbox.reaction == Hitbox.Reaction.LIGHT:
		finished.emit(ground_state())
