class_name PlayerSkills
extends Node
## The upgrades the player has learned, and the tier they have reached.
##
## Every skill in the game is listed in `all`. Skills come in lines of
## three levels that upgrade one ability (`lunge_1`, `lunge_2`, `lunge_3`),
## each level the parent of the next. A skill can be learned when it isn't
## learned yet, its parent is, and its tier is at most `max_tier`
## (`is_learnable()`). Learning it also needs the currency to pay for it
## (`can_learn()`). Abilities ask `level()` before they run.
##
## `max_tier` starts at `start_tier` and goes up by one with every tier
## relic picked up (`raise_tier()`), up to `TIER_CAP`.
##
## A global save system (see `SaveManager`): the learned ids and the tier
## are written to disk whenever the game saves.

signal learned(skill: PlayerSkill)
signal tier_raised(tier: int)

## Highest tier there is.
const TIER_CAP := 6
## Levels in one skill line.
const LEVELS := 3

## Every skill, line by line, levels in order. The skill menu shows one
## line per row.
@export var all: Array[PlayerSkill] = []
## Tier at the start of a new game.
@export_range(1, TIER_CAP) var start_tier := 1

var save_id := &"skills"
var max_tier := start_tier
var _learned := {}

@onready var player := owner as Player
## One child per skill line with an ability behind it.
@onready var charged: PlayerChargedAttack = $Charged
@onready var lunge: PlayerLungeAttack = $Lunge
@onready var dive: PlayerDiveAttack = $Dive
@onready var ranged: PlayerRangedAttack = $Ranged


func _ready() -> void:
	max_tier = start_tier
	SaveManager.register(self)


func has(id: StringName) -> bool:
	return _learned.has(id)


## The highest learned level of a skill line (`&"lunge"` checks `lunge_1`
## to `lunge_3`), or 0 when none is learned.
func level(line: StringName) -> int:
	for i in range(LEVELS, 0, -1):
		if has(StringName("%s_%d" % [line, i])):
			return i
	return 0


## Not learned yet, parent learned and tier open. Ignores the cost.
func is_learnable(skill: PlayerSkill) -> bool:
	if has(skill.id) or skill.tier > max_tier:
		return false
	return skill.parent == null or has(skill.parent.id)


func can_learn(skill: PlayerSkill) -> bool:
	return is_learnable(skill) and player.wallet.amount >= skill.cost


## Pays for `skill` and learns it. Returns false if it can't be learned.
func learn(skill: PlayerSkill) -> bool:
	if not can_learn(skill) or not player.wallet.spend(skill.cost):
		return false
	_learned[skill.id] = true
	learned.emit(skill)
	return true


## Opens the next tier. Returns false at `TIER_CAP`.
func raise_tier() -> bool:
	if max_tier >= TIER_CAP:
		return false
	max_tier += 1
	tier_raised.emit(max_tier)
	return true


func get_save_data() -> Dictionary:
	return {"learned": _learned.keys(), "tier": max_tier}


func apply_save_data(data: Dictionary) -> void:
	_learned.clear()
	var ids: Variant = data.get("learned", [])
	if ids is Array:
		for id: Variant in ids:
			_learned[StringName(str(id))] = true
	max_tier = clampi(int(data.get("tier", start_tier)), 1, TIER_CAP)
