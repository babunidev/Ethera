extends RefCounted
class_name EtheraCatalog

var traits: Dictionary = {}
var equipment_slots: Dictionary = {}
var body_regions: Dictionary = {}
var skill_phases: Dictionary = {}
var interactions: Dictionary = {}
var item_templates: Dictionary = {}
var states: Dictionary = {}
var milestone1_world: Dictionary = {}

var presentation_assets_path: String = ""

func load_from_res() -> Error:
	var index: Variant = _read_json("res://data/content_index.json")
	if typeof(index) != TYPE_DICTIONARY:
		push_error("EtheraCatalog: content_index.json is missing or invalid")
		return ERR_FILE_CORRUPT
	var files: Dictionary = index.get("files", {})
	presentation_assets_path = str(files.get("presentation_assets", ""))
	var collections := {
		"traits": ["traits", "traits"],
		"equipment_slots": ["slots", "equipment_slots"],
		"body_regions": ["regions", "body_regions"],
		"skill_phases": ["phases", "skill_phases"],
		"interactions": ["interactions", "interactions"],
		"item_templates": ["templates", "item_templates"],
		"states": ["states", "states"],
	}
	for file_key in collections.keys():
		var entry: Array = collections[file_key]
		var parsed: Variant = _read_json(str(files.get(file_key, "")))
		if typeof(parsed) != TYPE_DICTIONARY or not parsed.has(str(entry[0])):
			push_error("EtheraCatalog: %s is missing or has no '%s' array" % [file_key, str(entry[0])])
			return ERR_FILE_CORRUPT
		set(str(entry[1]), _index_by_id(parsed.get(str(entry[0]), [])))
	var world: Variant = _read_json(str(files.get("milestone1_world", "")))
	if typeof(world) != TYPE_DICTIONARY or not world.has("entities"):
		push_error("EtheraCatalog: milestone1 world is missing or has no entities")
		return ERR_FILE_CORRUPT
	milestone1_world = world
	return OK


func get_body_region(region_id: String) -> Dictionary:
	return body_regions.get(region_id, {})


func get_interaction(interaction_id: String) -> Dictionary:
	return interactions.get(interaction_id, {})


func get_skill_phase(phase_id: String) -> Dictionary:
	return skill_phases.get(phase_id, {})


func get_item_template(template_id: String) -> Dictionary:
	return item_templates.get(template_id, {})


func get_slot(slot_id: String) -> Dictionary:
	return equipment_slots.get(slot_id, {})


func _index_by_id(items: Variant) -> Dictionary:
	var mapped: Dictionary = {}
	if typeof(items) != TYPE_ARRAY:
		return mapped
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			mapped[str(item["id"])] = item
	return mapped


func _read_json(path: String) -> Variant:
	if path.is_empty():
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		push_error("EtheraCatalog: failed to read %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("EtheraCatalog: failed to parse %s" % path)
		return {}
	return parsed
