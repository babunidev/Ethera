@tool
extends StaticBody3D
class_name EtheraBush

## A small authored bush. Collision only; not a simulation entity.

@export_range(0.6, 2.4, 0.05, "suffix:m") var bush_height: float = 1.25:
	set(value):
		bush_height = maxf(value, 0.4)
		if is_node_ready():
			_rebuild()

@export_range(0.35, 1.6, 0.05, "suffix:m") var bush_radius: float = 0.7:
	set(value):
		bush_radius = maxf(value, 0.2)
		if is_node_ready():
			_rebuild()


func occupancy_radius() -> float:
	return maxf(bush_radius * 0.7, 0.35)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var visual := get_node_or_null("Foliage") as Node3D
	if visual == null:
		visual = Node3D.new()
		visual.name = "Foliage"
		add_child(visual)
	for child in visual.get_children():
		child.queue_free()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.32, 0.24, 0.16)
	bark.roughness = 0.95
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.28, 0.42, 0.22)
	leaf.roughness = 0.9
	var trunk := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = bush_radius * 0.12
	cylinder.bottom_radius = bush_radius * 0.16
	cylinder.height = bush_height * 0.45
	trunk.mesh = cylinder
	trunk.material_override = bark
	trunk.position.y = cylinder.height * 0.5
	trunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	visual.add_child(trunk)
	var offsets: Array[Vector3] = [
		Vector3(0.0, bush_height * 0.72, 0.0),
		Vector3(bush_radius * 0.35, bush_height * 0.58, bush_radius * 0.1),
		Vector3(-bush_radius * 0.28, bush_height * 0.62, -bush_radius * 0.18),
		Vector3(bush_radius * 0.08, bush_height * 0.84, -bush_radius * 0.22),
	]
	for i in offsets.size():
		var blob := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		var scale: float = bush_radius * (0.72 if i == 0 else 0.48)
		sphere.radius = scale
		sphere.height = scale * 1.55
		blob.mesh = sphere
		blob.material_override = leaf
		blob.position = offsets[i]
		blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		visual.add_child(blob)
	var shape_node := get_node_or_null("BushCollision") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "BushCollision"
		add_child(shape_node)
	var capsule := CapsuleShape3D.new()
	capsule.radius = bush_radius * 0.62
	capsule.height = bush_height
	shape_node.shape = capsule
	shape_node.position.y = bush_height * 0.5
	shape_node.disabled = false
