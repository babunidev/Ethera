extends Node

# Harvested grass sinks fully out of sight. Filling it later raises it again.
const SINK_DEPTH := 0.58
const SINK_SECONDS := 0.7

var _visual: Node3D
var _pick: CollisionShape3D
var _rest_y := 0.0
var _amount := 0.0

func _ready() -> void:
	_visual = get_parent().find_child("GrassPatch", true, false) as Node3D
	_pick = get_parent().get_node_or_null("ContainerPick") as CollisionShape3D
	if _visual:
		_rest_y = _visual.position.y

func sync_sink(opened: bool, delta: float) -> void:
	if _visual == null:
		return
	var goal: float = 1.0 if opened else 0.0
	var step: float = delta / SINK_SECONDS if SINK_SECONDS > 0.0 else 1.0
	if _amount < goal:
		_amount = minf(goal, _amount + step)
	elif _amount > goal:
		_amount = maxf(goal, _amount - step)
	var t: float = _ease(_amount)
	_visual.position.y = _rest_y - SINK_DEPTH * t
	_visual.visible = t < 0.97
	if _pick:
		_pick.disabled = opened

func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
