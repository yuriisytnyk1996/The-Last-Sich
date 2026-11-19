class_name MapScreen
extends MenuScreen
## The pause menu's map page: the zone under the cursor and how much of
## the world is explored (`WorldMap.completion()`), the `MapView` and a
## legend. Opened from the pause screen or straight from the
## `map` action (M / Back).
##
## In travel mode (opened by kneeling at a rest point, see `KneelScreen`)
## the cursor hops between rest points (`MapTravel`). Attack on one asks
## the world to travel there (`Events.travel_requested`); back closes the
## whole menu, so the player rises.

const VIEW_SIZE := Vector2(480, 216)

var _map: WorldMap
var _zone: Label
var _hint: Label
var _view := MapView.new()
var _travel_mode := false


func _init(map: WorldMap, travel_mode := false) -> void:
	_map = map
	_travel_mode = travel_mode


func _build() -> void:
	add_title(tr("Travel") if _travel_mode else tr("Map"))
	_zone = add_text("")
	_view.custom_minimum_size = VIEW_SIZE
	_map.refresh()
	_view.setup(_map, _travel_mode)
	_view.zone_changed.connect(_on_zone_changed)
	_view.travel_chosen.connect(_on_travel_chosen)
	add_child(_view)
	add_gap(2)
	for entries: Array in _legend_rows():
		add_child(_legend(entries))
	_hint = add_text(_look_hint())
	_view.picking_changed.connect(_on_picking_changed)
	_on_zone_changed("")


func _process(_delta: float) -> void:
	if _view.travel:
		if _view.travel.can_travel():
			_hint.text = tr("Move: choose   Attack: travel   Back: rise")
		else:
			_hint.text = tr("Move: choose   Back: rise")


func go_back() -> void:
	if _travel_mode:
		menu.close()
	else:
		super()


func _on_travel_chosen(cell: Vector2i) -> void:
	var map_room := _map.room_at(cell)
	if map_room:
		Events.travel_requested.emit(map_room.path, cell)


## Two rows, so the legend fits the screen width.
func _legend_rows() -> Array:
	var marks := MapView.MARK_COLORS
	return [
		[
			[tr("You"), MapView.PLAYER_COLOR],
			[tr("Rest point"), marks[MapRoom.Mark.REST_POINT]],
			[tr("Shrine"), marks[MapRoom.Mark.SHRINE]],
			[tr("Shop"), marks[MapRoom.Mark.SHOP]],
			[tr("Cleanse"), marks[MapRoom.Mark.CLEANSE]],
		],
		[
			[tr("Upgrade"), marks[MapRoom.Mark.UPGRADE]],
			[tr("Door"), marks[MapRoom.Mark.DOOR]],
			[tr("Death mark"), marks[MapRoom.Mark.DEATH_MARK]],
		],
	]


func _look_hint() -> String:
	return tr("Move: look around   Jump: zoom   Attack: mark   Back: close")


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
	_hint.text = tr("Move: choose   Attack: place   Back: cancel") if picking else _look_hint()


func _on_zone_changed(zone: String) -> void:
	var explored := tr("%d%% explored") % floori(_map.completion() * 100.0)
	_zone.text = "%s   %s" % [tr(zone), explored] if zone != "" else explored
