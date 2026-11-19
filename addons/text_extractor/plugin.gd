@tool
extends EditorPlugin
## Registers `TextParser` with the editor's POT generation.

const TextParser := preload("res://addons/text_extractor/text_parser.gd")

var _parser := TextParser.new()


func _enter_tree() -> void:
	add_translation_parser_plugin(_parser)


func _exit_tree() -> void:
	remove_translation_parser_plugin(_parser)
