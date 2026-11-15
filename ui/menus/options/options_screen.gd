class_name OptionsScreen
extends MenuScreen
## The options hub, shared by the main menu and the pause menu. Every
## change applies and saves at once, so there is no "apply" step.


func _build() -> void:
	add_title("Options")
	add_button("Video", func() -> void: menu.push(VideoOptions.new()))
	add_button("Audio", func() -> void: menu.push(AudioOptions.new()))
	add_button("Accessibility", func() -> void: menu.push(AccessibilityOptions.new()))
	add_button("Controls", func() -> void: menu.push(ControlsOptions.new()))
	add_gap()
	add_button("Back", go_back)
