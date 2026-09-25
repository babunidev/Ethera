extends Node

# One short visual acknowledgement of opening; never a persistent hinged pose.
const DURATION := 2.0
const SLIDE_DISTANCE := 0.16
const SLIDE_OUT_END := 0.85
const SLIDE_BACK_START := 1.15

var _pivot: Node3D
var _rest := Transform3D.IDENTITY
var _initialized := false
var _was_revealed := false
var _elapsed := DURATION

func _ready() -> void:
	_pivot = get_parent().find_child("LidPivot", true, false) as Node3D
	if _pivot:
		_rest = _pivot.transform

func sync_lid(contents_revealed: bool, delta: float) -> void:
	if _pivot == null:
		return
	if not _initialized:
		# Loading an already-discovered container must not replay its opening.
		_initialized = true
	elif contents_revealed and not _was_revealed:
		_elapsed = 0.0
	_was_revealed = contents_revealed
	_elapsed = minf(DURATION, _elapsed + maxf(delta, 0.0))
	var amount := 0.0
	if _elapsed < SLIDE_OUT_END:
		amount = _ease(_elapsed / SLIDE_OUT_END)
	elif _elapsed < SLIDE_BACK_START:
		amount = 1.0
	else:
		amount = 1.0 - _ease((_elapsed - SLIDE_BACK_START) / (DURATION - SLIDE_BACK_START))
	# Keep the entire disc, clasp and crystals level and return exactly to rest.
	_pivot.transform = _rest
	_pivot.position += Vector3.RIGHT * SLIDE_DISTANCE * amount

func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
