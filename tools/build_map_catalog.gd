extends SceneTree
## Builds `levels/map/map_catalog.tres` (a `MapCatalog`) from the room
## scenes in `levels/rooms/`: every scene whose root node uses
## `levels/room.gd`, with its `bounds` and `map_cell`.
##
## Reads the `.tscn` text instead of loading the scenes, so it is fast and
## needs no autoloads. Run with `pnpm map:catalog`. With `-- --check` it
## only compares and exits with 1 when the catalog is out of date (the
## pre-commit hook uses that).

const ROOMS_DIR := "res://levels/rooms/"
const ROOM_SCRIPT := "res://levels/room.gd"
const OUTPUT := "res://levels/map/map_catalog.tres"
## Must match `WorldMap.cell_size` and the defaults of `Room`.
const CELL_SIZE := Vector2i(320, 180)
const DEFAULT_BOUNDS := Rect2i(0, 0, 1280, 360)
const DEFAULT_MAP_CELL := Vector2i.ZERO
## By path, not class name: the class cache may not know a fresh checkout.
const Catalog := preload("res://levels/map/map_catalog.gd")


func _initialize() -> void:
	var catalog := Catalog.new()
	for file in DirAccess.get_files_at(ROOMS_DIR):
		if file.ends_with(".tscn"):
			var path := ROOMS_DIR + file
			var rect: Variant = _room_rect(FileAccess.get_file_as_string(path))
			if rect is Rect2i:
				catalog.rooms[path] = rect
	if "--check" in OS.get_cmdline_user_args():
		quit(_check(catalog))
		return
	var error := ResourceSaver.save(catalog, OUTPUT)
	if error != OK:
		printerr("Map catalog: can't write %s (%s)" % [OUTPUT, error_string(error)])
	else:
		print("Map catalog: %d rooms, %d cells" % [catalog.rooms.size(), catalog.cells().size()])
	quit(0 if error == OK else 1)


## The room's map rectangle, or null when the scene isn't a room.
func _room_rect(text: String) -> Variant:
	var scripts := {}
	var props := {}
	var in_root := false
	for line in text.split("\n"):
		if line.begins_with("[ext_resource") and ROOM_SCRIPT in line:
			scripts[_attribute(line, "id")] = true
		elif line.begins_with("[node"):
			if in_root or "parent=" in line:
				break
			in_root = true
		elif in_root and " = " in line:
			var parts := line.split(" = ", true, 1)
			props[parts[0]] = parts[1]
	var script_ref: String = props.get("script", "")
	if not script_ref.begins_with("ExtResource(") or not scripts.has(_attribute(script_ref, "")):
		return null
	var bounds: Rect2i = str_to_var(props.get("bounds", var_to_str(DEFAULT_BOUNDS)))
	var map_cell: Vector2i = str_to_var(props.get("map_cell", var_to_str(DEFAULT_MAP_CELL)))
	return Catalog.rect_for(map_cell, bounds, CELL_SIZE)


## The first quoted value after `key=` (or anywhere, with an empty key).
func _attribute(line: String, key: String) -> String:
	var start := line.find(key + '="') + key.length() + 2 if key != "" else line.find('"') + 1
	return line.substr(start, line.find('"', start) - start)


func _check(catalog: Catalog) -> int:
	var saved := load(OUTPUT) as Catalog
	if saved and saved.rooms == catalog.rooms:
		return 0
	printerr("Map catalog is out of date. Run: pnpm map:catalog")
	return 1
