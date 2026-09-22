extends RefCounted
class_name EtheraTerrain

# Shared height for the starting grassland hex. Presentation builds the mesh from
# this; walking uses the same samples so a 50° slope is the same wall in both.

const EDGE_BLEND := 18.0
const FOUNTAIN_FLAT := 8.0
const CIRCLE_LOCAL := Vector2(18.0, 0.0)
const NORMAL_SAMPLE := 0.4
const WALKABLE_SLOPE_DEGREES := 50.0


static func height_at(x: float, z: float) -> float:
	if not EtheraHexCoords.contains_local(x, z, 0.0):
		return 0.0
	var fountain: float = Vector2(x, z).length()
	var height: float = 0.0
	if fountain > FOUNTAIN_FLAT:
		height = 0.48 * sin(x * 0.042) * cos(z * 0.038)
		height += 0.22 * sin((x + z) * 0.031)
		var to_circle: float = Vector2(x - CIRCLE_LOCAL.x, z - CIRCLE_LOCAL.y).length()
		var rise: float = 1.0 - clampf((to_circle - 4.0) / 12.0, 0.0, 1.0)
		height += 0.32 * rise * rise
	var edge: float = EtheraHexCoords.edge_clearance(x, z)
	var blend: float = clampf(edge / EDGE_BLEND, 0.0, 1.0)
	return height * blend


static func normal_at(x: float, z: float, sampler: Callable = Callable()) -> Vector3:
	var sample := NORMAL_SAMPLE
	var dx: float = _sample(sampler, x + sample, z) - _sample(sampler, x - sample, z)
	var dz: float = _sample(sampler, x, z + sample) - _sample(sampler, x, z - sample)
	return Vector3(-dx, sample * 2.0, -dz).normalized()


static func slope_degrees(x: float, z: float, sampler: Callable = Callable()) -> float:
	return rad_to_deg(Vector3.UP.angle_to(normal_at(x, z, sampler)))


static func is_walkable(x: float, z: float, limit_degrees: float = WALKABLE_SLOPE_DEGREES, sampler: Callable = Callable()) -> bool:
	return slope_degrees(x, z, sampler) <= limit_degrees + 0.001


static func _sample(sampler: Callable, x: float, z: float) -> float:
	if sampler.is_valid():
		return float(sampler.call(x, z))
	return height_at(x, z)
