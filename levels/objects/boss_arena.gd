class_name BossArena
extends Node2D
## Runs a boss fight: walking into `Trigger` closes the gates under
## `Gates`, plays the `intro` cutscene if there is one, then wakes the
## `boss`. Killing it opens the gates for good and
## gives `item`; the boss's own `currency_reward` is paid as usual.
##
## If the player dies mid-fight, the gates open and the boss goes back to
## sleep (the room resets or reloads it). Put it in the room's `Logic`.
## Saved (`persistent` group): a beaten boss is gone and the arena stays
## open. Its gates aren't saved on their own: the arena decides.

## The boss was killed (never when a save restores the arena as won).
signal boss_beaten

## Arenas with a fight on are in this group, so other systems can tell a
## fight is running (the duma of return can't be sung in one).
const FIGHT_GROUP := &"boss_fights"

@export var boss: Boss
## Played once the gates are shut, before the boss wakes: a camera pan to
## the boss and its name. Optional; with a `flag` it plays only once.
@export var intro: Cutscene
## Given when the boss dies. Optional.
@export var item: Item
## Camera trauma when the boss dies (0 to 1).
@export var death_shake := 0.8
## Seconds the game freezes on the killing blow.
@export var death_hit_stop := 0.3
@export_group("Audio")
## Music per boss phase (`Boss.phase`): the first plays as the fight
## starts, the next when the boss reaches the next phase. A phase without
## one keeps the last. The room's music comes back after the fight.
@export var phase_music: Array[AudioStream] = []
@export var death_sound := &"boss_death"

var defeated := false
var _fighting := false
var _player: Player

@onready var trigger: Area2D = $Trigger
@onready var gates: Node = $Gates


func _ready() -> void:
	add_to_group(SaveManager.PERSISTENT_GROUP)
	for gate in _gates():
		gate.remove_from_group(SaveManager.PERSISTENT_GROUP)
	trigger.body_entered.connect(_on_trigger_body_entered)
	boss.health.died.connect(_on_boss_died)
	boss.phase_changed.connect(_play_phase_music)
	Events.player_died.connect(_on_player_died)


func get_save_data() -> Dictionary:
	return {"defeated": defeated}


func apply_save_data(data: Dictionary) -> void:
	if data.get("defeated", false):
		defeated = true
		_remove_boss(0.0)


func _on_trigger_body_entered(body: Node2D) -> void:
	if body is Player and not defeated and not _fighting:
		_player = body
		_fighting = true
		add_to_group(FIGHT_GROUP)
		_set_gates_open(false)
		if intro and intro.can_play():
			await intro.play()
		_play_phase_music(0)
		boss.awaken()
		Events.boss_fight_started.emit(
			boss.display_name, boss.health.current, boss.health.max_health
		)


func _on_boss_died() -> void:
	if not _fighting:
		return
	_fighting = false
	remove_from_group(FIGHT_GROUP)
	defeated = true
	_set_gates_open(true)
	Events.boss_fight_ended.emit()
	Events.camera_shake_requested.emit(death_shake)
	HitStop.freeze(death_hit_stop)
	Audio.play_at(death_sound, boss.global_position)
	Music.play_room_music(3.0)
	if item and is_instance_valid(_player):
		_player.inventory.add(item)
	_remove_boss(boss.damage.corpse_time + boss.damage.fade_time)
	boss_beaten.emit()


func _on_player_died() -> void:
	if not _fighting:
		return
	_fighting = false
	remove_from_group(FIGHT_GROUP)
	_set_gates_open(true)
	Events.boss_fight_ended.emit()
	Music.play_room_music()


func _play_phase_music(phase: int) -> void:
	if _fighting and phase < phase_music.size() and phase_music[phase]:
		Music.play(phase_music[phase], 0.5)


## Out of the `enemies` group at once, so a rest can't bring it back,
## then freed once its death fade is over.
func _remove_boss(delay: float) -> void:
	if not is_instance_valid(boss):
		return
	boss.remove_from_group(&"enemies")
	if delay <= 0.0:
		boss.queue_free()
	else:
		get_tree().create_timer(delay, false).timeout.connect(boss.queue_free)


func _set_gates_open(value: bool) -> void:
	for gate in _gates():
		gate.set_open(value)


func _gates() -> Array[Gate]:
	var found: Array[Gate] = []
	for child in gates.get_children():
		if child is Gate:
			found.append(child)
	return found
