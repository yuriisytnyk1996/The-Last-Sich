class_name AudioOptions
extends MenuScreen
## One volume row per bus in `AudioSettings`.


func _build() -> void:
	add_title(tr("Audio"))
	var labels := {
		&"Master": tr("Master volume"),
		&"Music": tr("Music"),
		&"Effects": tr("Effects"),
		&"Voice": tr("Voice"),
	}
	var values := percent_values(0, 100, AudioSettings.STEP)
	for bus in AudioSettings.BUSES:
		var index := AudioSettings.get_volume(bus) / AudioSettings.STEP
		add_option(labels[bus], values, index, _on_volume.bind(bus), false)
	add_gap()
	add_button(tr("Back"), go_back)


func _on_volume(index: int, bus: StringName) -> void:
	AudioSettings.set_volume(bus, index * AudioSettings.STEP)
