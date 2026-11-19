class_name AccessibilityOptions
extends MenuScreen
## Toggles from `AccessibilitySettings`.


func _build() -> void:
	var settings := AccessibilitySettings
	add_title(tr("Accessibility"))
	add_option(
		tr("Screen shake"),
		on_off(),
		int(settings.screen_shake),
		func(i: int) -> void: settings.set_screen_shake(i == 1)
	)
	add_option(tr("Rumble"), on_off(), int(settings.rumble), _on_rumble)
	add_option(
		tr("Tips"), on_off(), int(settings.tips), func(i: int) -> void: settings.set_tips(i == 1)
	)
	add_gap()
	add_button(tr("Back"), go_back)


func _on_rumble(index: int) -> void:
	AccessibilitySettings.set_rumble(index == 1)
	# A short buzz so the player feels what they just turned on.
	Rumble.play(0.5, 0.2)
