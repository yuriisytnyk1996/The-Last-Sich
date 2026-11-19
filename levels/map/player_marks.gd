class_name PlayerMarks
extends RefCounted
## Marks the player places on the world map by hand: a chest to come back
## for, a question, a strong enemy, a person, or a plain coloured pin.
## One per cell. `WorldMap` owns them, says where one may go
## (`WorldMap.can_place_mark()`) and saves them.

enum Kind { CHEST, QUESTION, ENEMY, PERSON, BLUE, GREEN, RED }

## Map cell -> `Kind`.
var marks: Dictionary[Vector2i, int] = {}


func has(cell: Vector2i) -> bool:
	return marks.has(cell)


func place(cell: Vector2i, kind: Kind) -> void:
	marks[cell] = kind


func remove(cell: Vector2i) -> void:
	marks.erase(cell)


func to_data() -> Array:
	var data := []
	for cell in marks:
		data.append([cell.x, cell.y, marks[cell]])
	return data


func apply_data(data: Variant) -> void:
	marks.clear()
	if not data is Array:
		return
	for entry: Array in data:
		var kind := int(entry[2])
		if kind >= 0 and kind < Kind.size():
			marks[Vector2i(int(entry[0]), int(entry[1]))] = kind


## The kind's name, translated. Static, so `TranslationServer.tr()`
## stands in for `tr()`.
static func kind_name(kind: Kind) -> String:
	var names := {
		Kind.CHEST: TranslationServer.tr("Chest"),
		Kind.QUESTION: TranslationServer.tr("Question"),
		Kind.ENEMY: TranslationServer.tr("Enemy"),
		Kind.PERSON: TranslationServer.tr("Person"),
		Kind.BLUE: TranslationServer.tr("Blue pin"),
		Kind.GREEN: TranslationServer.tr("Green pin"),
		Kind.RED: TranslationServer.tr("Red pin"),
	}
	return names[kind]
