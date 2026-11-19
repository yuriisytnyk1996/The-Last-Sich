class_name SlotSummary
extends RefCounted
## What the slot-select screen shows about one save slot: whether it can
## be loaded, the zone it was saved in, the play time and the currency.
##
## Read with `SaveFile.peek()`, so showing the slots never touches the
## files. The values come from the global systems' own save data
## (`world`, `play_clock`, `wallet`), so no system has to write a summary.

enum State { EMPTY, READY, OLD, DAMAGED }

var slot := 0
var state := State.EMPTY
var zone := ""
var play_time := 0.0
var currency := 0
## Share of the map explored, 0 to 1.
var explored := 0.0


static func read(which: int) -> SlotSummary:
	var summary := SlotSummary.new()
	summary.slot = which
	if not SaveFile.exists(which):
		return summary
	var data := SaveFile.peek(which)
	if data.is_empty():
		summary.state = State.DAMAGED
	elif int(data.get("version", 0)) != SaveManager.FORMAT_VERSION:
		summary.state = State.OLD
	else:
		summary.state = State.READY
		summary._fill(data.get("global", {}))
	return summary


func is_empty() -> bool:
	return state == State.EMPTY


## The zone saved in, or "Unknown" for saves made before zones were kept.
## Translated: the save keeps the English name.
func zone_name() -> String:
	return tr(zone) if zone != "" else tr("Unknown")


## "42%", rounded down like the map page.
func explored_text() -> String:
	return "%d%%" % floori(explored * 100.0)


## "1h 05m" or "12m".
func play_time_text() -> String:
	var minutes := int(play_time) / 60
	if minutes < 60:
		return tr("%dm") % minutes
	return tr("%dh %02dm") % [minutes / 60, minutes % 60]


func _fill(global: Variant) -> void:
	if not global is Dictionary:
		return
	zone = str(_section(global, "world").get("zone", ""))
	play_time = maxf(float(_section(global, "play_clock").get("seconds", 0.0)), 0.0)
	currency = maxi(int(_section(global, "wallet").get("amount", 0)), 0)
	explored = clampf(float(_section(global, "world_map").get("explored", 0.0)), 0.0, 1.0)


static func _section(global: Dictionary, key: String) -> Dictionary:
	var section: Variant = global.get(key)
	return section if section is Dictionary else {}
