@tool
extends Node3D

## Authoring workspace for the starting hex. The runtime streams
## `scenes/terrain/hex_grassland_a.tscn`; this scene mounts that same tile as a
## live tree so Low Poly Terrain Builder can sculpt it. Saving writes the hex
## scene and the external sculpt resource. Do not keep a packed instance here:
## Godot would treat the manager as a placeholder and hide the terrain.

const HEX_SCENE := "res://scenes/terrain/hex_grassland_a.tscn"


func _ready() -> void:
	if Engine.is_editor_hint():
		_mount_live_hex()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE and Engine.is_editor_hint():
		_save_runtime_hex()


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray([
		"This mounts %s live for sculpting. Save writes that hex scene." % HEX_SCENE
	])


func _mount_live_hex() -> void:
	var existing := get_node_or_null("HexGrasslandA")
	if existing != null:
		if existing.scene_file_path == "" or existing.owner != self:
			return
		existing.free()
	if not ResourceLoader.exists(HEX_SCENE):
		return
	var packed: PackedScene = load(HEX_SCENE) as PackedScene
	if packed == null:
		return
	var hex: Node = packed.instantiate()
	hex.name = "HexGrasslandA"
	add_child(hex)
	var editor: Object = Engine.get_singleton("EditorInterface")
	if editor == null:
		return
	var manager: Node = hex.find_child("LowPolyTerrainManager", true, false)
	if manager != null:
		editor.call("edit_node", manager)


func _save_runtime_hex() -> void:
	var hex := get_node_or_null("HexGrasslandA") as Node3D
	if hex == null:
		return
	var manager: LowPolyTerrainManager = hex.find_child("LowPolyTerrainManager", true, false) as LowPolyTerrainManager
	if manager != null:
		manager.persist_sculpt_resource()
		for child in manager.get_children():
			if child is LowPolyTerrainChunk:
				child.free()
		var markers: Node = manager.find_child("Hex_Edge_Markers", false, false)
		if markers != null:
			markers.free()
	var collision: Node = hex.get_node_or_null("LowPolyTerrainManager_Collisions")
	if collision != null:
		collision.free()
	var packed := PackedScene.new()
	if packed.pack(hex) != OK:
		push_error("Hex tile editor could not pack %s" % HEX_SCENE)
		return
	if ResourceSaver.save(packed, HEX_SCENE) != OK:
		push_error("Hex tile editor could not save %s" % HEX_SCENE)
		return
	if manager != null:
		manager.rebuild_chunks_structure()
		manager.refresh_hex_edge_authoring()
