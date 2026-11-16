extends PlayerComboStrike
## The heavy last swing of the ground combo. With a combo skill learned,
## attack during its recovery goes into a finisher, picked by the skill
## and the stick:
## - `combo_1`: the forward finisher.
## - `combo_2`: up held gives the rising finisher, otherwise forward.
## - `combo_3`: down held gives the slam finisher as well.
## Without a skill the combo ends here.

const COMBO_SKILLS: Array[StringName] = [&"combo_1", &"combo_2", &"combo_3"]


func chain_state() -> StringName:
	var skill := player.skills.highest(COMBO_SKILLS)
	if skill == &"":
		return super.chain_state()
	var vertical := player.get_vertical_axis()
	var threshold := player.attack_vertical_threshold
	if vertical <= -threshold and skill != &"combo_1":
		return COMBO_FINISHER_UP
	if vertical >= threshold and skill == &"combo_3":
		return COMBO_FINISHER_DOWN
	return COMBO_FINISHER
