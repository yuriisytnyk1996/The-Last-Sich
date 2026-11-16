extends PlayerAttackState
## Horizontal slash in front of the player, on the ground or in the air.
## On the ground the player is planted, but pushing the other way turns them
## around mid-swing (the hitbox turns with them). In the air, facing stays
## locked.
##
## Ground combo: a ground swing that hit chains into another side swing
## when attack is pressed during recovery. Once the chain has started,
## every swing chains, hit or not. A swing that hits once `heavy_after_hits`
## swings of the chain have hit goes into the heavy ComboHeavy instead.

## How far the stick must point the other way to turn around.
const TURN_THRESHOLD := 0.2

## Hits in one chain that lead into the heavy combo swing.
@export var heavy_after_hits := 2

## Swings of the current chain that hit.
var _hits := 0
var _in_chain := false
## Set when this state chains into itself, so `enter()` keeps the chain.
var _chaining := false


func enter(previous_state: StringName) -> void:
	super.enter(previous_state)
	if not _chaining:
		_hits = 0
		_in_chain = false
	_chaining = false


func move(delta: float) -> void:
	super.move(delta)
	if not _started_on_floor:
		return
	var axis := player.get_move_axis()
	if absf(axis) > TURN_THRESHOLD and signf(axis) != player.facing:
		player.set_facing(axis)


## Attack still held at the end of a ground slash: charge (with the skill).
func end_state() -> StringName:
	if _started_on_floor and player.skills.charged.wants():
		return CHARGE
	return super.end_state()


func chain_state() -> StringName:
	if not _started_on_floor or not player.is_on_floor() or attack_state() != SIDE_ATTACK:
		return super.chain_state()
	var hit := hitbox.has_hit()
	if not hit and not _in_chain:
		return super.chain_state()
	if hit:
		_hits += 1
		if _hits >= heavy_after_hits:
			return COMBO_HEAVY
	_in_chain = true
	_chaining = true
	return SIDE_ATTACK
