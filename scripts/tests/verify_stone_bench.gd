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
	var bench := (load("res://scenes/props/stone_bench.tscn") as PackedScene).instantiate() as EtheraStoneBench
	root.add_child(bench)
	var mesh_node := _find_mesh(bench)
	var size := mesh_node.mesh.get_aabb().size * mesh_node.global_basis.get_scale()
	check(size.x > 1.6 and size.x < 2.0, "Imported bench is about 1.8 m long (got %s)" % size.x)
	check(size.y > 0.4 and size.y < 0.7, "Imported bench is about half a metre tall (got %s)" % size.y)
	var bottom := mesh_node.global_position.y + mesh_node.mesh.get_aabb().position.y * mesh_node.global_basis.get_scale().y
	check(absf(bottom) < 0.02, "Imported bench sits on the ground")
	var collision := bench.find_child("BenchCollision", true, false) as CollisionShape3D
	check(collision != null and collision.shape != null, "Imported bench has collision")
	var hex: Node = load("res://scenes/terrain/hex_grassland_a.tscn").instantiate()
	root.add_child(hex)
	var placed: Node = hex.find_child("StoneBench", false, false)
	check(placed is EtheraStoneBench, "The authored hex contains a StoneBench")
	if placed is Node3D:
		check(placed.position.length() > 3.0, "Placed bench is offset from the fountain")
	var hall := (load("res://scenes/props/town_hall.tscn") as PackedScene).instantiate() as EtheraTownHall
	root.add_child(hall)
	var hall_mesh := _find_mesh(hall)
	var hall_size := hall_mesh.mesh.get_aabb().size * hall_mesh.global_basis.get_scale()
	check(hall_size.x > 6.0 and hall_size.y > 5.0, "Town hall is building-sized (got %s)" % hall_size)
	var hall_collision := hall.find_child("MeshCollision", true, false) as CollisionShape3D
	check(hall_collision != null and hall_collision.shape != null, "Town hall has collision")
	check(hall_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED, "Town hall walls cast interior shadows")
	var hall_mat := hall_mesh.get_active_material(0) as StandardMaterial3D
	check(hall_mat != null and hall_mat.cull_mode == BaseMaterial3D.CULL_DISABLED, "Town hall interior faces stay visible")
	check(hall.get_script() != bench.get_script(), "Town hall is not a bench")
	var disks: Array = hall.occupancy_blockers()
	check(disks.size() >= 8, "Town hall walls occupy walking space")
	var room := Vector3.ZERO
	var wall := Vector3.INF
	var door := hall_mesh.global_transform * Vector3(0.62, 0.12, 0.0)
	for disk in disks:
		var at := Vector3(float(disk.get("x", 0.0)), 0.0, float(disk.get("z", 0.0)))
		var radius: float = float(disk.get("radius", 0.0))
		if at.distance_to(room) < radius:
			room = Vector3.INF
		if wall.x == INF:
			wall = at
	check(room.x != INF, "The town hall room is walkable")
	check(wall.x != INF, "A town hall wall disk exists")
	var door_blocked := false
	for disk in disks:
		var at := Vector3(float(disk.get("x", 0.0)), 0.0, float(disk.get("z", 0.0)))
		if at.distance_to(Vector3(door.x, 0.0, door.z)) < float(disk.get("radius", 0.0)) + 0.2:
			door_blocked = true
			break
	check(not door_blocked, "The town hall door stays open")
	var cavity: Vector3 = hall_mesh.global_transform * Vector3(0.40, 0.12, 0.30)
	var cavity_blocked := false
	for disk in disks:
		var at := Vector3(float(disk.get("x", 0.0)), 0.0, float(disk.get("z", 0.0)))
		if at.distance_to(Vector3(cavity.x, 0.0, cavity.z)) < float(disk.get("radius", 0.0)) + 0.18:
			cavity_blocked = true
			break
	check(cavity_blocked, "The space between town hall walls is not a path")
	var floor_y: float = hall.floor_height_at(0.0, 0.0)
	check(not is_nan(floor_y) and floor_y > -0.02, "The town hall has a walkable floor")
	var burrow := (load("res://scenes/props/burrow.tscn") as PackedScene).instantiate() as EtheraBurrow
	root.add_child(burrow)
	var burrow_mesh := _find_mesh(burrow)
	var burrow_size := burrow_mesh.mesh.get_aabb().size * burrow_mesh.global_basis.get_scale()
	check(burrow_size.x > 2.5 and burrow_size.y > 1.6 and burrow_size.y < 2.4, "Burrow is den-sized (got %s)" % burrow_size)
	var burrow_collision := burrow.find_child("MeshCollision", true, false) as CollisionShape3D
	check(burrow_collision != null and burrow_collision.shape != null, "Burrow has collision")
	check(burrow.occupancy_radius() > 0.8, "Burrow occupies walking space")
	var burrow_mat := burrow_mesh.get_active_material(0) as StandardMaterial3D
	check(burrow_mat != null and burrow_mat.cull_mode == BaseMaterial3D.CULL_DISABLED, "Burrow interior faces stay visible")
	hex.free()
	bench.free()
	hall.free()
	burrow.free()
	quit(1 if failed else 0)


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null:
			return found
	return null
