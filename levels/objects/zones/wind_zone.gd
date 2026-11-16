@tool
class_name WindZone
extends AreaEffect
## Wind that pushes the player sideways, on the ground and in the air.
## Its speed is added to the speed the player runs or drifts at: running
## against it is slower, letting go carries the player along. Dashes,
## ladders and ledges ignore it.

const STREAK_SPACING := Vector2(24.0, 12.0)
const STREAK_LENGTH := 8.0

## Push in px/s. Positive blows right, negative left.
@export var strength := 60.0:
	set(value):
		strength = value
		queue_redraw()

var _drift := 0.0


func wind_speed() -> float:
	return strength


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_drift = fmod(_drift + strength * delta, STREAK_SPACING.x)
	queue_redraw()


func _get_color() -> Color:
	return Color(0.75, 0.85, 1.0, 0.08)


## Placeholder streaks that drift with the wind.
func _draw() -> void:
	super()
	var color := Color(0.85, 0.92, 1.0, 0.35)
	var row := 0
	var y := STREAK_SPACING.y / 2.0
	while y < size.y:
		var stagger := STREAK_SPACING.x / 2.0 if row % 2 == 1 else 0.0
		var x := fposmod(_drift + stagger, STREAK_SPACING.x) - STREAK_SPACING.x
		while x < size.x:
			var from := clampf(x, 0.0, size.x)
			var to := clampf(x + STREAK_LENGTH, 0.0, size.x)
			if to > from:
				draw_line(Vector2(from, y), Vector2(to, y), color)
			x += STREAK_SPACING.x
		y += STREAK_SPACING.y
		row += 1
