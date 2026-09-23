extends RefCounted
class_name EtheraTasks

# Needs, Common Tasks, and the reserved objective. Presentation asks through
# queries and the select_need / activate_task commands. It does not read this.

const OBJECTIVE_PREFIX := "trait.objective."
const LCG_A := 1103515245
const LCG_C := 12345

var world: EtheraWorld
var catalog: EtheraCatalog


func _init(loaded_world: EtheraWorld, loaded_catalog: EtheraCatalog) -> void:
	world = loaded_world
	catalog = loaded_catalog


func refresh(actor_id: String) -> void:
	var actor: Dictionary = world.get_entity(actor_id)
	if actor.is_empty() or str(actor.get("kind", "")) != "character":
		return
	_ensure_task_fields(actor)
	var before: String = "%s|%s|%s|%s" % [
		str(actor.get("needs", [])),
		str(actor.get("task_ids", [])),
		str(actor.get("active_task_id", "")),
		str(actor.get("task_objectives", {})),
	]
	var previous_needs: Array[String] = _string_list(actor.get("needs", []))
	var previous_tasks: Array[String] = _string_list(actor.get("task_ids", []))
	var previous_active: String = str(actor.get("active_task_id", ""))
	var previous_objectives: Dictionary = (actor.get("task_objectives", {}) as Dictionary).duplicate()
	var need_ids: Array[String] = _present_needs(actor)
	var eligible: Array[String] = _eligible_tasks(actor, need_ids)
	var kept: Array[String] = []
	for task_id in _string_list(actor.get("task_ids", [])):
		if eligible.has(task_id):
			kept.append(task_id)
		else:
			_release(actor, task_id)
	for task_id in eligible:
		if not kept.has(task_id):
			kept.append(task_id)
	actor["needs"] = need_ids
	actor["task_ids"] = kept
	var active: String = str(actor.get("active_task_id", ""))
	if not kept.has(active):
		if active != "":
			_release(actor, active)
		active = ""
	var forced: String = _blocking_task(actor, active, kept)
	if forced != "" and forced != active:
		if active != "":
			_release(actor, active)
		active = forced
	if active == "" and not kept.is_empty():
		active = _default_task(need_ids, kept)
	actor["active_task_id"] = active
	if active != "":
		_ensure_reservation(actor, active)
	var after: String = "%s|%s|%s|%s" % [
		str(actor.get("needs", [])),
		str(actor.get("task_ids", [])),
		str(actor.get("active_task_id", "")),
		str(actor.get("task_objectives", {})),
	]
	if before != after:
		world.bump(actor_id, EtheraIds.CHANGE_NEEDS)
	_note_transition(actor, previous_needs, previous_tasks, previous_active, previous_objectives)


func select_need(actor_id: String, need_id: String) -> void:
	refresh(actor_id)
	var actor: Dictionary = world.get_entity(actor_id)
	if actor.is_empty() or not _string_list(actor.get("needs", [])).has(need_id):
		return
	world.add_log("need", "Need selected: %s" % _need_name(need_id))
	var need: Dictionary = catalog.needs.get(need_id, {})
	var task_id: String = str(need.get("task_id", ""))
	if task_id == "" or not _string_list(actor.get("task_ids", [])).has(task_id):
		return
	var active: String = str(actor.get("active_task_id", ""))
	if active != "" and active == task_id:
		return
	_switch_to(actor, task_id)


func activate_task(actor_id: String, task_id: String) -> void:
	refresh(actor_id)
	var actor: Dictionary = world.get_entity(actor_id)
	if actor.is_empty() or not _string_list(actor.get("task_ids", [])).has(task_id):
		return
	world.add_log("task", "Task chosen: %s" % _task_name(task_id))
	if str(actor.get("active_task_id", "")) == task_id:
		return
	_switch_to(actor, task_id)


func orientation(actor_id: String) -> Dictionary:
	var guide: Dictionary = {
		"active": false,
		"entity_id": "",
		"x": 0.0,
		"y": 0.0,
		"z": 0.0,
		"actor_x": 0.0,
		"actor_z": 0.0,
		"bearing": 0.0,
		"cue_interval_ms": int(world.tuning.get("orientation_cue_interval_ms", 10000)),
		"wave_aside": float(world.tuning.get("orientation_wave_aside", 5.0)),
		"wave_travel": float(world.tuning.get("orientation_wave_travel", 5.0)),
		"glint_ahead": float(world.tuning.get("orientation_glint_ahead", 14.0)),
		"glint_travel": float(world.tuning.get("orientation_glint_travel", 3.0)),
		"cue_life_ms": int(world.tuning.get("orientation_cue_life_ms", 1600)),
	}
	var actor: Dictionary = world.get_entity(actor_id)
	if actor.is_empty():
		return guide
	var actor_pos: Vector3 = world.position_of(actor)
	guide["actor_x"] = actor_pos.x
	guide["actor_z"] = actor_pos.z
	var task_id: String = str(actor.get("active_task_id", ""))
	var objective_id: String = str((actor.get("task_objectives", {}) as Dictionary).get(task_id, ""))
	if task_id == "" or objective_id == "":
		return guide
	var point: Vector3 = _objective_point(objective_id)
	if point == Vector3.INF:
		return guide
	var dx: float = point.x - actor_pos.x
	var dz: float = point.z - actor_pos.z
	var bearing: float = 0.0
	if Vector2(dx, dz).length() > 0.001:
		bearing = EtheraWorld.quantize(atan2(dx, dz), EtheraWorld.ANGLE_QUANTUM)
	guide["active"] = true
	guide["entity_id"] = objective_id
	guide["x"] = point.x
	guide["y"] = point.y
	guide["z"] = point.z
	guide["bearing"] = bearing
	return guide


func panel_fields(actor_id: String) -> Dictionary:
	var actor: Dictionary = world.get_entity(actor_id)
	if actor.is_empty():
		return {}
	var need_records: Array[Dictionary] = []
	for need_id in _string_list(actor.get("needs", [])):
		var need: Dictionary = catalog.needs.get(need_id, {})
		need_records.append({
			"id": need_id,
			"name": str(need.get("name", need_id)),
			"description": str(need.get("description", "")),
			"important": bool(need.get("important", false)),
			"task_id": str(need.get("task_id", "")),
		})
	var active: String = str(actor.get("active_task_id", ""))
	var task_records: Array[Dictionary] = []
	for task_id in _string_list(actor.get("task_ids", [])):
		var task: Dictionary = catalog.tasks.get(task_id, {})
		task_records.append({
			"id": task_id,
			"name": str(task.get("name", task_id)),
			"active": task_id == active,
		})
	var objective_id: String = str((actor.get("task_objectives", {}) as Dictionary).get(active, ""))
	return {
		"needs": need_records,
		"tasks": task_records,
		"active_task_id": active,
		"checklist": _checklist(actor, active),
		"reserved_objective_id": objective_id,
	}


func _switch_to(actor: Dictionary, task_id: String) -> void:
	var previous_needs: Array[String] = _string_list(actor.get("needs", []))
	var previous_tasks: Array[String] = _string_list(actor.get("task_ids", []))
	var previous_active: String = str(actor.get("active_task_id", ""))
	var previous_objectives: Dictionary = (actor.get("task_objectives", {}) as Dictionary).duplicate()
	if previous_active != "" and previous_active != task_id:
		_release(actor, previous_active)
	actor["active_task_id"] = task_id
	_ensure_reservation(actor, task_id)
	world.bump(str(actor.get("id", "")), EtheraIds.CHANGE_NEEDS)
	_note_transition(actor, previous_needs, previous_tasks, previous_active, previous_objectives)


func _ensure_reservation(actor: Dictionary, task_id: String) -> void:
	var task: Dictionary = catalog.tasks.get(task_id, {})
	if str(task.get("hidden_solution", {}).get("type", "")) != "manifested_traits":
		_release(actor, task_id)
		return
	var objectives: Dictionary = actor.get("task_objectives", {})
	var current_id: String = str(objectives.get(task_id, ""))
	if current_id != "" and _solution_valid(world.get_entity(current_id), task):
		return
	if current_id != "":
		_clear_mark(current_id, str(task.get("objective_trait_id", "")))
		objectives.erase(task_id)
		actor["task_objectives"] = objectives
	var chosen: String = _choose_solution(actor, task)
	if chosen == "":
		return
	_mark(chosen, str(task.get("objective_trait_id", "")))
	objectives[task_id] = chosen
	actor["task_objectives"] = objectives


func _release(actor: Dictionary, task_id: String) -> void:
	var task: Dictionary = catalog.tasks.get(task_id, {})
	var objectives: Dictionary = actor.get("task_objectives", {})
	var entity_id: String = str(objectives.get(task_id, ""))
	if entity_id != "":
		_clear_mark(entity_id, str(task.get("objective_trait_id", "")))
	objectives.erase(task_id)
	actor["task_objectives"] = objectives


func _choose_solution(actor: Dictionary, task: Dictionary) -> String:
	var here: Array[String] = []
	var elsewhere: Array[String] = []
	for entity_id in world.entities.keys():
		var entity: Dictionary = world.get_entity(str(entity_id))
		if not _solution_free(entity, task):
			continue
		if _same_hex(actor, entity):
			here.append(str(entity_id))
		else:
			elsewhere.append(str(entity_id))
	here.sort()
	elsewhere.sort()
	if not here.is_empty():
		return here[_pick_index(here.size())]
	if not elsewhere.is_empty():
		return elsewhere[_pick_index(elsewhere.size())]
	return _place_fallback(actor, task)


func _solution_free(entity: Dictionary, task: Dictionary) -> bool:
	if not _solution_valid(entity, task):
		return false
	for trait_id in _string_list(entity.get("traits", [])):
		if trait_id.begins_with(OBJECTIVE_PREFIX):
			return false
	return true


func _solution_valid(entity: Dictionary, task: Dictionary) -> bool:
	if entity.is_empty() or not world.is_manifested(entity):
		return false
	var solution: Dictionary = task.get("hidden_solution", {})
	if str(solution.get("type", "")) != "manifested_traits":
		return false
	for trait_id in _string_list(solution.get("trait_ids", [])):
		if not world.has_trait(entity, trait_id):
			return false
	return true


func _place_fallback(actor: Dictionary, task: Dictionary) -> String:
	var fallback: Dictionary = task.get("fallback", {})
	if str(fallback.get("type", "")) != "replace_world_node_occupant":
		return ""
	var node_id: String = str(fallback.get("node_id", ""))
	if node_id == "":
		return ""
	var occupant_id: String = _manifested_occupant(node_id)
	var anchor_id: String = occupant_id if occupant_id != "" else _any_occupant(node_id)
	if anchor_id == "":
		return ""
	var anchor: Dictionary = world.get_entity(anchor_id)
	if world.is_manifested(anchor) and _has_objective_mark(anchor):
		return ""
	var position: Dictionary = (anchor.get("position", {}) as Dictionary).duplicate(true)
	var yaw: float = float(anchor.get("yaw", 0.0))
	var place_id: String = str(anchor.get("place_id", world.place_id))
	if world.is_manifested(anchor):
		_unmanifest_occupant(anchor)
	else:
		anchor["world_node_id"] = ""
	var rock_id: String = world.make_id("entity.shapeable_rock")
	world.add_entity({
		"id": rock_id,
		"kind": "world_object",
		"name": str(fallback.get("name", "Shapeable Rock")),
		"place_id": place_id,
		"traits": _string_list(fallback.get("traits", [])),
		"states": [],
		"manifested": true,
		"yields_template_id": str(fallback.get("yields_template_id", EtheraIds.TEMPLATE_STONE_CLUB)),
		"yields_base_color": str(fallback.get("yields_base_color", "slate")),
		"position": position,
		"yaw": yaw,
		"occupancy": {"radius": float(fallback.get("occupancy_radius", 0.55))},
		"world_node_id": node_id,
		"presentation": {"asset_id": str(fallback.get("asset_id", "asset.shapeable_rock"))},
	})
	return rock_id


func _manifested_occupant(node_id: String) -> String:
	var found: Array[String] = []
	for entity_id in world.entities.keys():
		var entity: Dictionary = world.get_entity(str(entity_id))
		if str(entity.get("world_node_id", "")) != node_id:
			continue
		if world.is_manifested(entity):
			found.append(str(entity_id))
	found.sort()
	if found.is_empty():
		return ""
	return found[0]


func _any_occupant(node_id: String) -> String:
	var found: Array[String] = []
	for entity_id in world.entities.keys():
		var entity: Dictionary = world.get_entity(str(entity_id))
		if str(entity.get("world_node_id", "")) == node_id:
			found.append(str(entity_id))
	found.sort()
	if found.is_empty():
		return ""
	return found[0]


func _unmanifest_occupant(occupant: Dictionary) -> void:
	var occupant_id: String = str(occupant.get("id", ""))
	for item_id in _string_list(occupant.get("contained_item_ids", [])):
		var item: Dictionary = world.get_entity(item_id)
		if item.is_empty():
			continue
		item["manifested"] = false
		item["holder_id"] = null
		world.bump(item_id, EtheraIds.CHANGE_MANIFESTATION)
	occupant["manifested"] = false
	occupant["world_node_id"] = ""
	world.bump(occupant_id, EtheraIds.CHANGE_MANIFESTATION)


func _has_objective_mark(entity: Dictionary) -> bool:
	for trait_id in _string_list(entity.get("traits", [])):
		if trait_id.begins_with(OBJECTIVE_PREFIX):
			return true
	return false


func _mark(entity_id: String, trait_id: String) -> void:
	if trait_id == "":
		return
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty():
		return
	var traits: Array[String] = _string_list(entity.get("traits", []))
	if traits.has(trait_id):
		return
	traits.append(trait_id)
	entity["traits"] = traits
	world.bump(entity_id, EtheraIds.CHANGE_TRAITS)


func _clear_mark(entity_id: String, trait_id: String) -> void:
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty() or trait_id == "":
		return
	var traits: Array[String] = _string_list(entity.get("traits", []))
	if not traits.has(trait_id):
		return
	traits.erase(trait_id)
	entity["traits"] = traits
	world.bump(entity_id, EtheraIds.CHANGE_TRAITS)


func _present_needs(actor: Dictionary) -> Array[String]:
	var present: Dictionary = {}
	for need_id in catalog.needs.keys():
		var need: Dictionary = catalog.needs[need_id]
		if _need_present(actor, need):
			present[str(need_id)] = true
	var ids: Array[String] = []
	for need_id in _string_list(actor.get("needs", [])):
		if present.has(need_id):
			ids.append(need_id)
			present.erase(need_id)
	var fresh: Array = present.keys()
	fresh.sort()
	for need_id in fresh:
		ids.append(str(need_id))
	return ids


func _eligible_tasks(actor: Dictionary, need_ids: Array[String]) -> Array[String]:
	var ids: Array[String] = []
	var ordered: Array = catalog.tasks.keys()
	ordered.sort()
	for task_id in ordered:
		var task: Dictionary = catalog.tasks[task_id]
		if not need_ids.has(str(task.get("need_id", ""))):
			continue
		var required: String = str(task.get("requires_trait_id", ""))
		if required != "" and not world.has_trait(actor, required):
			continue
		if _task_complete(actor, task):
			continue
		ids.append(str(task_id))
	return ids


func _need_present(actor: Dictionary, need: Dictionary) -> bool:
	var condition: Dictionary = need.get("present_while", {})
	match str(condition.get("type", "")):
		"lacks_possessed_item_trait":
			return not _possesses_trait(str(actor.get("id", "")), str(condition.get("trait_id", "")))
		_:
			return false


func _task_complete(actor: Dictionary, task: Dictionary) -> bool:
	var completion: Dictionary = task.get("completion", {})
	match str(completion.get("type", "")):
		"possesses_item_trait":
			return _possesses_trait(str(actor.get("id", "")), str(completion.get("trait_id", "")))
		_:
			return false


func _possesses_trait(actor_id: String, trait_id: String) -> bool:
	if trait_id == "":
		return false
	for entity_id in world.entities.keys():
		var entity: Dictionary = world.get_entity(str(entity_id))
		if not world.is_manifested(entity) or not world.has_trait(entity, trait_id):
			continue
		if str(entity.get("holder_id", "")) == actor_id:
			return true
	return false


func _blocking_task(actor: Dictionary, active: String, task_ids: Array[String]) -> String:
	if active == "":
		return ""
	for state_id in _string_list(actor.get("states", [])):
		var state: Dictionary = catalog.states.get(state_id, {})
		var blocked: Array[String] = _string_list(state.get("impossible_task_ids", []))
		if not blocked.has(active):
			continue
		var resolving: String = str(state.get("resolving_task_id", ""))
		if resolving != "" and task_ids.has(resolving):
			return resolving
	return ""


func _default_task(need_ids: Array[String], task_ids: Array[String]) -> String:
	for need_id in need_ids:
		var task_id: String = str(catalog.needs.get(need_id, {}).get("task_id", ""))
		if task_ids.has(task_id):
			return task_id
	return task_ids[0]


func _checklist(actor: Dictionary, task_id: String) -> Dictionary:
	var task: Dictionary = catalog.tasks.get(task_id, {})
	var known: Array[Dictionary] = []
	for raw in task.get("checklist", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var shard_id: String = str(raw.get("revealed_by_shard_id", ""))
		var shown: bool = bool(raw.get("known", false))
		if shard_id != "" and world.knows_shard(actor, shard_id):
			shown = true
		if not shown:
			continue
		known.append({
			"id": str(raw.get("id", "")),
			"text": str(raw.get("text", "")),
		})
	return {
		"goal": str(task.get("goal", task.get("name", ""))),
		"requirements": known,
	}


func _objective_point(entity_id: String) -> Vector3:
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty() or not world.is_manifested(entity):
		return Vector3.INF
	var holder_id: String = str(entity.get("holder_id", ""))
	if holder_id != "":
		var holder: Dictionary = world.get_entity(holder_id)
		if not holder.is_empty() and world.is_manifested(holder):
			return world.position_of(holder)
	return world.position_of(entity)


func _same_hex(actor: Dictionary, entity: Dictionary) -> bool:
	var actor_at: Vector3 = world.position_of(actor)
	var entity_at: Vector3 = world.position_of(entity)
	var actor_hex: Vector2i = EtheraHexCoords.world_to_axial(actor_at.x, actor_at.z)
	var entity_hex: Vector2i = EtheraHexCoords.world_to_axial(entity_at.x, entity_at.z)
	return actor_hex == entity_hex


func _pick_index(count: int) -> int:
	if count <= 1:
		return 0
	var seed: int = world.objective_pick_seed
	if seed == 0:
		seed = 1
	seed = (seed * LCG_A + LCG_C) & 0x7fffffff
	if seed == 0:
		seed = 1
	world.objective_pick_seed = seed
	return seed % count


func _ensure_task_fields(actor: Dictionary) -> void:
	if not actor.has("needs"):
		actor["needs"] = []
	if not actor.has("task_ids"):
		actor["task_ids"] = []
	if not actor.has("active_task_id"):
		actor["active_task_id"] = ""
	if typeof(actor.get("task_objectives", null)) != TYPE_DICTIONARY:
		actor["task_objectives"] = {}


func _note_transition(actor: Dictionary, previous_needs: Array[String], previous_tasks: Array[String], previous_active: String, previous_objectives: Dictionary) -> void:
	var needs: Array[String] = _string_list(actor.get("needs", []))
	for need_id in needs:
		if not previous_needs.has(need_id):
			world.add_log("need", "Need appeared: %s" % _need_name(need_id))
	for need_id in previous_needs:
		if not needs.has(need_id):
			world.add_log("need", "Need fulfilled: %s" % _need_name(need_id))
	var task_ids: Array[String] = _string_list(actor.get("task_ids", []))
	for task_id in previous_tasks:
		if task_ids.has(task_id):
			continue
		if _task_complete(actor, catalog.tasks.get(task_id, {})):
			world.add_log("task", "Task fulfilled: %s" % _task_name(task_id))
		else:
			world.add_log("task", "Task removed: %s" % _task_name(task_id))
	var active: String = str(actor.get("active_task_id", ""))
	if active != "" and active != previous_active:
		world.add_log("task", "Priority stone placed on %s" % _task_name(active))
	var now_id: String = ""
	if active != "":
		now_id = str((actor.get("task_objectives", {}) as Dictionary).get(active, ""))
	var then_id: String = ""
	if previous_active != "":
		then_id = str(previous_objectives.get(previous_active, ""))
	if now_id == then_id:
		return
	if now_id != "":
		world.add_log("objective", "Objective reserved: %s" % _entity_name(now_id))
	elif then_id != "":
		world.add_log("objective", "Objective released")


func _need_name(need_id: String) -> String:
	return str(catalog.needs.get(need_id, {}).get("name", need_id))


func _task_name(task_id: String) -> String:
	return str(catalog.tasks.get(task_id, {}).get("name", task_id))


func _entity_name(entity_id: String) -> String:
	var name: String = str(world.get_entity(entity_id).get("name", ""))
	return name if name != "" else entity_id


func _string_list(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(str(item))
	return result
