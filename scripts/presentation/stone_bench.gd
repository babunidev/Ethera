@tool
extends StaticBody3D
class_name EtheraStoneBench

## A rectangular stone block for hex authoring. Change the sizes here, or scale the node.
## Duplicate the node to place another. This is a visual prop, not a simulation entity.

@export_group("Size")
@export_range(0.4, 6.0, 0.05, "or_greater", "suffix:m") var length: float = 1.8:
	set(value):
		length = maxf(value, 0.3)
		if is_node_ready():
			_rebuild()

@export_range(0.3, 2.0, 0.05, "or_greater", "suffix:m") var depth: float = 0.5:
	set(value):
		depth = maxf(value, 0.2)
		if is_node_ready():
			_rebuild()

@export_range(0.2, 1.2, 0.01, "or_greater", "suffix:m") var height: float = 0.45:
	set(value):
		height = maxf(value, 0.15)
		if is_node_ready():
			_rebuild()

const _MESH_VERSION := 1
var _shown_version := -1


func _ready() -> void:
	_rebuild()
	_shown_version = _MESH_VERSION
	if not Engine.is_editor_hint():
		set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	if _shown_version == _MESH_VERSION:
		return
	_shown_version = _MESH_VERSION
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_block(surface, length, height, depth)
	var mesh := surface.commit()
	mesh.surface_set_material(0, _stone_material())
	var visual := get_node_or_null("BenchMesh") as MeshInstance3D
	if visual == null:
		visual = MeshInstance3D.new()
		visual.name = "BenchMesh"
		add_child(visual)
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var shape_node := get_node_or_null("BenchCollision") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "BenchCollision"
		add_child(shape_node)
	shape_node.position = Vector3.ZERO
	shape_node.rotation = Vector3.ZERO
	shape_node.shape = mesh.create_trimesh_shape()
	collision_layer = 1
	collision_mask = 0


func _stone_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.50, 0.47, 0.42)
	material.roughness = 0.94
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


func _add_block(surface: SurfaceTool, block_length: float, block_height: float, block_depth: float) -> void:
	var hx := block_length * 0.5
	var hz := block_depth * 0.5
	var chamfer := minf(minf(hx, hz), block_height) * 0.14
	var y0 := 0.0
	var y1 := block_height
	var yc0 := chamfer
	var yc1 := block_height - chamfer
	var x0 := -hx
	var x1 := hx
	var xi0 := -hx + chamfer
	var xi1 := hx - chamfer
	var z0 := -hz
	var z1 := hz
	var zi0 := -hz + chamfer
	var zi1 := hz - chamfer
	var b0 := Vector3(xi0, y0, zi0)
	var b1 := Vector3(xi1, y0, zi0)
	var b2 := Vector3(xi1, y0, zi1)
	var b3 := Vector3(xi0, y0, zi1)
	var t0 := Vector3(xi0, y1, zi0)
	var t1 := Vector3(xi1, y1, zi0)
	var t2 := Vector3(xi1, y1, zi1)
	var t3 := Vector3(xi0, y1, zi1)
	var f0 := Vector3(xi0, yc0, z0)
	var f1 := Vector3(xi1, yc0, z0)
	var f2 := Vector3(xi1, yc1, z0)
	var f3 := Vector3(xi0, yc1, z0)
	var k0 := Vector3(xi0, yc0, z1)
	var k1 := Vector3(xi1, yc0, z1)
	var k2 := Vector3(xi1, yc1, z1)
	var k3 := Vector3(xi0, yc1, z1)
	var px0 := Vector3(x1, yc0, zi0)
	var px1 := Vector3(x1, yc0, zi1)
	var px2 := Vector3(x1, yc1, zi1)
	var px3 := Vector3(x1, yc1, zi0)
	var nx0 := Vector3(x0, yc0, zi0)
	var nx1 := Vector3(x0, yc0, zi1)
	var nx2 := Vector3(x0, yc1, zi1)
	var nx3 := Vector3(x0, yc1, zi0)
	_quad(surface, t0, t3, t2, t1)
	_quad(surface, b0, b1, b2, b3)
	_quad(surface, f0, f3, f2, f1)
	_quad(surface, k0, k1, k2, k3)
	_quad(surface, px0, px3, px2, px1)
	_quad(surface, nx0, nx1, nx2, nx3)
	_quad(surface, b0, f0, f1, b1)
	_quad(surface, b3, b2, k1, k0)
	_quad(surface, b1, px0, px1, b2)
	_quad(surface, b0, b3, nx1, nx0)
	_quad(surface, t0, t1, f2, f3)
	_quad(surface, t3, k3, k2, t2)
	_quad(surface, t1, t2, px2, px3)
	_quad(surface, t0, nx3, nx2, t3)
	_quad(surface, f0, nx0, nx3, f3)
	_quad(surface, f1, f2, px3, px0)
	_quad(surface, k1, px1, px2, k2)
	_quad(surface, k0, k3, nx2, nx1)
	_tri(surface, b0, nx0, f0)
	_tri(surface, b1, f1, px0)
	_tri(surface, b2, px1, k1)
	_tri(surface, b3, k0, nx1)
	_tri(surface, t0, f3, nx3)
	_tri(surface, t1, px3, f2)
	_tri(surface, t2, k2, px2)
	_tri(surface, t3, nx2, k3)


func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var outward := (b - a).cross(c - a)
	if outward.length_squared() < 0.0000001:
		return
	outward = outward.normalized()
	# Godot treats clockwise as the front face. Emit that order, and keep the
	# lighting normal pointing out of the block.
	for vertex in [a, c, b]:
		surface.set_normal(outward)
		surface.add_vertex(vertex)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(surface, a, b, c)
	_tri(surface, a, c, d)
