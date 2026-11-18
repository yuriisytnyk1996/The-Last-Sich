class_name SaveFile
extends RefCounted
## Reads and writes one save slot as JSON, safely.
##
## Writes go to a temporary file first and are then renamed over the slot,
## so a crash mid-write never leaves a half-written save. After every
## successful read the slot is copied to a backup; a slot that fails to
## read falls back to that backup.

const SLOT_PATH := "user://save_%d.json"
const BACKUP_SUFFIX := ".bak"
const TEMP_SUFFIX := ".tmp"


static func path(slot: int) -> String:
	return SLOT_PATH % slot


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


## Returns the saved dictionary, or an empty one when the slot is missing
## or both the slot and its backup are unreadable.
static func read(slot: int) -> Dictionary:
	var main := path(slot)
	var data := _read_json(main)
	if not data.is_empty():
		DirAccess.copy_absolute(main, main + BACKUP_SUFFIX)
		return data
	if not FileAccess.file_exists(main):
		return {}
	push_warning("Save slot %d is unreadable, restoring its backup" % slot)
	data = _read_json(main + BACKUP_SUFFIX)
	if not data.is_empty():
		DirAccess.copy_absolute(main + BACKUP_SUFFIX, main)
	return data


## Like `read()`, but never copies a file: for showing a slot, not loading
## it. Falls back to the backup when the slot is unreadable.
static func peek(slot: int) -> Dictionary:
	var data := _read_json(path(slot))
	return data if not data.is_empty() else _read_json(path(slot) + BACKUP_SUFFIX)


## When the slot was last written (Unix time), or 0 when it doesn't exist.
static func modified_time(slot: int) -> int:
	return FileAccess.get_modified_time(path(slot)) if exists(slot) else 0


static func write(slot: int, data: Dictionary) -> bool:
	var main := path(slot)
	var temp := main + TEMP_SUFFIX
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("Can't write %s: %s" % [temp, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(temp, main) == OK


static func delete(slot: int) -> void:
	var main := path(slot)
	for file_path: String in [main, main + BACKUP_SUFFIX, main + TEMP_SUFFIX]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)


static func _read_json(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}
