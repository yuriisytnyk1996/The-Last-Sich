extends Node
## Game language (autoload "LanguageSettings"), saved in the `[language]`
## section of `user://settings.cfg`. The first start picks the system
## language when the game has it, English otherwise.
##
## English is the source language: the text in code and resources is the
## English, so it needs no translation file. Other languages are the `.po`
## files in `locale/`, listed in Project Settings > Localization.

signal changed

const SECTION := "language"
## Language codes in menu order.
const LOCALES: PackedStringArray = ["en", "uk"]
## Each language's name in that language, never translated.
const NAMES: PackedStringArray = ["English", "Українська"]

var locale := "en"


func _ready() -> void:
	var saved := SettingsFile.load_section(SECTION)
	var start := str(saved.get("locale", OS.get_locale_language()))
	locale = start if start in LOCALES else LOCALES[0]
	TranslationServer.set_locale(locale)


func set_locale(code: String) -> void:
	locale = code if code in LOCALES else LOCALES[0]
	TranslationServer.set_locale(locale)
	SettingsFile.save_section(SECTION, {"locale": locale})
	changed.emit()
