extends RefCounted
class_name EtheraSimulation

var catalog: EtheraCatalog
var world: EtheraWorld
var evaluator: EtheraEvaluator
var results: EtheraResults
# The command journal is how this node got here, not part of the hashed world. A
# snapshot replaces it; a validator replays the journal against an earlier snapshot.
var command_log: Array[Dictionary] = []
const COMMAND_LOG_LIMIT := 2000

func _init(loaded_catalog: EtheraCatalog = null) -> void:
	catalog = loaded_catalog if loaded_catalog != null else EtheraCatalog.new()
	if catalog.milestone1_world.is_empty():
		var err: Error = catalog.load_from_res()
		if err != OK:
			push_error("EtheraSimulation: content failed to load")
	world = EtheraWorld.new()
	world.setup_milestone_1(catalog)
	evaluator = EtheraEvaluator.new(world)
	results = EtheraResults.new(world, catalog, evaluator)
	_emit_boot_log()


func apply(command: Dictionary) -> Array[Dictionary]:
	var recorded: Dictionary = command.duplicate(true)
	command_log.append({"tick": world.tick, "command": recorded})
	while command_log.size() > COMMAND_LOG_LIMIT:
		command_log.remove_at(0)
	var events: Array[Dictionary] = []
	var command_type: String = str(command.get("type", ""))
	match command_type:
		EtheraIds.CMD_TICK:
			events.append_array(_tick(int(command.get("ticks", 1))))
		EtheraIds.CMD_SET_WALK_DESTINATION:
			events.append_array(_set_walk_destination(command))
		EtheraIds.CMD_STOP_WALKING:
			events.append_array(_stop_walking(str(command.get("entity_id", world.inhabited_entity_id))))
		EtheraIds.CMD_SET_FOCUS_HOLD:
			events.append_array(_set_focus_hold(command))
		EtheraIds.CMD_PICKUP_ITEM:
			events.append_array(_pickup_item(str(command.get("actor_id", world.inhabited_entity_id)), str(command.get("item_id", ""))))
		EtheraIds.CMD_OPEN_CONTAINER:
			events.append_array(_open_container(str(command.get("actor_id", world.inhabited_entity_id)), str(command.get("target_id", ""))))
		EtheraIds.CMD_OBSERVE_TARGET:
			events.append_array(_observe_target(str(command.get("actor_id", world.inhabited_entity_id)), str(command.get("target_id", ""))))
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


func query_inhabited_id() -> String:
	return world.inhabited_entity_id


# What a character knows is authoritative state, not client data. Only the inhabited
# character's own knowledge crosses this boundary; everyone else is described by what
# an onlooker could see. A Memory Fountain never hands its contents to a client.
func query_panel(entity_id: String = "") -> Dictionary:
	var id: String = entity_id if entity_id != "" else world.inhabited_entity_id
	var entity: Dictionary = world.get_entity(id)
	if entity.is_empty():
		return {}
	var equipment: Dictionary = {}
	for slot_id in catalog.equipment_slots.keys():
		var equipped_id: String = world.equipped_item_id(entity, str(slot_id))
		var equipped: Dictionary = world.get_entity(equipped_id) if equipped_id != "" else {}
		equipment[str(slot_id)] = _equipment_summary(equipped)
	var panel: Dictionary = {
		"id": id,
		"name": str(entity.get("name", id)),
		"people": str(entity.get("people", "")),
		"sex": str(entity.get("sex", "")),
		"body_regions": _body_region_summaries(entity.get("body_regions", {})),
		"traits": _named_ids(entity.get("traits", []), catalog.traits, "name"),
		"states": _state_summaries(entity),
		"needs": entity.get("needs", []),
		"equipment": equipment,
		"knowledge_visible": id == world.inhabited_entity_id,
	}
	if id == world.inhabited_entity_id:
		panel["known_shards"] = _shard_summaries(world.known_shards(entity))
		panel["known_interactions"] = _named_ids(entity.get("known_interaction_ids", []), catalog.interactions, "name")
	return panel


# The round plus the authored phase shape presentation needs to draw it, so the
# presentation layer never reads the content catalog directly.
func query_skill() -> Dictionary:
	var skill: Dictionary = world.active_round.duplicate(true)
	if skill.is_empty():
		return skill
	var phase: Dictionary = catalog.get_skill_phase(str(skill.get("skill_phase_id", "")))
	skill["phase"] = {
		"id": str(phase.get("id", "")),
		"name": str(phase.get("name", "")),
		"challenge": str(phase.get("challenge", "")),
		"checkpoints": phase.get("checkpoints", []),
		"checkpoint_radius": float(phase.get("checkpoint_radius", 0.05)),
		"recess": phase.get("recess", {}),
		"rotation": phase.get("rotation", {}),
	}
	return skill


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
		"tick": world.tick,
		"world_time_ms": world.world_time_ms,
		"inhabited_entity_id": world.inhabited_entity_id,
		"place_id": world.place_id,
		"entities": entities,
		"skill": query_skill(),
	}


func resolve_shard(shard_id: String) -> Dictionary:
	return world.shards.get(shard_id, {})


# Snapshot, hash and restore are the runtime's half of the handoff a networked node needs:
# a state to send, a fingerprint to compare and a way to resume from someone else's state.
# Content is not carried; a receiving node loads the same catalog.
func create_snapshot() -> Dictionary:
	return world.serialize()


func state_hash() -> String:
	return world.hash_state()


func restore_snapshot(snapshot: Dictionary) -> bool:
	if not world.restore(snapshot):
		return false
	evaluator.cache.clear()
	command_log.clear()
	return true


# Replays a recorded command journal onto this simulation. Used by tests and, later, by
# a validator reconstructing a round from timestamped samples.
func replay(journal: Array) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for entry in journal:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var command: Variant = entry.get("command", entry)
		if typeof(command) != TYPE_DICTIONARY:
			continue
		events.append_array(apply(command as Dictionary))
	return events


# The authoritative clock only ever advances in whole ticks. Presentation converts its
# own frame time into a tick count; frame deltas never enter the simulation.
func _tick(ticks: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for _i in range(max(ticks, 0)):
		world.advance_tick()
		events.append_array(_tick_states())
		events.append_array(_tick_walking())
		events.append_array(_tick_skill())
	return events


func _set_walk_destination(command: Dictionary) -> Array[Dictionary]:
	var entity_id: String = str(command.get("entity_id", world.inhabited_entity_id))
	var events: Array[Dictionary] = []
	if _owns_movement(entity_id):
		# A running skill phase keeps movement; an approach can still be abandoned.
		if str(world.active_round.get("stage", "")) != "approaching":
			return []
		events.append_array(_cancel_round("player_chose_a_new_destination"))
	var entity: Dictionary = world.get_entity(entity_id)
	if entity.is_empty() or not world.is_manifested(entity):
		return events
	var gait: String = "run" if str(command.get("gait", "walk")) == "run" else "walk"
	_begin_walk(
		entity_id,
		Vector3(float(command.get("x", 0.0)), float(command.get("y", 0.0)), float(command.get("z", 0.0))),
		"walk",
		{"gait": gait}
	)
	events.append(_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": "run_started" if gait == "run" else "walk_started"}))
	return events


func _stop_walking(entity_id: String) -> Array[Dictionary]:
	# Stopping mid-approach would otherwise leave the round waiting for an arrival that never comes.
	if _owns_movement(entity_id) and str(world.active_round.get("stage", "")) == "approaching":
		return _cancel_round("stopped")
	return _clear_walk(entity_id, "stopped")


func _set_focus_hold(command: Dictionary) -> Array[Dictionary]:
	var entity_id: String = str(command.get("entity_id", world.inhabited_entity_id))
	var held: bool = bool(command.get("held", false))
	if held == world.focus_hold.has(entity_id):
		return []
	if held:
		world.focus_hold[entity_id] = true
	else:
		world.focus_hold.erase(entity_id)
	return [_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {
		"entity_id": entity_id,
		"reason": "focus_hold_started" if held else "focus_hold_ended",
	})]


func _cancel_round(reason: String) -> Array[Dictionary]:
	var interaction_id: String = str(world.active_round.get("interaction_id", ""))
	var actor_id: String = str(world.active_round.get("actor_id", ""))
	var target_id: String = str(world.active_round.get("target_id", ""))
	world.active_round = {}
	# An abandoned round resolves nothing, so it creates no Shard and no history entry.
	var events: Array[Dictionary] = _clear_walk(actor_id, "approach_cancelled")
	events.append(_log_event("action_cancelled", "%s cancelled (%s)" % [catalog.get_interaction(interaction_id).get("name", interaction_id), reason], {
		"interaction_id": interaction_id,
		"target_id": target_id,
		"reason": reason,
	}))
	events.append(_event(EtheraIds.EVENT_SKILL_ENDED, {"outcome": "cancelled", "reason": reason, "interaction_id": interaction_id}))
	return events


func _body_radius() -> float:
	return float(world.tuning.get("body_radius", 0.38))


func _walk_radius() -> float:
	return world.walk_radius(_body_radius())


func _walk_ignore_ids(entity_id: String, motor: Dictionary = {}) -> Array:
	var ignore_ids: Array = [entity_id]
	if str(motor.get("reason", "")) == "approach" or str(motor.get("reason", "")) == "pickup" or str(motor.get("reason", "")) == "open":
		var target_id: String = str(motor.get("target_id", ""))
		if target_id != "":
			ignore_ids.append(target_id)
	return ignore_ids


func _begin_walk(entity_id: String, destination: Vector3, reason: String, extra: Dictionary = {}) -> void:
	var speed: float = _current_speed(entity_id)
	var motor := {
		"reason": reason,
		"interaction_id": str(extra.get("interaction_id", "")),
		"target_id": str(extra.get("target_id", "")),
	}
	var ignore_ids: Array = _walk_ignore_ids(entity_id, motor)
	var dest: Vector3 = world.nearest_open_point(destination, _walk_radius(), ignore_ids)
	var from: Vector3 = world.position_of(world.get_entity(entity_id))
	dest = world.last_walkable_toward(from, dest)
	var lazy: bool = reason != "approach" and reason != "pickup" and reason != "open"
	world.walk_motor[entity_id] = {
		"destination": EtheraWorld.quantized_point(dest),
		"path": _quantize_path(world.find_walk_path(from, dest, _walk_radius(), ignore_ids, lazy)),
		"speed": speed,
		"reason": reason,
		"gait": "run" if str(extra.get("gait", "walk")) == "run" else "walk",
		"interaction_id": str(extra.get("interaction_id", "")),
		"target_id": str(extra.get("target_id", "")),
	}


func _quantize_path(points: Array) -> Array:
	var stored: Array = []
	for point in points:
		stored.append(EtheraWorld.quantized_point(point))
	return stored


func _path_points(motor: Dictionary) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for raw in motor.get("path", []):
		points.append(EtheraWorld.to_vector(raw))
	return points


func _steer_along_path(motor: Dictionary, position: Vector3, destination: Vector3, ignore_ids: Array) -> Vector3:
	var reason: String = str(motor.get("reason", ""))
	var lazy: bool = reason != "approach" and reason != "pickup" and reason != "open"
	var path: Array[Vector3] = _path_points(motor)
	if path.is_empty():
		path = []
		for point in world.find_walk_path(position, destination, _walk_radius(), ignore_ids, lazy):
			path.append(point)
	var arrive: float = max(0.2, float(world.tuning.get("path_cell", 0.32)) * 0.85)
	while path.size() > 1 and _planar_distance(position, path[0]) <= arrive:
		path.remove_at(0)
	if (
		path.size() == 1
		and _planar_distance(position, path[0]) <= arrive
		and _planar_distance(path[0], destination) > arrive * 2.0
	):
		path = []
		for point in world.find_walk_path(position, destination, _walk_radius(), ignore_ids, lazy):
			path.append(point)
		while path.size() > 1 and _planar_distance(position, path[0]) <= arrive:
			path.remove_at(0)
	motor["path"] = _quantize_path(path)
	if path.is_empty():
		return destination
	return path[0]


func _owns_movement(entity_id: String) -> bool:
	return not world.active_round.is_empty() and str(world.active_round.get("actor_id", "")) == entity_id


func _current_speed(entity_id: String) -> float:
	if not world.walk_motor.has(entity_id):
		return 0.0
	return float((world.walk_motor[entity_id] as Dictionary).get("speed", 0.0))


func _clear_walk(entity_id: String, reason: String) -> Array[Dictionary]:
	if world.walk_motor.has(entity_id):
		world.walk_motor.erase(entity_id)
		return [_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": reason})]
	return []


func _tick_walking() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var dt: float = EtheraWorld.SECONDS_PER_TICK
	var movers: Array = world.walk_motor.keys()
	for entity_id in movers:
		if not world.walk_motor.has(entity_id):
			continue
		var motor: Dictionary = world.walk_motor[entity_id]
		var entity: Dictionary = world.get_entity(str(entity_id))
		if entity.is_empty():
			continue
		var ignore_ids: Array = _walk_ignore_ids(str(entity_id), motor)
		var position: Vector3 = world.position_of(entity)
		if world.is_blocked(position, _walk_radius(), ignore_ids):
			position = world.nearest_open_point(position, _walk_radius(), ignore_ids)
			world.set_position(str(entity_id), position, float(entity.get("yaw", 0.0)))
		var destination: Vector3 = EtheraWorld.to_vector(motor["destination"])
		var remaining: Vector3 = destination - position
		remaining.y = 0.0
		var distance: float = remaining.length()
		var arrive_at: float = float(world.tuning.get("stop_distance", 0.18))
		if str(motor.get("reason", "")) == "approach":
			arrive_at = float(world.tuning.get("interaction_arrive_distance", 0.22))
		var max_speed: float = float(world.tuning.get("walk_speed", 2.4))
		if str(motor.get("gait", "walk")) == "run":
			max_speed = float(world.tuning.get("run_speed", 5.2))
		max_speed *= world.movement_speed_scale(entity)
		if world.focus_hold.has(str(entity_id)):
			max_speed *= float(world.tuning.get("focus_hold_speed_scale", 0.45))
		var accel: float = float(world.tuning.get("walk_acceleration", 7.0))
		var decel: float = float(world.tuning.get("walk_deceleration", 9.0))
		if str(motor.get("gait", "walk")) == "run":
			accel = float(world.tuning.get("run_acceleration", 3.2))
			decel = float(world.tuning.get("run_deceleration", 5.0))
		var speed: float = float(motor.get("speed", 0.0))
		if distance <= arrive_at:
			var stand: Vector3 = position
			if world.is_blocked(stand, _walk_radius(), ignore_ids):
				stand = world.nearest_open_point(stand, _walk_radius(), ignore_ids)
			world.set_position(str(entity_id), stand, _yaw_toward(position, destination, float(entity.get("yaw", 0.0))))
			world.walk_motor.erase(str(entity_id))
			events.append(_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": "arrived"}))
			match str(motor.get("reason", "")):
				"approach":
					events.append_array(_start_skill_phase(str(entity_id), str(motor.get("target_id", "")), str(motor.get("interaction_id", ""))))
				"pickup":
					events.append_array(_take_item_on_arrival(str(entity_id), str(motor.get("target_id", ""))))
				"open":
					events.append_array(_open_container_on_arrival(str(entity_id), str(motor.get("target_id", ""))))
			continue
		var stopping_distance: float = (speed * speed) / max(2.0 * decel, 0.001)
		if stopping_distance >= distance:
			speed = max(0.0, speed - decel * dt)
		elif speed > max_speed:
			# A cap that drops mid-stride, such as focus hold, eases down instead of snapping.
			speed = max(max_speed, speed - decel * dt)
		else:
			speed = min(max_speed, speed + accel * dt)
		motor["speed"] = EtheraWorld.quantize(speed, EtheraWorld.SPEED_QUANTUM)
		if speed <= 0.0:
			continue
		var steer: Vector3 = _steer_along_path(motor, position, destination, ignore_ids)
		var heading: Vector3 = steer - position
		heading.y = 0.0
		if heading.length() < 0.0005:
			heading = remaining
		var step: Vector3 = heading.normalized() * speed * dt
		if step.length() > heading.length():
			step = heading
		var next: Vector3 = world.slide_move(position, position + step, _walk_radius(), ignore_ids)
		if _planar_distance(position, next) < 0.0005:
			motor["path"] = _quantize_path(world.find_walk_path(position, destination, _walk_radius(), ignore_ids))
			steer = _steer_along_path(motor, position, destination, ignore_ids)
			heading = steer - position
			heading.y = 0.0
			if heading.length() >= 0.0005:
				step = heading.normalized() * speed * dt
				if step.length() > heading.length():
					step = heading
				next = world.slide_move(position, position + step, _walk_radius(), ignore_ids)
		if _planar_distance(position, next) < 0.0005:
			if str(motor.get("reason", "")) == "approach":
				events.append_array(_cancel_round("blocked"))
			else:
				events.append_array(_clear_walk(str(entity_id), "blocked"))
			continue
		var yaw: float = atan2(heading.x, heading.z)
		world.set_position(str(entity_id), next, yaw)
		events.append(_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": entity_id, "reason": "moved"}))
	return events


func _begin_interaction(command: Dictionary) -> Array[Dictionary]:
	var actor_id: String = str(command.get("actor_id", world.inhabited_entity_id))
	var target_id: String = str(command.get("target_id", ""))
	var interaction_id: String = str(command.get("interaction_id", ""))
	if not world.active_round.is_empty():
		return [_log_event("blocked", "An interaction is already in progress")]
	if not evaluator.is_available(actor_id, target_id, interaction_id):
		return [_log_event("blocked", "Interaction %s is unavailable" % interaction_id, {"interaction_id": interaction_id, "target_id": target_id})]
	var actor: Dictionary = world.get_entity(actor_id)
	var target: Dictionary = world.get_entity(target_id)
	var definition: Dictionary = catalog.get_interaction(interaction_id)
	var approach: Vector3 = _approach_point(actor, target, definition)
	var face: Vector3 = world.position_of(target) - approach
	world.set_position(actor_id, world.position_of(actor), atan2(face.x, face.z) if face.length() > 0.001 else float(actor.get("yaw", 0.0)))
	_begin_walk(actor_id, approach, "approach", {
		"interaction_id": interaction_id,
		"target_id": target_id,
	})
	world.active_round = {
		"stage": "approaching",
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
		world.active_round = {}
		return [_log_event("blocked", "Interaction became unavailable before the skill phase")]
	var definition: Dictionary = catalog.get_interaction(interaction_id)
	var selected_shard_id: String = results.select_for(interaction_id, actor_id, target_id)
	var target: Dictionary = world.get_entity(target_id)
	var face: Vector3 = world.position_of(target) - world.position_of(world.get_entity(actor_id))
	if face.length() > 0.001:
		world.set_position(actor_id, world.position_of(world.get_entity(actor_id)), atan2(face.x, face.z))
	if str(definition.get("skill_phase_id", "")) == "":
		world.active_round = {
			"stage": "skill",
			"actor_id": actor_id,
			"target_id": target_id,
			"interaction_id": interaction_id,
			"skill_phase_id": "",
			"selected_shard_id": selected_shard_id,
			"inputs": [],
		}
		return _succeed_skill()
	var phase: Dictionary = catalog.get_skill_phase(str(definition.get("skill_phase_id", "")))
	world.active_round = {
		"stage": "skill",
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
		"inputs": [],
	}
	return [
		_log_event("skill_started", "%s began" % str(phase.get("name", "Skill")), {"skill_phase_id": str(phase.get("id", ""))}),
		_event(EtheraIds.EVENT_SKILL_STARTED, query_skill()),
	]


func _tick_skill() -> Array[Dictionary]:
	if world.active_round.is_empty() or str(world.active_round.get("stage", "")) != "skill":
		return []
	world.active_round["remaining_ms"] = int(world.active_round.get("remaining_ms", 0)) - EtheraWorld.MS_PER_TICK
	if _challenge() == EtheraIds.CHALLENGE_ALIGN:
		_update_alignment(_phase())
	if int(world.active_round.get("remaining_ms", 0)) <= 0:
		return _fail_skill("timeout")
	return [_event(EtheraIds.EVENT_SKILL_UPDATED, query_skill())]


func _skill_pointer(command: Dictionary) -> Array[Dictionary]:
	if world.active_round.is_empty() or str(world.active_round.get("stage", "")) != "skill":
		return []
	var pointer: Dictionary = {
		"x": clampf(float(command.get("x", 0.5)), 0.0, 1.0),
		"y": clampf(float(command.get("y", 0.5)), 0.0, 1.0),
	}
	world.active_round["pointer"] = pointer
	_record_skill_input(EtheraIds.CMD_SKILL_POINTER, pointer)
	if _challenge() == EtheraIds.CHALLENGE_TRACE:
		_hit_checkpoints(_phase(), pointer)
	return [_event(EtheraIds.EVENT_SKILL_UPDATED, query_skill())]


# Dispatch is on the phase's authored challenge, so a new phase of an existing kind is
# content rather than code.
func _skill_click(_command: Dictionary) -> Array[Dictionary]:
	if world.active_round.is_empty() or str(world.active_round.get("stage", "")) != "skill":
		return []
	_record_skill_input(EtheraIds.CMD_SKILL_CLICK, world.active_round.get("pointer", {"x": 0.5, "y": 0.5}))
	var phase: Dictionary = _phase()
	match _challenge():
		EtheraIds.CHALLENGE_TRACE:
			if _all_checkpoints_hit(phase):
				return _succeed_skill()
			return [_log_event("skill_click", "%s is not complete yet" % str(phase.get("name", "The challenge")))]
		EtheraIds.CHALLENGE_ALIGN:
			if _is_aligned(phase):
				return _succeed_skill()
			return [_log_event("skill_click", "%s click missed alignment or recess; time continues" % str(phase.get("name", "The challenge")))]
	return [_log_event("error", "Skill phase %s has no runtime challenge" % str(phase.get("id", "")), {"challenge": _challenge()})]


func _phase() -> Dictionary:
	return catalog.get_skill_phase(str(world.active_round.get("skill_phase_id", "")))


func _challenge() -> String:
	return str(_phase().get("challenge", ""))


# The actor never reports a score. It reports timestamped samples; the runtime decides
# what they mean. A validator re-runs those samples instead of trusting an outcome.
func _record_skill_input(kind: String, pointer: Dictionary) -> void:
	var inputs: Array = world.active_round.get("inputs", [])
	inputs.append({
		"tick": world.tick,
		"type": kind,
		"x": float(pointer.get("x", 0.5)),
		"y": float(pointer.get("y", 0.5)),
	})
	world.active_round["inputs"] = inputs


func _succeed_skill() -> Array[Dictionary]:
	var interaction_id: String = str(world.active_round.get("interaction_id", ""))
	var actor_id: String = str(world.active_round.get("actor_id", ""))
	var target_id: String = str(world.active_round.get("target_id", ""))
	if not evaluator.is_available(actor_id, target_id, interaction_id):
		return _fail_skill("invalidated")
	if results.requires_selection(interaction_id) and str(world.active_round.get("selected_shard_id", "")) == "":
		return _fail_skill("selection_empty")
	# Results, their event record and its recipients are all authored. The runtime does
	# not know which interaction this is.
	var resolved: Dictionary = results.resolve(world.active_round)
	if not bool(resolved.get("ok", false)):
		return _fail_skill(str(resolved.get("reason", "unknown_result")))
	var events: Array[Dictionary] = resolved.get("events", []) as Array[Dictionary]
	events.append(_log_event("action_succeeded", "%s succeeded" % catalog.get_interaction(interaction_id).get("name", interaction_id), {"interaction_id": interaction_id}))
	events.append(_event(EtheraIds.EVENT_SKILL_ENDED, {"outcome": "success", "interaction_id": interaction_id}))
	world.append_history(actor_id, {
		"interaction_id": interaction_id,
		"target_id": target_id,
		"world_time": world.world_time_ms,
		"outcome": "success",
	})
	world.active_round = {}
	return events


func _fail_skill(reason: String) -> Array[Dictionary]:
	var interaction_id: String = str(world.active_round.get("interaction_id", ""))
	var events: Array[Dictionary] = [
		_log_event("action_failed", "%s failed (%s)" % [catalog.get_interaction(interaction_id).get("name", interaction_id), reason], {"interaction_id": interaction_id, "reason": reason}),
		_event(EtheraIds.EVENT_SKILL_ENDED, {"outcome": "failure", "reason": reason, "interaction_id": interaction_id}),
	]
	world.active_round = {}
	return events


func _pickup_item(actor_id: String, item_id: String) -> Array[Dictionary]:
	if not world.active_round.is_empty():
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
	_begin_walk(
		actor_id,
		_point_beside(
			world.position_of(item),
			world.position_of(world.get_entity(actor_id)),
			float(world.tuning.get("pickup_approach_distance", 0.8))
		),
		"pickup",
		{"target_id": item_id}
	)
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
	# Open containers retain unclaimed content IDs until the revealed item is taken.
	# Removing the ID closes an emptied lid and prevents later swaps reopening it.
	for container_id in world.entities.keys():
		var container: Dictionary = world.get_entity(str(container_id))
		if not EtheraIds.is_container_kind(container.get("kind", "")) or not bool(container.get("opened", false)):
			continue
		var unclaimed: Array = container.get("contained_item_ids", [])
		if unclaimed.has(item_id):
			unclaimed.erase(item_id)
			world.bump(str(container_id), EtheraIds.CHANGE_MANIFESTATION)
	world.bump(item_id, EtheraIds.CHANGE_INVENTORY)
	events.append(_event(EtheraIds.EVENT_EQUIPMENT, {"entity_id": actor_id, "slot_id": slot_id, "item_id": item_id}))
	events.append(_log_event("equipment_changed", "Picked up %s" % item.get("name", item_id), {"item_id": item_id, "slot_id": slot_id}))
	world.commit_item(EtheraIds.TX_SWAP if previous_id != "" else EtheraIds.TX_PICKUP, {
		"entity_id": actor_id,
		"item_id": item_id,
		"slot_id": slot_id,
		"displaced_item_id": previous_id,
	})
	events.append_array(_record_inherent_shard(actor_id, item_id, EtheraIds.ACTION_PICKUP, EtheraIds.RESULT_PICKED_UP))
	events.append_array(_clear_walk(actor_id, "pickup"))
	return events


func _open_container(actor_id: String, target_id: String) -> Array[Dictionary]:
	if not world.active_round.is_empty():
		return [_log_event("blocked", "Cannot open a container during an interaction")]
	var hover: Dictionary = evaluator.hover_for(actor_id, target_id)
	if str(hover.get("kind", EtheraIds.HOVER_NONE)) != EtheraIds.HOVER_OPEN:
		return [_log_event("blocked", "That is not an unlocked closed container", {"target_id": target_id})]
	var actor_position: Vector3 = world.position_of(world.get_entity(actor_id))
	var target: Dictionary = world.get_entity(target_id)
	var target_position: Vector3 = world.position_of(target)
	var distance: float = _planar_distance(actor_position, target_position)
	var stand: float = _interact_stand_off(target)
	if distance > _interact_reach(target) or distance + 0.05 < stand:
		return _walk_to_open(actor_id, target_id)
	return _reveal_container(actor_id, target_id)


func _walk_to_open(actor_id: String, target_id: String) -> Array[Dictionary]:
	var target: Dictionary = world.get_entity(target_id)
	_begin_walk(
		actor_id,
		_point_beside(
			world.position_of(target),
			world.position_of(world.get_entity(actor_id)),
			_interact_stand_off(target)
		),
		"open",
		{"target_id": target_id}
	)
	return [
		_log_event("open_approach", "Walking to %s before opening it" % target.get("name", target_id), {"target_id": target_id}),
		_event(EtheraIds.EVENT_ENTITY_TRANSFORM, {"entity_id": actor_id, "reason": "open_walk_started"}),
	]


func _open_container_on_arrival(actor_id: String, target_id: String) -> Array[Dictionary]:
	var hover: Dictionary = evaluator.hover_for(actor_id, target_id)
	if str(hover.get("kind", EtheraIds.HOVER_NONE)) != EtheraIds.HOVER_OPEN:
		return [_log_event("blocked", "The container is no longer closed", {"target_id": target_id})]
	return _reveal_container(actor_id, target_id)


func _reveal_container(actor_id: String, target_id: String) -> Array[Dictionary]:
	var container: Dictionary = world.get_entity(target_id)
	container["opened"] = true
	world.bump(target_id, EtheraIds.CHANGE_MANIFESTATION)
	var events: Array[Dictionary] = []
	var origin: Vector3 = world.position_of(container)
	var drop_offset: Vector3 = _container_reveal_offset(actor_id, container)
	for item_id in container.get("contained_item_ids", []):
		var item: Dictionary = world.get_entity(str(item_id))
		if item.is_empty():
			continue
		item["manifested"] = true
		item["container_id"] = null
		item["holder_id"] = null
		item["position"] = EtheraWorld.quantized_point(origin + drop_offset)
		world.bump(str(item_id), EtheraIds.CHANGE_MANIFESTATION)
		events.append(_event(EtheraIds.EVENT_MANIFESTATION, {"entity_id": item_id, "manifested": true}))
	events.append(_log_event("container_opened", "Opened %s" % container.get("name", target_id), {"target_id": target_id}))
	events.append_array(_record_inherent_shard(actor_id, target_id, EtheraIds.ACTION_DISCOVERY, EtheraIds.RESULT_DISCOVERED))
	events.append_array(_clear_walk(actor_id, "open"))
	return events


func _tick_states() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for marker in world.expire_states():
		events.append(_log_event("state_changed", "%s ended" % marker, {"marker": marker}))
	return events


func _observe_target(actor_id: String, target_id: String) -> Array[Dictionary]:
	var actor: Dictionary = world.get_entity(actor_id)
	var landmark: Dictionary = world.get_entity(target_id)
	if actor.is_empty() or landmark.is_empty() or not world.is_manifested(actor) or not world.is_manifested(landmark):
		return []
	var radius: float = float(landmark.get("discovery_radius", 0.0))
	if radius <= 0.0:
		return []
	if _planar_distance(world.position_of(actor), world.position_of(landmark)) > radius:
		return []
	return _discover_place(actor_id, target_id)


func _discover_place(actor_id: String, target_id: String) -> Array[Dictionary]:
	if _knows_discovery_of(actor_id, target_id):
		return []
	var landmark: Dictionary = world.get_entity(target_id)
	var place_id: String = str(landmark.get("place_id", world.place_id))
	var place: Dictionary = world.places.get(place_id, {})
	var place_name: String = str(place.get("name", landmark.get("name", target_id)))
	var shard: Dictionary = world.create_shard({
		"actor_ids": [actor_id],
		"target_ids": [target_id],
		"action_id": EtheraIds.ACTION_DISCOVERY,
		"reaction_ids": [EtheraIds.REACTION_NONE],
		"result_ids": [EtheraIds.RESULT_DISCOVERED],
		"place_id": place_id,
		"world_time": world.world_time_ms,
	})
	var shard_id: String = str(shard["id"])
	var events: Array[Dictionary] = [_event(EtheraIds.EVENT_SHARD_CREATED, shard)]
	if world.grant_shard(actor_id, shard_id):
		events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": actor_id, "shard_id": shard_id, "granted": true}))
	events.append(_log_event("place_discovered", "Discovered %s" % place_name, {
		"target_id": target_id,
		"place_id": place_id,
		"place_name": place_name,
		"shard_id": shard_id,
	}))
	return events


func _knows_discovery_of(actor_id: String, target_id: String) -> bool:
	for shard_id in world.known_shards(world.get_entity(actor_id)):
		var shard: Dictionary = world.shards.get(str(shard_id), {})
		if str(shard.get("action_id", "")) != EtheraIds.ACTION_DISCOVERY:
			continue
		if (shard.get("target_ids", []) as Array).has(target_id):
			return true
	return false


func _record_inherent_shard(actor_id: String, target_id: String, action_id: String, result_id: String) -> Array[Dictionary]:
	if action_id == EtheraIds.ACTION_PICKUP:
		world.forget_pickup_shards_for(actor_id, target_id)
	var shard: Dictionary = world.create_shard({
		"actor_ids": [actor_id],
		"target_ids": [target_id],
		"action_id": action_id,
		"reaction_ids": [EtheraIds.REACTION_NONE],
		"result_ids": [result_id],
		"place_id": str(world.get_entity(actor_id).get("place_id", world.place_id)),
		"world_time": world.world_time_ms,
	})
	var shard_id: String = str(shard["id"])
	var events: Array[Dictionary] = [_event(EtheraIds.EVENT_SHARD_CREATED, shard)]
	if world.grant_shard(actor_id, shard_id):
		events.append(_event(EtheraIds.EVENT_SHARD_REFERENCE, {"entity_id": actor_id, "shard_id": shard_id, "granted": true}))
	events.append(_log_event("shard_created", "%s Shard created; only the actor knows it" % action_id, {
		"shard_id": shard_id,
		"action_id": action_id,
		"target_id": target_id,
	}))
	return events


func _hit_checkpoints(phase: Dictionary, pointer: Dictionary) -> void:
	var radius: float = float(phase.get("checkpoint_radius", 0.05))
	var hit: Dictionary = world.active_round.get("checkpoints_hit", {})
	for checkpoint in phase.get("checkpoints", []):
		var dx: float = float(pointer.get("x", 0.0)) - float(checkpoint.get("x", 0.0))
		var dy: float = float(pointer.get("y", 0.0)) - float(checkpoint.get("y", 0.0))
		if Vector2(dx, dy).length() <= radius:
			hit[str(checkpoint.get("id", ""))] = true
	world.active_round["checkpoints_hit"] = hit


func _all_checkpoints_hit(phase: Dictionary) -> bool:
	var authored: Array = phase.get("checkpoints", [])
	if authored.is_empty():
		return false
	var hit: Dictionary = world.active_round.get("checkpoints_hit", {})
	for checkpoint in authored:
		if not bool(hit.get(str(checkpoint.get("id", "")), false)):
			return false
	return true


func _update_alignment(phase: Dictionary) -> void:
	var rotation: Dictionary = phase.get("rotation", {})
	var elapsed: float = float(int(world.active_round.get("duration_ms", 0)) - int(world.active_round.get("remaining_ms", 0)))
	var period: float = max(float(rotation.get("period_ms", 1800.0)), 1.0)
	var align: float = float(rotation.get("align_at_degrees", 0.0))
	var oscillation: float = float(rotation.get("oscillation_degrees", 40.0))
	# The alignment check reads this value, so the platform's sin() is quantized before it
	# can decide whether a click succeeded.
	world.active_round["rotation_degrees"] = EtheraWorld.quantize(
		align + oscillation * sin(TAU * elapsed / period),
		EtheraWorld.DEGREE_QUANTUM
	)


func _is_aligned(phase: Dictionary) -> bool:
	var recess: Dictionary = phase.get("recess", {})
	var pointer: Dictionary = world.active_round.get("pointer", {"x": 0.5, "y": 0.5})
	var dx: float = float(pointer.get("x", 0.0)) - float(recess.get("x", 0.5))
	var dy: float = float(pointer.get("y", 0.0)) - float(recess.get("y", 0.5))
	if Vector2(dx, dy).length() > float(recess.get("radius", 0.08)):
		return false
	var rotation: Dictionary = phase.get("rotation", {})
	var delta: float = absf(float(world.active_round.get("rotation_degrees", 0.0)) - float(rotation.get("align_at_degrees", 0.0)))
	while delta > 180.0:
		delta -= 360.0
	return absf(delta) <= float(rotation.get("tolerance_degrees", 12.0))


func _interact_stand_off(target: Dictionary) -> float:
	var occupancy: float = world.occupancy_radius(target)
	if occupancy <= 0.0:
		return float(world.tuning.get("pickup_approach_distance", 0.8))
	return occupancy + float(world.tuning.get("object_stand_off", 0.35))


func _interact_reach(target: Dictionary) -> float:
	return maxf(float(world.tuning.get("pickup_reach", 1.1)), _interact_stand_off(target) + 0.05)


func _approach_point(actor: Dictionary, target: Dictionary, definition: Dictionary) -> Vector3:
	# Authored interactions stand on the side the actor is already on, at the
	# interaction's ring distance. A single stand point is not used.
	return _point_beside(
		world.position_of(target),
		world.position_of(actor),
		float(definition.get("approach", {}).get("distance", 1.45))
	)


# Revealed contents sit to the object's left or right, never on the opener's stand-off.
func _container_reveal_offset(actor_id: String, container: Dictionary) -> Vector3:
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
		"attachment": str(entity.get("attachment", "back")),
		"equipment_slot_id": str(entity.get("equipment_slot_id", "")),
		"template_id": str(entity.get("template_id", "")),
		"occupancy_radius": world.occupancy_radius(entity),
		"discovery_radius": float(entity.get("discovery_radius", 0.0)),
		"discovered_by_inhabited": _knows_discovery_of(world.inhabited_entity_id, str(entity.get("id", ""))),
		"container_opened": EtheraIds.is_container_kind(entity.get("kind", "")) and bool(entity.get("opened", false)),
		"container_lid_open": str(entity.get("kind", "")) == EtheraIds.KIND_CONTAINER and bool(entity.get("opened", false)) and not (entity.get("contained_item_ids", []) as Array).is_empty(),
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


func _state_summaries(entity: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var until: Dictionary = entity.get("state_until", {})
	for state_id in entity.get("states", []):
		var definition: Dictionary = catalog.states.get(str(state_id), {})
		var ends_at: int = int(until.get(str(state_id), 0))
		result.append({
			"id": str(state_id),
			"name": str(definition.get("name", state_id)),
			"description": str(definition.get("description", "")),
			"walk_speed_scale": float(definition.get("walk_speed_scale", 1.0)),
			"duration_ms": int(definition.get("duration_ms", 0)),
			"remaining_ms": maxi(0, ends_at - world.world_time_ms) if ends_at > 0 else 0,
		})
	return result


func _shard_summaries(ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for shard_id in ids:
		var shard: Dictionary = resolve_shard(shard_id)
		var targets: Array[String] = []
		for target_id in shard.get("target_ids", []):
			var target: Dictionary = world.get_entity(str(target_id))
			targets.append(str(target.get("name", target_id)) if not target.is_empty() else str(target_id))
		result.append({
			"id": shard_id,
			"action_id": str(shard.get("action_id", "")),
			"actor_ids": shard.get("actor_ids", []),
			"target_ids": shard.get("target_ids", []),
			"target_names": targets,
			"reaction_ids": shard.get("reaction_ids", []),
			"result_ids": shard.get("result_ids", []),
			"place_id": str(shard.get("place_id", "")),
			"place_name": str(world.places.get(str(shard.get("place_id", "")), {}).get("name", shard.get("place_id", ""))),
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
