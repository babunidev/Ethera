extends SceneTree

var failed := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failed += 1
		push_error(message)


func run() -> void:
	_test_hex_measures()
	_test_clip_forces_perimeter_height()
	_test_rectangle_brush_is_unchanged()
	await _test_hex_tile()
	quit(1 if failed else 0)


func _test_hex_measures() -> void:
	var flat := 256.0
	check(is_equal_approx(LowPolyTerrainHex.apothem(flat), 128.0), "Apothem of a 256 m hex is 128 m")
	var corner: float = LowPolyTerrainHex.corner_to_corner(flat)
	check(absf(corner - 295.603) < 0.01, "Corner-to-corner is about 295.603 m (got %s)" % corner)
	check(
		LowPolyTerrainHex.contains(0.0, 0.0, flat, LowPolyTerrainHex.Orientation.POINTY_TOP),
		"Pointy-top hex contains its centre"
	)
	check(
		LowPolyTerrainHex.contains(127.0, 0.0, flat, LowPolyTerrainHex.Orientation.POINTY_TOP),
		"Pointy-top hex contains a point just inside the east flat"
	)
	check(
		not LowPolyTerrainHex.contains(129.0, 0.0, flat, LowPolyTerrainHex.Orientation.POINTY_TOP),
		"Pointy-top hex excludes a point just outside the east flat"
	)
	check(
		not LowPolyTerrainHex.is_editable(128.0, 0.0, flat, LowPolyTerrainHex.Orientation.POINTY_TOP),
		"The exact perimeter cannot be sculpted"
	)
	check(
		LowPolyTerrainHex.contains(0.0, 127.0, flat, LowPolyTerrainHex.Orientation.FLAT_TOP),
		"Flat-top hex contains a point just inside the north flat"
	)
	check(
		not LowPolyTerrainHex.contains(0.0, 129.0, flat, LowPolyTerrainHex.Orientation.FLAT_TOP),
		"Flat-top hex excludes a point just outside the north flat"
	)


func _test_clip_forces_perimeter_height() -> void:
	var flat := 8.0
	var limit: float = LowPolyTerrainHex.apothem(flat)
	var clipped: Array = LowPolyTerrainHex.clip_triangle(
		Vector3(limit - 1.0, 5.0, 0.0),
		Vector3(limit + 2.0, 4.0, 1.0),
		Vector3(limit + 2.0, 4.0, -1.0),
		Color(1, 0, 0, 0), Color(0, 1, 0, 0), Color(0, 0, 1, 0),
		Vector3.ZERO, flat, LowPolyTerrainHex.Orientation.POINTY_TOP
	)
	check(not clipped.is_empty(), "A triangle crossing the east flat produces clipped geometry")
	var saw_boundary := false
	var saw_interior := false
	for tri in clipped:
		for vertex in tri:
			var point: LowPolyTerrainHex.ClipVertex = vertex
			var clearance: float = LowPolyTerrainHex.clearance(
				point.position.x, point.position.z, flat, LowPolyTerrainHex.Orientation.POINTY_TOP
			)
			check(clearance >= -0.001, "Clipped vertex stays inside the hex")
			if clearance <= 0.001:
				saw_boundary = true
				check(is_zero_approx(point.position.y), "Intersection vertex on the hex edge is Y 0")
			elif point.position.y > 1.0:
				saw_interior = true
	check(saw_boundary, "Clipping created a vertex on the hex edge")
	check(saw_interior, "The interior vertex kept its sculpted height")


func _test_rectangle_brush_is_unchanged() -> void:
	var manager := LowPolyTerrainManager.new()
	manager.preview_world_chunks = Vector2i(2, 2)
	manager.preview_chunk_size = 10
	manager.preview_cell_size = 1.0
	manager.jitter_strength = 0.0
	root.add_child(manager)
	manager.step_height = 0.5
	manager.brush_strength = 1.0
	manager.brush_radius = 1
	manager.brush_falloff_strength = 0.0
	manager.tool_mode = LowPolyTerrainManager.BrushMode.RAISE
	manager.interact_at_world_position(Vector3(2.0, 0.0, -2.0), false)
	check(
		is_equal_approx(manager.get_height_at(2, 2), 0.5),
		"Rectangle raise still writes the grid cell under the brush"
	)
	check(
		manager.chunk_local_position(Vector2i.ZERO).is_equal_approx(Vector3.ZERO),
		"Rectangle chunks still start at the manager origin"
	)
	check(manager.terrain_shape == LowPolyTerrainManager.TerrainShape.RECTANGLE, "Default shape stays rectangle")
	manager.free()


func _test_hex_tile() -> void:
	var manager := LowPolyTerrainManager.new()
	manager.preview_chunk_size = 8
	manager.preview_cell_size = 1.0
	manager.hex_flat_to_flat = 48.0
	manager.hex_orientation = LowPolyTerrainHex.Orientation.POINTY_TOP
	manager.terrain_shape = LowPolyTerrainManager.TerrainShape.HEXAGON
	manager.jitter_strength = 0.0
	root.add_child(manager)
	await process_frame

	var flat: float = manager.hex_flat_to_flat
	var orientation: int = manager.hex_orientation
	check(manager.world_chunks.x > 0 and manager.world_chunks.y > 0, "Hex mode sized a backing grid")
	check(
		is_equal_approx(manager.hex_boundary_height, 0.0),
		"Boundary height is reported as 0"
	)
	check(
		absf(manager.hex_corner_to_corner - LowPolyTerrainHex.corner_to_corner(flat)) < 0.001,
		"Inspector corner-to-corner matches the flat-to-flat size"
	)

	var samples := _collect_vertices(manager)
	check(samples.size() > 30, "Hex terrain produced a mesh (%d vertices)" % samples.size())
	var outside := 0
	var boundary := 0
	var raised_boundary := 0
	for point in samples:
		var clearance: float = LowPolyTerrainHex.clearance(point.x, point.z, flat, orientation)
		if clearance < -0.001:
			outside += 1
		if clearance <= 0.002:
			boundary += 1
			if absf(point.y) > 0.0001:
				raised_boundary += 1
	check(outside == 0, "No rendered vertex lies outside the hex (%d outside)" % outside)
	check(boundary >= 6, "The perimeter has vertices (%d)" % boundary)
	check(raised_boundary == 0, "Every perimeter vertex is Y 0 (%d raised)" % raised_boundary)
	check(_edges_are_straight(samples, flat, orientation), "All six edges are straight spans of the hex")

	var centre_height_before: float = manager.get_height_at_world_position(Vector3.ZERO)
	manager.step_height = 1.0
	manager.brush_strength = 1.0
	manager.brush_radius = 1
	manager.brush_falloff_strength = 0.0
	manager.tool_mode = LowPolyTerrainManager.BrushMode.RAISE
	manager.interact_at_world_position(Vector3.ZERO, false)
	check(
		manager.get_height_at_world_position(Vector3.ZERO) > centre_height_before + 0.5,
		"Raise works at the centre of the hex"
	)

	manager.brush_radius = 30
	var edge := Vector3(LowPolyTerrainHex.apothem(flat) - 1.5, 0.0, 0.0)
	manager.interact_at_world_position(edge, false)
	var outside_grid := _outside_sample_height(manager)
	check(is_zero_approx(outside_grid), "A brush overlapping the edge leaves outside samples at 0")

	var after := _collect_vertices(manager)
	var moved_perimeter := 0
	for point in after:
		var clearance: float = LowPolyTerrainHex.clearance(point.x, point.z, flat, orientation)
		if clearance <= 0.002 and absf(point.y) > 0.0001:
			moved_perimeter += 1
	check(moved_perimeter == 0, "Sculpting near the edge cannot lift the perimeter")
	check(_collision_matches_render(manager, flat, orientation), "Collision faces stay inside the same hex")
	check(_seams_match(manager), "Adjacent chunks agree on their shared vertices")
	check(
		manager.is_inside_terrain(0.0, 0.0),
		"The hex centre counts as inside the terrain"
	)
	check(
		not manager.is_inside_terrain(flat, flat),
		"A point far outside the hex is not inside the terrain"
	)

	manager.hex_orientation = LowPolyTerrainHex.Orientation.FLAT_TOP
	await process_frame
	var flat_top := _collect_vertices(manager)
	check(
		_edges_are_straight(flat_top, manager.hex_flat_to_flat, manager.hex_orientation),
		"Flat-top orientation also produces six straight edges"
	)
	manager.hex_orientation = LowPolyTerrainHex.Orientation.POINTY_TOP
	manager.jitter_strength = 0.5
	manager.rebuild_chunks_structure()
	var jittered := _collect_vertices(manager)
	var jitter_outside := 0
	var jitter_raised := 0
	for point in jittered:
		var clearance: float = LowPolyTerrainHex.clearance(
			point.x, point.z, manager.hex_flat_to_flat, manager.hex_orientation
		)
		if clearance < -0.001:
			jitter_outside += 1
		if clearance <= 0.002 and absf(point.y) > 0.0001:
			jitter_raised += 1
	check(jitter_outside == 0, "Jitter does not push vertices outside the hex")
	check(jitter_raised == 0, "Jitter does not lift the perimeter off Y 0")
	manager.free()

	var editor: Node = load("res://scenes/tools/hex_tile_editor.tscn").instantiate()
	root.add_child(editor)
	await process_frame
	var authored: LowPolyTerrainManager = editor.get_node("LowPolyTerrainManager")
	check(authored.terrain_shape == LowPolyTerrainManager.TerrainShape.HEXAGON, "Tile editor opens in hex mode")
	check(is_equal_approx(authored.hex_flat_to_flat, 256.0), "Tile editor hex is 256 m flat-to-flat")
	check(
		authored.hex_orientation == LowPolyTerrainHex.Orientation.POINTY_TOP,
		"Tile editor hex is pointy-top"
	)
	check(
		authored.chunk_local_position(Vector2i.ZERO).x < -1.0,
		"The backing grid is centred on the manager, not parked at a corner"
	)
	var tile := _collect_vertices(authored)
	var tile_outside := 0
	var tile_edges_ok := _edges_are_straight(tile, 256.0, LowPolyTerrainHex.Orientation.POINTY_TOP)
	for point in tile:
		if LowPolyTerrainHex.clearance(point.x, point.z, 256.0, LowPolyTerrainHex.Orientation.POINTY_TOP) < -0.001:
			tile_outside += 1
	check(tile.size() > 100, "The 256 m tile has a mesh (%d vertices)" % tile.size())
	check(tile_outside == 0, "The 256 m tile stays inside its hex")
	check(tile_edges_ok, "The 256 m tile has six straight edges")
	editor.free()


func _collect_vertices(manager: LowPolyTerrainManager) -> PackedVector3Array:
	var found := PackedVector3Array()
	for coord in manager.get_chunk_coords():
		var mesh: ArrayMesh = manager.get_chunk_mesh(coord)
		if mesh == null:
			continue
		var origin: Vector3 = manager.get_chunk_local_position(coord)
		var soup: PackedVector3Array = LowPolyTerrainMeshBuilder.build_face_soup(mesh)
		for vertex in soup:
			found.append(origin + vertex)
	return found


func _edges_are_straight(points: PackedVector3Array, flat: float, orientation: int) -> bool:
	var edge_length: float = LowPolyTerrainHex.circumradius(flat)
	var occupied := 0
	for plane in 6:
		var normal: Vector2 = LowPolyTerrainHex.plane_normal(plane, orientation)
		var tangent := Vector2(-normal.y, normal.x)
		var low := INF
		var high := -INF
		var count := 0
		for point in points:
			var clearance: float = LowPolyTerrainHex.clearance(point.x, point.z, flat, orientation)
			var signed: float = point.x * normal.x + point.z * normal.y - LowPolyTerrainHex.apothem(flat)
			if clearance > 0.05 or absf(signed) > 0.02:
				continue
			var along: float = point.x * tangent.x + point.z * tangent.y
			low = minf(low, along)
			high = maxf(high, along)
			count += 1
		if count >= 2 and high - low > edge_length * 0.35:
			occupied += 1
	return occupied == 6


func _outside_sample_height(manager: LowPolyTerrainManager) -> float:
	var worst := 0.0
	for z in range(manager._total_vertices_z):
		for x in range(manager._total_vertices_x):
			if manager.hex_sample_is_editable(x, z):
				continue
			worst = maxf(worst, absf(manager.get_height_at(x, z)))
	return worst


func _collision_matches_render(manager: LowPolyTerrainManager, flat: float, orientation: int) -> bool:
	for coord in manager.get_chunk_coords():
		var mesh: ArrayMesh = manager.get_chunk_mesh(coord)
		if mesh == null:
			continue
		var origin: Vector3 = manager.get_chunk_local_position(coord)
		var soup: PackedVector3Array = LowPolyTerrainMeshBuilder.build_face_soup(mesh)
		if soup.is_empty():
			return false
		for vertex in soup:
			var world: Vector3 = origin + vertex
			if LowPolyTerrainHex.clearance(world.x, world.z, flat, orientation) < -0.001:
				return false
	return true


func _seams_match(manager: LowPolyTerrainManager) -> bool:
	var coords: Array = manager.get_chunk_coords()
	var present := {}
	for coord in coords:
		present[coord] = true
	for coord in coords:
		var east := Vector2i(coord.x + 1, coord.y)
		if present.has(east) and not _shared_edge_matches(manager, coord, east):
			return false
		var south := Vector2i(coord.x, coord.y + 1)
		if present.has(south) and not _shared_edge_matches(manager, coord, south):
			return false
	return true


func _shared_edge_matches(manager: LowPolyTerrainManager, a: Vector2i, b: Vector2i) -> bool:
	var keys_a := _seam_keys(manager, a, b)
	var keys_b := _seam_keys(manager, b, a)
	if keys_a.is_empty() or keys_b.is_empty():
		return true
	for key in keys_a:
		if not keys_b.has(key):
			return false
	return true


func _seam_keys(manager: LowPolyTerrainManager, owner: Vector2i, neighbor: Vector2i) -> Dictionary:
	var mesh: ArrayMesh = manager.get_chunk_mesh(owner)
	var keys := {}
	if mesh == null:
		return keys
	var origin: Vector3 = manager.get_chunk_local_position(owner)
	var neighbor_origin: Vector3 = manager.get_chunk_local_position(neighbor)
	var seam_x: bool = neighbor.x != owner.x
	var seam: float = neighbor_origin.x if seam_x else neighbor_origin.z
	var soup: PackedVector3Array = LowPolyTerrainMeshBuilder.build_face_soup(mesh)
	for vertex in soup:
		var world: Vector3 = origin + vertex
		var on_seam: bool = absf((world.x if seam_x else world.z) - seam) <= 0.001
		if not on_seam:
			continue
		var key := Vector3i(
			roundi(world.x * 1000.0),
			roundi(world.y * 1000.0),
			roundi(world.z * 1000.0)
		)
		keys[key] = true
	return keys
