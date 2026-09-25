@tool
extends "res://scripts/presentation/static_prop.gd"
class_name EtheraBurrow

## A placed burrow. Occupies like a rock. Not a simulation entity and not an interaction.


func occupancy_radius() -> float:
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
		span = 2.4
	return maxf(span * 0.48, 0.7)


func _ready() -> void:
	super._ready()
	for mesh_node in find_children("*", "MeshInstance3D", true, false):
		var visual := mesh_node as MeshInstance3D
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		if visual.mesh == null:
			continue
		for surface in visual.mesh.get_surface_count():
			var source := visual.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var mat := source.duplicate() as StandardMaterial3D
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			visual.set_surface_override_material(surface, mat)
