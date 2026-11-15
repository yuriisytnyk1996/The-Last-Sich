extends Label
## Shows the game version from Project Settings → Application → Config → Version.
## Kept in release builds so screenshots of bugs always show the version.


func _ready() -> void:
	text = "v%s" % ProjectSettings.get_setting("application/config/version", "dev")
