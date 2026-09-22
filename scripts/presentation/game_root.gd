extends Node3D

const HOLD_MS := 180
const RADIAL_RADIUS := 92.0
const RADIAL_SLOT_HIT := 34.0
const RADIAL_SLOT := 28.0
const RADIAL_HUB := 18.0
const RADIAL_LABEL_SIZE := 16
# Right-clicking an object stops on this side of it, not on the click point.
const OBJECT_WALK_GAP := 0.35
const OBJECT_WALK_ITEM := 0.4
const RUN_CLICK_MS := 520
const RUN_CLICK_RANGE := 1.6

# A stall must not fast-forward the world, so surplus accumulated time is dropped rather
# than replayed as a burst of ticks.
const MAX_TICKS_PER_FRAME := 6
# Views chase the 20 Hz authoritative pose so rendering stays smooth at any frame rate.
const VIEW_FOLLOW_RATE := 18.0
const VIEW_SNAP_DISTANCE := 3.0

var simulation: EtheraSimulation
var tick_accumulator_ms: float = 0.0
var assets: EtheraAssetLibrary
var handoff: EtheraItemHandoff
var views: Dictionary = {}
var orbit_yaw: float = 0.6
var orbit_pitch: float = 0.55
var orbit_distance: float = 6.5
var dragging_orbit := false
const ORBIT_NEAR := 1.15
const ORBIT_FAR := 22.0
const ORBIT_PITCH_MIN := -1.52
const ORBIT_PITCH_MAX := 1.52
const ORBIT_FLOOR := 0.12
const ORBIT_FOCUS_HEIGHT := 1.15
const ORBIT_COLLISION_SKIN := 0.12
const ORBIT_COLLISION_MIN := 0.45
var hex_stream: EtheraHexStreamer
var holding_left := false
var press_time_ms := 0
var press_target_id := ""
var press_screen := Vector2.ZERO
var panel_visible := false
var title_open := true
var log_open := true
var title_chrome: PanelContainer
var log_chrome: PanelContainer
var panel_chrome: PanelContainer
var title_content: Control
var title_toggle: Button
var log_toggle: Button
var _walk_click_ms := -99999
var _walk_click_at := Vector3.INF
var radial_open := false
var radial_actions: Array[Dictionary] = []
var radial_index := -1
var radial_target_name := ""
var hover_kind := EtheraIds.HOVER_NONE

@onready var world_root: Node3D = $World
@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $StartupOverlay
@onready var status_label: Label = $StartupOverlay/MarginContainer/VBoxContainer/Status
@onready var title_label: Label = $StartupOverlay/MarginContainer/VBoxContainer/Title
@onready var temporary_ground: Node3D = $World/TemporaryGround

var panel_tab := "traits"
var panel_refreshing := false
var panel_identity: Label
var panel_body: Label
var panel_gear: Label
var panel_tab_row: HBoxContainer
var panel_page: Label
var panel_shards: ItemList
var panel_shard_detail: Label
var log_label: Label
var overlay: Control
var toast_label: Label
var toast_until_ms := 0
var toast_seen_ms := -1

func _ready() -> void:
	simulation = EtheraSimulation.new()
	assets = EtheraAssetLibrary.new()
	handoff = EtheraItemHandoff.new()
	assets.load_from_res()
	_build_hud()
	_configure_sun()
	assets.try_mount_environment(world_root, temporary_ground)
	_make_hex_ground()
	_rebuild_views()
	_refresh_hud()


func _process(delta: float) -> void:
	_advance_simulation(delta)
	_apply_mouse_mode()
	_update_hold_radial()
	_sync_hex_stream()
	_sync_views(delta)
	_update_camera()
	_update_hover()
	_update_discovery_toast(delta)
	_refresh_hud()


# Frame time is converted into whole authoritative ticks here. The simulation clock never
# sees a frame delta, so world time advances identically on every machine.
func _advance_simulation(delta: float) -> void:
	tick_accumulator_ms += delta * 1000.0
	var ticks: int = EtheraWorld.ticks_available(tick_accumulator_ms)
	if ticks <= 0:
		return
	tick_accumulator_ms -= float(ticks * EtheraWorld.MS_PER_TICK)
	simulation.apply({"type": EtheraIds.CMD_TICK, "ticks": mini(ticks, MAX_TICKS_PER_FRAME)})


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_panel"):
		panel_visible = not panel_visible
		get_viewport().set_input_as_handled()
		return
	if _skill_overlay_active():
		_set_orbit_dragging(false)
		_handle_skill_input(event)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		orbit_distance = clampf(orbit_distance - 0.7, ORBIT_NEAR, ORBIT_FAR)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		orbit_distance = clampf(orbit_distance + 0.7, ORBIT_NEAR, ORBIT_FAR)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var command: Dictionary = walk_command_from_right_click(_intersect(true), event.double_click)
		if not command.is_empty():
			simulation.apply(command)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_left_mouse(event)
	elif event is InputEventMouseMotion and dragging_orbit:
		orbit_yaw -= event.relative.x * 0.007
		orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.007, ORBIT_PITCH_MIN, ORBIT_PITCH_MAX)


func _handle_left_mouse(event: InputEventMouseButton) -> void:
	if event.pressed:
		holding_left = true
		press_time_ms = Time.get_ticks_msec()
		press_screen = event.position
		var hit: Dictionary = left_pick_from_hits(_intersect_hits())
		press_target_id = str(hit.get("entity_id", ""))
		_set_orbit_dragging(_is_orbit_press_target(press_target_id) and not _skill_overlay_active())
		return
	holding_left = false
	_set_orbit_dragging(false)
	if radial_open:
		if radial_index >= 0 and radial_index < radial_actions.size():
			var action: Dictionary = radial_actions[radial_index]
			simulation.apply({
				"type": EtheraIds.CMD_BEGIN_INTERACTION,
				"target_id": press_target_id,
				"interaction_id": str(action.get("id", "")),
			})
		_close_radial()
		get_viewport().set_input_as_handled()
		return
	var held: int = Time.get_ticks_msec() - press_time_ms
	var hit: Dictionary = left_pick_from_hits(_intersect_hits())
	var target_id: String = str(hit.get("entity_id", ""))
	if held < HOLD_MS and target_id != "":
		var hover: Dictionary = simulation.query_hover(simulation.query_inhabited_id(), target_id)
		if str(hover.get("kind", "")) == EtheraIds.HOVER_PICKUP or str(hover.get("kind", "")) == EtheraIds.HOVER_SWAP:
			simulation.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": target_id})
			get_viewport().set_input_as_handled()
		elif str(hover.get("kind", "")) == EtheraIds.HOVER_OPEN:
			simulation.apply({"type": EtheraIds.CMD_OPEN_CONTAINER, "target_id": target_id})
			get_viewport().set_input_as_handled()


func _update_hold_radial() -> void:
	if radial_open:
		radial_index = EtheraRadialSelection.highlighted_index(
			press_screen,
			get_viewport().get_mouse_position(),
			radial_actions.size(),
			RADIAL_RADIUS,
			RADIAL_SLOT_HIT
		)
		return
	if not holding_left or dragging_orbit or press_target_id == "":
		return
	if Time.get_ticks_msec() - press_time_ms < HOLD_MS:
		return
	var actions: Array[Dictionary] = simulation.query_available_interactions(simulation.query_inhabited_id(), press_target_id)
	if actions.is_empty():
		return
	radial_open = true
	radial_actions = actions
	radial_index = -1
	radial_target_name = _entity_display_name(press_target_id)
	_set_focus_hold(true)


func _close_radial() -> void:
	radial_open = false
	radial_actions = []
	radial_index = -1
	radial_target_name = ""
	_set_focus_hold(false)


func _set_focus_hold(held: bool) -> void:
	simulation.apply({"type": EtheraIds.CMD_SET_FOCUS_HOLD, "held": held})


func _handle_skill_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		holding_left = false
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed):
		var pointer: Vector2 = _skill_pointer_from_screen()
		simulation.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": pointer.x, "y": pointer.y})
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		simulation.apply({"type": EtheraIds.CMD_SKILL_CLICK})
		get_viewport().set_input_as_handled()


func _rebuild_views() -> void:
	for child in views.values():
		if child is Node:
			(child as Node).queue_free()
	views.clear()
	var snapshot: Dictionary = simulation.query_world_view()
	for entity in snapshot.get("entities", []):
		_ensure_view(entity)


func _sync_views(delta: float) -> void:
	var seen: Dictionary = {}
	var snapshot: Dictionary = simulation.query_world_view()
	var by_id: Dictionary = {}
	for entity in snapshot.get("entities", []):
		by_id[str(entity.get("id", ""))] = entity
	var follow: float = 1.0 - exp(-VIEW_FOLLOW_RATE * delta)
	for entity in snapshot.get("entities", []):
		var entity_id: String = str(entity.get("id", ""))
		seen[entity_id] = true
		_ensure_view(entity)
		var node: Node3D = views.get(entity_id)
		if node == null:
			continue
		node.visible = bool(entity.get("manifested", false))
		var lid: Node = node.get_node_or_null("ContainerLid")
		if lid != null:
			lid.sync_lid(bool(entity.get("container_lid_open", false)), delta)
		_sync_discovery_aura(node, bool(entity.get("discovered_by_inhabited", false)))
		var sink: Node = node.get_node_or_null("GrassPatchSink")
		if sink != null:
			sink.sync_sink(bool(entity.get("container_opened", false)), delta)
		var holder_id: Variant = entity.get("holder_id", null)
		var carried: bool = not EtheraIds.is_empty_slot(holder_id) and views.has(str(holder_id))
		var pos: Dictionary = entity.get("position", {})
		var rest := Vector3(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)), float(pos.get("z", 0.0)))
		if not carried:
			rest.y = terrain_height(rest.x, rest.z)
		var yaw: float = float(entity.get("yaw", 0.0))
		var goal: Transform3D = EtheraItemHandoff.loose_transform(rest, yaw)
		if carried:
			var holder: Node3D = views[str(holder_id)]
			goal = assets.attach_world_transform(
				holder,
				by_id.get(str(holder_id), {}),
				str(entity.get("attachment", "back"))
			)
		handoff.observe(entity_id, carried, node.global_transform)
		if handoff.is_active(entity_id):
			node.global_transform = handoff.step(entity_id, delta, goal)
			assets.apply_carried_visual(node, carried or handoff.is_airborne(entity_id))
			continue
		if carried:
			node.global_transform = goal
			assets.apply_carried_visual(node, true)
			continue
		assets.apply_carried_visual(node, false)
		if node.global_position.distance_to(rest) > VIEW_SNAP_DISTANCE:
			node.global_transform = goal
		else:
			node.global_transform = node.global_transform.interpolate_with(goal, follow)
	for entity_id in views.keys():
		if not seen.has(entity_id):
			(views[entity_id] as Node).queue_free()
			views.erase(entity_id)
			handoff.forget(entity_id)


func _ensure_view(entity: Dictionary) -> void:
	var entity_id: String = str(entity.get("id", ""))
	if views.has(entity_id) or str(entity.get("kind", "")) == "place":
		return
	var body: StaticBody3D = assets.make_entity_body(entity)
	world_root.add_child(body)
	views[entity_id] = body


# Right-click always walks. An object click stops just before that object.
# Pickup, open, and radials stay on left-click.
func walk_command_from_right_click(hit: Dictionary, double_click: bool) -> Dictionary:
	if hit.is_empty() or not (hit.get("position") is Vector3):
		return {}
	if _is_orbit_press_target(str(hit.get("entity_id", ""))):
		return {}
	var point: Vector3 = hit.get("position")
	var entity_id: String = str(hit.get("entity_id", ""))
	if entity_id != "":
		point = _stand_off_from_entity(entity_id, point)
	var run: bool = double_click or register_run_click(point)
	return {
		"type": EtheraIds.CMD_SET_WALK_DESTINATION,
		"x": point.x,
		"y": 0.0,
		"z": point.z,
		"gait": "run" if run else "walk",
	}


func register_run_click(point: Vector3, now_ms: int = -1) -> bool:
	if now_ms < 0:
		now_ms = Time.get_ticks_msec()
	var is_run: bool = now_ms - _walk_click_ms <= RUN_CLICK_MS and point.distance_to(_walk_click_at) <= RUN_CLICK_RANGE
	_walk_click_ms = now_ms
	_walk_click_at = point
	return is_run


static func point_beside(anchor: Vector3, toward: Vector3, distance: float) -> Vector3:
	var offset: Vector3 = toward - anchor
	offset.y = 0.0
	if offset.length() < 0.001:
		offset = Vector3(1.0, 0.0, 0.0)
	var ground := Vector3(anchor.x, 0.0, anchor.z)
	return ground + offset.normalized() * distance


func _stand_off_from_entity(entity_id: String, fallback: Vector3) -> Vector3:
	var entity: Dictionary = _world_view_entity(entity_id)
	if entity.is_empty():
		return Vector3(fallback.x, 0.0, fallback.z)
	var occupancy: float = float(entity.get("occupancy_radius", 0.0))
	var distance: float = occupancy + OBJECT_WALK_GAP if occupancy > 0.0 else OBJECT_WALK_ITEM
	return point_beside(_entity_ground(entity), _actor_ground(), distance)


func _world_view_entity(entity_id: String) -> Dictionary:
	for entity in simulation.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == entity_id:
			return entity
	return {}


func _entity_ground(entity: Dictionary) -> Vector3:
	var position: Dictionary = entity.get("position", {})
	return Vector3(float(position.get("x", 0.0)), 0.0, float(position.get("z", 0.0)))


func _actor_ground() -> Vector3:
	var actor: Dictionary = _world_view_entity(simulation.query_inhabited_id())
	if actor.is_empty():
		return Vector3.ZERO
	return _entity_ground(actor)


func _skill_overlay_active() -> bool:
	return not simulation.query_skill().is_empty() and str(simulation.query_skill().get("stage", "")) == "skill"


func _set_orbit_dragging(active: bool) -> void:
	if _skill_overlay_active():
		active = false
	dragging_orbit = active
	_apply_mouse_mode()


func _apply_mouse_mode() -> void:
	var mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
	if _skill_overlay_active():
		mode = Input.MOUSE_MODE_CONFINED
	elif dragging_orbit:
		mode = Input.MOUSE_MODE_CAPTURED
	if Input.get_mouse_mode() == mode:
		return
	if mode == Input.MOUSE_MODE_CONFINED:
		get_viewport().warp_mouse(Vector2(640.0, 340.0))
	Input.set_mouse_mode(mode)


# Starting 256 m hex plus neighbors that exist in the layout. Simulation xz stays planar.
func terrain_height(x: float, z: float) -> float:
	if hex_stream != null:
		return hex_stream.height_at(x, z)
	return 0.0


func terrain_normal(x: float, z: float) -> Vector3:
	if hex_stream != null:
		return hex_stream.normal_at(x, z)
	return Vector3.UP


func _sync_hex_stream() -> void:
	if hex_stream == null:
		return
	var actor_view: Node3D = views.get(simulation.query_inhabited_id())
	var at: Vector3 = actor_view.global_position if actor_view else Vector3.ZERO
	hex_stream.sync_around(Vector2(at.x, at.z))


func _make_hex_ground() -> void:
	if temporary_ground == null or not temporary_ground.visible:
		return
	var hidden: MeshInstance3D = temporary_ground.get_node_or_null("MeshInstance3D")
	if hidden:
		hidden.mesh = null
		hidden.visible = false
	var old_collider: CollisionShape3D = temporary_ground.get_node_or_null("CollisionShape3D")
	if old_collider:
		old_collider.queue_free()
	for old_tile in temporary_ground.find_children("GroundTile_*", "", false, false):
		old_tile.queue_free()
	for old_mark in temporary_ground.find_children("GroundCorner_*", "", false, false):
		old_mark.queue_free()
	hex_stream = EtheraHexStreamer.new()
	hex_stream.name = "HexStream"
	temporary_ground.add_child(hex_stream)
	hex_stream.setup(temporary_ground as CollisionObject3D)


func _update_camera() -> void:
	# The camera follows the smoothed view rather than the 20 Hz authoritative pose.
	var actor_view: Node3D = views.get(simulation.query_inhabited_id())
	if actor_view == null:
		return
	var focus: Vector3 = actor_view.global_position + Vector3(0.0, ORBIT_FOCUS_HEIGHT, 0.0)
	var heading := Vector3(
		sin(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		cos(orbit_yaw) * cos(orbit_pitch)
	)
	var floor_used: float = orbit_used_distance(orbit_pitch, orbit_distance, focus.y)
	if floor_used + 0.001 < orbit_distance:
		orbit_distance = floor_used
	var used: float = orbit_ray_blocked_distance(focus, heading, floor_used, _orbit_blockers())
	var candidate: Vector3 = focus + heading * used
	var ground_y: float = terrain_height(candidate.x, candidate.z) + ORBIT_FLOOR
	if candidate.y < ground_y:
		used = orbit_used_distance(orbit_pitch, used, focus.y, ground_y)
		used = orbit_ray_blocked_distance(focus, heading, used, _orbit_blockers())
		candidate = focus + heading * used
	camera.near = 0.05
	camera.global_position = candidate
	camera.look_at(focus)


# A low tilt that would bury the camera pulls it in along the look so the orbit
# can keep going. It stays on this side of the ground so the hex does not vanish.
static func orbit_used_distance(pitch: float, requested: float, focus_y: float, floor_y: float = ORBIT_FLOOR) -> float:
	var distance: float = clampf(requested, ORBIT_NEAR, ORBIT_FAR)
	var rise: float = sin(pitch) * distance
	if focus_y + rise >= floor_y:
		return distance
	if sin(pitch) >= -0.0001:
		return distance
	var skim: float = (focus_y - floor_y) / -sin(pitch)
	if skim < 0.05:
		return 0.05
	return minf(distance, skim)


# Equipped gear is part of the inhabited body for orbit, not a separate click target.
func _is_orbit_press_target(entity_id: String) -> bool:
	var inhabited_id: String = simulation.query_inhabited_id()
	if entity_id == "" or inhabited_id == "":
		return false
	if entity_id == inhabited_id:
		return true
	for entity in simulation.query_world_view().get("entities", []):
		if str(entity.get("id", "")) != entity_id:
			continue
		return str(entity.get("holder_id", "")) == inhabited_id
	return false


func _orbit_blockers() -> Array:
	var inhabited_id: String = simulation.query_inhabited_id()
	var volumes: Array = []
	for entity in simulation.query_world_view().get("entities", []):
		var entity_id: String = str(entity.get("id", ""))
		if entity_id == inhabited_id:
			continue
		if str(entity.get("holder_id", "")) == inhabited_id:
			continue
		if str(entity.get("kind", "")) == "grass":
			continue
		if str(entity.get("presentation", {}).get("asset_id", "")) == "asset.grass":
			continue
		if float(entity.get("occupancy_radius", 0.0)) <= 0.0:
			continue
		var node: Node3D = views.get(entity_id) as Node3D
		var mesh_volumes: Array = _orbit_volumes_from_view(node)
		if mesh_volumes.is_empty():
			var position: Dictionary = entity.get("position", {})
			volumes.append({
				"x": float(position.get("x", 0.0)),
				"z": float(position.get("z", 0.0)),
				"radius": float(entity.get("occupancy_radius", 0.0)),
				"y_min": 0.0,
				"y_max": 1.2,
			})
		else:
			volumes.append_array(mesh_volumes)
	return volumes


func _orbit_volumes_from_view(root: Node) -> Array:
	var volumes: Array = []
	if root == null:
		return volumes
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.insert(0, root)
	for node in meshes:
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		if box.size.x < 0.04 and box.size.z < 0.04:
			continue
		volumes.append({
			"x": box.get_center().x,
			"z": box.get_center().z,
			"radius": maxf(maxf(box.size.x, box.size.z) * 0.5, 0.08),
			"y_min": box.position.y,
			"y_max": box.position.y + box.size.y,
		})
	return volumes


# Occupancy is a disk for walking. The camera stops on each visible solid, not a
# column of air above a small basin or through the empty middle of a ring.
static func orbit_ray_blocked_distance(origin: Vector3, direction: Vector3, max_distance: float, cylinders: Array, skin: float = ORBIT_COLLISION_SKIN) -> float:
	if direction.length() < 0.0001 or max_distance <= 0.0:
		return max_distance
	var dir: Vector3 = direction.normalized()
	var best: float = max_distance
	for raw in cylinders:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var hit: float = _vertical_cylinder_hit(origin, dir, max_distance, raw)
		if hit < INF:
			best = minf(best, hit - skin)
	return maxf(ORBIT_COLLISION_MIN, best)


static func _vertical_cylinder_hit(origin: Vector3, dir: Vector3, max_distance: float, cylinder: Dictionary) -> float:
	var cx: float = float(cylinder.get("x", 0.0))
	var cz: float = float(cylinder.get("z", 0.0))
	var radius: float = float(cylinder.get("radius", 0.0))
	if radius <= 0.0:
		return INF
	var ox: float = origin.x - cx
	var oz: float = origin.z - cz
	var a: float = dir.x * dir.x + dir.z * dir.z
	var c: float = ox * ox + oz * oz - radius * radius
	if a < 0.0000001:
		return 0.0 if c < 0.0 else INF
	if c < 0.0:
		return 0.0 if ox * dir.x + oz * dir.z < 0.0 else INF
	var b: float = 2.0 * (ox * dir.x + oz * dir.z)
	var disc: float = b * b - 4.0 * a * c
	if disc < 0.0:
		return INF
	var t: float = (-b - sqrt(disc)) / (2.0 * a)
	if t <= 0.0001 or t > max_distance:
		return INF
	var y: float = origin.y + dir.y * t
	if y < float(cylinder.get("y_min", -2.0)) or y > float(cylinder.get("y_max", 4.0)):
		return INF
	return t


func _update_hover() -> void:
	hover_kind = EtheraIds.HOVER_NONE
	if radial_open or dragging_orbit:
		return
	if _skill_overlay_active():
		return
	var hit: Dictionary = left_pick_from_hits(_intersect_hits())
	var target_id: String = str(hit.get("entity_id", ""))
	if target_id == "":
		target_id = _discover_target_under_mouse()
	if target_id == "":
		return
	hover_kind = str(simulation.query_hover(simulation.query_inhabited_id(), target_id).get("kind", EtheraIds.HOVER_NONE))
	_maybe_observe_place(target_id)


func _discover_target_under_mouse() -> String:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var best_id := ""
	var best_distance := 42.0
	for entity in simulation.query_world_view().get("entities", []):
		if float(entity.get("discovery_radius", 0.0)) <= 0.0:
			continue
		if bool(entity.get("discovered_by_inhabited", false)):
			continue
		var position: Dictionary = entity.get("position", {})
		var world_at := Vector3(float(position.get("x", 0.0)), 1.46, float(position.get("z", 0.0)))
		if camera.is_position_behind(world_at):
			continue
		var distance: float = camera.unproject_position(world_at).distance_to(mouse)
		if distance < best_distance:
			best_distance = distance
			best_id = str(entity.get("id", ""))
	return best_id


func walk_pick_from_hits(hits: Array) -> Dictionary:
	for raw in hits:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if _is_orbit_press_target(str(raw.get("entity_id", ""))):
			continue
		return raw
	return {}


# The orbit mask is larger than her silhouette so camera drag does not need to
# be exact. A loose item, swap, or open under that same ray still wins: hover
# and left-click reach the object instead of starting orbit.
func left_pick_from_hits(hits: Array) -> Dictionary:
	var first: Dictionary = {}
	var seen_self := false
	for raw in hits:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entity_id: String = str(raw.get("entity_id", ""))
		if first.is_empty():
			first = raw
		if _is_orbit_press_target(entity_id):
			seen_self = true
			continue
		if not seen_self:
			return raw
		if _is_orbit_item_exception(entity_id):
			return raw
		return first
	return first


func _is_orbit_item_exception(entity_id: String) -> bool:
	if entity_id == "":
		return false
	var kind: String = str(simulation.query_hover(simulation.query_inhabited_id(), entity_id).get("kind", EtheraIds.HOVER_NONE))
	return kind == EtheraIds.HOVER_PICKUP or kind == EtheraIds.HOVER_SWAP or kind == EtheraIds.HOVER_OPEN


func _entity_id_from_collider(collider: Object) -> String:
	var node: Node = collider as Node
	while node != null:
		if node.has_meta("entity_id"):
			return str(node.get_meta("entity_id"))
		node = node.get_parent()
	return ""


func _intersect(through_self: bool = false) -> Dictionary:
	var hits: Array = _intersect_hits()
	if through_self:
		return walk_pick_from_hits(hits)
	if hits.is_empty():
		return {}
	return hits[0]


func _intersect_hits() -> Array:
	var hits: Array = []
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var direction: Vector3 = camera.project_ray_normal(mouse)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for _i in range(16):
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 200.0)
		query.exclude = exclude
		query.hit_from_inside = true
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: Object = hit.get("collider")
		var entity_id: String = _entity_id_from_collider(collider)
		if entity_id != "":
			hits.append({"kind": "entity", "entity_id": entity_id, "position": hit.get("position")})
		else:
			hits.append({"kind": "ground", "position": hit.get("position")})
			break
		if collider is CollisionObject3D:
			exclude.append((collider as CollisionObject3D).get_rid())
			continue
		break
	return hits


func _build_hud() -> void:
	var old_margin: Control = title_label.get_parent().get_parent() as Control
	old_margin.visible = false
	old_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "Ethera: The Stonewrought"
	title_chrome = _make_chrome_panel()
	title_chrome.set_anchors_preset(Control.PRESET_TOP_LEFT)
	title_chrome.position = Vector2(16, 16)
	title_toggle = _make_chrome_button()
	title_toggle.pressed.connect(func() -> void:
		title_open = not title_open
		_refresh_hud()
	)
	title_content = VBoxContainer.new()
	title_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_row := HBoxContainer.new()
	title_row.add_child(title_toggle)
	title_row.add_child(title_content)
	title_label.get_parent().remove_child(title_label)
	status_label.get_parent().remove_child(status_label)
	title_content.add_child(title_label)
	title_content.add_child(status_label)
	title_chrome.add_child(title_row)
	hud.add_child(title_chrome)
	log_chrome = _make_chrome_panel()
	log_chrome.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	log_chrome.anchor_left = 1.0
	log_chrome.anchor_right = 1.0
	log_chrome.offset_left = -430
	log_chrome.offset_right = -16
	log_chrome.offset_top = 16
	log_chrome.offset_bottom = 16
	log_toggle = _make_chrome_button()
	log_toggle.pressed.connect(func() -> void:
		log_open = not log_open
		_refresh_hud()
	)
	var log_column := VBoxContainer.new()
	var log_header := HBoxContainer.new()
	log_header.alignment = BoxContainer.ALIGNMENT_END
	log_header.add_child(log_toggle)
	log_label = Label.new()
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_color_override("font_color", Color(0.93, 0.90, 0.82))
	log_label.custom_minimum_size = Vector2(380, 0)
	log_column.add_child(log_header)
	log_column.add_child(log_label)
	log_chrome.add_child(log_column)
	hud.add_child(log_chrome)
	panel_chrome = _make_chrome_panel()
	panel_chrome.anchor_left = 0.5
	panel_chrome.anchor_top = 0.5
	panel_chrome.anchor_right = 0.5
	panel_chrome.anchor_bottom = 0.5
	panel_chrome.offset_left = -460
	panel_chrome.offset_top = -310
	panel_chrome.offset_right = 460
	panel_chrome.offset_bottom = 310
	_build_character_panel(panel_chrome)
	hud.add_child(panel_chrome)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(overlay)
	overlay.draw.connect(_draw_overlay)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	toast_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62))
	toast_label.add_theme_font_size_override("font_size", 28)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.offset_left = -280
	toast_label.offset_right = 280
	toast_label.offset_top = 36
	toast_label.offset_bottom = 110
	toast_label.visible = false
	hud.add_child(toast_label)


func _configure_sun() -> void:
	var sun: DirectionalLight3D = get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.shadow_enabled = true
		sun.light_energy = 1.05
		sun.shadow_bias = 0.03
		sun.shadow_normal_bias = 1.0
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 48.0
		sun.directional_shadow_split_1 = 0.12
		sun.directional_shadow_split_2 = 0.32
		sun.directional_shadow_split_3 = 0.6
		sun.directional_shadow_blend_splits = true
		sun.directional_shadow_pancake_size = 8.0
	var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env != null and world_env.environment != null:
		var env: Environment = world_env.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.46, 0.62, 0.78)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.82, 0.74, 0.62)
		env.ambient_light_energy = 0.42
		env.fog_enabled = false


func _sync_discovery_aura(node: Node, discovered: bool) -> void:
	for aura_name in ["DiscoveryAura"]:
		var aura: Node = node.find_child(aura_name, true, false)
		if aura is Node3D:
			(aura as Node3D).visible = not discovered


func _maybe_observe_place(target_id: String) -> void:
	var actor_id: String = simulation.query_inhabited_id()
	if target_id == "" or target_id == actor_id:
		return
	var landmark: Dictionary = {}
	var actor: Dictionary = {}
	for entity in simulation.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == target_id:
			landmark = entity
		if str(entity.get("id", "")) == actor_id:
			actor = entity
	if landmark.is_empty() or float(landmark.get("discovery_radius", 0.0)) <= 0.0:
		return
	if bool(landmark.get("discovered_by_inhabited", false)):
		return
	var from: Dictionary = actor.get("position", {})
	var to: Dictionary = landmark.get("position", {})
	var dx: float = float(to.get("x", 0.0)) - float(from.get("x", 0.0))
	var dz: float = float(to.get("z", 0.0)) - float(from.get("z", 0.0))
	if Vector2(dx, dz).length() > float(landmark.get("discovery_radius", 0.0)):
		return
	simulation.apply({"type": EtheraIds.CMD_OBSERVE_TARGET, "target_id": target_id})


func _update_discovery_toast(_delta: float) -> void:
	if toast_label == null:
		return
	for entry in simulation.query_dev_log(8):
		if str(entry.get("kind", "")) != "place_discovered":
			continue
		var when: int = int(entry.get("world_time", 0))
		if when <= toast_seen_ms:
			continue
		toast_seen_ms = when
		toast_label.text = "Discovered\n%s" % str(entry.get("place_name", entry.get("text", "")))
		toast_until_ms = Time.get_ticks_msec() + 3200
	toast_label.visible = Time.get_ticks_msec() < toast_until_ms


func _make_chrome_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.82)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


func _make_chrome_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(28, 28)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Hide or show"
	return button


func _refresh_hud() -> void:
	var using_models: bool = assets.has_model("asset.khar_morr") or assets.has_model("asset.memory_fountain") or assets.has_model("asset.village_center") or assets.has_model("asset.stone_club")
	status_label.text = "Local simulation running\n%s\nC toggles the character panel" % ("Models loaded from assets/models" if using_models else "Placeholder meshes; drop GLBs into assets/models")
	title_chrome.visible = not panel_visible
	log_chrome.visible = not panel_visible
	title_content.visible = title_open
	log_label.visible = log_open
	log_label.custom_minimum_size = Vector2(380, 200) if log_open else Vector2(0, 0)
	log_chrome.offset_bottom = 16 + (248 if log_open else 44)
	title_toggle.text = "▾" if title_open else "▸"
	log_toggle.text = "▾" if log_open else "▸"
	panel_chrome.visible = panel_visible
	if panel_visible:
		_refresh_character_panel(simulation.query_panel())
	var lines: PackedStringArray = PackedStringArray()
	for entry in simulation.query_dev_log(12):
		lines.append(str(entry.get("text", "")))
	log_label.text = "\n".join(lines)
	overlay.queue_redraw()


func _build_character_panel(host: PanelContainer) -> void:
	var ink := Color(0.93, 0.90, 0.82)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	host.add_child(root)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_identity = _panel_label(ink, 22)
	panel_body = _panel_label(ink)
	panel_gear = _panel_label(ink)
	left.add_child(panel_identity)
	left.add_child(panel_body)
	left.add_child(panel_gear)
	root.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	panel_tab_row = HBoxContainer.new()
	for tab_id in ["traits", "needs", "shards", "states", "interactions"]:
		var button := Button.new()
		button.text = tab_id.capitalize()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_panel_tab.bind(tab_id))
		panel_tab_row.add_child(button)
	right.add_child(panel_tab_row)
	panel_page = _panel_label(ink)
	panel_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(panel_page)
	panel_shards = ItemList.new()
	panel_shards.custom_minimum_size = Vector2(0, 220)
	panel_shards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_shards.item_selected.connect(func(_index: int) -> void:
		_refresh_character_panel(simulation.query_panel())
	)
	right.add_child(panel_shards)
	panel_shard_detail = _panel_label(ink)
	panel_shard_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(panel_shard_detail)
	root.add_child(right)


func _panel_label(ink: Color, size: int = 16) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", ink)
	label.add_theme_font_size_override("font_size", size)
	return label


func _select_panel_tab(tab_id: String) -> void:
	panel_tab = tab_id
	_refresh_character_panel(simulation.query_panel())


func _refresh_character_panel(panel: Dictionary) -> void:
	if panel_refreshing:
		return
	panel_refreshing = true
	panel_identity.text = "%s\n%s, %s" % [
		str(panel.get("name", "")),
		str(panel.get("people", "")),
		str(panel.get("sex", "")),
	]
	var body_lines: PackedStringArray = PackedStringArray(["Body"])
	var regions: Dictionary = panel.get("body_regions", {})
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		body_lines.append("%s  %s" % [str(region.get("name", region_id)), str(region.get("condition", ""))])
	panel_body.text = "\n".join(body_lines)
	var gear_lines: PackedStringArray = PackedStringArray(["Equipment"])
	var equipment: Dictionary = panel.get("equipment", {})
	for slot_id in equipment.keys():
		var slot: Dictionary = equipment[slot_id]
		var slot_name: String = _pretty_id(str(slot_id))
		if bool(slot.get("empty", true)):
			gear_lines.append("%s  empty" % slot_name)
		else:
			var extra: String = str(slot.get("base_color", ""))
			gear_lines.append("%s  %s%s" % [
				slot_name,
				str(slot.get("name", slot.get("id", ""))),
				("  [%s]" % extra) if extra != "" else "",
			])
	panel_gear.text = "\n".join(gear_lines)
	for button in panel_tab_row.get_children():
		(button as Button).set_pressed_no_signal(button.text.to_lower() == panel_tab)
	var shards: Array = panel.get("known_shards", [])
	var states: Array = panel.get("states", [])
	var show_shards: bool = panel_tab == "shards"
	var show_states: bool = panel_tab == "states"
	panel_shards.visible = show_shards or show_states
	panel_shard_detail.visible = show_shards or show_states
	panel_page.visible = not show_shards and not show_states
	if show_shards:
		_fill_panel_list(shards, "No known Shards.", _shard_title, _shard_detail)
		panel_refreshing = false
		return
	if show_states:
		_fill_panel_list(states, "No current States.", _state_title, _state_detail)
		panel_refreshing = false
		return
	match panel_tab:
		"traits":
			panel_page.text = _named_list("Traits", panel.get("traits", []))
		"needs":
			panel_page.text = _id_list("Needs", panel.get("needs", []))
		_:
			panel_page.text = _named_list("Interactions", panel.get("known_interactions", []))
	panel_refreshing = false


func _fill_panel_list(entries: Array, empty_text: String, title_fn: Callable, detail_fn: Callable) -> void:
	var selected: int = panel_shards.get_selected_items()[0] if panel_shards.is_anything_selected() else 0
	panel_shards.clear()
	if entries.is_empty():
		panel_shards.add_item("none")
		panel_shards.select(0)
		panel_shard_detail.text = empty_text
		return
	for entry in entries:
		panel_shards.add_item(str(title_fn.call(entry)))
	selected = clampi(selected, 0, entries.size() - 1)
	panel_shards.select(selected)
	panel_shard_detail.text = str(detail_fn.call(entries[selected]))


func _shard_title(shard: Variant) -> String:
	var data: Dictionary = shard if typeof(shard) == TYPE_DICTIONARY else {}
	return "%s  %s" % [_pretty_id(str(data.get("action_id", "shard"))), str(data.get("id", ""))]


func _shard_detail(shard: Variant) -> String:
	var data: Dictionary = shard if typeof(shard) == TYPE_DICTIONARY else {}
	var targets: PackedStringArray = PackedStringArray()
	for name in data.get("target_names", data.get("target_ids", [])):
		targets.append(str(name))
	var seconds: float = float(data.get("world_time", 0)) / 1000.0
	return "\n".join(PackedStringArray([
		"Action  %s" % _pretty_id(str(data.get("action_id", ""))),
		"Result  %s" % ", ".join(_pretty_ids(data.get("result_ids", []))),
		"Targets  %s" % (", ".join(targets) if targets.size() > 0 else "none"),
		"Place  %s" % str(data.get("place_name", _pretty_id(str(data.get("place_id", ""))))),
		"Time  %.1fs" % seconds,
		"Id  %s" % str(data.get("id", "")),
	]))


func _state_title(state: Variant) -> String:
	var data: Dictionary = state if typeof(state) == TYPE_DICTIONARY else {}
	return str(data.get("name", data.get("id", "state")))


func _state_detail(state: Variant) -> String:
	var data: Dictionary = state if typeof(state) == TYPE_DICTIONARY else {}
	var remaining: float = float(data.get("remaining_ms", 0)) / 1000.0
	var duration: float = float(data.get("duration_ms", 0)) / 1000.0
	var speed: float = float(data.get("walk_speed_scale", 1.0))
	var lines: PackedStringArray = PackedStringArray([
		str(data.get("name", data.get("id", ""))),
		str(data.get("description", "")),
		"Remaining  %.1fs" % remaining,
		"Duration  %.1fs" % duration,
	])
	if not is_equal_approx(speed, 1.0):
		lines.append("Walk speed  %.1f×" % speed)
	lines.append("Id  %s" % str(data.get("id", "")))
	return "\n".join(lines)


func _named_list(title: String, entries: Variant) -> String:
	var names: PackedStringArray = PackedStringArray([title])
	if typeof(entries) == TYPE_ARRAY and (entries as Array).size() > 0:
		for entry in entries:
			if typeof(entry) == TYPE_DICTIONARY:
				names.append(str(entry.get("name", entry.get("id", ""))))
			else:
				names.append(_pretty_id(str(entry)))
	else:
		names.append("none")
	return "\n".join(names)


func _id_list(title: String, entries: Variant) -> String:
	var names: PackedStringArray = PackedStringArray([title])
	if typeof(entries) == TYPE_ARRAY and (entries as Array).size() > 0:
		for entry in entries:
			names.append(_pretty_id(str(entry)))
	else:
		names.append("none")
	return "\n".join(names)


func _pretty_ids(ids: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if typeof(ids) != TYPE_ARRAY:
		return result
	for id in ids:
		result.append(_pretty_id(str(id)))
	return result


func _pretty_id(id: String) -> String:
	var parts: PackedStringArray = id.split(".")
	var tail: String = parts[parts.size() - 1] if parts.size() > 0 else id
	return tail.capitalize().replace("_", " ")


func _skill_pointer_from_screen() -> Vector2:
	var rect := Rect2(Vector2(440, 140), Vector2(400, 400))
	var mouse: Vector2 = get_viewport().get_mouse_position()
	return Vector2(
		clampf((mouse.x - rect.position.x) / rect.size.x, 0.0, 1.0),
		clampf((mouse.y - rect.position.y) / rect.size.y, 0.0, 1.0)
	)


func _draw_overlay() -> void:
	if not panel_visible:
		_draw_hover_cursor()
		_draw_radial()
	_draw_skill()


func _draw_hover_cursor() -> void:
	if dragging_orbit or hover_kind == EtheraIds.HOVER_NONE:
		return
	var mouse: Vector2 = get_viewport().get_mouse_position() + Vector2(18, 8)
	var gold := Color(0.86, 0.72, 0.32)
	if hover_kind == EtheraIds.HOVER_PICKUP:
		overlay.draw_rect(Rect2(mouse, Vector2(16, 18)), gold, false, 2.0)
		overlay.draw_line(mouse + Vector2(0, 6), mouse + Vector2(16, 6), gold, 2.0)
	elif hover_kind == EtheraIds.HOVER_SWAP:
		overlay.draw_line(mouse, mouse + Vector2(22, 0), gold, 2.0)
		overlay.draw_line(mouse + Vector2(16, -5), mouse + Vector2(22, 0), gold, 2.0)
		overlay.draw_line(mouse + Vector2(6, 5), mouse, gold, 2.0)
		overlay.draw_line(mouse + Vector2(0, 12), mouse + Vector2(22, 12), gold, 2.0)
		overlay.draw_line(mouse + Vector2(6, 7), mouse + Vector2(0, 12), gold, 2.0)
		overlay.draw_line(mouse + Vector2(16, 17), mouse + Vector2(22, 12), gold, 2.0)
	elif hover_kind == EtheraIds.HOVER_OPEN:
		overlay.draw_rect(Rect2(mouse, Vector2(18, 14)), gold, false, 2.0)
		overlay.draw_line(mouse + Vector2(-2, 3), mouse + Vector2(20, 3), gold, 2.0)
	elif hover_kind == EtheraIds.HOVER_DISCOVER:
		var eye: Vector2 = mouse + Vector2(22, 12)
		var outline := PackedVector2Array()
		for i in range(24):
			var t: float = TAU * float(i) / 24.0
			outline.append(eye + Vector2(cos(t) * 16.0, sin(t) * 9.0))
		outline.append(outline[0])
		overlay.draw_colored_polygon(outline, Color(0.96, 0.94, 0.86, 0.95))
		overlay.draw_polyline(outline, gold, 3.0)
		overlay.draw_circle(eye, 5.5, Color(0.12, 0.10, 0.08))
		overlay.draw_circle(eye + Vector2(-1.5, -1.0), 2.0, gold)
	elif hover_kind == EtheraIds.HOVER_INTERACT:
		overlay.draw_arc(mouse + Vector2(10, 10), 10.0, 0.0, TAU, 16, gold, 2.0)


func _entity_display_name(entity_id: String) -> String:
	if entity_id == "":
		return ""
	for entity in simulation.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == entity_id:
			return str(entity.get("name", ""))
	return ""


func _draw_radial() -> void:
	if not radial_open:
		return
	var count: int = radial_actions.size()
	var font: Font = ThemeDB.fallback_font
	overlay.draw_circle(press_screen, RADIAL_HUB, Color(0.08, 0.08, 0.1, 0.7))
	if radial_target_name != "":
		var title: Rect2 = EtheraRadialSelection.hub_title_frame(
			press_screen,
			radial_target_name,
			font,
			RADIAL_LABEL_SIZE,
			RADIAL_HUB
		)
		overlay.draw_rect(title, Color(0.08, 0.08, 0.1, 0.92))
		overlay.draw_rect(title, Color(0.86, 0.72, 0.32), false, 2.0)
		overlay.draw_string(
			font,
			Vector2(title.position.x + 10.0, title.position.y + font.get_ascent(RADIAL_LABEL_SIZE) + 6.0),
			radial_target_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			title.size.x - 20.0,
			RADIAL_LABEL_SIZE,
			Color(0.95, 0.84, 0.4)
		)
	for i in range(count):
		var slot: Vector2 = EtheraRadialSelection.slot_center(press_screen, i, count, RADIAL_RADIUS)
		var selected: bool = i == radial_index
		var color := Color(0.95, 0.84, 0.4) if selected else Color(0.72, 0.62, 0.28)
		overlay.draw_circle(slot, RADIAL_SLOT, Color(0.08, 0.08, 0.1, 0.82))
		overlay.draw_arc(slot, RADIAL_SLOT, 0.0, TAU, 20, color, 2.0)
		if not selected:
			continue
		var label: String = str(radial_actions[i].get("name", radial_actions[i].get("id", "")))
		var frame: Rect2 = EtheraRadialSelection.label_frame(
			slot,
			label,
			font,
			RADIAL_LABEL_SIZE,
			RADIAL_SLOT,
			press_screen
		)
		overlay.draw_rect(frame, Color(0.08, 0.08, 0.1, 0.92))
		overlay.draw_rect(frame, color, false, 2.0)
		overlay.draw_string(
			font,
			Vector2(frame.position.x + 10.0, frame.position.y + font.get_ascent(RADIAL_LABEL_SIZE) + 6.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			frame.size.x - 20.0,
			RADIAL_LABEL_SIZE,
			color
		)


func _draw_skill() -> void:
	var skill: Dictionary = simulation.query_skill()
	if skill.is_empty() or str(skill.get("stage", "")) != "skill":
		return
	var rect := Rect2(Vector2(440, 140), Vector2(400, 400))
	overlay.draw_rect(rect, Color(0.08, 0.08, 0.1, 0.72))
	var remaining: float = float(skill.get("remaining_ms", 0))
	var duration: float = max(float(skill.get("duration_ms", 1)), 1.0)
	overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(remaining / duration, 0.0, 1.0), 8.0)), Color(0.86, 0.72, 0.32))
	var phase: Dictionary = skill.get("phase", {})
	if str(phase.get("challenge", "")) == EtheraIds.CHALLENGE_TRACE:
		var hit: Dictionary = skill.get("checkpoints_hit", {})
		for checkpoint in phase.get("checkpoints", []):
			var center := rect.position + Vector2(float(checkpoint.get("x", 0.0)), float(checkpoint.get("y", 0.0))) * rect.size
			var filled: bool = bool(hit.get(str(checkpoint.get("id", "")), false))
			overlay.draw_circle(center, 14.0, Color(0.95, 0.82, 0.35) if filled else Color(0.62, 0.48, 0.18))
	elif str(phase.get("challenge", "")) == EtheraIds.CHALLENGE_ALIGN:
		var recess: Dictionary = phase.get("recess", {})
		var center := rect.position + Vector2(float(recess.get("x", 0.5)), float(recess.get("y", 0.5))) * rect.size
		var recess_r: float = float(recess.get("radius", 0.08)) * minf(rect.size.x, rect.size.y)
		overlay.draw_circle(center, recess_r + 6.0, Color(0.12, 0.10, 0.08, 0.9))
		overlay.draw_circle(center, recess_r, Color(0.03, 0.03, 0.04, 1.0))
		overlay.draw_arc(center, recess_r, 0.0, TAU, 28, Color(0.86, 0.72, 0.32), 2.0)
		var target := Vector2(recess_r + 18.0, 0.0)
		overlay.draw_line(center - target, center + target, Color(0.86, 0.72, 0.32, 0.35), 2.0)
		var angle: float = deg_to_rad(float(skill.get("rotation_degrees", 0.0)))
		var pointer: Vector2 = Vector2(cos(angle), sin(angle)) * (recess_r + 18.0)
		overlay.draw_line(center - pointer, center + pointer, Color(0.95, 0.84, 0.4), 4.0)
		var cursor: Vector2 = rect.position + Vector2(float(skill.get("pointer", {}).get("x", 0.5)), float(skill.get("pointer", {}).get("y", 0.5))) * rect.size
		overlay.draw_arc(cursor, 7.0, 0.0, TAU, 16, Color(0.95, 0.84, 0.4), 2.0)
