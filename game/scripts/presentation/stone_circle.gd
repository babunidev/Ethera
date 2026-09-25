@tool
extends EtheraPlacedEntity
class_name EtheraStoneCircle

## Reusable Ancient Stone Circle. Place and move this in an authored hex.
## Gameplay identity stays on entity.stone_circle.
## Discovery is a 10 m horizontal disk (simulation y is ignored). The decal is
## visual only: 20 m across, 8 m tall, centred 2.4 m up. Picks are the stones,
## not a cylinder. The far-away eye aims at the crystal height and needs line
## of sight. Occupancy is the inner 3.2 m disk.

const DEFINITION_CIRCLE := "definition.stone_circle"

@export var discovery_radius: float = 10.0


func _ready() -> void:
	if definition_id == "":
		definition_id = DEFINITION_CIRCLE
	if entity_id == "":
		entity_id = "entity.stone_circle"
	populate(self, discovery_radius)
	super._ready()


static func populate(root: Node3D, aura_radius: float) -> void:
	if root.get_node_or_null("RingStone_0") != null:
		return
	var ring: float = 2.65
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0 + 0.12
		var stone := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.42 + 0.04 * float(i % 3), 0.92, 0.28 + 0.03 * float(i % 2))
		stone.name = "RingStone_%d" % i
		stone.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.46, 0.44, 0.40).darkened(0.04 * float(i % 3))
		mat.roughness = 0.92
		stone.material_override = mat
		stone.position = Vector3(cos(angle) * ring, box.size.y * 0.5, sin(angle) * ring)
		stone.rotation.y = angle + 0.35
		stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(stone)
	var center := MeshInstance3D.new()
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.22
	pillar.bottom_radius = 0.34
	pillar.height = 1.08
	center.mesh = pillar
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.40, 0.39, 0.36)
	center_mat.roughness = 0.9
	center.material_override = center_mat
	center.position.y = 0.54
	center.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(center)
	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.42, 0.78, 0.88)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.28, 0.72, 0.86)
	gem_mat.emission_energy_multiplier = 1.45
	gem_mat.roughness = 0.12
	gem_mat.metallic = 0.18
	var gem := MeshInstance3D.new()
	gem.name = "CrystalGem"
	var crystal := PrismMesh.new()
	crystal.size = Vector3(0.58, 0.96, 0.58)
	gem.mesh = crystal
	gem.material_override = gem_mat
	gem.position.y = 1.46
	root.add_child(gem)
	var gem_cross := MeshInstance3D.new()
	var crystal_cross := PrismMesh.new()
	crystal_cross.size = Vector3(0.42, 0.82, 0.42)
	gem_cross.mesh = crystal_cross
	gem_cross.material_override = gem_mat
	gem_cross.position.y = 1.42
	gem_cross.rotation.y = PI * 0.5
	root.add_child(gem_cross)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.55, 0.86, 0.95)
	lamp.light_energy = 1.15
	lamp.omni_range = 7.5
	lamp.shadow_enabled = false
	lamp.position.y = 1.62
	root.add_child(lamp)
	var aura := Decal.new()
	aura.name = "DiscoveryAura"
	var radius: float = maxf(aura_radius, 4.0)
	aura.size = Vector3(radius * 2.0, 8.0, radius * 2.0)
	aura.position.y = 2.4
	aura.texture_albedo = _discovery_ring_texture()
	aura.modulate = Color(0.52, 0.88, 0.96, 0.85)
	aura.albedo_mix = 0.85
	root.add_child(aura)


static func _discovery_ring_texture() -> Texture2D:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var center := Vector2(127.5, 127.5)
	for y in 256:
		for x in 256:
			var n: float = Vector2(x, y).distance_to(center) / 128.0
			var alpha := 0.0
			if n >= 0.84 and n <= 0.98:
				alpha = 1.0
			elif n > 0.80 and n < 0.84:
				alpha = (n - 0.80) / 0.04
			elif n > 0.98 and n < 1.0:
				alpha = 1.0 - (n - 0.98) / 0.02
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)
