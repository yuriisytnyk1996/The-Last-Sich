class_name SkillsScreen
extends MenuScreen
## The skill shrine page: the player's currency and every skill with its
## state (cost, learned or locked). The focused skill's description shows
## below the list. Choosing a skill the player can pay for asks to confirm,
## then learns it.

var _skills: PlayerSkills
var _currency: Label
var _info: Label
var _rows: Dictionary[PlayerSkill, Button] = {}


func _init(skills: PlayerSkills) -> void:
	_skills = skills


func _build() -> void:
	add_title("Skills")
	_currency = add_text("")
	add_gap()
	for skill in _skills.all:
		var row := add_button("", _on_row_pressed.bind(skill))
		row.focus_entered.connect(_show_info.bind(skill))
		_rows[skill] = row
	add_gap()
	_info = add_text("")
	add_gap()
	add_button("Leave", go_back)
	_refresh()


func _refresh() -> void:
	_currency.text = "Currency: %d" % _skills.player.wallet.amount
	for skill in _rows:
		_rows[skill].text = _row_text(skill)


func _row_text(skill: PlayerSkill) -> String:
	if _skills.has(skill.id):
		return "%s - learned" % skill.title
	if _skills.is_learnable(skill):
		return "%s - %d" % [skill.title, skill.cost]
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
		return "Needs tier %d." % skill.tier
	return "Learn %s first." % skill.parent.title


func _on_row_pressed(skill: PlayerSkill) -> void:
	if not _skills.can_learn(skill):
		return
	var question := "Learn %s for %d?" % [skill.title, skill.cost]
	menu.push(ConfirmScreen.new(question, _learn.bind(skill)))


func _learn(skill: PlayerSkill) -> void:
	_skills.learn(skill)
	menu.pop()
	_refresh()
	_show_info(skill)
