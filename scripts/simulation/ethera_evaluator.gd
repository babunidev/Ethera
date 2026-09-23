extends RefCounted
class_name EtheraEvaluator

var world: EtheraWorld
var cache: Dictionary = {}

func _init(world_state: EtheraWorld) -> void:
	world = world_state


func available_interactions(actor_id: String, target_id: String) -> Array[Dictionary]:
	var actor: Dictionary = world.get_entity(actor_id)
	var target: Dictionary = world.get_entity(target_id)
	if actor.is_empty() or target.is_empty():
		return []
	if not _cache_valid(actor_id, target_id):
		cache[_key(actor_id, target_id)] = {
			"actor_versions": world.versions_of(actor_id),
			"target_versions": world.versions_of(target_id),
			"results": _compute(actor, target),
		}
	return (cache[_key(actor_id, target_id)]["results"] as Array).duplicate(true)


func is_available(actor_id: String, target_id: String, interaction_id: String) -> bool:
	for entry in available_interactions(actor_id, target_id):
		if str(entry.get("id", "")) == interaction_id:
			return true
	return false


func hover_for(actor_id: String, target_id: String) -> Dictionary:
	var actor: Dictionary = world.get_entity(actor_id)
	var target: Dictionary = world.get_entity(target_id)
	if actor.is_empty() or target.is_empty():
		return {"kind": EtheraIds.HOVER_NONE}
	if _is_closed_container(target):
		return {"kind": EtheraIds.HOVER_OPEN, "target_id": target_id}
	if _is_loose_compatible_item(actor, target):
		var slot_id: String = str(target.get("equipment_slot_id", EtheraIds.SLOT_SMALL_WEAPON))
		if world.equipped_item_id(actor, slot_id) == "":
			return {"kind": EtheraIds.HOVER_PICKUP, "slot_id": slot_id, "target_id": target_id}
		return {"kind": EtheraIds.HOVER_SWAP, "slot_id": slot_id, "target_id": target_id}
	if _is_discoverable_landmark(actor, target):
		return {"kind": EtheraIds.HOVER_DISCOVER, "target_id": target_id}
	var actions: Array[Dictionary] = available_interactions(actor_id, target_id)
	if not actions.is_empty():
		return {"kind": EtheraIds.HOVER_INTERACT, "target_id": target_id, "actions": actions}
	return {"kind": EtheraIds.HOVER_NONE}


func first_eligible_shard(actor: Dictionary, target: Dictionary) -> String:
	var found: Array[String] = eligible_shards(actor, target, 1)
	return found[0] if not found.is_empty() else ""


func eligible_shards(actor: Dictionary, target: Dictionary, limit: int = 1) -> Array[String]:
	var found: Array[String] = []
	for shard_id in world.known_shards(actor):
		if world.knows_shard(target, shard_id):
			continue
		found.append(str(shard_id))
		if found.size() >= max(limit, 0):
			break
	return found


func _compute(actor: Dictionary, target: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for interaction_id in world.catalog.interactions.keys():
		var definition: Dictionary = world.catalog.get_interaction(str(interaction_id))
		if definition.is_empty():
			continue
		if _matches_definition(actor, target, definition) and not _blocked(actor, definition):
			results.append({
				"id": str(definition["id"]),
				"name": str(definition.get("name", definition["id"])),
				"skill_phase_id": str(definition.get("skill_phase_id", "")),
			})
	return results


func _matches_definition(actor: Dictionary, target: Dictionary, definition: Dictionary) -> bool:
	var groups: Array = definition.get("requirement_groups", [])
	if groups.is_empty():
		return false
	for group in groups:
		if _matches_group(actor, target, group):
			return true
	return false


func _matches_group(actor: Dictionary, target: Dictionary, group: Dictionary) -> bool:
	return _matches_conditions(actor, target, group.get("actor", []), true) and _matches_conditions(actor, target, group.get("target", []), false)


func _matches_conditions(actor: Dictionary, target: Dictionary, conditions: Variant, on_actor: bool) -> bool:
	if typeof(conditions) != TYPE_ARRAY:
		return true
	var subject: Dictionary = actor if on_actor else target
	for condition in conditions:
		if typeof(condition) != TYPE_DICTIONARY:
			return false
		if not _matches_condition(actor, target, subject, condition):
			return false
	return true


func _matches_condition(actor: Dictionary, target: Dictionary, subject: Dictionary, condition: Dictionary) -> bool:
	var kind: String = str(condition.get("type", ""))
	match kind:
		"has_trait":
			return world.has_trait(subject, str(condition.get("trait_id", "")))
		"healthy_region":
			return world.region_condition(subject, str(condition.get("region_id", ""))) == "healthy"
		"manifested":
			return world.is_manifested(subject) == bool(condition.get("manifested", true))
		"actor_has_shard_unknown_to_target":
			return first_eligible_shard(actor, target) != ""
		"has_equipped":
			var slot_id: String = str(condition.get("slot_id", ""))
			var item_id: String = world.equipped_item_id(subject, slot_id)
			if item_id == "":
				return false
			var trait_id: String = str(condition.get("trait_id", ""))
			return trait_id == "" or world.has_trait(world.get_entity(item_id), trait_id)
		"knows_discovery_of_target":
			return not _place_undiscovered_by(actor, target)
		_:
			return false


func _blocked(actor: Dictionary, definition: Dictionary) -> bool:
	var interaction_id: String = str(definition.get("id", ""))
	for state_id in actor.get("states", []):
		var state: Dictionary = world.catalog.states.get(str(state_id), {})
		if state.is_empty():
			continue
		if _string_has(state.get("blocked_interaction_ids", []), interaction_id):
			return true
		for trait_id in state.get("blocked_trait_ids", []):
			if _requires_trait(definition, str(trait_id)):
				return true
	return false


func _requires_trait(definition: Dictionary, trait_id: String) -> bool:
	for group in definition.get("requirement_groups", []):
		for condition in group.get("actor", []):
			if str(condition.get("type", "")) == "has_trait" and str(condition.get("trait_id", "")) == trait_id:
				return true
	return false


func _is_discoverable_landmark(actor: Dictionary, target: Dictionary) -> bool:
	if float(target.get("discovery_radius", 0.0)) <= 0.0 or not world.is_manifested(target):
		return false
	return _place_undiscovered_by(actor, target)


func _is_undiscovered_place(actor: Dictionary, target: Dictionary) -> bool:
	var radius: float = float(target.get("discovery_radius", 0.0))
	if radius <= 0.0 or not world.is_manifested(target) or not world.is_manifested(actor):
		return false
	var dx: float = world.position_of(target).x - world.position_of(actor).x
	var dz: float = world.position_of(target).z - world.position_of(actor).z
	if Vector2(dx, dz).length() > radius:
		return false
	return _place_undiscovered_by(actor, target)


func _place_undiscovered_by(actor: Dictionary, target: Dictionary) -> bool:
	if actor.is_empty():
		return true
	for shard_id in world.known_shards(actor):
		var shard: Dictionary = world.shards.get(str(shard_id), {})
		if str(shard.get("action_id", "")) != EtheraIds.ACTION_DISCOVERY:
			continue
		if (shard.get("target_ids", []) as Array).has(str(target.get("id", ""))):
			return false
	return true


func _is_closed_container(target: Dictionary) -> bool:
	if not EtheraIds.is_container_kind(target.get("kind", "")):
		return false
	if not world.is_manifested(target):
		return false
	if bool(target.get("opened", false)):
		return false
	return world.has_trait(target, EtheraIds.TRAIT_CONTAINER)


func _is_loose_compatible_item(actor: Dictionary, target: Dictionary) -> bool:
	if str(target.get("kind", "")) != "item":
		return false
	if not world.is_manifested(target):
		return false
	if not EtheraIds.is_empty_slot(target.get("holder_id", null)):
		return false
	if not EtheraIds.is_empty_slot(target.get("container_id", null)):
		return false
	var slot_id: String = str(target.get("equipment_slot_id", ""))
	if slot_id == "" or not actor.get("equipment", {}).has(slot_id):
		return false
	var slot: Dictionary = world.catalog.get_slot(slot_id)
	for trait_id in slot.get("compatible_traits", []):
		if world.has_trait(target, str(trait_id)):
			return true
	return false


func _cache_valid(actor_id: String, target_id: String) -> bool:
	var key: String = _key(actor_id, target_id)
	if not cache.has(key):
		return false
	var entry: Dictionary = cache[key]
	return _versions_equal(entry.get("actor_versions", {}), world.versions_of(actor_id)) and _versions_equal(entry.get("target_versions", {}), world.versions_of(target_id))


func _versions_equal(left: Dictionary, right: Dictionary) -> bool:
	for category in left.keys():
		if int(left.get(category, -1)) != int(right.get(category, -2)):
			return false
	return left.size() == right.size()


func _key(actor_id: String, target_id: String) -> String:
	return "%s|%s" % [actor_id, target_id]


func _string_has(values: Variant, needle: String) -> bool:
	if typeof(values) != TYPE_ARRAY:
		return false
	for value in values:
		if str(value) == needle:
			return true
	return false
