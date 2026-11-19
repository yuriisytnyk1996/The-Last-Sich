class_name ConfirmScreen
extends MenuScreen
## Asks before something that can't be undone. "No" is focused first, so
## a stray press of accept is harmless.

var _question: String
var _on_yes: Callable


func _init(question: String, on_yes: Callable) -> void:
	_question = question
	_on_yes = on_yes


func _build() -> void:
	add_text(_question)
	add_gap()
	add_button(tr("No"), go_back)
	add_button(tr("Yes"), _on_yes)
