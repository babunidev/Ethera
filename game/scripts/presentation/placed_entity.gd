@tool
extends StaticBody3D
class_name EtheraPlacedEntity

## A reusable game object placed in an authored hex. The GLB is the visual;
## definition_id is the shared gameplay kind. entity_id is this instance.

const DEFINITION_FOUNTAIN := "definition.memory_fountain"
const DEFINITION_CRADLE := "definition.echo_cradle"

@export var entity_id: String = ""
@export var definition_id: String = ""


func _ready() -> void:
	if entity_id != "":
		set_meta("entity_id", entity_id)
	collision_layer = 1
	collision_mask = 0
	call_deferred("_ensure_mesh_collision")
	if definition_id == DEFINITION_CRADLE:
		call_deferred("_ensure_fountain_kind_collision")


func occupancy_radius() -> float:
	if definition_id != DEFINITION_CRADLE:
		return 0.0
	var span := 0.0
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var box: AABB = mesh.get_aabb()
		if mesh.is_inside_tree():
			box = mesh.global_transform * box
		else:
			box = mesh.transform * box
		span = maxf(span, maxf(box.size.x, box.size.z))
	if span < 0.2:
		span = 0.7 * maxf(absf(scale.x), absf(scale.z))
	return clampf(span * 0.5, 0.45, 1.6)


func _ensure_mesh_collision() -> void:
	if not is_inside_tree():
		return
	var static_prop := preload("res://scripts/presentation/static_prop.gd")
	var index := 0
	var only_ring := self is EtheraStoneCircle
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		var visual := mesh_node as MeshInstance3D
		if visual.mesh == null:
			continue
		if only_ring and not visual.name.begins_with("RingStone_"):
			continue
		var shape_name := "MeshCollision" if index == 0 else "MeshCollision_%d" % index
		if find_child(shape_name, false, false) != null:
			index += 1
			continue
		var collider: CollisionShape3D = static_prop.attach_direct_trimesh(self, visual, shape_name)
		if collider != null and entity_id != "":
			collider.set_meta("entity_id", entity_id)
		index += 1


func _ensure_fountain_kind_collision() -> void:
	if not is_inside_tree():
		return
	var box := AABB()
	var first := true
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var local: AABB = mesh.transform * mesh.get_aabb()
		var current: Node = mesh.get_parent()
		while current != null and current != self:
			if current is Node3D:
				local = (current as Node3D).transform * local
			current = current.get_parent()
		if first:
			box = local
			first = false
		else:
			box = box.merge(local)
	var radius: float = 0.55
	var height: float = 1.1
	if not first:
		radius = maxf(maxf(box.size.x, box.size.z) * 0.5, 0.45)
		height = maxf(box.size.y, 0.8)
	var basin := get_node_or_null("CradleBasin") as CollisionShape3D
	if basin == null:
		basin = CollisionShape3D.new()
		basin.name = "CradleBasin"
		add_child(basin)
	var basin_shape := basin.shape as CylinderShape3D
	if basin_shape == null:
		basin_shape = CylinderShape3D.new()
		basin.shape = basin_shape
	basin_shape.radius = radius
	basin_shape.height = minf(height * 0.35, 0.7)
	basin.position = Vector3(box.get_center().x if not first else 0.0, basin_shape.height * 0.5, box.get_center().z if not first else 0.0)
	var stem := get_node_or_null("CradleStem") as CollisionShape3D
	if stem == null:
		stem = CollisionShape3D.new()
		stem.name = "CradleStem"
		add_child(stem)
	var stem_shape := stem.shape as CylinderShape3D
	if stem_shape == null:
		stem_shape = CylinderShape3D.new()
		stem.shape = stem_shape
	stem_shape.radius = maxf(radius * 0.28, 0.22)
	stem_shape.height = height
	stem.position = Vector3(basin.position.x, height * 0.5, basin.position.z)
