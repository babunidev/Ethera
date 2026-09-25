extends RefCounted
class_name EtheraSimulationTests

const _Orientation := preload("res://scripts/simulation/ethera_orientation.gd")

# A crashing script still lets assertions be skipped rather than fail, so a floor on the
# assertion count turns a mass failure into a reported failure instead of a short pass.
const MINIMUM_ASSERTIONS := 200

var _failed: Array[String] = []
var _passed: int = 0

func run() -> int:
	_test_starting_data()
	_test_adopt_authored_placements()
	_test_adopt_scenery_blockers()
	_test_landscape_and_herb()
	_test_fixed_clock()
	_test_determinism_and_quantization()
	_test_knowledge_stays_authoritative()
	_test_snapshot_hash_and_restore()
	_test_command_journal_replays()
	_test_skill_inputs_are_timestamped()
	_test_item_commits_immediately()
	_test_walking()
	_test_walk_to_object_does_not_interact()
	_test_run_uses_run_speed()
	_test_occupancy_blocks_walking()
	_test_walkable_slope()
	_test_fountain_approach_from_any_side()
	_test_shape_weapon_approach_from_any_side()
	_test_sheath_pose()
	_test_item_handoff()
	_test_club_presentation_variants()
	_test_character_pick_volume()
	_test_fountain_pick_follows_visual()
	_test_focus_hold_slows_pace()
	_test_shape_trace_timeout_and_success()
	_test_right_click_cancels_approach()
	_test_pickup_walks_into_reach()
	_test_pickup_and_container_shards()
	_test_place_discovery()
	_test_make_offering()
	_test_long_walk_approaches_first()
	_test_walk_goes_around_a_solid()
	_test_pickup_swap_and_occupied_shaping()
	_test_echo_imprint_and_event_distribution()
	_test_echo_imprint_shares_up_to_three()
	_test_a_third_interaction_needs_no_result_code()
	_test_authored_results_fail_closed()
	_test_availability_and_historical_resolution()
	_test_blockers_and_injury()
	_test_radial_selection()
	_test_event_envelope_and_logs()
	_test_stone_weapon_need()
	_test_trakia_vorr_and_greeting()
	_test_spectate_and_inhabit()
	_test_delivery_objective_follows_capability()
	_test_village_delivery()
	var total: int = _passed + _failed.size()
	if total < MINIMUM_ASSERTIONS:
		_failed.append("only %d assertions ran; expected at least %d, so something aborted early" % [total, MINIMUM_ASSERTIONS])
	print("Ethera simulation tests: %d passed, %d failed" % [_passed, _failed.size()])
	for message in _failed:
		printerr("FAIL: %s" % message)
	return _failed.size()


func _test_starting_data() -> void:
	var sim := _new_sim()
	var panel: Dictionary = sim.query_panel()
	_eq("start name", panel.get("name"), "Khar-Morr the First Carved")
	_eq("start people", panel.get("people"), "grimnir")
	_eq("start sex", panel.get("sex"), "female")
	_eq("start shards empty", (panel.get("known_shards", []) as Array).size(), 0)
	_eq("start has no automatic need", (panel.get("needs", []) as Array).size(), 0)
	_eq("start has no automatic task", str(panel.get("active_task_id", "")), "")
	_eq("start small weapon empty", bool(panel.get("equipment", {}).get(EtheraIds.SLOT_SMALL_WEAPON, {}).get("empty", false)), true)
	_eq("start herb empty", bool(panel.get("equipment", {}).get(EtheraIds.SLOT_HERB, {}).get("empty", false)), true)
	var regions: Dictionary = panel.get("body_regions", {})
	for region_id in [EtheraIds.BODY_HEAD, EtheraIds.BODY_TORSO, EtheraIds.BODY_ARMS, EtheraIds.BODY_LEGS]:
		_eq("healthy %s" % region_id, str(regions.get(region_id, {}).get("condition", "")), "healthy")
	_eq("body region carries its authored name", str(regions.get(EtheraIds.BODY_ARMS, {}).get("name", "")), "Arms")
	var trait_ids := _ids(panel.get("traits", []))
	_true("has grimnir", trait_ids.has(EtheraIds.TRAIT_GRIMNIR))
	_true("has female", trait_ids.has(EtheraIds.TRAIT_FEMALE))
	_true("has weapon shaping", trait_ids.has(EtheraIds.TRAIT_WEAPON_SHAPING))
	_true("has echo imprint", trait_ids.has(EtheraIds.TRAIT_ECHO_IMPRINT))
	_eq("no interactions are recorded before she uses one", (panel.get("known_interactions", []) as Array).size(), 0)
	_eq("start states empty", (panel.get("states", []) as Array).size(), 0)
	var fountain: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)
	_eq("fountain shards empty", sim.world.known_shards(fountain).size(), 0)
	_true("fountain has echo", sim.world.has_trait(fountain, EtheraIds.TRAIT_ECHO))
	_true("rock manifested", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_ROCK)))
	_eq("inhabiting khar-morr", sim.world.inhabited_entity_id, EtheraIds.ENTITY_KHAR_MORR)
	var fountain_radius := 0.0
	var club_radius := -1.0
	for entity in sim.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == EtheraIds.ENTITY_FOUNTAIN:
			fountain_radius = float(entity.get("occupancy_radius", 0.0))
		if str(entity.get("id", "")) == EtheraIds.ENTITY_CLUB_UMBER:
			club_radius = float(entity.get("occupancy_radius", -1.0))
	_eq("presentation sees Fountain occupancy", fountain_radius, 2.5)
	_eq("a loose club does not occupy space", club_radius, 0.0)


func _test_adopt_authored_placements() -> void:
	var sim := _new_sim()
	var before_log: int = sim.command_log.size()
	var start: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	sim.adopt_authored_placements([
		{"entity_id": EtheraIds.ENTITY_FOUNTAIN, "x": start.x + 1.5, "z": start.z - 0.25, "yaw": 0.4},
		{"entity_id": "entity.echo_cradle.1", "x": 9.0, "z": 9.0, "yaw": 0.0},
	])
	var moved: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	_true("adopt moves a known authored entity", is_equal_approx(moved.x, start.x + 1.5))
	_eq("adopt is not a journaled command", sim.command_log.size(), before_log)
	_true("adopt ignores unknown instance ids", sim.world.get_entity("entity.echo_cradle.1").is_empty())
	_true("Fountain identity is unchanged", sim.world.has_trait(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN), EtheraIds.TRAIT_ECHO))


func _test_adopt_scenery_blockers() -> void:
	var sim := _new_sim()
	_hide_landscape_occupancy(sim)
	var before_log: int = sim.command_log.size()
	sim.adopt_scenery_blockers([
		{"id": "scenery.bush.Bush1", "x": 12.0, "z": 0.0, "radius": 0.5},
		{"id": "scenery.bench.StoneBench", "x": 12.0, "z": 4.0, "radius": 0.8},
		{"id": "scenery.cradle.EchoCradle1", "x": 12.0, "z": 8.0, "radius": 0.7},
	])
	_eq("scenery adopt is not journaled", sim.command_log.size(), before_log)
	var ids: Array = []
	for blocker in sim.world.blockers_near():
		ids.append(str(blocker.get("id", "")))
	_true("a bush occupies like a rock", ids.has("scenery.bush.Bush1"))
	_true("a bench occupies like a rock", ids.has("scenery.bench.StoneBench"))
	_true("a cradle occupies like the Fountain", ids.has("scenery.cradle.EchoCradle1"))
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, Vector3(15.0, 0.0, 0.0))
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 12.0, "y": 0.0, "z": 0.0})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var after: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_KHAR_MORR))
	var body: float = float(sim.world.tuning.get("body_radius", 0.38))
	_true("a walk into a bush stops at its rim", after.distance_to(Vector3(12.0, 0.0, 0.0)) >= 0.5 + body - 0.05)
	sim.adopt_scenery_blockers([{"id": "scenery.bush.Bush2", "x": 20.0, "z": 0.0, "radius": 0.4}])
	var refreshed: Array = []
	for blocker in sim.world.blockers_near():
		refreshed.append(str(blocker.get("id", "")))
	_true("a later hex refresh replaces old scenery disks", refreshed.has("scenery.bush.Bush2"))
	_true("stale scenery disks are dropped", not refreshed.has("scenery.bush.Bush1"))
	sim.adopt_scenery_blockers([
		{"id": "scenery.hall.TownHall.0", "x": 30.0, "z": 0.0, "radius": 0.3},
		{"id": "scenery.hall.TownHall.1", "x": 32.0, "z": 2.0, "radius": 0.3},
		{"id": "scenery.hall.TownHall.2", "x": 32.0, "z": -2.0, "radius": 0.3},
		{"id": "scenery.hall.TownHall.3", "x": 34.0, "z": 0.0, "radius": 0.3},
	])
	_true("a hollow building keeps its room open", not sim.world.is_blocked(Vector3(32.0, 0.0, 0.0), 0.2))
	_true("a hollow building wall occupies", sim.world.is_blocked(Vector3(30.0, 0.0, 0.0), 0.2))


func _test_landscape_and_herb() -> void:
	var sim := _new_sim()
	var patch_ids: Array[String] = []
	var bundle_ids: Array[String] = []
	var rock_ids: Array[String] = []
	var variants: Dictionary = {}
	for entity_id in sim.world.entities.keys():
		var entity: Dictionary = sim.world.get_entity(str(entity_id))
		if str(entity.get("kind", "")) == EtheraIds.KIND_GRASS:
			patch_ids.append(str(entity_id))
			variants[int(entity.get("presentation", {}).get("variant", 0))] = true
		elif str(entity.get("template_id", "")) == EtheraIds.TEMPLATE_GRASS_LEAF:
			bundle_ids.append(str(entity_id))
		elif str(entity_id).begins_with("entity.shapeable_rock.scatter."):
			rock_ids.append(str(entity_id))
			_true("scatter rock is shapeable", sim.world.has_trait(entity, EtheraIds.TRAIT_SHAPEABLE))
			_true("scatter rock occupies space", sim.world.occupancy_radius(entity) > 0.12)
	_true("grass patches are scattered", patch_ids.size() >= 12)
	_eq("each patch holds a bundle", bundle_ids.size(), patch_ids.size())
	_eq("five grass looks", variants.size(), 5)
	var blades := 0
	for patch_id in patch_ids:
		blades = maxi(blades, int(sim.world.get_entity(patch_id).get("presentation", {}).get("blade_count", 0)))
		_eq("a grass patch does not occupy walking space", sim.world.occupancy_radius(sim.world.get_entity(patch_id)), 0.0)
		_eq("a grass patch is closed until opened", bool(sim.world.get_entity(patch_id).get("opened", true)), false)
	_true("a grass patch has many blades", blades >= 15)
	_eq("the harvestable bundle is five blades", int(sim.world.get_entity("entity.grass.bundle.1").get("presentation", {}).get("blade_count", 0)), 5)
	_true("the bundle stays unmanifested until the patch is opened", not sim.world.is_manifested(sim.world.get_entity("entity.grass.bundle.1")))
	_true("shapeable scatter rocks are present", rock_ids.size() >= 20)
	_eq("the harvestable plant is an offering herb", str(sim.world.get_entity("entity.grass.1").get("name", "")), "Offering Herb")
	_eq("hover open on a grass patch", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, "entity.grass.1").get("kind", "")), EtheraIds.HOVER_OPEN)
	_eq("a grass patch is its own kind", str(sim.world.get_entity("entity.grass.1").get("kind", "")), EtheraIds.KIND_GRASS)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": "entity.grass.1"})
	_eq("a grass patch is not a pickup", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_HERB), "")
	sim.apply({"type": EtheraIds.CMD_OPEN_CONTAINER, "target_id": "entity.grass.1"})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("picking grass uses Material Selection", str(sim.query_skill().get("skill_phase_id", "")), EtheraIds.SKILL_MATERIAL_SELECTION)
	_finish_trace(sim)
	var grass_open_at: Vector3 = sim.world.position_of(sim.world.get_entity("entity.grass.1"))
	_true(
		"opening a grass patch still uses stand-off",
		sim.world.position_of(sim.world.inhabiting()).distance_to(grass_open_at) >= 0.55
	)
	_true("opening a grass patch manifests the bundle", sim.world.is_manifested(sim.world.get_entity("entity.grass.bundle.1")))
	_true("an opened grass patch is harvested", bool(sim.world.get_entity("entity.grass.1").get("opened", false)))
	_assert_revealed_beside(sim, "entity.grass.1", "entity.grass.bundle.1", "grass bundle")
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": "entity.grass.bundle.1"})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("the bundle equips the herb slot", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_HERB), "entity.grass.bundle.1")
	_true("picking a bundle leaves the weapon slot empty", EtheraIds.is_empty_slot(sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON)))
	_eq("held grass uses the hip attachment", str(sim.world.get_entity("entity.grass.bundle.1").get("attachment", "")), "hip")
	_eq("taking the bundle empties the patch", (sim.world.get_entity("entity.grass.1").get("contained_item_ids", []) as Array).size(), 0)
	var grass_at: Vector3 = sim.world.position_of(sim.world.get_entity("entity.grass.1"))
	var through_grass: Dictionary = sim.world.first_path_blocker(
		grass_at + Vector3(-2.0, 0.0, 0.0),
		grass_at + Vector3(2.0, 0.0, 0.0),
		sim.world.walk_radius(),
		[EtheraIds.ENTITY_KHAR_MORR]
	)
	_true("a walk through grass does not hit the patch", str(through_grass.get("id", "")) != "entity.grass.1")
	var scatter: Dictionary = sim.world.get_entity(rock_ids[0])
	_eq("Shape Weapon is offered on a scatter rock", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, str(scatter.get("id", ""))).get("kind", "")), EtheraIds.HOVER_INTERACT)


func _test_fixed_clock() -> void:
	var sim := _new_sim()
	_eq("a fresh world starts at tick zero", sim.world.tick, 0)
	_eq("a fresh world starts at time zero", sim.world.world_time_ms, 0)
	_tick(sim, 1)
	_eq("one tick is one fixed step", sim.world.world_time_ms, EtheraWorld.MS_PER_TICK)
	_eq("twenty ticks make a second", EtheraWorld.TICKS_PER_SECOND * EtheraWorld.MS_PER_TICK, 1000)

	# However presentation batches its frame time, the world must land on the same instant.
	var batched := _new_sim()
	var single := _new_sim()
	batched.apply({"type": EtheraIds.CMD_TICK, "ticks": 40})
	for _i in range(40):
		single.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	_eq("batching ticks cannot change world time", batched.world.world_time_ms, single.world.world_time_ms)
	_eq("batching ticks cannot change the tick count", batched.world.tick, single.world.tick)
	_eq("two seconds of ticks is two thousand ms", batched.world.world_time_ms, 2000)

	var ignored := _new_sim()
	ignored.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 9000})
	_eq("a frame delta cannot advance the clock", ignored.world.world_time_ms, EtheraWorld.MS_PER_TICK)

	# The original defect: world time used to move at the machine's frame rate. It must now
	# track real time to within a single tick, whatever the frame rate is.
	for fps in [24, 30, 37, 60, 90, 144, 240]:
		var paced := _new_sim()
		var accumulator: float = 0.0
		for _frame in range(fps * 3):
			accumulator += 1000.0 / float(fps)
			var earned: int = EtheraWorld.ticks_available(accumulator)
			if earned <= 0:
				continue
			accumulator -= float(earned * EtheraWorld.MS_PER_TICK)
			_tick(paced, earned)
		_true(
			"three real seconds at %d fps is three world seconds" % fps,
			absi(paced.world.world_time_ms - 3000) <= EtheraWorld.MS_PER_TICK
		)


func _test_determinism_and_quantization() -> void:
	var runs: Array[String] = []
	for _run in range(2):
		var sim := _new_sim()
		_complete_shape_weapon(sim)
		_complete_echo_imprint(sim)
		sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
		_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
		var actor: Dictionary = sim.world.inhabiting()
		var position: Vector3 = sim.world.position_of(actor)
		var shard_ids: Array = sim.world.known_shards(actor).duplicate()
		shard_ids.sort()
		runs.append("t=%d pos=%.9f,%.9f yaw=%.9f shards=%s equipped=%s" % [
			sim.world.tick,
			position.x,
			position.z,
			float(actor.get("yaw", 0.0)),
			str(shard_ids),
			sim.world.equipped_item_id(actor, EtheraIds.SLOT_SMALL_WEAPON),
		])
	_eq("an identical command sequence reaches an identical state", runs[0], runs[1])

	var quantized := _new_sim()
	quantized.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 3.33333, "y": 0.0, "z": -1.77777})
	for _i in range(7):
		_tick(quantized, 1)
		var actor: Dictionary = quantized.world.inhabiting()
		var position: Vector3 = quantized.world.position_of(actor)
		_true("stored x sits on the position grid", _on_grid(position.x, EtheraWorld.POSITION_QUANTUM))
		_true("stored z sits on the position grid", _on_grid(position.z, EtheraWorld.POSITION_QUANTUM))
		_true("stored yaw sits on the angle grid", _on_grid(float(actor.get("yaw", 0.0)), EtheraWorld.ANGLE_QUANTUM))

	var fitting := _new_sim()
	_complete_shape_weapon(fitting)
	fitting.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_IMPRINT,
	})
	_arrive(fitting, EtheraIds.ENTITY_KHAR_MORR)
	for _i in range(12):
		_tick(fitting, 1)
		_true(
			"the alignment the click reads sits on the degree grid",
			_on_grid(float(fitting.query_skill().get("rotation_degrees", 0.0)), EtheraWorld.DEGREE_QUANTUM)
		)


func _test_knowledge_stays_authoritative() -> void:
	var sim := _new_sim()
	_complete_shape_weapon(sim)
	_complete_echo_imprint(sim)
	var own: Dictionary = sim.query_panel()
	_true("the inhabited character sees its own knowledge", bool(own.get("knowledge_visible", false)))
	_true("the inhabited panel carries its Shards", own.has("known_shards"))
	var fountain_panel: Dictionary = sim.query_panel(EtheraIds.ENTITY_FOUNTAIN)
	_true("another entity's panel still describes what is observable", str(fountain_panel.get("id", "")) == EtheraIds.ENTITY_FOUNTAIN)
	_true("another entity's knowledge is marked hidden", not bool(fountain_panel.get("knowledge_visible", true)))
	_true("the Fountain never hands its Shards to a client", not fountain_panel.has("known_shards"))
	_true("the Fountain never hands its interactions to a client", not fountain_panel.has("known_interactions"))
	# The runtime still reads the hidden knowledge when it decides availability.
	_true("availability is still decided from the hidden state", sim.world.known_shards(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)).size() == 2)


func _test_snapshot_hash_and_restore() -> void:
	var fresh_a := _new_sim()
	var fresh_b := _new_sim()
	_eq("two untouched worlds hash identically", fresh_a.state_hash(), fresh_b.state_hash())

	var sim := _new_sim()
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 4.0, "y": 0.0, "z": -2.0})
	_tick(sim, 8)
	var mid_hash: String = sim.state_hash()
	var snapshot: Dictionary = sim.create_snapshot()
	_eq("a snapshot of the same world hashes the same", sim.state_hash(), mid_hash)

	var restored := _new_sim()
	_true("restore accepts a current snapshot", restored.restore_snapshot(snapshot))
	_eq("restore reproduces the hash", restored.state_hash(), mid_hash)
	_eq("restore reproduces the tick", restored.world.tick, sim.world.tick)
	_eq("restore carries the walk", str((restored.world.walk_motor.get(EtheraIds.ENTITY_KHAR_MORR, {}) as Dictionary).get("reason", "")), "walk")

	# A snapshot that has gone through JSON, as it would on the wire, must still restore.
	var parsed: Variant = JSON.parse_string(JSON.stringify(snapshot))
	var from_json := _new_sim()
	_true("a JSON snapshot restores", from_json.restore_snapshot(parsed))
	_eq("a JSON snapshot hashes the same", from_json.state_hash(), mid_hash)

	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_arrive(restored, EtheraIds.ENTITY_KHAR_MORR)
	_eq("continuing from a snapshot matches continuing the original", sim.state_hash(), restored.state_hash())

	var rejected := _new_sim()
	_true("an unknown schema is refused", not rejected.restore_snapshot({"schema": "nope"}))
	_eq("a refused restore leaves the world untouched", rejected.world.tick, 0)


func _test_command_journal_replays() -> void:
	var original := _new_sim()
	_complete_shape_weapon(original)
	original.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(original, EtheraIds.ENTITY_KHAR_MORR)
	_true("the journal recorded the run", original.command_log.size() > 0)

	var replayed := _new_sim()
	replayed.replay(original.command_log)
	_eq("replaying the journal reproduces the hash", replayed.state_hash(), original.state_hash())
	_eq("replaying the journal reproduces the equipped item", replayed.world.equipped_item_id(replayed.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), original.world.equipped_item_id(original.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON))


func _test_skill_inputs_are_timestamped() -> void:
	var sim := _new_sim()
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("a new skill phase starts with an empty sample list", (sim.world.active_round.get("inputs", []) as Array).size(), 0)
	var started_at: int = sim.world.tick
	sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": 0.5, "y": 0.18})
	_tick(sim, 3)
	sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": 0.5, "y": 0.32})
	var samples: Array = sim.world.active_round.get("inputs", [])
	_eq("each pointer sample is kept", samples.size(), 2)
	_eq("the first sample is stamped with the tick it arrived", int((samples[0] as Dictionary).get("tick", -1)), started_at)
	_eq("the second sample is stamped later", int((samples[1] as Dictionary).get("tick", -1)), started_at + 3)
	_eq("the sample is a pointer, not a score", str((samples[0] as Dictionary).get("type", "")), EtheraIds.CMD_SKILL_POINTER)
	_true("the sample carries cursor x", absf(float((samples[0] as Dictionary).get("x", 0.0)) - 0.5) < 0.0001)


func _test_item_commits_immediately() -> void:
	var sim := _new_sim()
	_eq("authored loose items start committed", str(sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER).get("commit_status", "")), EtheraIds.COMMIT_COMMITTED)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("a pickup is committed without waiting", str(sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER).get("commit_status", "")), EtheraIds.COMMIT_COMMITTED)
	_eq("a pickup wrote a transaction", sim.world.transactions.size(), 1)
	var pickup_tx: Dictionary = sim.world.transactions.values()[0]
	_eq("the pickup transaction is committed", str(pickup_tx.get("status", "")), EtheraIds.COMMIT_COMMITTED)
	_eq("the pickup transaction names the item", str(pickup_tx.get("item_id", "")), EtheraIds.ENTITY_CLUB_UMBER)

	_complete_shape_weapon(sim)
	var club_id: String = sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON)
	_eq("a shaped club is committed as it is equipped", str(sim.world.get_entity(club_id).get("commit_status", "")), EtheraIds.COMMIT_COMMITTED)
	_eq("the displaced pickup is still committed", str(sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER).get("commit_status", "")), EtheraIds.COMMIT_COMMITTED)
	_true("shaping recorded further transactions", sim.world.transactions.size() >= 2)


func _test_walking() -> void:
	var sim := _new_sim()
	var start: Vector3 = sim.world.position_of(sim.world.inhabiting())
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": start.x + 2.0, "y": 0.0, "z": start.z})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var after: Vector3 = sim.world.position_of(sim.world.inhabiting())
	_true("walked closer to destination", absf(after.x - (start.x + 2.0)) < 0.25)
	_true("retained ground height", absf(after.y - start.y) < 0.001)


func _test_walk_to_object_does_not_interact() -> void:
	var sim := _new_sim()
	var club: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER))
	var shards: int = sim.world.shards.size()
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": club.x, "y": 0.0, "z": club.z})
	_eq("a walk toward a club is ordinary walking", _motor_reason(sim), "walk")
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("walking onto a club does not equip it", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), "")
	_eq("walking onto a club writes no shard", sim.world.shards.size(), shards)
	_true("walking onto a club starts no interaction", sim.query_skill().is_empty())


func _test_run_uses_run_speed() -> void:
	var walking := _new_sim()
	var start: Vector3 = walking.world.position_of(walking.world.inhabiting())
	var dest_x: float = start.x + 6.0
	walking.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": dest_x, "y": 0.0, "z": start.z})
	_eq("a single click stores a walk gait", str(_motor(walking).get("gait", "")), "walk")
	var walk_ticks := 0
	for _i in range(240):
		if not walking.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR):
			break
		_tick(walking, 1)
		walk_ticks += 1
	_true("a walk arrives", walking.world.position_of(walking.world.inhabiting()).distance_to(Vector3(dest_x, 0.0, start.z)) < 0.3)

	var running := _new_sim()
	running.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": dest_x, "y": 0.0, "z": start.z, "gait": "run"})
	_eq("a double-click stores a run gait", str(_motor(running).get("gait", "")), "run")
	var run_ticks := 0
	var peak: float = 0.0
	for _i in range(240):
		if not running.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR):
			break
		peak = maxf(peak, _motor_speed(running))
		_tick(running, 1)
		run_ticks += 1
	_true("a run arrives sooner than a walk", run_ticks < walk_ticks)
	_true("run speed exceeds walk speed", peak > float(running.world.tuning.get("walk_speed", 2.4)) + 0.4)

	var ramp := _new_sim()
	var ramp_start: Vector3 = ramp.world.position_of(ramp.world.inhabiting())
	ramp.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": ramp_start.x + 10.0, "y": 0.0, "z": ramp_start.z, "gait": "run"})
	_tick(ramp, 2)
	var early: float = _motor_speed(ramp)
	_tick(ramp, 8)
	var later: float = _motor_speed(ramp)
	_true("a run builds speed instead of snapping", early < float(ramp.world.tuning.get("run_speed", 5.2)) * 0.45)
	_true("run speed increases over the first strides", later > early + 0.4)

	var settling := _new_sim()
	var settle_start: Vector3 = settling.world.position_of(settling.world.inhabiting())
	var settle_dest := Vector3(settle_start.x + 16.0, 0.0, settle_start.z)
	settling.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": settle_dest.x, "y": 0.0, "z": settle_dest.z, "gait": "run"})
	var settle_peak: float = 0.0
	var settled_to_walk := false
	var last_speed: float = 0.0
	for _i in range(400):
		if not settling.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR):
			break
		last_speed = _motor_speed(settling)
		settle_peak = maxf(settle_peak, last_speed)
		var left: float = settling.world.position_of(settling.world.inhabiting()).distance_to(settle_dest)
		if left < 1.4 and left > 0.3:
			settled_to_walk = last_speed <= float(settling.world.tuning.get("walk_speed", 1.92)) + 0.2
		_tick(settling, 1)
	_true("a long run reaches run speed", settle_peak > float(settling.world.tuning.get("walk_speed", 1.92)) + 0.8)
	_true("the last meters of a run ease back to a walk", settled_to_walk)
	_true("a run finishes at a walk before it stops", last_speed <= float(settling.world.tuning.get("arrive_speed", 0.28)) + 0.05)


func _test_fountain_approach_from_any_side() -> void:
	var sim := _new_sim()
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shape_weapon(sim)
	var fountain: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	var ring: float = 3.2
	var sides: Array[Vector3] = [
		Vector3(5.0, 0.0, 0.0),
		Vector3(-5.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 5.0),
		Vector3(0.0, 0.0, -5.0),
	]
	for offset in sides:
		sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, fountain + offset)
		sim.apply({
			"type": EtheraIds.CMD_BEGIN_INTERACTION,
			"target_id": EtheraIds.ENTITY_FOUNTAIN,
			"interaction_id": EtheraIds.INTERACTION_ECHO_IMPRINT,
		})
		var dest: Vector3 = EtheraWorld.to_vector(_motor(sim).get("destination", {}))
		_true("Fountain approach stays on the same side", (dest - fountain).dot(offset) > 0.0)
		_true("Fountain approach sits on the ring", absf(dest.distance_to(fountain) - ring) < 0.08)
		sim.apply({"type": EtheraIds.CMD_STOP_WALKING})
		_eq("approach abandoned between sides", sim.query_skill().is_empty(), true)


func _test_shape_weapon_approach_from_any_side() -> void:
	var sim := _new_sim()
	var rock: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_ROCK))
	var ring: float = 1.45
	var sides: Array[Vector3] = [
		Vector3(4.0, 0.0, 0.0),
		Vector3(-4.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 4.0),
		Vector3(0.0, 0.0, -4.0),
	]
	for offset in sides:
		sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, rock + offset)
		sim.apply({
			"type": EtheraIds.CMD_BEGIN_INTERACTION,
			"target_id": EtheraIds.ENTITY_ROCK,
			"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
		})
		var dest: Vector3 = EtheraWorld.to_vector(_motor(sim).get("destination", {}))
		_true("Shape Weapon approach stays on the same side", (dest - rock).dot(offset) > 0.0)
		_true("Shape Weapon approach sits on the ring", absf(dest.distance_to(rock) - ring) < 0.08)
		var first: Vector3 = EtheraWorld.to_vector((_motor(sim).get("path", [{}]) as Array)[0]) if (_motor(sim).get("path", []) as Array).size() > 0 else dest
		_true("Shape Weapon does not walk closer than the ring first", first.distance_to(rock) >= ring - 0.35)
		sim.apply({"type": EtheraIds.CMD_STOP_WALKING})
		_eq("Shape Weapon approach abandoned between sides", sim.query_skill().is_empty(), true)


func _test_occupancy_blocks_walking() -> void:
	var sim := _new_sim()
	var fountain: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	var radius: float = sim.world.occupancy_radius(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	var body: float = float(sim.world.tuning.get("body_radius", 0.38))
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, fountain + Vector3(5.0, 0.0, 0.0))
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": fountain.x, "y": 0.0, "z": fountain.z})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var after: Vector3 = sim.world.position_of(sim.world.inhabiting())
	_true("a walk into the Fountain stops at its rim", after.distance_to(fountain) >= radius + body - 0.05)
	_true("the walk does not remain stuck mid-stride", not sim.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR))

	var blocked := _new_sim()
	var rock_pos: Vector3 = blocked.world.position_of(blocked.world.get_entity(EtheraIds.ENTITY_ROCK))
	var rock_radius: float = blocked.world.occupancy_radius(blocked.world.get_entity(EtheraIds.ENTITY_ROCK))
	blocked.world.set_position(EtheraIds.ENTITY_KHAR_MORR, rock_pos + Vector3(0.0, 0.0, 3.0))
	blocked.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": rock_pos.x, "y": 0.0, "z": rock_pos.z})
	_arrive(blocked, EtheraIds.ENTITY_KHAR_MORR)
	_true(
		"a walk into the rock stops at its rim",
		blocked.world.position_of(blocked.world.inhabiting()).distance_to(rock_pos) >= rock_radius + body - 0.05
	)
	var circle: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_STONE_CIRCLE))
	_true("the stone circle sits on the starting hex", circle.distance_to(Vector3(108.0, 0.0, 0.0)) < 0.05)


func _test_walkable_slope() -> void:
	var sim := _new_sim()
	_eq("walkable slope is fifty degrees", float(sim.world.tuning.get("walkable_slope_degrees", 0.0)), 50.0)
	_eq("the world default matches vanilla", sim.world.walkable_slope_degrees(), EtheraTerrain.WALKABLE_SLOPE_DEGREES)
	_true("the fountain pad is walkable", EtheraTerrain.is_walkable(0.0, 0.0))
	_true("the village rise stays under fifty degrees", EtheraTerrain.is_walkable(18.0, 0.0))
	_true("gentle grassland is walkable", EtheraTerrain.slope_degrees(12.0, 8.0) < 10.0)
	var ramp_60 := func(x: float, _z: float) -> float:
		if x <= 4.0:
			return 0.0
		return tan(deg_to_rad(60.0)) * (x - 4.0)
	var ramp_40 := func(x: float, _z: float) -> float:
		if x <= 4.0:
			return 0.0
		return tan(deg_to_rad(40.0)) * (x - 4.0)
	_true("a sixty degree face is unwalkable", not EtheraTerrain.is_walkable(6.0, 0.0, 50.0, ramp_60))
	_true("a forty degree face is walkable", EtheraTerrain.is_walkable(6.0, 0.0, 50.0, ramp_40))
	_hide_landscape_occupancy(sim)
	sim.world.terrain_sampler = ramp_60
	_true("sixty degrees blocks a point", sim.world.is_too_steep(Vector3(6.0, 0.0, 22.0)))
	_true("the flat before the face stays open", not sim.world.is_too_steep(Vector3(2.0, 0.0, 22.0)))
	var stop: Vector3 = sim.world.last_walkable_toward(Vector3(0.0, 0.0, 22.0), Vector3(12.0, 0.0, 22.0))
	_true("a click through a cliff stops at the face", stop.x < 5.2 and stop.x > 3.2)
	var path: Array = sim.world.find_walk_path(Vector3(0.0, 0.0, 22.0), Vector3(12.0, 0.0, 22.0), sim.world.walk_radius())
	_true("the planned walk ends at the cliff", path.size() == 1 and float((path[0] as Vector3).x) < 5.2)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, Vector3(0.0, 0.0, 22.0))
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 12.0, "y": 0.0, "z": 22.0})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var after: Vector3 = sim.world.position_of(sim.world.inhabiting())
	_true("she walks up to a sixty degree slope and stops", after.x < 5.2 and after.x > 2.5)
	var gentle := _new_sim()
	_hide_landscape_occupancy(gentle)
	gentle.world.terrain_sampler = ramp_40
	gentle.world.set_position(EtheraIds.ENTITY_KHAR_MORR, Vector3(0.0, 0.0, 22.0))
	gentle.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 10.0, "y": 0.0, "z": 22.0})
	_arrive(gentle, EtheraIds.ENTITY_KHAR_MORR)
	_true(
		"a forty degree slope is ordinary walking",
		gentle.world.position_of(gentle.world.inhabiting()).x > 9.4
	)


func _test_sheath_pose() -> void:
	var identity: Transform3D = EtheraAssetLibrary.sheath_transform({})
	_true("an empty sheath pose is identity", identity.is_equal_approx(Transform3D.IDENTITY))
	var sheathed: Transform3D = EtheraAssetLibrary.sheath_transform({
		"x": 0.0,
		"y": -0.06,
		"z": -0.08,
		"diagonal_degrees": 58,
	})
	_true("a sheathed club sits off the back, not through the chest", sheathed.origin.z < -0.04)
	var long_axis: Vector3 = sheathed.basis * Vector3(0.0, 0.0, 1.0)
	_true("a sheathed club lies in the back plane", absf(long_axis.z) < 0.1)
	_true("a sheathed club has a vertical rise", long_axis.y > 0.3)
	_true("a sheathed club slants toward a shoulder", absf(long_axis.x) > 0.3)
	var attach: Dictionary = _new_sim().world.inhabiting().get("presentation", {}).get("attach_points", {}).get("back", {})
	var sheath: Dictionary = attach.get("sheath", {})
	_true("the character authors a back-plane diagonal", sheath.has("diagonal_degrees"))
	_true("the authored slash is about forty-six degrees", absf(float(sheath.get("diagonal_degrees", 0.0)) - 46.0) < 0.5)
	_true("the authored slash sits close to the back", float(sheath.get("z", 0.0)) > 0.18)
	_true("the authored slash sits toward the spine", float(sheath.get("x", 0.0)) < -0.04)
	_true("the authored slash sits high on the back", float(sheath.get("y", 0.0)) > 0.06)


func _test_item_handoff() -> void:
	var start := Transform3D(Basis.from_euler(Vector3(0.4, 0.2, 0.1)), Vector3(1.0, 1.1, 2.0))
	var rest: Transform3D = EtheraItemHandoff.loose_transform(Vector3(2.0, 0.0, 2.4), 0.3)
	var back := Transform3D(Basis.from_euler(Vector3(0.2, 1.1, -0.3)), Vector3(1.2, 1.15, 1.8))
	_true("a rise starts on the ground pose", EtheraItemHandoff.rise_pose(0.0, start, back).origin.is_equal_approx(start.origin))
	_true("a rise ends on the back pose", EtheraItemHandoff.rise_pose(1.0, start, back).origin.is_equal_approx(back.origin))
	var mid_rise: Transform3D = EtheraItemHandoff.rise_pose(0.5, start, back)
	_true("a rising club leaves the ground", mid_rise.origin.y > start.origin.y)
	var drop_end: Transform3D = EtheraItemHandoff.drop_pose(1.0, start, rest)
	_true("a finished drop lies on the authored rest", drop_end.origin.is_equal_approx(rest.origin))
	var rest_long: Vector3 = drop_end.basis * Vector3(0.0, 0.0, 1.0)
	_true("a finished drop is horizontal", absf(rest_long.y) < 0.08)
	var fall_mid: Transform3D = EtheraItemHandoff.drop_pose(0.85, start, rest)
	_true("the last third of a drop is still in the air or bouncing", fall_mid.origin.y > rest.origin.y)
	var contact_y: float = EtheraItemHandoff.bounce_height(0.58, 0.0, EtheraItemHandoff.CONTACT)
	var bounce_y: float = EtheraItemHandoff.bounce_height(0.58, 0.0, EtheraItemHandoff.CONTACT + 0.2)
	_true("a drop bounces after first contact", bounce_y > contact_y)
	var motion := EtheraItemHandoff.new()
	motion.observe("club.a", true, start)
	motion.observe("club.a", false, start)
	_true("leaving the back starts a drop", motion.is_active("club.a"))
	var after: Transform3D = motion.step("club.a", EtheraItemHandoff.DURATION, rest)
	_true("a completed drop motion returns the rest pose", after.origin.is_equal_approx(rest.origin))
	_true("a completed drop motion is no longer airborne", not motion.is_active("club.a"))


func _test_club_presentation_variants() -> void:
	var sim := _new_sim()
	_eq("umber club uses the first sculpt", str(sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER).get("presentation", {}).get("asset_id", "")), "asset.stone_club")
	_eq("green club uses the second sculpt", str(sim.world.get_entity(EtheraIds.ENTITY_CLUB_GREEN).get("presentation", {}).get("asset_id", "")), "asset.stone_club_b")
	var assets := EtheraAssetLibrary.new()
	_eq("club asset catalog loads", assets.load_from_res(), OK)
	_true("first club sculpt is present", assets.has_model("asset.stone_club"))
	_true("second club sculpt is present", assets.has_model("asset.stone_club_b"))
	_true("umber and green use different glow colors", assets.color_for("umber") != assets.color_for("green"))


func _test_character_pick_volume() -> void:
	var assets := EtheraAssetLibrary.new()
	var shape: Shape3D = assets._collision_for("character")
	_true("orbit picking uses a capsule", shape is CapsuleShape3D)
	_true("the character pick volume is wider than the body", (shape as CapsuleShape3D).radius >= 0.65)
	_true("the character pick volume is taller than the body", (shape as CapsuleShape3D).height >= 2.0)


func _test_fountain_pick_follows_visual() -> void:
	var assets := EtheraAssetLibrary.new()
	_eq("fountain pick catalog loads", assets.load_from_res(), OK)
	var modeled: StaticBody3D = assets.make_entity_body({
		"id": EtheraIds.ENTITY_FOUNTAIN,
		"kind": "memory_fountain",
		"presentation": {"asset_id": "asset.memory_fountain"},
	})
	var fat := false
	for child in modeled.get_children():
		if not (child is CollisionShape3D):
			continue
		var shape: Shape3D = (child as CollisionShape3D).shape
		if shape is CylinderShape3D and (shape as CylinderShape3D).height >= 2.0:
			fat = true
	_true("the Fountain model is not a full-height pick cylinder", not fat)
	_true("the Fountain pick follows its mesh", modeled.find_child("MeshCollision", true, false) != null)
	var placeholder: StaticBody3D = assets.make_entity_body({
		"id": EtheraIds.ENTITY_FOUNTAIN,
		"kind": "memory_fountain",
		"presentation": {"asset_id": "asset.missing_fountain"},
	})
	var cylinders := 0
	for child in placeholder.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is CylinderShape3D:
			cylinders += 1
	_eq("a placeholder Fountain uses a base and a stem", cylinders, 2)
	modeled.free()
	placeholder.free()


func _test_focus_hold_slows_pace() -> void:
	var normal := _new_sim()
	var slowed := _new_sim()
	var start: Vector3 = normal.world.position_of(normal.world.inhabiting())
	var full_speed: float = float(slowed.world.tuning.get("walk_speed", 2.4))
	var scale: float = float(slowed.world.tuning.get("focus_hold_speed_scale", 0.45))
	slowed.apply({"type": EtheraIds.CMD_SET_FOCUS_HOLD, "held": true})
	for sim in [normal, slowed]:
		sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": start.x + 20.0, "y": 0.0, "z": start.z})
		_tick(sim, _seconds(1.0))
	_true("the held pace reaches the scaled speed", absf(_motor_speed(slowed) - full_speed * scale) < 0.01)
	_true("the free pace reaches the full speed", absf(_motor_speed(normal) - full_speed) < 0.01)
	var covered: float = slowed.world.position_of(slowed.world.inhabiting()).distance_to(start)
	_true("holding focus covers less ground", covered < normal.world.position_of(normal.world.inhabiting()).distance_to(start))
	slowed.apply({"type": EtheraIds.CMD_SET_FOCUS_HOLD, "held": false})
	_tick(slowed, _seconds(1.0))
	_true("releasing focus restores the full pace", absf(_motor_speed(slowed) - full_speed) < 0.01)


func _test_shape_trace_timeout_and_success() -> void:
	var sim := _new_sim()
	_eq("shape weapon available", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0, true)
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"actor_id": EtheraIds.ENTITY_KHAR_MORR,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("skill is shape trace", str(sim.query_skill().get("skill_phase_id", "")), EtheraIds.SKILL_SHAPE_TRACE)
	_tick(sim, _seconds(9.0))
	_eq("timeout creates no shards", sim.world.shards.size(), 0)
	_true("timeout leaves rock", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_ROCK)))
	_true("timeout leaves slot empty", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON) == "")
	_complete_shape_weapon(sim)
	var shaped: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_ROCK)
	_true("rock stays after shaping", sim.world.is_manifested(shaped))
	_true("shaping marks the rock Shaped", (shaped.get("states", []) as Array).has(EtheraIds.STATE_SHAPED))
	_true("Shaped disables Shapeable", not sim.world.has_trait(shaped, EtheraIds.TRAIT_SHAPEABLE))
	_eq("shape weapon cannot use the same rock while it is Shaped", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size(), 0)
	_tick(sim, _seconds(60.0))
	_true("Shaped ends after one minute", not (sim.world.get_entity(EtheraIds.ENTITY_ROCK).get("states", []) as Array).has(EtheraIds.STATE_SHAPED))
	_true("Shapeable returns when Shaped ends", sim.world.has_trait(sim.world.get_entity(EtheraIds.ENTITY_ROCK), EtheraIds.TRAIT_SHAPEABLE))
	_true("shape weapon can use the rock again", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0)
	var equipped_id: String = sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON)
	_true("club equipped", equipped_id != "")
	var club: Dictionary = sim.world.get_entity(equipped_id)
	_true("club is weapon", sim.world.has_trait(club, EtheraIds.TRAIT_WEAPON))
	_true("club is stone weapon", sim.world.has_trait(club, EtheraIds.TRAIT_STONE_WEAPON))
	_eq("club color from rock", str(club.get("base_color", "")), "slate")
	_eq("one event shard", sim.world.shards.size(), 1)
	var shard: Dictionary = sim.world.shards.values()[0]
	_eq("shard actor", (shard.get("actor_ids", []) as Array)[0], EtheraIds.ENTITY_KHAR_MORR)
	_eq("shard target remains the rock id", (shard.get("target_ids", []) as Array)[0], EtheraIds.ENTITY_ROCK)
	_eq("shard action", str(shard.get("action_id", "")), EtheraIds.INTERACTION_SHAPE_WEAPON)
	_eq("shard reaction none", (shard.get("reaction_ids", []) as Array)[0], EtheraIds.REACTION_NONE)
	_eq("shard result is club", (shard.get("result_ids", []) as Array)[0], equipped_id)
	_eq("shard place", str(shard.get("place_id", "")), EtheraIds.PLACE_VILLAGE_CENTER)
	_true("khar-morr knows the event", sim.world.knows_shard(sim.world.inhabiting(), str(shard["id"])))
	var discovered: Array = sim.query_panel().get("known_interactions", [])
	_eq("using shape weapon records it", discovered.size(), 1)
	_eq("the record names shape weapon", str((discovered[0] as Dictionary).get("name", "")), "Shape Weapon")
	_eq("the record describes shape weapon", str((discovered[0] as Dictionary).get("description", "")), "Shape a suitable rock into a stone club and take it in hand.")
	var requirements: Array = (discovered[0] as Dictionary).get("requirements", [])
	_true("the record requires weapon shaping", requirements.has("Weapon Shaping"))
	_true("the record requires shapeable", requirements.has("Shapeable"))
	_true("the log records the discovered interaction", _log_has(sim, "Interaction discovered: Shape Weapon"))


func _test_right_click_cancels_approach() -> void:
	var sim := _new_sim()
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_eq("approach is running", str(sim.query_skill().get("stage", "")), "approaching")
	_tick(sim, 2)
	var here: Vector3 = sim.world.position_of(sim.world.inhabiting())
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": here.x, "y": 0.0, "z": here.z + 3.0})
	_true("the round is abandoned", sim.query_skill().is_empty())
	_eq("movement returns to a plain walk", _motor_reason(sim), "walk")
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_true("no skill phase starts after cancelling", sim.query_skill().is_empty())
	_true("cancelling creates no shard", sim.world.shards.is_empty())
	_eq("cancelling records no history", sim.query_recent_interactions().size(), 0)
	_eq("cancelling does not record the interaction", (sim.query_panel().get("known_interactions", []) as Array).size(), 0)
	_true("the interaction is offered again", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0)

	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("skill phase reached on the retry", str(sim.query_skill().get("stage", "")), "skill")
	var during: Vector3 = sim.world.position_of(sim.world.inhabiting())
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": during.x + 4.0, "y": 0.0, "z": during.z})
	_true("a running skill phase ignores new destinations", not sim.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR))
	_eq("the running skill phase survives", str(sim.query_skill().get("stage", "")), "skill")

	var walking := _new_sim()
	walking.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_eq("a distant pickup starts a walk", _motor_reason(walking), "pickup")
	var origin: Vector3 = walking.world.position_of(walking.world.inhabiting())
	walking.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": origin.x, "y": 0.0, "z": origin.z + 2.0})
	_eq("right-click abandons a pickup walk", _motor_reason(walking), "walk")
	_arrive(walking, EtheraIds.ENTITY_KHAR_MORR)
	_eq("the abandoned pickup equips nothing", walking.world.equipped_item_id(walking.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), "")


func _test_pickup_walks_into_reach() -> void:
	var sim := _new_sim()
	var club_pos: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER))
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, club_pos + Vector3(14.0, 0.0, 0.0))
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_eq("a distant click equips nothing yet", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), "")
	_eq("the walk is a pickup approach", _motor_reason(sim), "pickup")
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("arriving takes the item", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), EtheraIds.ENTITY_CLUB_UMBER)
	_true("stopped within pickup reach", club_pos.distance_to(sim.world.position_of(sim.world.inhabiting())) <= float(sim.world.tuning.get("pickup_reach", 1.1)))
	_eq("pickup writes one shard", sim.world.shards.size(), 1)
	_true("only the picker knows the pickup shard", sim.world.knows_shard(sim.world.inhabiting(), str(sim.world.shards.keys()[0])))
	_true("the Fountain does not learn pickup automatically", not sim.world.knows_shard(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN), str(sim.world.shards.keys()[0])))


func _test_pickup_and_container_shards() -> void:
	var sim := _new_sim()
	_eq("hover open on the closed container", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_CONTAINER).get("kind", "")), EtheraIds.HOVER_OPEN)
	_true("the green club stays unmanifested until opened", not sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_CLUB_GREEN)))
	_place_beside(sim, EtheraIds.ENTITY_CONTAINER)
	sim.apply({"type": EtheraIds.CMD_OPEN_CONTAINER, "target_id": EtheraIds.ENTITY_CONTAINER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var container_pos: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_CONTAINER))
	var stand: Vector3 = sim.world.position_of(sim.world.inhabiting())
	var occupancy: float = sim.world.occupancy_radius(sim.world.get_entity(EtheraIds.ENTITY_CONTAINER))
	_true("opening stops short of the container", stand.distance_to(container_pos) >= occupancy + 0.25)
	_true("opening stays close enough to interact", stand.distance_to(container_pos) <= occupancy + 1.15)
	_true("opening manifests the green club", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_CLUB_GREEN)))
	_assert_revealed_beside(sim, EtheraIds.ENTITY_CONTAINER, EtheraIds.ENTITY_CLUB_GREEN, "green club")
	_eq("opening writes a discovery shard", sim.world.shards.size(), 1)
	var discovery: Dictionary = sim.world.shards.values()[0]
	_eq("discovery action", str(discovery.get("action_id", "")), EtheraIds.ACTION_DISCOVERY)
	_eq("discovery target is the container", (discovery.get("target_ids", []) as Array)[0], EtheraIds.ENTITY_CONTAINER)
	_true("only the opener knows the discovery", sim.world.knows_shard(sim.world.inhabiting(), str(discovery["id"])))
	_eq("an opened container is no longer an open hover", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_CONTAINER).get("kind", "")), EtheraIds.HOVER_NONE)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_GREEN})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("taking from a container writes a pickup shard too", sim.world.shards.size(), 2)
	var pickup_id: String = ""
	for shard_id in sim.world.shards.keys():
		if str(sim.world.shards[shard_id].get("action_id", "")) == EtheraIds.ACTION_PICKUP:
			pickup_id = str(shard_id)
	_true("a pickup shard exists after taking the green club", pickup_id != "")
	_place_beside(sim, EtheraIds.ENTITY_CLUB_UMBER)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("umber is equipped after the second pickup", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), EtheraIds.ENTITY_CLUB_UMBER)
	var pickup_count: int = 0
	for shard in sim.world.shards.values():
		if str(shard.get("action_id", "")) == EtheraIds.ACTION_PICKUP:
			pickup_count += 1
	_eq("picking a second club keeps a separate pickup shard", pickup_count, 2)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_GREEN})
	var green_pickups: Array[String] = []
	for shard_id in sim.world.known_shards(sim.world.inhabiting()):
		var shard: Dictionary = sim.world.shards.get(shard_id, {})
		if str(shard.get("action_id", "")) == EtheraIds.ACTION_PICKUP and (shard.get("target_ids", []) as Array).has(EtheraIds.ENTITY_CLUB_GREEN):
			green_pickups.append(str(shard_id))
	_eq("re-picking the same club keeps one pickup shard for it", green_pickups.size(), 1)


func _test_place_discovery() -> void:
	var sim := _new_sim()
	var landmark: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_STONE_CIRCLE)
	_eq("the stone circle is a landmark", str(landmark.get("kind", "")), "landmark")
	_eq("the stone circle belongs to its own place", str(landmark.get("place_id", "")), EtheraIds.PLACE_STONE_CIRCLE)
	_eq("the authored place name", str(sim.world.places.get(EtheraIds.PLACE_STONE_CIRCLE, {}).get("name", "")), "Ancient Stone Circle")
	_eq("discovery radius is ten meters", float(landmark.get("discovery_radius", 0.0)), 10.0)
	_true("the circle occupies the inner stones", sim.world.occupancy_radius(landmark) >= 3.0)
	_eq("hovering the circle from far away shows discovery", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).get("kind", "")), EtheraIds.HOVER_DISCOVER)
	_tick(sim, 20)
	_eq("staying in the village does not discover the circle", sim.world.shards.size(), 0)
	var origin: Vector3 = sim.world.position_of(landmark)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, origin + Vector3(10.4, 0.0, 0.0))
	sim.apply({"type": EtheraIds.CMD_OBSERVE_TARGET, "target_id": EtheraIds.ENTITY_STONE_CIRCLE})
	_eq("hovering outside the aura does not discover it", sim.world.shards.size(), 0)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, origin + Vector3(6.0, 0.0, 0.0))
	_eq("hovering the center inside the aura is discovery", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).get("kind", "")), EtheraIds.HOVER_DISCOVER)
	_tick(sim, 1)
	_eq("entering the aura without hovering does not discover it", sim.world.shards.size(), 0)
	sim.apply({"type": EtheraIds.CMD_OBSERVE_TARGET, "target_id": EtheraIds.ENTITY_STONE_CIRCLE})
	_eq("hovering the center stone inside the aura writes one discovery shard", sim.world.shards.size(), 1)
	var shard: Dictionary = sim.world.shards.values()[0]
	var shard_id: String = str(shard.get("id", ""))
	_eq("place discovery action", str(shard.get("action_id", "")), EtheraIds.ACTION_DISCOVERY)
	_eq("place discovery result", (shard.get("result_ids", []) as Array)[0], EtheraIds.RESULT_DISCOVERED)
	_eq("place discovery target", (shard.get("target_ids", []) as Array)[0], EtheraIds.ENTITY_STONE_CIRCLE)
	_eq("place discovery records the place", str(shard.get("place_id", "")), EtheraIds.PLACE_STONE_CIRCLE)
	_true("only the walker knows the place discovery", sim.world.knows_shard(sim.world.inhabiting(), shard_id))
	_true("the Fountain does not learn a place by proximity", not sim.world.knows_shard(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN), shard_id))
	var found_toast := false
	for entry in sim.query_dev_log():
		if str(entry.get("kind", "")) != "place_discovered":
			continue
		found_toast = true
		_eq("the discovery log names the place", str(entry.get("place_name", "")), "Ancient Stone Circle")
	_true("entering the aura writes a place-discovered log", found_toast)
	var view: Dictionary = {}
	for entity in sim.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == EtheraIds.ENTITY_STONE_CIRCLE:
			view = entity
	_true("the inhabited character has discovered the circle", bool(view.get("discovered_by_inhabited", false)))
	var panel: Dictionary = sim.query_panel()
	_eq("the panel lists the place discovery", (panel.get("known_shards", []) as Array).size(), 1)
	_eq("the panel names the discovered place", str((panel.get("known_shards", []) as Array)[0].get("place_name", "")), "Ancient Stone Circle")
	_tick(sim, 20)
	_eq("standing in the aura does not write a second shard", sim.world.shards.size(), 1)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, origin + Vector3(20.0, 0.0, 0.0))
	_tick(sim, 1)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, origin + Vector3(4.0, 0.0, 0.0))
	sim.apply({"type": EtheraIds.CMD_OBSERVE_TARGET, "target_id": EtheraIds.ENTITY_STONE_CIRCLE})
	_eq("observing the same object id does not write another shard", sim.world.shards.size(), 1)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, Vector3(4.5, 0.0, 0.0))
	_complete_echo_imprint(sim)
	_true("Echo Imprint can share a place discovery", sim.world.knows_shard(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN), shard_id))


func _test_make_offering() -> void:
	var sim := _new_sim()
	_eq("Make Offering is hidden without a grass bundle", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).size(), 0)
	sim.apply({"type": EtheraIds.CMD_OPEN_CONTAINER, "target_id": "entity.grass.1"})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_finish_trace(sim)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": "entity.grass.bundle.1"})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("the herb is equipped before the offering", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_HERB), "entity.grass.bundle.1")
	_eq("Make Offering stays hidden until the place is known", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).size(), 0)
	_eq("an undiscovered circle still shows the eye", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).get("kind", "")), EtheraIds.HOVER_DISCOVER)
	var origin: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_STONE_CIRCLE))
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_STONE_CIRCLE,
		"interaction_id": EtheraIds.INTERACTION_MAKE_OFFERING,
	})
	_eq("offering cannot start on an undiscovered place", sim.query_skill().is_empty(), true)
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, origin + Vector3(6.0, 0.0, 0.0))
	sim.apply({"type": EtheraIds.CMD_OBSERVE_TARGET, "target_id": EtheraIds.ENTITY_STONE_CIRCLE})
	_eq("Make Offering appears after the place is discovered", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).size() > 0, true)
	_eq("a discovered circle with an offering shows interact", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).get("kind", "")), EtheraIds.HOVER_INTERACT)
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_STONE_CIRCLE,
		"interaction_id": EtheraIds.INTERACTION_MAKE_OFFERING,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("Make Offering uses Shard Fit", str(sim.query_skill().get("skill_phase_id", "")), EtheraIds.SKILL_SHARD_FIT)
	_complete_shard_fit(sim)
	_eq("the offering consumes the grass bundle", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_HERB), "")
	_true("the offered bundle is gone", not sim.world.is_manifested(sim.world.get_entity("entity.grass.bundle.1")))
	_true("Swiftness is on the character", (sim.world.inhabiting().get("states", []) as Array).has(EtheraIds.STATE_SWIFTNESS))
	_eq("the panel names Swiftness", str((sim.query_panel().get("states", []) as Array)[0].get("name", "")), "Swiftness")
	_true("the States panel has remaining time", int((sim.query_panel().get("states", []) as Array)[0].get("remaining_ms", 0)) > 0)
	_eq("the States panel describes Swiftness", str((sim.query_panel().get("states", []) as Array)[0].get("description", "")), "An offering's blessing. Movement is faster while it lasts.")
	var action_count := 0
	var offering_id := ""
	for shard in sim.world.shards.values():
		if str(shard.get("action_id", "")) == EtheraIds.INTERACTION_MAKE_OFFERING:
			action_count += 1
			offering_id = str(shard.get("id", ""))
	_eq("the offering writes one event Shard", action_count, 1)
	_true("only the actor knows the offering", sim.world.knows_shard(sim.world.inhabiting(), offering_id))
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": origin.x + 20.0, "y": 0.0, "z": origin.z})
	var boosted := 0.0
	for _i in range(12):
		_tick(sim, 1)
		boosted = maxf(boosted, _motor_speed(sim))
	_true("Swiftness raises walking speed", boosted > float(sim.world.tuning.get("walk_speed", 2.4)) + 0.3)
	_tick(sim, _seconds(181.0))
	_true("Swiftness ends after its duration", not (sim.world.inhabiting().get("states", []) as Array).has(EtheraIds.STATE_SWIFTNESS))
	_eq("Make Offering is gone after the bundle is consumed", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_STONE_CIRCLE).size(), 0)


func _test_long_walk_approaches_first() -> void:
	var sim := _new_sim()
	var dest: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_STONE_CIRCLE))
	var planned: Array = sim.world.find_walk_path(Vector3.ZERO, dest, sim.world.walk_radius(), [EtheraIds.ENTITY_KHAR_MORR])
	_true("a walk to the stone circle returns a path", planned.size() >= 1)
	_true("a long walk does not grid the hex", planned.size() <= 8)
	var fountain: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	var behind: Array = sim.world.find_walk_path(
		fountain + Vector3(0.0, 0.0, 18.0),
		fountain + Vector3(0.0, 0.0, -6.0),
		sim.world.walk_radius(),
		[EtheraIds.ENTITY_KHAR_MORR]
	)
	_true("a click behind a solid still returns a path", behind.size() >= 1)
	_true("she walks up to the solid first", behind[0].distance_to(fountain) < 10.0)
	_true("the first step is not the far-side click", behind[0].distance_to(fountain + Vector3(0.0, 0.0, -6.0)) > 8.0)


func _test_walk_goes_around_a_solid() -> void:
	var sim := _new_sim()
	var fountain: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	var radius: float = sim.world.occupancy_radius(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	var body: float = float(sim.world.tuning.get("body_radius", 0.38))
	var clearance: float = sim.world.walk_radius(body)
	var start := fountain + Vector3(5.0, 0.0, 0.0)
	var dest := Vector3(fountain.x - 5.0, 0.0, fountain.z)
	var planned: Array = sim.world.find_walk_path(start, dest, clearance, [EtheraIds.ENTITY_KHAR_MORR])
	_true("the planner returns a route to the far side", planned.size() >= 1)
	_true("the planned route is not a straight line through the Fountain", planned.size() > 1 or start.distance_to(dest) < radius)
	for point in planned:
		_true("every planned waypoint stays clear of the Fountain", point.distance_to(fountain) >= clearance + radius - 0.08)

	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, start)
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": dest.x, "y": 0.0, "z": dest.z})
	var farthest_side: float = 0.0
	var closest: float = INF
	for _i in range(320):
		if not sim.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR):
			break
		var here: Vector3 = sim.world.position_of(sim.world.inhabiting())
		farthest_side = maxf(farthest_side, absf(here.z - fountain.z))
		closest = minf(closest, here.distance_to(fountain))
		_tick(sim, 1)
	var after: Vector3 = sim.world.position_of(sim.world.inhabiting())
	_true("she reaches the far side of the Fountain", after.distance_to(dest) < 0.4)
	_true("the path leaves the straight line and goes around", farthest_side > radius * 0.5)
	_true("she stays outside the Fountain", after.distance_to(fountain) >= radius + body - 0.05)
	_true("she keeps walking clearance from the Fountain", closest >= radius + body - 0.05)

	var behind := _new_sim()
	behind.world.set_position(EtheraIds.ENTITY_KHAR_MORR, fountain + Vector3(0.0, 0.0, 5.0))
	var south := Vector3(fountain.x, 0.0, fountain.z - 5.0)
	behind.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": south.x, "y": 0.0, "z": south.z})
	_arrive(behind, EtheraIds.ENTITY_KHAR_MORR)
	_true(
		"a click on the far side of the Fountain still arrives",
		behind.world.position_of(behind.world.inhabiting()).distance_to(south) < 0.45
	)


func _test_pickup_swap_and_occupied_shaping() -> void:
	var sim := _new_sim()
	_complete_shape_weapon(sim)
	var slate_id: String = sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON)
	var umber_before: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER)
	var umber_pos: Dictionary = umber_before.get("position", {}).duplicate(true)
	_eq("hover swap", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_CLUB_UMBER).get("kind", "")), EtheraIds.HOVER_SWAP)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("umber now equipped", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), EtheraIds.ENTITY_CLUB_UMBER)
	var displaced: Dictionary = sim.world.get_entity(slate_id)
	_eq("displaced x", float(displaced.get("position", {}).get("x", 0.0)), float(umber_pos.get("x", -1.0)))
	_eq("displaced z", float(displaced.get("position", {}).get("z", 0.0)), float(umber_pos.get("z", -1.0)))
	_true("displaced is loose", EtheraIds.is_empty_slot(displaced.get("holder_id", null)))
	var slate_ground_pos: Dictionary = displaced.get("position", {}).duplicate(true)
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": slate_id})
	_true("a pickup already within reach needs no walk", not sim.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR))
	_eq("slate equipped again", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), slate_id)
	var umber_after: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER)
	_eq("umber took slate click position x", float(umber_after.get("position", {}).get("x", 0.0)), float(slate_ground_pos.get("x", 1.0)))

	var occupied := _new_sim()
	occupied.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(occupied, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shape_weapon(occupied)
	var actor_pos: Vector3 = occupied.world.position_of(occupied.world.inhabiting())
	var umber: Dictionary = occupied.world.get_entity(EtheraIds.ENTITY_CLUB_UMBER)
	_true("occupied shaping dropped umber loose", EtheraIds.is_empty_slot(umber.get("holder_id", null)))
	var drop: Vector3 = occupied.world.position_of(umber)
	_true("drop is beside actor", drop.distance_to(actor_pos) < 1.5)
	_true("shaped club equipped over umber", occupied.world.equipped_item_id(occupied.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON) != EtheraIds.ENTITY_CLUB_UMBER)


func _test_echo_imprint_and_event_distribution() -> void:
	var sim := _new_sim()
	_complete_shape_weapon(sim)
	var shape_shard_id: String = str(sim.world.shards.keys()[0])
	_true("imprint available after shaping", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN).size() > 0)
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_IMPRINT,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": 0.08, "y": 0.08})
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_true("wrong click leaves skill running", str(sim.query_skill().get("stage", "")) == "skill")
	_tick(sim, _seconds(8.0))
	_eq("timeout creates no imprint shard", sim.world.shards.size(), 1)
	_eq("fountain still empty after timeout", sim.world.known_shards(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)).size(), 0)

	_complete_echo_imprint(sim)
	var fountain: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)
	_true("fountain has same shape shard id", sim.world.knows_shard(fountain, shape_shard_id))
	_true("khar-morr still has shape shard", sim.world.knows_shard(sim.world.inhabiting(), shape_shard_id))
	_eq("two shards exist after imprint", sim.world.shards.size(), 2)
	var imprint_shard: Dictionary = {}
	for shard in sim.world.shards.values():
		if str(shard.get("action_id", "")) == EtheraIds.INTERACTION_ECHO_IMPRINT:
			imprint_shard = shard
	_true("imprint event exists", not imprint_shard.is_empty())
	_eq("imprint result is transferred id", (imprint_shard.get("result_ids", []) as Array)[0], shape_shard_id)
	var imprint_id: String = str(imprint_shard.get("id", ""))
	_true("the actor learns the imprint event", sim.world.knows_shard(sim.world.inhabiting(), imprint_id))
	_true("the fountain learns the imprint event", sim.world.knows_shard(fountain, imprint_id))
	_eq("the actor knows both records", sim.world.known_shards(sim.world.inhabiting()).size(), 2)
	_eq("the fountain knows both records", sim.world.known_shards(fountain).size(), 2)
	_eq("no record is left unshared", sim.evaluator.first_eligible_shard(sim.world.inhabiting(), fountain), "")
	_eq("the panel lists both records", (sim.query_panel().get("known_shards", []) as Array).size(), 2)


func _test_echo_imprint_shares_up_to_three() -> void:
	var sim := _new_sim()
	sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shape_weapon(sim)
	_place_beside(sim, EtheraIds.ENTITY_CONTAINER)
	sim.apply({"type": EtheraIds.CMD_OPEN_CONTAINER, "target_id": EtheraIds.ENTITY_CONTAINER})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var actor: Dictionary = sim.world.inhabiting()
	var fountain: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)
	var eligible: Array[String] = sim.evaluator.eligible_shards(actor, fountain, 3)
	_eq("three eligible records wait at the Fountain", eligible.size(), 3)
	_place_beside(sim, EtheraIds.ENTITY_FOUNTAIN, Vector3(5.0, 0.0, 0.0))
	_complete_echo_imprint(sim)
	fountain = sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)
	for shard_id in eligible:
		_true("the Fountain gained %s" % shard_id, sim.world.knows_shard(fountain, shard_id))
	_eq("one imprint still writes one event Shard", sim.world.shards.size(), eligible.size() + 1)
	_eq("no eligible record remains after the imprint", sim.evaluator.first_eligible_shard(sim.world.inhabiting(), fountain), "")
	_eq("imprint holds her on the Fountain", _greeting_focus_target(sim), EtheraIds.ENTITY_FOUNTAIN)
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 0.0, "y": 0.0, "z": 0.0})
	_true("she cannot walk away during the imprint", not sim.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR))
	_tick(sim, _seconds(5.0))
	_eq("the imprint releases her after five seconds", _greeting_focus_target(sim), "")
	var counted := false
	for entry in sim.query_dev_log():
		if str(entry.get("text", "")).find("Echo Imprint transferred 3 Shards") >= 0:
			counted = true
			break
	_true("the event log names how many Shards transferred", counted)


# The point of authored results: a whole new interaction, using result types no Milestone 1
# content uses, runs end to end without a line of new runtime code. The interaction is
# invented by this test only and is not content.
func _test_a_third_interaction_needs_no_result_code() -> void:
	var sim := _new_sim()
	_author_test_interaction(sim, [
		{"type": EtheraIds.RESULT_SET_BODY_REGION, "entity": "actor", "region_id": EtheraIds.BODY_LEGS, "condition": "bruised"},
		{"type": EtheraIds.RESULT_ADD_STATE, "entity": "actor", "state_id": "state.test_marker"},
		{
			"type": EtheraIds.RESULT_EQUIP_SPAWNED_ITEM,
			"entity": "actor",
			"slot_id": EtheraIds.SLOT_SMALL_WEAPON,
			"template_id": EtheraIds.TEMPLATE_STONE_CLUB,
			"base_color": "testing",
			"displace_previous": "beside_actor",
		},
	], {"reaction_ids": [EtheraIds.REACTION_NONE], "known_by": ["target"]})

	_true("an authored interaction becomes available", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN).size() > 0)
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": "interaction.test_authored",
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	for checkpoint in sim.query_skill().get("phase", {}).get("checkpoints", []):
		sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": float(checkpoint.get("x", 0.0)), "y": float(checkpoint.get("y", 0.0))})
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_true("the authored round resolved", sim.query_skill().is_empty())

	var actor: Dictionary = sim.world.inhabiting()
	_eq("the body result applied", sim.world.region_condition(actor, EtheraIds.BODY_LEGS), "bruised")
	_true("the state result applied", (actor.get("states", []) as Array).has("state.test_marker"))
	var spawned_id: String = sim.world.equipped_item_id(actor, EtheraIds.SLOT_SMALL_WEAPON)
	_true("the item result equipped something", spawned_id != "")
	_eq("the item result used the authored colour", str(sim.world.get_entity(spawned_id).get("base_color", "")), "testing")

	_eq("the authored action produced exactly one Shard", sim.world.shards.size(), 1)
	var shard: Dictionary = sim.world.shards.values()[0]
	_eq("the record names the authored action", str(shard.get("action_id", "")), "interaction.test_authored")
	_eq("the record references what the results produced", (shard.get("result_ids", []) as Array)[0], spawned_id)
	_true("the authored recipient learned it", sim.world.knows_shard(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN), str(shard["id"])))
	_true("a non-recipient did not", not sim.world.knows_shard(actor, str(shard["id"])))


func _test_authored_results_fail_closed() -> void:
	var unknown := _new_sim()
	_author_test_interaction(unknown, [{"type": "result.does_not_exist", "entity": "actor"}], {})
	_complete_test_interaction(unknown)
	_true("an unrecognized result type creates no Shard", unknown.world.shards.is_empty())
	_true("an unrecognized result type ends the round", unknown.query_skill().is_empty())

	var empty := _new_sim()
	_author_test_interaction(empty, [], {})
	_complete_test_interaction(empty)
	_true("an interaction with no authored results creates no Shard", empty.world.shards.is_empty())

	# A result list is checked as a whole, so a bad entry late in the list must prevent the
	# earlier entries from applying at all.
	var partial := _new_sim()
	_author_test_interaction(partial, [
		{"type": EtheraIds.RESULT_ADD_STATE, "entity": "actor", "state_id": "state.test_marker"},
		{"type": EtheraIds.RESULT_SET_BODY_REGION, "entity": "actor", "region_id": "body.does_not_exist", "condition": "bruised"},
	], {})
	_complete_test_interaction(partial)
	_true("a failed later result still writes no Shard", partial.world.shards.is_empty())
	_true(
		"a failed later result rolls nothing forward",
		not (partial.world.inhabiting().get("states", []) as Array).has("state.test_marker")
	)


func _author_test_interaction(sim: EtheraSimulation, results: Array, record: Dictionary) -> void:
	sim.catalog.states["state.test_marker"] = {
		"id": "state.test_marker",
		"blocked_interaction_ids": [],
		"blocked_trait_ids": [],
	}
	sim.catalog.interactions["interaction.test_authored"] = {
		"id": "interaction.test_authored",
		"name": "Authored Test Action",
		"skill_phase_id": EtheraIds.SKILL_SHAPE_TRACE,
		"approach": {"distance": 1.7, "face_target": true},
		"requirement_groups": [{
			"id": "group.default",
			"actor": [{"type": "has_trait", "trait_id": EtheraIds.TRAIT_GRIMNIR}],
			"target": [{"type": "has_trait", "trait_id": EtheraIds.TRAIT_ECHO}],
		}],
		"results": results,
		"record": record,
	}
	var actor: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_KHAR_MORR)
	var known: Array = actor.get("known_interaction_ids", [])
	known.append("interaction.test_authored")
	actor["known_interaction_ids"] = known
	sim.world.bump(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.CHANGE_TRAITS)


func _complete_test_interaction(sim: EtheraSimulation) -> void:
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": "interaction.test_authored",
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	for checkpoint in sim.query_skill().get("phase", {}).get("checkpoints", []):
		sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": float(checkpoint.get("x", 0.0)), "y": float(checkpoint.get("y", 0.0))})
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})


func _test_availability_and_historical_resolution() -> void:
	var sim := _new_sim()
	_complete_shape_weapon(sim)
	_complete_echo_imprint(sim)
	var after_imprint: Array = _ids(sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN))
	_true("imprint is unavailable when the fountain has every known shard", not after_imprint.has(EtheraIds.INTERACTION_ECHO_IMPRINT))
	_true("with no common task the fountain offers a village delivery", after_imprint.has(EtheraIds.INTERACTION_ECHO_ATTUNEMENT))
	var extra: Dictionary = sim.world.create_shard({
		"actor_ids": [EtheraIds.ENTITY_KHAR_MORR],
		"target_ids": [EtheraIds.ENTITY_ROCK],
		"action_id": "interaction.test_extra",
		"result_ids": ["result.test"],
		"place_id": EtheraIds.PLACE_VILLAGE_CENTER,
	})
	sim.world.grant_shard(EtheraIds.ENTITY_KHAR_MORR, str(extra["id"]))
	_true("imprint available again with a new eligible shard", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN).size() > 0)
	var rock: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_ROCK)
	_true("unmanifested rock entity remains", not rock.is_empty())
	var shape_shard: Dictionary = {}
	for shard in sim.world.shards.values():
		if str(shard.get("action_id", "")) == EtheraIds.INTERACTION_SHAPE_WEAPON:
			shape_shard = shard
	_eq("historical target still rock", (shape_shard.get("target_ids", []) as Array)[0], EtheraIds.ENTITY_ROCK)
	_eq("historical place still village center", str(shape_shard.get("place_id", "")), EtheraIds.PLACE_VILLAGE_CENTER)
	var panel: Dictionary = sim.query_panel()
	_true("panel lists known shards", (panel.get("known_shards", []) as Array).size() >= 1)
	_true("panel lists known interactions", (panel.get("known_interactions", []) as Array).size() >= 2)
	_true("dev log has entries", sim.query_dev_log().size() > 0)


func _test_blockers_and_injury() -> void:
	var sim := _new_sim()
	_true("shape weapon starts available", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0)
	sim.world.set_region_condition(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.BODY_ARMS, "injured")
	_eq("injured arms hide shape weapon", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size(), 0)
	_eq("hover pickup still works while injured", str(sim.query_hover(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_CLUB_UMBER).get("kind", "")), EtheraIds.HOVER_PICKUP)
	sim.world.set_region_condition(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.BODY_ARMS, "healthy")
	_true("healthy arms restore shape weapon", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0)
	sim.catalog.states["state.test_block_shape_weapon"] = {
		"id": "state.test_block_shape_weapon",
		"blocked_interaction_ids": [EtheraIds.INTERACTION_SHAPE_WEAPON],
		"blocked_trait_ids": [],
	}
	sim.world.add_state(EtheraIds.ENTITY_KHAR_MORR, "state.test_block_shape_weapon")
	_eq("negative state filter hides shape weapon", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size(), 0)
	sim.world.remove_state(EtheraIds.ENTITY_KHAR_MORR, "state.test_block_shape_weapon")
	_true("removing the state restores shape weapon", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0)


func _test_radial_selection() -> void:
	var center := Vector2(100, 100)
	var slot0: Vector2 = EtheraRadialSelection.slot_center(center, 0, 2, 92)
	var slot1: Vector2 = EtheraRadialSelection.slot_center(center, 1, 2, 92)
	_eq("the hold origin has no highlight", EtheraRadialSelection.highlighted_index(center, center, 2), -1)
	_eq("standing on a slot selects it", EtheraRadialSelection.highlighted_index(center, slot0, 2), 0)
	_eq("standing on the other slot selects it", EtheraRadialSelection.highlighted_index(center, slot1, 2), 1)
	_eq("missing the slot selects nothing", EtheraRadialSelection.highlighted_index(center, center + Vector2(0, -80), 2), -1)
	_true("empty radial has no highlight", EtheraRadialSelection.highlighted_index(center, slot0, 0) == -1)
	var font: Font = ThemeDB.fallback_font
	var name := "Echo Imprint"
	var frame: Rect2 = EtheraRadialSelection.label_frame(slot0, name, font, 16, 28.0, center)
	_true("the label frame is wide enough for the name", frame.size.x >= font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	_true("the label frame sits outside the slot", frame.get_center().distance_to(center) > slot0.distance_to(center))
	var title: Rect2 = EtheraRadialSelection.hub_title_frame(center, "Memory Fountain", font, 16)
	_true("the object name sits above the hub", title.end.y <= center.y - 18.0)
	_true("the object name is centered on the hub", absf(title.get_center().x - center.x) < 1.0)


func _test_event_envelope_and_logs() -> void:
	var sim := _new_sim()
	_tick(sim, _seconds(5.0))
	var events: Array[Dictionary] = []
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var phase: Dictionary = sim.query_skill().get("phase", {})
	_eq("the skill query names the running phase", str(phase.get("id", "")), EtheraIds.SKILL_SHAPE_TRACE)
	for checkpoint in phase.get("checkpoints", []):
		sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": float(checkpoint.get("x", 0.0)), "y": float(checkpoint.get("y", 0.0))})
	events = sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	var creation_time: int = -1
	for event in events:
		if str(event.get("type", "")) == EtheraIds.EVENT_SHARD_CREATED:
			creation_time = int(event.get("world_time", -1))
			_true("event envelope carries event_time", event.has("event_time"))
	var shard_id: String = str(sim.world.shards.keys()[0])
	_eq("shard event keeps the record's own world_time", creation_time, int(sim.resolve_shard(shard_id).get("world_time", -2)))

	var spawned_id: String = sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON)
	_eq("spawned club takes its asset id from the template", str(sim.world.get_entity(spawned_id).get("presentation", {}).get("asset_id", "")), "asset.stone_club")

	var history: Array = sim.query_recent_interactions()
	_eq("successful round enters recent history", history.size(), 1)
	_eq("history records the interaction", str((history[0] as Dictionary).get("interaction_id", "")), EtheraIds.INTERACTION_SHAPE_WEAPON)

	for _i in range(EtheraWorld.DEV_LOG_LIMIT + 50):
		sim.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_ROCK})
	_eq("dev log is capped", sim.query_dev_log().size(), EtheraWorld.DEV_LOG_LIMIT)
	_eq("dev log honors a limit", sim.query_dev_log(5).size(), 5)


func _complete_shape_weapon(sim: EtheraSimulation) -> void:
	if str(sim.query_skill().get("stage", "")) != "skill":
		sim.apply({
			"type": EtheraIds.CMD_BEGIN_INTERACTION,
			"target_id": EtheraIds.ENTITY_ROCK,
			"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
		})
		_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	# The checkpoints come from the skill query, the same way presentation receives them.
	for checkpoint in sim.query_skill().get("phase", {}).get("checkpoints", []):
		sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": float(checkpoint.get("x", 0.0)), "y": float(checkpoint.get("y", 0.0))})
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_eq("shape skill ended", sim.query_skill().is_empty(), true)


func _complete_echo_imprint(sim: EtheraSimulation) -> void:
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_IMPRINT,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shard_fit(sim)
	_eq("imprint skill ended", sim.query_skill().is_empty(), true)


func _finish_trace(sim: EtheraSimulation) -> void:
	for checkpoint in sim.query_skill().get("phase", {}).get("checkpoints", []):
		sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": float(checkpoint.get("x", 0.0)), "y": float(checkpoint.get("y", 0.0))})
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_eq("trace skill ended", sim.query_skill().is_empty(), true)


func _finish_alignment(sim: EtheraSimulation) -> void:
	sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": 0.5, "y": 0.5})
	var aligned := false
	for _i in range(_seconds(2.0)):
		_tick(sim, 1)
		if sim.query_skill().is_empty():
			break
		if absf(float(sim.query_skill().get("rotation_degrees", 99.0))) <= 24.0:
			aligned = true
			break
	_true("alignment was reached", aligned)
	if not sim.query_skill().is_empty():
		sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_eq("alignment skill ended", sim.query_skill().is_empty(), true)


func _complete_shard_fit(sim: EtheraSimulation) -> void:
	sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": 0.5, "y": 0.5})
	var aligned := false
	for _i in range(_seconds(2.0)):
		_tick(sim, 1)
		if absf(float(sim.query_skill().get("rotation_degrees", 99.0))) <= 24.0:
			aligned = true
			break
	_true("shard fit reached alignment", aligned)
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_eq("shard fit ended", sim.query_skill().is_empty(), true)


func _grant_stone_weapon_need(sim: EtheraSimulation) -> void:
	var actor: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_KHAR_MORR)
	actor["granted_need_ids"] = [EtheraIds.NEED_STONE_WEAPON]
	sim.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})


func _test_stone_weapon_need() -> void:
	var sim := _new_sim()
	var other := _new_sim()
	_eq("lacking a weapon does not create the need", (sim.query_panel().get("needs", []) as Array).size(), 0)
	_eq("lacking a weapon does not create a task", str(sim.query_panel().get("active_task_id", "")), "")
	_grant_stone_weapon_need(sim)
	_grant_stone_weapon_need(other)
	var panel: Dictionary = sim.query_panel()
	_eq("the sole task is active without a click", str(panel.get("active_task_id", "")), EtheraIds.TASK_ACQUIRE_STONE_WEAPON)
	_true("the log records the need appearing", _log_has(sim, "Need appeared: Stone Weapon"))
	_true("the log records the priority stone", _log_has(sim, "Priority stone placed on Acquire a Stone Weapon"))
	_true("the log records the reserved objective", _log_has(sim, "Objective reserved: Shapeable Rock"))
	var reserved: String = str(panel.get("reserved_objective_id", ""))
	_eq("a second start reserves the same rock", reserved, str(other.query_panel().get("reserved_objective_id", "")))
	var rock: Dictionary = sim.world.get_entity(reserved)
	_true("the reserved entity is a manifested shapeable rock", sim.world.is_manifested(rock) and sim.world.has_trait(rock, EtheraIds.TRAIT_ROCK) and sim.world.has_trait(rock, EtheraIds.TRAIT_SHAPEABLE))
	_true("the reserved rock carries her objective trait", sim.world.has_trait(rock, EtheraIds.TRAIT_OBJECTIVE_KHAR_MORR))
	_true("the container stays while a free rock exists", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_CONTAINER)))
	var checklist: Dictionary = panel.get("checklist", {})
	_eq("the checklist states the goal", str(checklist.get("goal", "")), "Acquire a Stone Weapon")
	_eq("unknown solution knowledge stays off the checklist", (checklist.get("requirements", []) as Array).size(), 0)
	_true("the checklist does not name the hidden rock traits", not str(checklist).contains("trait.rock") and not str(checklist).contains("Shapeable"))
	var guide: Dictionary = sim.query_orientation()
	_true("guidance is active for the inhabited character", bool(guide.get("active", false)))
	_eq("guidance names the reserved rock", str(guide.get("entity_id", "")), reserved)
	_eq("cue interval is ten seconds", int(guide.get("cue_interval_ms", 0)), 10000)
	_eq("the wind shade sits beside her", float(guide.get("wave_aside", 0.0)), 1.5)
	_eq("the glint appears just ahead", float(guide.get("glint_ahead", 0.0)), 2.5)
	_eq("the glint travels a short way", float(guide.get("glint_travel", 0.0)), 1.5)
	_true("another character is not given her bearing", not bool(sim.query_orientation(EtheraIds.ENTITY_FOUNTAIN).get("active", true)))
	var kinds: Dictionary = {}
	for index in 8:
		var kind: String = _Orientation.cue_kind(index)
		_true("a cue is one sign", kind == _Orientation.CUE_WIND_WAVE or kind == _Orientation.CUE_GLINT)
		kinds[kind] = true
	_eq("the schedule uses both signs", kinds.size(), 2)
	var seed_before: int = sim.world.objective_pick_seed
	sim.apply({"type": EtheraIds.CMD_SELECT_NEED, "need_id": EtheraIds.NEED_STONE_WEAPON})
	_true("the log records the selected need", _log_has(sim, "Need selected: Stone Weapon"))
	_eq("selecting the only need does not move the stone", str(sim.query_panel().get("reserved_objective_id", "")), reserved)
	_eq("selecting the only need does not roll again", sim.world.objective_pick_seed, seed_before)
	sim.apply({"type": EtheraIds.CMD_ACTIVATE_TASK, "task_id": EtheraIds.TASK_ACQUIRE_STONE_WEAPON})
	_true("the log records the chosen task", _log_has(sim, "Task chosen: Acquire a Stone Weapon"))
	_eq("activating the current task leaves the rock", str(sim.query_panel().get("reserved_objective_id", "")), reserved)

	sim.world.set_position(reserved, Vector3(30.0, 0.0, 12.0), 0.0)
	var moved: Dictionary = sim.query_orientation()
	_eq("guidance follows the same entity", str(moved.get("entity_id", "")), reserved)
	_eq("guidance uses the new position", float(moved.get("x", 0.0)), float(sim.world.get_entity(reserved).get("position", {}).get("x", 0.0)))

	sim.world.get_entity(reserved)["manifested"] = false
	sim.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	var again: String = str(sim.query_panel().get("reserved_objective_id", ""))
	_true("an invalid rock is replaced by another free one", again != "" and again != reserved)
	_true("the old rock loses the objective trait", not sim.world.has_trait(sim.world.get_entity(reserved), EtheraIds.TRAIT_OBJECTIVE_KHAR_MORR))
	_true("the container is still untouched", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_CONTAINER)))

	for entity_id in sim.world.entities.keys():
		var entity: Dictionary = sim.world.get_entity(str(entity_id))
		if sim.world.has_trait(entity, EtheraIds.TRAIT_ROCK) and sim.world.has_trait(entity, EtheraIds.TRAIT_SHAPEABLE):
			entity["manifested"] = false
	var shards_before: int = sim.world.shards.size()
	sim.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	var placed: String = str(sim.query_panel().get("reserved_objective_id", ""))
	var placed_rock: Dictionary = sim.world.get_entity(placed)
	_eq("the fallback rock occupies the village node", str(placed_rock.get("world_node_id", "")), EtheraIds.NODE_VILLAGE_001)
	_true("the fallback rock is shapeable", sim.world.has_trait(placed_rock, EtheraIds.TRAIT_SHAPEABLE))
	_true("the container is no longer manifested", not sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_CONTAINER)))
	_true("the club inside the container stays unmanifested", not sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_CLUB_GREEN)))
	_eq("placement creates no shard", sim.world.shards.size(), shards_before)

	var bare := _new_sim()
	_grant_stone_weapon_need(bare)
	var actor: Dictionary = bare.world.get_entity(EtheraIds.ENTITY_KHAR_MORR)
	var traits: Array = (actor.get("traits", []) as Array).duplicate()
	traits.erase(EtheraIds.TRAIT_WEAPON_SHAPING)
	actor["traits"] = traits
	bare.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	var bare_panel: Dictionary = bare.query_panel()
	_eq("the need remains without weapon shaping", str((bare_panel.get("needs", []) as Array)[0].get("id", "")), EtheraIds.NEED_STONE_WEAPON)
	_eq("no task is given without the capability", str(bare_panel.get("active_task_id", "")), "")
	_true("guidance stops when there is no task", not bool(bare.query_orientation().get("active", true)))
	_eq("no objective is reserved without a task", _objective_mark_count(bare), 0)
	_true("losing the capability removes the task in the log", _log_has(bare, "Task removed: Acquire a Stone Weapon"))
	_true("losing the capability is not fulfillment", not _log_has(bare, "Task fulfilled:"))

	var pickup := _new_sim()
	_grant_stone_weapon_need(pickup)
	var marked: String = str(pickup.query_panel().get("reserved_objective_id", ""))
	pickup.apply({"type": EtheraIds.CMD_PICKUP_ITEM, "item_id": EtheraIds.ENTITY_CLUB_UMBER})
	_arrive(pickup, EtheraIds.ENTITY_KHAR_MORR)
	var after_pickup: Dictionary = pickup.query_panel()
	_eq("picking up a stone weapon clears the need", (after_pickup.get("needs", []) as Array).size(), 0)
	_eq("picking up a stone weapon clears the task", str(after_pickup.get("active_task_id", "")), "")
	_true("guidance stops after the need is met", not bool(pickup.query_orientation().get("active", true)))
	_true("the reservation is released after pickup", not pickup.world.has_trait(pickup.world.get_entity(marked), EtheraIds.TRAIT_OBJECTIVE_KHAR_MORR))
	_true("the log records the fulfilled need", _log_has(pickup, "Need fulfilled: Stone Weapon"))
	_true("the log records the fulfilled task", _log_has(pickup, "Task fulfilled: Acquire a Stone Weapon"))
	_true("the log records the released objective", _log_has(pickup, "Objective released"))
	pickup.development_note("orientation", "Divine Orientation: Ground Glint")
	_true("a development note stays in the log", _log_has(pickup, "Divine Orientation: Ground Glint"))

	var blocked := _new_sim()
	_grant_stone_weapon_need(blocked)
	blocked.catalog.needs["need.test_block"] = {
		"id": "need.test_block",
		"name": "Test Block",
		"important": false,
		"task_id": "task.test_block",
		"present_while": {"type": "lacks_possessed_item_trait", "trait_id": "trait.test_unpossessed"},
	}
	blocked.catalog.tasks["task.test_block"] = {
		"id": "task.test_block",
		"name": "Resolve The Block",
		"kind": "common",
		"need_id": "need.test_block",
		"requires_trait_id": EtheraIds.TRAIT_GRIMNIR,
		"objective_trait_id": EtheraIds.TRAIT_OBJECTIVE_KHAR_MORR,
		"goal": "Resolve the block",
		"checklist": [],
		"completion": {"type": "none"},
		"hidden_solution": {"type": "none"},
	}
	blocked.catalog.states["state.test_impossible_task"] = {
		"id": "state.test_impossible_task",
		"impossible_task_ids": [EtheraIds.TASK_ACQUIRE_STONE_WEAPON],
		"resolving_task_id": "task.test_block",
	}
	blocked.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	_eq("a new task does not take the stone", str(blocked.query_panel().get("active_task_id", "")), EtheraIds.TASK_ACQUIRE_STONE_WEAPON)
	blocked.world.add_state(EtheraIds.ENTITY_KHAR_MORR, "state.test_impossible_task")
	blocked.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	_eq("an impossible task yields the stone to the resolving task", str(blocked.query_panel().get("active_task_id", "")), "task.test_block")
	blocked.world.remove_state(EtheraIds.ENTITY_KHAR_MORR, "state.test_impossible_task")
	blocked.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	_eq("clearing the block does not move the stone back", str(blocked.query_panel().get("active_task_id", "")), "task.test_block")
	blocked.apply({"type": EtheraIds.CMD_ACTIVATE_TASK, "task_id": EtheraIds.TASK_ACQUIRE_STONE_WEAPON})
	_eq("the player can return the stone", str(blocked.query_panel().get("active_task_id", "")), EtheraIds.TASK_ACQUIRE_STONE_WEAPON)


func _log_has(sim: EtheraSimulation, text: String) -> bool:
	for entry in sim.query_dev_log():
		if str(entry.get("text", "")).find(text) >= 0:
			return true
	return false


func _objective_mark_count(sim: EtheraSimulation) -> int:
	var count: int = 0
	for entity_id in sim.world.entities.keys():
		if sim.world.has_trait(sim.world.get_entity(str(entity_id)), EtheraIds.TRAIT_OBJECTIVE_KHAR_MORR):
			count += 1
	return count


func _tick(sim: EtheraSimulation, ticks: int) -> void:
	sim.apply({"type": EtheraIds.CMD_TICK, "ticks": ticks})


func _seconds(seconds: float) -> int:
	return int(seconds * float(EtheraWorld.TICKS_PER_SECOND))


func _on_grid(value: float, quantum: float) -> bool:
	return absf(value * quantum - round(value * quantum)) < 0.000001


func _motor(sim: EtheraSimulation, entity_id: String = EtheraIds.ENTITY_KHAR_MORR) -> Dictionary:
	return sim.world.walk_motor.get(entity_id, {})


func _motor_reason(sim: EtheraSimulation, entity_id: String = EtheraIds.ENTITY_KHAR_MORR) -> String:
	return str(_motor(sim, entity_id).get("reason", ""))


func _motor_speed(sim: EtheraSimulation, entity_id: String = EtheraIds.ENTITY_KHAR_MORR) -> float:
	return float(_motor(sim, entity_id).get("speed", 0.0))


func _assert_revealed_beside(sim: EtheraSimulation, container_id: String, item_id: String, label: String) -> void:
	var origin: Vector3 = sim.world.position_of(sim.world.get_entity(container_id))
	var actor: Vector3 = sim.world.position_of(sim.world.inhabiting())
	var item: Vector3 = sim.world.position_of(sim.world.get_entity(item_id))
	var to_actor: Vector3 = actor - origin
	var to_item: Vector3 = item - origin
	to_actor.y = 0.0
	to_item.y = 0.0
	_true("%s sits beside the container" % label, to_item.length() >= 0.75)
	_true("%s is not on the opener" % label, item.distance_to(actor) >= 0.7)
	if to_actor.length() > 0.001 and to_item.length() > 0.001:
		_true("%s is off the opener's side of the object" % label, absf(to_item.normalized().dot(to_actor.normalized())) < 0.4)


func _place_beside(sim: EtheraSimulation, entity_id: String, offset: Vector3 = Vector3(2.5, 0.0, 0.0)) -> void:
	var at: Vector3 = sim.world.position_of(sim.world.get_entity(entity_id))
	sim.world.set_position(EtheraIds.ENTITY_KHAR_MORR, at + offset)


func _test_village_delivery() -> void:
	var sim := _new_sim()
	_true("with no task the fountain can give one", _ids(sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN)).has(EtheraIds.INTERACTION_ECHO_ATTUNEMENT))
	_complete_shape_weapon(sim)
	_eq("two villagers need two weapons", sim.world.villager_count(), 2)
	_eq("the hall is empty of weapons", sim.world.store_count(EtheraIds.TRAIT_STONE_WEAPON), 0)
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_ATTUNEMENT,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shard_fit(sim)
	_eq("one attunement gives the weapon delivery", str(sim.query_panel().get("active_task_id", "")), EtheraIds.TASK_DELIVER_STONE_WEAPON)
	_true("taking the task is announced like a discovery", _log_has(sim, "Deliver a Stone Weapon"))
	_eq("carrying the weapon points her at the hall", str(sim.query_orientation().get("entity_id", "")), EtheraIds.ENTITY_TOWN_HALL)
	var equipped: String = sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON)
	sim.apply({
		"type": EtheraIds.CMD_DEPOSIT_EQUIPPED,
		"slot_id": EtheraIds.SLOT_SMALL_WEAPON,
		"target_id": EtheraIds.ENTITY_TOWN_HALL,
	})
	_eq("the hall holds the weapon", sim.world.store_count(EtheraIds.TRAIT_STONE_WEAPON), 1)
	_eq("delivering does not create the stone weapon need", (sim.query_panel().get("needs", []) as Array).size(), 0)
	_true("she can ask the fountain for the next delivery", _ids(sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN)).has(EtheraIds.INTERACTION_ECHO_ATTUNEMENT))
	_eq("the weapon is no longer equipped", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), "")
	_true("one delivery ends that task", str(sim.query_panel().get("active_task_id", "")) != EtheraIds.TASK_DELIVER_STONE_WEAPON)
	_eq("the stored weapon can be taken back", equipped != "", true)
	sim.apply({"type": EtheraIds.CMD_TAKE_STORED, "item_id": equipped})
	_eq("taking it equips it again", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON), equipped)
	_eq("the hall is empty again", sim.world.store_count(EtheraIds.TRAIT_STONE_WEAPON), 0)
	var seek := _new_sim()
	_place_beside(seek, EtheraIds.ENTITY_FOUNTAIN)
	seek.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_ATTUNEMENT,
	})
	_arrive(seek, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shard_fit(seek)
	var pointed: String = str(seek.query_orientation().get("entity_id", ""))
	var rock: Dictionary = seek.world.get_entity(pointed)
	_true("without a weapon the delivery points at a shapeable rock", seek.world.is_manifested(rock) and seek.world.has_trait(rock, EtheraIds.TRAIT_ROCK) and seek.world.has_trait(rock, EtheraIds.TRAIT_SHAPEABLE))
	rock["states"] = [EtheraIds.STATE_SHAPED]
	seek.apply({"type": EtheraIds.CMD_TICK, "ticks": 1})
	var later: String = str(seek.query_orientation().get("entity_id", ""))
	var later_rock: Dictionary = seek.world.get_entity(later)
	_true("a rock on cooldown is not the objective", later != pointed and not (later_rock.get("states", []) as Array).has(EtheraIds.STATE_SHAPED))
	var herb := _new_sim()
	var open_patch := ""
	for entity_id in herb.world.entities.keys():
		var patch: Dictionary = herb.world.get_entity(str(entity_id))
		if str(patch.get("kind", "")) != EtheraIds.KIND_GRASS:
			continue
		if open_patch == "":
			open_patch = str(entity_id)
			patch["opened"] = false
		else:
			patch["opened"] = true
	var hall: Dictionary = herb.world.get_entity(EtheraIds.ENTITY_TOWN_HALL)
	var stored: Array = hall.get("contained_item_ids", [])
	for index in herb.world.villager_count():
		var club_id := "entity.test_club.%d" % index
		herb.world.add_entity({
			"id": club_id,
			"kind": "item",
			"name": "Stone Club",
			"traits": [EtheraIds.TRAIT_STONE_WEAPON],
			"manifested": false,
			"container_id": EtheraIds.ENTITY_TOWN_HALL,
		})
		stored.append(club_id)
	hall["contained_item_ids"] = stored
	_place_beside(herb, EtheraIds.ENTITY_FOUNTAIN)
	herb.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_ATTUNEMENT,
	})
	_arrive(herb, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shard_fit(herb)
	_eq("a harvested patch is not the herb objective", str(herb.query_orientation().get("entity_id", "")), open_patch)
	seek.world.set_position(EtheraIds.ENTITY_KHAR_MORR, seek.world.position_of(seek.world.get_entity(EtheraIds.ENTITY_TOWN_HALL)) + Vector3(20.0, 0.0, 0.0))
	_true("the hall stays closed from far away", not bool(seek.query_store().get("in_reach", true)))
	seek.apply({"type": EtheraIds.CMD_OPEN_CONTAINER, "target_id": EtheraIds.ENTITY_TOWN_HALL})
	_eq("she walks to the hall before it opens", _motor_reason(seek), "open")
	_true("the hall is not open while she is still walking", not bool(seek.world.get_entity(EtheraIds.ENTITY_TOWN_HALL).get("opened", false)))
	_arrive(seek, EtheraIds.ENTITY_KHAR_MORR)
	_true("arriving beside the hall opens it", bool(seek.world.get_entity(EtheraIds.ENTITY_TOWN_HALL).get("opened", false)))
	_true("the store is in reach once she arrives", bool(seek.query_store().get("in_reach", false)))


func _test_delivery_objective_follows_capability() -> void:
	var sim := _new_sim()
	sim.apply({"type": EtheraIds.CMD_RELEASE_INHABITATION})
	sim.apply({"type": EtheraIds.CMD_INHABIT, "entity_id": EtheraIds.ENTITY_TRAKIA_VORR})
	var fountain_at: Vector3 = sim.world.position_of(sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN))
	sim.world.set_position(EtheraIds.ENTITY_TRAKIA_VORR, fountain_at + Vector3(2.5, 0.0, 0.0))
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_ATTUNEMENT,
	})
	_arrive(sim, EtheraIds.ENTITY_TRAKIA_VORR)
	_complete_shard_fit(sim)
	var pointed: Dictionary = sim.world.get_entity(str(sim.query_orientation().get("entity_id", "")))
	_true("without shaping the objective is an existing stone weapon", sim.world.has_trait(pointed, EtheraIds.TRAIT_STONE_WEAPON))
	_true("that weapon is not waiting in the town hall", str(pointed.get("container_id", "")) != EtheraIds.ENTITY_TOWN_HALL)
	var blocked := _new_sim()
	blocked.catalog.states["state.test_unshaped"] = {
		"id": "state.test_unshaped",
		"name": "Unshaped",
		"blocked_interaction_ids": [EtheraIds.INTERACTION_SHAPE_WEAPON],
	}
	var actor: Dictionary = blocked.world.get_entity(EtheraIds.ENTITY_KHAR_MORR)
	actor["states"] = ["state.test_unshaped"]
	_place_beside(blocked, EtheraIds.ENTITY_FOUNTAIN)
	blocked.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_FOUNTAIN,
		"interaction_id": EtheraIds.INTERACTION_ECHO_ATTUNEMENT,
	})
	_arrive(blocked, EtheraIds.ENTITY_KHAR_MORR)
	_complete_shard_fit(blocked)
	var instead: Dictionary = blocked.world.get_entity(str(blocked.query_orientation().get("entity_id", "")))
	_true("a state that blocks shaping points at an existing weapon", blocked.world.has_trait(instead, EtheraIds.TRAIT_STONE_WEAPON))


func _test_spectate_and_inhabit() -> void:
	var sim := _new_sim()
	_eq("play starts in Khar-Morr", sim.query_inhabited_id(), EtheraIds.ENTITY_KHAR_MORR)
	var before: Dictionary = sim.query_roster()
	_eq("both lives are listed", (before.get("characters", []) as Array).size(), 2)
	_eq("the inhabited life is not free", (before.get("free", []) as Array).size(), 1)
	sim.apply({"type": EtheraIds.CMD_RELEASE_INHABITATION})
	_eq("spectating leaves the life", sim.query_inhabited_id(), "")
	var waiting: Dictionary = sim.query_roster()
	_eq("both lives are free once she steps out", (waiting.get("free", []) as Array).size(), 2)
	sim.apply({"type": EtheraIds.CMD_INHABIT, "entity_id": EtheraIds.ENTITY_TRAKIA_VORR})
	_eq("Trakia-Vorr can be inhabited", sim.query_inhabited_id(), EtheraIds.ENTITY_TRAKIA_VORR)
	sim.apply({"type": EtheraIds.CMD_INHABIT, "entity_id": EtheraIds.ENTITY_KHAR_MORR})
	_eq("a second life waits until this one is left", sim.query_inhabited_id(), EtheraIds.ENTITY_TRAKIA_VORR)
	_true("her weapon did not follow the player", sim.world.equipped_item_id(sim.world.get_entity(EtheraIds.ENTITY_KHAR_MORR), EtheraIds.SLOT_SMALL_WEAPON) == "")
	sim.apply({"type": EtheraIds.CMD_RELEASE_INHABITATION})
	sim.apply({"type": EtheraIds.CMD_INHABIT, "entity_id": EtheraIds.ENTITY_KHAR_MORR})
	_eq("Khar-Morr can be inhabited again", sim.query_inhabited_id(), EtheraIds.ENTITY_KHAR_MORR)


func _test_trakia_vorr_and_greeting() -> void:
	var sim := _new_sim()
	var trakia: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_TRAKIA_VORR)
	_eq("Trakia-Vorr is named", str(trakia.get("name", "")), "Trakia-Vorr the Path Maker")
	_true("Trakia-Vorr is manifested", sim.world.is_manifested(trakia))
	_true("Trakia-Vorr is inhabitable", bool(trakia.get("inhabitable", false)))
	_eq("play still inhabits Khar-Morr", sim.world.inhabited_entity_id, EtheraIds.ENTITY_KHAR_MORR)
	_true("Trakia-Vorr is Grimnir", sim.world.has_trait(trakia, EtheraIds.TRAIT_GRIMNIR))
	_true("Trakia-Vorr is Female", sim.world.has_trait(trakia, EtheraIds.TRAIT_FEMALE))
	_true("Trakia-Vorr holds shards", sim.world.has_trait(trakia, EtheraIds.TRAIT_SHARD_HOLDER))
	_true("Trakia-Vorr does not shape weapons", not sim.world.has_trait(trakia, EtheraIds.TRAIT_WEAPON_SHAPING))
	_eq("Trakia-Vorr uses her own model", str(trakia.get("presentation", {}).get("asset_id", "")), "asset.trakia_vorr")
	var on_her: Array = _ids(sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_TRAKIA_VORR))
	_true("Khar-Morr can greet Trakia-Vorr", on_her.has(EtheraIds.INTERACTION_GREET))
	var the_other_way: Array = _ids(sim.query_available_interactions(EtheraIds.ENTITY_TRAKIA_VORR, EtheraIds.ENTITY_KHAR_MORR))
	_true("Trakia-Vorr can greet Khar-Morr", the_other_way.has(EtheraIds.INTERACTION_GREET))
	var on_self: Array = _ids(sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_KHAR_MORR))
	_true("a Grimnir does not greet herself", not on_self.has(EtheraIds.INTERACTION_GREET))
	var on_fountain: Array = _ids(sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN))
	_true("the Fountain is not greeted", not on_fountain.has(EtheraIds.INTERACTION_GREET))
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_TRAKIA_VORR,
		"interaction_id": EtheraIds.INTERACTION_GREET,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("greeting uses Call and Response", str(sim.query_skill().get("skill_phase_id", "")), EtheraIds.SKILL_CALL_AND_RESPONSE)
	_eq("the hello waits for the skill", _speech_text(sim, EtheraIds.ENTITY_KHAR_MORR), "")
	_finish_alignment(sim)
	_eq("the speaker says Hi", _speech_text(sim, EtheraIds.ENTITY_KHAR_MORR), "Hi")
	_eq("the answer waits a second", _speech_text(sim, EtheraIds.ENTITY_TRAKIA_VORR), "")
	_true("the greeting holds her focus", _greeting_focus_target(sim) == EtheraIds.ENTITY_TRAKIA_VORR)
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": 0.0, "y": 0.0, "z": 0.0})
	_true("she cannot walk away during the greeting", not sim.world.walk_motor.has(EtheraIds.ENTITY_KHAR_MORR))
	_tick(sim, _seconds(1.0))
	_eq("the target answers Hi", _speech_text(sim, EtheraIds.ENTITY_TRAKIA_VORR), "Hi")
	_eq("the speaker is still saying Hi", _speech_text(sim, EtheraIds.ENTITY_KHAR_MORR), "Hi")
	_eq("one greeting record", sim.world.shards.size(), 1)
	var shard: Dictionary = sim.world.shards.values()[0]
	_eq("the record is the greeting", str(shard.get("action_id", "")), EtheraIds.INTERACTION_GREET)
	_true("Khar-Morr knows the greeting", sim.world.known_shards(sim.world.get_entity(EtheraIds.ENTITY_KHAR_MORR)).size() == 1)
	_true("Trakia-Vorr knows the greeting", sim.world.known_shards(sim.world.get_entity(EtheraIds.ENTITY_TRAKIA_VORR)).size() == 1)
	var known: Array = _ids(sim.query_panel().get("known_interactions", []))
	_true("Greet is recorded once she has used it", known.has(EtheraIds.INTERACTION_GREET))
	_tick(sim, _seconds(2.2))
	_eq("the greeting fades", _speech_text(sim, EtheraIds.ENTITY_KHAR_MORR), "")
	_eq("the answer has faded", _speech_text(sim, EtheraIds.ENTITY_TRAKIA_VORR), "")
	_eq("focus releases when the answer ends", _greeting_focus_target(sim), "")


func _greeting_focus_target(sim: EtheraSimulation) -> String:
	for entity in sim.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == EtheraIds.ENTITY_KHAR_MORR:
			return str(entity.get("greeting_focus_target_id", ""))
	return ""


func _speech_text(sim: EtheraSimulation, entity_id: String) -> String:
	for entity in sim.query_world_view().get("entities", []):
		if str(entity.get("id", "")) == entity_id:
			return str(entity.get("speech_text", ""))
	return ""


func _arrive(sim: EtheraSimulation, entity_id: String) -> void:
	for _i in range(480):
		if not sim.world.walk_motor.has(entity_id):
			return
		_tick(sim, 1)
	_true("arrived within timeout", not sim.world.walk_motor.has(entity_id))


func _hide_landscape_occupancy(sim: EtheraSimulation) -> void:
	for entity_id in sim.world.entities.keys():
		var id: String = str(entity_id)
		if id.begins_with("entity.grass.") or id.begins_with("entity.shapeable_rock.scatter"):
			sim.world.entities[id]["manifested"] = false


func _new_sim() -> EtheraSimulation:
	var catalog := EtheraCatalog.new()
	var err: Error = catalog.load_from_res()
	_eq("catalog loads", err, OK)
	return EtheraSimulation.new(catalog)


func _ids(entries: Variant) -> Array:
	var ids: Array = []
	if typeof(entries) != TYPE_ARRAY:
		return ids
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY:
			ids.append(str(entry.get("id", "")))
		else:
			ids.append(str(entry))
	return ids


func _eq(label: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		_failed.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
	else:
		_passed += 1


func _true(label: String, value: bool) -> void:
	_eq(label, value, true)
