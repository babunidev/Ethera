extends RefCounted
class_name EtheraSimulationTests

var _failed: Array[String] = []
var _passed: int = 0

func run() -> int:
	_test_starting_data()
	_test_walking()
	_test_focus_hold_slows_pace()
	_test_shape_trace_timeout_and_success()
	_test_right_click_cancels_approach()
	_test_pickup_walks_into_reach()
	_test_pickup_swap_and_occupied_shaping()
	_test_echo_imprint_and_event_distribution()
	_test_availability_and_historical_resolution()
	_test_blockers_and_injury()
	_test_radial_selection()
	_test_event_envelope_and_logs()
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
	_eq("start small weapon empty", bool(panel.get("equipment", {}).get(EtheraIds.SLOT_SMALL_WEAPON, {}).get("empty", false)), true)
	var regions: Dictionary = panel.get("body_regions", {})
	for region_id in [EtheraIds.BODY_HEAD, EtheraIds.BODY_TORSO, EtheraIds.BODY_ARMS, EtheraIds.BODY_LEGS]:
		_eq("healthy %s" % region_id, str(regions.get(region_id, {}).get("condition", "")), "healthy")
	_eq("body region carries its authored name", str(regions.get(EtheraIds.BODY_ARMS, {}).get("name", "")), "Arms")
	var trait_ids := _ids(panel.get("traits", []))
	_true("has grimnir", trait_ids.has(EtheraIds.TRAIT_GRIMNIR))
	_true("has weapon shaping", trait_ids.has(EtheraIds.TRAIT_WEAPON_SHAPING))
	_true("has echo imprint", trait_ids.has(EtheraIds.TRAIT_ECHO_IMPRINT))
	_eq("start states empty", (panel.get("states", []) as Array).size(), 0)
	var fountain: Dictionary = sim.world.get_entity(EtheraIds.ENTITY_FOUNTAIN)
	_eq("fountain shards empty", sim.world.known_shards(fountain).size(), 0)
	_true("fountain has echo", sim.world.has_trait(fountain, EtheraIds.TRAIT_ECHO))
	_true("rock manifested", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_ROCK)))
	_eq("inhabiting khar-morr", sim.world.inhabited_entity_id, EtheraIds.ENTITY_KHAR_MORR)


func _test_walking() -> void:
	var sim := _new_sim()
	var start: Vector3 = sim.world.position_of(sim.world.inhabiting())
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": start.x + 2.0, "y": 0.0, "z": start.z})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var after: Vector3 = sim.world.position_of(sim.world.inhabiting())
	_true("walked closer to destination", absf(after.x - (start.x + 2.0)) < 0.25)
	_true("retained ground height", absf(after.y - start.y) < 0.001)


func _test_focus_hold_slows_pace() -> void:
	var normal := _new_sim()
	var slowed := _new_sim()
	var start: Vector3 = normal.world.position_of(normal.world.inhabiting())
	var full_speed: float = float(slowed.world.tuning.get("walk_speed", 2.4))
	var scale: float = float(slowed.world.tuning.get("focus_hold_speed_scale", 0.45))
	slowed.apply({"type": EtheraIds.CMD_SET_FOCUS_HOLD, "held": true})
	for sim in [normal, slowed]:
		sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": start.x + 20.0, "y": 0.0, "z": start.z})
		for _i in range(20):
			sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 50})
	_true("the held pace reaches the scaled speed", absf(_motor_speed(slowed) - full_speed * scale) < 0.01)
	_true("the free pace reaches the full speed", absf(_motor_speed(normal) - full_speed) < 0.01)
	var covered: float = slowed.world.position_of(slowed.world.inhabiting()).distance_to(start)
	_true("holding focus covers less ground", covered < normal.world.position_of(normal.world.inhabiting()).distance_to(start))
	slowed.apply({"type": EtheraIds.CMD_SET_FOCUS_HOLD, "held": false})
	for _i in range(20):
		slowed.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 50})
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
	sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 9000})
	_eq("timeout creates no shards", sim.world.shards.size(), 0)
	_true("timeout leaves rock", sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_ROCK)))
	_true("timeout leaves slot empty", sim.world.equipped_item_id(sim.world.inhabiting(), EtheraIds.SLOT_SMALL_WEAPON) == "")
	_complete_shape_weapon(sim)
	_true("rock unmanifested after success", not sim.world.is_manifested(sim.world.get_entity(EtheraIds.ENTITY_ROCK)))
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


func _test_right_click_cancels_approach() -> void:
	var sim := _new_sim()
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_eq("approach is running", str(sim.query_skill().get("phase", "")), "approaching")
	sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 100})
	var here: Vector3 = sim.world.position_of(sim.world.inhabiting())
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": here.x, "y": 0.0, "z": here.z + 3.0})
	_true("the round is abandoned", sim.query_skill().is_empty())
	_eq("movement returns to a plain walk", _motor_reason(sim), "walk")
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_true("no skill phase starts after cancelling", sim.query_skill().is_empty())
	_true("cancelling creates no shard", sim.world.shards.is_empty())
	_eq("cancelling records no history", sim.query_recent_interactions().size(), 0)
	_true("the interaction is offered again", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_ROCK).size() > 0)

	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	_eq("skill phase reached on the retry", str(sim.query_skill().get("phase", "")), "skill")
	var during: Vector3 = sim.world.position_of(sim.world.inhabiting())
	sim.apply({"type": EtheraIds.CMD_SET_WALK_DESTINATION, "x": during.x + 4.0, "y": 0.0, "z": during.z})
	_true("a running skill phase ignores new destinations", not sim.walk_velocity.has(EtheraIds.ENTITY_KHAR_MORR))
	_eq("the running skill phase survives", str(sim.query_skill().get("phase", "")), "skill")

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
	_true("pickup still creates no shard", sim.world.shards.is_empty())


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
	_true("a pickup already within reach needs no walk", not sim.walk_velocity.has(EtheraIds.ENTITY_KHAR_MORR))
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
	_true("wrong click leaves skill running", str(sim.query_skill().get("phase", "")) == "skill")
	sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 8000})
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


func _test_availability_and_historical_resolution() -> void:
	var sim := _new_sim()
	_complete_shape_weapon(sim)
	_complete_echo_imprint(sim)
	_eq("imprint unavailable when fountain has every known shard", sim.query_available_interactions(EtheraIds.ENTITY_KHAR_MORR, EtheraIds.ENTITY_FOUNTAIN).size(), 0)
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
	_eq("deadzone cancels", EtheraRadialSelection.highlighted_index(center, center + Vector2(10, 0), 2), -1)
	_eq("up selects first of two", EtheraRadialSelection.highlighted_index(center, center + Vector2(0, -80), 2), 0)
	_eq("down selects second of two", EtheraRadialSelection.highlighted_index(center, center + Vector2(0, 80), 2), 1)
	_true("empty radial has no highlight", EtheraRadialSelection.highlighted_index(center, center + Vector2(0, -80), 0) == -1)


func _test_event_envelope_and_logs() -> void:
	var sim := _new_sim()
	sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 5000})
	var events: Array[Dictionary] = []
	sim.apply({
		"type": EtheraIds.CMD_BEGIN_INTERACTION,
		"target_id": EtheraIds.ENTITY_ROCK,
		"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
	})
	_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var phase: Dictionary = sim.catalog.get_skill_phase(EtheraIds.SKILL_SHAPE_TRACE)
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
	if str(sim.query_skill().get("phase", "")) != "skill":
		sim.apply({
			"type": EtheraIds.CMD_BEGIN_INTERACTION,
			"target_id": EtheraIds.ENTITY_ROCK,
			"interaction_id": EtheraIds.INTERACTION_SHAPE_WEAPON,
		})
		_arrive(sim, EtheraIds.ENTITY_KHAR_MORR)
	var phase: Dictionary = sim.catalog.get_skill_phase(EtheraIds.SKILL_SHAPE_TRACE)
	for checkpoint in phase.get("checkpoints", []):
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
	sim.apply({"type": EtheraIds.CMD_SKILL_POINTER, "x": 0.5, "y": 0.5})
	var aligned := false
	for _i in range(40):
		sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 50})
		if absf(float(sim.query_skill().get("rotation_degrees", 99.0))) <= 12.0:
			aligned = true
			break
	_true("shard fit reached alignment", aligned)
	sim.apply({"type": EtheraIds.CMD_SKILL_CLICK})
	_eq("imprint skill ended", sim.query_skill().is_empty(), true)


func _motor(sim: EtheraSimulation, entity_id: String = EtheraIds.ENTITY_KHAR_MORR) -> Dictionary:
	return sim.walk_velocity.get(entity_id, {})


func _motor_reason(sim: EtheraSimulation, entity_id: String = EtheraIds.ENTITY_KHAR_MORR) -> String:
	return str(_motor(sim, entity_id).get("reason", ""))


func _motor_speed(sim: EtheraSimulation, entity_id: String = EtheraIds.ENTITY_KHAR_MORR) -> float:
	return float(_motor(sim, entity_id).get("speed", 0.0))


func _arrive(sim: EtheraSimulation, entity_id: String) -> void:
	for _i in range(240):
		if not sim.walk_velocity.has(entity_id):
			return
		sim.apply({"type": EtheraIds.CMD_TICK, "delta_ms": 50})
	_true("arrived within timeout", not sim.walk_velocity.has(entity_id))


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
