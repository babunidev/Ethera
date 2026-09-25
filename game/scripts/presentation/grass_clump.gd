@tool
extends StaticBody3D
class_name EtheraGrassClump

## Authored harvestable grass. Same kind as the seeded patches: open, sink, herb bundle.

@export var entity_id: String = ""

@export_range(0, 4, 1) var grass_variant: int = 0:
	set(value):
		grass_variant = clampi(value, 0, 4)
		if is_node_ready():
			_rebuild()

@export_range(15, 30, 1) var blade_count: int = 20:
	set(value):
		blade_count = clampi(value, 15, 30)
		if is_node_ready():
			_rebuild()

@export var clump_seed: int = 1:
	set(value):
		clump_seed = value
		grass_variant = posmod(value, 5)
		if is_node_ready():
			_rebuild()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if entity_id != "":
		set_meta("entity_id", entity_id)
	_rebuild()
	call_deferred("_ensure_gameplay")


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var old := get_node_or_null("GrassPatch")
	if old != null:
		old.free()
	var assets := EtheraAssetLibrary.new()
	var visual: Node3D = assets.make_grass_patch_visual(grass_variant, blade_count)
	visual.name = "GrassPatch"
	add_child(visual)


func _ensure_gameplay() -> void:
	if not is_inside_tree():
		return
	if entity_id != "":
		set_meta("entity_id", entity_id)
	var visual := get_node_or_null("GrassPatch") as Node3D
	if visual == null:
		return
	var assets := EtheraAssetLibrary.new()
	assets.make_grass_patch_pick(self, visual)
	assets.attach_grass_patch_sink(self)
