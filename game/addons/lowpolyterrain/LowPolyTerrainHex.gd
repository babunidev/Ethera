@tool
extends RefCounted
class_name LowPolyTerrainHex

## Regular-hex boundary imposed on the addon's rectangular height grid.
##
## The grid, chunks and sculpting stay square. This class only answers where the hex is,
## clips already-built triangles against it, and forces every point that lands on the
## perimeter down to BOUNDARY_HEIGHT. Both terrain backends call the same functions, so
## the rendered mesh, the colliders and the export all inherit one boundary.

const BOUNDARY_HEIGHT: float = 0.0
## Metres. A grid sample this close to an edge is the perimeter and stays at height 0.
## Intersection vertices produced by clipping land well inside this tolerance.
const BOUNDARY_EPSILON: float = 0.0001

const COVERAGE_OUTSIDE: int = -1
const COVERAGE_PARTIAL: int = 0
const COVERAGE_INSIDE: int = 1

enum Orientation {
	POINTY_TOP = 0,
	FLAT_TOP = 1,
}


class ClipVertex:
	var position: Vector3
	var color: Color

	func _init(at: Vector3, paint: Color = Color(0, 0, 0, 0)) -> void:
		position = at
		color = paint


static func apothem(flat_to_flat: float) -> float:
	return flat_to_flat * 0.5


static func circumradius(flat_to_flat: float) -> float:
	return flat_to_flat / sqrt(3.0)


static func corner_to_corner(flat_to_flat: float) -> float:
	return circumradius(flat_to_flat) * 2.0


## Half-width (X) and half-depth (Z) of the hex in manager-local metres.
static func half_extents(flat_to_flat: float, orientation: int) -> Vector2:
	var across_flats: float = apothem(flat_to_flat)
	var across_corners: float = circumradius(flat_to_flat)
	if orientation == Orientation.FLAT_TOP:
		return Vector2(across_corners, across_flats)
	return Vector2(across_flats, across_corners)


## Outward normal of one of the six edges. Pointy-top edge 0 faces +X, matching
## EtheraHexCoords so a flat east edge sits on the positive X side.
static func plane_normal(index: int, orientation: int) -> Vector2:
	var angle: float = deg_to_rad(60.0 * float(index))
	if orientation == Orientation.FLAT_TOP:
		angle += deg_to_rad(30.0)
	return Vector2(cos(angle), sin(angle))


static func corners(flat_to_flat: float, orientation: int) -> PackedVector2Array:
	var radius: float = circumradius(flat_to_flat)
	var pts := PackedVector2Array()
	pts.resize(6)
	for i in 6:
		var angle: float = deg_to_rad(60.0 * float(i))
		if orientation == Orientation.POINTY_TOP:
			angle -= deg_to_rad(30.0)
		pts[i] = Vector2(cos(angle), sin(angle)) * radius
	return pts


## Signed distance inside the hex. Positive is inside, zero is the perimeter.
static func clearance(x: float, z: float, flat_to_flat: float, orientation: int) -> float:
	var limit: float = apothem(flat_to_flat)
	var best: float = limit
	for i in 6:
		var normal: Vector2 = plane_normal(i, orientation)
		best = minf(best, limit - (x * normal.x + z * normal.y))
	return best


static func contains(x: float, z: float, flat_to_flat: float, orientation: int) -> bool:
	return clearance(x, z, flat_to_flat, orientation) >= -BOUNDARY_EPSILON


## True when a height sample may be sculpted. The perimeter and everything outside it may not.
static func is_editable(x: float, z: float, flat_to_flat: float, orientation: int) -> bool:
	return clearance(x, z, flat_to_flat, orientation) > BOUNDARY_EPSILON


## Chunk counts whose centred rectangle covers the hex plus one cell of margin, so the
## boundary always cuts through triangles instead of landing on the outer grid edge.
static func backend_chunk_counts(
	flat_to_flat: float, cell_size: float, chunk_size: int, orientation: int
) -> Vector2i:
	var half: Vector2 = half_extents(flat_to_flat, orientation)
	var margin: float = maxf(cell_size, 0.001)
	return Vector2i(
		_chunks_for_reach(half.x + margin, cell_size, chunk_size),
		_chunks_for_reach(half.y + margin, cell_size, chunk_size)
	)


static func _chunks_for_reach(reach: float, cell_size: float, chunk_size: int) -> int:
	if cell_size <= 0.0 or chunk_size <= 0:
		return 1
	var cells: int = ceili((reach * 2.0) / cell_size)
	return maxi(ceili(float(cells) / float(chunk_size)), 1)


## How a chunk's rectangle, expanded by `margin` for jitter, sits relative to the hex.
## `origin` is the chunk's manager-local position (its +X, less-negative-Z corner).
static func chunk_coverage(
	origin: Vector3, size_m: float, margin: float, flat_to_flat: float, orientation: int
) -> int:
	var min_x: float = origin.x - margin
	var max_x: float = origin.x + size_m + margin
	var min_z: float = origin.z - size_m - margin
	var max_z: float = origin.z + margin
	if _rect_strictly_inside(min_x, max_x, min_z, max_z, flat_to_flat, orientation):
		return COVERAGE_INSIDE
	if not _rect_hits(min_x, max_x, min_z, max_z, flat_to_flat, orientation):
		return COVERAGE_OUTSIDE
	return COVERAGE_PARTIAL


static func _rect_strictly_inside(
	min_x: float, max_x: float, min_z: float, max_z: float,
	flat_to_flat: float, orientation: int
) -> bool:
	var corners_xz: Array[Vector2] = [
		Vector2(min_x, min_z), Vector2(max_x, min_z),
		Vector2(min_x, max_z), Vector2(max_x, max_z),
	]
	for corner in corners_xz:
		if clearance(corner.x, corner.y, flat_to_flat, orientation) <= BOUNDARY_EPSILON:
			return false
	return true


static func _rect_hits(
	min_x: float, max_x: float, min_z: float, max_z: float,
	flat_to_flat: float, orientation: int
) -> bool:
	var limit: float = apothem(flat_to_flat)
	for i in 6:
		var normal: Vector2 = plane_normal(i, orientation)
		# The corner most inside this plane. If even that corner is outside, the rect is too.
		var px: float = min_x if normal.x > 0.0 else max_x
		var pz: float = min_z if normal.y > 0.0 else max_z
		if px * normal.x + pz * normal.y > limit:
			return false
	return true


## Clips one triangle to the hex. Positions are chunk-local; `chunk_origin` lifts them into
## the manager space the hex is defined in. New perimeter vertices are Y = BOUNDARY_HEIGHT.
## Returns a fan of triangles as ClipVertex triplets. Empty when the triangle misses the hex.
static func clip_triangle(
	a: Vector3, b: Vector3, c: Vector3,
	ca: Color, cb: Color, cc: Color,
	chunk_origin: Vector3,
	flat_to_flat: float,
	orientation: int
) -> Array:
	var polygon: Array[ClipVertex] = [
		ClipVertex.new(a, ca),
		ClipVertex.new(b, cb),
		ClipVertex.new(c, cc),
	]
	polygon = clip_polygon(polygon, chunk_origin, flat_to_flat, orientation)
	return _fan(polygon)


static func clip_polygon(
	polygon: Array[ClipVertex],
	chunk_origin: Vector3,
	flat_to_flat: float,
	orientation: int
) -> Array[ClipVertex]:
	var output: Array[ClipVertex] = polygon
	var limit: float = apothem(flat_to_flat)
	for plane in 6:
		if output.size() < 3:
			return []
		var normal: Vector2 = plane_normal(plane, orientation)
		var input: Array[ClipVertex] = output
		var next: Array[ClipVertex] = []
		var previous: ClipVertex = input[input.size() - 1]
		var previous_inside: bool = _inside(previous, chunk_origin, normal, limit)
		for current in input:
			var current_inside: bool = _inside(current, chunk_origin, normal, limit)
			if current_inside:
				if not previous_inside:
					next.append(_intersect(
						previous, current, chunk_origin, normal, limit
					))
				next.append(_snapped(current, chunk_origin, flat_to_flat, orientation))
			elif previous_inside:
				next.append(_intersect(
					previous, current, chunk_origin, normal, limit
				))
			previous = current
			previous_inside = current_inside
		output = next
	return _dedupe(output)


static func _inside(vertex: ClipVertex, origin: Vector3, normal: Vector2, limit: float) -> bool:
	return _signed_outside(vertex, origin, normal, limit) <= BOUNDARY_EPSILON


static func _signed_outside(
	vertex: ClipVertex, origin: Vector3, normal: Vector2, limit: float
) -> float:
	var x: float = origin.x + vertex.position.x
	var z: float = origin.z + vertex.position.z
	return x * normal.x + z * normal.y - limit


static func _intersect(
	a: ClipVertex, b: ClipVertex, origin: Vector3, normal: Vector2, limit: float
) -> ClipVertex:
	var outside_a: float = _signed_outside(a, origin, normal, limit)
	var outside_b: float = _signed_outside(b, origin, normal, limit)
	var denom: float = outside_a - outside_b
	var t: float = 0.0
	if absf(denom) > 0.000000000001:
		t = clampf(outside_a / denom, 0.0, 1.0)
	var pos: Vector3 = a.position.lerp(b.position, t)
	pos.y = BOUNDARY_HEIGHT
	return ClipVertex.new(pos, a.color.lerp(b.color, t))


static func _snapped(
	vertex: ClipVertex, origin: Vector3, flat_to_flat: float, orientation: int
) -> ClipVertex:
	var x: float = origin.x + vertex.position.x
	var z: float = origin.z + vertex.position.z
	if clearance(x, z, flat_to_flat, orientation) <= BOUNDARY_EPSILON:
		return ClipVertex.new(
			Vector3(vertex.position.x, BOUNDARY_HEIGHT, vertex.position.z), vertex.color
		)
	return vertex


static func _dedupe(polygon: Array[ClipVertex]) -> Array[ClipVertex]:
	var cleaned: Array[ClipVertex] = []
	for vertex in polygon:
		if cleaned.is_empty():
			cleaned.append(vertex)
			continue
		if cleaned[cleaned.size() - 1].position.distance_squared_to(vertex.position) <= 0.0000000001:
			continue
		cleaned.append(vertex)
	if cleaned.size() >= 2 and cleaned[0].position.distance_squared_to(cleaned[cleaned.size() - 1].position) <= 0.0000000001:
		cleaned.remove_at(cleaned.size() - 1)
	return cleaned


static func _fan(polygon: Array[ClipVertex]) -> Array:
	var triangles: Array = []
	if polygon.size() < 3:
		return triangles
	for i in range(1, polygon.size() - 1):
		var a: ClipVertex = polygon[0]
		var b: ClipVertex = polygon[i]
		var c: ClipVertex = polygon[i + 1]
		var edge1 := Vector2(b.position.x - a.position.x, b.position.z - a.position.z)
		var edge2 := Vector2(c.position.x - a.position.x, c.position.z - a.position.z)
		var cross: float = edge1.x * edge2.y - edge1.y * edge2.x
		if absf(cross) < 0.00000001:
			continue
		if cross < 0.0:
			triangles.append([a, c, b])
		else:
			triangles.append([a, b, c])
	return triangles


## Flat editor marker for one deactivated chunk, cut to the hex so the square chunk
## footprint does not draw outside the tile. Null when the chunk misses the hex.
static func build_deactivated_preview(
	chunk_origin: Vector3,
	chunk_size: int,
	cell_size: float,
	flat_to_flat: float,
	orientation: int
) -> ArrayMesh:
	var size_m: float = float(chunk_size) * cell_size
	if chunk_coverage(chunk_origin, size_m, 0.0, flat_to_flat, orientation) == COVERAGE_OUTSIDE:
		return null

	var y: float = LowPolyTerrainMeshBuilder.PREVIEW_PLANE_Y
	var polygon: Array[ClipVertex] = [
		ClipVertex.new(Vector3(0.0, y, 0.0)),
		ClipVertex.new(Vector3(0.0, y, -size_m)),
		ClipVertex.new(Vector3(size_m, y, -size_m)),
		ClipVertex.new(Vector3(size_m, y, 0.0)),
	]
	polygon = clip_polygon(polygon, chunk_origin, flat_to_flat, orientation)
	var triangles: Array = _fan(polygon)
	if triangles.is_empty():
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in triangles:
		for vertex in tri:
			var point: ClipVertex = vertex
			st.set_normal(Vector3.UP)
			st.add_vertex(point.position)
	return st.commit()


## Editor wire of the six edges, in manager-local space. Not collision and not export.
static func build_outline_mesh(flat_to_flat: float, orientation: int) -> ArrayMesh:
	var pts: PackedVector2Array = corners(flat_to_flat, orientation)
	var verts := PackedVector3Array()
	verts.resize(12)
	for i in 6:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 6]
		verts[i * 2] = Vector3(a.x, 0.04, a.y)
		verts[i * 2 + 1] = Vector3(b.x, 0.04, b.y)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


static func build_outline_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.95, 1.0, 1.0)
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## Connection kind of one hex edge. This is not a terrain paint layer.
enum EdgeType {
	GRASS = 0,
	DIRT = 1,
	STONE = 2,
	VEGETATION = 3,
}

const EDGE_COUNT: int = 6


## Edge `index + 3` is the opposite flat. 0↔3, 1↔4, 2↔5.
static func opposite_edge(index: int) -> int:
	return posmod(index + 3, EDGE_COUNT)


## Authored edge whose flat the point is nearest. Uses `edge_outward`, not `plane_normal`.
static func nearest_edge(x: float, z: float, orientation: int = Orientation.POINTY_TOP) -> int:
	var best := 0
	var best_proj := -INF
	for index in EDGE_COUNT:
		var outward: Vector2 = edge_outward(index, orientation)
		var projection: float = x * outward.x + z * outward.y
		if projection > best_proj:
			best_proj = projection
			best = index
	return best


## Stable id written for later world generation. Not a paint-layer name.
static func edge_type_id(type: int) -> String:
	match clampi(type, 0, EdgeType.VEGETATION):
		EdgeType.DIRT:
			return "dirt"
		EdgeType.STONE:
			return "stone"
		EdgeType.VEGETATION:
			return "vegetation"
		_:
			return "grass"


static func edge_type_label(type: int) -> String:
	match clampi(type, 0, EdgeType.VEGETATION):
		EdgeType.DIRT:
			return "Dirt"
		EdgeType.STONE:
			return "Stone"
		EdgeType.VEGETATION:
			return "Vegetation"
		_:
			return "Grass"


## Compass name of the flat this edge faces. Pointy-top index 0 is East, then clockwise
## toward -Z: Northeast, Northwest, West, Southwest, Southeast.
static func edge_compass_label(index: int, orientation: int) -> String:
	var names: PackedStringArray = PackedStringArray([
		"East", "Northeast", "Northwest", "West", "Southwest", "Southeast",
	])
	if orientation != Orientation.FLAT_TOP:
		return names[posmod(index, EDGE_COUNT)]
	var degrees := wrapf(rad_to_deg(edge_outward_angle(index, orientation)), -180.0, 180.0)
	var best := 0
	var best_delta := 360.0
	for candidate in EDGE_COUNT:
		var target := wrapf(-60.0 * float(candidate), -180.0, 180.0)
		var delta := absf(wrapf(degrees - target, -180.0, 180.0))
		if delta < best_delta:
			best_delta = delta
			best = candidate
	return names[best]


static func edge_type_color(type: int) -> Color:
	match clampi(type, 0, EdgeType.VEGETATION):
		EdgeType.DIRT:
			return Color(0.62, 0.42, 0.24)
		EdgeType.STONE:
			return Color(0.66, 0.68, 0.72)
		EdgeType.VEGETATION:
			return Color(0.16, 0.42, 0.2)
		_:
			return Color(0.34, 0.62, 0.28)


## True when two touching edges carry the same connection id.
static func connections_match(a: String, b: String) -> bool:
	return a != "" and a == b


## Outward angle of edge `index`. Pointy-top edge 0 faces +X (east). Index 1 is the next
## edge toward -Z, matching EtheraHexCoords neighbors: east, northeast, northwest, west,
## southwest, southeast. Flat-top adds 30° so index 0 is still a flat, not a corner.
static func edge_outward_angle(index: int, orientation: int) -> float:
	var angle := deg_to_rad(-60.0 * float(posmod(index, EDGE_COUNT)))
	if orientation == Orientation.FLAT_TOP:
		angle += deg_to_rad(30.0)
	return angle


static func edge_outward(index: int, orientation: int) -> Vector2:
	var angle := edge_outward_angle(index, orientation)
	return Vector2(cos(angle), sin(angle))


## Midpoint of the flat, in manager-local XZ. Not a corner.
static func edge_midpoint(index: int, flat_to_flat: float, orientation: int) -> Vector2:
	return edge_outward(index, orientation) * apothem(flat_to_flat)


static func edge_endpoints(index: int, flat_to_flat: float, orientation: int) -> PackedVector2Array:
	var mid_angle := edge_outward_angle(index, orientation)
	var radius: float = circumradius(flat_to_flat)
	var pts := PackedVector2Array()
	pts.resize(2)
	for side in 2:
		var delta := deg_to_rad(-30.0 if side == 0 else 30.0)
		var angle := mid_angle + delta
		pts[side] = Vector2(cos(angle), sin(angle)) * radius
	return pts


## About 2–3 m across on a 256 m hex. Small enough to click, not a landmark.
static func edge_handle_radius(flat_to_flat: float) -> float:
	return clampf(flat_to_flat * 0.0055, 0.75, 1.5)


## Gap between the true edge and anything drawn outside it, so the white outline stays clear.
static func edge_outside_gap() -> float:
	return 0.2


## Thin coloured strip just outside the flat. Not a ribbon across the tile.
static func edge_band_width(flat_to_flat: float) -> float:
	return clampf(flat_to_flat * 0.002, 0.25, 0.65)


## Sphere centre, outside the flat by at least the sphere radius. Y rests the sphere on the ground.
static func edge_handle_center(index: int, flat_to_flat: float, orientation: int) -> Vector3:
	var mid := edge_midpoint(index, flat_to_flat, orientation)
	var radius := edge_handle_radius(flat_to_flat)
	var outward := edge_outward(index, orientation)
	var push := radius + edge_outside_gap()
	return Vector3(mid.x, radius, mid.y) + Vector3(outward.x, 0.0, outward.y) * push


## Label origin relative to the handle centre: further outside the hex, and above the sphere.
static func edge_label_local_position(index: int, flat_to_flat: float, orientation: int) -> Vector3:
	var radius := edge_handle_radius(flat_to_flat)
	var outward := edge_outward(index, orientation)
	return Vector3(outward.x, 0.0, outward.y) * (radius + 0.55) + Vector3(0.0, radius * 1.25, 0.0)


## Four corners of the coloured strip, inner edge first. All of them are outside the flat.
static func edge_band_corners(index: int, flat_to_flat: float, orientation: int) -> PackedVector3Array:
	var ends := edge_endpoints(index, flat_to_flat, orientation)
	var outward := edge_outward(index, orientation)
	var out3 := Vector3(outward.x, 0.0, outward.y)
	var inner := edge_outside_gap()
	var outer := inner + edge_band_width(flat_to_flat)
	var height := 0.12
	var corners := PackedVector3Array()
	corners.resize(4)
	var a := Vector3(ends[0].x, height, ends[0].y)
	var b := Vector3(ends[1].x, height, ends[1].y)
	corners[0] = a + out3 * inner
	corners[1] = b + out3 * inner
	corners[2] = b + out3 * outer
	corners[3] = a + out3 * outer
	return corners


## True when the sphere lies completely outside the hex, not merely clear of one corner.
static func sphere_clears_hex(center: Vector3, radius: float, flat_to_flat: float, orientation: int) -> bool:
	var point := Vector2(center.x, center.z)
	var limit := apothem(flat_to_flat)
	for index in EDGE_COUNT:
		var nearest: float = point.dot(edge_outward(index, orientation)) - radius
		if nearest >= limit - 0.001:
			return true
	return false


## Distance along the ray to the sphere, or -1 when it misses.
static func ray_sphere_distance(origin: Vector3, direction: Vector3, center: Vector3, radius: float) -> float:
	var offset := origin - center
	var slope := offset.dot(direction)
	var discriminant := slope * slope - (offset.dot(offset) - radius * radius)
	if discriminant < 0.0:
		return -1.0
	var nearest := -slope - sqrt(discriminant)
	if nearest >= 0.0:
		return nearest
	var farther := -slope + sqrt(discriminant)
	return farther if farther >= 0.0 else -1.0
