extends RefCounted
class_name EtheraItemHandoff

# Pickup and swap land instantly in the simulation. This only draws the travel:
# the incoming club rises onto the back while the outgoing one leaves, then falls.
# They may pass through each other. The last third of a drop is a scripted bounce
# onto a corner; Godot physics does not choose the resting pose.

const DURATION := 0.64
const GUIDE_END := 0.67
const CONTACT := 0.42

var _carried: Dictionary = {}
var _motions: Dictionary = {}


func forget(entity_id: String) -> void:
	_carried.erase(entity_id)
	_motions.erase(entity_id)


func observe(entity_id: String, carried: bool, current: Transform3D) -> void:
	if not _carried.has(entity_id):
		_carried[entity_id] = carried
		return
	if bool(_carried[entity_id]) == carried:
		return
	_carried[entity_id] = carried
	_motions[entity_id] = {
		"kind": "rise" if carried else "drop",
		"elapsed": 0.0,
		"start": current,
	}


func is_active(entity_id: String) -> bool:
	return _motions.has(entity_id)


func is_airborne(entity_id: String) -> bool:
	return _motions.has(entity_id)


func step(entity_id: String, delta: float, target: Transform3D) -> Transform3D:
	if not _motions.has(entity_id):
		return target
	var motion: Dictionary = _motions[entity_id]
	motion["elapsed"] = float(motion.get("elapsed", 0.0)) + delta
	var t: float = clampf(float(motion["elapsed"]) / DURATION, 0.0, 1.0)
	var start: Transform3D = motion["start"]
	var posed: Transform3D
	if str(motion.get("kind", "")) == "rise":
		posed = rise_pose(t, start, target)
	else:
		posed = drop_pose(t, start, target)
	if t >= 1.0:
		_motions.erase(entity_id)
		return target
	return posed


static func loose_transform(position: Vector3, yaw: float) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), position)


static func rise_pose(t: float, start: Transform3D, target: Transform3D) -> Transform3D:
	t = clampf(t, 0.0, 1.0)
	var u: float = _ease_out_cubic(t)
	var pos: Vector3 = start.origin.lerp(target.origin, u)
	pos.y += sin(t * PI) * 0.42
	return Transform3D(_slerp_basis(start.basis, target.basis, u), pos)


static func drop_pose(t: float, start: Transform3D, target: Transform3D) -> Transform3D:
	t = clampf(t, 0.0, 1.0)
	var release: Transform3D = release_transform(start, target)
	if t <= GUIDE_END:
		var u: float = _ease_out_cubic(t / GUIDE_END)
		return Transform3D(
			_slerp_basis(start.basis, release.basis, u),
			start.origin.lerp(release.origin, u)
		)
	return fall_pose((t - GUIDE_END) / (1.0 - GUIDE_END), release, target)


static func release_transform(start: Transform3D, target: Transform3D) -> Transform3D:
	var aside: Vector3 = target.origin - start.origin
	aside.y = 0.0
	if aside.length() < 0.05:
		aside = Vector3(0.22, 0.0, 0.12)
	else:
		aside = aside.normalized() * 0.18
	var origin := Vector3(
		target.origin.x + aside.x * 0.3,
		maxf(target.origin.y + 0.58, 0.5),
		target.origin.z + aside.z * 0.3
	)
	var yaw: float = target.basis.get_euler().y
	return Transform3D(Basis.from_euler(Vector3(0.85, yaw + 0.35, 0.55)), origin)


static func fall_pose(u: float, release: Transform3D, target: Transform3D) -> Transform3D:
	u = clampf(u, 0.0, 1.0)
	var pos: Vector3 = release.origin.lerp(target.origin, _ease_in_cubic(u))
	pos.y = bounce_height(release.origin.y, target.origin.y, u)
	var basis: Basis
	if u < CONTACT:
		basis = _slerp_basis(release.basis, impact_basis(target), _ease_in_cubic(u / CONTACT))
	else:
		basis = _slerp_basis(impact_basis(target), target.basis, _ease_out_cubic((u - CONTACT) / (1.0 - CONTACT)))
	return Transform3D(basis, pos)


static func impact_basis(target: Transform3D) -> Basis:
	var yaw: float = target.basis.get_euler().y
	return Basis.from_euler(Vector3(0.28, yaw + 0.2, 0.4))


static func bounce_height(start_y: float, rest_y: float, u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	var rise: float = start_y - rest_y
	if u < CONTACT:
		var s: float = u / CONTACT
		return lerpf(start_y, rest_y, s * s)
	var s: float = (u - CONTACT) / (1.0 - CONTACT)
	return rest_y + rise * 0.28 * (1.0 - s) * sin(s * PI)


static func _slerp_basis(from: Basis, to: Basis, weight: float) -> Basis:
	return Basis(from.get_rotation_quaternion().slerp(to.get_rotation_quaternion(), clampf(weight, 0.0, 1.0)))


static func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


static func _ease_in_cubic(t: float) -> float:
	var clamped: float = clampf(t, 0.0, 1.0)
	return clamped * clamped * clamped
