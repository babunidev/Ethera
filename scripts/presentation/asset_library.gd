extends RefCounted
class_name EtheraAssetLibrary

var colors: Dictionary = {}
var assets: Dictionary = {}
var environment_asset_id: String = "asset.village_center"

func load_from_res(path: String = "res://data/presentation/assets.json") -> Error:
	var parsed: Variant = _read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("assets"):
		push_error("EtheraAssetLibrary: %s is missing or has no 'assets' array" % path)
		return ERR_FILE_CORRUPT
	colors = parsed.get("colors", {})
	environment_asset_id = str(parsed.get("environment_asset_id", environment_asset_id))
	assets = {}
	for item in parsed.get("assets", []):
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			assets[str(item["id"])] = item
	return OK


func color_for(base_color: String) -> Color:
	var values: Variant = colors.get(base_color, null)
	if typeof(values) == TYPE_ARRAY and values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color(0.5, 0.5, 0.5)


func path_for(asset_id: String) -> String:
	return str(assets.get(asset_id, {}).get("path", ""))


func has_model(asset_id: String) -> bool:
	var path: String = path_for(asset_id)
	return path != "" and ResourceLoader.exists(path)


func make_entity_body(entity: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	var entity_id: String = str(entity.get("id", ""))
	body.name = entity_id
	body.set_meta("entity_id", entity_id)
	var asset_id: String = str(entity.get("presentation", {}).get("asset_id", ""))
	var visual: Node3D = _make_visual(entity, asset_id)
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = _collision_for(str(entity.get("kind", "")))
	collision.position.y = _collision_height(str(entity.get("kind", "")))
	body.add_child(collision)
	return body


func try_mount_environment(world_root: Node3D, temporary_ground: Node3D) -> void:
	if not has_model(environment_asset_id):
		return
	var packed: Resource = load(path_for(environment_asset_id))
	if packed is PackedScene:
		var instance: Node = (packed as PackedScene).instantiate()
		instance.name = "VillageCenter"
		world_root.add_child(instance)
		if temporary_ground:
			temporary_ground.visible = false
			temporary_ground.process_mode = Node.PROCESS_MODE_DISABLED


func attach_world_position(holder: Node3D, entity: Dictionary) -> Vector3:
	var points: Dictionary = entity.get("presentation", {}).get("attach_points", {})
	var fallback: Dictionary = points.get("back", {"x": 0.0, "y": 1.15, "z": -0.22})
	var local := Vector3(float(fallback.get("x", 0.0)), float(fallback.get("y", 1.15)), float(fallback.get("z", -0.22)))
	var named: Node = holder.find_child("back", true, false)
	if named is Node3D:
		return (named as Node3D).global_position
	return holder.global_position + local.rotated(Vector3.UP, holder.rotation.y)


func _make_visual(entity: Dictionary, asset_id: String) -> Node3D:
	if has_model(asset_id):
		var packed: Resource = load(path_for(asset_id))
		if packed is PackedScene:
			var instance: Node = (packed as PackedScene).instantiate()
			_tint_meshes(instance, str(entity.get("base_color", "")))
			if instance is Node3D:
				return instance as Node3D
			var pivot := Node3D.new()
			pivot.add_child(instance)
			return pivot
	return _placeholder(entity)


func _placeholder(entity: Dictionary) -> Node3D:
	var mesh := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.roughness = 1.0
	var kind: String = str(entity.get("kind", ""))
	match kind:
		"character":
			var capsule := CapsuleMesh.new()
			capsule.radius = 0.38
			capsule.height = 1.7
			mesh.mesh = capsule
			material.albedo_color = Color(0.72, 0.74, 0.78)
			mesh.position.y = 0.85
		"memory_fountain":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 1.1
			cylinder.bottom_radius = 1.35
			cylinder.height = 1.4
			mesh.mesh = cylinder
			material.albedo_color = Color(0.22, 0.26, 0.32)
			mesh.position.y = 0.7
		"item":
			var club := BoxMesh.new()
			club.size = Vector3(0.18, 0.18, 0.7)
			mesh.mesh = club
			material.albedo_color = color_for(str(entity.get("base_color", "slate")))
			mesh.position.y = 0.12
		_:
			var rock := PrismMesh.new()
			rock.size = Vector3(0.9, 0.7, 0.9)
			mesh.mesh = rock
			material.albedo_color = Color(0.42, 0.44, 0.46)
			mesh.position.y = 0.35
	mesh.material_override = material
	return mesh


func _collision_for(kind: String) -> Shape3D:
	match kind:
		"character":
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.38
			capsule.height = 1.7
			return capsule
		"memory_fountain":
			var cylinder := CylinderShape3D.new()
			cylinder.radius = 1.25
			cylinder.height = 1.4
			return cylinder
		"item":
			var box := BoxShape3D.new()
			box.size = Vector3(0.22, 0.22, 0.74)
			return box
		_:
			var rock := BoxShape3D.new()
			rock.size = Vector3(0.9, 0.7, 0.9)
			return rock


func _collision_height(kind: String) -> float:
	match kind:
		"character":
			return 0.85
		"memory_fountain":
			return 0.7
		"item":
			return 0.12
		_:
			return 0.35


func _tint_meshes(node: Node, base_color: String) -> void:
	if base_color == "":
		return
	var color: Color = color_for(base_color)
	if node is MeshInstance3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_tint_meshes(child, base_color)


func _read_json(path: String) -> Variant:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed != null else {}
