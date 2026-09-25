extends SceneTree

## Dress hex.grassland.a edges from authored connection kinds, then blend inward.
## Stones may sit on the lower slopes. Grass and stones are the existing harvestable
## patches and shapeable rocks. Does not move the stone circle.

const HEX_PATH := "res://scenes/terrain/hex_grassland_a.tscn"
const BUSH := "res://scenes/props/bush.tscn"
const GRASS := "res://scenes/props/grass_clump.tscn"
const STONE := "res://scenes/props/scatter_stone.tscn"
const FLAT := 256.0
const MAX_Y_PLANT := 2.2
const MAX_Y_STONE := 6.2
const MIN_NORMAL_PLANT := 0.72
const MIN_NORMAL_STONE := 0.40


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hex: EtheraHexTile = load(HEX_PATH).instantiate() as EtheraHexTile
	root.add_child(hex)
	await process_frame
	await process_frame
	var manager: LowPolyTerrainManager = hex.terrain_manager()
	if manager == null:
		push_error("No terrain manager on the starting hex")
		quit(1)
		return
	var circle_xf := Transform3D.IDENTITY
	var circle_node: Node3D = hex.find_child("StoneCircle", false, false) as Node3D
	if circle_node != null:
		circle_xf = circle_node.transform
	_clear_stones(hex)
	var connections: PackedStringArray = manager.get_hex_edge_connections()
	var orientation: int = manager.hex_orientation
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260924
	var circle_xz := Vector2(circle_xf.origin.x, circle_xf.origin.z)
	var village_xz := Vector2(1.2, 88.7)
	var marker: Node3D = hex.find_child("EtheraWorldNodeMarker", true, false) as Node3D
	if marker != null:
		var mark: Vector3 = marker.global_position
		village_xz = Vector2(mark.x, mark.z)
	var taken: Array[Vector2] = [
		Vector2.ZERO,
		circle_xz,
		village_xz,
		Vector2(-5.0, 3.4),
	]
	for child in hex.get_children():
		if child is EtheraBush or child is EtheraGrassClump:
			taken.append(Vector2((child as Node3D).position.x, (child as Node3D).position.z))
	var reserved: Array = [
		[Vector2.ZERO, 8.0],
		[circle_xz, 12.0],
		[village_xz, 4.0],
	]
	var stone_n := 0
	for edge in 6:
		var kind: String = connections[edge]
		if kind != "dirt" and kind != "stone":
			continue
		var along: int = 6 if kind == "stone" else 4
		for row in 2:
			for step in along:
				var t: float = (float(step) + 0.5) / float(along)
				var jitter := rng.randf_range(-0.3, 0.3)
				var inward: float = 10.0 + float(row) * 10.0 + rng.randf_range(-1.6, 1.6)
				var at: Vector2 = _edge_point(edge, orientation, t + jitter / float(along), inward)
				if not _usable(hex, at, taken, reserved, 3.6, true):
					continue
				_add_stone(hex, at, rng, stone_n)
				taken.append(at)
				stone_n += 1
	for _i in 36:
		var radius: float = rng.randf_range(28.0, 108.0)
		var angle: float = rng.randf_range(0.0, TAU)
		var at := Vector2(cos(angle), sin(angle)) * radius
		if not _usable(hex, at, taken, reserved, 4.2, true):
			continue
		_add_stone(hex, at, rng, stone_n)
		taken.append(at)
		stone_n += 1
	for _i in 24:
		var radius: float = rng.randf_range(16.0, 112.0)
		var angle: float = rng.randf_range(0.0, TAU)
		var at := Vector2(cos(angle), sin(angle)) * radius
		if not _usable(hex, at, taken, reserved, 3.8, true):
			continue
		if hex.height_at_local(at.x, at.y) < 0.7:
			continue
		_add_stone(hex, at, rng, stone_n)
		taken.append(at)
		stone_n += 1
	hex.seat_scenery()
	circle_node = hex.find_child("StoneCircle", false, false) as Node3D
	if circle_node != null:
		circle_node.transform = circle_xf
	var synced: Dictionary = EtheraHexLandscapeSync.new().sync(hex)
	_strip_generated(hex)
	await process_frame
	var packed := PackedScene.new()
	if packed.pack(hex) != OK or ResourceSaver.save(packed, HEX_PATH) != OK:
		push_error("Could not save hex scenery")
		quit(1)
		return
	print("Hex rock scenery: %d stones; landscape %s grass / %s rocks" % [stone_n, synced.get("grass", 0), synced.get("rocks", 0)])
	quit(0)


func _clear_stones(hex: Node) -> void:
	for child in hex.get_children():
		if child is EtheraScatterStone:
			child.free()


func _edge_point(edge: int, orientation: int, t: float, inward: float) -> Vector2:
	var ends: PackedVector2Array = LowPolyTerrainHex.edge_endpoints(edge, FLAT, orientation)
	var along: Vector2 = ends[0].lerp(ends[1], clampf(t, 0.08, 0.92))
	var outward: Vector2 = LowPolyTerrainHex.edge_outward(edge, orientation)
	return along - outward * inward


func _usable(hex: EtheraHexTile, at: Vector2, taken: Array[Vector2], reserved: Array, spacing: float, stone: bool) -> bool:
	if LowPolyTerrainHex.clearance(at.x, at.y, FLAT, LowPolyTerrainHex.Orientation.POINTY_TOP) < 6.0:
		return false
	var y: float = hex.height_at_local(at.x, at.y)
	if y > (MAX_Y_STONE if stone else MAX_Y_PLANT):
		return false
	if hex.normal_at_local(at.x, at.y).y < (MIN_NORMAL_STONE if stone else MIN_NORMAL_PLANT):
		return false
	for keep in reserved:
		if at.distance_to(keep[0]) < float(keep[1]):
			return false
	for other in taken:
		if at.distance_to(other) < spacing:
			return false
	return true


func _place_for_kind(hex: Node, kind: String, at: Vector2, rng: RandomNumberGenerator, grass_n: int, bush_n: int, stone_n: int) -> String:
	if kind == "grass":
		_add_grass(hex, at, rng, grass_n)
		return "grass"
	if kind == "vegetation":
		_add_bush(hex, at, rng, bush_n)
		return "bush"
	if kind == "stone":
		_add_stone(hex, at, rng, stone_n)
		return "stone"
	if rng.randf() < 0.22:
		_add_grass(hex, at, rng, grass_n)
		return "grass"
	_add_stone(hex, at, rng, stone_n)
	return "stone"


func _add_grass(hex: Node, at: Vector2, rng: RandomNumberGenerator, index: int) -> void:
	var node: Node3D = (load(GRASS) as PackedScene).instantiate() as Node3D
	node.name = "GrassClump%d" % (index + 1)
	hex.add_child(node)
	node.owner = hex
	node.position = Vector3(at.x, 0.0, at.y)
	node.set("clump_seed", 11 + index)
	node.set("blade_count", rng.randi_range(16, 28))


func _add_bush(hex: Node, at: Vector2, rng: RandomNumberGenerator, index: int) -> void:
	var node: Node3D = (load(BUSH) as PackedScene).instantiate() as Node3D
	node.name = "Bush%d" % (index + 1)
	hex.add_child(node)
	node.owner = hex
	node.position = Vector3(at.x, 0.0, at.y)
	node.rotation.y = rng.randf_range(0.0, TAU)
	node.set("bush_height", rng.randf_range(1.05, 1.5))
	node.set("bush_radius", rng.randf_range(0.52, 0.78))


func _add_stone(hex: Node, at: Vector2, rng: RandomNumberGenerator, index: int) -> void:
	var node: Node3D = (load(STONE) as PackedScene).instantiate() as Node3D
	node.name = "ScatterStone%d" % (index + 1)
	hex.add_child(node)
	node.owner = hex
	node.position = Vector3(at.x, 0.0, at.y)
	node.rotation.y = rng.randf_range(0.0, TAU)
	node.set("stone_size", rng.randf_range(0.55, 1.65))
	node.set("stone_seed", 40 + index)


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
