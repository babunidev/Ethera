@tool
extends "res://scripts/presentation/static_prop.gd"
class_name EtheraTownHall

## A placed building. Walls occupy walking space; the door and room do not.
## Not a simulation entity and not an interaction.

const WALK_HEIGHT := 0.9
const CELL := 0.40
const DISK := 0.27
const TIGHT := 1.05
const MIN_PASSAGE := 2.15
const CORRIDOR := 4.0
const FLOOR_DOT := 0.64
const FLOOR_PROBE := 2.4
const FLOOR_MAX := 1.35

var _blockers_cache: Array = []
var _blockers_xform := Transform3D()
var _floor_tris: PackedVector3Array = PackedVector3Array()
var _floor_box := AABB()
var _floor_xform := Transform3D()
var _floor_ready := false


func _ready() -> void:
	super._ready()
	set_meta("entity_id", EtheraIds.ENTITY_TOWN_HALL)
	_prepare_interior()


func occupancy_blockers() -> Array:
	var mesh_node := _first_mesh()
	var xform: Transform3D = Transform3D.IDENTITY
	if mesh_node != null and mesh_node.is_inside_tree():
		xform = mesh_node.global_transform
	elif mesh_node != null:
		xform = mesh_node.transform
	if not _blockers_cache.is_empty() and xform.is_equal_approx(_blockers_xform):
		return _blockers_cache
	var found: Array = []
	if mesh_node == null or mesh_node.mesh == null:
		return found
	var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if verts.is_empty() or indices.is_empty():
		return found
	var walk_y: float = (global_position.y if is_inside_tree() else position.y) + WALK_HEIGHT
	var slab_lo: float = walk_y - 0.35
	var slab_hi: float = walk_y + 0.55
	var occupied: Dictionary = {}
	var i := 0
	while i + 2 < indices.size():
		var a: Vector3 = xform * verts[indices[i]]
		var b: Vector3 = xform * verts[indices[i + 1]]
		var c: Vector3 = xform * verts[indices[i + 2]]
		i += 3
		if maxf(a.y, maxf(b.y, c.y)) < slab_lo or minf(a.y, minf(b.y, c.y)) > slab_hi:
			continue
		var wall_normal: Vector3 = (b - a).cross(c - a)
		if wall_normal.y * wall_normal.y >= wall_normal.length_squared() * FLOOR_DOT * FLOOR_DOT:
			continue
		var min_x: float = minf(a.x, minf(b.x, c.x))
		var max_x: float = maxf(a.x, maxf(b.x, c.x))
		var min_z: float = minf(a.z, minf(b.z, c.z))
		var max_z: float = maxf(a.z, maxf(b.z, c.z))
		var cx0: int = int(floor(min_x / CELL))
		var cx1: int = int(floor(max_x / CELL))
		var cz0: int = int(floor(min_z / CELL))
		var cz1: int = int(floor(max_z / CELL))
		for cx in range(cx0, cx1 + 1):
			for cz in range(cz0, cz1 + 1):
				var key := Vector2i(cx, cz)
				if occupied.has(key):
					continue
				var sample := Vector3((float(cx) + 0.5) * CELL, walk_y, (float(cz) + 0.5) * CELL)
				if _dist2_point_triangle(sample, a, b, c) <= DISK * DISK:
					occupied[key] = true
	_seal_wall_cavities(occupied)
	for key in occupied.keys():
		var cell: Vector2i = key
		found.append({
			"x": (float(cell.x) + 0.5) * CELL,
			"z": (float(cell.y) + 0.5) * CELL,
			"radius": DISK,
		})
	_blockers_cache = found
	_blockers_xform = xform
	return found


func floor_height_at(x: float, z: float) -> float:
	_ensure_floor_cache()
	if not _floor_ready:
		return NAN
	if x < _floor_box.position.x - 0.15 or x > _floor_box.end.x + 0.15 or z < _floor_box.position.z - 0.15 or z > _floor_box.end.z + 0.15:
		return NAN
	var origin := Vector3(x, (global_position.y if is_inside_tree() else position.y) + FLOOR_PROBE, z)
	var ceiling: float = origin.y - FLOOR_PROBE + FLOOR_MAX
	var best := NAN
	var i := 0
	while i + 2 < _floor_tris.size():
		var a: Vector3 = _floor_tris[i]
		var b: Vector3 = _floor_tris[i + 1]
		var c: Vector3 = _floor_tris[i + 2]
		i += 3
		var hit: Variant = Geometry3D.ray_intersects_triangle(origin, Vector3.DOWN, a, b, c)
		if hit == null:
			continue
		var at: Vector3 = hit
		if at.y > ceiling or at.y >= origin.y - 0.02:
			continue
		if is_nan(best) or at.y > best:
			best = at.y
	return best


func _ensure_floor_cache() -> void:
	var mesh_node := _first_mesh()
	if mesh_node == null or mesh_node.mesh == null:
		_floor_ready = false
		return
	var xform: Transform3D = mesh_node.global_transform if mesh_node.is_inside_tree() else mesh_node.transform
	if _floor_ready and xform.is_equal_approx(_floor_xform):
		return
	_floor_xform = xform
	_floor_tris = PackedVector3Array()
	var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var first := true
	var i := 0
	while i + 2 < indices.size():
		var a: Vector3 = xform * verts[indices[i]]
		var b: Vector3 = xform * verts[indices[i + 1]]
		var c: Vector3 = xform * verts[indices[i + 2]]
		i += 3
		var normal: Vector3 = (b - a).cross(c - a)
		if normal.y * normal.y < normal.length_squared() * FLOOR_DOT * FLOOR_DOT:
			continue
		_floor_tris.append(a)
		_floor_tris.append(b)
		_floor_tris.append(c)
		var tri := AABB(a, Vector3.ZERO).expand(b).expand(c)
		if first:
			_floor_box = tri
			first = false
		else:
			_floor_box = _floor_box.merge(tri)
	_floor_ready = not first


func _seal_wall_cavities(occupied: Dictionary) -> void:
	if occupied.is_empty():
		return
	var min_cx := 9999
	var max_cx := -9999
	var min_cz := 9999
	var max_cz := -9999
	for key in occupied.keys():
		var cell: Vector2i = key
		min_cx = mini(min_cx, cell.x)
		max_cx = maxi(max_cx, cell.x)
		min_cz = mini(min_cz, cell.y)
		max_cz = maxi(max_cz, cell.y)
	var sealed: Array[Vector2i] = []
	for cz in range(min_cz, max_cz + 1):
		for cx in range(min_cx, max_cx + 1):
			var cell := Vector2i(cx, cz)
			if occupied.has(cell):
				continue
			if _is_wall_cavity(occupied, cell, min_cx, max_cx, min_cz, max_cz):
				sealed.append(cell)
	for cell in sealed:
		occupied[cell] = true


func _is_wall_cavity(occupied: Dictionary, cell: Vector2i, min_cx: int, max_cx: int, min_cz: int, max_cz: int) -> bool:
	var west: float = _open_span(occupied, cell, -1, 0, min_cx, max_cx, min_cz, max_cz)
	var east: float = _open_span(occupied, cell, 1, 0, min_cx, max_cx, min_cz, max_cz)
	var north: float = _open_span(occupied, cell, 0, -1, min_cx, max_cx, min_cz, max_cz)
	var south: float = _open_span(occupied, cell, 0, 1, min_cx, max_cx, min_cz, max_cz)
	var width_x: float = _axis_width(west, east)
	var width_z: float = _axis_width(north, south)
	var narrow: float = minf(width_x, width_z)
	if narrow < TIGHT:
		return true
	if narrow >= MIN_PASSAGE:
		return false
	# A doorway is short and opens to the world. A double-wall gap is a long pinched corridor.
	if west > 50.0 or east > 50.0 or north > 50.0 or south > 50.0:
		return false
	return maxf(width_x, width_z) > CORRIDOR


func _axis_width(neg: float, pos: float) -> float:
	if neg > 50.0 or pos > 50.0:
		return 99.0
	return (neg + 1.0 + pos) * CELL


func _open_span(occupied: Dictionary, start: Vector2i, dx: int, dz: int, min_cx: int, max_cx: int, min_cz: int, max_cz: int) -> float:
	var count := 0
	var cell: Vector2i = start + Vector2i(dx, dz)
	while count < 50:
		if cell.x < min_cx or cell.x > max_cx or cell.y < min_cz or cell.y > max_cz:
			return 99.0
		if occupied.has(cell):
			return float(count)
		count += 1
		cell += Vector2i(dx, dz)
	return 99.0


func _prepare_interior() -> void:
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		var visual := mesh_node as MeshInstance3D
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		if visual.mesh == null:
			continue
		for surface in visual.mesh.get_surface_count():
			var source := visual.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var mat := source.duplicate() as StandardMaterial3D
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat.disable_receive_shadows = false
			visual.set_surface_override_material(surface, mat)


func _first_mesh() -> MeshInstance3D:
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		if (mesh_node as MeshInstance3D).mesh != null:
			return mesh_node
	return null


func _dist2_point_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab: Vector3 = b - a
	var ac: Vector3 = c - a
	var ap: Vector3 = p - a
	var d1: float = ab.dot(ap)
	var d2: float = ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return ap.length_squared()
	var bp: Vector3 = p - b
	var d3: float = ab.dot(bp)
	var d4: float = ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return bp.length_squared()
	var vc: float = d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		var v: float = d1 / (d1 - d3)
		return (a + ab * v - p).length_squared()
	var cp: Vector3 = p - c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return cp.length_squared()
	var vb: float = d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		var w: float = d2 / (d2 - d6)
		return (a + ac * w - p).length_squared()
	var va: float = d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		var w2: float = (d4 - d3) / ((d4 - d3) + (d5 - d6))
		return (b + (c - b) * w2 - p).length_squared()
	var denom: float = 1.0 / (va + vb + vc)
	return (a + ab * (vb * denom) + ac * (vc * denom)).distance_squared_to(p)
