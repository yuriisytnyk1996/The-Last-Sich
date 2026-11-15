class_name SettingsFile
extends RefCounted
## Player options in `user://settings.cfg`, one section per settings
## autoload (display, audio, accessibility, controls).
##
## Kept apart from the save slots, so starting a new game or deleting the
## save never resets the player's options.

const PATH := "user://settings.cfg"


## Every key in `section`, or an empty dictionary when there is none.
static func load_section(section: String) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(PATH) != OK or not config.has_section(section):
		return {}
	var values := {}
	for key in config.get_section_keys(section):
		values[key] = config.get_value(section, key)
	return values


## Replaces `section` with `values`, keeping the other sections.
static func save_section(section: String, values: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	if config.has_section(section):
		config.erase_section(section)
	for key: String in values:
		config.set_value(section, key, values[key])
	config.save(PATH)


static func erase_section(section: String) -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK or not config.has_section(section):
		return
	config.erase_section(section)
	config.save(PATH)
