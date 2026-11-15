class_name AudioOptions
extends MenuScreen
## One volume row per bus in `AudioSettings`.

const LABELS := {
	&"Master": "Master volume",
	&"Music": "Music",
	&"Effects": "Effects",
	&"Voice": "Voice",
}


func _build() -> void:
	add_title("Audio")
	var values := percent_values(0, 100, AudioSettings.STEP)
	for bus in AudioSettings.BUSES:
		var index := AudioSettings.get_volume(bus) / AudioSettings.STEP
		add_option(LABELS[bus], values, index, _on_volume.bind(bus), false)
	add_gap()
	add_button("Back", go_back)


func _on_volume(index: int, bus: StringName) -> void:
	AudioSettings.set_volume(bus, index * AudioSettings.STEP)
