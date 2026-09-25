extends SceneTree

# One-shot: turn the editor workspace into the runtime starting hex.
# hex_tile_editor.tscn becomes a wrapper that instances that hex.

const EDITOR_PATH := "res://scenes/tools/hex_tile_editor.tscn"
const HEX_PATH := "res://scenes/terrain/hex_grassland_a.tscn"
const SCULPT_PATH := "res://scenes/terrain/hex_grassland_a_sculpt.res"
const FOUNTAIN_PATH := "res://scenes/props/memory_fountain.tscn"
const CRADLE_PATH := "res://scenes/props/echo_cradle.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var editor: Node3D = load(EDITOR_PATH).instantiate() as Node3D
	root.add_child(editor)
	await process_frame

	var hex := Node3D.new()
	hex.name = "HexGrasslandA"
	hex.set_script(load("res://scripts/presentation/hex_tile.gd"))
	hex.tile_id = "hex.grassland.a"
	root.add_child(hex)

	var fountain_scene: PackedScene = load(FOUNTAIN_PATH)
	var cradle_scene: PackedScene = load(CRADLE_PATH)
	var cradle_index := 1
	var children: Array = editor.get_children()
	for child in children:
		editor.remove_child(child)
		if str(child.name) == "memory_fountain":
			var fountain: Node3D = fountain_scene.instantiate() as Node3D
			fountain.name = "MemoryFountain"
			fountain.transform = child.transform
			hex.add_child(fountain)
			fountain.owner = hex
			child.free()
			continue
		if str(child.name).begins_with("ech_cradle"):
			var cradle: Node3D = cradle_scene.instantiate() as Node3D
			cradle.name = "EchoCradle%d" % cradle_index
			if "entity_id" in cradle:
				cradle.entity_id = "entity.echo_cradle.%d" % cradle_index
			cradle.transform = child.transform
			hex.add_child(cradle)
			cradle.owner = hex
			cradle_index += 1
			child.free()
			continue
		hex.add_child(child)
		child.owner = hex
		if child is LowPolyTerrainManager:
			for leftover in child.get_children():
				if leftover is LowPolyTerrainChunk:
					leftover.free()
			for leftover in child.get_children():
				if leftover is LowPolyTerrainChunk:
					continue
				leftover.owner = hex

	var manager: LowPolyTerrainManager = hex.find_child("LowPolyTerrainManager", true, false) as LowPolyTerrainManager
	if manager != null:
		var sculpt := LowPolyTerrainSculpt.new()
		sculpt.height = manager.global_height_data
		sculpt.paint = manager.global_paint_data
		sculpt.activity = manager.chunk_activity_data
		var save_err: Error = ResourceSaver.save(sculpt, SCULPT_PATH)
		if save_err != OK:
			push_error("Could not save sculpt resource: %s" % save_err)
			quit(1)
			return
		manager.sculpt_data = load(SCULPT_PATH)
		manager.global_height_data = PackedFloat32Array()
		manager.global_paint_data = PackedByteArray()
		manager.chunk_activity_data = PackedByteArray()
		manager.owner = hex

	var packed := PackedScene.new()
	var pack_err: Error = packed.pack(hex)
	if pack_err != OK:
		push_error("Could not pack starting hex: %s" % pack_err)
		quit(1)
		return
	var hex_err: Error = ResourceSaver.save(packed, HEX_PATH)
	if hex_err != OK:
		push_error("Could not save starting hex: %s" % hex_err)
		quit(1)
		return

	_write_editor_wrapper()
	print("Authored starting hex written to ", HEX_PATH)
	print("Sculpt resource written to ", SCULPT_PATH)
	print("Editor wrapper rewritten at ", EDITOR_PATH)
	quit(0)


func _own_tree(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_own_tree(child, owner)


func _write_editor_wrapper() -> void:
	var body := """[gd_scene load_steps=3 format=3 uid=\"uid://cktfrvccrm2vu\"]

[ext_resource type=\"Script\" path=\"res://scripts/presentation/hex_tile_editor.gd\" id=\"1_tool\"]
[ext_resource type=\"PackedScene\" path=\"res://scenes/terrain/hex_grassland_a.tscn\" id=\"2_hex\"]

[node name=\"HexTileEditor\" type=\"Node3D\"]
script = ExtResource(\"1_tool\")

[node name=\"HexGrasslandA\" parent=\".\" instance=ExtResource(\"2_hex\")]
"""
	var file := FileAccess.open(EDITOR_PATH, FileAccess.WRITE)
	file.store_string(body)
	file.close()
