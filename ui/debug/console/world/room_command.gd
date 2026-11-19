extends ConsoleCommand
## `room`: lists the rooms and moves the player to one, through the same
## fade as an exit (`Events.room_change_requested`). The console closes
## first, so the transition runs with the game unpaused.

const ROOMS_DIR := "res://levels/rooms/"


func _init() -> void:
	names = ["room", "go"]
	summary = "List the rooms, or go to one"
	usage = [
		"room: list the rooms, > marks the current one",
		"room <name> [exit]: go there, to its spawn point or to the exit named",
	]


func run(args: PackedStringArray) -> void:
	var current := world().room.scene_file_path
	if args.is_empty():
		for room_name in room_names():
			write("%s %s" % [">" if _path(room_name) == current else " ", room_name])
		return
	var room_name := args[0].trim_suffix(".tscn").get_file()
	if not room_name in room_names():
		error('No room "%s". Type room for the list.' % room_name)
		return
	var exit_name := StringName(args[1]) if args.size() > 1 else &""
	shell.close_requested.emit()
	Events.room_change_requested.emit(_path(room_name), exit_name)


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return room_names() if index == 0 else PackedStringArray()


## Every room scene, by file name. Exported builds list remapped files.
static func room_names() -> PackedStringArray:
	var found := PackedStringArray()
	for file in DirAccess.get_files_at(ROOMS_DIR):
		file = file.trim_suffix(".remap")
		if file.get_extension() == "tscn":
			found.append(file.get_basename())
	found.sort()
	return found


static func _path(room_name: String) -> String:
	return ROOMS_DIR + room_name + ".tscn"
