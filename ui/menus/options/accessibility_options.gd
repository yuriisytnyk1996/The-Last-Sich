class_name AccessibilityOptions
extends MenuScreen
## Toggles from `AccessibilitySettings`.


func _build() -> void:
	var settings := AccessibilitySettings
	add_title("Accessibility")
	add_option(
		"Screen shake",
		ON_OFF,
		int(settings.screen_shake),
		func(i: int) -> void: settings.set_screen_shake(i == 1)
	)
	add_option("Rumble", ON_OFF, int(settings.rumble), _on_rumble)
	add_option("Tips", ON_OFF, int(settings.tips), func(i: int) -> void: settings.set_tips(i == 1))
	add_gap()
	add_button("Back", go_back)


func _on_rumble(index: int) -> void:
	AccessibilitySettings.set_rumble(index == 1)
	# A short buzz so the player feels what they just turned on.
	Rumble.play(0.5, 0.2)
