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
const ORBIT_NEAR := 8.0
const ORBIT_FAR := 18.0
const ORBIT_PITCH_FAR := 0.96
const ORBIT_PITCH_NEAR := 0.68
const ORBIT_FOV := 48.0
const ORBIT_LOOK_AHEAD_FAR := 2.4
const ORBIT_LOOK_AHEAD_NEAR := 0.0
const ORBIT_FLOOR := 0.12
const ORBIT_FOCUS_HEIGHT := 1.15
const ORBIT_CAMERA_RADIUS := 0.22
const ORBIT_COLLISION_MIN := 0.45
var orbit_yaw: float = 0.6
# Pitch comes only from zoom. Far is raised; scrolling close lowers it so she sits in the middle.
var orbit_distance: float = ORBIT_FAR
var dragging_orbit := false
var greeting_lock: Dictionary = {}
var hex_stream: EtheraHexStreamer
var _streamed_hex_key := ""
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
var store_chrome: PanelContainer
var store_list: ItemList
var store_wants := false
var store_item_ids: Array[String] = []
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
@onready var hex_host: Node3D = $World/HexHost
var authored_views: Dictionary = {}

var panel_tab := "traits"
var panel_refreshing := false
var panel_identity: Label
var panel_body: Label
var panel_gear: Label
var panel_tab_row: HBoxContainer
var panel_page: Label
var panel_shards: ItemList
var panel_shard_detail: Label
var panel_needs: VBoxContainer
var destiny_button: Button
var character_root: Control
var destiny_root: Control
var destiny_task_title: Label
var destiny_body: Label
var destiny_tasks: VBoxContainer
var destiny_open := false
var task_list_open := false
var _need_button_key := ""
var _task_button_key := ""
var log_label: Label
var overlay: Control
var toast_label: Label
var toast_until_ms := 0
var toast_seen_ms := -1
var _seen_holders: Dictionary = {}
var _holders_primed := false
var _equipped_weapon := ""
var _equipped_herb := ""

func _ready() -> void:
	simulation = EtheraSimulation.new()
	assets = EtheraAssetLibrary.new()
	handoff = EtheraItemHandoff.new()
	assets.load_from_res()
	_build_hud()
	_configure_sun()
	_setup_day_night()
	assets.try_mount_environment(world_root, hex_host)
	_make_hex_ground()
	_bind_authored_hex_objects()
	_bind_world_node_occupants()
	_bind_scenery_blockers()
	if hex_stream != null:
		_streamed_hex_key = hex_stream.loaded_key()
	_rebuild_views()
	_bind_terrain_follow()
	_apply_living_stone_glow()
	var orientation = (preload("res://scripts/presentation/divine_orientation.gd") as GDScript).new()
	orientation.name = "DivineOrientation"
	orientation.game = self
	world_root.add_child(orientation)
	_refresh_hud()
	_build_store_panel()


func _process(delta: float) -> void:
	_advance_simulation(delta)
	_advance_day_night(delta)
	_apply_mouse_mode()
	_update_hold_radial()
	_sync_hex_stream()
	_sync_views(delta)
	_sync_view_ring()
	_refresh_greeting_lock()
	_apply_living_stone_glow()
	_update_camera()
	_sync_store_panel()
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
	if event.is_action_pressed("toggle_destiny"):
		if panel_visible and destiny_open:
			panel_visible = false
		else:
			panel_visible = true
			destiny_open = true
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_character_panel"):
		panel_visible = not panel_visible
		get_viewport().set_input_as_handled()
		return
	if _skill_overlay_active():
		_set_orbit_dragging(false)
		_handle_skill_input(event)
		return
	if not greeting_lock.is_empty() and (event is InputEventMouseButton or event is InputEventMouseMotion):
		_set_orbit_dragging(false)
		holding_left = false
		get_viewport().set_input_as_handled()
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
			store_wants = true
			_open_store_if_ready(target_id)
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
	var stale: Array = []
	for entity_id in views.keys():
		if not authored_views.has(entity_id):
			stale.append(entity_id)
	for entity_id in stale:
		var child: Variant = views[entity_id]
		if child is Node:
			(child as Node).queue_free()
		views.erase(entity_id)
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
		var holder_id: Variant = entity.get("holder_id", null)
		_note_pickup(entity_id, holder_id)
		var carried: bool = not EtheraIds.is_empty_slot(holder_id) and views.has(str(holder_id))
		var pos: Dictionary = entity.get("position", {})
		var rest := Vector3(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)), float(pos.get("z", 0.0)))
		if authored_views.has(entity_id):
			node.visible = bool(entity.get("manifested", false))
			_sync_grass_sink(node, entity, delta)
			_sync_speech(node, entity)
			continue
		if not carried:
			rest.y = terrain_height(rest.x, rest.z)
		var yaw: float = float(entity.get("yaw", 0.0))
		var goal: Transform3D = EtheraItemHandoff.loose_transform(rest, yaw)
		if carried:
			var holder: Node3D = views[str(holder_id)]
			assets.apply_carried_visual(node, true)
			goal = assets.attach_world_transform(
				holder,
				by_id.get(str(holder_id), {}),
				str(entity.get("attachment", "back")),
				node
			)
		handoff.observe(entity_id, carried, node.global_transform)
		if handoff.is_active(entity_id):
			node.global_transform = handoff.step(entity_id, delta, goal)
			assets.apply_carried_visual(node, carried or handoff.is_airborne(entity_id))
			_sync_grass_sink(node, entity, delta)
			_sync_speech(node, entity)
			continue
		if carried:
			node.global_transform = goal
			assets.apply_carried_visual(node, true)
			_sync_grass_sink(node, entity, delta)
			_sync_speech(node, entity)
			continue
		assets.apply_carried_visual(node, false)
		_sync_grass_sink(node, entity, delta)
		_sync_speech(node, entity)
		if node.global_position.distance_to(rest) > VIEW_SNAP_DISTANCE:
			node.global_transform = goal
		else:
			node.global_transform = node.global_transform.interpolate_with(goal, follow)
	for entity_id in views.keys():
		if seen.has(entity_id) or authored_views.has(entity_id):
			continue
		(views[entity_id] as Node).queue_free()
		views.erase(entity_id)
		handoff.forget(entity_id)
	_note_equipped_pickup()
	_holders_primed = true


# Carried-item layout turns every collision shape back on. The harvested plant
# must stay unclickable afterwards, or its box covers the herb that just dropped.
func _sync_grass_sink(node: Node, entity: Dictionary, delta: float) -> void:
	var sink: Node = node.get_node_or_null("GrassPatchSink")
	if sink == null:
		return
	sink.sync_sink(bool(entity.get("container_opened", false)), delta)


func _note_equipped_pickup() -> void:
	var inhabited_id: String = simulation.query_inhabited_id()
	var actor: Dictionary = simulation.world.get_entity(inhabited_id)
	if actor.is_empty():
		return
	var weapon: String = simulation.world.equipped_item_id(actor, EtheraIds.SLOT_SMALL_WEAPON)
	var herb: String = simulation.world.equipped_item_id(actor, EtheraIds.SLOT_HERB)
	var gained_weapon: bool = weapon != "" and weapon != _equipped_weapon
	var gained_herb: bool = herb != "" and herb != _equipped_herb
	if _holders_primed and (gained_weapon or gained_herb):
		var body: Node = views.get(inhabited_id)
		var animator: Node = body.get_node_or_null("CharacterAnimation") if body != null else null
		if animator != null and animator.has_method("play_pickup"):
			animator.play_pickup()
	_equipped_weapon = weapon
	_equipped_herb = herb


func _note_pickup(entity_id: String, holder_id: Variant) -> void:
	var holder := "" if EtheraIds.is_empty_slot(holder_id) else str(holder_id)
	var inhabited_id: String = simulation.query_inhabited_id()
	var previous := str(_seen_holders.get(entity_id, ""))
	var known: bool = _seen_holders.has(entity_id)
	var taken: bool = holder == inhabited_id and holder != ""
	if _holders_primed and taken and ((known and previous != inhabited_id) or not known):
		var body: Node = views.get(inhabited_id)
		var animator: Node = body.get_node_or_null("CharacterAnimation") if body != null else null
		if animator != null and animator.has_method("play_pickup"):
			animator.play_pickup()
	_seen_holders[entity_id] = holder


func _sync_speech(node: Node3D, entity: Dictionary) -> void:
	var text: String = str(entity.get("speech_text", ""))
	var label: Label3D = node.get_node_or_null("Speech") as Label3D
	if text == "":
		if label != null:
			label.visible = false
		return
	if label == null:
		label = Label3D.new()
		label.name = "Speech"
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.pixel_size = 0.004
		label.outline_size = 16
		label.modulate = Color(0.16, 0.12, 0.08)
		label.outline_modulate = Color(0.96, 0.93, 0.84)
		label.position = Vector3(0.0, 2.05, 0.0)
		node.add_child(label)
	label.text = text
	label.visible = true
	label.position = Vector3(0.0, 2.05, 0.0)


func _ensure_view(entity: Dictionary) -> void:
	var entity_id: String = str(entity.get("id", ""))
	if views.has(entity_id) or str(entity.get("kind", "")) == "place":
		return
	if authored_views.has(entity_id):
		return
	var body: StaticBody3D = assets.make_entity_body(entity)
	world_root.add_child(body)
	views[entity_id] = body


func _bind_authored_hex_objects() -> void:
	if hex_stream == null:
		return
	var placements: Array = []
	for hex in hex_stream.loaded_hexes():
		if not (hex is EtheraHexTile):
			continue
		for hall in (hex as EtheraHexTile).find_children("*", "EtheraTownHall", true, false):
			if hall is EtheraTownHall:
				views[EtheraIds.ENTITY_TOWN_HALL] = hall
				authored_views[EtheraIds.ENTITY_TOWN_HALL] = true
		for placed in (hex as EtheraHexTile).placed_entities():
			if placed.entity_id == "":
				continue
			var first: bool = not authored_views.has(placed.entity_id)
			views[placed.entity_id] = placed
			authored_views[placed.entity_id] = true
			if not first:
				continue
			placements.append({
				"entity_id": placed.entity_id,
				"x": placed.global_position.x,
				"z": placed.global_position.z,
				"yaw": placed.rotation.y,
			})
		# Hex grass and stones are editor markers. Play uses the existing grass
		# patches and shapeable rocks spawned from landscape data.
		for raw in (hex as EtheraHexTile).landscape_placements():
			if str(raw.get("entity_id", "")) != "":
				placements.append(raw)
	if not placements.is_empty():
		simulation.adopt_authored_placements(placements)


func _bind_scenery_blockers() -> void:
	if hex_stream == null:
		return
	var blockers: Array = []
	for hex in hex_stream.loaded_hexes():
		if hex is EtheraHexTile:
			blockers.append_array((hex as EtheraHexTile).scenery_blockers())
	simulation.adopt_scenery_blockers(blockers)


func _bind_world_node_occupants() -> void:
	if hex_stream == null:
		return
	var placements: Array = []
	var seated: Dictionary = {}
	for hex in hex_stream.loaded_hexes():
		if not (hex is EtheraHexTile):
			continue
		for entity_id in simulation.world.entities.keys():
			var entity: Dictionary = simulation.world.get_entity(str(entity_id))
			var node_id: String = str(entity.get("world_node_id", ""))
			if node_id == "" or seated.has(str(entity_id)):
				continue
			var marker: EtheraWorldNodeMarker = (hex as EtheraHexTile).world_node_marker(node_id)
			if marker == null:
				continue
			seated[str(entity_id)] = true
			placements.append({
				"entity_id": str(entity_id),
				"x": marker.global_position.x,
				"z": marker.global_position.z,
				"yaw": marker.rotation.y,
			})
	if not placements.is_empty():
		simulation.adopt_authored_placements(placements)


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
# Presentation Y can sit on a town hall floor; slope checks still use the hex sculpt.
func terrain_height(x: float, z: float) -> float:
	var ground := 0.0
	if hex_stream != null:
		ground = hex_stream.height_at(x, z)
	var floor_y: float = _walk_floor_height(x, z)
	if not is_nan(floor_y):
		return maxf(ground, floor_y)
	return ground


func _walk_floor_height(x: float, z: float) -> float:
	if hex_stream == null:
		return NAN
	var best := NAN
	for hex in hex_stream.loaded_hexes():
		if not (hex is EtheraHexTile):
			continue
		var floor_y: float = (hex as EtheraHexTile).walk_floor_height(x, z)
		if is_nan(floor_y):
			continue
		if is_nan(best) or floor_y > best:
			best = floor_y
	return best


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
	var key: String = hex_stream.loaded_key()
	if key == _streamed_hex_key:
		return
	_streamed_hex_key = key
	_bind_authored_hex_objects()
	_bind_world_node_occupants()
	_bind_scenery_blockers()
	_bind_terrain_follow()


func _bind_terrain_follow() -> void:
	if hex_stream == null:
		return
	var actor: Node3D = views.get(simulation.query_inhabited_id()) as Node3D
	if actor == null:
		return
	for hex in hex_stream.loaded_hexes():
		if hex is EtheraHexTile:
			(hex as EtheraHexTile).follow_actor(actor)


func _sync_view_ring() -> void:
	if hex_stream == null:
		return
	var inhabited_id: String = simulation.query_inhabited_id()
	var actor: Node3D = views.get(inhabited_id) as Node3D
	if actor == null:
		return
	var xz := Vector2(actor.global_position.x, actor.global_position.z)
	for hex in hex_stream.loaded_hexes():
		if hex is EtheraHexTile:
			(hex as EtheraHexTile).sync_view_ring(xz)
	var radius_sq: float = EtheraHexTile.VIEW_RING_RADIUS * EtheraHexTile.VIEW_RING_RADIUS
	for entity_id in views.keys():
		if str(entity_id) == inhabited_id:
			continue
		var node: Node3D = views[entity_id] as Node3D
		if node == null:
			continue
		var dx: float = node.global_position.x - xz.x
		var dz: float = node.global_position.z - xz.y
		if dx * dx + dz * dz > radius_sq:
			node.visible = false


func _make_hex_ground() -> void:
	if hex_host == null or not hex_host.visible:
		return
	hex_stream = EtheraHexStreamer.new()
	hex_stream.name = "HexStream"
	hex_host.add_child(hex_stream)
	hex_stream.setup(hex_host as CollisionObject3D)


func _build_store_panel() -> void:
	store_chrome = _make_chrome_panel()
	store_chrome.anchor_left = 0.5
	store_chrome.anchor_top = 0.5
	store_chrome.anchor_right = 0.5
	store_chrome.anchor_bottom = 0.5
	store_chrome.offset_left = -180
	store_chrome.offset_top = -220
	store_chrome.offset_right = 180
	store_chrome.offset_bottom = 220
	store_chrome.visible = false
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_top = 12
	box.offset_right = -12
	box.offset_bottom = -12
	store_chrome.add_child(box)
	var title := Label.new()
	title.text = "Town Hall"
	box.add_child(title)
	store_list = ItemList.new()
	store_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	store_list.item_selected.connect(_on_store_item_selected)
	box.add_child(store_list)
	var place_weapon := Button.new()
	place_weapon.text = "Place stone weapon"
	place_weapon.pressed.connect(func() -> void: _deposit_slot(EtheraIds.SLOT_SMALL_WEAPON))
	box.add_child(place_weapon)
	var place_herb := Button.new()
	place_herb.text = "Place offering herb"
	place_herb.pressed.connect(func() -> void: _deposit_slot(EtheraIds.SLOT_HERB))
	box.add_child(place_herb)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func() -> void:
		store_wants = false
		store_chrome.visible = false
	)
	box.add_child(close)
	hud.add_child(store_chrome)


func _open_store_if_ready(target_id: String) -> void:
	if target_id != EtheraIds.ENTITY_TOWN_HALL:
		return
	var store: Dictionary = simulation.query_store(target_id)
	if not bool(store.get("ui_store", false)):
		return
	for entity in simulation.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == target_id and bool(entity.get("container_opened", entity.get("opened", false))):
			store_wants = true


func _sync_store_panel() -> void:
	if store_chrome == null:
		return
	var opened := false
	for entity in simulation.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == EtheraIds.ENTITY_TOWN_HALL:
			opened = bool(entity.get("container_opened", false))
	var store: Dictionary = simulation.query_store()
	store_chrome.visible = store_wants and opened and bool(store.get("in_reach", false))
	if not store_chrome.visible:
		return
	var next_ids: Array[String] = []
	for item in store.get("items", []):
		next_ids.append(str(item.get("id", "")))
	if next_ids == store_item_ids:
		return
	store_item_ids = next_ids
	store_list.clear()
	for item in store.get("items", []):
		store_list.add_item(str(item.get("name", "item")))


func _on_store_item_selected(index: int) -> void:
	if index < 0 or index >= store_item_ids.size():
		return
	simulation.apply({"type": EtheraIds.CMD_TAKE_STORED, "item_id": store_item_ids[index]})


func _deposit_slot(slot_id: String) -> void:
	simulation.apply({
		"type": EtheraIds.CMD_DEPOSIT_EQUIPPED,
		"slot_id": slot_id,
		"target_id": EtheraIds.ENTITY_TOWN_HALL,
	})


func _update_camera() -> void:
	# The camera follows the smoothed view rather than the 20 Hz authoritative pose.
	var actor_view: Node3D = views.get(simulation.query_inhabited_id())
	if actor_view == null:
		return
	var close: float = clampf(inverse_lerp(ORBIT_FAR, ORBIT_NEAR, orbit_distance), 0.0, 1.0)
	var orbit_pitch: float = lerpf(ORBIT_PITCH_FAR, ORBIT_PITCH_NEAR, close)
	var look_ahead: float = lerpf(ORBIT_LOOK_AHEAD_FAR, ORBIT_LOOK_AHEAD_NEAR, close)
	var ahead := Vector3(-sin(orbit_yaw), 0.0, -cos(orbit_yaw)) * look_ahead
	var focus: Vector3 = actor_view.global_position + Vector3(0.0, ORBIT_FOCUS_HEIGHT, 0.0) + ahead
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
	camera.fov = ORBIT_FOV
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
		if node != null and not node.visible:
			continue
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
	if hex_stream != null:
		for hex in hex_stream.loaded_hexes():
			if not (hex is EtheraHexTile):
				continue
			for child in (hex as EtheraHexTile).get_children():
				if not (child is Node3D) or not (child as Node3D).visible:
					continue
				if child is EtheraBush or child is EtheraStoneBench:
					volumes.append_array(_orbit_volumes_from_view(child))
				elif child is EtheraPlacedEntity and (child as EtheraPlacedEntity).definition_id == EtheraPlacedEntity.DEFINITION_CRADLE:
					volumes.append_array(_orbit_volumes_from_view(child))
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


# Occupancy is a disk for walking. The camera only pulls in when it would sit
# inside a visible solid, not because something stands between it and her, and
# not for a column of air above a small basin or the empty middle of a ring.
static func orbit_ray_blocked_distance(origin: Vector3, direction: Vector3, max_distance: float, cylinders: Array, skin: float = ORBIT_CAMERA_RADIUS) -> float:
	if direction.length() < 0.0001 or max_distance <= 0.0:
		return max_distance
	var dir: Vector3 = direction.normalized()
	var camera_at: Vector3 = origin + dir * max_distance
	var best: float = max_distance
	for raw in cylinders:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var volume: Dictionary = (raw as Dictionary).duplicate()
		volume["radius"] = float(volume.get("radius", 0.0)) + skin
		volume["y_min"] = float(volume.get("y_min", -2.0)) - skin
		volume["y_max"] = float(volume.get("y_max", 4.0)) + skin
		if not _point_in_vertical_cylinder(camera_at, volume):
			continue
		var hit: float = _vertical_cylinder_hit(origin, dir, max_distance, volume)
		if hit < INF:
			best = minf(best, hit)
	return maxf(ORBIT_COLLISION_MIN, best)


static func _point_in_vertical_cylinder(point: Vector3, cylinder: Dictionary) -> bool:
	var radius: float = float(cylinder.get("radius", 0.0))
	if radius <= 0.0:
		return false
	var dx: float = point.x - float(cylinder.get("x", 0.0))
	var dz: float = point.z - float(cylinder.get("z", 0.0))
	if dx * dx + dz * dz > radius * radius:
		return false
	return point.y >= float(cylinder.get("y_min", -2.0)) and point.y <= float(cylinder.get("y_max", 4.0))


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
		var world_at: Vector3 = _discovery_aim_point(str(entity.get("id", "")), entity)
		if camera.is_position_behind(world_at):
			continue
		var distance: float = camera.unproject_position(world_at).distance_to(mouse)
		if distance >= best_distance:
			continue
		if not _has_line_of_sight(camera.global_position, world_at, str(entity.get("id", ""))):
			continue
		best_distance = distance
		best_id = str(entity.get("id", ""))
	return best_id


func _discovery_aim_point(entity_id: String, entity: Dictionary) -> Vector3:
	var node: Node3D = views.get(entity_id) as Node3D
	if node != null and node.is_inside_tree():
		return node.global_position + Vector3(0.0, 1.46, 0.0)
	var position: Dictionary = entity.get("position", {})
	var x: float = float(position.get("x", 0.0))
	var z: float = float(position.get("z", 0.0))
	return Vector3(x, terrain_height(x, z) + 1.46, z)


func _has_line_of_sight(from: Vector3, to: Vector3, allow_id: String = "") -> bool:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.hit_from_inside = true
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return true
	var entity_id: String = _entity_id_from_collider(hit.get("collider"))
	if entity_id != "" and (allow_id == "" or entity_id == allow_id):
		return true
	return from.distance_to(hit.get("position", from)) + 0.2 >= from.distance_to(to)


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
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.fog_enabled = true


func _setup_day_night() -> void:
	var cycle: EtheraDayNight = get_node_or_null("DayNight") as EtheraDayNight
	if cycle == null:
		cycle = EtheraDayNight.new()
		cycle.name = "DayNight"
		add_child(cycle)
	cycle.setup(
		get_node_or_null("Sun") as DirectionalLight3D,
		get_node_or_null("WorldEnvironment") as WorldEnvironment,
		camera
	)


func _advance_day_night(delta: float) -> void:
	var cycle: EtheraDayNight = get_node_or_null("DayNight") as EtheraDayNight
	if cycle != null:
		cycle.advance(delta)


func _apply_living_stone_glow() -> void:
	var cycle: EtheraDayNight = get_node_or_null("DayNight") as EtheraDayNight
	if cycle != null:
		cycle.apply_living_stone_glow()


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
		var kind: String = str(entry.get("kind", ""))
		if kind != "place_discovered" and kind != "task_taken":
			continue
		var when: int = int(entry.get("world_time", 0))
		if when <= toast_seen_ms:
			continue
		toast_seen_ms = when
		if kind == "task_taken":
			toast_label.text = "Task\n%s" % str(entry.get("task_name", entry.get("text", "")))
		else:
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
	status_label.text = "Local simulation running\n%s\nC toggles the character panel\nJ opens Destiny" % ("Models loaded from assets/models" if using_models else "Placeholder meshes; drop GLBs into assets/models")
	title_chrome.visible = not panel_visible
	log_chrome.visible = true
	title_content.visible = title_open
	log_label.visible = log_open
	log_label.custom_minimum_size = Vector2(380, 280) if log_open else Vector2(0, 0)
	log_chrome.offset_bottom = 16 + (328 if log_open else 44)
	title_toggle.text = "▾" if title_open else "▸"
	log_toggle.text = "▾" if log_open else "▸"
	panel_chrome.visible = panel_visible
	if not panel_visible:
		destiny_open = false
		task_list_open = false
	if character_root != null:
		character_root.visible = not destiny_open
	if destiny_root != null:
		destiny_root.visible = panel_visible and destiny_open
	if panel_visible:
		log_chrome.move_to_front()
	if panel_visible:
		_refresh_character_panel(simulation.query_panel())
		if destiny_open:
			_refresh_destiny(simulation.query_panel())
	var lines: PackedStringArray = PackedStringArray()
	for entry in simulation.query_dev_log(16):
		lines.append(str(entry.get("text", "")))
	log_label.text = "\n".join(lines)
	overlay.queue_redraw()


func _build_character_panel(host: PanelContainer) -> void:
	var ink := Color(0.93, 0.90, 0.82)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	host.add_child(root)
	character_root = root
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_identity = _panel_label(ink, 22)
	panel_body = _panel_label(ink)
	panel_gear = _panel_label(ink)
	destiny_button = Button.new()
	destiny_button.text = "Destiny"
	destiny_button.focus_mode = Control.FOCUS_NONE
	destiny_button.pressed.connect(func() -> void:
		destiny_open = true
	)
	left.add_child(panel_identity)
	left.add_child(panel_body)
	left.add_child(panel_gear)
	left.add_child(destiny_button)
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
	panel_needs = VBoxContainer.new()
	panel_needs.visible = false
	panel_needs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(panel_needs)
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
	_build_destiny_screen(host)


func _build_destiny_screen(host: PanelContainer) -> void:
	var ink := Color(0.93, 0.90, 0.82)
	destiny_root = VBoxContainer.new()
	destiny_root.visible = false
	destiny_root.add_theme_constant_override("separation", 10)
	host.add_child(destiny_root)
	var header := HBoxContainer.new()
	var back := Button.new()
	back.text = "Character"
	back.custom_minimum_size = Vector2(110, 0)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void:
		destiny_open = false
		task_list_open = false
	)
	header.add_child(back)
	var title := Label.new()
	title.text = "Destiny"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", ink)
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(110, 0)
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(balance)
	destiny_root.add_child(header)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	destiny_root.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	destiny_task_title = _panel_label(ink, 20)
	left.add_child(destiny_task_title)
	destiny_body = _panel_label(ink)
	destiny_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(destiny_body)
	destiny_tasks = VBoxContainer.new()
	destiny_tasks.visible = false
	left.add_child(destiny_tasks)
	var common := Button.new()
	common.text = "Common tasks"
	common.focus_mode = Control.FOCUS_NONE
	common.alignment = HORIZONTAL_ALIGNMENT_LEFT
	common.pressed.connect(func() -> void:
		task_list_open = not task_list_open
	)
	left.add_child(common)
	var crest = (preload("res://scripts/presentation/destiny_crest.gd") as GDScript).new()
	crest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crest.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crest.size_flags_stretch_ratio = 3.0
	columns.add_child(crest)


func _sync_need_buttons(needs: Variant) -> void:
	var records: Array = needs if typeof(needs) == TYPE_ARRAY else []
	var key: String = ""
	for entry in records:
		if typeof(entry) == TYPE_DICTIONARY:
			key += str(entry.get("id", "")) + "|"
	if key == _need_button_key:
		return
	_need_button_key = key
	for child in panel_needs.get_children():
		child.queue_free()
	var heading := Label.new()
	heading.text = "Needs"
	heading.add_theme_color_override("font_color", Color(0.93, 0.90, 0.82))
	panel_needs.add_child(heading)
	if records.is_empty():
		var empty := Label.new()
		empty.text = "none"
		empty.add_theme_color_override("font_color", Color(0.93, 0.90, 0.82))
		panel_needs.add_child(empty)
		return
	for entry in records:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var button := Button.new()
		var name: String = str(entry.get("name", entry.get("id", "")))
		if bool(entry.get("important", false)):
			button.text = "%s    important" % name
			button.modulate = Color(1.0, 0.92, 0.62)
		else:
			button.text = name
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var need_id: String = str(entry.get("id", ""))
		button.pressed.connect(_choose_need.bind(need_id))
		panel_needs.add_child(button)


func _choose_need(need_id: String) -> void:
	simulation.apply({"type": EtheraIds.CMD_SELECT_NEED, "need_id": need_id})
	destiny_open = true


func _refresh_destiny(panel: Dictionary) -> void:
	if destiny_tasks == null:
		return
	destiny_tasks.visible = task_list_open
	var tasks: Array = panel.get("tasks", [])
	var key: String = ""
	for entry in tasks:
		if typeof(entry) == TYPE_DICTIONARY:
			key += str(entry.get("id", "")) + "|"
	if key != _task_button_key:
		_task_button_key = key
		for child in destiny_tasks.get_children():
			child.queue_free()
		if tasks.is_empty():
			var empty := Label.new()
			empty.text = "none"
			empty.add_theme_color_override("font_color", Color(0.93, 0.90, 0.82))
			destiny_tasks.add_child(empty)
		for entry in tasks:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.set_meta("task_id", str(entry.get("id", "")))
			var task_id: String = str(entry.get("id", ""))
			button.pressed.connect(_choose_task.bind(task_id))
			destiny_tasks.add_child(button)
	var active_name := ""
	for button in destiny_tasks.get_children():
		if not button.has_meta("task_id"):
			continue
		var task_id: String = str(button.get_meta("task_id", ""))
		var task_name: String = task_id
		var active: bool = false
		for entry in tasks:
			if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == task_id:
				task_name = str(entry.get("name", task_id))
				active = bool(entry.get("active", false))
		button.text = ("priority stone    " if active else "") + task_name
		if active:
			active_name = task_name
	if active_name == "":
		destiny_task_title.text = "No common task"
		destiny_body.text = ""
		return
	destiny_task_title.text = active_name
	var checklist: Dictionary = panel.get("checklist", {})
	var lines: PackedStringArray = PackedStringArray(["priority stone", "", "Goal", str(checklist.get("goal", ""))])
	lines.append("")
	lines.append("Known requirements")
	var requirements: Array = checklist.get("requirements", [])
	if requirements.is_empty():
		lines.append("none")
	else:
		for requirement in requirements:
			if typeof(requirement) == TYPE_DICTIONARY:
				lines.append(str(requirement.get("text", "")))
	destiny_body.text = "\n".join(lines)


func _choose_task(task_id: String) -> void:
	simulation.apply({"type": EtheraIds.CMD_ACTIVATE_TASK, "task_id": task_id})
	task_list_open = false


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
	var show_interactions: bool = panel_tab == "interactions"
	panel_shards.visible = show_shards or show_states or show_interactions
	panel_shard_detail.visible = show_shards or show_states or show_interactions
	var show_needs: bool = panel_tab == "needs"
	panel_needs.visible = show_needs
	panel_page.visible = not show_shards and not show_states and not show_needs and not show_interactions
	if show_needs:
		_sync_need_buttons(panel.get("needs", []))
	if show_shards:
		_fill_panel_list(shards, "No known Shards.", _shard_title, _shard_detail)
		panel_refreshing = false
		return
	if show_states:
		_fill_panel_list(states, "No current States.", _state_title, _state_detail)
		panel_refreshing = false
		return
	if show_interactions:
		_fill_panel_list(panel.get("known_interactions", []), "No discovered interactions.", _interaction_title, _interaction_detail)
		panel_refreshing = false
		return
	panel_page.text = _named_list("Traits", panel.get("traits", []))
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
		if typeof(entry) == TYPE_DICTIONARY:
			var tip: String = _interaction_tooltip(entry)
			if tip != "":
				panel_shards.set_item_tooltip(panel_shards.item_count - 1, tip)
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


func _interaction_title(entry: Variant) -> String:
	var data: Dictionary = entry if typeof(entry) == TYPE_DICTIONARY else {}
	return str(data.get("name", data.get("id", "interaction")))


func _interaction_detail(entry: Variant) -> String:
	var data: Dictionary = entry if typeof(entry) == TYPE_DICTIONARY else {}
	var lines: PackedStringArray = PackedStringArray([str(data.get("name", ""))])
	var description: String = str(data.get("description", ""))
	if description != "":
		lines.append(description)
	lines.append("")
	lines.append("Requires")
	var requirements: Array = data.get("requirements", [])
	if requirements.is_empty():
		lines.append("none")
	else:
		for phrase in requirements:
			lines.append(str(phrase))
	return "\n".join(lines)


func _interaction_tooltip(entry: Dictionary) -> String:
	var description: String = str(entry.get("description", ""))
	var requires: String = _requirement_tooltip(entry.get("requirements", []))
	if description == "":
		return requires
	if requires == "":
		return description
	return "%s\n%s" % [description, requires]


func _requirement_tooltip(requirements: Variant) -> String:
	if typeof(requirements) != TYPE_ARRAY or (requirements as Array).is_empty():
		return ""
	var chunks: PackedStringArray = PackedStringArray()
	var current: PackedStringArray = PackedStringArray()
	for phrase in requirements:
		if str(phrase) == "or":
			if current.size() > 0:
				chunks.append(", ".join(current))
			current = PackedStringArray()
		else:
			current.append(str(phrase))
	if current.size() > 0:
		chunks.append(", ".join(current))
	if chunks.is_empty():
		return ""
	return "Requires %s" % " or ".join(chunks)


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


func _refresh_greeting_lock() -> void:
	greeting_lock = {}
	var snapshot: Dictionary = simulation.query_world_view()
	var now_ms: int = int(snapshot.get("world_time_ms", 0))
	var inhabited_id: String = str(snapshot.get("inhabited_entity_id", ""))
	for entity in snapshot.get("entities", []):
		if str(entity.get("id", "")) != inhabited_id:
			continue
		var until_ms: int = int(entity.get("greeting_focus_until_ms", 0))
		if until_ms <= now_ms:
			return
		greeting_lock = {
			"target_id": str(entity.get("greeting_focus_target_id", "")),
			"started_ms": int(entity.get("greeting_focus_started_ms", now_ms)),
			"until_ms": until_ms,
			"now_ms": now_ms,
		}
		return


func _draw_overlay() -> void:
	_draw_greeting_ring()
	if not panel_visible:
		_draw_hover_cursor()
		_draw_radial()
	_draw_skill()


func _draw_greeting_ring() -> void:
	if greeting_lock.is_empty():
		return
	var started_ms: int = int(greeting_lock.get("started_ms", 0))
	var until_ms: int = int(greeting_lock.get("until_ms", started_ms + 1))
	var span: float = maxf(1.0, float(until_ms - started_ms))
	var closed: float = clampf(float(int(greeting_lock.get("now_ms", started_ms)) - started_ms) / span, 0.0, 1.0)
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var gold := Color(0.86, 0.72, 0.32, 0.95)
	overlay.draw_arc(mouse, lerpf(28.0, 4.0, closed), 0.0, TAU, 40, gold, 2.5)
	overlay.draw_arc(mouse, 28.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - closed), 40, Color(0.96, 0.93, 0.84, 0.7), 1.5)


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
