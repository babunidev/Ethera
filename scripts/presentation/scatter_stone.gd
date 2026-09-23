@tool
extends StaticBody3D
class_name EtheraScatterStone

## Authored shapeable rock. Same sculpt and Shape Weapon path as the seeded rocks.

const ROCK_SCENE := "res://assets/models/shapeable_rock.glb"

@export var entity_id: String = ""

@export_range(0.35, 2.4, 0.05) var stone_size: float = 1.0:
	set(value):
		stone_size = clampf(value, 0.3, 2.8)
		if is_node_ready():
			_rebuild()

@export var stone_seed: int = 1:
	set(value):
		stone_seed = value
		if is_node_ready():
			_rebuild()


func occupancy_radius() -> float:
	return maxf(0.16, 0.55 * stone_size)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if entity_id != "":
		set_meta("entity_id", entity_id)
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = stone_seed
	var visual := get_node_or_null("RockVisual") as Node3D
	if visual == null:
		if not ResourceLoader.exists(ROCK_SCENE):
			return
		var packed: PackedScene = load(ROCK_SCENE) as PackedScene
		if packed == null:
			return
		visual = packed.instantiate() as Node3D
		if visual == null:
			return
		visual.name = "RockVisual"
		add_child(visual)
	var yaw: float = rng.randf_range(0.0, TAU)
	var tilt: float = rng.randf_range(-0.18, 0.18)
	visual.rotation = Vector3(tilt, yaw, rng.randf_range(-0.12, 0.12))
	visual.scale = Vector3.ONE * stone_size
	EtheraAssetLibrary.new().seat_rock_in_ground(visual, self)
	_ensure_collision(visual)


func _ensure_collision(visual: Node3D) -> void:
	if find_child("StoneCollision", true, false) != null:
		return
	for mesh_node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var collider: CollisionShape3D = preload("res://scripts/presentation/static_prop.gd").attach_direct_trimesh(self, mesh, "StoneCollision")
		if collider != null and entity_id != "":
			collider.set_meta("entity_id", entity_id)
		return
