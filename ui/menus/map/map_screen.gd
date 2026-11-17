class_name MapScreen
extends MenuScreen
## The pause menu's map page: the zone under the cursor, the `MapView`
## and a legend. Opened from the pause screen or straight from the
## `map` action (M / Back).
##
## In travel mode (opened by kneeling at a rest point, see `KneelScreen`)
## the cursor hops between rest points (`MapTravel`). Attack on one asks
## the world to travel there (`Events.travel_requested`); back closes the
## whole menu, so the player rises.

const VIEW_SIZE := Vector2(480, 216)
## Two rows, so the legend fits the screen width.
const LEGEND := [
	[
		["You", MapView.PLAYER_COLOR],
		["Rest point", MapView.MARK_COLORS[MapRoom.Mark.REST_POINT]],
		["Shrine", MapView.MARK_COLORS[MapRoom.Mark.SHRINE]],
		["Shop", MapView.MARK_COLORS[MapRoom.Mark.SHOP]],
		["Cleanse", MapView.MARK_COLORS[MapRoom.Mark.CLEANSE]],
	],
	[
		["Upgrade", MapView.MARK_COLORS[MapRoom.Mark.UPGRADE]],
		["Door", MapView.MARK_COLORS[MapRoom.Mark.DOOR]],
		["Death mark", MapView.MARK_COLORS[MapRoom.Mark.DEATH_MARK]],
	],
]

const HINT := "Move: look around   Jump: zoom   Attack: mark   Back: close"
const PICK_HINT := "Move: choose   Attack: place   Back: cancel"
const TRAVEL_HINT := "Move: choose   Attack: travel   Back: rise"
const NO_TRAVEL_HINT := "Move: choose   Back: rise"

var _map: WorldMap
var _zone: Label
var _hint: Label
var _view := MapView.new()
var _travel_mode := false


func _init(map: WorldMap, travel_mode := false) -> void:
	_map = map
	_travel_mode = travel_mode


func _build() -> void:
	add_title("Travel" if _travel_mode else "Map")
	_zone = add_text("")
	_view.custom_minimum_size = VIEW_SIZE
	_map.refresh()
	_view.setup(_map, _travel_mode)
	_view.zone_changed.connect(_on_zone_changed)
	_view.travel_chosen.connect(_on_travel_chosen)
	add_child(_view)
	add_gap(2)
	for entries: Array in LEGEND:
		add_child(_legend(entries))
	_hint = add_text(HINT)
	_view.picking_changed.connect(_on_picking_changed)
	_on_zone_changed("")


func _process(_delta: float) -> void:
	if _view.travel:
		_hint.text = TRAVEL_HINT if _view.travel.can_travel() else NO_TRAVEL_HINT


func go_back() -> void:
	if _travel_mode:
		menu.close()
	else:
		super()


func _on_travel_chosen(cell: Vector2i) -> void:
	var map_room := _map.room_at(cell)
	if map_room:
		Events.travel_requested.emit(map_room.path, cell)


func _legend(entries: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for entry: Array in entries:
		var swatch := ColorRect.new()
		swatch.color = entry[1]
		swatch.custom_minimum_size = Vector2(4, 4)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var label := Label.new()
		label.text = entry[0]
		row.add_child(swatch)
		row.add_child(label)
	return row


func _on_picking_changed(picking: bool) -> void:
	_hint.text = PICK_HINT if picking else HINT


func _on_zone_changed(zone: String) -> void:
	_zone.text = zone if zone != "" else " "
