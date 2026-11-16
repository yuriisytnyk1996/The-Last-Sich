class_name PlayerSkill
extends Resource
## One upgrade the player can learn at a skill shrine, bought with
## currency. Each skill is a `.tres` file in this folder, listed on the
## player's `Skills` node. See `PlayerSkills`.

## Saved to disk and checked by the abilities (`PlayerSkills.has()`).
## Never rename one that has shipped.
@export var id := &""
@export var title := ""
@export_multiline var description := ""
## Skills are learned tier by tier: a skill can't be learned until the
## player's `PlayerSkills.max_tier` reaches its tier.
@export_range(1, 9) var tier := 1
@export var cost := 100
## Has to be learned first. Empty for a skill with no prerequisite.
@export var parent: PlayerSkill
