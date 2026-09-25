@tool
extends "res://scripts/presentation/static_prop.gd"
class_name EtheraStoneBench

## The imported stone bench. A visual prop, not a simulation entity.
## Duplicate the node to place another. Scale the node to resize it.


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
		span = 1.8
	return maxf(span * 0.48, 0.45)
