@tool
extends Node3D
class_name EtheraHexTile

# One authored hex. When a LowPolyTerrainManager is present, that sculpt is the
# ground. The generated grassland mesh is only a fallback for empty tiles.

const SUBDIV := 48

var tile_id: String = "hex.grassland.a"
var terrain: MeshInstance3D
var _walk_floors: Array[EtheraTownHall] = []


func _ready() -> void:
	if not Engine.is_editor_hint():
		_hide_landscape_markers()
	call_deferred("seat_scenery")
	call_deferred("_collect_walk_floors")


func _hide_landscape_markers() -> void:
	for child in get_children():
		if child is EtheraGrassClump or child is EtheraScatterStone:
			(child as Node3D).visible = false
			if child is CollisionObject3D:
				(child as CollisionObject3D).collision_layer = 0
				(child as CollisionObject3D).collision_mask = 0


func terrain_manager() -> LowPolyTerrainManager:
	return find_child("LowPolyTerrainManager", true, false) as LowPolyTerrainManager


func build_terrain() -> Mesh:
	if terrain_manager() != null:
		return null
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
	var manager: LowPolyTerrainManager = terrain_manager()
	if manager != null:
		manager.enable_collision_culling = false
		if manager.has_method("_bake_live_collisions_as_child"):
			manager.call("_bake_live_collisions_as_child")
		seat_scenery()
		return
	var mesh: Mesh = build_terrain()
	if mesh == null:
		return
	var collider := CollisionShape3D.new()
	collider.name = "HexCollide_%s" % name
	collider.shape = mesh.create_trimesh_shape()
	collider.position = position
	collider.rotation = rotation
	host.add_child(collider)


func _collect_walk_floors() -> void:
	_walk_floors.clear()
	for child in find_children("*", "", true, false):
		if child is EtheraTownHall:
			_walk_floors.append(child)


func walk_floor_height(x: float, z: float) -> float:
	if _walk_floors.is_empty():
		_collect_walk_floors()
	var best := NAN
	for hall in _walk_floors:
		if not is_instance_valid(hall):
			continue
		var floor_y: float = hall.floor_height_at(x, z)
		if is_nan(floor_y):
			continue
		if is_nan(best) or floor_y > best:
			best = floor_y
	return best


func height_at_local(x: float, z: float) -> float:
	var manager: LowPolyTerrainManager = terrain_manager()
	if manager != null:
		if manager.has_method("get_height_at_world_coords"):
			var world_y: float = manager.get_height_at_world_coords(global_position.x + x, global_position.z + z)
			return world_y - global_position.y
		return 0.0
	return EtheraTerrain.height_at(x, z)


func normal_at_local(x: float, z: float) -> Vector3:
	var sample := 0.4
	var dx: float = height_at_local(x + sample, z) - height_at_local(x - sample, z)
	var dz: float = height_at_local(x, z + sample) - height_at_local(x, z - sample)
	return Vector3(-dx, sample * 2.0, -dz).normalized()


func scenery_blockers() -> Array:
	var found: Array = []
	_gather_scenery_blockers(self, found)
	return found


func _gather_scenery_blockers(node: Node, found: Array) -> void:
	if node is EtheraTownHall:
		var disks: Array = (node as EtheraTownHall).occupancy_blockers()
		for i in disks.size():
			var disk: Dictionary = disks[i]
			found.append({
				"id": "scenery.hall.%s.%d" % [node.name, i],
				"x": float(disk.get("x", 0.0)),
				"z": float(disk.get("z", 0.0)),
				"radius": float(disk.get("radius", 0.0)),
			})
		for child in node.get_children():
			_gather_scenery_blockers(child, found)
		return
	if node is EtheraBurrow:
		_append_scenery_disk(found, "burrow", node, (node as EtheraBurrow).occupancy_radius())
		return
	if node is EtheraBush:
		_append_scenery_disk(found, "bush", node, (node as EtheraBush).occupancy_radius())
	elif node is EtheraStoneBench:
		_append_scenery_disk(found, "bench", node, (node as EtheraStoneBench).occupancy_radius())
	elif node is EtheraPlacedEntity:
		var placed := node as EtheraPlacedEntity
		if placed.definition_id == EtheraPlacedEntity.DEFINITION_CRADLE:
			_append_scenery_disk(found, "cradle", placed, placed.occupancy_radius())
	for child in node.get_children():
		_gather_scenery_blockers(child, found)


func _append_scenery_disk(found: Array, kind: String, node: Node3D, radius: float) -> void:
	if radius <= 0.0:
		return
	found.append({
		"id": "scenery.%s.%s" % [kind, node.name],
		"x": node.global_position.x,
		"z": node.global_position.z,
		"radius": radius,
	})


func seat_scenery() -> void:
	for child in get_children():
		if not (child is Node3D):
			continue
		if not (child is EtheraBush or child is EtheraGrassClump or child is EtheraScatterStone):
			continue
		var node := child as Node3D
		node.position.y = height_at_local(node.position.x, node.position.z)


func hex_edge_connections() -> PackedStringArray:
	var manager: LowPolyTerrainManager = terrain_manager()
	if manager != null and manager.has_method("get_hex_edge_connections"):
		return manager.get_hex_edge_connections()
	return PackedStringArray(["grassland", "grassland", "grassland", "grassland", "grassland", "grassland"])


func landscape_placements() -> Array:
	var found: Array = []
	for child in get_children():
		if not (child is Node3D):
			continue
		var entity_id := ""
		var radius := -1.0
		if child is EtheraGrassClump:
			entity_id = (child as EtheraGrassClump).entity_id
		elif child is EtheraScatterStone:
			entity_id = (child as EtheraScatterStone).entity_id
			radius = (child as EtheraScatterStone).occupancy_radius()
		else:
			continue
		if entity_id == "":
			continue
		var node := child as Node3D
		var entry := {
			"entity_id": entity_id,
			"x": node.global_position.x,
			"z": node.global_position.z,
			"yaw": node.rotation.y,
		}
		if radius >= 0.0:
			entry["radius"] = radius
		found.append(entry)
	return found


func placed_entities() -> Array[EtheraPlacedEntity]:
	var found: Array[EtheraPlacedEntity] = []
	_gather_placed(self, found)
	return found


func world_node_definitions() -> Array[Dictionary]:
	return EtheraWorldNodeMarker.collect_from(self)


func world_node_marker(node_id: String) -> EtheraWorldNodeMarker:
	for marker in _world_node_markers():
		if marker.node_id == node_id:
			return marker
	return null


func _world_node_markers() -> Array[EtheraWorldNodeMarker]:
	var found: Array[EtheraWorldNodeMarker] = []
	EtheraWorldNodeMarker._gather(self, found)
	return found


func _gather_placed(node: Node, into: Array[EtheraPlacedEntity]) -> void:
	if node is EtheraPlacedEntity:
		into.append(node)
	for child in node.get_children():
		_gather_placed(child, into)


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
