extends SceneTree
## Fills the POT generation list (Project Settings > Localization >
## Template Generation) with every file that may hold player-facing text:
## scripts that call `tr()`, every scene, and resources of the classes the
## text extractor reads (`addons/text_extractor/text_parser.gd`).
##
## Run with `pnpm i18n:files` before generating the POT, so new files are
## not missed. With `-- --check` it only compares and exits with 1 when the
## list is out of date.

const SETTING := "internationalization/locale/translations_pot_files"
const SKIPPED: PackedStringArray = ["addons", "docs", "node_modules", "tools"]
const SCRIPT_CLASS := 'script_class="%s"'
## `tr(`, `tr_n(`, `atr(`, also as `TranslationServer.tr(`, but not `str(`.
const TR_CALL := "\\ba?tr(_n)?\\("
## By path: the class cache may not know a fresh checkout.
const Parser := preload("res://addons/text_extractor/text_parser.gd")


func _initialize() -> void:
	var files := PackedStringArray()
	_collect("res://", files)
	files.sort()
	var current: PackedStringArray = ProjectSettings.get_setting(SETTING, PackedStringArray())
	if "--check" in OS.get_cmdline_user_args():
		if current != files:
			printerr("POT file list is out of date. Run `pnpm i18n:files`.")
		quit(0 if current == files else 1)
		return
	ProjectSettings.set_setting(SETTING, files)
	ProjectSettings.save()
	print("POT file list: %d files." % files.size())
	quit()


func _collect(dir: String, files: PackedStringArray) -> void:
	for sub in DirAccess.get_directories_at(dir):
		var path := dir + sub + "/"
		if not sub.begins_with(".") and not sub in SKIPPED and not _ignored(path):
			_collect(path, files)
	for file in DirAccess.get_files_at(dir):
		if _has_text(dir + file):
			files.append(dir + file)


func _has_text(path: String) -> bool:
	match path.get_extension():
		"tscn":
			return true
		"gd":
			return (
				RegEx.create_from_string(TR_CALL).search(FileAccess.get_file_as_string(path))
				!= null
			)
		"tres":
			var header := FileAccess.open(path, FileAccess.READ).get_line()
			for script_class: StringName in Parser.PROPERTIES:
				if header.contains(SCRIPT_CLASS % script_class):
					return true
	return false


## Godot skips folders holding a `.gdignore` file.
func _ignored(path: String) -> bool:
	return FileAccess.file_exists(path + ".gdignore")
