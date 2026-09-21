extends RefCounted
class_name EtheraWorld

const HISTORY_LIMIT := 100
const DEV_LOG_LIMIT := 200

var catalog: EtheraCatalog
var entities: Dictionary = {}
var places: Dictionary = {}
var shards: Dictionary = {}
var world_time_ms: int = 0
var id_seq: int = 0
var inhabited_entity_id: String = ""
var place_id: String = ""
var tuning: Dictionary = {}
var change_versions: Dictionary = {}
var interaction_history: Dictionary = {}
var dev_log: Array[Dictionary] = []

func setup_milestone_1(loaded_catalog: EtheraCatalog) -> void:
	catalog = loaded_catalog
	var authored: Dictionary = catalog.milestone1_world.duplicate(true)
	place_id = str(authored.get("place_id", EtheraIds.PLACE_VILLAGE_CENTER))
	inhabited_entity_id = str(authored.get("inhabited_entity_id", EtheraIds.ENTITY_KHAR_MORR))
	tuning = authored.get("tuning", {})
	for place in authored.get("places", []):
		places[str(place["id"])] = place.duplicate(true)
	for raw in authored.get("entities", []):
		var entity: Dictionary = _normalize_entity(raw.duplicate(true))
		entities[str(entity["id"])] = entity
		_ensure_versions(str(entity["id"]))


func make_id(prefix: String) -> String:
	id_seq += 1
	return "%s.runtime.%d" % [prefix, id_seq]


func get_entity(entity_id: String) -> Dictionary:
	return entities.get(entity_id, {})


func inhabiting() -> Dictionary:
	return get_entity(inhabited_entity_id)


func bump(entity_id: String, category: String) -> void:
	_ensure_versions(entity_id)
	var versions: Dictionary = change_versions[entity_id]
	versions[category] = int(versions.get(category, 0)) + 1


func versions_of(entity_id: String) -> Dictionary:
	_ensure_versions(entity_id)
	return (change_versions[entity_id] as Dictionary).duplicate(true)


func has_trait(entity: Dictionary, trait_id: String) -> bool:
	return _string_array(entity.get("traits", [])).has(trait_id)


func is_manifested(entity: Dictionary) -> bool:
	return bool(entity.get("manifested", false))


func region_condition(entity: Dictionary, region_id: String) -> String:
	var regions: Dictionary = entity.get("body_regions", {})
	return str(regions.get(region_id, ""))


func known_shards(entity: Dictionary) -> Array[String]:
	return _string_array(entity.get("known_shard_ids", []))


func knows_shard(entity: Dictionary, shard_id: String) -> bool:
	return known_shards(entity).has(shard_id)


func set_region_condition(entity_id: String, region_id: String, condition: String) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	var regions: Dictionary = entity.get("body_regions", {})
	regions[region_id] = condition
	entity["body_regions"] = regions
	bump(entity_id, EtheraIds.CHANGE_INJURIES)


func add_state(entity_id: String, state_id: String) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	var states: Array[String] = _string_array(entity.get("states", []))
	if states.has(state_id):
		return
	states.append(state_id)
	entity["states"] = states
	bump(entity_id, EtheraIds.CHANGE_STATES)


func remove_state(entity_id: String, state_id: String) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	var states: Array[String] = _string_array(entity.get("states", []))
	states.erase(state_id)
	entity["states"] = states
	bump(entity_id, EtheraIds.CHANGE_STATES)


func grant_shard(entity_id: String, shard_id: String) -> bool:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return false
	if not has_trait(entity, EtheraIds.TRAIT_SHARD_HOLDER):
		return false
	var known: Array[String] = known_shards(entity)
	if known.has(shard_id):
		return false
	known.append(shard_id)
	entity["known_shard_ids"] = known
	bump(entity_id, EtheraIds.CHANGE_SHARDS)
	return true


func create_shard(fields: Dictionary) -> Dictionary:
	var shard: Dictionary = {
		"id": str(fields.get("id", make_id("shard"))),
		"actor_ids": _string_array(fields.get("actor_ids", [])),
		"target_ids": _string_array(fields.get("target_ids", [])),
		"action_id": str(fields.get("action_id", "")),
		"reaction_ids": _string_array(fields.get("reaction_ids", [EtheraIds.REACTION_NONE])),
		"result_ids": _string_array(fields.get("result_ids", [])),
		"place_id": str(fields.get("place_id", place_id)),
		"world_time": int(fields.get("world_time", world_time_ms)),
	}
	if shard["reaction_ids"].is_empty():
		shard["reaction_ids"] = [EtheraIds.REACTION_NONE] as Array[String]
	shards[str(shard["id"])] = shard
	return shard


func append_history(actor_id: String, entry: Dictionary) -> void:
	if not interaction_history.has(actor_id):
		interaction_history[actor_id] = [] as Array[Dictionary]
	var history: Array = interaction_history[actor_id]
	history.append(entry)
	while history.size() > HISTORY_LIMIT:
		history.remove_at(0)


func recent_interactions(actor_id: String) -> Array:
	return (interaction_history.get(actor_id, []) as Array).duplicate(true)


func add_log(kind: String, text: String, extra: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = extra.duplicate(true)
	entry["world_time"] = world_time_ms
	entry["kind"] = kind
	entry["text"] = text
	dev_log.append(entry)
	while dev_log.size() > DEV_LOG_LIMIT:
		dev_log.remove_at(0)
	return entry


func position_of(entity: Dictionary) -> Vector3:
	var pos: Dictionary = entity.get("position", {})
	return Vector3(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)), float(pos.get("z", 0.0)))


func set_position(entity_id: String, position: Vector3, yaw: float = NAN) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	entity["position"] = {"x": position.x, "y": position.y, "z": position.z}
	if not is_nan(yaw):
		entity["yaw"] = yaw


func equipped_item_id(entity: Dictionary, slot_id: String) -> String:
	var equipment: Dictionary = entity.get("equipment", {})
	if not equipment.has(slot_id):
		return ""
	var value: Variant = equipment[slot_id]
	if EtheraIds.is_empty_slot(value):
		return ""
	return str(value)


func set_equipped(entity_id: String, slot_id: String, item_id: Variant) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	var equipment: Dictionary = entity.get("equipment", {})
	equipment[slot_id] = item_id
	entity["equipment"] = equipment
	bump(entity_id, EtheraIds.CHANGE_INVENTORY)


func spawn_item_from_template(template_id: String, extra: Dictionary) -> Dictionary:
	var template: Dictionary = catalog.get_item_template(template_id).duplicate(true)
	var item: Dictionary = {
		"id": str(extra.get("id", make_id("entity.club"))),
		"kind": "item",
		"name": str(template.get("name", "Item")),
		"template_id": template_id,
		"place_id": str(extra.get("place_id", place_id)),
		"traits": _string_array(template.get("traits", [])),
		"condition": str(template.get("condition", "okay")),
		"equipment_slot_id": str(template.get("equipment_slot_id", EtheraIds.SLOT_SMALL_WEAPON)),
		"attachment": str(template.get("attachment", "back")),
		"base_color": str(extra.get("base_color", "")),
		"holder_id": extra.get("holder_id", null),
		"equipped_slot_id": extra.get("equipped_slot_id", null),
		"position": extra.get("position", {"x": 0.0, "y": 0.0, "z": 0.0}),
		"yaw": float(extra.get("yaw", 0.0)),
		"manifested": bool(extra.get("manifested", true)),
		"states": [],
		"presentation": template.get("presentation", {}).duplicate(true),
	}
	entities[str(item["id"])] = item
	_ensure_versions(str(item["id"]))
	return item


func _normalize_entity(entity: Dictionary) -> Dictionary:
	entity["traits"] = _string_array(entity.get("traits", []))
	entity["states"] = _string_array(entity.get("states", []))
	entity["known_shard_ids"] = _string_array(entity.get("known_shard_ids", []))
	entity["needed_shard_ids"] = _string_array(entity.get("needed_shard_ids", []))
	entity["known_interaction_ids"] = _string_array(entity.get("known_interaction_ids", []))
	if not entity.has("manifested"):
		entity["manifested"] = true
	if not entity.has("position"):
		entity["position"] = {"x": 0.0, "y": 0.0, "z": 0.0}
	if entity.get("kind", "") == "character" and not entity.has("equipment"):
		entity["equipment"] = {EtheraIds.SLOT_SMALL_WEAPON: null}
	return entity


func _ensure_versions(entity_id: String) -> void:
	if change_versions.has(entity_id):
		return
	change_versions[entity_id] = {
		EtheraIds.CHANGE_TRAITS: 0,
		EtheraIds.CHANGE_INVENTORY: 0,
		EtheraIds.CHANGE_NEEDS: 0,
		EtheraIds.CHANGE_SHARDS: 0,
		EtheraIds.CHANGE_STATES: 0,
		EtheraIds.CHANGE_INJURIES: 0,
		EtheraIds.CHANGE_RELATIONSHIPS: 0,
		EtheraIds.CHANGE_MANIFESTATION: 0,
	}


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		if item == null:
			continue
		result.append(str(item))
	return result
