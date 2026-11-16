class_name PlayerWallet
extends Node
## The currency the player carries.
##
## Killed enemies add to it through `Events.currency_earned`, scaled by
## `gain_factor`, which death marks lower (see `DeathPenalty`). Every
## change is reported through `Events.player_currency_changed`, which
## drives the HUD.
##
## A global save system (see `SaveManager`): the amount is written to disk
## whenever the game saves.

var save_id := &"wallet"
var amount := 0
## Multiplier for currency earned from kills, set by `DeathPenalty`.
var gain_factor := 1.0


func _ready() -> void:
	Events.currency_earned.connect(_on_currency_earned)
	SaveManager.register(self)
	# Deferred: the HUD may come after the player in the tree and isn't ready yet.
	_announce.call_deferred()


## Adds `value` as is. Earned currency goes through `gain_factor` first.
func add(value: int) -> void:
	if value <= 0:
		return
	amount += value
	_announce()


## Takes `value` away if there is enough. Returns false and changes nothing
## otherwise.
func spend(value: int) -> bool:
	if value < 0 or value > amount:
		return false
	amount -= value
	_announce()
	return true


func get_save_data() -> Dictionary:
	return {"amount": amount}


func apply_save_data(data: Dictionary) -> void:
	amount = maxi(int(data.get("amount", 0)), 0)
	_announce()


func _on_currency_earned(value: int) -> void:
	add(roundi(value * gain_factor))


func _announce() -> void:
	Events.player_currency_changed.emit(amount)
