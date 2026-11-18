class_name ItemIcon
extends Control
## Draws an item's `icon`, or a placeholder until items have art: a
## shape per kind (a gem for charms, a blade for blades, a pouch for
## keepsakes, a lantern for relics, a scroll for dumas, a vial for quest
## items) with the first
## letter of the title in the corner (small icons only, where the shapes
## alone look alike).

const KIND_COLORS := {
	Item.Kind.CHARM: Color(0.95, 0.78, 0.4),
	Item.Kind.BLADE: Color(0.78, 0.84, 0.92),
	Item.Kind.KEEPSAKE: Color(0.72, 0.52, 0.32),
	Item.Kind.RELIC: Color(0.7, 0.85, 0.75),
	Item.Kind.DUMA: Color(0.62, 0.7, 1.0),
	Item.Kind.QUEST: Color(0.55, 0.85, 0.9),
}
const LETTER_COLOR := Color(1, 0.95, 0.85, 0.9)
## Icons taller than this (px) skip the letter.
const LETTER_MAX_SIZE := 30.0

var item: Item:
	set(value):
		item = value
		queue_redraw()
## Draws the item darker, for an item shown but not usable.
var dimmed := false:
	set(value):
		dimmed = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if item == null:
		return
	var tint := Color(0.5, 0.5, 0.5) if dimmed else Color.WHITE
	if item.icon:
		draw_texture_rect(item.icon, Rect2(Vector2.ZERO, size), false, tint)
		return
	var color: Color = KIND_COLORS[item.kind] * tint
	var center := size / 2.0
	var r := minf(size.x, size.y) * 0.34
	match item.kind:
		Item.Kind.CHARM:
			_draw_gem(center, r, color)
		Item.Kind.BLADE:
			_draw_blade(center, r, color)
		Item.Kind.KEEPSAKE:
			_draw_pouch(center, r, color)
		Item.Kind.RELIC:
			_draw_lantern(center, r, color)
		Item.Kind.DUMA:
			_draw_scroll(center, r, color)
		Item.Kind.QUEST:
			_draw_vial(center, r, color)
	if size.y > LETTER_MAX_SIZE:
		return
	var font := get_theme_default_font()
	var font_size := maxi(int(size.y * 0.3), 6)
	var spot := Vector2(size.x * 0.62, size.y - 2.0)
	draw_string(
		font,
		spot,
		item.title.left(1),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		LETTER_COLOR * tint
	)


func _draw_gem(c: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array(
		[c + Vector2(0, -r), c + Vector2(r * 0.8, 0), c + Vector2(0, r), c + Vector2(-r * 0.8, 0)]
	)
	draw_colored_polygon(points, color)
	draw_line(c + Vector2(0, -r), c + Vector2(0, r), color.darkened(0.3))


func _draw_blade(c: Vector2, r: float, color: Color) -> void:
	var width := maxf(r * 0.3, 2.0)
	draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r, -r), color, width)
	draw_line(
		c + Vector2(-r * 0.75, r * 0.15),
		c + Vector2(-r * 0.15, r * 0.75),
		color.darkened(0.3),
		width
	)
	draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(-r, r), color.darkened(0.5), width)


func _draw_pouch(c: Vector2, r: float, color: Color) -> void:
	draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.4), Vector2(r * 1.6, r * 1.3)), color)
	draw_rect(
		Rect2(c + Vector2(-r * 0.35, -r * 0.8), Vector2(r * 0.7, r * 0.4)), color.darkened(0.25)
	)


func _draw_lantern(c: Vector2, r: float, color: Color) -> void:
	draw_arc(
		c + Vector2(0, -r * 0.75), r * 0.25, PI, TAU, 8, color.darkened(0.3), maxf(r * 0.12, 1.0)
	)
	draw_rect(
		Rect2(c + Vector2(-r * 0.55, -r * 0.6), Vector2(r * 1.1, r * 0.2)), color.darkened(0.3)
	)
	draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.4), Vector2(r * 0.9, r * 1.1)), color)
	draw_rect(
		Rect2(c + Vector2(-r * 0.2, -r * 0.2), Vector2(r * 0.4, r * 0.7)), color.lightened(0.6)
	)
	draw_rect(
		Rect2(c + Vector2(-r * 0.55, r * 0.7), Vector2(r * 1.1, r * 0.2)), color.darkened(0.3)
	)


func _draw_scroll(c: Vector2, r: float, color: Color) -> void:
	draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.7), Vector2(r * 1.2, r * 1.4)), color)
	var roll := color.darkened(0.3)
	draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.9), Vector2(r * 1.6, r * 0.3)), roll)
	draw_rect(Rect2(c + Vector2(-r * 0.8, r * 0.6), Vector2(r * 1.6, r * 0.3)), roll)
	for i in 3:
		var y := -r * 0.3 + r * 0.3 * i
		draw_line(c + Vector2(-r * 0.35, y), c + Vector2(r * 0.35, y), roll)


func _draw_vial(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c + Vector2(0, r * 0.35), r * 0.6, color)
	draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.7), Vector2(r * 0.4, r * 0.6)), color)
	draw_rect(
		Rect2(c + Vector2(-r * 0.3, -r * 0.95), Vector2(r * 0.6, r * 0.25)), color.darkened(0.4)
	)
	draw_circle(c + Vector2(-r * 0.2, r * 0.2), r * 0.15, color.lightened(0.6))
