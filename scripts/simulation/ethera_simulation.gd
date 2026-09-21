extends RefCounted
class_name EtheraSimulation

var catalog: EtheraCatalog
var world: EtheraWorld
var evaluator: EtheraEvaluator
var active_skill: Dictionary = {}
var walk_velocity: Dictionary = {}
var focus_hold: Dictionary = {}

func _init(loaded_catalog: EtheraCatalog = null) -> void:
	catalog = loaded_catalog if loaded_catalog != null else EtheraCatalog.new()
	if catalog.milestone1_world.is_empty():
		var err: Error = catalog.load_from_res()
		if err != OK:
			push_error("EtheraSimulation: content failed to load")
	world = EtheraWorld.new()
	world.setup_milestone_1(catalog)
	evaluator = EtheraEvaluator.new(world)
	_emit_boot_log()


func apply(command: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var command_type: String = str(command.get("type", ""))
	match command_type:
		EtheraIds.CMD_TICK:
			events.append_array(_tick(float(command.get("delta_ms", 16.0))))
		EtheraIds.CMD_SET_WALK_DESTINATION:
			events.append_array(_set_walk_destination(command))
		EtheraIds.CMD_STOP_WALKING:
			events.append_array(_stop_walking(str(command.get("entity_id", world.inhabited_entity_id))))
		EtheraIds.CMD_SET_FOCUS_HOLD:
			events.append_array(_set_focus_hold(command))
		EtheraIds.CMD_PICKUP_ITEM:
			events.append_array(_pickup_item(str(command.get("actor_id", world.inhabited_entity_id)), str(command.get("item_id", ""))))
		EtheraIds.CMD_BEGIN_INTERACTION:
			events.append_array(_begin_interaction(command))
		EtheraIds.CMD_SKILL_POINTER:
			events.append_array(_skill_pointer(command))
		EtheraIds.CMD_SKILL_CLICK:
			events.append_array(_skill_click(command))
		_:
			events.append(_log_event("error", "Unknown command %s" % command_type, {"command": command_type}))
	return events


func query_available_interactions(actor_id: String, target_id: String) -> Array[Dictionary]:
	return evaluator.available_interactions(actor_id, target_id)


func query_hover(actor_id: String, target_id: String) -> Dictionary:
	return evaluator.hover_for(actor_id, target_id)


func query_panel(entity_id: String = "") -> Dictionary:
	var id: String = entity_id if entity_id != "" else world.inhabited_entity_id
	var entity: Dictionary = world.get_entity(id)
	if entity.is_empty():
		return {}
	var slot_id: String = EtheraIds.SLOT_SMALL_WEAPON
	var equipped_id: String = world.equipped_item_id(entity, slot_id)
	var equipped: Dictionary = world.get_entity(equipped_id) if equipped_id != "" else {}
	return {
		"id": id,
		"name": str(entity.get("name", id)),
		"people": str(entity.get("people", "")),
		"sex": str(entity.get("sex", "")),
		"body_regions": _body_region_summaries(entity.get("body_regions", {})),
		"traits": _named_ids(entity.get("traits", []), catalog.traits, "name"),
		"states": entity.get("states", []),
		"known_shards": _shard_summaries(world.known_shards(entity)),
		"known_interactions": _named_ids(entity.get("known_interaction_ids", []), catalog.interactions, "name"),
		"equipment": {
			slot_id: _equipment_summary(equipped)
		},
	}


func query_skill() -> Dictionary:
	return active_skill.duplicate(true)


func query_dev_log(limit: int = 0) -> Array[Dictionary]:
	if limit <= 0 or limit >= world.dev_log.size():
		return world.dev_log.duplicate(true)
	var recent: Array[Dictionary] = []
	for i in range(world.dev_log.size() - limit, world.dev_log.size()):
		recent.append((world.dev_log[i] as Dictionary).duplicate(true))
	return recent


func query_recent_interactions(entity_id: String = "") -> Array:
	return world.recent_interactions(entity_id if entity_id != "" else world.inhabited_entity_id)


func query_world_view() -> Dictionary:
	var entities: Array[Dictionary] = []
	for entity_id in world.entities.keys():
		entities.append(_presentation_entity(world.get_entity(str(entity_id))))
	return {
		"world_time_ms": world.world_time_ms,
		"inhabited_entity_id": world.inhabited_entity_id,
		"place_id": world.place_id,
		"entities": entities,
		"skill": query_skill(),
	}


func resolve_shard(shard_id: String) -> Dictionary:
	return world.shards.get(shard_id, {})


func _tick(delta_ms: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var clamped: float = max(delta_ms, 0.0)
	world.world_time_ms += int(round(clamped))
	events.append_array(_tick_walking(clamped))
	events.append_array(_tick_skill(clamped))
	return events


func _set_walk_destination(command: Dictionary) -> Array[Dictionary]:
	var entity_id: String = str(command.get("entity_id", world.inhabited_entity_id))
	var events: Array[Dictionary] = []
	if _owns_movement(entity_id):
		# A running skill phase keeps movement; an approach can still be abandoned.
		if str(active_skill.get("phase", "")) != "approaching":
			return []
		events.append_array(_cancel_round("player_chose_a_new_destination"))
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty() or not world.is_manifested(entity):
		return events
	walk_velocity[entity_id] = {
		"destination": Vector3(float(command.get("x", 0.0)), float(command.get("y", 0.0)), float(command.get("z", 0.0))),
		"speed": _current_speed(entity_id),
		"reason": "walk",
		"interaction_id": "",
		"target_id": "",
	}
	events.append(_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": "walk_started"}))
	return events


func _stop_walking(entity_id: String) -> Array[Dictionary]:
	# Stopping mid-approach would otherwise leave the round waiting for an arrival that never comes.
	if _owns_movement(entity_id) and str(active_skill.get("phase", "")) == "approaching":
		return _cancel_round("stopped")
	return _clear_walk(entity_id, "stopped")


func _set_focus_hold(command: Dictionary) -> Array[Dictionary]:
	var entity_id: String = str(command.get("entity_id", world.inhabited_entity_id))
	var held: bool = bool(command.get("held", false))
	if held == focus_hold.has(entity_id):
		return []
	if held:
		focus_hold[entity_id] = true
	else:
		focus_hold.erase(entity_id)
	return [_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {
		"entity_id": entity_id,
		"reason": "focus_hold_started" if held else "focus_hold_ended",
	})]


func _cancel_round(reason: String) -> Array[Dictionary]:
	var interaction_id: String = str(active_skill.get("interaction_id", ""))
	var actor_id: String = str(active_skill.get("actor_id", ""))
	var target_id: String = str(active_skill.get("target_id", ""))
	active_skill = {}
	# An abandoned round resolves nothing, so it creates no Shard and no history entry.
	var events: Array[Dictionary] = _clear_walk(actor_id, "approach_cancelled")
	events.append(_log_event("action_cancelled", "%s cancelled (%s)" % [catalog.get_interaction(interaction_id).get("name", interaction_id), reason], {
		"interaction_id": interaction_id,
		"target_id": target_id,
		"reason": reason,
	}))
	events.append(_event(EtheraIds.EVENT_SKILL_ENDED, {"outcome": "cancelled", "reason": reason, "interaction_id": interaction_id}))
	return events


func _owns_movement(entity_id: String) -> bool:
	return not active_skill.is_empty() and str(active_skill.get("actor_id", "")) == entity_id


func _current_speed(entity_id: String) -> float:
	if not walk_velocity.has(entity_id):
		return 0.0
	return float((walk_velocity[entity_id] as Dictionary).get("speed", 0.0))


func _clear_walk(entity_id: String, reason: String) -> Array[Dictionary]:
	if walk_velocity.has(entity_id):
		walk_velocity.erase(entity_id)
		return [_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": reason})]
	return []


func _tick_walking(delta_ms: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var dt: float = delta_ms / 1000.0
	var movers: Array = walk_velocity.keys()
	for entity_id in movers:
		if not walk_velocity.has(entity_id):
			continue
		var motor: Dictionary = walk_velocity[entity_id]
		var entity: Dictionary = world.get_entity(str(entity_id))
		if entity.is_empty():
			continue
		var position: Vector3 = world.position_of(entity)
		var destination: Vector3 = motor["destination"]
		var remaining: Vector3 = destination - position
		remaining.y = 0.0
		var distance: float = remaining.length()
		var arrive_at: float = float(world.tuning.get("stop_distance", 0.18))
		if str(motor.get("reason", "")) == "approach":
			arrive_at = float(world.tuning.get("interaction_arrive_distance", 0.22))
		var max_speed: float = float(world.tuning.get("walk_speed", 2.4))
		if focus_hold.has(str(entity_id)):
			max_speed *= float(world.tuning.get("focus_hold_speed_scale", 0.45))
		var accel: float = float(world.tuning.get("walk_acceleration", 7.0))
		var decel: float = float(world.tuning.get("walk_deceleration", 9.0))
		var speed: float = float(motor.get("speed", 0.0))
		if distance <= arrive_at:
			world.set_position(str(entity_id), Vector3(destination.x, position.y, destination.z), _yaw_toward(position, destination, float(entity.get("yaw", 0.0))))
			walk_velocity.erase(str(entity_id))
			events.append(_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": "arrived"}))
			match str(motor.get("reason", "")):
				"approach":
					events.append_array(_start_skill_phase(str(entity_id), str(motor.get("target_id", "")), str(motor.get("interaction_id", ""))))
				"pickup":
					events.append_array(_take_item_on_arrival(str(entity_id), str(motor.get("target_id", ""))))
			continue
		var stopping_distance: float = (speed * speed) / max(2.0 * decel, 0.001)
		if stopping_distance >= distance:
			speed = max(0.0, speed - decel * dt)
		elif speed > max_speed:
			# A cap that drops mid-stride, such as focus hold, eases down instead of snapping.
			speed = max(max_speed, speed - decel * dt)
		else:
			speed = min(max_speed, speed + accel * dt)
		motor["speed"] = speed
		if speed <= 0.0:
			continue
		var step: Vector3 = remaining.normalized() * speed * dt
		if step.length() > distance:
			step = remaining
		var next: Vector3 = position + step
		var yaw: float = atan2(remaining.x, remaining.z)
		world.set_position(str(entity_id), next, yaw)
		events.append(_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": "moved"}))
	return events


func _begin_interaction(command: Dictionary) -> Array[Dictionary]:
	var actor_id: String = str(command.get("actor_id", world.inhabited_entity_id))
	var target_id: String = str(command.get("target_id", ""))
	var interaction_id: String = str(command.get("interaction_id", ""))
	if not active_skill.is_empty():
		return [_log_event("blocked", "An interaction is already in progress")]
	if not evaluator.is_available(actor_id, target_id, interaction_id):
		return [_log_event("blocked", "Interaction %s is unavailable" % interaction_id, {"interaction_id": interaction_id, "target_id": target_id})]
	var actor: Dictionary = world.get_entity(actor_id)
	var target: Dictionary = world.get_entity(target_id)
	var definition: Dictionary = catalog.get_interaction(interaction_id)
	var approach: Vector3 = _approach_point(actor, target, definition)
	var face: Vector3 = world.position_of(target) - approach
	world.set_position(actor_id, world.position_of(actor), atan2(face.x, face.z) if face.length() > 0.001 else float(actor.get("yaw", 0.0)))
	walk_velocity[actor_id] = {
		"destination": approach,
		"speed": _current_speed(actor_id),
		"reason": "approach",
		"interaction_id": interaction_id,
		"target_id": target_id,
	}
	active_skill = {
		"phase": "approaching",
		"actor_id": actor_id,
		"target_id": target_id,
		"interaction_id": interaction_id,
		"skill_phase_id": str(definition.get("skill_phase_id", "")),
	}
	return [
		_log_event("action_started", "%s selected; approaching %s" % [definition.get("name", interaction_id), target.get("name", target_id)], {"interaction_id": interaction_id, "target_id": target_id}),
		_event(EtheraIds.EVENT_INTERACTION_STARTED, {"actor_id": actor_id, "target_id": target_id, "interaction_id": interaction_id}),
	]


func _start_skill_phase(actor_id: String, target_id: String, interaction_id: String) -> Array[Dictionary]:
	if not evaluator.is_available(actor_id, target_id, interaction_id):
		active_skill = {}
		return [_log_event("blocked", "Interaction became unavailable before the skill phase")]
	var definition: Dictionary = catalog.get_interaction(interaction_id)
	var phase: Dictionary = catalog.get_skill_phase(str(definition.get("skill_phase_id", "")))
	var selected_shard_id: String = ""
	if interaction_id == EtheraIds.INTERACTION_ECHO_IMPRINT:
		selected_shard_id = evaluator.first_eligible_shard(world.get_entity(actor_id), world.get_entity(target_id))
	var target: Dictionary = world.get_entity(target_id)
	var face: Vector3 = world.position_of(target) - world.position_of(world.get_entity(actor_id))
	if face.length() > 0.001:
		world.set_position(actor_id, world.position_of(world.get_entity(actor_id)), atan2(face.x, face.z))
	active_skill = {
		"phase": "skill",
		"actor_id": actor_id,
		"target_id": target_id,
		"interaction_id": interaction_id,
		"skill_phase_id": str(phase.get("id", "")),
		"duration_ms": int(phase.get("duration_ms", 1000)),
		"remaining_ms": int(phase.get("duration_ms", 1000)),
		"pointer": {"x": 0.5, "y": 0.5},
		"checkpoints_hit": {},
		"rotation_degrees": float(phase.get("rotation", {}).get("start_degrees", 0.0)),
		"selected_shard_id": selected_shard_id,
	}
	return [
		_log_event("skill_started", "%s began" % str(phase.get("name", "Skill")), {"skill_phase_id": str(phase.get("id", ""))}),
		_event(EtheraIds.EVENT_SKILL_STARTED, query_skill()),
	]


func _tick_skill(delta_ms: float) -> Array[Dictionary]:
	if active_skill.is_empty() or str(active_skill.get("phase", "")) != "skill":
		return []
	active_skill["remaining_ms"] = int(active_skill.get("remaining_ms", 0)) - int(round(delta_ms))
	var phase: Dictionary = catalog.get_skill_phase(str(active_skill.get("skill_phase_id", "")))
	_update_shard_fit_rotation(phase)
	if int(active_skill.get("remaining_ms", 0)) <= 0:
		return _fail_skill("timeout")
	return [_event(EtheraIds.EVENT_SKILL_UPDATED, query_skill())]


func _skill_pointer(command: Dictionary) -> Array[Dictionary]:
	if active_skill.is_empty() or str(active_skill.get("phase", "")) != "skill":
		return []
	var pointer: Dictionary = {
		"x": clampf(float(command.get("x", 0.5)), 0.0, 1.0),
		"y": clampf(float(command.get("y", 0.5)), 0.0, 1.0),
	}
	active_skill["pointer"] = pointer
	if str(active_skill.get("skill_phase_id", "")) == EtheraIds.SKILL_SHAPE_TRACE:
		_hit_shape_trace_checkpoints(pointer)
	return [_event(EtheraIds.EVENT_SKILL_UPDATED, query_skill())]


func _skill_click(_command: Dictionary) -> Array[Dictionary]:
	if active_skill.is_empty() or str(active_skill.get("phase", "")) != "skill":
		return []
	var phase_id: String = str(active_skill.get("skill_phase_id", ""))
	if phase_id == EtheraIds.SKILL_SHAPE_TRACE:
		if _all_checkpoints_hit():
			return _succeed_skill()
		return [_log_event("skill_click", "Shape Trace is not complete yet")]
	if phase_id == EtheraIds.SKILL_SHARD_FIT:
		if _shard_fit_aligned():
			return _succeed_skill()
		return [_log_event("skill_click", "Shard Fit click missed alignment or recess; time continues")]
	return []


func _succeed_skill() -> Array[Dictionary]:
	var interaction_id: String = str(active_skill.get("interaction_id", ""))
	var actor_id: String = str(active_skill.get("actor_id", ""))
	var target_id: String = str(active_skill.get("target_id", ""))
	if not evaluator.is_available(actor_id, target_id, interaction_id):
		return _fail_skill("invalidated")
	if interaction_id == EtheraIds.INTERACTION_ECHO_IMPRINT and str(active_skill.get("selected_shard_id", "")) == "":
		return _fail_skill("no_eligible_shard")
	var events: Array[Dictionary] = []
	match interaction_id:
		EtheraIds.INTERACTION_SHAPE_WEAPON:
			events.append_array(_apply_shape_weapon(actor_id, target_id))
		EtheraIds.INTERACTION_ECHO_IMPRINT:
			events.append_array(_apply_echo_imprint(actor_id, target_id, str(active_skill.get("selected_shard_id", ""))))
		_:
			return _fail_skill("unknown_result")
	events.append(_log_event("action_succeeded", "%s succeeded" % catalog.get_interaction(interaction_id).get("name", interaction_id), {"interaction_id": interaction_id}))
	events.append(_event(EtheraIds.EVENT_SKILL_ENDED, {"outcome": "success", "interaction_id": interaction_id}))
	world.append_history(actor_id, {
		"interaction_id": interaction_id,
		"target_id": target_id,
		"world_time": world.world_time_ms,
		"outcome": "success",
	})
	active_skill = {}
	return events


func _fail_skill(reason: String) -> Array[Dictionary]:
	var interaction_id: String = str(active_skill.get("interaction_id", ""))
	var events: Array[Dictionary] = [
		_log_event("action_failed", "%s failed (%s)" % [catalog.get_interaction(interaction_id).get("name", interaction_id), reason], {"interaction_id": interaction_id, "reason": reason}),
		_event(EtheraIds.EVENT_SKILL_ENDED, {"outcome": "failure", "reason": reason, "interaction_id": interaction_id}),
	]
	active_skill = {}
	return events


func _apply_shape_weapon(actor_id: String, rock_id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var actor: Dictionary = world.get_entity(actor_id)
	var rock: Dictionary = world.get_entity(rock_id)
	rock["manifested"] = false
	world.bump(rock_id, EtheraIds.CHANGE_MANIFESTATION)
	events.append(_event(EtheraIds.EVENT_MANIFESTATION, {"entity_id": rock_id, "manifested": false}))
	events.append(_log_event("manifestation", "Rock manifestation removed", {"entity_id": rock_id}))
	var slot_id: String = EtheraIds.SLOT_SMALL_WEAPON
	var previous_id: String = world.equipped_item_id(actor, slot_id)
	if previous_id != "":
		events.append_array(_drop_item_beside(actor_id, previous_id, slot_id))
	var club: Dictionary = world.spawn_item_from_template(str(rock.get("yields_template_id", EtheraIds.TEMPLATE_STONE_CLUB)), {
		"base_color": str(rock.get("yields_base_color", "slate")),
		"place_id": str(actor.get("place_id", world.place_id)),
		"position": actor.get("position", {"x": 0.0, "y": 0.0, "z": 0.0}),
		"holder_id": actor_id,
		"equipped_slot_id": slot_id,
		"manifested": true,
	})
	world.set_equipped(actor_id, slot_id, str(club["id"]))
	events.append(_event(EtheraIds.EVENT_EQUIPMENT, {"entity_id": actor_id, "slot_id": slot_id, "item_id": str(club["id"])}))
	events.append(_log_event("club_created", "Stone club created and equipped", {"item_id": str(club["id"]), "base_color": str(club.get("base_color", ""))}))
	var shard: Dictionary = world.create_shard({
		"actor_ids": [actor_id],
		"target_ids": [rock_id],
		"action_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
		"reaction_ids": [EtheraIds.REACTION_NONE],
		"result_ids": [str(club["id"])],
		"place_id": str(actor.get("place_id", world.place_id)),
		"world_time": world.world_time_ms,
	})
	world.grant_shard(actor_id, str(shard["id"]))
	events.append(_event(EtheraIds.EVENT_SHARD_CREATED, shard))
	events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": actor_id, "shard_id": str(shard["id"]), "granted": true}))
	events.append(_log_event("shard_created", "Shape Weapon event Shard created and known by %s" % actor.get("name", actor_id), {"shard_id": str(shard["id"])}))
	return events


func _apply_echo_imprint(actor_id: String, target_id: String, selected_shard_id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var actor: Dictionary = world.get_entity(actor_id)
	var newly_granted: bool = world.grant_shard(target_id, selected_shard_id)
	if newly_granted:
		events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": target_id, "shard_id": selected_shard_id, "granted": true}))
		events.append(_log_event("fountain_learned", "Fountain gained reference to %s" % selected_shard_id, {"shard_id": selected_shard_id, "target_id": target_id}))
	var event_shard: Dictionary = world.create_shard({
		"actor_ids": [actor_id],
		"target_ids": [target_id],
		"action_id": EtheraIds.INTERACTION_ECHO_IMPRINT,
		"reaction_ids": [EtheraIds.REACTION_NONE],
		"result_ids": [selected_shard_id],
		"place_id": str(actor.get("place_id", world.place_id)),
		"world_time": world.world_time_ms,
	})
	events.append(_event(EtheraIds.EVENT_SHARD_CREATED, event_shard))
	# Both participants learn the new event, so no unshared record is left behind and
	# Echo Imprint does not immediately offer itself again.
	var event_shard_id: String = str(event_shard["id"])
	for recipient_id in [actor_id, target_id]:
		if world.grant_shard(str(recipient_id), event_shard_id):
			events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": recipient_id, "shard_id": event_shard_id, "granted": true}))
	events.append(_log_event("shard_created", "Echo Imprint event Shard created and known by both participants", {
		"shard_id": event_shard_id,
		"transferred_shard_id": selected_shard_id,
		"actor_still_knows_transferred": world.knows_shard(actor, selected_shard_id),
	}))
	return events


func _pickup_item(actor_id: String, item_id: String) -> Array[Dictionary]:
	if not active_skill.is_empty():
		return [_log_event("blocked", "Cannot pick up during an interaction")]
	var hover: Dictionary = evaluator.hover_for(actor_id, item_id)
	var kind: String = str(hover.get("kind", EtheraIds.HOVER_NONE))
	if kind != EtheraIds.HOVER_PICKUP and kind != EtheraIds.HOVER_SWAP:
		return [_log_event("blocked", "Item is not a compatible loose pickup", {"item_id": item_id})]
	var actor_position: Vector3 = world.position_of(world.get_entity(actor_id))
	var item_position: Vector3 = world.position_of(world.get_entity(item_id))
	if _planar_distance(actor_position, item_position) > float(world.tuning.get("pickup_reach", 1.1)):
		return _walk_to_pickup(actor_id, item_id)
	return _take_item(actor_id, item_id, str(hover.get("slot_id", EtheraIds.SLOT_SMALL_WEAPON)))


func _walk_to_pickup(actor_id: String, item_id: String) -> Array[Dictionary]:
	var item: Dictionary = world.get_entity(item_id)
	walk_velocity[actor_id] = {
		"destination": _point_beside(
			world.position_of(item),
			world.position_of(world.get_entity(actor_id)),
			float(world.tuning.get("pickup_approach_distance", 0.8))
		),
		"speed": _current_speed(actor_id),
		"reason": "pickup",
		"interaction_id": "",
		"target_id": item_id,
	}
	return [
		_log_event("pickup_approach", "Walking to %s before taking it" % item.get("name", item_id), {"item_id": item_id}),
		_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": actor_id, "reason": "pickup_walk_started"}),
	]


func _take_item_on_arrival(actor_id: String, item_id: String) -> Array[Dictionary]:
	var hover: Dictionary = evaluator.hover_for(actor_id, item_id)
	var kind: String = str(hover.get("kind", EtheraIds.HOVER_NONE))
	if kind != EtheraIds.HOVER_PICKUP and kind != EtheraIds.HOVER_SWAP:
		return [_log_event("blocked", "Item is no longer a compatible loose pickup", {"item_id": item_id})]
	return _take_item(actor_id, item_id, str(hover.get("slot_id", EtheraIds.SLOT_SMALL_WEAPON)))


func _take_item(actor_id: String, item_id: String, slot_id: String) -> Array[Dictionary]:
	var actor: Dictionary = world.get_entity(actor_id)
	var item: Dictionary = world.get_entity(item_id)
	var clicked_position: Dictionary = item.get("position", {"x": 0.0, "y": 0.0, "z": 0.0}).duplicate(true)
	var previous_id: String = world.equipped_item_id(actor, slot_id)
	var events: Array[Dictionary] = []
	if previous_id != "":
		var previous: Dictionary = world.get_entity(previous_id)
		previous["holder_id"] = null
		previous["equipped_slot_id"] = null
		previous["position"] = clicked_position
		previous["manifested"] = true
		world.bump(previous_id, EtheraIds.CHANGE_INVENTORY)
		events.append(_event(EtheraIds.EVENT_ITEM_MOVED, {"entity_id": previous_id, "position": clicked_position, "reason": "displaced_to_clicked_position"}))
		events.append(_log_event("equipment_swap", "Displaced item placed at the clicked item's exact position", {"item_id": previous_id, "position": clicked_position}))
	item["holder_id"] = actor_id
	item["equipped_slot_id"] = slot_id
	item["position"] = actor.get("position", item.get("position", {}))
	world.set_equipped(actor_id, slot_id, item_id)
	world.bump(item_id, EtheraIds.CHANGE_INVENTORY)
	events.append(_event(EtheraIds.EVENT_EQUIPMENT, {"entity_id": actor_id, "slot_id": slot_id, "item_id": item_id}))
	events.append(_log_event("equipment_changed", "Picked up %s" % item.get("name", item_id), {"item_id": item_id, "slot_id": slot_id}))
	events.append_array(_clear_walk(actor_id, "pickup"))
	return events


func _drop_item_beside(actor_id: String, item_id: String, slot_id: String) -> Array[Dictionary]:
	var actor: Dictionary = world.get_entity(actor_id)
	var item: Dictionary = world.get_entity(item_id)
	var offset: Dictionary = world.tuning.get("shaping_drop_offset", {"x": 0.55, "y": 0.0, "z": 0.0})
	var origin: Vector3 = world.position_of(actor)
	var drop := Vector3(origin.x + float(offset.get("x", 0.55)), origin.y, origin.z + float(offset.get("z", 0.0)))
	item["holder_id"] = null
	item["equipped_slot_id"] = null
	item["position"] = {"x": drop.x, "y": drop.y, "z": drop.z}
	item["manifested"] = true
	world.bump(item_id, EtheraIds.CHANGE_INVENTORY)
	world.set_equipped(actor_id, slot_id, null)
	return [
		_event(EtheraIds.EVENT_ITEM_MOVED, {"entity_id": item_id, "position": item["position"], "reason": "displaced_beside_actor"}),
		_log_event("equipment_swap", "Previous club placed beside the character", {"item_id": item_id}),
	]


func _hit_shape_trace_checkpoints(pointer: Dictionary) -> void:
	var phase: Dictionary = catalog.get_skill_phase(EtheraIds.SKILL_SHAPE_TRACE)
	var radius: float = float(phase.get("checkpoint_radius", 0.05))
	var hit: Dictionary = active_skill.get("checkpoints_hit", {})
	for checkpoint in phase.get("checkpoints", []):
		var dx: float = float(pointer.get("x", 0.0)) - float(checkpoint.get("x", 0.0))
		var dy: float = float(pointer.get("y", 0.0)) - float(checkpoint.get("y", 0.0))
		if Vector2(dx, dy).length() <= radius:
			hit[str(checkpoint.get("id", ""))] = true
	active_skill["checkpoints_hit"] = hit


func _all_checkpoints_hit() -> bool:
	var phase: Dictionary = catalog.get_skill_phase(EtheraIds.SKILL_SHAPE_TRACE)
	var hit: Dictionary = active_skill.get("checkpoints_hit", {})
	for checkpoint in phase.get("checkpoints", []):
		if not bool(hit.get(str(checkpoint.get("id", "")), false)):
			return false
	return true


func _update_shard_fit_rotation(phase: Dictionary) -> void:
	if str(phase.get("id", "")) != EtheraIds.SKILL_SHARD_FIT:
		return
	var rotation: Dictionary = phase.get("rotation", {})
	var elapsed: float = float(int(active_skill.get("duration_ms", 0)) - int(active_skill.get("remaining_ms", 0)))
	var period: float = max(float(rotation.get("period_ms", 1800.0)), 1.0)
	var align: float = float(rotation.get("align_at_degrees", 0.0))
	var oscillation: float = float(rotation.get("oscillation_degrees", 40.0))
	active_skill["rotation_degrees"] = align + oscillation * sin(TAU * elapsed / period)


func _shard_fit_aligned() -> bool:
	var phase: Dictionary = catalog.get_skill_phase(EtheraIds.SKILL_SHARD_FIT)
	var recess: Dictionary = phase.get("recess", {})
	var pointer: Dictionary = active_skill.get("pointer", {"x": 0.5, "y": 0.5})
	var dx: float = float(pointer.get("x", 0.0)) - float(recess.get("x", 0.5))
	var dy: float = float(pointer.get("y", 0.0)) - float(recess.get("y", 0.5))
	if Vector2(dx, dy).length() > float(recess.get("radius", 0.08)):
		return false
	var rotation: Dictionary = phase.get("rotation", {})
	var delta: float = absf(float(active_skill.get("rotation_degrees", 0.0)) - float(rotation.get("align_at_degrees", 0.0)))
	while delta > 180.0:
		delta -= 360.0
	return absf(delta) <= float(rotation.get("tolerance_degrees", 12.0))


func _approach_point(actor: Dictionary, target: Dictionary, definition: Dictionary) -> Vector3:
	if target.has("interaction_approach"):
		var authored: Dictionary = target["interaction_approach"]
		return Vector3(float(authored.get("x", 0.0)), float(authored.get("y", 0.0)), float(authored.get("z", 0.0)))
	return _point_beside(
		world.position_of(target),
		world.position_of(actor),
		float(definition.get("approach", {}).get("distance", 1.45))
	)


# A standing point the given distance from the anchor, on the side the mover is already on.
func _point_beside(anchor: Vector3, toward: Vector3, distance: float) -> Vector3:
	var offset: Vector3 = toward - anchor
	offset.y = 0.0
	if offset.length() < 0.001:
		offset = Vector3(1.0, 0.0, 0.0)
	return anchor + offset.normalized() * distance


func _planar_distance(from: Vector3, to: Vector3) -> float:
	return Vector2(to.x - from.x, to.z - from.z).length()


func _yaw_toward(from: Vector3, to: Vector3, fallback: float) -> float:
	var delta: Vector3 = to - from
	delta.y = 0.0
	if delta.length() < 0.001:
		return fallback
	return atan2(delta.x, delta.z)


func _presentation_entity(entity: Dictionary) -> Dictionary:
	return {
		"id": str(entity.get("id", "")),
		"kind": str(entity.get("kind", "")),
		"name": str(entity.get("name", "")),
		"manifested": world.is_manifested(entity),
		"position": entity.get("position", {}),
		"yaw": float(entity.get("yaw", 0.0)),
		"base_color": str(entity.get("base_color", "")),
		"holder_id": entity.get("holder_id", null),
		"equipped_slot_id": entity.get("equipped_slot_id", null),
		"presentation": entity.get("presentation", {}),
		"traits": entity.get("traits", []),
	}


func _named_ids(ids: Variant, catalog_map: Dictionary, field: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(ids) != TYPE_ARRAY:
		return result
	for item_id in ids:
		var definition: Dictionary = catalog_map.get(str(item_id), {})
		result.append({
			"id": str(item_id),
			"name": str(definition.get(field, item_id)),
		})
	return result


func _shard_summaries(ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for shard_id in ids:
		var shard: Dictionary = resolve_shard(shard_id)
		result.append({
			"id": shard_id,
			"action_id": str(shard.get("action_id", "")),
			"target_ids": shard.get("target_ids", []),
			"result_ids": shard.get("result_ids", []),
			"place_id": str(shard.get("place_id", "")),
			"world_time": int(shard.get("world_time", 0)),
		})
	return result


func _equipment_summary(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {"empty": true}
	return {
		"empty": false,
		"id": str(item.get("id", "")),
		"name": str(item.get("name", "")),
		"base_color": str(item.get("base_color", "")),
		"condition": str(item.get("condition", "okay")),
		"attachment": str(item.get("attachment", "back")),
	}


func _body_region_summaries(regions: Dictionary) -> Dictionary:
	var summaries: Dictionary = {}
	for region_id in regions.keys():
		var definition: Dictionary = catalog.get_body_region(str(region_id))
		summaries[str(region_id)] = {
			"name": str(definition.get("name", region_id)),
			"condition": str(regions[region_id]),
		}
	return summaries


# The envelope uses event_time so a payload's own world_time, such as a Shard's
# original timestamp, is never overwritten.
func _event(event_type: String, payload: Dictionary) -> Dictionary:
	var event: Dictionary = payload.duplicate(true)
	event["type"] = event_type
	event["event_time"] = world.world_time_ms
	return event


func _log_event(kind: String, text: String, extra: Dictionary = {}) -> Dictionary:
	return _event(EtheraIds.EVENT_LOG, world.add_log(kind, text, extra))


func _emit_boot_log() -> void:
	world.add_log("boot", "Milestone 1 local simulation ready", {
		"inhabited_entity_id": world.inhabited_entity_id,
		"entity_count": world.entities.size(),
	})
