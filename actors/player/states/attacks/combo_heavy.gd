extends PlayerComboStrike
## The heavy last swing of the ground combo. With a combo skill learned,
## attack during its recovery goes into a finisher, picked by the skill
## level and the stick:
## - level 1: the forward finisher.
## - level 2: up held gives the rising finisher, otherwise forward.
## - level 3: down held gives the slam finisher as well.
## Without a skill the combo ends here.


func chain_state() -> StringName:
	var level := player.skills.level(&"combo")
	if level == 0:
		return super.chain_state()
	var vertical := player.get_vertical_axis()
	var threshold := player.attack_vertical_threshold
	if vertical <= -threshold and level >= 2:
		return COMBO_FINISHER_UP
	if vertical >= threshold and level >= 3:
		return COMBO_FINISHER_DOWN
	return COMBO_FINISHER
