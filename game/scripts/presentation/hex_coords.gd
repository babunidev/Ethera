extends RefCounted
class_name EtheraHexCoords

# Pointy-top axial hexes. +X is a real east edge, matching world east.
# `size` is center-to-vertex. Flat-to-flat across is 256 m.

const FLAT_TO_FLAT := 256.0
const SIZE := FLAT_TO_FLAT / sqrt(3.0)
const APOTHEM := FLAT_TO_FLAT * 0.5

# Clockwise from east: E, NE, NW, W, SW, SE.
const NEIGHBORS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


static func axial_to_world(q: int, r: int) -> Vector2:
	var x: float = SIZE * (sqrt(3.0) * float(q) + sqrt(3.0) * 0.5 * float(r))
	var z: float = SIZE * (1.5 * float(r))
	return Vector2(x, z)


static func world_to_axial(x: float, z: float) -> Vector2i:
	var q: float = (sqrt(3.0) / 3.0 * x - z / 3.0) / SIZE
	var r: float = (2.0 / 3.0 * z) / SIZE
	return cube_round(q, r)


static func cube_round(q: float, r: float) -> Vector2i:
	var s: float = -q - r
	var rq: float = round(q)
	var rr: float = round(r)
	var rs: float = round(s)
	var dq: float = absf(rq - q)
	var dr: float = absf(rr - r)
	var ds: float = absf(rs - s)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(int(rq), int(rr))


static func neighbor(q: int, r: int, direction: int) -> Vector2i:
	var step: Vector2i = NEIGHBORS[posmod(direction, 6)]
	return Vector2i(q + step.x, r + step.y)


static func corner(index: int, radius: float = SIZE) -> Vector2:
	var angle: float = deg_to_rad(60.0 * float(index) - 30.0)
	return Vector2(cos(angle), sin(angle)) * radius


static func edge_clearance(x: float, z: float) -> float:
	var best: float = APOTHEM
	for i in 6:
		var angle: float = deg_to_rad(60.0 * float(i))
		var distance: float = APOTHEM - (x * cos(angle) + z * sin(angle))
		best = minf(best, distance)
	return best


static func contains_local(x: float, z: float, margin: float = 0.0) -> bool:
	return edge_clearance(x, z) >= margin


static func ring_around(q: int, r: int, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(q, r)]
	if radius <= 0:
		return cells
	for dq in range(-radius, radius + 1):
		for dr in range(maxi(-radius, -dq - radius), mini(radius, -dq + radius) + 1):
			if dq == 0 and dr == 0:
				continue
			cells.append(Vector2i(q + dq, r + dr))
	return cells
