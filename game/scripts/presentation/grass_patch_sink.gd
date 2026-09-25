extends Node

# Harvested grass sinks fully out of sight. Filling it later raises it again.
const SINK_DEPTH := 0.58
const SINK_SECONDS := 0.7

var _visual: Node3D
var _pick: CollisionShape3D
var _rest_y := 0.0
var _depth := SINK_DEPTH
var _amount := 0.0

func _ready() -> void:
	_visual = get_parent().find_child("GrassPatch", true, false) as Node3D
	_pick = get_parent().get_node_or_null("ContainerPick") as CollisionShape3D
	if _visual:
		_rest_y = _visual.position.y
		_depth = maxf(SINK_DEPTH, _visual_height(_visual) + 0.08)

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
	_visual.position.y = _rest_y - _depth * t
	_visual.visible = t < 0.97
	if _pick:
		_pick.disabled = opened

func _visual_height(visual: Node3D) -> float:
	var min_y := INF
	var max_y := -INF
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
	if visual is MeshInstance3D:
		meshes.append(visual)
	for mesh_node in meshes:
		var mesh := mesh_node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var to_visual := Transform3D.IDENTITY
		var current: Node = mesh
		while current != null and current != visual:
			if current is Node3D:
				to_visual = (current as Node3D).transform * to_visual
			current = current.get_parent()
		var placed: AABB = to_visual * mesh.get_aabb()
		min_y = minf(min_y, placed.position.y)
		max_y = maxf(max_y, placed.position.y + placed.size.y)
	if min_y >= INF:
		return SINK_DEPTH
	return max_y - min_y


func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
