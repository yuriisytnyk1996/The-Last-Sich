class_name HeavyStrikesEffect
extends ItemEffect
## Turns every swing of the player into a HEAVY hit while it runs (longer
## stagger, more knockback, double spirit). For dumas; pair it with a
## `StatEffect` for extra damage.

## Where the swing hitboxes live, from the player.
const ATTACKS_PATH := ^"Visual/Attacks"
## Meta key holding a hitbox's own reaction while this runs.
const META := &"reaction_before_heavy_strikes"


func start(player: Player, _source: StringName) -> void:
	for hitbox in _hitboxes(player):
		if not hitbox.has_meta(META):
			hitbox.set_meta(META, hitbox.reaction)
		hitbox.reaction = Hitbox.Reaction.HEAVY


func stop(player: Player, _source: StringName) -> void:
	for hitbox in _hitboxes(player):
		if hitbox.has_meta(META):
			hitbox.reaction = hitbox.get_meta(META)
			hitbox.remove_meta(META)


func _hitboxes(player: Player) -> Array[Hitbox]:
	var found: Array[Hitbox] = []
	for child in player.get_node(ATTACKS_PATH).get_children():
		if child is Hitbox:
			found.append(child)
	return found
