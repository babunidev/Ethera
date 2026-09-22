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


func _ready() -> void:
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
	_play_idle(0.0, true)


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var offset := _body.global_position - _previous_position
	_previous_position = _body.global_position
	offset.y = 0.0
	# Initial placement / large corrections must not appear as a sprint.
	if offset.length() > 0.5:
		_speed = 0.0
		return
	_speed = lerpf(_speed, offset.length() / delta, 1.0 - exp(-6.0 * delta))
	var moving := _speed > (0.06 if _locomotion != "idle" else 0.12)
	var want := "idle"
	if moving:
		var run_at := 3.0 if _locomotion == "run" else 3.5
		want = "run" if _speed > run_at and _run != &"" else "walk"
	if want != _locomotion:
		_locomotion = want
		match _locomotion:
			"walk":
				if _walk != &"":
					_player.play(_walk, 0.22)
			"run":
				_player.play(_run, 0.28)
			_:
				_play_idle(0.26)
	# Locomotion clips are in-place. Only cadence changes, never the simulation's speed.
	if _locomotion == "walk":
		_player.speed_scale = clampf(_speed / 1.4, 0.4, 2.0)
	elif _locomotion == "run":
		_player.speed_scale = clampf(_speed / 4.8, 0.6, 1.35)
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


func _pick_idle() -> StringName:
	if _idles.is_empty():
		return &""
	var choices: Array[StringName] = []
	for clip in _idles:
		if clip != _last_idle or _idles.size() == 1:
			choices.append(clip)
	return choices[randi() % choices.size()]
