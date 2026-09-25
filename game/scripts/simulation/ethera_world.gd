extends RefCounted
class_name EtheraWorld

const HISTORY_LIMIT := 100
const DEV_LOG_LIMIT := 200
const TX_LIMIT := 50
const SNAPSHOT_SCHEMA := "ethera.world.snapshot.v1"

# The authoritative clock advances in whole ticks. World time is derived from the
# tick count, never from a frame delta, so every node reaches the same timestamps.
const TICKS_PER_SECOND := 20
const MS_PER_TICK := 1000 / TICKS_PER_SECOND
const SECONDS_PER_TICK := 1.0 / float(TICKS_PER_SECOND)

# Authoritative quantities snap to these grids before they are stored. The quanta are
# powers of two so the snapping itself is exact in binary floating point, which keeps
# platform-dependent sin/cos/atan2 results from ever reaching stored state.
const POSITION_QUANTUM := 1024.0
const ANGLE_QUANTUM := 4096.0
const DEGREE_QUANTUM := 64.0
const SPEED_QUANTUM := 1024.0

var catalog: EtheraCatalog
var entities: Dictionary = {}
var places: Dictionary = {}
var shards: Dictionary = {}
var tick: int = 0
var world_time_ms: int = 0
var id_seq: int = 0
# Advances only when a new objective is chosen among several free solutions.
var objective_pick_seed: int = 1
var inhabited_entity_id: String = ""
var place_id: String = ""
var tuning: Dictionary = {}
# Tests may replace the starting-hex height. Production uses EtheraTerrain.height_at.
var terrain_sampler: Callable = Callable()
var change_versions: Dictionary = {}
var interaction_history: Dictionary = {}
var dev_log: Array[Dictionary] = []

# In-flight action state belongs to the world, not to the simulation object, so a
# snapshot or a handoff to another node carries an interaction that is still running.
var walk_motor: Dictionary = {}
var active_round: Dictionary = {}
var focus_hold: Dictionary = {}
var transactions: Dictionary = {}

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
	for raw in catalog.milestone1_landscape.get("entities", []):
		if typeof(raw) != TYPE_DICTIONARY or not raw.has("id"):
			continue
		var scatter: Dictionary = _normalize_entity(raw.duplicate(true))
		entities[str(scatter["id"])] = scatter
		_ensure_versions(str(scatter["id"]))


func advance_tick() -> void:
	tick += 1
	world_time_ms = tick * MS_PER_TICK


# How many whole ticks a presentation layer's accumulated frame time has earned. The
# caller keeps the remainder, which is what makes world time independent of frame rate.
static func ticks_available(accumulated_ms: float) -> int:
	if accumulated_ms < 0.0:
		return 0
	return int(accumulated_ms) / MS_PER_TICK


# Round half away from zero, matching the rounding the Rust runtime will use.
static func quantize(value: float, quantum: float) -> float:
	return round(value * quantum) / quantum


# Any authoritative point stored outside set_position goes through here, so nothing
# reaches state off the grid. World state holds only plain data, never engine types, so
# the whole world serializes without conversion.
static func quantized_point(point: Vector3) -> Dictionary:
	return {
		"x": quantize(point.x, POSITION_QUANTUM),
		"y": quantize(point.y, POSITION_QUANTUM),
		"z": quantize(point.z, POSITION_QUANTUM),
	}


static func to_vector(point: Variant) -> Vector3:
	if typeof(point) != TYPE_DICTIONARY:
		return Vector3.ZERO
	return Vector3(float(point.get("x", 0.0)), float(point.get("y", 0.0)), float(point.get("z", 0.0)))


func add_entity(raw: Dictionary) -> Dictionary:
	var entity: Dictionary = _normalize_entity(raw.duplicate(true))
	var entity_id: String = str(entity.get("id", ""))
	entities[entity_id] = entity
	_ensure_versions(entity_id)
	return entity


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
	if not _string_array(entity.get("traits", [])).has(trait_id):
		return false
	# A state's blocked traits are disabled on the entity that carries the state.
	for state_id in _string_array(entity.get("states", [])):
		var state: Dictionary = catalog.states.get(str(state_id), {})
		if _string_array(state.get("blocked_trait_ids", [])).has(trait_id):
			return false
	return true


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
	if not states.has(state_id):
		states.append(state_id)
		entity["states"] = states
	var duration_ms: int = int(catalog.states.get(state_id, {}).get("duration_ms", 0))
	var until: Dictionary = entity.get("state_until", {})
	if duration_ms > 0:
		until[state_id] = world_time_ms + duration_ms
	entity["state_until"] = until
	bump(entity_id, EtheraIds.CHANGE_STATES)


func remove_state(entity_id: String, state_id: String) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	var states: Array[String] = _string_array(entity.get("states", []))
	states.erase(state_id)
	entity["states"] = states
	var until: Dictionary = entity.get("state_until", {})
	until.erase(state_id)
	entity["state_until"] = until
	bump(entity_id, EtheraIds.CHANGE_STATES)


func expire_states() -> Array[String]:
	var expired: Array[String] = []
	for entity_id in entities.keys():
		var entity: Dictionary = get_entity(str(entity_id))
		var until: Dictionary = entity.get("state_until", {})
		if until.is_empty():
			continue
		var due: Array[String] = []
		for state_id in until.keys():
			if int(until[state_id]) <= world_time_ms:
				due.append(str(state_id))
		for state_id in due:
			remove_state(str(entity_id), state_id)
			expired.append("%s:%s" % [entity_id, state_id])
	return expired


func movement_speed_scale(entity: Dictionary) -> float:
	var scale: float = 1.0
	for state_id in entity.get("states", []):
		scale *= float(catalog.states.get(str(state_id), {}).get("walk_speed_scale", 1.0))
	return scale


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


func remember_interaction(actor_id: String, interaction_id: String) -> bool:
	var actor: Dictionary = get_entity(actor_id)
	if actor.is_empty() or interaction_id == "":
		return false
	var known: Array[String] = _string_array(actor.get("known_interaction_ids", []))
	if known.has(interaction_id):
		return false
	known.append(interaction_id)
	actor["known_interaction_ids"] = known
	bump(actor_id, EtheraIds.CHANGE_TRAITS)
	return true


func forget_shard(entity_id: String, shard_id: String) -> bool:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return false
	var known: Array[String] = known_shards(entity)
	if not known.has(shard_id):
		return false
	known.erase(shard_id)
	entity["known_shard_ids"] = known
	bump(entity_id, EtheraIds.CHANGE_SHARDS)
	if not _shard_is_held(shard_id):
		shards.erase(shard_id)
	return true


func forget_pickup_shards_for(actor_id: String, item_id: String) -> void:
	var actor: Dictionary = get_entity(actor_id)
	var prior: Array[String] = known_shards(actor)
	for shard_id in prior:
		var shard: Dictionary = shards.get(shard_id, {})
		if str(shard.get("action_id", "")) != EtheraIds.ACTION_PICKUP:
			continue
		if not _targets_include(shard, item_id):
			continue
		forget_shard(actor_id, shard_id)


func _targets_include(shard: Dictionary, entity_id: String) -> bool:
	for target_id in shard.get("target_ids", []):
		if str(target_id) == entity_id:
			return true
	return false


func _shard_is_held(shard_id: String) -> bool:
	for entity_id in entities.keys():
		if knows_shard(get_entity(str(entity_id)), shard_id):
			return true
	return false


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
	return to_vector(entity.get("position", {}))


func occupancy_radius(entity: Dictionary) -> float:
	if entity.is_empty() or not is_manifested(entity):
		return 0.0
	if str(entity.get("kind", "")) == EtheraIds.KIND_GRASS:
		return 0.0
	if entity.has("occupancy"):
		return max(0.0, float((entity["occupancy"] as Dictionary).get("radius", 0.0)))
	match str(entity.get("kind", "")):
		"memory_fountain":
			return 2.5
		"world_object":
			return 0.55
		"character":
			return float(tuning.get("body_radius", 0.38))
		"container":
			return 0.45
		"landmark":
			return 3.2
		_:
			return 0.0


func blockers_near(ignore_ids: Array = []) -> Array[Dictionary]:
	var ignored: Dictionary = {}
	for ignore_id in ignore_ids:
		ignored[str(ignore_id)] = true
	var result: Array[Dictionary] = []
	for entity_id in entities.keys():
		if ignored.has(str(entity_id)):
			continue
		var entity: Dictionary = get_entity(str(entity_id))
		var radius: float = occupancy_radius(entity)
		if radius <= 0.0:
			continue
		var position: Vector3 = position_of(entity)
		result.append({
			"id": str(entity_id),
			"x": position.x,
			"z": position.z,
			"radius": radius,
		})
	var place: Dictionary = places.get(place_id, {})
	for raw in place.get("blockers", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		result.append({
			"id": str(raw.get("id", "blocker")),
			"x": float(raw.get("x", 0.0)),
			"z": float(raw.get("z", 0.0)),
			"radius": max(0.0, float(raw.get("radius", 0.0))),
		})
	return result


func walkable_slope_degrees() -> float:
	return float(tuning.get("walkable_slope_degrees", EtheraTerrain.WALKABLE_SLOPE_DEGREES))


func terrain_height_at(x: float, z: float) -> float:
	if terrain_sampler.is_valid():
		return float(terrain_sampler.call(x, z))
	return EtheraTerrain.height_at(x, z)


func is_too_steep(point: Vector3) -> bool:
	return not EtheraTerrain.is_walkable(point.x, point.z, walkable_slope_degrees(), terrain_sampler)


# Last open point on the segment before ground steeper than walkable_slope_degrees.
# A click through a cliff walks to that face, the same way a click through a rock
# walks to the rim. Does not invent a path around the hillside.
func last_walkable_toward(from: Vector3, dest: Vector3) -> Vector3:
	var start_steep: bool = is_too_steep(from)
	var delta: Vector3 = dest - from
	delta.y = 0.0
	var length: float = delta.length()
	if length < 0.001:
		if is_too_steep(dest):
			return from
		return dest
	var step: float = maxf(0.16, float(tuning.get("path_cell", 0.32)) * 0.5)
	var count: int = maxi(1, int(ceil(length / step)))
	var last_ok: Vector3 = from
	for i in range(1, count + 1):
		var point: Vector3 = from.lerp(dest, float(i) / float(count))
		point.y = from.y
		var steep: bool = is_too_steep(point)
		if start_steep:
			if not steep:
				start_steep = false
				last_ok = point
			continue
		if steep:
			return last_ok
		last_ok = point
	if is_too_steep(dest):
		return last_ok
	return dest


func is_blocked(point: Vector3, mover_radius: float, ignore_ids: Array = []) -> bool:
	if is_too_steep(point):
		return true
	return not first_blocker(point, mover_radius, ignore_ids).is_empty()


func first_blocker(point: Vector3, mover_radius: float, ignore_ids: Array = []) -> Dictionary:
	for blocker in blockers_near(ignore_ids):
		var dx: float = point.x - float(blocker.get("x", 0.0))
		var dz: float = point.z - float(blocker.get("z", 0.0))
		var limit: float = float(blocker.get("radius", 0.0)) + mover_radius
		if dx * dx + dz * dz < limit * limit:
			return blocker
	return {}


# Push a point just outside the first overlapping solid. Used so a click onto a
# fountain walks to its rim instead of through its centre.
func nearest_open_point(point: Vector3, mover_radius: float, ignore_ids: Array = []) -> Vector3:
	var resolved: Vector3 = point
	for _i in range(8):
		var blocker: Dictionary = first_blocker(resolved, mover_radius, ignore_ids)
		if blocker.is_empty():
			return resolved
		var center := Vector3(float(blocker.get("x", 0.0)), resolved.y, float(blocker.get("z", 0.0)))
		var away: Vector3 = resolved - center
		away.y = 0.0
		if away.length() < 0.0001:
			away = Vector3(1.0, 0.0, 0.0)
		var limit: float = float(blocker.get("radius", 0.0)) + mover_radius + 0.02
		resolved = center + away.normalized() * limit
	return resolved


# If the straight step hits a solid, slide along it. If even that is blocked, stay put.
func slide_move(from: Vector3, to: Vector3, mover_radius: float, ignore_ids: Array = []) -> Vector3:
	if not is_blocked(to, mover_radius, ignore_ids):
		return to
	var blocker: Dictionary = first_blocker(to, mover_radius, ignore_ids)
	if blocker.is_empty():
		return from
	var center := Vector3(float(blocker.get("x", 0.0)), from.y, float(blocker.get("z", 0.0)))
	var away: Vector3 = from - center
	away.y = 0.0
	if away.length() < 0.0001:
		return nearest_open_point(from, mover_radius, ignore_ids)
	var normal: Vector3 = away.normalized()
	var step: Vector3 = to - from
	var slide: Vector3 = step - normal * step.dot(normal)
	var slid: Vector3 = from + slide
	if not is_blocked(slid, mover_radius, ignore_ids):
		return slid
	return from


func walk_radius(mover_radius: float = NAN) -> float:
	var body: float = mover_radius
	if is_nan(body):
		body = float(tuning.get("body_radius", 0.38))
	return body + float(tuning.get("walk_clearance", 0.22))


# Right-click walks go up to the first solid, then grid only around that solid.
# Interaction, pickup and open walks keep going to their stand-off instead of
# closing in and then snapping back to the ring.
func find_walk_path(from: Vector3, dest: Vector3, mover_radius: float, ignore_ids: Array = [], lazy: bool = true) -> Array:
	var start: Vector3 = nearest_open_point(from, mover_radius, ignore_ids)
	var goal: Vector3 = nearest_open_point(dest, mover_radius, ignore_ids)
	start.y = from.y
	goal.y = from.y
	var slope_goal: Vector3 = last_walkable_toward(start, goal)
	var slope_cut: bool = start.distance_to(slope_goal) + 0.05 < start.distance_to(goal)
	var blocker: Dictionary = first_path_blocker(start, goal, mover_radius, ignore_ids)
	if slope_cut:
		var slope_dist: float = start.distance_to(slope_goal)
		var disk_dist: float = INF
		if not blocker.is_empty():
			var disk := Vector3(float(blocker.get("x", 0.0)), start.y, float(blocker.get("z", 0.0)))
			disk_dist = maxf(0.0, start.distance_to(disk) - float(blocker.get("radius", 0.0)) - mover_radius)
		if slope_dist <= disk_dist + 0.05:
			return [slope_goal]
	if blocker.is_empty():
		return [goal]
	var center := Vector3(float(blocker.get("x", 0.0)), start.y, float(blocker.get("z", 0.0)))
	var avoid: float = float(blocker.get("radius", 0.0)) + mover_radius
	var approach: Vector3 = _point_before_disk(start, goal, center, avoid + 0.8)
	var dx: float = start.x - center.x
	var dz: float = start.z - center.z
	if lazy and sqrt(dx * dx + dz * dz) > avoid + 5.0:
		return [approach]
	var far: Vector3 = _point_after_disk(start, goal, center, avoid + 0.8)
	var blockers: Array[Dictionary] = blockers_near(ignore_ids)
	var around: Array = _grid_path(start, far, mover_radius, blockers, _blocker_bounds(start, far, center, avoid + 8.0))
	if around.is_empty():
		around = [far]
	var last: Vector3 = around[around.size() - 1]
	if last.distance_to(goal) > 0.05:
		var more: Vector3 = last_walkable_toward(last, goal)
		if first_path_blocker(last, more, mover_radius, ignore_ids).is_empty() and last.distance_to(more) > 0.05:
			around.append(more)
	return _simplify_walk_path(start, around, mover_radius, ignore_ids)


func _grid_path(start: Vector3, goal: Vector3, mover_radius: float, blockers: Array, bounds: Dictionary) -> Array:
	var cell: float = max(0.16, float(tuning.get("path_cell", 0.32)))
	var origin_x: float = float(bounds["min_x"])
	var origin_z: float = float(bounds["min_z"])
	var width: int = int(ceil((float(bounds["max_x"]) - origin_x) / cell))
	var height: int = int(ceil((float(bounds["max_z"]) - origin_z) / cell))
	if width < 1 or height < 1:
		return [goal]
	var start_cell: Vector2i = _path_clamp_cell(_world_to_path_cell(start, origin_x, origin_z, cell), width, height)
	var goal_cell: Vector2i = _path_clamp_cell(_world_to_path_cell(goal, origin_x, origin_z, cell), width, height)
	var blocked: Dictionary = {}
	start_cell = _nearest_open_cell(start_cell, width, height, origin_x, origin_z, cell, start.y, mover_radius, blockers, blocked)
	goal_cell = _nearest_open_cell(goal_cell, width, height, origin_x, origin_z, cell, start.y, mover_radius, blockers, blocked)
	var came: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	var start_key: String = _path_cell_key(start_cell)
	g_score[start_key] = 0.0
	f_score[start_key] = _path_octile(start_cell, goal_cell)
	var open: Array[Vector2i] = [start_cell]
	var closed: Dictionary = {}
	var best: Vector2i = start_cell
	var best_h: float = _path_octile(start_cell, goal_cell)
	var expansions: int = 0
	while not open.is_empty() and expansions < 2500:
		var current: Vector2i = _path_pop_best(open, f_score, g_score)
		expansions += 1
		if current == goal_cell:
			best = current
			break
		var current_key: String = _path_cell_key(current)
		closed[current_key] = true
		var current_h: float = _path_octile(current, goal_cell)
		if current_h < best_h - 0.0001 or (absf(current_h - best_h) <= 0.0001 and float(g_score.get(current_key, INF)) < float(g_score.get(_path_cell_key(best), INF))):
			best = current
			best_h = current_h
		for dz in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				var neighbor := Vector2i(current.x + dx, current.y + dz)
				if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
					continue
				var neighbor_key: String = _path_cell_key(neighbor)
				if closed.has(neighbor_key):
					continue
				if _path_cell_blocked(neighbor, width, height, origin_x, origin_z, cell, start.y, mover_radius, blockers, blocked):
					continue
				if dx != 0 and dz != 0:
					var side_a := Vector2i(current.x + dx, current.y)
					var side_b := Vector2i(current.x, current.y + dz)
					if _path_cell_blocked(side_a, width, height, origin_x, origin_z, cell, start.y, mover_radius, blockers, blocked):
						continue
					if _path_cell_blocked(side_b, width, height, origin_x, origin_z, cell, start.y, mover_radius, blockers, blocked):
						continue
				var step_cost: float = 1.41421356 if dx != 0 and dz != 0 else 1.0
				var tentative: float = float(g_score.get(current_key, INF)) + step_cost
				if tentative + 0.000001 >= float(g_score.get(neighbor_key, INF)):
					continue
				came[neighbor_key] = current
				g_score[neighbor_key] = tentative
				f_score[neighbor_key] = tentative + _path_octile(neighbor, goal_cell)
				if not _path_open_has(open, neighbor):
					open.append(neighbor)
	var cells: Array[Vector2i] = _reconstruct_path_cells(came, start_cell, best)
	var points: Array = []
	for cell_i in range(cells.size()):
		if cell_i == 0:
			continue
		var world_point: Vector3 = _path_cell_center(cells[cell_i], origin_x, origin_z, cell, start.y)
		if not _point_hits_blockers(world_point, mover_radius, blockers) and not is_too_steep(world_point):
			points.append(world_point)
	if points.is_empty() or points[points.size() - 1].distance_to(goal) > 0.001:
		points.append(goal)
	return points


func first_path_blocker(from: Vector3, dest: Vector3, mover_radius: float, ignore_ids: Array = []) -> Dictionary:
	var hit: Dictionary = {}
	var nearest: float = INF
	for blocker in blockers_near(ignore_ids):
		var radius: float = float(blocker.get("radius", 0.0)) + mover_radius
		if not _ahead_hits_disk(from, dest, float(blocker.get("x", 0.0)), float(blocker.get("z", 0.0)), radius):
			continue
		var dx: float = from.x - float(blocker.get("x", 0.0))
		var dz: float = from.z - float(blocker.get("z", 0.0))
		var distance: float = dx * dx + dz * dz
		if distance < nearest:
			nearest = distance
			hit = blocker
	return hit


# A solid only steers the walk if the path ahead enters it. Standing beside one
# must not count as already being blocked from leaving.
func _ahead_hits_disk(from: Vector3, dest: Vector3, cx: float, cz: float, radius: float) -> bool:
	var dest_dx: float = dest.x - cx
	var dest_dz: float = dest.z - cz
	var dest_inside: bool = dest_dx * dest_dx + dest_dz * dest_dz < radius * radius
	var abx: float = dest.x - from.x
	var abz: float = dest.z - from.z
	var acx: float = cx - from.x
	var acz: float = cz - from.z
	var ab2: float = abx * abx + abz * abz
	if ab2 < 0.0000001:
		return dest_inside
	var t: float = clampf((acx * abx + acz * abz) / ab2, 0.0, 1.0)
	if t <= 0.001:
		return dest_inside
	var px: float = from.x + abx * t
	var pz: float = from.z + abz * t
	var dx: float = px - cx
	var dz: float = pz - cz
	return dx * dx + dz * dz < radius * radius


func _path_bounds(start: Vector3, goal: Vector3) -> Dictionary:
	var pad: float = 10.0
	return {
		"min_x": minf(start.x, goal.x) - pad,
		"max_x": maxf(start.x, goal.x) + pad,
		"min_z": minf(start.z, goal.z) - pad,
		"max_z": maxf(start.z, goal.z) + pad,
	}


func _blocker_bounds(start: Vector3, goal: Vector3, center: Vector3, pad: float) -> Dictionary:
	return {
		"min_x": minf(minf(start.x, goal.x), center.x) - pad,
		"max_x": maxf(maxf(start.x, goal.x), center.x) + pad,
		"min_z": minf(minf(start.z, goal.z), center.z) - pad,
		"max_z": maxf(maxf(start.z, goal.z), center.z) + pad,
	}


func _segment_disk_times(from: Vector3, dest: Vector3, center: Vector3, radius: float) -> Vector2:
	var dx: float = dest.x - from.x
	var dz: float = dest.z - from.z
	var fx: float = from.x - center.x
	var fz: float = from.z - center.z
	var a: float = dx * dx + dz * dz
	if a < 0.0000001:
		return Vector2(INF, INF)
	var b: float = 2.0 * (fx * dx + fz * dz)
	var c: float = fx * fx + fz * fz - radius * radius
	var disc: float = b * b - 4.0 * a * c
	if disc < 0.0:
		return Vector2(INF, INF)
	var root: float = sqrt(disc)
	var t0: float = (-b - root) / (2.0 * a)
	var t1: float = (-b + root) / (2.0 * a)
	if t0 > t1:
		var swap: float = t0
		t0 = t1
		t1 = swap
	return Vector2(t0, t1)


func _point_before_disk(from: Vector3, dest: Vector3, center: Vector3, radius: float) -> Vector3:
	var times: Vector2 = _segment_disk_times(from, dest, center, radius)
	var along := Vector3(dest.x - from.x, 0.0, dest.z - from.z)
	var hit: Vector3
	if times.x == INF:
		var away := Vector3(from.x - center.x, 0.0, from.z - center.z)
		if away.length() < 0.001:
			away = Vector3.RIGHT
		hit = Vector3(center.x, from.y, center.z) + away.normalized() * radius
	else:
		hit = from.lerp(dest, clampf(times.x, 0.0, 1.0))
	if along.length() > 0.001:
		hit -= along.normalized() * 0.35
	return Vector3(hit.x, from.y, hit.z)


func _point_after_disk(from: Vector3, dest: Vector3, center: Vector3, radius: float) -> Vector3:
	var times: Vector2 = _segment_disk_times(from, dest, center, radius)
	var along := Vector3(dest.x - from.x, 0.0, dest.z - from.z)
	var hit: Vector3
	if times.y == INF:
		hit = dest
	else:
		hit = from.lerp(dest, clampf(times.y, 0.0, 1.0))
	if along.length() > 0.001:
		hit += along.normalized() * 0.35
	return Vector3(hit.x, from.y, hit.z)


func _point_hits_blockers(point: Vector3, mover_radius: float, blockers: Array) -> bool:
	for blocker in blockers:
		var dx: float = point.x - float(blocker.get("x", 0.0))
		var dz: float = point.z - float(blocker.get("z", 0.0))
		var limit: float = float(blocker.get("radius", 0.0)) + mover_radius
		if dx * dx + dz * dz < limit * limit:
			return true
	return false


func _world_to_path_cell(point: Vector3, origin_x: float, origin_z: float, cell: float) -> Vector2i:
	return Vector2i(int(floor((point.x - origin_x) / cell)), int(floor((point.z - origin_z) / cell)))


func _path_cell_center(cell: Vector2i, origin_x: float, origin_z: float, cell_size: float, y: float) -> Vector3:
	return Vector3(origin_x + (float(cell.x) + 0.5) * cell_size, y, origin_z + (float(cell.y) + 0.5) * cell_size)


func _path_clamp_cell(cell: Vector2i, width: int, height: int) -> Vector2i:
	return Vector2i(clampi(cell.x, 0, width - 1), clampi(cell.y, 0, height - 1))


func _path_cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _path_octile(from_cell: Vector2i, to_cell: Vector2i) -> float:
	var dx: int = absi(from_cell.x - to_cell.x)
	var dz: int = absi(from_cell.y - to_cell.y)
	var longest: int = maxi(dx, dz)
	var shortest: int = mini(dx, dz)
	return float(longest - shortest) + float(shortest) * 1.41421356


func _path_open_has(open: Array[Vector2i], cell: Vector2i) -> bool:
	for existing in open:
		if existing == cell:
			return true
	return false


func _path_pop_best(open: Array[Vector2i], f_score: Dictionary, g_score: Dictionary) -> Vector2i:
	var best_index: int = 0
	var best: Vector2i = open[0]
	var best_f: float = float(f_score.get(_path_cell_key(best), INF))
	var best_g: float = float(g_score.get(_path_cell_key(best), INF))
	for i in range(1, open.size()):
		var candidate: Vector2i = open[i]
		var candidate_f: float = float(f_score.get(_path_cell_key(candidate), INF))
		var candidate_g: float = float(g_score.get(_path_cell_key(candidate), INF))
		var better: bool = candidate_f < best_f - 0.0001
		if not better and absf(candidate_f - best_f) <= 0.0001:
			if candidate_g < best_g - 0.0001:
				better = true
			elif absf(candidate_g - best_g) <= 0.0001:
				if candidate.x < best.x or (candidate.x == best.x and candidate.y < best.y):
					better = true
		if better:
			best_index = i
			best = candidate
			best_f = candidate_f
			best_g = candidate_g
	open.remove_at(best_index)
	return best


func _path_cell_blocked(
	cell: Vector2i,
	width: int,
	height: int,
	origin_x: float,
	origin_z: float,
	cell_size: float,
	y: float,
	mover_radius: float,
	blockers: Array,
	cache: Dictionary
) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	var key: String = _path_cell_key(cell)
	if cache.has(key):
		return bool(cache[key])
	var center: Vector3 = _path_cell_center(cell, origin_x, origin_z, cell_size, y)
	var blocked: bool = _point_hits_blockers(center, mover_radius, blockers) or is_too_steep(center)
	cache[key] = blocked
	return blocked


func _nearest_open_cell(
	cell: Vector2i,
	width: int,
	height: int,
	origin_x: float,
	origin_z: float,
	cell_size: float,
	y: float,
	mover_radius: float,
	blockers: Array,
	cache: Dictionary
) -> Vector2i:
	if not _path_cell_blocked(cell, width, height, origin_x, origin_z, cell_size, y, mover_radius, blockers, cache):
		return cell
	for radius in range(1, mini(32, maxi(width, height)) + 1):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dz)) != radius:
					continue
				var candidate := Vector2i(cell.x + dx, cell.y + dz)
				if not _path_cell_blocked(candidate, width, height, origin_x, origin_z, cell_size, y, mover_radius, blockers, cache):
					return candidate
	return cell


func _reconstruct_path_cells(came: Dictionary, start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [end_cell]
	var current: Vector2i = end_cell
	var guard: int = 0
	while current != start_cell and guard < 8000:
		guard += 1
		var previous: Variant = came.get(_path_cell_key(current), null)
		if previous == null:
			break
		current = previous
		cells.append(current)
	cells.reverse()
	return cells


func _simplify_walk_path(from: Vector3, points: Array, mover_radius: float, ignore_ids: Array) -> Array:
	if points.is_empty():
		return []
	var simplified: Array = []
	var cursor: Vector3 = from
	var i: int = 0
	while i < points.size():
		var farthest: int = i
		for j in range(i, points.size()):
			if first_path_blocker(cursor, points[j], mover_radius, ignore_ids).is_empty():
				farthest = j
		simplified.append(points[farthest])
		cursor = points[farthest]
		i = farthest + 1
	return simplified


func set_position(entity_id: String, position: Vector3, yaw: float = NAN) -> void:
	var entity: Dictionary = get_entity(entity_id)
	if entity.is_empty():
		return
	entity["position"] = quantized_point(position)
	if not is_nan(yaw):
		entity["yaw"] = quantize(yaw, ANGLE_QUANTUM)


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


# Locally the same node is the authority, so a transfer is accepted, reserved and
# committed in one step. The stored status is still the persistent end of
# PENDING → VALIDATING → COMMITTED; a later validator can leave it pending instead.
func commit_item(kind: String, fields: Dictionary) -> Dictionary:
	var item_id: String = str(fields.get("item_id", ""))
	var tx: Dictionary = {
		"id": str(fields.get("id", make_id("tx"))),
		"kind": kind,
		"item_id": item_id,
		"entity_id": str(fields.get("entity_id", "")),
		"slot_id": str(fields.get("slot_id", "")),
		"displaced_item_id": str(fields.get("displaced_item_id", "")),
		"tick": tick,
		"status": EtheraIds.COMMIT_COMMITTED,
	}
	transactions[str(tx["id"])] = tx
	while transactions.size() > TX_LIMIT:
		transactions.erase(str(transactions.keys()[0]))
	var item: Dictionary = get_entity(item_id)
	if not item.is_empty():
		item["commit_status"] = EtheraIds.COMMIT_COMMITTED
	var displaced_id: String = str(tx.get("displaced_item_id", ""))
	if displaced_id != "":
		var displaced: Dictionary = get_entity(displaced_id)
		if not displaced.is_empty():
			displaced["commit_status"] = EtheraIds.COMMIT_COMMITTED
	return tx


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
		"position": quantized_point(to_vector(extra.get("position", {"x": 0.0, "y": 0.0, "z": 0.0}))),
		"yaw": quantize(float(extra.get("yaw", 0.0)), ANGLE_QUANTUM),
		"manifested": bool(extra.get("manifested", true)),
		"commit_status": str(extra.get("commit_status", EtheraIds.COMMIT_COMMITTED)),
		"states": [],
		"presentation": template.get("presentation", {}).duplicate(true),
	}
	entities[str(item["id"])] = item
	_ensure_versions(str(item["id"]))
	return item


# Everything a node needs to continue this world, including an interaction still in
# progress. Content comes from the catalog and is identified rather than copied; the
# development log is an observation aid, not state, and is excluded.
func serialize() -> Dictionary:
	return {
		"schema": SNAPSHOT_SCHEMA,
		"tick": tick,
		"id_seq": id_seq,
		"objective_pick_seed": objective_pick_seed,
		"place_id": place_id,
		"inhabited_entity_id": inhabited_entity_id,
		"entities": entities.duplicate(true),
		"places": places.duplicate(true),
		"shards": shards.duplicate(true),
		"interaction_history": interaction_history.duplicate(true),
		"walk_motor": walk_motor.duplicate(true),
		"active_round": active_round.duplicate(true),
		"focus_hold": focus_hold.duplicate(true),
		"change_versions": change_versions.duplicate(true),
		"transactions": transactions.duplicate(true),
	}


func restore(snapshot: Dictionary) -> bool:
	if str(snapshot.get("schema", "")) != SNAPSHOT_SCHEMA:
		return false
	tick = int(snapshot.get("tick", 0))
	world_time_ms = tick * MS_PER_TICK
	id_seq = int(snapshot.get("id_seq", 0))
	objective_pick_seed = int(snapshot.get("objective_pick_seed", 1))
	place_id = str(snapshot.get("place_id", place_id))
	inhabited_entity_id = str(snapshot.get("inhabited_entity_id", inhabited_entity_id))
	entities = (snapshot.get("entities", {}) as Dictionary).duplicate(true)
	places = (snapshot.get("places", {}) as Dictionary).duplicate(true)
	shards = (snapshot.get("shards", {}) as Dictionary).duplicate(true)
	interaction_history = (snapshot.get("interaction_history", {}) as Dictionary).duplicate(true)
	walk_motor = (snapshot.get("walk_motor", {}) as Dictionary).duplicate(true)
	active_round = (snapshot.get("active_round", {}) as Dictionary).duplicate(true)
	focus_hold = (snapshot.get("focus_hold", {}) as Dictionary).duplicate(true)
	change_versions = (snapshot.get("change_versions", {}) as Dictionary).duplicate(true)
	transactions = (snapshot.get("transactions", {}) as Dictionary).duplicate(true)
	for entity_id in entities.keys():
		_ensure_versions(str(entity_id))
	return true


# A validator compares hashes, so the encoding must not depend on the order a node
# happened to insert its keys. Dictionary keys are sorted and floats are written at full
# precision; determinism comes from keeping platform-dependent values out of state, not
# from rounding them away here.
func hash_state() -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(canonical_encoding(serialize()).to_utf8_buffer())
	return context.finish().hex_encode()


static func canonical_encoding(value: Variant) -> String:
	match typeof(value):
		TYPE_DICTIONARY:
			var keys: Array = (value as Dictionary).keys()
			keys.sort()
			var pairs: PackedStringArray = PackedStringArray()
			for key in keys:
				pairs.append("%s=%s" % [str(key), canonical_encoding((value as Dictionary)[key])])
			return "{%s}" % ",".join(pairs)
		TYPE_ARRAY:
			var items: PackedStringArray = PackedStringArray()
			for item in value as Array:
				items.append(canonical_encoding(item))
			return "[%s]" % ",".join(items)
		TYPE_INT, TYPE_FLOAT:
			# Ints and whole floats must hash identically: JSON round-trips turn 20 into 20.0.
			# Godot's % operator has no %g, so this uses String.num rather than C printf.
			return String.num(float(value), 17)
		TYPE_BOOL:
			return "true" if bool(value) else "false"
		TYPE_NIL:
			return "null"
		_:
			return str(value)


func villager_count() -> int:
	var count := 0
	for entity_id in entities.keys():
		var entity: Dictionary = get_entity(str(entity_id))
		if str(entity.get("kind", "")) == "character" and is_manifested(entity) and has_trait(entity, EtheraIds.TRAIT_GRIMNIR):
			count += 1
	return count


func store_count(trait_id: String) -> int:
	var hall: Dictionary = get_entity(EtheraIds.ENTITY_TOWN_HALL)
	var count := 0
	for item_id in hall.get("contained_item_ids", []):
		if has_trait(get_entity(str(item_id)), trait_id):
			count += 1
	return count


# Weapon deliveries come first, then herbs. One shortfall is one task.
func next_village_task() -> String:
	var villagers: int = villager_count()
	if store_count(EtheraIds.TRAIT_STONE_WEAPON) < villagers:
		return EtheraIds.TASK_DELIVER_STONE_WEAPON
	if store_count(EtheraIds.TRAIT_HERB) < villagers:
		return EtheraIds.TASK_DELIVER_OFFERING_HERB
	return ""


func _normalize_entity(entity: Dictionary) -> Dictionary:
	entity["traits"] = _string_array(entity.get("traits", []))
	entity["states"] = _string_array(entity.get("states", []))
	if not entity.has("state_until"):
		entity["state_until"] = {}
	entity["known_shard_ids"] = _string_array(entity.get("known_shard_ids", []))
	entity["needed_shard_ids"] = _string_array(entity.get("needed_shard_ids", []))
	entity["known_interaction_ids"] = _string_array(entity.get("known_interaction_ids", []))
	if not entity.has("manifested"):
		entity["manifested"] = true
	if not entity.has("position"):
		entity["position"] = {"x": 0.0, "y": 0.0, "z": 0.0}
	if entity.get("kind", "") == "character":
		var equipment: Dictionary = entity.get("equipment", {})
		if not equipment.has(EtheraIds.SLOT_SMALL_WEAPON):
			equipment[EtheraIds.SLOT_SMALL_WEAPON] = null
		if not equipment.has(EtheraIds.SLOT_HERB):
			equipment[EtheraIds.SLOT_HERB] = null
		entity["equipment"] = equipment
	if entity.get("kind", "") == "item" and not entity.has("commit_status"):
		entity["commit_status"] = EtheraIds.COMMIT_COMMITTED
	if entity.has("contained_item_ids"):
		entity["contained_item_ids"] = _string_array(entity.get("contained_item_ids", []))
	if EtheraIds.is_container_kind(entity.get("kind", "")) and not entity.has("opened"):
		entity["opened"] = false
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
