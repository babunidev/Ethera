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
	check(EtheraWorldNodeMarker.is_valid_id("node.001"), "node.001 is a valid id")
	check(not EtheraWorldNodeMarker.is_valid_id("entity.memory_fountain"), "Entity ids are not World Node ids")
	check(not EtheraWorldNodeMarker.is_valid_id("Node.001"), "World Node ids stay lowercase")
	_test_definitions_follow_the_hex()
	_test_save_round_trip()
	_test_duplicate_warning()
	_test_game_hides_the_gizmo()
	quit(1 if failed else 0)


func _test_definitions_follow_the_hex() -> void:
	var hex := EtheraHexTile.new()
	hex.position = Vector3(80.0, 0.0, -30.0)
	hex.rotation.y = 0.6
	root.add_child(hex)
	var folder := Node3D.new()
	folder.name = "WorldNodes"
	hex.add_child(folder)
	var later := _marker("node.010", Vector3(4.0, 0.0, 1.5), 0.3)
	var earlier := _marker("node.002", Vector3(-2.0, 0.5, 3.0), -0.4)
	folder.add_child(later)
	folder.add_child(earlier)
	later.name = "RenamedInTheSceneTree"
	var definitions := EtheraWorldNodeMarker.collect_from(hex)
	check(definitions.size() == 2, "Both markers are discovered")
	check(str(definitions[0]["id"]) == "node.002", "Discovery is sorted by id, not scene order")
	check(str(definitions[1]["id"]) == "node.010", "The renamed node keeps node.010")
	check(str(definitions[0]["tile_id"]) == "hex.grassland.a", "The hex tile id is reported beside the node id")
	var position: Vector3 = definitions[0]["position"]
	check(position.distance_to(Vector3(-2.0, 0.5, 3.0)) < 0.001, "Position stays in hex space when the hex moves")
	var rotation: Vector3 = definitions[0]["rotation"]
	check(is_equal_approx(rotation.y, -0.4), "Yaw is kept")
	hex.queue_free()


func _test_save_round_trip() -> void:
	var hex := Node3D.new()
	hex.name = "AuthoredHex"
	var folder := Node3D.new()
	folder.name = "WorldNodes"
	hex.add_child(folder)
	folder.owner = hex
	var marker := _marker("node.004", Vector3(1.25, 0.0, -6.5), 1.1)
	folder.add_child(marker)
	marker.owner = hex
	var packed := PackedScene.new()
	check(packed.pack(hex) == OK, "The authored hex packs")
	var restored: Node3D = packed.instantiate() as Node3D
	root.add_child(restored)
	restored.get_node("WorldNodes/WorldNodeMarker").name = "AfterReload"
	var definitions := EtheraWorldNodeMarker.collect_from(restored)
	check(definitions.size() == 1, "The reloaded hex still has its marker")
	check(str(definitions[0]["id"]) == "node.004", "Reload keeps the stable id")
	var position: Vector3 = definitions[0]["position"]
	check(position.distance_to(Vector3(1.25, 0.0, -6.5)) < 0.001, "Reload keeps the position")
	var rotation: Vector3 = definitions[0]["rotation"]
	check(is_equal_approx(rotation.y, 1.1), "Reload keeps the rotation")
	restored.queue_free()
	hex.free()


func _test_duplicate_warning() -> void:
	var hex := Node3D.new()
	root.add_child(hex)
	var first := _marker("node.001", Vector3.ZERO, 0.0)
	var second := _marker("node.001", Vector3(2.0, 0.0, 0.0), 0.0)
	hex.add_child(first)
	hex.add_child(second)
	var warnings := first._get_configuration_warnings()
	check(warnings.size() > 0, "A repeated id warns in the editor")
	second.node_id = "node.002"
	check(first._get_configuration_warnings().is_empty(), "Distinct ids clear the warning")
	first.node_id = "TreasureSpawn"
	check(first._get_configuration_warnings().size() > 0, "A content-type name is not a World Node id")
	hex.queue_free()


func _test_game_hides_the_gizmo() -> void:
	var marker: Node3D = load("res://scenes/tools/world_node_marker.tscn").instantiate() as Node3D
	root.add_child(marker)
	var visual := marker.get_node("Visual") as Node3D
	check(visual != null and not visual.visible, "The marker gizmo is hidden outside the editor")
	var ring := visual.get_node("Ring") as MeshInstance3D
	var bounds := ring.mesh.get_aabb()
	check(bounds.size.x > bounds.size.y and bounds.size.z > bounds.size.y, "The ring lies flat on the ground")
	marker.queue_free()


func _marker(id: String, at: Vector3, yaw: float) -> EtheraWorldNodeMarker:
	var marker := EtheraWorldNodeMarker.new()
	marker.name = "WorldNodeMarker"
	marker.node_id = id
	marker.position = at
	marker.rotation = Vector3(0.0, yaw, 0.0)
	return marker
