extends SceneTree

## Bind authored hex grass and stones to the existing harvestable / shapeable entities.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hex: EtheraHexTile = load("res://scenes/terrain/hex_grassland_a.tscn").instantiate() as EtheraHexTile
	root.add_child(hex)
	await process_frame
	await process_frame
	var result: Dictionary = EtheraHexLandscapeSync.new().sync(hex)
	_strip_generated(hex)
	var packed := PackedScene.new()
	if packed.pack(hex) != OK or ResourceSaver.save(packed, "res://scenes/terrain/hex_grassland_a.tscn") != OK:
		push_error("Could not save hex landscape ids")
		quit(1)
		return
	print("Hex landscape sync: %s grass, %s rocks" % [result.get("grass", 0), result.get("rocks", 0)])
	quit(0)


func _strip_generated(hex: Node) -> void:
	var manager: Node = hex.find_child("LowPolyTerrainManager", true, false)
	if manager:
		for child in manager.get_children():
			if child is LowPolyTerrainChunk:
				child.free()
		var markers: Node = manager.find_child("Hex_Edge_Markers", false, false)
		if markers != null:
			markers.free()
	var collision: Node = hex.get_node_or_null("LowPolyTerrainManager_Collisions")
	if collision != null:
		collision.free()
