extends RefCounted
class_name EtheraAssetLibrary

var colors: Dictionary = {}
var glow_energy: float = 0.62
var assets: Dictionary = {}
var environment_asset_id: String = "asset.village_center"

const FALLBACK_ASSETS_PATH := "res://data/presentation/assets.json"
const PEBBLE_FOOTPRINT := 0.5
const MEDIUM_ROCK_SCENES: Array[String] = [
	"res://glTF/Rock_Medium_1.gltf",
	"res://glTF/Rock_Medium_2.gltf",
	"res://glTF/Rock_Medium_3.gltf",
]
const PEBBLE_SCENES: Array[String] = [
	"res://glTF/Pebble_Round_1.gltf",
	"res://glTF/Pebble_Round_2.gltf",
	"res://glTF/Pebble_Round_3.gltf",
	"res://glTF/Pebble_Round_4.gltf",
	"res://glTF/Pebble_Round_5.gltf",
	"res://glTF/Pebble_Square_1.gltf",
	"res://glTF/Pebble_Square_2.gltf",
	"res://glTF/Pebble_Square_3.gltf",
	"res://glTF/Pebble_Square_4.gltf",
	"res://glTF/Pebble_Square_5.gltf",
	"res://glTF/Pebble_Square_6.gltf",
]

# Presentation resolves its own asset manifest from the content index rather than reading
# it off the simulation's catalog, so nothing here depends on the runtime object.
func load_from_res(path: String = "") -> Error:
	var resolved: String = path if path != "" else _indexed_assets_path()
	var parsed: Variant = _read_json(resolved)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("assets"):
		push_error("EtheraAssetLibrary: %s is missing or has no 'assets' array" % resolved)
		return ERR_FILE_CORRUPT
	colors = parsed.get("colors", {})
	glow_energy = float(parsed.get("glow_energy", glow_energy))
	environment_asset_id = str(parsed.get("environment_asset_id", environment_asset_id))
	assets = {}
	for item in parsed.get("assets", []):
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			assets[str(item["id"])] = item
	return OK


func _indexed_assets_path() -> String:
	var index: Variant = _read_json("res://data/content_index.json")
	if typeof(index) != TYPE_DICTIONARY:
		return FALLBACK_ASSETS_PATH
	var indexed: String = str((index.get("files", {}) as Dictionary).get("presentation_assets", ""))
	return indexed if indexed != "" else FALLBACK_ASSETS_PATH


func color_for(base_color: String) -> Color:
	var values: Variant = colors.get(base_color, null)
	if typeof(values) == TYPE_ARRAY and values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return Color(0.5, 0.5, 0.5)


func glow_for(base_color: String) -> Color:
	return color_for(base_color)


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
	_apply_visual_scale(visual, entity)
	body.add_child(visual)
	if asset_id == "asset.shapeable_rock":
		seat_rock_in_ground(visual, body)
	var kind: String = str(entity.get("kind", ""))
	if kind == "character":
		_add_pick_collision(body, kind)
	elif kind == "container" or kind == "grass":
		if kind == "container" and _visual_has_mesh(visual):
			_ensure_mesh_collision(visual, entity_id)
		_add_fitted_pick(body, visual, "ContainerPick")
	elif _is_herb_item(entity):
		_add_fitted_pick(body, visual, "HerbPick")
	elif kind == "memory_fountain" and not has_model(asset_id):
		_add_pick_collision(body, kind)
	elif _visual_has_mesh(visual):
		_ensure_mesh_collision(visual, entity_id)
	else:
		_add_pick_collision(body, kind)
	if str(entity.get("kind", "")) == "character" and has_model(asset_id):
		var animator := Node.new()
		animator.name = "CharacterAnimation"
		animator.set_script(preload("res://scripts/presentation/character_animation.gd"))
		body.add_child(animator)
	if str(entity.get("kind", "")) == "container" and visual.find_child("LidPivot", true, false) != null:
		var lid := Node.new()
		lid.name = "ContainerLid"
		lid.set_script(preload("res://scripts/presentation/stone_container_lid.gd"))
		body.add_child(lid)
	if _is_grass_patch(entity):
		var sink := Node.new()
		sink.name = "GrassPatchSink"
		sink.set_script(preload("res://scripts/presentation/grass_patch_sink.gd"))
		body.add_child(sink)
	return body


func try_mount_environment(world_root: Node3D, _hex_host: Node3D) -> void:
	if not has_model(environment_asset_id):
		return
	var packed: Resource = load(path_for(environment_asset_id))
	if packed is PackedScene:
		var instance: Node = (packed as PackedScene).instantiate()
		instance.name = "VillageCenter"
		world_root.add_child(instance)
		_ensure_mesh_collision(instance)


# The chest-bone `back` node is used for position only. Its rotation follows the
# rig, which is not the character's facing, and was leaving the club as a
# crossbar through the torso. Orientation is built in character space: +Y up,
# -Z out the back. The club's long axis (local +Z) lies on that back plane.
func attach_world_transform(holder: Node3D, entity: Dictionary, attachment: String = "back", carried: Node3D = null) -> Transform3D:
	var points: Dictionary = entity.get("presentation", {}).get("attach_points", {})
	var point: Dictionary = points.get(attachment, {"x": 0.0, "y": 1.15, "z": -0.22})
	var facing := Basis.from_euler(Vector3(0.0, holder.rotation.y, 0.0))
	var named: Node = holder.find_child(attachment, true, false)
	var origin: Vector3
	if named is Node3D and (named as Node3D).is_inside_tree():
		origin = (named as Node3D).global_position
	else:
		var mount := Vector3(float(point.get("x", 0.0)), float(point.get("y", 1.15)), float(point.get("z", -0.22)))
		origin = holder.global_position + facing * mount
	var extra := Basis.IDENTITY
	var lean: float = deg_to_rad(float(point.get("lean_degrees", 0.0)))
	if absf(lean) > 0.001:
		extra = Basis.from_euler(Vector3(lean, deg_to_rad(18.0), deg_to_rad(-12.0)))
	var local: Transform3D = sheath_transform(point.get("sheath", {}))
	var posed := Transform3D(facing * extra * local.basis, origin + facing * local.origin)
	if attachment == "back" and carried != null:
		posed.origin += _sheath_pull_to_mount(carried, posed, origin, facing)
	return posed


func attach_world_position(holder: Node3D, entity: Dictionary) -> Vector3:
	return attach_world_transform(holder, entity).origin


# Keep the club on the animated `back` node. Pull the club mesh inward so its
# inner face sits on the node instead of hovering by half the sculpt thickness.
const SHEATH_PULL_IN := 0.28


func _sheath_pull_to_mount(carried: Node3D, posed: Transform3D, mount: Vector3, facing: Basis) -> Vector3:
	var back_out: Vector3 = facing * Vector3(0.0, 0.0, -1.0)
	var club: AABB = _aabb_in_ancestor(carried, carried)
	if club.size.x < 0.02 or club.size.y < 0.02 or club.size.z < 0.02:
		return -back_out * SHEATH_PULL_IN
	var club_in := INF
	for corner in _aabb_corners(club):
		club_in = minf(club_in, (posed * corner).dot(back_out))
	if club_in >= INF:
		return -back_out * SHEATH_PULL_IN
	var target: float = mount.dot(back_out) - SHEATH_PULL_IN
	return back_out * (target - club_in)


func _aabb_corners(box: AABB) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for x in [0.0, 1.0]:
		for y in [0.0, 1.0]:
			for z in [0.0, 1.0]:
				corners.append(box.position + box.size * Vector3(x, y, z))
	return corners


# Placeholder clubs sit 0.12 m up so they rest on the ground. That local Y becomes
# the back-normal once sheathed, so drop it while carried and restore it when loose.
# Grass bundles keep their blade layout on the hip.
func apply_carried_visual(node: Node3D, carried: bool) -> void:
	_set_pick_shapes_disabled(node, carried)
	if node.has_meta("keep_carried_layout"):
		return
	for child in node.get_children():
		if not child is Node3D:
			continue
		if not child.has_meta("loose_local"):
			child.set_meta("loose_local", (child as Node3D).position)
		(child as Node3D).position = Vector3.ZERO if carried else child.get_meta("loose_local")


func _set_pick_shapes_disabled(node: Node, disabled: bool) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = disabled
	for child in node.get_children():
		_set_pick_shapes_disabled(child, disabled)


# Character-local sheath. `diagonal_degrees` is the angle in the back plane from
# horizontal: 0 lies across the shoulders, 90 stands up the spine. The marked
# pose is a slash from hip toward the opposite shoulder.
static func sheath_transform(sheath: Dictionary) -> Transform3D:
	if sheath.is_empty():
		return Transform3D.IDENTITY
	var offset := Vector3(
		float(sheath.get("x", 0.0)),
		float(sheath.get("y", 0.0)),
		float(sheath.get("z", 0.0))
	)
	var from_horizontal: float = deg_to_rad(float(sheath.get("diagonal_degrees", 58.0)))
	var long_axis := Vector3(cos(from_horizontal), sin(from_horizontal), 0.0).normalized()
	var back_out := Vector3(0.0, 0.0, -1.0)
	var side: Vector3 = back_out.cross(long_axis)
	if side.length() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var normal: Vector3 = long_axis.cross(side).normalized()
	return Transform3D(Basis(side, normal, long_axis), offset)


func _ensure_mesh_collision(root: Node, entity_id: String = "") -> void:
	if root is CollisionObject3D and _has_collision_shape(root):
		return
	for child in root.get_children():
		_ensure_mesh_collision(child, entity_id)
	if not (root is MeshInstance3D):
		return
	var mesh: Mesh = (root as MeshInstance3D).mesh
	if mesh == null:
		return
	var shape: Shape3D = mesh.create_trimesh_shape()
	if shape == null:
		return
	var body := StaticBody3D.new()
	body.name = "MeshCollision"
	if entity_id != "":
		body.set_meta("entity_id", entity_id)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)


func _add_pick_collision(body: StaticBody3D, kind: String) -> void:
	if kind == "memory_fountain":
		_add_shape(body, _cylinder(2.5, 0.5), 0.25)
		_add_shape(body, _cylinder(0.65, 2.2), 1.5)
		return
	var collision := CollisionShape3D.new()
	collision.shape = _collision_for(kind)
	collision.position.y = _collision_height(kind)
	body.add_child(collision)


func _add_fitted_pick(body: StaticBody3D, visual: Node3D, pick_name: String = "ContainerPick") -> void:
	var box: AABB = _aabb_in_ancestor(visual, body)
	if box.size.x < 0.05 or box.size.y < 0.05 or box.size.z < 0.05:
		_add_pick_collision(body, "container" if pick_name == "ContainerPick" else "item")
		return
	var shape := BoxShape3D.new()
	shape.size = Vector3(maxf(box.size.x, 0.08), maxf(box.size.y, 0.08), maxf(box.size.z, 0.08))
	var collision := CollisionShape3D.new()
	collision.name = pick_name
	collision.shape = shape
	collision.position = box.get_center()
	body.add_child(collision)


func _aabb_in_ancestor(root: Node, ancestor: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.insert(0, root)
	for node in meshes:
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var local: AABB = _transform_to_ancestor(mesh, ancestor) * mesh.get_aabb()
		if first:
			combined = local
			first = false
		else:
			combined = combined.merge(local)
	return combined


func _add_shape(body: StaticBody3D, shape: Shape3D, height: float) -> void:
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = height
	body.add_child(collision)


func _cylinder(radius: float, height: float) -> CylinderShape3D:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	return cylinder


func _visual_has_mesh(root: Node) -> bool:
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		return true
	return not root.find_children("*", "MeshInstance3D", true, false).is_empty()


func _has_collision_shape(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape3D:
			return true
		if _has_collision_shape(child):
			return true
	return false


func _is_herb_item(entity: Dictionary) -> bool:
	return str(entity.get("equipment_slot_id", "")) == EtheraIds.SLOT_HERB or str(entity.get("template_id", "")) == EtheraIds.TEMPLATE_GRASS_LEAF


func _is_grass_patch(entity: Dictionary) -> bool:
	return str(entity.get("kind", "")) == EtheraIds.KIND_GRASS or (
		str(entity.get("kind", "")) == EtheraIds.KIND_CONTAINER
		and str(entity.get("presentation", {}).get("asset_id", "")) == "asset.grass"
	)


func _apply_visual_scale(visual: Node3D, entity: Dictionary) -> void:
	var raw: Variant = entity.get("presentation", {}).get("scale", null)
	if raw == null:
		if visual.has_meta("footprint_fit"):
			visual.scale *= float(visual.get_meta("footprint_fit"))
		return
	if typeof(raw) == TYPE_DICTIONARY:
		var values: Dictionary = raw
		visual.scale = Vector3(float(values.get("x", 1.0)), float(values.get("y", 1.0)), float(values.get("z", 1.0)))
	else:
		var amount: float = float(raw)
		visual.scale = Vector3(amount, amount, amount)
	if visual.has_meta("footprint_fit"):
		visual.scale *= float(visual.get_meta("footprint_fit"))


func make_grass_patch_visual(variant: int, blade_count: int) -> Node3D:
	return _make_grass({
		"kind": EtheraIds.KIND_GRASS,
		"presentation": {
			"variant": variant,
			"blade_count": blade_count,
		},
	})


func make_grass_patch_pick(body: StaticBody3D, visual: Node3D) -> void:
	if body.get_node_or_null("ContainerPick") != null:
		return
	_add_fitted_pick(body, visual, "ContainerPick")


func attach_grass_patch_sink(body: Node) -> void:
	if body.get_node_or_null("GrassPatchSink") != null:
		return
	var sink := Node.new()
	sink.name = "GrassPatchSink"
	sink.set_script(preload("res://scripts/presentation/grass_patch_sink.gd"))
	body.add_child(sink)


static func medium_rock_scene_path(index: int) -> String:
	if MEDIUM_ROCK_SCENES.is_empty():
		return ""
	return MEDIUM_ROCK_SCENES[posmod(index, MEDIUM_ROCK_SCENES.size())]


static func pebble_scene_path(index: int) -> String:
	if PEBBLE_SCENES.is_empty():
		return ""
	return PEBBLE_SCENES[posmod(index, PEBBLE_SCENES.size())]


static func _stable_index(text: String, count: int) -> int:
	if count <= 1:
		return 0
	var mixed := 0
	for i in text.length():
		mixed = (mixed * 33 + text.unicode_at(i)) % 1000003
	return posmod(mixed, count)


func _make_grass(entity: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.set_meta("keep_carried_layout", true)
	var presentation: Dictionary = entity.get("presentation", {})
	var bundled: bool = bool(presentation.get("bundle", false)) or _is_herb_item(entity)
	var variant: int = int(presentation.get("variant", 0))
	if not bundled:
		root.name = "GrassPatch"
	var blades: int = 5 if bundled else clampi(int(presentation.get("blade_count", 18)), 15, 30)
	var palette: Array[Color] = [
		Color(0.32, 0.50, 0.21),
		Color(0.38, 0.54, 0.24),
		Color(0.28, 0.44, 0.18),
		Color(0.34, 0.48, 0.20),
		Color(0.40, 0.56, 0.26),
	]
	var heights: Array[Vector2] = [
		Vector2(0.14, 0.26),
		Vector2(0.10, 0.18),
		Vector2(0.18, 0.30),
		Vector2(0.13, 0.22),
		Vector2(0.16, 0.29),
	]
	var height_range: Vector2 = heights[variant % heights.size()]
	if bundled:
		height_range = Vector2(0.11, 0.18)
	for i in range(blades):
		var height: float = lerpf(height_range.x, height_range.y, float((i * 17) % 10) / 9.0)
		var base: float = lerpf(0.028, 0.055, float((i * 13) % 8) / 7.0)
		var color: Color = palette[(variant + i) % palette.size()].lightened(0.03 * float(i % 4))
		var blade := MeshInstance3D.new()
		blade.mesh = _grass_triangle_mesh(height, base, color)
		var angle: float = TAU * float(i) / float(maxi(blades, 1)) + 0.37 * float(i)
		var radius: float
		if bundled:
			radius = 0.006 + 0.013 * sqrt(float((i * 11) % blades) / float(maxi(blades, 1)))
		else:
			radius = 0.03 + 0.18 * sqrt(float((i * 11) % blades) / float(maxi(blades, 1)))
		blade.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		blade.rotation = Vector3(
			deg_to_rad((-8.0 if bundled else -12.0) - float((i * 7) % 18)),
			angle + 0.4 * float(i % 3),
			deg_to_rad(8.0 * float((i % 2) * 2 - 1))
		)
		root.add_child(blade)
	if bundled:
		var tie := MeshInstance3D.new()
		var wrap := CylinderMesh.new()
		wrap.top_radius = 0.028
		wrap.bottom_radius = 0.032
		wrap.height = 0.016
		wrap.radial_segments = 10
		tie.mesh = wrap
		tie.position = Vector3(0.0, 0.055, 0.0)
		var wrap_mat := StandardMaterial3D.new()
		wrap_mat.albedo_color = Color(0.28, 0.36, 0.16)
		wrap_mat.roughness = 0.96
		tie.material_override = wrap_mat
		root.add_child(tie)
	for child in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_seat_item_on_ground(root)
	return root


func _grass_triangle_mesh(height: float, base: float, color: Color) -> ArrayMesh:
	var half: float = base * 0.5
	var verts := PackedVector3Array([
		Vector3(-half, -0.03, 0.0),
		Vector3(half, -0.03, 0.0),
		Vector3(0.0, height, 0.0),
	])
	var normals := PackedVector3Array([Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0)])
	var uvs := PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(0.5, 0.0)])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, material)
	return mesh


func _make_stone_circle(entity: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "StoneCircle"
	EtheraStoneCircle.populate(root, float(entity.get("discovery_radius", 10.0)))
	return root


func _instance_model(path: String) -> Node3D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var packed: Resource = load(path)
	if not packed is PackedScene:
		return null
	var instance: Node = (packed as PackedScene).instantiate()
	if instance is Node3D:
		return instance as Node3D
	var root := Node3D.new()
	root.add_child(instance)
	return root


func _make_visual(entity: Dictionary, asset_id: String) -> Node3D:
	if _is_grass_patch(entity) or _is_herb_item(entity):
		return _make_grass(entity)
	if asset_id == "asset.stone_circle":
		return _make_stone_circle(entity)
	if asset_id == "asset.shapeable_rock":
		var entity_id: String = str(entity.get("id", ""))
		var scattered: bool = entity_id.begins_with("entity.shapeable_rock.scatter.")
		var model_path: String = medium_rock_scene_path(_stable_index(entity_id, MEDIUM_ROCK_SCENES.size())) if scattered else pebble_scene_path(_stable_index(entity_id, PEBBLE_SCENES.size()))
		var rock: Node3D = _instance_model(model_path)
		if rock != null:
			if scattered:
				rock.set_meta("footprint_fit", footprint_fit(rock))
			return rock
	if has_model(asset_id):
		var packed: Resource = load(path_for(asset_id))
		if packed is PackedScene:
			var instance: Node = (packed as PackedScene).instantiate()
			_tint_meshes(instance, str(entity.get("base_color", "")))
			var visual: Node3D
			if instance is Node3D:
				visual = instance as Node3D
			else:
				visual = Node3D.new()
				visual.add_child(instance)
			if str(entity.get("kind", "")) == "item":
				_seat_item_on_ground(visual)
			return visual
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
			cylinder.top_radius = 2.2
			cylinder.bottom_radius = 2.7
			cylinder.height = 2.8
			mesh.mesh = cylinder
			material.albedo_color = Color(0.22, 0.26, 0.32)
			mesh.position.y = 1.4
		"item":
			var club := BoxMesh.new()
			club.size = Vector3(0.18, 0.18, 0.7)
			mesh.mesh = club
			material.albedo_color = color_for(str(entity.get("base_color", "slate")))
			mesh.position.y = 0.12
		"container":
			var chest := BoxMesh.new()
			chest.size = Vector3(0.7, 0.42, 0.48)
			mesh.mesh = chest
			material.albedo_color = Color(0.36, 0.28, 0.2)
			mesh.position.y = 0.21
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
			capsule.radius = 0.72
			capsule.height = 2.05
			return capsule
		"landmark":
			return _cylinder(3.15, 3.4)
		"memory_fountain":
			return _cylinder(2.5, 0.5)
		"item":
			var box := BoxShape3D.new()
			box.size = Vector3(0.22, 0.22, 0.74)
			return box
		"container":
			var chest := BoxShape3D.new()
			chest.size = Vector3(0.7, 0.42, 0.48)
			return chest
		_:
			var rock := BoxShape3D.new()
			rock.size = Vector3(0.9, 0.7, 0.9)
			return rock


func _collision_height(kind: String) -> float:
	match kind:
		"character":
			return 1.025
		"landmark":
			return 1.6
		"memory_fountain":
			return 1.4
		"item":
			return 0.12
		"container":
			return 0.21
		_:
			return 0.35


func _tint_meshes(node: Node, base_color: String) -> void:
	if base_color == "":
		return
	var color: Color = color_for(base_color)
	var glow: Color = glow_for(base_color)
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var source: Material = mesh.get_active_material(0)
		var material: StandardMaterial3D
		if source is StandardMaterial3D:
			material = (source as StandardMaterial3D).duplicate()
		else:
			material = StandardMaterial3D.new()
			material.roughness = 0.72
		# Keep the imported albedo map; the color multiplies it so variants stay readable.
		# Emission is the living-stone tint, not a lamp. Day and night scale it.
		material.albedo_color = color.lerp(Color.WHITE, 0.28)
		material.next_pass = null
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = glow_energy
		mesh.material_override = material
		mesh.set_meta("living_stone_glow", glow_energy)
		if not mesh.is_in_group("ethera_living_stone"):
			mesh.add_to_group("ethera_living_stone")
	for child in node.get_children():
		_tint_meshes(child, base_color)


# Seat the mesh on the ground, then bury enough of it that it grows out of the dirt.
const ROCK_EMBED_FRACTION := 0.55
const ROCK_EMBED_MIN := 0.08


func footprint_fit(visual: Node3D, footprint: float = PEBBLE_FOOTPRINT) -> float:
	var box: AABB = _aabb_in_ancestor(visual, visual)
	var span: float = maxf(box.size.x, box.size.z)
	if span < 0.001:
		return 1.0
	return footprint / span


func seat_rock_in_ground(visual: Node3D, ancestor: Node3D = null) -> void:
	if ancestor == null:
		ancestor = visual
	var box: AABB = _aabb_in_ancestor(visual, ancestor)
	if box.size.y < 0.02:
		return
	var embed: float = maxf(box.size.y * ROCK_EMBED_FRACTION, ROCK_EMBED_MIN)
	embed = minf(embed, box.size.y * 0.62)
	visual.position.y -= box.position.y + embed


func _seat_item_on_ground(visual: Node3D) -> void:
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
	if visual is MeshInstance3D:
		meshes.insert(0, visual)
	if meshes.is_empty():
		return
	var min_y := INF
	for mesh in meshes:
		var to_visual: Transform3D = _transform_to_ancestor(mesh as Node3D, visual)
		var box: AABB = visual.transform * to_visual * (mesh as MeshInstance3D).get_aabb()
		min_y = minf(min_y, box.position.y)
	if min_y < INF:
		visual.position.y -= min_y


func _transform_to_ancestor(node: Node3D, ancestor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != ancestor:
		if current is Node3D:
			xf = (current as Node3D).transform * xf
		current = current.get_parent()
	return xf


func _read_json(path: String) -> Variant:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed != null else {}
