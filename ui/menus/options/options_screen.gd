class_name OptionsScreen
extends MenuScreen
## The options hub, shared by the main menu and the pause menu. Every
## change applies and saves at once, so there is no "apply" step.


func _build() -> void:
	add_title(tr("Options"))
	add_button(tr("Video"), func() -> void: menu.push(VideoOptions.new()))
	add_button(tr("Audio"), func() -> void: menu.push(AudioOptions.new()))
	add_button(tr("Accessibility"), func() -> void: menu.push(AccessibilityOptions.new()))
	add_button(tr("Controls"), func() -> void: menu.push(ControlsOptions.new()))
	var languages := LanguageSettings.LOCALES
	add_option(
		tr("Language"),
		LanguageSettings.NAMES,
		languages.find(LanguageSettings.locale),
		func(i: int) -> void: LanguageSettings.set_locale(languages[i])
	)
	add_gap()
	add_button(tr("Back"), go_back)
