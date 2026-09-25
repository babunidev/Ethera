extends Node3D
class_name EtheraDivineOrientation

const _Orientation := preload("res://scripts/simulation/ethera_orientation.gd")
const _SHADE_SHADER := preload("res://scripts/presentation/orientation_shade.gdshader")

# Intermittent ground signs toward the active objective. One cue about every
# ten seconds, either a wind-shade or a glint. Not a path, arrow, or marker.
# The shade is draped on the terrain, just beside her, and slides
# parallel to the bearing. The glint is a one-meter omni light a step ahead.

const WIND_LENGTH := 4.0
const WIND_BREADTH := 2.0
const WIND_ALONG := 12
const WIND_ACROSS := 5
const WIND_LIFT := 0.16
const GLINT_ENERGY := 6.0
const GLINT_RANGE := 0.33
const GLINT_HEIGHT := 0.28

var game: Node = null
var _elapsed_ms: float = 0.0
var _cue_index: int = 0
var _armed := false
var _cue: Node3D = null
var _cue_kind: String = ""
var _cue_age_ms: float = 0.0
var _cue_life_ms: float = 1600.0
var _cue_from: Vector3 = Vector3.ZERO
var _cue_to: Vector3 = Vector3.ZERO
var _wave_right: Vector3 = Vector3.RIGHT
var _wave_forward: Vector3 = Vector3.FORWARD
var _glint_light: OmniLight3D = null


func _process(delta: float) -> void:
	if game == null or game.simulation == null:
		return
	var guide: Dictionary = game.simulation.query_orientation()
	if not bool(guide.get("active", false)):
		_clear_cue()
		_elapsed_ms = 0.0
		_armed = false
		return
	if not _armed:
		_elapsed_ms = float(guide.get("cue_interval_ms", 10000))
		_armed = true
	_elapsed_ms += delta * 1000.0
	var interval: float = float(guide.get("cue_interval_ms", 10000))
	if _cue == null and _elapsed_ms >= interval:
		_elapsed_ms -= interval
		_spawn(guide, _Orientation.cue_kind(_cue_index))
		_cue_index += 1
	_advance_cue(delta, guide)


func _spawn(guide: Dictionary, kind: String) -> void:
	_clear_cue()
	_cue_kind = kind
	var origin := Vector3(float(guide.get("actor_x", 0.0)), 0.0, float(guide.get("actor_z", 0.0)))
	var bearing: float = float(guide.get("bearing", 0.0))
	var direction := Vector3(sin(bearing), 0.0, cos(bearing))
	if direction.length_squared() < 0.0001:
		direction = Vector3(0.0, 0.0, 1.0)
	direction = direction.normalized()
	if kind == _Orientation.CUE_GLINT:
		var ahead: float = float(guide.get("glint_ahead", 14.0))
		var travel: float = float(guide.get("glint_travel", 3.0))
		_cue_from = origin + direction * ahead
		_cue_to = _cue_from + direction * travel
		var spark := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.02
		sphere.height = 0.04
		spark.mesh = sphere
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.disable_receive_shadows = true
		material.albedo_color = Color(1.0, 0.94, 0.7, 0.0)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.9, 0.55)
		material.emission_energy_multiplier = 0.0
		spark.material_override = material
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.9, 0.55)
		light.light_energy = 0.0
		light.light_indirect_energy = 0.0
		light.light_specular = 0.35
		light.shadow_enabled = false
		light.omni_range = GLINT_RANGE
		light.omni_attenuation = 0.85
		light.position = Vector3(0.0, 0.12, 0.0)
		spark.add_child(light)
		_glint_light = light
		_cue = spark
	else:
		var aside: float = float(guide.get("wave_aside", 5.0))
		var travel: float = float(guide.get("wave_travel", 5.0))
		var right := Vector3.UP.cross(direction)
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		right = right.normalized()
		if _cue_index % 2 != 0:
			right = -right
		_wave_right = right
		_wave_forward = direction
		var center: Vector3 = origin + right * aside
		_cue_from = center - direction * (travel * 0.5)
		_cue_to = center + direction * (travel * 0.5)
		var shade := MeshInstance3D.new()
		shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shade.extra_cull_margin = 4.0
		var material := ShaderMaterial.new()
		material.shader = _SHADE_SHADER
		material.set_shader_parameter("strength", 0.0)
		shade.material_override = material
		_cue = shade
	_cue_from = _seat(_cue_from)
	_cue_to = _seat(_cue_to)
	_cue_life_ms = float(guide.get("cue_life_ms", 1600))
	_cue_age_ms = 0.0
	add_child(_cue)
	if kind == _Orientation.CUE_GLINT:
		_cue.global_position = _cue_from
	else:
		_drape_wave(_cue_from)
	var sign: String = "Ground Glint" if kind == _Orientation.CUE_GLINT else "Ground Wind-Wave"
	if game.simulation != null and game.simulation.has_method("development_note"):
		game.simulation.development_note("orientation", "Divine Orientation: %s" % sign)


func _advance_cue(delta: float, _guide: Dictionary) -> void:
	if _cue == null:
		return
	_cue_age_ms += delta * 1000.0
	var life: float = maxf(_cue_life_ms, 1.0)
	var t: float = clampf(_cue_age_ms / life, 0.0, 1.0)
	var center: Vector3 = _cue_from.lerp(_cue_to, t)
	if _cue_kind == _Orientation.CUE_GLINT:
		_cue.global_position = Vector3(center.x, _ground(center.x, center.z) + GLINT_HEIGHT, center.z)
		var presence: float = sin(t * PI)
		presence *= presence
		if _glint_light != null:
			_glint_light.light_energy = presence * GLINT_ENERGY
		var spark: MeshInstance3D = _cue as MeshInstance3D
		if spark != null:
			var material: StandardMaterial3D = spark.material_override as StandardMaterial3D
			if material != null:
				var color: Color = material.albedo_color
				color.a = presence
				material.albedo_color = color
				material.emission_energy_multiplier = presence * 2.0
	else:
		_drape_wave(center)
		var shade: ShaderMaterial = (_cue as MeshInstance3D).material_override as ShaderMaterial
		if shade != null:
			shade.set_shader_parameter("strength", sin(t * PI) * 0.55)
	if t >= 1.0:
		_clear_cue()


func _drape_wave(center: Vector3) -> void:
	var shade: MeshInstance3D = _cue as MeshInstance3D
	if shade == null:
		return
	shade.global_position = center
	shade.basis = Basis.IDENTITY
	var columns: int = WIND_ACROSS + 1
	var rows: int = WIND_ALONG + 1
	var points: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	points.resize(columns * rows)
	uvs.resize(columns * rows)
	for row in rows:
		var along: float = float(row) / float(WIND_ALONG) - 0.5
		for column in columns:
			var across: float = float(column) / float(WIND_ACROSS) - 0.5
			var flat: Vector3 = center + _wave_right * (across * WIND_BREADTH) + _wave_forward * (along * WIND_LENGTH)
			var normal: Vector3 = _surface_normal(flat.x, flat.z)
			var lifted: Vector3 = Vector3(flat.x, _ground(flat.x, flat.z), flat.z) + normal * WIND_LIFT
			var index: int = row * columns + column
			points[index] = shade.to_local(lifted)
			uvs[index] = Vector2(float(column) / float(WIND_ACROSS), float(row) / float(WIND_ALONG))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in WIND_ALONG:
		for column in WIND_ACROSS:
			var a: int = row * columns + column
			var b: int = a + 1
			var c: int = a + columns
			var d: int = c + 1
			_add_corner(tool, points[a], uvs[a])
			_add_corner(tool, points[c], uvs[c])
			_add_corner(tool, points[b], uvs[b])
			_add_corner(tool, points[b], uvs[b])
			_add_corner(tool, points[c], uvs[c])
			_add_corner(tool, points[d], uvs[d])
	shade.mesh = tool.commit()


func _add_corner(tool: SurfaceTool, point: Vector3, uv: Vector2) -> void:
	tool.set_uv(uv)
	tool.add_vertex(point)


func _seat(point: Vector3) -> Vector3:
	point.y = _ground(point.x, point.z)
	return point


func _ground(x: float, z: float) -> float:
	if game != null and game.has_method("terrain_height"):
		return float(game.terrain_height(x, z))
	return 0.0


func _surface_normal(x: float, z: float) -> Vector3:
	if game != null and game.has_method("terrain_normal"):
		var normal: Vector3 = game.terrain_normal(x, z)
		if normal.length_squared() > 0.001:
			return normal.normalized()
	return Vector3.UP


func _clear_cue() -> void:
	if _cue != null:
		_cue.queue_free()
		_cue = null
		_cue_kind = ""
		_glint_light = null
