class_name MapMarkPainter
extends RefCounted
## Draws a player mark (`PlayerMarks.Kind`) as a 5×5 pixel icon on a dark
## backing, so it reads on any zone colour and apart from the plain
## squares of the map's own marks.

const BACKING := Color(0.05, 0.04, 0.07)
const ICONS := {
	PlayerMarks.Kind.CHEST: [".###.", "#...#", "#####", "#...#", "#####"],
	PlayerMarks.Kind.QUESTION: [".###.", "#...#", "..##.", ".....", "..#.."],
	PlayerMarks.Kind.ENEMY: ["#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
	PlayerMarks.Kind.PERSON: ["..#..", "#####", "..#..", ".#.#.", ".#.#."],
	PlayerMarks.Kind.BLUE: ["..#..", ".###.", "#####", ".###.", "..#.."],
	PlayerMarks.Kind.GREEN: ["..#..", ".###.", "#####", ".###.", "..#.."],
	PlayerMarks.Kind.RED: ["..#..", ".###.", "#####", ".###.", "..#.."],
}
const COLORS := {
	PlayerMarks.Kind.CHEST: Color(0.95, 0.75, 0.3),
	PlayerMarks.Kind.QUESTION: Color(1, 1, 1),
	PlayerMarks.Kind.ENEMY: Color(1, 0.35, 0.3),
	PlayerMarks.Kind.PERSON: Color(0.95, 0.85, 0.7),
	PlayerMarks.Kind.BLUE: Color(0.35, 0.6, 1),
	PlayerMarks.Kind.GREEN: Color(0.4, 0.9, 0.4),
	PlayerMarks.Kind.RED: Color(1, 0.3, 0.35),
}
## Icon size (px), without the backing.
const SIZE := 5


## Draws `kind` centred on `center`.
static func draw_mark(canvas: CanvasItem, kind: int, center: Vector2) -> void:
	var top_left := (center - Vector2(SIZE, SIZE) * 0.5).floor()
	canvas.draw_rect(Rect2(top_left - Vector2.ONE, Vector2(SIZE + 2, SIZE + 2)), BACKING)
	var rows: Array = ICONS[kind]
	for y in SIZE:
		var row: String = rows[y]
		for x in SIZE:
			if row[x] == "#":
				canvas.draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), COLORS[kind])
