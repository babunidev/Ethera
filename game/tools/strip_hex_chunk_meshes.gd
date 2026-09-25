extends SceneTree

const HEX_PATH := "res://scenes/terrain/hex_grassland_a.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hex: Node3D = load(HEX_PATH).instantiate() as Node3D
	root.add_child(hex)
	await process_frame
	var removed := 0
	var manager: Node = hex.find_child("LowPolyTerrainManager", true, false)
	if manager:
		for child in manager.get_children():
			if child is LowPolyTerrainChunk:
				child.free()
				removed += 1
	await process_frame
	var packed := PackedScene.new()
	var err: Error = packed.pack(hex)
	if err != OK:
		push_error("pack failed %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, HEX_PATH)
	if err != OK:
		push_error("save failed %s" % err)
		quit(1)
		return
	print("Removed %d generated terrain chunks from the starting hex" % removed)
	quit(0)
