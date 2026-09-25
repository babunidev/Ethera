extends RefCounted
class_name EtheraRadialSelection

const DEFAULT_ORBIT := 92.0
const DEFAULT_HIT := 34.0

# Highlight only when the pointer is on a slot, not the whole pie wedge.
static func highlighted_index(
	center: Vector2,
	mouse: Vector2,
	count: int,
	orbit_radius: float = DEFAULT_ORBIT,
	hit_radius: float = DEFAULT_HIT
) -> int:
	if count <= 0:
		return -1
	for i in range(count):
		if mouse.distance_to(slot_center(center, i, count, orbit_radius)) <= hit_radius:
			return i
	return -1


static func slot_center(center: Vector2, index: int, count: int, radius: float) -> Vector2:
	if count <= 0:
		return center
	var slice: float = TAU / float(count)
	var angle: float = -PI / 2.0 + slice * (float(index) + 0.5)
	return center + Vector2(cos(angle), sin(angle)) * radius


# A frame just outside the slot, along the line from the hub through that slot.
static func label_frame(
	slot: Vector2,
	text: String,
	font: Font,
	font_size: int,
	slot_radius: float = 28.0,
	center: Vector2 = Vector2.ZERO
) -> Rect2:
	var measured: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var size := Vector2(maxf(measured.x + 20.0, 48.0), maxf(measured.y + 12.0, 22.0))
	var outward: Vector2 = slot - center
	if outward.length_squared() < 0.0001:
		outward = Vector2(0.0, -1.0)
	else:
		outward = outward.normalized()
	var half := size * 0.5
	var extent: float = absf(outward.x) * half.x + absf(outward.y) * half.y
	var origin: Vector2 = slot + outward * (slot_radius + 8.0 + extent) - half
	return Rect2(origin, size)


# The focused object's name sits just above the hub circle.
static func hub_title_frame(
	center: Vector2,
	text: String,
	font: Font,
	font_size: int,
	hub_radius: float = 18.0
) -> Rect2:
	var measured: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var size := Vector2(maxf(measured.x + 20.0, 48.0), maxf(measured.y + 12.0, 22.0))
	var origin := center + Vector2(-size.x * 0.5, -hub_radius - 8.0 - size.y)
	return Rect2(origin, size)
