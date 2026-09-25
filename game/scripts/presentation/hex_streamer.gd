extends Node
class_name EtheraHexStreamer

const LIBRARY_PATH := "res://data/world/hex_library.json"
const LAYOUT_PATH := "res://data/world/hex_layout.json"
const STREAM_RADIUS := 1

var host: CollisionObject3D
var library: Dictionary = {}
var tiles: Dictionary = {}
var placed: Dictionary = {}
var loaded: Dictionary = {}


func setup(collision_host: CollisionObject3D) -> void:
	host = collision_host
	library = _read_json(LIBRARY_PATH)
	var layout: Dictionary = _read_json(LAYOUT_PATH)
	tiles = {}
	for entry in library.get("tiles", []):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			tiles[str(entry["id"])] = entry
	placed = {}
	for entry in layout.get("hexes", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var q: int = int(entry.get("q", 0))
		var r: int = int(entry.get("r", 0))
		placed[_key(q, r)] = entry
	sync_around(Vector2.ZERO)


func sync_around(world_xz: Vector2) -> void:
	var center: Vector2i = EtheraHexCoords.world_to_axial(world_xz.x, world_xz.y)
	var wanted: Dictionary = {}
	for cell in EtheraHexCoords.ring_around(center.x, center.y, STREAM_RADIUS):
		var key: String = _key(cell.x, cell.y)
		if placed.has(key):
			wanted[key] = placed[key]
	for key in loaded.keys():
		if not wanted.has(key):
			_unload(str(key))
	for key in wanted.keys():
		if not loaded.has(key):
			_load_hex(str(key), wanted[key])


func height_at(x: float, z: float) -> float:
	var cell: Vector2i = EtheraHexCoords.world_to_axial(x, z)
	var node: Node = loaded.get(_key(cell.x, cell.y), null)
	if node is Node3D and node.has_method("height_at_local"):
		var origin: Vector2 = EtheraHexCoords.axial_to_world(cell.x, cell.y)
		return float(node.call("height_at_local", x - origin.x, z - origin.y))
	return 0.0


func normal_at(x: float, z: float) -> Vector3:
	var cell: Vector2i = EtheraHexCoords.world_to_axial(x, z)
	var node: Node = loaded.get(_key(cell.x, cell.y), null)
	if node is Node3D and node.has_method("normal_at_local"):
		var origin: Vector2 = EtheraHexCoords.axial_to_world(cell.x, cell.y)
		return node.call("normal_at_local", x - origin.x, z - origin.y) as Vector3
	return Vector3.UP


func loaded_count() -> int:
	return loaded.size()


func loaded_hexes() -> Array:
	return loaded.values()


func loaded_key() -> String:
	var keys: Array = loaded.keys()
	keys.sort()
	return ",".join(keys)


func hex_at(q: int, r: int) -> Node:
	return loaded.get(_key(q, r), null)


func _load_hex(key: String, entry: Dictionary) -> void:
	var tile_id: String = str(entry.get("tile_id", ""))
	var spec: Dictionary = tiles.get(tile_id, {})
	var scene_path: String = str(spec.get("scene", ""))
	var hex: Node3D
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var packed: Resource = load(scene_path)
		if packed is PackedScene:
			hex = (packed as PackedScene).instantiate() as Node3D
	if hex == null:
		hex = Node3D.new()
		hex.set_script(preload("res://scripts/presentation/hex_tile.gd"))
	var q: int = int(entry.get("q", 0))
	var r: int = int(entry.get("r", 0))
	var origin: Vector2 = EtheraHexCoords.axial_to_world(q, r)
	hex.name = "Hex_%d_%d" % [q, r]
	hex.position = Vector3(origin.x, 0.0, origin.y)
	hex.rotation.y = float(int(entry.get("rotation_steps", 0))) * TAU / 6.0
	if "tile_id" in hex:
		hex.tile_id = tile_id
	if host:
		host.add_child(hex)
		if hex.has_method("build_terrain"):
			hex.call("build_terrain")
		if hex.has_method("attach_host_collision"):
			hex.call("attach_host_collision", host)
	loaded[key] = hex


func _unload(key: String) -> void:
	var hex: Node = loaded.get(key, null)
	loaded.erase(key)
	if hex is Node:
		var collide: Node = host.get_node_or_null("HexCollide_%s" % hex.name) if host else null
		if collide:
			collide.queue_free()
		hex.queue_free()


func _key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
