extends Node3D
class_name EtheraHexTile

# One authored hex. The interior can later be replaced by a sculpted scene;
# this default grassland is a subdivided hex so Forward+ can light and shadow it.

const SUBDIV := 48

var tile_id: String = "hex.grassland.a"
var terrain: MeshInstance3D


func build_terrain() -> Mesh:
	if terrain != null and terrain.mesh != null:
		return terrain.mesh
	var mesh: ArrayMesh = _make_mesh()
	terrain = MeshInstance3D.new()
	terrain.name = "Terrain"
	terrain.mesh = mesh
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	terrain.extra_cull_margin = 24.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.47, 0.42, 0.26)
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = false
	terrain.material_override = material
	add_child(terrain)
	return mesh


func attach_host_collision(host: CollisionObject3D) -> void:
	var mesh: Mesh = build_terrain()
	var collider := CollisionShape3D.new()
	collider.name = "HexCollide_%s" % name
	collider.shape = mesh.create_trimesh_shape()
	collider.position = position
	collider.rotation = rotation
	host.add_child(collider)


func height_at_local(x: float, z: float) -> float:
	return EtheraTerrain.height_at(x, z)


func normal_at_local(x: float, z: float) -> Vector3:
	return EtheraTerrain.normal_at(x, z)


func _make_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	rings.append([Vector3.ZERO])
	for ring in range(1, SUBDIV + 1):
		var radius: float = EtheraHexCoords.SIZE * float(ring) / float(SUBDIV)
		var ring_points: Array = []
		for side in 6:
			var a: Vector2 = EtheraHexCoords.corner(side, radius)
			var b: Vector2 = EtheraHexCoords.corner(side + 1, radius)
			for step in ring:
				var t: float = float(step) / float(ring)
				ring_points.append(Vector3(lerpf(a.x, b.x, t), 0.0, lerpf(a.y, b.y, t)))
		rings.append(ring_points)
	for ring in rings:
		for i in ring.size():
			var point: Vector3 = ring[i]
			point.y = height_at_local(point.x, point.z)
			ring[i] = point
	var inner: Array = rings[0]
	var first_ring: Array = rings[1]
	for i in 6:
		_add_triangle(surface, inner[0], first_ring[i], first_ring[(i + 1) % 6])
	for ring in range(1, SUBDIV):
		var inner_ring: Array = rings[ring]
		var outer_ring: Array = rings[ring + 1]
		var inner_n: int = inner_ring.size()
		var outer_n: int = outer_ring.size()
		var inner_i := 0
		var outer_i := 0
		for side in 6:
			for _step in ring:
				var i0: Vector3 = inner_ring[inner_i % inner_n]
				var i1: Vector3 = inner_ring[(inner_i + 1) % inner_n]
				var o0: Vector3 = outer_ring[outer_i % outer_n]
				var o1: Vector3 = outer_ring[(outer_i + 1) % outer_n]
				_add_triangle(surface, i0, o0, o1)
				_add_triangle(surface, i0, o1, i1)
				inner_i += 1
				outer_i += 1
			var spoke: Vector3 = inner_ring[inner_i % inner_n]
			var extra0: Vector3 = outer_ring[outer_i % outer_n]
			var extra1: Vector3 = outer_ring[(outer_i + 1) % outer_n]
			_add_triangle(surface, spoke, extra0, extra1)
			outer_i += 1
	surface.generate_normals()
	surface.generate_tangents()
	return surface.commit()


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	_add_vertex(surface, a)
	_add_vertex(surface, b)
	_add_vertex(surface, c)


func _add_vertex(surface: SurfaceTool, point: Vector3) -> void:
	surface.set_uv(Vector2(point.x / 16.0 + 0.5, point.z / 16.0 + 0.5))
	surface.add_vertex(point)
