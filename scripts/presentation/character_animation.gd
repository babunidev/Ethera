extends Node
## Visual-only locomotion. The existing controller owns all movement and game rules.

var _body: Node3D
var _player: AnimationPlayer
var _previous_position := Vector3.ZERO
var _speed := 0.0
var _locomotion := "idle"
var _idles: Array[StringName] = []
var _walk: StringName
var _run: StringName
var _last_idle: StringName = &""
var _pickup: StringName = &""
var _pickup_until_ms := 0
var _pickup_anchor := Vector3.ZERO
const _PICKUP_KEYS := "res://data/presentation/unarmed_pickup.json"
const _PICKUP_SPEED := 0.8


func _ready() -> void:
	process_priority = -20
	_body = get_parent() as Node3D
	_previous_position = _body.global_position
	var players := _body.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		set_process(false)
		return
	_player = players[0] as AnimationPlayer
	for clip in _player.get_animation_list():
		var short_name := String(clip).get_slice("/", String(clip).get_slice_count("/") - 1)
		if short_name == "Walk":
			_walk = clip
			_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		elif short_name == "Run":
			_run = clip
			_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		elif short_name.begins_with("Idle"):
			_idles.append(clip)
			_player.get_animation(clip).loop_mode = Animation.LOOP_NONE
	_player.animation_finished.connect(_on_animation_finished)
	_install_pickup()
	_play_idle(0.0, true)


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var offset := _body.global_position - _previous_position
	_previous_position = _body.global_position
	offset.y = 0.0
	# Initial placement / large corrections must not appear as a sprint.
	if offset.length() > 0.5 and _pickup_until_ms <= 0:
		_speed = 0.0
		return
	if _pickup_until_ms > 0:
		var drifted: bool = _body.global_position.distance_to(_pickup_anchor) > 0.45
		if Time.get_ticks_msec() < _pickup_until_ms and not drifted:
			_speed = 0.0
			_player.speed_scale = _PICKUP_SPEED
			return
		_pickup_until_ms = 0
	_speed = lerpf(_speed, offset.length() / delta, 1.0 - exp(-6.0 * delta))
	var moving := _speed > (0.06 if _locomotion != "idle" else 0.12)
	var want := "idle"
	if moving:
		var run_at := 2.25 if _locomotion == "run" else 3.05
		want = "run" if _speed > run_at and _run != &"" else "walk"
	if want != _locomotion:
		_locomotion = want
		match _locomotion:
			"walk":
				if _walk != &"":
					_player.play(_walk, 0.42)
			"run":
				_player.play(_run, 0.48)
			_:
				_play_idle(0.34)
	# Locomotion clips are in-place. Only cadence changes, never the simulation's speed.
	if _locomotion == "walk":
		_player.speed_scale = clampf(_speed / 1.92, 0.45, 1.2)
	elif _locomotion == "run":
		_player.speed_scale = clampf(_speed / 4.16, 0.7, 1.12)
	else:
		_player.speed_scale = 1.0


func _on_animation_finished(_anim_name: StringName) -> void:
	if _locomotion != "idle":
		return
	_play_idle(0.22)


func _play_idle(blend: float, first: bool = false) -> void:
	var clip := _idles[0] if first and not _idles.is_empty() else _pick_idle()
	if clip != &"":
		_last_idle = clip
		_player.play(clip, blend)


func play_pickup() -> void:
	if _player == null or _pickup == &"":
		return
	var clip: Animation = _player.get_animation(_pickup)
	_pickup_until_ms = Time.get_ticks_msec() + int(clip.length / _PICKUP_SPEED * 1000.0)
	_pickup_anchor = _body.global_position
	_speed = 0.0
	_locomotion = "idle"
	_player.play(_pickup, 0.12)
	_player.speed_scale = _PICKUP_SPEED


func _install_pickup() -> void:
	var target: Skeleton3D = _skeleton()
	if target == null or not FileAccess.file_exists(_PICKUP_KEYS):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_PICKUP_KEYS))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var baked := Animation.new()
	baked.length = float(parsed.get("length", 1.0))
	baked.loop_mode = Animation.LOOP_NONE
	var bones: Dictionary = parsed.get("bones", {})
	for short_name in bones.keys():
		var bone_name := _mixamo_bone(target, str(short_name))
		if bone_name == "":
			continue
		var rest := target.get_bone_rest(target.find_bone(bone_name)).basis.get_rotation_quaternion()
		var rot := baked.add_track(Animation.TYPE_ROTATION_3D)
		baked.track_set_path(rot, NodePath("%s:%s" % [_track_prefix(bone_name), bone_name]))
		baked.track_set_interpolation_type(rot, Animation.INTERPOLATION_LINEAR)
		for key in bones[short_name]:
			if typeof(key) != TYPE_ARRAY or key.size() < 5:
				continue
			var delta := Quaternion(float(key[1]), float(key[2]), float(key[3]), float(key[4]))
			baked.rotation_track_insert_key(rot, float(key[0]), rest * delta)
	var hip_name := _mixamo_bone(target, "Hips")
	var drops: Array = parsed.get("hips_y", [])
	if hip_name != "" and not drops.is_empty():
		var hip_rest: Vector3 = target.get_bone_rest(target.find_bone(hip_name)).origin
		var pos := baked.add_track(Animation.TYPE_POSITION_3D)
		baked.track_set_path(pos, NodePath("%s:%s" % [_track_prefix(hip_name), hip_name]))
		baked.track_set_interpolation_type(pos, Animation.INTERPOLATION_LINEAR)
		for key in drops:
			if typeof(key) != TYPE_ARRAY or key.size() < 2:
				continue
			baked.position_track_insert_key(pos, float(key[0]), hip_rest + Vector3(0.0, float(key[1]), 0.0))
	if baked.get_track_count() == 0:
		return
	var library := AnimationLibrary.new()
	library.add_animation("Pickup", baked)
	_player.add_animation_library("pickup", library)
	_pickup = &"pickup/Pickup"


func _mixamo_bone(skeleton: Skeleton3D, short_name: String) -> String:
	for index in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(index)
		if bone_name == short_name or bone_name.ends_with(":" + short_name) or bone_name.ends_with("_" + short_name):
			return bone_name
	return ""


func _track_prefix(bone_name: String) -> String:
	var sample_name: StringName = _walk if _walk != &"" else (_idles[0] if not _idles.is_empty() else &"")
	if sample_name == &"":
		return "Skeleton3D"
	var sample: Animation = _player.get_animation(sample_name)
	var needle := ":" + bone_name
	for index in sample.get_track_count():
		var path := str(sample.track_get_path(index))
		if path.ends_with(needle):
			return path.substr(0, path.length() - needle.length())
	return "Skeleton3D"


func _skeleton_of(root: Node) -> Skeleton3D:
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	return skeletons[0] if not skeletons.is_empty() else null


func _skeleton() -> Skeleton3D:
	return _skeleton_of(_body)


func _pick_idle() -> StringName:
	if _idles.is_empty():
		return &""
	var choices: Array[StringName] = []
	for clip in _idles:
		if clip != _last_idle or _idles.size() == 1:
			choices.append(clip)
	return choices[randi() % choices.size()]
