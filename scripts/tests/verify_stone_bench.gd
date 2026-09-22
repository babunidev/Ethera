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
	var bench := EtheraStoneBench.new()
	root.add_child(bench)
	var mesh := (bench.get_node("BenchMesh") as MeshInstance3D).mesh as ArrayMesh
	var aabb := mesh.get_aabb()
	check(is_equal_approx(aabb.size.x, 1.8), "Default block is 1.8 m long (got %s)" % aabb.size.x)
	check(is_equal_approx(aabb.size.z, 0.5), "Default block is 0.5 m deep (got %s)" % aabb.size.z)
	check(is_equal_approx(aabb.size.y, 0.45), "Default block is 0.45 m tall (got %s)" % aabb.size.y)
	check(aabb.position.y > -0.001 and aabb.position.y < 0.001, "Block sits on the ground")
	check(_front_faces_point_out(mesh), "Every face is visible from outside")
	check(bench.get_node("BenchCollision") is CollisionShape3D, "Block has collision for picking")
	bench.length = 3.2
	bench.depth = 0.8
	bench.height = 0.3
	mesh = (bench.get_node("BenchMesh") as MeshInstance3D).mesh as ArrayMesh
	aabb = mesh.get_aabb()
	check(is_equal_approx(aabb.size.x, 3.2), "Length rebuilds the block")
	check(is_equal_approx(aabb.size.z, 0.8), "Depth rebuilds the block")
	check(is_equal_approx(aabb.size.y, 0.3), "Height rebuilds the block")
	var editor: Node = load("res://scenes/tools/hex_tile_editor.tscn").instantiate()
	var placed: Node = editor.get_node_or_null("StoneBench")
	check(placed is EtheraStoneBench, "Hex tile editor contains a StoneBench")
	if placed is Node3D:
		check(placed.position.length() > 3.0, "Placed block is offset from the fountain")
	editor.free()
	bench.free()
	quit(1 if failed else 0)


func _front_faces_point_out(mesh: ArrayMesh) -> bool:
	var faces := mesh.get_faces()
	var center := mesh.get_aabb().get_center()
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var winding := (b - a).cross(c - a)
		var outward := (a + b + c) / 3.0 - center
		# Clockwise from outside: the vertex-order cross points back into the block.
		if winding.dot(outward) >= 0.0:
			return false
	return faces.size() > 0
