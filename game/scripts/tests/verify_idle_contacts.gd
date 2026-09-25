extends SceneTree

var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
	else:
		print("PASS: ", message)

func run() -> void:
	var model = load("res://assets/models/khar_morr.glb").instantiate()
	root.add_child(model)
	var player: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	var names := player.get_animation_list()
	print("IDLE-LIKE: ", names)
	for clip in ["Idle", "IdleWait", "IdleFoldArms", "IdleLookAround"]:
		check(names.has(clip), clip + " imported as authored rest")
		if names.has(clip):
			check(player.get_animation(clip).length > 1.0, clip + " keeps its duration")
			player.play(clip, 0)
			player.seek(0.0, true)
			player.seek(player.get_animation(clip).length * 0.5, true)
	check(not names.has("Idle2"), "Repaired Idle2 stand-in is gone")
	check(not names.has("swagger"), "Traveling swagger is not an idle")
	print("Idle-like clip validation: ", failed, " failures")
	model.queue_free()
	quit(1 if failed else 0)
