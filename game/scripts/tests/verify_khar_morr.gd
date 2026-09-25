extends SceneTree

var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _living_stone_mesh(root: Node) -> MeshInstance3D:
	if root == null:
		return null
	if root is MeshInstance3D and (root as MeshInstance3D).has_meta("living_stone_glow"):
		return root as MeshInstance3D
	for child in root.find_children("*", "MeshInstance3D", true, false):
		if child.has_meta("living_stone_glow"):
			return child
	return null


func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
	else:
		print("PASS: ", message)

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	check(absf(scene.orbit_used_distance(1.4, 6.5, 1.15) - 6.5) < 0.01, "A high orbit keeps its distance")
	var floor_pull: float = scene.orbit_used_distance(-0.35, 6.5, 1.15)
	check(floor_pull < 3.2 and floor_pull > 2.7, "A low tilt that hits the ground pulls the camera in")
	var steep: float = scene.orbit_used_distance(-1.45, 6.5, 1.15)
	check(1.15 + sin(-1.45) * steep >= 0.12 - 0.01, "A steep tilt stays above the ground")
	var fountain := [{"x": 0.0, "z": 0.0, "radius": 2.5, "y_min": -2.0, "y_max": 4.0}]
	var covered: float = scene.orbit_ray_blocked_distance(
		Vector3(5.0, 1.15, 0.0),
		Vector3(-1.0, 0.0, 0.0),
		8.0,
		fountain
	)
	check(absf(covered - 8.0) < 0.01, "A solid between the camera and her does not pull the camera in")
	var colliding: float = scene.orbit_ray_blocked_distance(
		Vector3(5.0, 1.15, 0.0),
		Vector3(-1.0, 0.0, 0.0),
		3.2,
		fountain
	)
	check(colliding < 2.5 and colliding > 2.0, "The camera pulls in when it would sit inside a solid")
	var above_basin: float = scene.orbit_ray_blocked_distance(
		Vector3(0.0, 3.0, 5.0),
		Vector3(0.0, 0.0, -1.0),
		8.0,
		[{"x": 0.0, "z": 0.0, "radius": 0.6, "y_min": 0.0, "y_max": 0.6}]
	)
	check(absf(above_basin - 8.0) < 0.01, "Air above a small basin does not pull the camera")
	check(not scene.register_run_click(Vector3.ZERO, 1000), "The first click walks")
	check(scene.register_run_click(Vector3(0.4, 0.0, 0.0), 1480), "A slower second click still runs")
	check(not scene.register_run_click(Vector3.ZERO, 2800), "A late click walks again")
	check(scene.title_chrome.visible and scene.log_chrome.visible, "Title and log start visible")
	scene.title_open = false
	scene._refresh_hud()
	check(not scene.title_content.visible and scene.title_toggle.visible, "Title hides to its button")
	scene.title_open = true
	scene.log_open = false
	scene._refresh_hud()
	check(not scene.log_label.visible and scene.log_toggle.visible, "The event log hides to its button")
	scene.log_open = true
	scene.panel_visible = true
	scene._refresh_hud()
	check(not scene.title_chrome.visible and not scene.log_chrome.visible, "The character panel hides the other chrome")
	check(scene.panel_chrome.visible, "The character panel is shown")
	check(is_equal_approx(scene.panel_chrome.anchor_left, 0.5) and is_equal_approx(scene.panel_chrome.anchor_top, 0.5), "The character panel is centered")
	check(scene.panel_chrome.offset_right - scene.panel_chrome.offset_left > 700.0, "The character panel is large enough to read")
	check(scene.panel_tab_row.get_child_count() >= 5, "The character panel has concept tabs")
	scene.panel_tab = "shards"
	scene._refresh_character_panel(scene.simulation.query_panel())
	check(scene.panel_shards.visible, "The Shards tab lists known records")
	scene.panel_visible = false
	scene._refresh_hud()
	var pick_shapes: Array = scene.views["entity.khar_morr"].find_children("*", "CollisionShape3D", true, false)
	var fat_pick := false
	for node in pick_shapes:
		var shape: Shape3D = (node as CollisionShape3D).shape
		if shape is CapsuleShape3D and (shape as CapsuleShape3D).radius >= 0.65:
			fat_pick = true
	check(fat_pick, "Orbit picking uses a larger volume around the character")
	var through: Dictionary = scene.walk_pick_from_hits([
		{"kind": "entity", "entity_id": "entity.khar_morr", "position": Vector3(5.2, 1.0, 4.6)},
		{"kind": "ground", "position": Vector3(5.2, 0.0, 2.1)},
	])
	check(str(through.get("kind", "")) == "ground", "Right-click through the character walks on the ground")
	check(scene.hex_stream != null and scene.hex_stream.loaded_count() == 1, "The starting hex is streamed")
	var east: Vector2 = EtheraHexCoords.axial_to_world(1, 0)
	check(absf(east.x - EtheraHexCoords.FLAT_TO_FLAT) < 0.05 and absf(east.y) < 0.05, "The east neighbor is a real edge")
	var hex: EtheraHexTile = scene.hex_stream.hex_at(0, 0) as EtheraHexTile
	check(hex != null, "Axial 0,0 is the authored starting hex")
	var manager: LowPolyTerrainManager = hex.terrain_manager() if hex else null
	check(manager != null, "The starting hex uses the authored Low Poly Terrain")
	check(manager != null and is_equal_approx(manager.hex_flat_to_flat, 256.0), "The starting hex is 256 m flat-to-flat")
	check(manager != null and manager.terrain_shape == LowPolyTerrainManager.TerrainShape.HEXAGON, "The starting hex is a hex tile")
	var chunk_meshes := 0
	var hex_shadow := false
	if manager:
		for coord in manager.get_chunk_coords():
			var chunk_mesh: ArrayMesh = manager.get_chunk_mesh(coord)
			if chunk_mesh != null:
				chunk_meshes += 1
		for mesh_node in manager.find_children("*", "MeshInstance3D", true, false):
			if (mesh_node as MeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
				hex_shadow = true
	check(chunk_meshes > 10, "The authored hex has a terrain mesh")
	check(hex_shadow, "The hex terrain receives and casts shadows")
	await scene.get_tree().physics_frame
	await scene.get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var ground_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(10.0, 12.0, 4.0), Vector3(10.0, -4.0, 4.0)))
	check(not ground_hit.is_empty(), "A downward ray hits the landscape")
	if not ground_hit.is_empty():
		check(scene._entity_id_from_collider(ground_hit.get("collider")) == "", "Landscape clicks hit terrain, not an entity")
	check(absf(scene.terrain_height(0.0, 0.0)) < 1.5, "The fountain pad sits on the authored village floor")
	check(absf(scene.terrain_height(EtheraHexCoords.APOTHEM - 0.5, 0.0)) < 0.04, "Hex edges stay flat so neighbors can join")
	check(is_equal_approx(scene.simulation.world.walkable_slope_degrees(), 50.0), "Walkable slope is fifty degrees")
	check(EtheraTerrain.is_walkable(0.0, 0.0), "The fountain pad stays under fifty degrees")
	check(EtheraTerrain.is_walkable(12.0, 8.0), "Village grassland stays under fifty degrees")
	check(not scene.views.has("entity.hill.1"), "Square-grid occupancy hills are gone")
	var container: Node3D = scene.views.get("entity.container") as Node3D
	var container_pick: CollisionShape3D = container.get_node_or_null("ContainerPick") if container else null
	check(container_pick != null and container_pick.shape is BoxShape3D, "Container pick follows the sculpt")
	if container_pick and container_pick.shape is BoxShape3D:
		var pick_size: Vector3 = (container_pick.shape as BoxShape3D).size
		check(pick_size.x > 0.78 and pick_size.y > 0.50 and pick_size.z > 0.50, "Container pick is as large as the basin")
		check(pick_size.y < 1.4, "Container pick is not a column of air")
	var container_column := false
	for blocker in scene._orbit_blockers():
		if absf(float(blocker.get("x", 0.0)) - 1.2) < 1.2 and absf(float(blocker.get("z", 0.0)) - 88.709) < 1.2:
			if float(blocker.get("y_max", 0.0)) > 1.6:
				container_column = true
	check(not container_column, "A small container does not block the air above it")
	check(scene.views.has("entity.grass.1"), "A grass patch is in the landscape")
	check(scene.views.has("entity.shapeable_rock.scatter.1"), "A scatter rock is in the landscape")
	var seeded_rock: Node3D = scene.views.get("entity.shapeable_rock.scatter.1") as Node3D
	if seeded_rock:
		var rock_box := AABB()
		var rock_first := true
		for mesh_node in seeded_rock.find_children("*", "MeshInstance3D", true, false):
			var mesh := mesh_node as MeshInstance3D
			if mesh.mesh == null:
				continue
			var world_box: AABB = mesh.global_transform * mesh.get_aabb()
			if rock_first:
				rock_box = world_box
				rock_first = false
			else:
				rock_box = rock_box.merge(world_box)
		var ground_y: float = scene.terrain_height(seeded_rock.global_position.x, seeded_rock.global_position.z)
		check(not rock_first and rock_box.position.y < ground_y - 0.04, "Seeded rocks sit a little into the ground")
		check(not rock_first and rock_box.end.y > ground_y + 0.08, "Seeded rocks still stand out of the ground")
	var grass_pick: CollisionShape3D = (scene.views["entity.grass.1"] as Node).get_node_or_null("ContainerPick")
	check(grass_pick != null, "A grass patch uses a container pick volume")
	check((scene.views["entity.grass.1"] as Node).get_node_or_null("GrassPatchSink") != null, "A grass patch can sink when emptied")
	var grass_shadow := false
	for blade in (scene.views["entity.grass.1"] as Node).find_children("*", "MeshInstance3D", true, false):
		if (blade as MeshInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
			grass_shadow = true
	check(grass_shadow, "Grass blades cast shadows")
	var grass_pos: Vector3 = scene.simulation.world.position_of(scene.simulation.world.get_entity("entity.grass.1"))
	var grass_blocked := false
	for blocker in scene._orbit_blockers():
		if absf(float(blocker.get("x", 0.0)) - grass_pos.x) < 0.05 and absf(float(blocker.get("z", 0.0)) - grass_pos.z) < 0.05:
			grass_blocked = true
	check(not grass_blocked, "Grass occupancy does not pull the camera")
	check(not scene._is_orbit_press_target("entity.grass.1"), "A grass patch is not part of the body")
	var ground_at: Vector3 = through.get("position", Vector3.ZERO)
	check(is_equal_approx(ground_at.z, 2.1), "The walk uses the ground behind her")
	var object_walk: Dictionary = scene.walk_command_from_right_click({
		"kind": "entity",
		"entity_id": "entity.club.umber",
		"position": Vector3(3.0, 0.2, 4.0),
	}, false)
	check(str(object_walk.get("type", "")) == "set_walk_destination", "Right-click on an object walks")
	var club_dest := Vector3(float(object_walk.get("x", 0.0)), 0.0, float(object_walk.get("z", 0.0)))
	var club_pos := Vector3(4.6, 0.0, -3.6)
	check(club_dest.distance_to(club_pos) > 0.25, "A walk to an item stops short of it")
	check(club_dest.distance_to(club_pos) < 0.7, "A walk to an item stays next to it")
	check(str(object_walk.get("gait", "")) == "walk", "A single right-click on an object walks")
	var object_run: Dictionary = scene.walk_command_from_right_click({
		"kind": "entity",
		"entity_id": "entity.memory_fountain",
		"position": Vector3(0.0, 1.0, 0.0),
	}, true)
	check(str(object_run.get("gait", "")) == "run", "A right double-click on an object runs")
	var fountain_dest := Vector3(float(object_run.get("x", 0.0)), 0.0, float(object_run.get("z", 0.0)))
	check(fountain_dest.distance_to(Vector3.ZERO) > 2.5, "A walk to the Fountain stops short of its occupancy")
	check(scene.walk_command_from_right_click({
		"kind": "entity",
		"entity_id": "entity.khar_morr",
		"position": Vector3(5.2, 0.0, 4.6),
	}, false).is_empty(), "Right-click on the inhabited body does not walk")
	check(scene._is_orbit_press_target("entity.khar_morr"), "The inhabited body starts orbit")
	check(not scene._is_orbit_press_target("entity.memory_fountain"), "The Fountain does not start orbit")
	var through_item: Dictionary = scene.left_pick_from_hits([
		{"kind": "entity", "entity_id": "entity.khar_morr", "position": Vector3(5.2, 1.0, 4.6)},
		{"kind": "entity", "entity_id": "entity.club.umber", "position": Vector3(4.6, 0.12, -3.6)},
	])
	check(str(through_item.get("entity_id", "")) == "entity.club.umber", "A loose item behind the orbit mask stays clickable")
	var through_ground: Dictionary = scene.left_pick_from_hits([
		{"kind": "entity", "entity_id": "entity.khar_morr", "position": Vector3(5.2, 1.0, 4.6)},
		{"kind": "ground", "position": Vector3(5.2, 0.0, 2.1)},
	])
	check(str(through_ground.get("entity_id", "")) == "entity.khar_morr", "Empty ground behind the orbit mask still starts orbit")
	var through_fountain: Dictionary = scene.left_pick_from_hits([
		{"kind": "entity", "entity_id": "entity.khar_morr", "position": Vector3(5.2, 1.0, 4.6)},
		{"kind": "entity", "entity_id": "entity.memory_fountain", "position": Vector3(0.0, 1.0, 0.0)},
	])
	check(str(through_fountain.get("entity_id", "")) == "entity.khar_morr", "The orbit mask does not yield to the Fountain")
	var through_grass: Dictionary = scene.left_pick_from_hits([
		{"kind": "entity", "entity_id": "entity.khar_morr", "position": Vector3(5.2, 1.0, 4.6)},
		{"kind": "entity", "entity_id": "entity.grass.1", "position": Vector3(2.0, 0.0, 2.0)},
	])
	check(str(through_grass.get("entity_id", "")) == "entity.grass.1", "A grass patch behind the orbit mask still opens")
	var actor: Node3D = scene.views["entity.khar_morr"]
	var animator: Node = actor.get_node("CharacterAnimation")
	animator.set_process(false)
	var players := actor.find_children("*", "AnimationPlayer", true, false)
	check(players.size() == 1, "GLB AnimationPlayer imported")
	var player: AnimationPlayer = players[0]
	print("ANIMATIONS: ", player.get_animation_list())
	var idle_names: Array[String] = []
	for clip in player.get_animation_list():
		if String(clip).begins_with("Idle"):
			idle_names.append(String(clip))
	check(idle_names.size() >= 4, "Idle, wait, and other standing clips imported")
	check(player.get_animation_list().has("IdleWait"), "Waiting clip imported")
	check(player.get_animation_list().has("IdleFoldArms"), "Fold-arms wait imported")
	check(player.get_animation_list().has("IdleLookAround"), "Look-around wait imported")
	check(player.get_animation_list().has("Walk"), "Walk clip imported")
	check(player.get_animation_list().has("Run"), "Run clip imported")
	check(not player.get_animation_list().has("Bow"), "V3 clips are not imported")
	check(not player.get_animation_list().has("Telekinesis"), "V3 clips are not imported")
	check(String(player.current_animation).begins_with("Idle"), "Idle starts automatically")
	var skeletons := actor.find_children("*", "Skeleton3D", true, false)
	check(skeletons.size() == 1, "Character skeleton imported")
	check((skeletons[0] as Skeleton3D).get_bone_count() >= 60, "Full-body Mixamo skeleton imported")
	var back: Node3D = actor.find_child("back", true, false)
	check(back != null, "Equipment attachment retained")
	var hip: Node3D = actor.find_child("hip", true, false)
	check(hip != null, "Herb hip attachment retained")
	var local := actor.to_local(back.global_position)
	print("BACK LOCAL: ", local)
	check(local.y > 0.95 and local.y < 1.35 and local.z < -0.05, "Back mount at upper back")
	var model_meshes := actor.find_children("*", "MeshInstance3D", true, false)
	var mesh: MeshInstance3D = model_meshes[0]
	var box: AABB = mesh.global_transform * mesh.get_aabb()
	print("GLOBAL AABB Y: ", box.size.y, " origin ", box.position)
	check(box.size.y > 1.55 and box.size.y < 1.85, "Model matches existing 1.7 m character scale")
	check(box.size.x > box.size.z, "Imported V4 faces +Z, not +X")
	scene._process(1.0 / 60.0)
	animator._process(1.0 / 60.0)
	var start := actor.global_position
	scene.simulation.apply({"type": "set_walk_destination", "x": 10.0, "y": 0.0, "z": 10.0})
	for i in range(35):
		scene._process(1.0 / 60.0)
		animator._process(1.0 / 60.0)
	check(actor.global_position.distance_to(start) > 0.3, "Existing walk command moves model")
	check(player.current_animation == "Walk", "Movement selects Walk")
	var toward := Vector3(10.0 - actor.global_position.x, 0.0, 10.0 - actor.global_position.z)
	var body_forward := Vector3(actor.global_transform.basis.z.x, 0.0, actor.global_transform.basis.z.z)
	check(
		toward.length() > 0.2 and body_forward.normalized().dot(toward.normalized()) > 0.7,
		"Walk faces the destination"
	)
	for i in range(400):
		scene._process(1.0 / 60.0)
		animator._process(1.0 / 60.0)
	check(String(player.current_animation).begins_with("Idle"), "Arrival blends back to Idle")
	var arrived := Vector3(actor.global_position.x, 0.0, actor.global_position.z)
	check(arrived.distance_to(Vector3(10, 0, 10)) < 0.25, "Stops within authored reach")
	check(
		absf(actor.global_position.y - scene.terrain_height(actor.global_position.x, actor.global_position.z)) < 0.08,
		"Feet follow the hex"
	)
	scene.simulation.apply({"type": "set_walk_destination", "x": -8.0, "y": 0.0, "z": -8.0, "gait": "run"})
	for i in range(12):
		scene._process(1.0 / 60.0)
		animator._process(1.0 / 60.0)
	check(player.current_animation == "Walk", "A run builds from a walk")
	for i in range(100):
		scene._process(1.0 / 60.0)
		animator._process(1.0 / 60.0)
	check(player.current_animation == "Run", "Faster displayed travel selects Run")
	scene.simulation.apply({"type": "pickup_item", "item_id": "entity.club.umber"})
	for i in range(400):
		scene.simulation.apply({"type": "tick", "ticks": 1})
		if str(scene.simulation.query_panel().get("equipment", {}).get("slot.small_weapon", {}).get("id", "")) == "entity.club.umber":
			break
	check(scene._is_orbit_press_target("entity.club.umber"), "An equipped club starts orbit")
	for _i in range(50):
		scene._sync_views(1.0 / 60.0)
		if not scene.handoff.is_active("entity.club.umber"):
			break
	var club_view: Node3D = scene.views.get("entity.club.umber") as Node3D
	var back_node: Node3D = actor.find_child("back", true, false) as Node3D if actor else null
	var to_back := INF
	if club_view and back_node:
		to_back = club_view.global_position.distance_to(back_node.global_position)
		print("CLUB TO BACK NODE: ", to_back)
	check(club_view != null and to_back < 0.28, "The sheathed club is anchored to the back node")
	if club_view and back_node:
		var before: Vector3 = club_view.global_position
		back_node.position.z -= 0.18
		scene._sync_views(0.0)
		var followed: float = club_view.global_position.distance_to(before)
		back_node.position.z += 0.18
		scene._sync_views(0.0)
		check(followed > 0.1, "The sheathed club follows the back node")
	scene.simulation.apply({"type": "open_container", "target_id": "entity.grass.1"})
	for i in range(600):
		scene.simulation.apply({"type": "tick", "ticks": 1})
		var opened := false
		for entity in scene.simulation.query_world_view().get("entities", []):
			if str(entity.get("id", "")) == "entity.grass.1":
				opened = bool(entity.get("container_opened", false))
		if opened:
			break
	scene.simulation.apply({"type": "pickup_item", "item_id": "entity.grass.bundle.1"})
	for i in range(600):
		scene.simulation.apply({"type": "tick", "ticks": 1})
		if str(scene.simulation.query_panel().get("equipment", {}).get("slot.herb", {}).get("id", "")) == "entity.grass.bundle.1":
			break
	scene._sync_views(0.05)
	check(scene._is_orbit_press_target("entity.grass.bundle.1"), "An equipped grass bundle is part of the body")
	var herb_pick: CollisionShape3D = (scene.views.get("entity.grass.bundle.1") as Node).get_node_or_null("HerbPick") if scene.views.has("entity.grass.bundle.1") else null
	check(herb_pick != null and herb_pick.disabled, "A carried bundle does not steal character clicks")
	var fountain_placed: Array[EtheraPlacedEntity] = []
	var cradle_placed: Array[EtheraPlacedEntity] = []
	if hex:
		for placed in hex.placed_entities():
			if placed.entity_id == "entity.memory_fountain":
				fountain_placed.append(placed)
			elif placed.definition_id == EtheraPlacedEntity.DEFINITION_CRADLE:
				cradle_placed.append(placed)
	check(fountain_placed.size() == 1, "Exactly one authored Memory Fountain is in the hex")
	check(scene.views.get("entity.memory_fountain") == fountain_placed[0] if not fountain_placed.is_empty() else null, "The Fountain view is the authored object")
	check(scene.authored_views.has("entity.memory_fountain"), "The Fountain is not spawned a second time from world data")
	check(cradle_placed.size() == 8, "The eight authored Echo Cradles remain in the hex")
	var shared_cradle := true
	for cradle in cradle_placed:
		if cradle.definition_id != EtheraPlacedEntity.DEFINITION_CRADLE or cradle.entity_id == "":
			shared_cradle = false
	check(shared_cradle, "Echo Cradles share the common definition and keep instance ids")
	check(scene.views.get("entity.stone_circle") is EtheraStoneCircle, "The stone circle is an authored placeable object")
	var bench_col: CollisionShape3D = hex.find_child("BenchCollision", true, false) as CollisionShape3D if hex else null
	check(bench_col != null and bench_col.shape != null, "Stone benches have collision")
	var cradle_col := false
	var cradle_fountain_kind := false
	if not cradle_placed.is_empty():
		cradle_col = cradle_placed[0].find_child("MeshCollision", true, false) != null
		cradle_fountain_kind = cradle_placed[0].get_node_or_null("CradleBasin") != null and cradle_placed[0].get_node_or_null("CradleStem") != null
	check(cradle_col, "Echo Cradles have mesh collision")
	check(cradle_fountain_kind, "Echo Cradles use Fountain-kind basin and stem collision")
	check(cradle_placed.is_empty() or cradle_placed[0].occupancy_radius() >= 0.45, "Echo Cradle occupancy follows the sculpt")
	var node_defs: Array[Dictionary] = hex.world_node_definitions() if hex else []
	check(node_defs.size() == 1 and str(node_defs[0].get("id", "")) == "node.village_001", "World Node markers are discovered from the hex")
	var village_node: EtheraWorldNodeMarker = hex.world_node_marker("node.village_001") if hex else null
	var node_visual: Node3D = village_node.get_node_or_null("Visual") as Node3D if village_node else null
	check(node_visual != null and not node_visual.visible, "World Node markers stay hidden during play")
	check(not node_defs.is_empty() and not node_defs[0].has("occupant_id"), "A World Node is a location, not an occupant")
	var edges: PackedStringArray = hex.hex_edge_connections() if hex else PackedStringArray()
	check(
		edges == PackedStringArray(["dirt", "vegetation", "grass", "dirt", "dirt", "dirt"]),
		"Hex edge connection metadata survives load"
	)
	check(scene.views.has("entity.stone_circle"), "The stone circle is in the landscape")
	var circle: Node3D = scene.views.get("entity.stone_circle") as Node3D
	check(circle != null and circle.find_child("DiscoveryAura", true, false) != null, "The stone circle has a visible discovery ring")
	check(circle != null and circle.find_child("CrystalGem", true, false) != null, "The center stone carries a crystal")
	var ring_stones := 0
	if circle:
		for child in circle.find_children("RingStone_*", "MeshInstance3D", true, false):
			ring_stones += 1
	check(ring_stones == 6, "Six hip-height stones stand in a hexagon")
	check(scene.toast_label != null, "Place discovery shows a top-of-screen toast")
	var sun: DirectionalLight3D = scene.get_node_or_null("Sun") as DirectionalLight3D
	check(sun != null and sun.shadow_enabled, "The sun casts realtime shadows")
	check(
		sun != null and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
		"Directional shadows use camera cascades"
	)
	check(sun != null and sun.directional_shadow_max_distance <= 80.0, "Shadow distance follows the camera, not the hex")
	check(circle != null and circle.find_child("DiscoveryAura", true, false) is Decal, "The discovery ring is a terrain decal")
	var landmark: Dictionary = scene.simulation.world.get_entity("entity.stone_circle")
	var discover_r: float = float(landmark.get("discovery_radius", 0.0))
	var occupy_r: float = scene.simulation.world.occupancy_radius(landmark)
	var aura_decal: Decal = circle.find_child("DiscoveryAura", true, false) as Decal if circle else null
	print("STONE CIRCLE DISCOVERY RADIUS M: ", discover_r)
	print("STONE CIRCLE OCCUPANCY RADIUS M: ", occupy_r)
	if aura_decal:
		print("STONE CIRCLE AURA SIZE: ", aura_decal.size, " local y ", aura_decal.position.y)
	check(is_equal_approx(discover_r, 10.0), "Place discovery is a 10 m horizontal disk")
	check(occupy_r >= 3.0 and occupy_r <= 3.4, "Walking occupancy is the inner stones")
	if aura_decal:
		check(is_equal_approx(aura_decal.size.y, 8.0), "The visible aura volume is 8 m tall")
		check(is_equal_approx(aura_decal.position.y, 2.4), "The aura is centred 2.4 m above the ring")
	var world_env: WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	check(
		world_env != null
		and world_env.environment != null
		and world_env.environment.background_mode == Environment.BG_SKY
		and world_env.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR,
		"The sky is visible and ground light stays authored"
	)
	var cycle: EtheraDayNight = scene.get_node_or_null("DayNight") as EtheraDayNight
	check(cycle != null and is_equal_approx(EtheraDayNight.CYCLE_SECONDS, 600.0), "A day lasts ten minutes")
	check(cycle != null and cycle.get_node_or_null("SunDisc") != null, "The sun is a visible disc")
	if cycle != null and sun != null:
		cycle.apply_phase(0.50)
		check(sun.light_energy > 1.0, "Midday is bright")
		check(sun.global_transform.basis.z.y > 0.7, "The midday sun stands high")
		check(cycle.get_node("SunDisc").visible, "The midday sun can be seen")
		cycle.apply_phase(0.24)
		check(sun.light_color.r > sun.light_color.b, "Sunrise is warm")
		cycle.apply_phase(0.74)
		check(sun.light_color.r > sun.light_color.b, "Evening is warm")
		cycle.apply_phase(0.00)
		check(sun.light_energy < 0.02, "Night has no sun from under the world")
		check(not sun.shadow_enabled, "Night does not cast sun shadows")
		var club_mesh: MeshInstance3D = _living_stone_mesh(scene.views.get("entity.club.umber") as Node)
		check(club_mesh != null, "The stone club has a living-stone material")
		if club_mesh:
			var night_mat := club_mesh.material_override as StandardMaterial3D
			check(
				night_mat != null and night_mat.emission_energy_multiplier < 0.08,
				"The stone club does not glow through the night"
			)
			cycle.apply_phase(0.50)
			cycle.apply_living_stone_glow()
			var day_mat := club_mesh.material_override as StandardMaterial3D
			check(
				day_mat != null and day_mat.emission_energy_multiplier > 0.4,
				"The stone club keeps its daylight tint"
			)
		cycle.apply_phase(EtheraDayNight.START_PHASE)
	check(scene.find_child("ShadowCatcher", true, false) == null, "Ground shadows come from the hex tiles, not a catcher")
	var fat_circle := false
	var stone_mesh_pick := 0
	if circle:
		for child in circle.get_children():
			if child is CollisionShape3D and child.shape is CylinderShape3D:
				if (child.shape as CylinderShape3D).radius >= 3.0:
					fat_circle = true
		for child in circle.get_children():
			if child is CollisionShape3D and str(child.name).begins_with("MeshCollision"):
				stone_mesh_pick += 1
	check(not fat_circle, "The stone circle has no full-ring pick cylinder")
	check(stone_mesh_pick >= 6, "Each ring stone has its own pick")
	var circle_at: Vector3 = circle.global_position if circle else Vector3(108.0, 0.0, 0.0)
	var above: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(circle_at.x, 4.2, circle_at.z), Vector3(circle_at.x, 2.6, circle_at.z)))
	var above_id := ""
	if not above.is_empty():
		var node: Node = above.get("collider") as Node
		while node != null:
			if node.has_meta("entity_id"):
				above_id = str(node.get_meta("entity_id"))
				break
			node = node.get_parent()
	check(above_id != "entity.stone_circle", "Air above the stone circle is not the circle")
	var aim: Vector3 = scene._discovery_aim_point("entity.stone_circle", landmark)
	check(absf(aim.y - (circle_at.y + 1.46)) < 0.05, "The discovery eye aims at the circle's height")
	check(
		scene._has_line_of_sight(aim + Vector3(0.0, 0.4, 0.0), aim, "entity.stone_circle"),
		"A clear look at the circle can still show the eye"
	)
	var occluder := StaticBody3D.new()
	occluder.collision_layer = 1
	var occluder_shape := CollisionShape3D.new()
	var occluder_box := BoxShape3D.new()
	occluder_box.size = Vector3(6.0, 8.0, 6.0)
	occluder_shape.shape = occluder_box
	occluder.add_child(occluder_shape)
	scene.add_child(occluder)
	occluder.global_position = aim + Vector3(-6.0, 0.0, 0.0)
	await scene.get_tree().physics_frame
	check(
		not scene._has_line_of_sight(aim + Vector3(-12.0, 0.0, 0.0), aim, "entity.stone_circle"),
		"The discovery eye does not show through terrain"
	)
	occluder.queue_free()
	var aura: Node3D = circle.find_child("DiscoveryAura", true, false) as Node3D if circle else null
	check(aura != null and aura.visible, "The discovery ring starts visible")
	scene.simulation.world.set_position("entity.khar_morr", Vector3(circle_at.x, 0.0, circle_at.z))
	scene.simulation.apply({"type": "observe_target", "target_id": "entity.stone_circle"})
	scene._sync_views(0.05)
	aura = circle.find_child("DiscoveryAura", true, false) as Node3D if circle else null
	check(aura != null and not aura.visible, "The discovery ring hides after the place is known")
	print("Character presentation validation: ", failed, " failures")
	scene.queue_free()
	await process_frame
	quit(1 if failed else 0)
