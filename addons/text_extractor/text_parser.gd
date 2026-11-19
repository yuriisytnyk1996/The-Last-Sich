@tool
extends EditorTranslationParserPlugin
## Collects player-facing text from `.tres` and `.tscn` files for POT
## generation (Project Settings > Localization > Template Generation).
##
## Godot's own parsers skip custom resources and custom node properties,
## so `PROPERTIES` names them here. A parser for `.tscn` replaces Godot's
## scene parser, so the Control text that one reads (`CONTROL_TEXT`) is
## read here too. Resources embedded in a file are searched as well;
## resources in their own file are read when that file is parsed.

## Translatable properties by script class. Subclasses inherit them.
const PROPERTIES := {
	&"Dialogue": ["speaker", "lines"],
	&"DialogueChoice": ["text"],
	&"DialogueStep": ["speaker"],
	&"QuoteStep": ["text", "author"],
	&"TitleStep": ["title", "subtitle"],
	&"StoryOutcome": ["message"],
	&"Tip": ["title", "text"],
	&"Item": ["title", "description", "lore"],
	&"PlayerSkill": ["title", "description"],
	&"CrtPreset": ["display_name"],
	&"Npc": ["display_name"],
	&"Boss": ["display_name"],
	&"Room": ["map_zone"],
}
## Control properties Godot's scene parser reads (`String.match` patterns).
const CONTROL_TEXT: PackedStringArray = ["text", "*_text", "title"]


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["tres", "tscn"])


func _parse_file(path: String) -> Array[PackedStringArray]:
	var found: Array[PackedStringArray] = []
	var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource is PackedScene:
		_parse_scene((resource as PackedScene).get_state(), found)
	elif resource:
		_parse_resource(resource, found)
	return found


func _parse_scene(state: SceneState, found: Array[PackedStringArray]) -> void:
	for node in state.get_node_count():
		var wanted := _properties_of(_node_script(state, node))
		var control := ClassDB.is_parent_class(_node_type(state, node), &"Control")
		control = control and not _translation_off(state, node)
		for i in state.get_node_property_count(node):
			var property := state.get_node_property_name(node, i)
			var value: Variant = state.get_node_property_value(node, i)
			if property in wanted or (control and _is_control_text(property)):
				_add(value, property, found)
			for embedded in _embedded(value):
				_parse_resource(embedded, found)


func _parse_resource(resource: Resource, found: Array[PackedStringArray]) -> void:
	for property: String in _properties_of(resource.get_script()):
		_add(resource.get(property), property, found)
	for info in resource.get_property_list():
		if info.usage & PROPERTY_USAGE_STORAGE and info.name != "script":
			for embedded in _embedded(resource.get(info.name)):
				_parse_resource(embedded, found)


func _add(value: Variant, property: String, found: Array[PackedStringArray]) -> void:
	var texts := [value]
	if value is Array or value is PackedStringArray:
		texts = Array(value)
	for text: Variant in texts:
		if text is String and not (text as String).strip_edges().is_empty():
			found.append(PackedStringArray([text, "", "", property]))


## The resources inside `value` that were saved in this file.
func _embedded(value: Variant) -> Array[Resource]:
	var resources: Array[Resource] = []
	for item: Variant in value if value is Array else [value]:
		if item is Resource and not item is Script and _is_local(item):
			resources.append(item)
	return resources


func _is_local(resource: Resource) -> bool:
	return resource.resource_path.is_empty() or resource.resource_path.contains("::")


func _properties_of(script: Script) -> Array:
	var properties := []
	while script:
		properties.append_array(PROPERTIES.get(script.get_global_name(), []))
		script = script.get_base_script()
	return properties


func _is_control_text(property: String) -> bool:
	for pattern in CONTROL_TEXT:
		if property.match(pattern):
			return true
	return false


## True when the node sets `auto_translate_mode` to Disabled (a number).
func _translation_off(state: SceneState, node: int) -> bool:
	for i in state.get_node_property_count(node):
		if state.get_node_property_name(node, i) == &"auto_translate_mode":
			return state.get_node_property_value(node, i) == Node.AUTO_TRANSLATE_MODE_DISABLED
	return false


## The node's script, also when it comes from an instanced scene.
func _node_script(state: SceneState, node: int) -> Script:
	for i in state.get_node_property_count(node):
		if state.get_node_property_name(node, i) == &"script":
			return state.get_node_property_value(node, i) as Script
	var instance := state.get_node_instance(node)
	return _node_script(instance.get_state(), 0) if instance else null


func _node_type(state: SceneState, node: int) -> StringName:
	var instance := state.get_node_instance(node)
	if state.get_node_type(node) == &"" and instance:
		return _node_type(instance.get_state(), 0)
	return state.get_node_type(node)
