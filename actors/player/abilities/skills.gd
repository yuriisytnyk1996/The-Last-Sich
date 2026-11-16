class_name PlayerSkills
extends Node
## The upgrades the player has learned.
##
## Every skill in the game is listed in `all`. A skill can be learned when
## it isn't learned yet, its parent is, and its tier is open
## (`is_learnable()`). Learning it also needs the currency to pay for it
## (`can_learn()`). Abilities ask `has()` or `highest()` before they run.
##
## A global save system (see `SaveManager`): the learned ids are written to
## disk whenever the game saves.

signal learned(skill: PlayerSkill)

## Every skill, in menu order.
@export var all: Array[PlayerSkill] = []
## Highest skill tier the player can learn. Every tier is open until a
## progression item raises it.
@export_range(1, 9) var max_tier := 3

var save_id := &"skills"
var _learned := {}

@onready var player := owner as Player


func _ready() -> void:
	SaveManager.register(self)


func has(id: StringName) -> bool:
	return _learned.has(id)


## The last id in `ids` that is learned, or empty if none is. For skills
## that upgrade one ability in steps (`combo_1`, `combo_2`...).
func highest(ids: Array[StringName]) -> StringName:
	for i in range(ids.size() - 1, -1, -1):
		if has(ids[i]):
			return ids[i]
	return &""


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


func get_save_data() -> Dictionary:
	return {"learned": _learned.keys()}


func apply_save_data(data: Dictionary) -> void:
	_learned.clear()
	var ids: Variant = data.get("learned", [])
	if ids is Array:
		for id: Variant in ids:
			_learned[StringName(str(id))] = true
