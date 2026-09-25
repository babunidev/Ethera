@tool
extends Node3D
class_name EtheraWorldNodeMarker

## Authoring marker for one reusable World Node location inside a terrain hex.
## The scene-tree name is not the identity. Occupation, spawning and RealmNode
## regions are not stored here.

const ID_PREFIX := "node."

@export var node_id: String = "node.001":
	set(value):
		node_id = value.strip_edges()
		update_configuration_warnings()


func _enter_tree() -> void:
	call_deferred("_apply_presence")


func _ready() -> void:
	_ensure_visual()
	_apply_presence()
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if node_id == "":
		warnings.append("Assign a stable World Node id, such as node.001. The scene-tree name is not saved as the id.")
	elif not is_valid_id(node_id):
		warnings.append("World Node ids look like node.001. Keep the node. prefix and use lowercase letters, digits or underscores.")
	elif _id_is_duplicated():
		warnings.append("Another World Node marker in this hex already uses %s." % node_id)
	return warnings


static func is_valid_id(id: String) -> bool:
	if not id.begins_with(ID_PREFIX):
		return false
	var rest := id.substr(ID_PREFIX.length())
	if rest == "" or rest.begins_with(".") or rest.ends_with(".") or rest.contains(".."):
		return false
	for index in rest.length():
		var code := rest.unicode_at(index)
		var letter := code >= 97 and code <= 122
		var digit := code >= 48 and code <= 57
		if not letter and not digit and code != 95 and code != 46:
			return false
	return true


## Hex-local definitions for every marker under hex_root, sorted by id.
## Position is metres in that hex's space. Rotation is Euler radians in Godot's
## YXZ order, the same order as Node3D.rotation. tile_id is empty when the hex
## root does not carry one.
static func collect_from(hex_root: Node3D) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	if hex_root == null:
		return definitions
	var tile_id := ""
	if "tile_id" in hex_root:
		tile_id = str(hex_root.get("tile_id"))
	var markers: Array[EtheraWorldNodeMarker] = []
	_gather(hex_root, markers)
	for marker in markers:
		var entry := marker.definition_in(hex_root)
		entry["tile_id"] = tile_id
		definitions.append(entry)
	definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return definitions


func definition_in(hex_root: Node3D) -> Dictionary:
	var relative := hex_root.global_transform.affine_inverse() * global_transform
	return {
		"id": node_id,
		"position": relative.origin,
		"rotation": relative.basis.get_euler(),
	}


func _ensure_visual() -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null and visual.get_child_count() > 0:
		return
	if visual == null:
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
	var material := _marker_material()
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.58
	torus.rings = 8
	torus.ring_segments = 16
	ring.mesh = torus
	ring.position.y = 0.08
	_finish_gizmo_mesh(ring, material)
	visual.add_child(ring)
	var pin := MeshInstance3D.new()
	pin.name = "Pin"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.03
	cylinder.height = 1.15
	cylinder.radial_segments = 6
	pin.mesh = cylinder
	pin.position.y = 0.575
	_finish_gizmo_mesh(pin, material)
	visual.add_child(pin)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	sphere.radial_segments = 8
	sphere.rings = 4
	head.mesh = sphere
	head.position.y = 1.15
	_finish_gizmo_mesh(head, material)
	visual.add_child(head)


func _apply_presence() -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	visual.visible = Engine.is_editor_hint()


func _id_is_duplicated() -> bool:
	var root := _authoring_root()
	var copies := 0
	var markers: Array[EtheraWorldNodeMarker] = []
	_gather(root, markers)
	for marker in markers:
		if marker.node_id == node_id:
			copies += 1
	return copies > 1


func _authoring_root() -> Node:
	var current: Node = self
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is Viewport:
			return current
		if is_inside_tree() and parent == get_tree().root:
			return current
		current = parent
	return current


static func _gather(node: Node, into: Array[EtheraWorldNodeMarker]) -> void:
	if node is EtheraWorldNodeMarker:
		into.append(node)
	for child in node.get_children():
		_gather(child, into)


static func _marker_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.96, 0.62, 0.16)
	material.roughness = 1.0
	material.metallic = 0.0
	material.disable_receive_shadows = true
	return material


static func _finish_gizmo_mesh(mesh_node: MeshInstance3D, material: StandardMaterial3D) -> void:
	mesh_node.material_override = material
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_node.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
