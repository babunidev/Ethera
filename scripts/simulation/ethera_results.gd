extends RefCounted
class_name EtheraResults

# Applies the authored results of a successful interaction and produces its single event
# record. Nothing here knows which interaction it is running: the vocabulary is the
# authored `results` list in data/interactions.json, and an unrecognized type fails
# closed so a typo cannot silently succeed.
#
# Design reference: 09_Technical/Entities_Interactions_and_Content_Authoring.md — results
# are changes to bodies, state, items and knowledge, and a successful action produces
# exactly one Shard after the final world result.

var world: EtheraWorld
var catalog: EtheraCatalog
var evaluator: EtheraEvaluator

func _init(target_world: EtheraWorld, target_catalog: EtheraCatalog, target_evaluator: EtheraEvaluator) -> void:
	world = target_world
	catalog = target_catalog
	evaluator = target_evaluator


# What the round must pick before the skill phase begins, if the interaction authors a
# selection. An authored selection that resolves to nothing fails the round.
func select_for(interaction_id: String, actor_id: String, target_id: String) -> String:
	var selection: Dictionary = catalog.get_interaction(interaction_id).get("selection", {})
	if selection.is_empty():
		return ""
	match str(selection.get("type", "")):
		EtheraIds.SELECT_FIRST_ELIGIBLE_SHARD:
			return evaluator.first_eligible_shard(
				_entity_for(str(selection.get("from", EtheraIds.ROLE_ACTOR)), actor_id, target_id),
				_entity_for(str(selection.get("against", EtheraIds.ROLE_TARGET)), actor_id, target_id)
			)
		_:
			return ""


func requires_selection(interaction_id: String) -> bool:
	return not (catalog.get_interaction(interaction_id).get("selection", {}) as Dictionary).is_empty()


# Returns {"ok": bool, "reason": String, "events": Array[Dictionary]}.
func resolve(round: Dictionary) -> Dictionary:
	var interaction_id: String = str(round.get("interaction_id", ""))
	var actor_id: String = str(round.get("actor_id", ""))
	var target_id: String = str(round.get("target_id", ""))
	var selected_shard_id: String = str(round.get("selected_shard_id", ""))
	var definition: Dictionary = catalog.get_interaction(interaction_id)
	var authored: Array = definition.get("results", [])
	if authored.is_empty():
		return _failed("no_authored_results")

	# Every result is checked before any is applied, so a malformed or impossible list
	# leaves the world untouched instead of half-changed with no record to show it.
	for entry in authored:
		if typeof(entry) != TYPE_DICTIONARY:
			return _failed("malformed_result")
		var problem: String = _validate_one(entry, actor_id, target_id, selected_shard_id)
		if problem != "":
			return _failed(problem)

	var events: Array[Dictionary] = []
	var result_ids: Array[String] = []
	for entry in authored:
		var applied: Dictionary = _apply_one(entry, actor_id, target_id, selected_shard_id)
		if not bool(applied.get("ok", false)):
			return _failed(str(applied.get("reason", "unknown_result")))
		events.append_array(applied.get("events", []) as Array[Dictionary])
		for produced in applied.get("result_ids", []) as Array:
			result_ids.append(str(produced))

	events.append_array(_write_record(definition, actor_id, target_id, result_ids))
	return {"ok": true, "reason": "", "events": events}


# Returns "" when the result can be applied, otherwise the failure reason.
func _validate_one(entry: Dictionary, actor_id: String, target_id: String, selected_shard_id: String) -> String:
	var type_id: String = str(entry.get("type", ""))
	var subject_id: String = _id_for(str(entry.get("entity", EtheraIds.ROLE_TARGET)), actor_id, target_id)
	if world.get_entity(subject_id).is_empty():
		return "missing_entity"
	match type_id:
		EtheraIds.RESULT_REMOVE_MANIFESTATION:
			return ""
		EtheraIds.RESULT_EQUIP_SPAWNED_ITEM:
			if catalog.get_item_template(_authored_or_field(entry, "template_id", "template_from", actor_id, target_id)).is_empty():
				return "missing_item_template"
			var slot_id: String = str(entry.get("slot_id", EtheraIds.SLOT_SMALL_WEAPON))
			var occupied: bool = world.equipped_item_id(world.get_entity(subject_id), slot_id) != ""
			if occupied and str(entry.get("displace_previous", "")) != "beside_actor":
				return "occupied_slot_without_displacement"
			return ""
		EtheraIds.RESULT_SHARE_SELECTED_SHARD:
			return "" if selected_shard_id != "" else "no_selected_shard"
		EtheraIds.RESULT_SHARE_ELIGIBLE_SHARDS:
			return "" if selected_shard_id != "" or not evaluator.eligible_shards(
				world.get_entity(actor_id),
				world.get_entity(subject_id),
				maxi(1, int(entry.get("limit", 1)))
			).is_empty() else "no_selected_shard"
		EtheraIds.RESULT_SET_BODY_REGION:
			if str(entry.get("region_id", "")) == "" or str(entry.get("condition", "")) == "":
				return "malformed_result"
			return "" if not catalog.get_body_region(str(entry.get("region_id", ""))).is_empty() else "missing_body_region"
		EtheraIds.RESULT_ADD_STATE, EtheraIds.RESULT_REMOVE_STATE:
			return "" if catalog.states.has(str(entry.get("state_id", ""))) else "missing_state"
		EtheraIds.RESULT_CONSUME_EQUIPPED_ITEM:
			var slot_id: String = str(entry.get("slot_id", ""))
			return "" if world.equipped_item_id(world.get_entity(subject_id), slot_id) != "" else "missing_equipped_item"
		EtheraIds.RESULT_GREET:
			return "" if str(entry.get("text", "")) != "" else "malformed_result"
		EtheraIds.RESULT_REVEAL_CONTAINER:
			return "" if not bool(world.get_entity(subject_id).get("opened", false)) else "already_open"
		_:
			return "unknown_result_type"


func _apply_one(entry: Dictionary, actor_id: String, target_id: String, selected_shard_id: String) -> Dictionary:
	var subject_id: String = _id_for(str(entry.get("entity", EtheraIds.ROLE_TARGET)), actor_id, target_id)
	match str(entry.get("type", "")):
		EtheraIds.RESULT_REMOVE_MANIFESTATION:
			return _remove_manifestation(subject_id)
		EtheraIds.RESULT_EQUIP_SPAWNED_ITEM:
			return _equip_spawned_item(entry, subject_id, actor_id, target_id)
		EtheraIds.RESULT_SHARE_SELECTED_SHARD:
			return _share_selected_shard(subject_id, selected_shard_id)
		EtheraIds.RESULT_SHARE_ELIGIBLE_SHARDS:
			return _share_eligible_shards(entry, actor_id, subject_id, selected_shard_id)
		EtheraIds.RESULT_SET_BODY_REGION:
			return _set_body_region(entry, subject_id)
		EtheraIds.RESULT_ADD_STATE:
			return _change_state(entry, subject_id, true)
		EtheraIds.RESULT_REMOVE_STATE:
			return _change_state(entry, subject_id, false)
		EtheraIds.RESULT_CONSUME_EQUIPPED_ITEM:
			return _consume_equipped_item(entry, subject_id)
		EtheraIds.RESULT_GREET:
			return _greet(entry, actor_id, target_id)
		EtheraIds.RESULT_REVEAL_CONTAINER:
			return _reveal_container(subject_id, actor_id)
		_:
			return {"ok": false, "reason": "unknown_result_type"}


func _remove_manifestation(entity_id: String) -> Dictionary:
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty():
		return {"ok": false, "reason": "missing_entity"}
	entity["manifested"] = false
	world.bump(entity_id, EtheraIds.CHANGE_MANIFESTATION)
	return {
		"ok": true,
		"events": [
			_event(EtheraIds.EVENT_MANIFESTATION, {"entity_id": entity_id, "manifested": false}),
			_log(EtheraIds.EVENT_MANIFESTATION, "%s manifestation removed" % entity.get("name", entity_id), {"entity_id": entity_id}),
		],
	}


func _equip_spawned_item(entry: Dictionary, holder_id: String, actor_id: String, target_id: String) -> Dictionary:
	var holder: Dictionary = world.get_entity(holder_id)
	if holder.is_empty():
		return {"ok": false, "reason": "missing_entity"}
	var template_id: String = _authored_or_field(entry, "template_id", "template_from", actor_id, target_id)
	if catalog.get_item_template(template_id).is_empty():
		return {"ok": false, "reason": "missing_item_template"}
	var slot_id: String = str(entry.get("slot_id", EtheraIds.SLOT_SMALL_WEAPON))
	var events: Array[Dictionary] = []
	var previous_id: String = world.equipped_item_id(holder, slot_id)
	if previous_id != "":
		match str(entry.get("displace_previous", "")):
			"beside_actor":
				events.append_array(_displace_beside(holder_id, previous_id, slot_id))
			_:
				return {"ok": false, "reason": "occupied_slot_without_displacement"}
	var item: Dictionary = world.spawn_item_from_template(template_id, {
		"base_color": _authored_or_field(entry, "base_color", "base_color_from", actor_id, target_id),
		"place_id": str(holder.get("place_id", world.place_id)),
		"position": holder.get("position", {"x": 0.0, "y": 0.0, "z": 0.0}),
		"holder_id": holder_id,
		"equipped_slot_id": slot_id,
		"manifested": true,
	})
	var item_id: String = str(item["id"])
	world.set_equipped(holder_id, slot_id, item_id)
	world.commit_item(EtheraIds.TX_EQUIP_SPAWNED, {
		"entity_id": holder_id,
		"item_id": item_id,
		"slot_id": slot_id,
		"displaced_item_id": previous_id,
	})
	events.append(_event(EtheraIds.EVENT_EQUIPMENT, {"entity_id": holder_id, "slot_id": slot_id, "item_id": item_id}))
	events.append(_log("item_created", "%s created and equipped" % item.get("name", item_id), {
		"item_id": item_id,
		"base_color": str(item.get("base_color", "")),
	}))
	return {"ok": true, "events": events, "result_ids": [item_id]}


func _share_eligible_shards(entry: Dictionary, actor_id: String, recipient_id: String, selected_shard_id: String) -> Dictionary:
	var limit: int = maxi(1, int(entry.get("limit", 1)))
	var shard_ids: Array[String] = evaluator.eligible_shards(
		world.get_entity(actor_id),
		world.get_entity(recipient_id),
		limit
	)
	if shard_ids.is_empty() and selected_shard_id != "":
		shard_ids.append(selected_shard_id)
	if shard_ids.is_empty():
		return {"ok": false, "reason": "no_selected_shard"}
	var events: Array[Dictionary] = []
	var result_ids: Array[String] = []
	for shard_id in shard_ids:
		var shared: Dictionary = _share_selected_shard(recipient_id, shard_id, false)
		if not bool(shared.get("ok", false)):
			return shared
		events.append_array(shared.get("events", []) as Array[Dictionary])
		for produced in shared.get("result_ids", []) as Array:
			result_ids.append(str(produced))
	var recipient: Dictionary = world.get_entity(recipient_id)
	var count: int = result_ids.size()
	events.append(_log("knowledge_shared", "Echo Imprint transferred %d Shard%s to %s" % [
		count,
		"" if count == 1 else "s",
		recipient.get("name", recipient_id),
	], {"count": count, "shard_ids": result_ids, "entity_id": recipient_id}))
	return {"ok": true, "events": events, "result_ids": result_ids}


func _share_selected_shard(recipient_id: String, shard_id: String, write_log: bool = true) -> Dictionary:
	if shard_id == "":
		return {"ok": false, "reason": "no_selected_shard"}
	var events: Array[Dictionary] = []
	# The transferred record keeps its own id and original timestamp; only the reference
	# is new. A recipient that already holds it is not an error.
	if world.grant_shard(recipient_id, shard_id):
		events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": recipient_id, "shard_id": shard_id, "granted": true}))
		if write_log:
			events.append(_log("knowledge_shared", "%s gained a reference to %s" % [
				world.get_entity(recipient_id).get("name", recipient_id),
				shard_id,
			], {"shard_id": shard_id, "entity_id": recipient_id}))
	return {"ok": true, "events": events, "result_ids": [shard_id]}


func _set_body_region(entry: Dictionary, entity_id: String) -> Dictionary:
	var region_id: String = str(entry.get("region_id", ""))
	var condition: String = str(entry.get("condition", ""))
	if region_id == "" or condition == "":
		return {"ok": false, "reason": "malformed_result"}
	if catalog.get_body_region(region_id).is_empty():
		return {"ok": false, "reason": "missing_body_region"}
	world.set_region_condition(entity_id, region_id, condition)
	return {
		"ok": true,
		"events": [_log("body_changed", "%s is now %s" % [region_id, condition], {"entity_id": entity_id, "region_id": region_id})],
	}


func _change_state(entry: Dictionary, entity_id: String, adding: bool) -> Dictionary:
	var state_id: String = str(entry.get("state_id", ""))
	if state_id == "" or not catalog.states.has(state_id):
		return {"ok": false, "reason": "missing_state"}
	if adding:
		world.add_state(entity_id, state_id)
	else:
		world.remove_state(entity_id, state_id)
	return {
		"ok": true,
		"events": [_log("state_changed", "%s %s %s" % [entity_id, "gained" if adding else "lost", state_id], {"entity_id": entity_id, "state_id": state_id})],
	}


func _consume_equipped_item(entry: Dictionary, holder_id: String) -> Dictionary:
	var slot_id: String = str(entry.get("slot_id", ""))
	var holder: Dictionary = world.get_entity(holder_id)
	var item_id: String = world.equipped_item_id(holder, slot_id)
	var item: Dictionary = world.get_entity(item_id)
	if item.is_empty():
		return {"ok": false, "reason": "missing_equipped_item"}
	item["holder_id"] = null
	item["equipped_slot_id"] = null
	item["manifested"] = false
	world.set_equipped(holder_id, slot_id, null)
	world.bump(item_id, EtheraIds.CHANGE_INVENTORY)
	world.bump(item_id, EtheraIds.CHANGE_MANIFESTATION)
	world.commit_item(EtheraIds.TX_CONSUME, {
		"entity_id": holder_id,
		"item_id": item_id,
		"slot_id": slot_id,
	})
	return {
		"ok": true,
		"events": [
			_event(EtheraIds.EVENT_MANIFESTATION, {"entity_id": item_id, "manifested": false}),
			_event(EtheraIds.EVENT_EQUIPMENT, {"entity_id": holder_id, "slot_id": slot_id, "item_id": ""}),
			_log("item_consumed", "%s was offered and is gone" % item.get("name", item_id), {"item_id": item_id, "slot_id": slot_id}),
		],
		"result_ids": [item_id],
	}


func _reveal_container(container_id: String, actor_id: String) -> Dictionary:
	var container: Dictionary = world.get_entity(container_id)
	if container.is_empty():
		return {"ok": false, "reason": "missing_entity"}
	if bool(container.get("opened", false)):
		return {"ok": false, "reason": "already_open"}
	container["opened"] = true
	world.bump(container_id, EtheraIds.CHANGE_MANIFESTATION)
	var events: Array[Dictionary] = []
	var origin: Vector3 = world.position_of(container)
	var drop_offset: Vector3 = _reveal_offset(actor_id, container)
	for item_id in container.get("contained_item_ids", []):
		var item: Dictionary = world.get_entity(str(item_id))
		if item.is_empty():
			continue
		item["manifested"] = true
		item["container_id"] = null
		item["holder_id"] = null
		item["position"] = EtheraWorld.quantized_point(origin + drop_offset)
		world.bump(str(item_id), EtheraIds.CHANGE_MANIFESTATION)
		events.append(_event(EtheraIds.EVENT_MANIFESTATION, {"entity_id": str(item_id), "manifested": true}))
	events.append(_log("container_opened", "Opened %s" % container.get("name", container_id), {"target_id": container_id}))
	return {"ok": true, "events": events, "result_ids": [EtheraIds.RESULT_DISCOVERED]}


func _reveal_offset(actor_id: String, container: Dictionary) -> Vector3:
	var origin: Vector3 = world.position_of(container)
	var look: Vector3 = origin - world.position_of(world.get_entity(actor_id))
	look.y = 0.0
	if look.length() < 0.001:
		look = Vector3(1.0, 0.0, 0.0)
	look = look.normalized()
	var right := Vector3(-look.z, 0.0, look.x)
	var distance: float = maxf(world.occupancy_radius(container) + 0.65, 0.9)
	var ignore: Array = [str(container.get("id", ""))]
	if _point_hits_occupancy(origin + right * distance, ignore):
		return -right * distance
	return right * distance


func _point_hits_occupancy(point: Vector3, ignore_ids: Array) -> bool:
	for blocker in world.blockers_near(ignore_ids):
		var dx: float = point.x - float(blocker.get("x", 0.0))
		var dz: float = point.z - float(blocker.get("z", 0.0))
		var radius: float = float(blocker.get("radius", 0.0)) + 0.12
		if dx * dx + dz * dz < radius * radius:
			return true
	return false


func _greet(entry: Dictionary, actor_id: String, target_id: String) -> Dictionary:
	var speaker_id: String = _id_for(str(entry.get("entity", EtheraIds.ROLE_ACTOR)), actor_id, target_id)
	var speaker: Dictionary = world.get_entity(speaker_id)
	if speaker.is_empty():
		return {"ok": false, "reason": "missing_entity"}
	var text: String = str(entry.get("text", "Hi"))
	var duration_ms: int = maxi(1, int(entry.get("duration_ms", 2200)))
	var now: int = world.world_time_ms
	_set_speech(speaker_id, text, now, now + duration_ms)
	var reply_text: String = str(entry.get("reply_text", ""))
	var reply_after_ms: int = maxi(0, int(entry.get("reply_after_ms", 0)))
	var reply_duration_ms: int = maxi(1, int(entry.get("reply_duration_ms", duration_ms)))
	var until_ms: int = now + duration_ms
	if reply_text != "" and reply_after_ms > 0:
		var reply_id: String = target_id if speaker_id == actor_id else actor_id
		_set_speech(reply_id, reply_text, now + reply_after_ms, now + reply_after_ms + reply_duration_ms)
		until_ms = now + reply_after_ms + reply_duration_ms
	var actor: Dictionary = world.get_entity(actor_id)
	actor["greeting_focus"] = {
		"target_id": target_id,
		"started_ms": now,
		"until_ms": until_ms,
	}
	world.bump(actor_id, EtheraIds.CHANGE_STATES)
	return {
		"ok": true,
		"events": [_log("greeting", "%s says %s" % [speaker.get("name", speaker_id), text], {"entity_id": speaker_id, "text": text})],
	}


func _set_speech(entity_id: String, text: String, from_ms: int, until_ms: int) -> void:
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty():
		return
	entity["speech"] = {"text": text, "from_ms": from_ms, "until_ms": until_ms}
	world.bump(entity_id, EtheraIds.CHANGE_STATES)


# Exactly one Shard per successful action, written after the final world result.
func _write_record(definition: Dictionary, actor_id: String, target_id: String, result_ids: Array[String]) -> Array[Dictionary]:
	var record: Dictionary = definition.get("record", {})
	var shard: Dictionary = world.create_shard({
		"actor_ids": [actor_id],
		"target_ids": [target_id],
		"action_id": str(definition.get("id", "")),
		"reaction_ids": record.get("reaction_ids", [EtheraIds.REACTION_NONE]),
		"result_ids": result_ids,
		"place_id": str(world.get_entity(actor_id).get("place_id", world.place_id)),
		"world_time": world.world_time_ms,
	})
	var shard_id: String = str(shard["id"])
	var events: Array[Dictionary] = [_event(EtheraIds.EVENT_SHARD_CREATED, shard)]
	var recipients: Array = record.get("known_by", [EtheraIds.ROLE_ACTOR])
	var learned: Array[String] = []
	for role in recipients:
		var recipient_id: String = _id_for(str(role), actor_id, target_id)
		if world.grant_shard(recipient_id, shard_id):
			learned.append(recipient_id)
			events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": recipient_id, "shard_id": shard_id, "granted": true}))
	events.append(_log("shard_created", "%s event Shard created and known by %d holder(s)" % [
		definition.get("name", definition.get("id", "")),
		learned.size(),
	], {"shard_id": shard_id, "known_by": learned, "result_ids": result_ids}))
	return events


func _displace_beside(holder_id: String, item_id: String, slot_id: String) -> Array[Dictionary]:
	var holder: Dictionary = world.get_entity(holder_id)
	var item: Dictionary = world.get_entity(item_id)
	var offset: Dictionary = world.tuning.get("shaping_drop_offset", {"x": 0.55, "y": 0.0, "z": 0.0})
	var origin: Vector3 = world.position_of(holder)
	var drop := Vector3(origin.x + float(offset.get("x", 0.55)), origin.y, origin.z + float(offset.get("z", 0.0)))
	item["holder_id"] = null
	item["equipped_slot_id"] = null
	item["position"] = EtheraWorld.quantized_point(drop)
	item["manifested"] = true
	world.bump(item_id, EtheraIds.CHANGE_INVENTORY)
	world.set_equipped(holder_id, slot_id, null)
	world.commit_item(EtheraIds.TX_DISPLACE, {
		"entity_id": holder_id,
		"item_id": item_id,
		"slot_id": slot_id,
	})
	return [
		_event(EtheraIds.EVENT_ITEM_MOVED, {"entity_id": item_id, "position": item["position"], "reason": "displaced_beside_actor"}),
		_log("equipment_swap", "%s placed beside the character" % item.get("name", item_id), {"item_id": item_id}),
	]


# A literal value if authored, otherwise read from a field on the actor or target.
func _authored_or_field(entry: Dictionary, literal_key: String, reference_key: String, actor_id: String, target_id: String) -> String:
	if entry.has(literal_key):
		return str(entry[literal_key])
	var reference: Dictionary = entry.get(reference_key, {})
	if reference.is_empty():
		return ""
	var source: Dictionary = _entity_for(str(reference.get("entity", EtheraIds.ROLE_TARGET)), actor_id, target_id)
	return str(source.get(str(reference.get("field", "")), ""))


func _id_for(role: String, actor_id: String, target_id: String) -> String:
	return actor_id if role == EtheraIds.ROLE_ACTOR else target_id


func _entity_for(role: String, actor_id: String, target_id: String) -> Dictionary:
	return world.get_entity(_id_for(role, actor_id, target_id))


func _failed(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "events": [] as Array[Dictionary]}


func _event(event_type: String, payload: Dictionary) -> Dictionary:
	var event: Dictionary = payload.duplicate(true)
	event["type"] = event_type
	event["event_time"] = world.world_time_ms
	return event


func _log(kind: String, text: String, extra: Dictionary = {}) -> Dictionary:
	return _event(EtheraIds.EVENT_LOG, world.add_log(kind, text, extra))
