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
	_test_edge_order()
	await _test_manager_stores_connections()
	quit(1 if failed else 0)


func _test_edge_order() -> void:
	check(LowPolyTerrainHex.opposite_edge(0) == 3, "East is opposite west")
	check(LowPolyTerrainHex.opposite_edge(1) == 4, "Northeast is opposite southwest")
	check(LowPolyTerrainHex.opposite_edge(2) == 5, "Northwest is opposite southeast")
	check(LowPolyTerrainHex.opposite_edge(5) == 2, "Opposite is symmetric")
	var flat := 256.0
	var east := LowPolyTerrainHex.edge_midpoint(0, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
	check(is_equal_approx(east.x, 128.0) and is_equal_approx(east.y, 0.0), "Pointy edge 0 sits on the east flat")
	var northeast := LowPolyTerrainHex.edge_midpoint(1, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
	check(northeast.x > 0.0 and northeast.y < 0.0, "The next edge is the northeast flat")
	var west := LowPolyTerrainHex.edge_midpoint(3, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
	check(west.distance_to(-east) < 0.001, "The opposite midpoint mirrors across the centre")
	for index in 6:
		var ends := LowPolyTerrainHex.edge_endpoints(index, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
		var middle := (ends[0] + ends[1]) * 0.5
		var marked := LowPolyTerrainHex.edge_midpoint(index, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
		check(middle.distance_to(marked) < 0.001, "Handle %d is the edge midpoint, not a corner" % index)
	var flat_top := LowPolyTerrainHex.edge_midpoint(0, flat, LowPolyTerrainHex.Orientation.FLAT_TOP)
	check(is_equal_approx(flat_top.length(), 128.0), "Flat-top edge 0 is still a flat midpoint")
	var compass := ["East", "Northeast", "Northwest", "West", "Southwest", "Southeast"]
	for index in 6:
		check(
			LowPolyTerrainHex.edge_compass_label(index, LowPolyTerrainHex.Orientation.POINTY_TOP) == compass[index],
			"Pointy edge %d is labeled %s" % [index, compass[index]]
		)
	check(LowPolyTerrainHex.connections_match("grass", "grass"), "Matching connections compare equal")
	check(not LowPolyTerrainHex.connections_match("grass", "stone"), "Different connections do not match")
	var handle_radius := LowPolyTerrainHex.edge_handle_radius(flat)
	check(handle_radius * 2.0 >= 2.0 and handle_radius * 2.0 <= 3.0, "A 256 m hex handle is 2–3 m across")
	check(LowPolyTerrainHex.edge_band_width(flat) <= 0.65, "The coloured strip is a thin band")
	for index in 6:
		var center := LowPolyTerrainHex.edge_handle_center(index, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
		check(
			LowPolyTerrainHex.sphere_clears_hex(center, handle_radius, flat, LowPolyTerrainHex.Orientation.POINTY_TOP),
			"Handle %d stays outside the hex" % index
		)
		var outward := LowPolyTerrainHex.edge_outward(index, LowPolyTerrainHex.Orientation.POINTY_TOP)
		var limit := LowPolyTerrainHex.apothem(flat)
		var corners := LowPolyTerrainHex.edge_band_corners(index, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
		for corner in corners:
			var outside: float = Vector2(corner.x, corner.z).dot(outward) - limit
			check(outside >= LowPolyTerrainHex.edge_outside_gap() - 0.001, "Band vertex on edge %d is outside the flat" % index)
	var label_shift := LowPolyTerrainHex.edge_label_local_position(0, flat, LowPolyTerrainHex.Orientation.POINTY_TOP)
	check(label_shift.x > 0.0, "The east label sits further outside the handle")


func _test_manager_stores_connections() -> void:
	var manager := LowPolyTerrainManager.new()
	manager.hex_flat_to_flat = 48.0
	manager.terrain_shape = LowPolyTerrainManager.TerrainShape.HEXAGON
	root.add_child(manager)
	var paint_before: PackedByteArray = manager.global_paint_data.duplicate()
	manager.set_hex_edge_type(1, LowPolyTerrainHex.EdgeType.STONE)
	manager.set_hex_edge_type(4, LowPolyTerrainHex.EdgeType.DIRT)
	check(manager.global_paint_data == paint_before, "Assigning an edge does not repaint the terrain")
	var connections := manager.get_hex_edge_connections()
	check(connections[0] == "grass" and connections[1] == "stone" and connections[4] == "dirt", "Connections stay in edge order")
	var camera := Camera3D.new()
	var east_center := LowPolyTerrainHex.edge_handle_center(0, 48.0, manager.hex_orientation)
	root.add_child(camera)
	camera.current = true
	camera.look_at_from_position(east_center + Vector3(6.0, 24.0, 8.0), east_center, Vector3.UP)
	await process_frame
	var screen := camera.unproject_position(east_center)
	check(manager.hex_edge_handle_index_at(camera, screen) == 0, "A click on the east handle selects that edge")
	var centre_screen := camera.unproject_position(Vector3(0.0, east_center.y, 0.0))
	check(manager.hex_edge_handle_index_at(camera, centre_screen) == -1, "The middle of the hex is not an edge handle")
	manager.owner = null
	var packed := PackedScene.new()
	check(packed.pack(manager) == OK, "The terrain packs with its edge metadata")
	var restored: LowPolyTerrainManager = packed.instantiate() as LowPolyTerrainManager
	root.add_child(restored)
	check(restored.get_hex_edge_type(1) == LowPolyTerrainHex.EdgeType.STONE, "Reloading keeps the stone edge")
	check(restored.get_hex_edge_type(4) == LowPolyTerrainHex.EdgeType.DIRT, "Reloading keeps the dirt edge")
	check(restored.get_hex_edge_connections()[2] == "grass", "An unassigned edge stays grass")
	restored.free()
	camera.free()
	manager.free()
