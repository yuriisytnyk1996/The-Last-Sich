class_name SkillsScreen
extends MenuScreen
## The skill shrine page: the player's currency and tier, and the skill
## tree as a grid, one skill line per row and one level per column. Each
## cell shows the skill's cost, "learned", the tier it needs or "locked".
## The focused skill's description shows below the grid. Choosing a skill
## the player can pay for asks to confirm, then learns it.

const CELL_WIDTH := 150.0

var _skills: PlayerSkills
var _status: Label
var _info: Label
var _cells: Dictionary[PlayerSkill, Button] = {}


func _init(skills: PlayerSkills) -> void:
	_skills = skills


func _build() -> void:
	add_title("Skills")
	_status = add_text("")
	add_gap()
	var grid := GridContainer.new()
	grid.columns = PlayerSkills.LEVELS
	add_child(grid)
	for skill in _skills.all:
		var cell := Button.new()
		cell.custom_minimum_size.x = CELL_WIDTH
		cell.pressed.connect(_on_cell_pressed.bind(skill))
		cell.focus_entered.connect(_show_info.bind(skill))
		grid.add_child(cell)
		_cells[skill] = cell
	add_gap()
	_info = add_text("")
	_info.custom_minimum_size.x = CELL_WIDTH * PlayerSkills.LEVELS
	add_gap()
	if OS.is_debug_build():
		_add_debug_buttons()
	add_button("Leave", go_back)
	_refresh()


## Debug builds only.
func _add_debug_buttons() -> void:
	add_button("Debug: unlock all", _debug.bind(_skills.unlock_all))
	add_button("Debug: lock all", _debug.bind(_skills.lock_all))


func _debug(action: Callable) -> void:
	action.call()
	_refresh()
	_info.text = ""


func _refresh() -> void:
	_status.text = "Currency: %d    Tier: %d" % [_skills.player.wallet.amount, _skills.max_tier]
	for skill in _cells:
		_cells[skill].text = _cell_text(skill)


func _cell_text(skill: PlayerSkill) -> String:
	if _skills.has(skill.id):
		return "%s - learned" % skill.title
	if _skills.is_learnable(skill):
		return "%s - %d" % [skill.title, skill.cost]
	if skill.tier > _skills.max_tier:
		return "%s - tier %d" % [skill.title, skill.tier]
	return "%s - locked" % skill.title


func _show_info(skill: PlayerSkill) -> void:
	var text := skill.description
	if not _skills.has(skill.id) and not _skills.is_learnable(skill):
		text += "\n" + _lock_reason(skill)
	elif _skills.is_learnable(skill) and not _skills.can_learn(skill):
		text += "\nNot enough currency."
	_info.text = text


func _lock_reason(skill: PlayerSkill) -> String:
	if skill.tier > _skills.max_tier:
		return "Needs tier %d. Find relics to raise your tier." % skill.tier
	return "Learn %s first." % skill.parent.title


func _on_cell_pressed(skill: PlayerSkill) -> void:
	if not _skills.can_learn(skill):
		return
	var question := "Learn %s for %d?" % [skill.title, skill.cost]
	menu.push(ConfirmScreen.new(question, _learn.bind(skill)))


func _learn(skill: PlayerSkill) -> void:
	_skills.learn(skill)
	menu.pop()
	_refresh()
	_show_info(skill)
