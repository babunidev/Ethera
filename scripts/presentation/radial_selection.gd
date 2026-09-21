extends RefCounted
class_name EtheraRadialSelection

const DEADZONE := 36.0

static func highlighted_index(center: Vector2, mouse: Vector2, count: int, deadzone: float = DEADZONE) -> int:
	if count <= 0:
		return -1
	var delta: Vector2 = mouse - center
	if delta.length() < deadzone:
		return -1
	var angle: float = atan2(delta.x, -delta.y)
	if angle < 0.0:
		angle += TAU
	var slice: float = TAU / float(count)
	return int(floor(angle / slice)) % count


static func slot_center(center: Vector2, index: int, count: int, radius: float) -> Vector2:
	if count <= 0:
		return center
	var slice: float = TAU / float(count)
	var angle: float = -PI / 2.0 + slice * (float(index) + 0.5)
	return center + Vector2(cos(angle), sin(angle)) * radius
