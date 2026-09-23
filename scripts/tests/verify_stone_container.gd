extends SceneTree

var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failed += 1
		push_error(message)

func lid_open(sim) -> bool:
	for entity in sim.query_world_view().get("entities", []):
		if entity.get("id") == "entity.container":
			return bool(entity.get("container_lid_open", false))
	return false

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene._sync_views(0.0)
	var body: Node3D = scene.views["entity.container"]
	var pivot: Node3D = body.find_child("LidPivot", true, false)
	check(pivot != null, "Smooth stone container and lid pivot imported")
	if pivot == null:
		quit(1)
		return
	check(body.find_child("GrownStoneBasin", true, false) != null, "Basin replaces placeholder")
	check(body.find_child("CentralClaspGem", true, false) != null, "Clasp gem imported")
	var closed: Quaternion = pivot.quaternion
	var rest_position: Vector3 = pivot.position
	check(not lid_open(scene.simulation), "Container begins closed")
	var container_at: Vector3 = scene.simulation.world.position_of(scene.simulation.world.get_entity("entity.container"))
	scene.simulation.world.set_position("entity.khar_morr", container_at + Vector3(2.5, 0.0, 0.0))
	scene.simulation.apply({"type":"open_container", "target_id":"entity.container"})
	for i in range(500):
		scene.simulation.apply({"type":"tick"})
		if lid_open(scene.simulation):
			break
	check(lid_open(scene.simulation), "Opening exposes lid state through public query")
	var open_snapshot: Dictionary = scene.simulation.create_snapshot()
	scene._sync_views(0.1)
	check(pivot.position.x > rest_position.x and pivot.position.x < rest_position.x + 0.03, "Disc starts sliding gradually")
	for i in range(54):
		scene._sync_views(1.0/60.0)
	check(absf(pivot.position.x-rest_position.x-0.16)<0.001, "Disc slides a little sideways at the midpoint")
	check(closed.angle_to(pivot.quaternion)<0.001, "Disc stays level instead of hinging upward")
	for i in range(66):
		scene._sync_views(1.0/60.0)
	check(pivot.position.distance_to(rest_position)<0.001, "Disc closes automatically after two seconds before pickup")
	for i in range(180):
		scene._sync_views(1.0/60.0)
	check(pivot.position.distance_to(rest_position)<0.001, "Unclaimed contents do not repeat the slide")
	scene.simulation.apply({"type":"pickup_item", "item_id":"entity.club.green"})
	for i in range(500):
		scene.simulation.apply({"type":"tick"})
		if not lid_open(scene.simulation):
			break
	check(not lid_open(scene.simulation), "Taking the club clears the reveal signal")
	scene._sync_views(0.1)
	check(pivot.position.distance_to(rest_position)<0.001, "Later pickup does not repeat the animation")
	for i in range(120):
		scene._sync_views(1.0/60.0)
	check(closed.angle_to(pivot.quaternion)<0.001, "Lid settles fully closed after pickup")
	scene.simulation.apply({"type":"pickup_item", "item_id":"entity.club.umber"})
	for i in range(500):
		scene.simulation.apply({"type":"tick"})
	check(not lid_open(scene.simulation), "Dropping the former contents during a swap does not reopen the lid")
	# Snapshot restore must retain the distinction between discovered and emptied.
	check(scene.simulation.restore_snapshot(open_snapshot), "Open-container snapshot restores")
	check(lid_open(scene.simulation), "Restored snapshot retains unclaimed contents")
	var saved_hash: String = scene.simulation.state_hash()
	for i in range(120):
		scene._sync_views(1.0/60.0)
	check(saved_hash == scene.simulation.state_hash(), "Lid animation never changes simulation state")
	# Exercise the same exported lid at different rendering rates; a quick pickup
	# must not interrupt the return, and loading a revealed container stays closed.
	for fps in [30, 60, 144]:
		var model = load("res://assets/models/stone_container.glb").instantiate()
		root.add_child(model)
		var control := Node.new()
		control.set_script(load("res://scripts/presentation/stone_container_lid.gd"))
		model.add_child(control)
		var disc: Node3D = model.find_child("LidPivot", true, false)
		var initial: Transform3D = disc.transform
		control.sync_lid(true, 0.0)
		check(disc.transform.is_equal_approx(initial), "Restored container rests closed")
		control.sync_lid(false, 0.0)
		control.sync_lid(true, 0.0)
		for frame in range(fps * 2 + 1):
			control.sync_lid(frame < fps / 10, 1.0 / fps)
		check(disc.transform.is_equal_approx(initial), "Quick pickup returns lid at %s fps" % fps)
		model.queue_free()
	scene.queue_free()
	print("Stone container validation: ", failed, " failures")
	quit(1 if failed else 0)
