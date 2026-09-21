extends Node3D

const HOLD_MS := 180
const RADIAL_RADIUS := 92.0

var simulation: EtheraSimulation
var assets: EtheraAssetLibrary
var views: Dictionary = {}
var orbit_yaw: float = 0.6
var orbit_pitch: float = 0.7
var orbit_distance: float = 14.0
var dragging_orbit := false
var holding_left := false
var press_time_ms := 0
var press_target_id := ""
var press_screen := Vector2.ZERO
var panel_visible := false
var radial_open := false
var radial_actions: Array[Dictionary] = []
var radial_index := -1
var hover_kind := EtheraIds.HOVER_NONE

@onready var world_root: Node3D = $World
@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $StartupOverlay
@onready var status_label: Label = $StartupOverlay/MarginContainer/VBoxContainer/Status
@onready var title_label: Label = $StartupOverlay/MarginContainer/VBoxContainer/Title
@onready var temporary_ground: Node3D = $World/TemporaryGround

var panel_label: Label
var log_label: Label
var overlay: Control

func _ready() -> void:
	simulation = EtheraSimulation.new()
	assets = EtheraAssetLibrary.new()
	if simulation.catalog.presentation_assets_path != "":
		assets.load_from_res(simulation.catalog.presentation_assets_path)
	else:
		assets.load_from_res()
	_build_hud()
	assets.try_mount_environment(world_root, temporary_ground)
	_rebuild_views()
	_refresh_hud()


func _process(delta: float) -> void:
	simulation.apply({"type": EtheraIds.CMD_TICK, "delta_ms": delta * 1000.0})
	_update_hold_radial()
	_sync_views()
	_update_camera()
	_update_hover()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_panel"):
		panel_visible = not panel_visible
		get_viewport().set_input_as_handled()
		return
	if not simulation.query_skill().is_empty() and str(simulation.query_skill().get("phase", "")) == "skill":
		_handle_skill_input(event)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		orbit_distance = clampf(orbit_distance - 1.2, 4.0, 28.0)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		orbit_distance = clampf(orbit_distance + 1.2, 4.0, 28.0)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var hit: Dictionary = _intersect()
		if str(hit.get("kind", "")) == "ground":
			var point: Vector3 = hit.get("position", Vector3.ZERO)
			simulation.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": point.x, "y": 0.0, "z": point.z})
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_left_mouse(event)
	elif event is InputEventMouseMotion and dragging_orbit:
		orbit_yaw -= event.relative.x * 0.007
		orbit_pitch = clampf(orbit_pitch + event.relative.y * 0.007, 0.25, 1.35)


func _handle_left_mouse(event: InputEventMouseButton) -> void:
	if event.pressed:
		holding_left = true
		press_time_ms = Time.get_ticks_msec()
		press_screen = event.position
		var hit: Dictionary = _intersect()
		press_target_id = str(hit.get("entity_id", ""))
		dragging_orbit = press_target_id == simulation.world.inhabited_entity_id
		return
	holding_left = false
	dragging_orbit = false
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
	var hit: Dictionary = _intersect()
	var target_id: String = str(hit.get("entity_id", ""))
	if held < HOLD_MS and target_id != "":
		var hover: Dictionary = simulation.query_hover(simulation.world.inhabited_entity_id, target_id)
		if str(hover.get("kind", "")) == EtheraIds.HOVER_PICKUP or str(hover.get("kind", "")) == EtheraIds.HOVER_SWAP:
			simulation.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": target_id})
			get_viewport().set_input_as_handled()


func _update_hold_radial() -> void:
	if radial_open:
		radial_index = EtheraRadialSelection.highlighted_index(press_screen, get_viewport().get_mouse_position(), radial_actions.size())
		return
	if not holding_left or dragging_orbit or press_target_id == "":
		return
	if Time.get_ticks_msec() - press_time_ms < HOLD_MS:
		return
	var actions: Array[Dictionary] = simulation.query_available_interactions(simulation.world.inhabited_entity_id, press_target_id)
	if actions.is_empty():
		return
	radial_open = true
	radial_actions = actions
	radial_index = -1
	_set_focus_hold(true)


func _close_radial() -> void:
	radial_open = false
	radial_actions = []
	radial_index = -1
	_set_focus_hold(false)


func _set_focus_hold(held: bool) -> void:
	simulation.apply({"type": EtheraIds.CMD_SET_FOCUS_HOLD, "held": held})


func _handle_skill_input(event: InputEvent) -> void:
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


func _sync_views() -> void:
	var seen: Dictionary = {}
	var snapshot: Dictionary = simulation.query_world_view()
	for entity in snapshot.get("entities", []):
		var entity_id: String = str(entity.get("id", ""))
		seen[entity_id] = true
		_ensure_view(entity)
		var node: Node3D = views.get(entity_id)
		if node == null:
			continue
		node.visible = bool(entity.get("manifested", false))
		var pos: Dictionary = entity.get("position", {})
		var world_pos := Vector3(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)), float(pos.get("z", 0.0)))
		var holder_id: Variant = entity.get("holder_id", null)
		if not EtheraIds.is_empty_slot(holder_id) and views.has(str(holder_id)):
			var holder: Node3D = views[str(holder_id)]
			node.global_position = assets.attach_world_position(holder, simulation.world.get_entity(str(holder_id)))
			node.rotation.y = holder.rotation.y
		else:
			node.global_position = world_pos
			node.rotation.y = float(entity.get("yaw", 0.0))
	for entity_id in views.keys():
		if not seen.has(entity_id):
			(views[entity_id] as Node).queue_free()
			views.erase(entity_id)


func _ensure_view(entity: Dictionary) -> void:
	var entity_id: String = str(entity.get("id", ""))
	if views.has(entity_id) or str(entity.get("kind", "")) == "place":
		return
	var body: StaticBody3D = assets.make_entity_body(entity)
	world_root.add_child(body)
	views[entity_id] = body


func _update_camera() -> void:
	var actor: Dictionary = simulation.world.inhabiting()
	if actor.is_empty():
		return
	var focus: Vector3 = simulation.world.position_of(actor) + Vector3(0.0, 1.1, 0.0)
	var offset := Vector3(
		sin(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		cos(orbit_yaw) * cos(orbit_pitch)
	) * orbit_distance
	camera.global_position = focus + offset
	camera.look_at(focus)


func _update_hover() -> void:
	hover_kind = EtheraIds.HOVER_NONE
	if radial_open or dragging_orbit:
		return
	if not simulation.query_skill().is_empty() and str(simulation.query_skill().get("phase", "")) == "skill":
		return
	var hit: Dictionary = _intersect()
	var target_id: String = str(hit.get("entity_id", ""))
	if target_id == "":
		return
	hover_kind = str(simulation.query_hover(simulation.world.inhabited_entity_id, target_id).get("kind", EtheraIds.HOVER_NONE))


func _intersect() -> Dictionary:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse)
	var direction: Vector3 = camera.project_ray_normal(mouse)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 200.0)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return {}
	var collider: Object = hit.get("collider")
	if collider is Node and (collider as Node).has_meta("entity_id"):
		return {"kind": "entity", "entity_id": str((collider as Node).get_meta("entity_id")), "position": hit.get("position")}
	return {"kind": "ground", "position": hit.get("position")}


func _build_hud() -> void:
	title_label.text = "Ethera: The Stonewrought"
	panel_label = Label.new()
	panel_label.visible = false
	panel_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(panel_label)
	panel_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_label.position = Vector2(32, 120)
	panel_label.size = Vector2(460, 420)
	log_label = Label.new()
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(log_label)
	log_label.anchor_left = 1.0
	log_label.anchor_right = 1.0
	log_label.offset_left = -520
	log_label.offset_right = -24
	log_label.offset_top = 24
	log_label.offset_bottom = 320
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(overlay)
	overlay.draw.connect(_draw_overlay)


func _refresh_hud() -> void:
	var using_models: bool = assets.has_model("asset.khar_morr") or assets.has_model("asset.memory_fountain") or assets.has_model("asset.village_center")
	status_label.text = "Local simulation running\n%s\nC toggles the character panel" % ("Models loaded from assets/models" if using_models else "Placeholder meshes; drop GLBs into assets/models")
	panel_label.visible = panel_visible
	if panel_visible:
		panel_label.text = _panel_text(simulation.query_panel())
	var lines: PackedStringArray = PackedStringArray()
	for entry in simulation.query_dev_log(12):
		lines.append(str(entry.get("text", "")))
	log_label.text = "\n".join(lines)
	overlay.queue_redraw()


func _panel_text(panel: Dictionary) -> String:
	var shards: PackedStringArray = PackedStringArray()
	for shard_entry in panel.get("known_shards", []):
		shards.append("%s (%s)" % [str(shard_entry.get("id", "")), str(shard_entry.get("action_id", ""))])
	var traits: PackedStringArray = PackedStringArray()
	for trait_entry in panel.get("traits", []):
		traits.append(str(trait_entry.get("name", trait_entry.get("id", ""))))
	var interactions: PackedStringArray = PackedStringArray()
	for interaction in panel.get("known_interactions", []):
		interactions.append(str(interaction.get("name", interaction.get("id", ""))))
	var body: PackedStringArray = PackedStringArray()
	var regions: Dictionary = panel.get("body_regions", {})
	for region_id in regions.keys():
		var region: Dictionary = regions[region_id]
		body.append("%s %s" % [str(region.get("name", region_id)), str(region.get("condition", ""))])
	var weapon: Dictionary = panel.get("equipment", {}).get(EtheraIds.SLOT_SMALL_WEAPON, {})
	var weapon_text: String = "empty" if bool(weapon.get("empty", true)) else "%s [%s]" % [str(weapon.get("id", "")), str(weapon.get("base_color", ""))]
	return "\n".join(PackedStringArray([
		str(panel.get("name", "")),
		"%s, %s" % [str(panel.get("people", "")), str(panel.get("sex", ""))],
		"Body: %s" % ", ".join(body),
		"Traits: %s" % ", ".join(traits),
		"Known interactions: %s" % ", ".join(interactions),
		"Shards: %s" % (", ".join(shards) if shards.size() > 0 else "none"),
		"Small Weapon: %s" % weapon_text,
	]))


func _skill_pointer_from_screen() -> Vector2:
	var rect := Rect2(Vector2(440, 140), Vector2(400, 400))
	var mouse: Vector2 = get_viewport().get_mouse_position()
	return Vector2(
		clampf((mouse.x - rect.position.x) / rect.size.x, 0.0, 1.0),
		clampf((mouse.y - rect.position.y) / rect.size.y, 0.0, 1.0)
	)


func _draw_overlay() -> void:
	_draw_hover_cursor()
	_draw_radial()
	_draw_skill()


func _draw_hover_cursor() -> void:
	if hover_kind == EtheraIds.HOVER_NONE:
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
	elif hover_kind == EtheraIds.HOVER_INTERACT:
		overlay.draw_arc(mouse + Vector2(10, 10), 10.0, 0.0, TAU, 16, gold, 2.0)


func _draw_radial() -> void:
	if not radial_open:
		return
	var count: int = radial_actions.size()
	overlay.draw_circle(press_screen, 18.0, Color(0.08, 0.08, 0.1, 0.7))
	for i in range(count):
		var slot: Vector2 = EtheraRadialSelection.slot_center(press_screen, i, count, RADIAL_RADIUS)
		var selected: bool = i == radial_index
		var color := Color(0.95, 0.84, 0.4) if selected else Color(0.72, 0.62, 0.28)
		overlay.draw_circle(slot, 28.0, Color(0.08, 0.08, 0.1, 0.82))
		overlay.draw_arc(slot, 28.0, 0.0, TAU, 20, color, 2.0)
		var label: String = str(radial_actions[i].get("name", radial_actions[i].get("id", "")))
		overlay.draw_string(ThemeDB.fallback_font, slot + Vector2(-40, 4), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 14, color)


func _draw_skill() -> void:
	var skill: Dictionary = simulation.query_skill()
	if skill.is_empty() or str(skill.get("phase", "")) != "skill":
		return
	var rect := Rect2(Vector2(440, 140), Vector2(400, 400))
	overlay.draw_rect(rect, Color(0.08, 0.08, 0.1, 0.72))
	var remaining: float = float(skill.get("remaining_ms", 0))
	var duration: float = max(float(skill.get("duration_ms", 1)), 1.0)
	overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(remaining / duration, 0.0, 1.0), 8.0)), Color(0.86, 0.72, 0.32))
	var phase_id: String = str(skill.get("skill_phase_id", ""))
	if phase_id == EtheraIds.SKILL_SHAPE_TRACE:
		var phase: Dictionary = simulation.catalog.get_skill_phase(phase_id)
		var hit: Dictionary = skill.get("checkpoints_hit", {})
		for checkpoint in phase.get("checkpoints", []):
			var center := rect.position + Vector2(float(checkpoint.get("x", 0.0)), float(checkpoint.get("y", 0.0))) * rect.size
			var filled: bool = bool(hit.get(str(checkpoint.get("id", "")), false))
			overlay.draw_circle(center, 14.0, Color(0.95, 0.82, 0.35) if filled else Color(0.62, 0.48, 0.18))
	elif phase_id == EtheraIds.SKILL_SHARD_FIT:
		var center := rect.position + rect.size * 0.5
		overlay.draw_arc(center, 28.0, 0.0, TAU, 24, Color(0.86, 0.72, 0.32), 3.0)
		var angle: float = deg_to_rad(float(skill.get("rotation_degrees", 0.0)))
		var pointer: Vector2 = Vector2(cos(angle), sin(angle)) * 40.0
		overlay.draw_line(center - pointer, center + pointer, Color(0.95, 0.84, 0.4), 4.0)
