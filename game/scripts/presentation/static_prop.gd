@tool
extends StaticBody3D

## A placed visual with mesh collision. Not a simulation entity and not an interaction.

@export var collision_name: String = "MeshCollision"


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	call_deferred("_ensure_mesh_collision")


func _ensure_mesh_collision() -> void:
	if not is_inside_tree():
		return
	var existing := get_node_or_null(collision_name) as CollisionShape3D
	# A packed AABB is only a warning placeholder. At play, replace it with the
	# mesh so the door and room stay open. Never rewrite the body's scale.
	if existing != null and existing.shape is BoxShape3D:
		if Engine.is_editor_hint():
			return
		existing.free()
		existing = null
	if existing != null:
		return
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		var visual := mesh_node as MeshInstance3D
		if visual.mesh == null:
			continue
		if attach_direct_trimesh(self, visual, collision_name) != null:
			return


static func attach_direct_trimesh(body: CollisionObject3D, mesh_node: MeshInstance3D, shape_name: String) -> CollisionShape3D:
	if mesh_node.mesh == null:
		return null
	var shape: Shape3D = mesh_node.mesh.create_trimesh_shape()
	if shape == null:
		return null
	var concave := shape as ConcavePolygonShape3D
	if concave != null:
		var xform: Transform3D = _local_mesh_xform(body, mesh_node)
		if not xform.is_equal_approx(Transform3D.IDENTITY):
			var faces: PackedVector3Array = concave.get_faces()
			for i in faces.size():
				faces[i] = xform * faces[i]
			concave.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.name = shape_name
	collider.shape = shape
	body.add_child(collider)
	return collider


static func _local_mesh_xform(body: Node, mesh_node: Node3D) -> Transform3D:
	var xform: Transform3D = mesh_node.transform
	var current: Node = mesh_node.get_parent()
	while current != null and current != body:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform
