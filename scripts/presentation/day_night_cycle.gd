extends Node
class_name EtheraDayNight

## Presentation sky and sun. Ten minutes from midnight to midnight.
## Does not touch simulation time or gameplay.

const CYCLE_SECONDS := 600.0
const START_PHASE := 0.34
const MAX_ELEVATION := 0.92
const SUN_DISTANCE := 240.0
const SUN_SIZE := 7.5

var phase: float = START_PHASE
var living_glow: float = 1.0
var _sun: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _disc: MeshInstance3D
var _camera: Camera3D


func setup(sun: DirectionalLight3D, world_env: WorldEnvironment, camera: Camera3D) -> void:
	_sun = sun
	_camera = camera
	if world_env == null:
		return
	if world_env.environment == null:
		world_env.environment = Environment.new()
	_env = world_env.environment
	_env.background_mode = Environment.BG_SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_density = 0.0008
	_env.fog_aerial_perspective = 0.35
	_env.fog_sky_affect = 0.55
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_curve = 0.08
	_sky_mat.ground_curve = 0.12
	sky.sky_material = _sky_mat
	_env.sky = sky
	_ensure_disc()
	apply_phase(phase)


func advance(delta: float) -> void:
	if CYCLE_SECONDS <= 0.0:
		return
	apply_phase(phase + delta / CYCLE_SECONDS)


func apply_phase(value: float) -> void:
	phase = value - floorf(value)
	var look: Dictionary = _look(phase)
	var elevation: float = sin((phase - 0.25) * TAU) * MAX_ELEVATION
	var azimuth: float = TAU * 0.25 + phase * TAU
	var sun_dir := Vector3(cos(elevation) * sin(azimuth), sin(elevation), cos(elevation) * cos(azimuth)).normalized()
	if _sun != null:
		var above: float = clampf((sun_dir.y + 0.02) / 0.12, 0.0, 1.0)
		_sun.light_color = look.sun
		_sun.light_energy = float(look.sun_energy) * above
		_sun.shadow_enabled = above > 0.04
		_sun.look_at(_sun.global_position - sun_dir)
	if _env != null:
		_env.ambient_light_color = look.ambient
		_env.ambient_light_energy = float(look.ambient_energy)
		_env.fog_light_color = look.fog
		_env.background_color = look.horizon
	if _sky_mat != null:
		_sky_mat.sky_top_color = look.sky_top
		_sky_mat.sky_horizon_color = look.horizon
		_sky_mat.ground_horizon_color = look.horizon
		_sky_mat.ground_bottom_color = look.ground
		_sky_mat.energy_multiplier = float(look.sky_energy)
	living_glow = clampf(smoothstep(0.10, 0.85, float(look.sun_energy)), 0.0, 1.0)
	_place_disc(sun_dir, look)
	apply_living_stone_glow()


func apply_living_stone_glow() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("ethera_living_stone"):
		var mesh := node as MeshInstance3D
		if mesh == null:
			continue
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			continue
		var authored: float = float(mesh.get_meta("living_stone_glow", 0.62))
		mat.emission_energy_multiplier = authored * living_glow


func _place_disc(sun_dir: Vector3, look: Dictionary) -> void:
	if _disc == null:
		return
	var origin: Vector3 = _camera.global_position if _camera != null else Vector3.ZERO
	_disc.global_position = origin + sun_dir * SUN_DISTANCE
	_disc.scale = Vector3.ONE * SUN_SIZE
	var above: float = clampf((sun_dir.y + 0.04) / 0.18, 0.0, 1.0)
	_disc.visible = above > 0.02
	var mat: StandardMaterial3D = _disc.material_override as StandardMaterial3D
	if mat != null:
		var glow: Color = look.sun
		mat.albedo_color = glow
		mat.emission = glow
		mat.emission_energy_multiplier = 3.4 * above


func _ensure_disc() -> void:
	if _disc != null:
		return
	_disc = MeshInstance3D.new()
	_disc.name = "SunDisc"
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_disc.mesh = mesh
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.disable_fog = true
	mat.disable_receive_shadows = true
	_disc.material_override = mat
	add_child(_disc)


func _look(at: float) -> Dictionary:
	var keys: Array[Dictionary] = [
		{"t": 0.00, "sun_energy": 0.05, "ambient_energy": 0.14, "sky_energy": 0.22, "sun": Color(0.28, 0.36, 0.62), "ambient": Color(0.10, 0.12, 0.20), "sky_top": Color(0.03, 0.05, 0.10), "horizon": Color(0.07, 0.09, 0.16), "ground": Color(0.04, 0.04, 0.05), "fog": Color(0.06, 0.07, 0.12)},
		{"t": 0.22, "sun_energy": 0.22, "ambient_energy": 0.22, "sky_energy": 0.55, "sun": Color(1.00, 0.48, 0.28), "ambient": Color(0.62, 0.32, 0.24), "sky_top": Color(0.18, 0.22, 0.42), "horizon": Color(0.92, 0.46, 0.28), "ground": Color(0.16, 0.10, 0.08), "fog": Color(0.72, 0.38, 0.26)},
		{"t": 0.30, "sun_energy": 0.85, "ambient_energy": 0.36, "sky_energy": 0.95, "sun": Color(1.00, 0.78, 0.52), "ambient": Color(0.86, 0.62, 0.46), "sky_top": Color(0.38, 0.52, 0.78), "horizon": Color(1.00, 0.72, 0.48), "ground": Color(0.28, 0.22, 0.16), "fog": Color(0.90, 0.70, 0.52)},
		{"t": 0.42, "sun_energy": 1.12, "ambient_energy": 0.40, "sky_energy": 1.08, "sun": Color(1.00, 0.94, 0.82), "ambient": Color(0.82, 0.78, 0.70), "sky_top": Color(0.38, 0.58, 0.86), "horizon": Color(0.72, 0.80, 0.90), "ground": Color(0.32, 0.28, 0.22), "fog": Color(0.70, 0.78, 0.86)},
		{"t": 0.52, "sun_energy": 1.18, "ambient_energy": 0.42, "sky_energy": 1.12, "sun": Color(1.00, 0.96, 0.88), "ambient": Color(0.84, 0.80, 0.72), "sky_top": Color(0.36, 0.58, 0.88), "horizon": Color(0.70, 0.80, 0.92), "ground": Color(0.30, 0.28, 0.22), "fog": Color(0.68, 0.78, 0.88)},
		{"t": 0.64, "sun_energy": 1.00, "ambient_energy": 0.38, "sky_energy": 1.00, "sun": Color(1.00, 0.86, 0.64), "ambient": Color(0.84, 0.70, 0.52), "sky_top": Color(0.34, 0.50, 0.76), "horizon": Color(0.90, 0.70, 0.48), "ground": Color(0.30, 0.24, 0.16), "fog": Color(0.84, 0.66, 0.46)},
		{"t": 0.74, "sun_energy": 0.55, "ambient_energy": 0.28, "sky_energy": 0.72, "sun": Color(1.00, 0.46, 0.24), "ambient": Color(0.70, 0.36, 0.26), "sky_top": Color(0.22, 0.24, 0.42), "horizon": Color(0.88, 0.38, 0.22), "ground": Color(0.18, 0.10, 0.08), "fog": Color(0.70, 0.32, 0.20)},
		{"t": 0.84, "sun_energy": 0.08, "ambient_energy": 0.16, "sky_energy": 0.28, "sun": Color(0.32, 0.38, 0.62), "ambient": Color(0.12, 0.14, 0.22), "sky_top": Color(0.05, 0.07, 0.14), "horizon": Color(0.12, 0.12, 0.22), "ground": Color(0.05, 0.05, 0.06), "fog": Color(0.08, 0.09, 0.14)},
		{"t": 1.00, "sun_energy": 0.05, "ambient_energy": 0.14, "sky_energy": 0.22, "sun": Color(0.28, 0.36, 0.62), "ambient": Color(0.10, 0.12, 0.20), "sky_top": Color(0.03, 0.05, 0.10), "horizon": Color(0.07, 0.09, 0.16), "ground": Color(0.04, 0.04, 0.05), "fog": Color(0.06, 0.07, 0.12)},
	]
	var a: Dictionary = keys[0]
	var b: Dictionary = keys[keys.size() - 1]
	for i in range(keys.size() - 1):
		if at >= float(keys[i].t) and at <= float(keys[i + 1].t):
			a = keys[i]
			b = keys[i + 1]
			break
	var span: float = maxf(float(b.t) - float(a.t), 0.0001)
	var w: float = clampf((at - float(a.t)) / span, 0.0, 1.0)
	return {
		"sun_energy": lerpf(float(a.sun_energy), float(b.sun_energy), w),
		"ambient_energy": lerpf(float(a.ambient_energy), float(b.ambient_energy), w),
		"sky_energy": lerpf(float(a.sky_energy), float(b.sky_energy), w),
		"sun": (a.sun as Color).lerp(b.sun as Color, w),
		"ambient": (a.ambient as Color).lerp(b.ambient as Color, w),
		"sky_top": (a.sky_top as Color).lerp(b.sky_top as Color, w),
		"horizon": (a.horizon as Color).lerp(b.horizon as Color, w),
		"ground": (a.ground as Color).lerp(b.ground as Color, w),
		"fog": (a.fog as Color).lerp(b.fog as Color, w),
	}
