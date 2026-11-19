class_name TitleScreen
extends MenuScreen
## First page of the main menu. Continue loads the slot saved most
## recently and only shows when a slot is taken; Play opens the slot list.
## Quit is hidden on phones, where apps aren't closed from inside.

var _continue: Button


func _build() -> void:
	add_title("The Last Sich")
	add_gap(12)
	_continue = add_button(tr("Continue"), _on_continue)
	add_button(tr("Play"), func() -> void: menu.push(SlotsScreen.new()))
	add_button(tr("Options"), func() -> void: menu.push(OptionsScreen.new()))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		add_button(tr("Quit"), get_tree().quit)
	_refresh()


func _ready() -> void:
	super()
	# A slot may have been deleted on the slot pages.
	visibility_changed.connect(_refresh)


## The root screen stays put on back.
func go_back() -> void:
	pass


func _refresh() -> void:
	_continue.visible = _loadable_latest() >= 0


## The latest slot, or -1 when there is none or it can't be loaded.
func _loadable_latest() -> int:
	var latest := SaveManager.latest_slot()
	if latest >= 0 and SlotSummary.read(latest).state == SlotSummary.State.READY:
		return latest
	return -1


func _on_continue() -> void:
	var latest := _loadable_latest()
	if latest >= 0:
		SlotsScreen.play(get_tree(), latest, false)
