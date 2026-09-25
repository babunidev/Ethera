extends SceneTree

var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failed += 1
		push_error(message)


func _run() -> void:
	var editor_text := FileAccess.get_file_as_string("res://scenes/tools/hex_tile_editor.tscn")
	var editor_script := FileAccess.get_file_as_string("res://scripts/presentation/hex_tile_editor.gd")
	check(editor_script.contains("hex_grassland_a.tscn"), "The tile editor is a wrapper around the runtime hex")
	check(editor_text.length() < 2000 and not editor_text.contains("LowPolyTerrainManager"), "The tile editor does not embed terrain data")
	var hex_text := FileAccess.get_file_as_string("res://scenes/terrain/hex_grassland_a.tscn")
	check(hex_text.contains("hex_grassland_a_sculpt.res"), "The runtime hex stores sculpt data externally")
	check(not hex_text.contains("LowPolyTerrainChunk"), "Generated chunk meshes are not packed into the hex scene")
	check(hex_text.length() < 120000, "The authored hex scene stays small")

	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_process(false)

	check(scene.hex_stream != null, "Hex streaming is active")
	check(scene.hex_stream.loaded_count() == 1, "Only the starting hex is streamed")
	var hex: EtheraHexTile = scene.hex_stream.hex_at(0, 0) as EtheraHexTile
	check(hex != null and hex.tile_id == "hex.grassland.a", "Axial 0,0 streams hex.grassland.a")
	var manager: LowPolyTerrainManager = hex.terrain_manager() if hex else null
	check(manager != null, "The starting hex carries LowPolyTerrainManager")
	check(manager != null and is_equal_approx(manager.hex_flat_to_flat, 256.0), "The authored hex is 256 m flat-to-flat")
	check(manager != null and manager.sculpt_data != null, "Sculpt data is attached to the manager")
	check(
		manager != null and manager.get_hex_edge_connections() == PackedStringArray(["dirt", "vegetation", "grass", "dirt", "dirt", "dirt"]),
		"Edge connection metadata is available from the manager"
	)
	check(absf(scene.terrain_height(EtheraHexCoords.APOTHEM - 0.5, 0.0)) < 0.04, "The perimeter stays at height 0")

	await scene.get_tree().physics_frame
	await scene.get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
	var ground_hit: Dictionary = space.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(2.0, 8.0, 2.0), Vector3(2.0, -4.0, 2.0))
	)
	check(not ground_hit.is_empty(), "Terrain collision exists on the authored hex")
	check(scene._entity_id_from_collider(ground_hit.get("collider", null)) == "", "Terrain hits are not entities")

	var fountain_count := 0
	var cradle_count := 0
	var bench_count := 0
	if hex:
		for placed in hex.placed_entities():
			if placed.entity_id == "entity.memory_fountain":
				fountain_count += 1
			elif placed.definition_id == EtheraPlacedEntity.DEFINITION_CRADLE:
				cradle_count += 1
		for bench in hex.find_children("*", "", true, false):
			if bench is EtheraStoneBench or str(bench.name).begins_with("StoneBench"):
				if bench.get_parent() == hex:
					bench_count += 1
	check(fountain_count == 1, "Exactly one Memory Fountain is authored in the hex")
	check(scene.views.get("entity.memory_fountain") is EtheraPlacedEntity, "The Fountain view is the placed game object")
	check(scene.world_root.find_child("entity.memory_fountain", false, false) == null, "No second Fountain is spawned under World")
	check(cradle_count == 8, "All eight authored Echo Cradles are present")
	check(bench_count == 8, "Stone benches remain ordinary authored props")
	check(hex.find_child("Bush1", true, false) is EtheraBush, "Authored bushes are on the hex")
	var bush_body: EtheraBush = hex.find_child("Bush1", true, false) as EtheraBush
	var bush_col: CollisionShape3D = bush_body.get_node_or_null("BushCollision") as CollisionShape3D if bush_body else null
	check(bush_col != null and bush_col.shape != null and not bush_col.disabled, "Bushes have collision")
	var scenery: Array = hex.scenery_blockers() if hex else []
	var scenery_kinds := {"bush": 0, "bench": 0, "cradle": 0, "hall": 0, "burrow": 0}
	for blocker in scenery:
		var scenery_id := str(blocker.get("id", ""))
		if scenery_id.begins_with("scenery.bush."):
			scenery_kinds["bush"] = int(scenery_kinds["bush"]) + 1
		elif scenery_id.begins_with("scenery.bench."):
			scenery_kinds["bench"] = int(scenery_kinds["bench"]) + 1
		elif scenery_id.begins_with("scenery.cradle."):
			scenery_kinds["cradle"] = int(scenery_kinds["cradle"]) + 1
		elif scenery_id.begins_with("scenery.hall."):
			scenery_kinds["hall"] = int(scenery_kinds["hall"]) + 1
		elif scenery_id.begins_with("scenery.burrow."):
			scenery_kinds["burrow"] = int(scenery_kinds["burrow"]) + 1
	check(int(scenery_kinds["bush"]) >= 1, "Bushes occupy walking space like rocks")
	check(int(scenery_kinds["bench"]) == 8, "Benches occupy walking space like rocks")
	check(int(scenery_kinds["cradle"]) == 8, "Echo Cradles occupy walking space like the Fountain")
	check(int(scenery_kinds["hall"]) >= 8, "Town hall walls occupy walking space")
	check(int(scenery_kinds["burrow"]) >= 1, "Burrows occupy walking space like rocks")
	var adopted := {"bush": false, "bench": false, "cradle": false, "hall": false, "burrow": false}
	for blocker in scene.simulation.world.blockers_near():
		var blocker_id := str(blocker.get("id", ""))
		if blocker_id.begins_with("scenery.bush."):
			adopted["bush"] = true
		elif blocker_id.begins_with("scenery.bench."):
			adopted["bench"] = true
		elif blocker_id.begins_with("scenery.cradle."):
			adopted["cradle"] = true
		elif blocker_id.begins_with("scenery.hall."):
			adopted["hall"] = true
		elif blocker_id.begins_with("scenery.burrow."):
			adopted["burrow"] = true
	check(bool(adopted["bush"]) and bool(adopted["bench"]) and bool(adopted["cradle"]) and bool(adopted["hall"]) and bool(adopted["burrow"]), "Hex scenery is adopted as walk solids")
	check(hex.find_child("GrassClump1", true, false) is EtheraGrassClump, "Extra grass sits on the grass edge")
	check(hex.find_child("ScatterStone1", true, false) is EtheraScatterStone, "Dirt edges carry a few stones")
	var hex_grass: EtheraGrassClump = hex.find_child("GrassClump1", true, false) as EtheraGrassClump
	var hex_stone: EtheraScatterStone = hex.find_child("ScatterStone1", true, false) as EtheraScatterStone
	check(hex_grass != null and hex_grass.entity_id.begins_with("entity.grass."), "Hex grass is a harvestable patch")
	check(hex_stone != null and hex_stone.entity_id.begins_with("entity.shapeable_rock.scatter."), "Hex stones are shapeable rocks")
	if hex_grass:
		var grass_entity: Dictionary = scene.simulation.world.get_entity(hex_grass.entity_id)
		check(str(grass_entity.get("kind", "")) == EtheraIds.KIND_GRASS, "Hex grass uses the existing grass kind")
		check(
			str(scene.simulation.query_hover(EtheraIds.ENTITY_KHAR_MORR, hex_grass.entity_id).get("kind", "")) == EtheraIds.HOVER_OPEN,
			"Hex grass can be opened"
		)
		check(not hex_grass.visible, "Hex grass markers stay out of play")
		var grass_view: Node = scene.views.get(hex_grass.entity_id) as Node
		check(grass_view != null and grass_view != hex_grass, "Play uses the existing harvestable grass, not the hex marker")
		check(grass_view.get_node_or_null("ContainerPick") != null, "Hex grass has the same pick as seeded patches")
	if hex_stone:
		var rock_entity: Dictionary = scene.simulation.world.get_entity(hex_stone.entity_id)
		check(scene.simulation.world.has_trait(rock_entity, EtheraIds.TRAIT_SHAPEABLE), "Hex rocks accept Shape Weapon")
		check(scene.simulation.world.occupancy_radius(rock_entity) > 0.12, "Hex rocks occupy like seeded rocks")
		check(not hex_stone.visible, "Hex stone markers stay out of play")
		var rock_view: Node3D = scene.views.get(hex_stone.entity_id) as Node3D
		check(rock_view != null and rock_view != hex_stone, "Play uses the existing shapeable rock, not the hex marker")
		check(rock_view.find_child("MeshCollision", true, false) != null, "Play rocks have the shapeable-rock pick")
		var stone_ground: float = scene.terrain_height(rock_view.global_position.x, rock_view.global_position.z)
		var stone_box := AABB()
		var stone_first := true
		for mesh_node in rock_view.find_children("*", "MeshInstance3D", true, false):
			var mesh := mesh_node as MeshInstance3D
			if mesh.mesh == null:
				continue
			var world_box: AABB = mesh.global_transform * mesh.get_aabb()
			if stone_first:
				stone_box = world_box
				stone_first = false
			else:
				stone_box = stone_box.merge(world_box)
		check(not stone_first and stone_box.position.y < stone_ground - 0.04, "Rocks sit a little into the ground")
		check(not stone_first and stone_box.end.y > stone_ground + 0.12, "Most of the rock still stands out of the ground")
	var bush: Node3D = hex.find_child("Bush1", true, false) as Node3D
	if bush:
		check(
			absf(bush.position.y - hex.height_at_local(bush.position.x, bush.position.z)) < 0.08,
			"Bushes sit on the authored ground"
		)
	check(scene.views.get("entity.stone_circle") is EtheraStoneCircle, "The stone circle can be moved in the hex")
	var fountain_pos: Vector3 = (scene.views.get("entity.memory_fountain") as Node3D).global_position if scene.views.has("entity.memory_fountain") else Vector3.INF
	check(fountain_pos.distance_to(Vector3.ZERO) < 0.05, "The Fountain uses its authored scene transform")

	var nodes: Array[Dictionary] = hex.world_node_definitions() if hex else []
	check(nodes.size() == 1 and str(nodes[0].get("id", "")) == "node.village_001", "World Node markers are collected from the hex")
	var marker: EtheraWorldNodeMarker = hex.world_node_marker("node.village_001") if hex else null
	check(marker != null, "node.village_001 remains a location marker")
	var visual: Node3D = marker.get_node_or_null("Visual") as Node3D if marker else null
	check(visual != null and not visual.visible, "World Node gizmos are hidden in gameplay")
	var container: Dictionary = scene.simulation.world.get_entity("entity.container")
	var container_pos: Vector3 = scene.simulation.world.position_of(container)
	var marker_world: Vector3 = marker.global_position if marker else Vector3.ZERO
	check(container_pos.distance_to(Vector3(marker_world.x, 0.0, marker_world.z)) < 0.25, "The container occupies node.village_001")
	check(str(container.get("world_node_id", "")) == "node.village_001", "The occupant points at the World Node; the marker does not store the occupant")
	var actor_start: Dictionary = scene.simulation.world.get_entity("entity.khar_morr")
	var spawn: Vector3 = scene.simulation.world.position_of(actor_start)
	check(spawn.distance_to(Vector3(3.6, 0.0, 0.2)) < 0.05, "The player starts next to the Fountain")
	check(
		scene.simulation.world.has_trait(scene.simulation.world.get_entity("entity.memory_fountain"), EtheraIds.TRAIT_MEMORY_FOUNTAIN),
		"Existing Memory Fountain gameplay identity is preserved"
	)

	var actor: Node3D = scene.views.get("entity.khar_morr") as Node3D
	check(actor != null, "The player view exists on the authored hex")
	if actor:
		var start := actor.global_position
		scene.simulation.apply({"type": "set_walk_destination", "x": 6.0, "y": 0.0, "z": 4.0})
		for _i in range(40):
			scene._process(1.0 / 60.0)
		check(actor.global_position.distance_to(start) > 0.25, "The player can walk on the authored hex")
		check(
			absf(actor.global_position.y - scene.terrain_height(actor.global_position.x, actor.global_position.z)) < 0.15,
			"Feet follow the authored terrain"
		)
	if bush_body:
		for entity_id in scene.simulation.world.entities.keys():
			var id: String = str(entity_id)
			if id.begins_with("entity.grass.") or id.begins_with("entity.shapeable_rock.scatter"):
				scene.simulation.world.entities[id]["manifested"] = false
		var bush_at: Vector3 = bush_body.global_position
		var bush_r: float = bush_body.occupancy_radius()
		scene.simulation.world.set_position("entity.khar_morr", Vector3(bush_at.x + 3.0, 0.0, bush_at.z))
		scene.simulation.apply({"type": "set_walk_destination", "x": bush_at.x, "y": 0.0, "z": bush_at.z})
		for _j in range(80):
			scene.simulation.apply({"type": "tick", "ticks": 1})
			if not scene.simulation.world.walk_motor.has("entity.khar_morr"):
				break
		var stopped: Vector3 = scene.simulation.world.position_of(scene.simulation.world.get_entity("entity.khar_morr"))
		var body_r: float = float(scene.simulation.world.tuning.get("body_radius", 0.38))
		check(
			stopped.distance_to(Vector3(bush_at.x, 0.0, bush_at.z)) >= bush_r + body_r - 0.05,
			"A walk into a bush stops at its occupancy"
		)
	var burrow: EtheraBurrow = hex.find_child("Burrow", true, false) as EtheraBurrow if hex else null
	check(burrow != null, "The placed burrows are on the hex")
	if burrow:
		var burrow_at: Vector3 = burrow.global_position
		var burrow_r: float = burrow.occupancy_radius()
		scene.simulation.world.set_position("entity.khar_morr", Vector3(burrow_at.x + burrow_r + 2.4, 0.0, burrow_at.z))
		scene.simulation.apply({"type": "set_walk_destination", "x": burrow_at.x, "y": 0.0, "z": burrow_at.z})
		for _b in range(80):
			scene.simulation.apply({"type": "tick", "ticks": 1})
			if not scene.simulation.world.walk_motor.has("entity.khar_morr"):
				break
		var at_burrow: Vector3 = scene.simulation.world.position_of(scene.simulation.world.get_entity("entity.khar_morr"))
		check(
			at_burrow.distance_to(Vector3(burrow_at.x, 0.0, burrow_at.z)) >= burrow_r + float(scene.simulation.world.tuning.get("body_radius", 0.38)) - 0.05,
			"A walk into a burrow stops at its occupancy"
		)
	var hall: EtheraTownHall = hex.find_child("TownHall", true, false) as EtheraTownHall if hex else null
	check(hall != null, "The placed town hall is on the hex")
	if hall:
		var hall_mesh: MeshInstance3D = null
		for mesh_node in hall.find_children("*", "MeshInstance3D", true, false):
			if (mesh_node as MeshInstance3D).mesh != null:
				hall_mesh = mesh_node
				break
		check(
			hall_mesh != null and hall_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED,
			"The placed town hall casts interior shadows"
		)
		var inside := Vector3(hall.global_position.x, 0.0, hall.global_position.z)
		var outside: Vector3 = hall_mesh.global_transform * Vector3(0.72, 0.12, 0.0) if hall_mesh else inside + Vector3(8.0, 0.0, 0.0)
		outside.y = 0.0
		var wall_at := Vector3.INF
		for blocker in scene.simulation.world.blockers_near():
			if not str(blocker.get("id", "")).begins_with("scenery.hall."):
				continue
			wall_at = Vector3(float(blocker.get("x", 0.0)), 0.0, float(blocker.get("z", 0.0)))
			break
		check(wall_at.x != INF, "Town hall wall disks are adopted")
		check(not scene.simulation.world.is_blocked(inside, 0.2), "The town hall interior is walkable")
		var cavity: Vector3 = hall_mesh.global_transform * Vector3(0.40, 0.12, 0.30) if hall_mesh else inside
		cavity.y = 0.0
		check(scene.simulation.world.is_blocked(cavity, 0.2), "The space between the town hall walls is not a path")
		if wall_at.x != INF:
			var outward: Vector3 = wall_at - inside
			outward.y = 0.0
			if outward.length() < 0.01:
				outward = Vector3.RIGHT
			outward = outward.normalized()
			scene.simulation.world.set_position("entity.khar_morr", wall_at + outward * 2.6)
			scene.simulation.apply({"type": "set_walk_destination", "x": wall_at.x, "y": 0.0, "z": wall_at.z})
			for _k in range(80):
				scene.simulation.apply({"type": "tick", "ticks": 1})
				if not scene.simulation.world.walk_motor.has("entity.khar_morr"):
					break
			var at_wall: Vector3 = scene.simulation.world.position_of(scene.simulation.world.get_entity("entity.khar_morr"))
			check(
				at_wall.distance_to(wall_at) >= float(scene.simulation.world.tuning.get("body_radius", 0.38)) + 0.22,
				"A walk into a town hall wall stops at the wall"
			)
		scene.simulation.world.set_position("entity.khar_morr", outside)
		scene.simulation.apply({"type": "set_walk_destination", "x": inside.x, "y": 0.0, "z": inside.z})
		for _n in range(240):
			scene.simulation.apply({"type": "tick", "ticks": 1})
			if not scene.simulation.world.walk_motor.has("entity.khar_morr"):
				break
		var in_room: Vector3 = scene.simulation.world.position_of(scene.simulation.world.get_entity("entity.khar_morr"))
		check(in_room.distance_to(inside) < 1.2, "A walk through the door reaches the town hall room")
		var floor_y: float = hall.floor_height_at(inside.x, inside.z)
		var dirt_y: float = 0.0
		if manager != null and manager.has_method("get_height_at_world_coords"):
			dirt_y = manager.get_height_at_world_coords(inside.x, inside.z)
		check(not is_nan(floor_y), "The town hall has a walkable floor")
		if not is_nan(floor_y):
			check(floor_y > dirt_y + 0.05, "The town hall floor sits above the dirt")
			check(absf(scene.terrain_height(inside.x, inside.z) - floor_y) < 0.08, "Clicks in the room use the floor, not the dirt under it")
			var actor_view: Node3D = scene.views.get("entity.khar_morr") as Node3D
			if actor_view:
				scene._sync_views(0.2)
				check(
					absf(actor_view.global_position.y - floor_y) < 0.2,
					"Feet stand on the town hall floor"
				)

	print("Authored hex validation: ", failed, " failures")
	scene.queue_free()
	await process_frame
	quit(1 if failed else 0)
