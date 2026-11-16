class_name CurrencyCounter
extends Label
## The currency the player carries, shown as a number in the HUD. It
## flashes when the amount goes up. Driven by
## `Events.player_currency_changed`, never by the player directly.

## Seconds the number flashes after a gain.
@export var flash_time := 0.3
@export var normal_color := Color("d89a3a")
@export var flash_color := Color("fff2c8")

var _amount := -1
var _flash := 0.0


func _ready() -> void:
	Events.player_currency_changed.connect(_on_player_currency_changed)
	set_process(false)
	_paint()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if _flash == 0.0:
		set_process(false)
	_paint()


func _paint() -> void:
	add_theme_color_override(&"font_color", flash_color if _flash > 0.0 else normal_color)


func _on_player_currency_changed(amount: int) -> void:
	if _amount >= 0 and amount > _amount:
		_flash = flash_time
		set_process(true)
	_amount = amount
	text = str(amount)
	_paint()
