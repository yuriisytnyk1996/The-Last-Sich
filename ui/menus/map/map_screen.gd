class_name MapScreen
extends MenuScreen
## The pause menu's map page: the zone under the cursor, the `MapView`
## and a legend. Opened from the pause screen or straight from the
## `map` action (M / Back).

const VIEW_SIZE := Vector2(480, 216)
const LEGEND := [
	["You", MapView.PLAYER_COLOR],
	["Rest point", MapView.MARK_COLORS[MapRoom.Mark.REST_POINT]],
	["Shrine", MapView.MARK_COLORS[MapRoom.Mark.SHRINE]],
	["Door", MapView.MARK_COLORS[MapRoom.Mark.DOOR]],
	["Death mark", MapView.MARK_COLORS[MapRoom.Mark.DEATH_MARK]],
]

var _map: WorldMap
var _zone: Label


func _init(map: WorldMap) -> void:
	_map = map


func _build() -> void:
	add_title("Map")
	_zone = add_text("")
	var view := MapView.new()
	view.custom_minimum_size = VIEW_SIZE
	view.setup(_map)
	view.zone_changed.connect(_on_zone_changed)
	add_child(view)
	add_gap(2)
	add_child(_legend())
	add_text("Move: look around   Jump: zoom   Back: close")
	_on_zone_changed("")


func _legend() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for entry: Array in LEGEND:
		var swatch := ColorRect.new()
		swatch.color = entry[1]
		swatch.custom_minimum_size = Vector2(4, 4)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var label := Label.new()
		label.text = entry[0]
		row.add_child(swatch)
		row.add_child(label)
	return row


func _on_zone_changed(zone: String) -> void:
	_zone.text = zone if zone != "" else " "
