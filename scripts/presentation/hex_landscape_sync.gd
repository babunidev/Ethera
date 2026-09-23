extends RefCounted
class_name EtheraHexLandscapeSync

## Writes authored hex grass and stones into landscape_scatter.json as the
## existing harvestable grass and shapeable-rock entities.

const SCATTER_PATH := "res://data/milestone1/landscape_scatter.json"
const GRASS_KINDS := [
	{"variant": 0, "name": "Long Grass"},
	{"variant": 1, "name": "Soft Tuft"},
	{"variant": 2, "name": "Split Blade"},
	{"variant": 3, "name": "Flat Leaf"},
	{"variant": 4, "name": "Needle Grass"},
]


func sync(hex: EtheraHexTile) -> Dictionary:
	var payload: Dictionary = _load_scatter()
	var entities: Array = payload.get("entities", [])
	var kept: Array = []
	for raw in entities:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if bool((raw.get("presentation", {}) as Dictionary).get("hex_authored", false)):
			continue
		kept.append(raw)
	var next_grass: int = _next_index(kept, "entity.grass.")
	var next_rock: int = _next_index(kept, "entity.shapeable_rock.scatter.")
	var grass_n := 0
	var rock_n := 0
	for child in hex.get_children():
		if child is EtheraGrassClump:
			var grass := child as EtheraGrassClump
			if grass.entity_id == "":
				grass.entity_id = "entity.grass.%d" % next_grass
				next_grass += 1
			kept.append_array(_grass_records(grass))
			grass_n += 1
		elif child is EtheraScatterStone:
			var stone := child as EtheraScatterStone
			if stone.entity_id == "":
				stone.entity_id = "entity.shapeable_rock.scatter.%d" % next_rock
				next_rock += 1
			kept.append(_rock_record(stone))
			rock_n += 1
	payload["entities"] = kept
	payload["notes"] = "Seeded village clutter plus authored hex grass and shapeable rocks. Grass occupies nothing."
	_save_scatter(payload)
	return {"grass": grass_n, "rocks": rock_n}


func _grass_records(grass: EtheraGrassClump) -> Array:
	var index: int = _suffix_index(grass.entity_id)
	var kind: Dictionary = GRASS_KINDS[posmod(grass.grass_variant, GRASS_KINDS.size())]
	var blades: int = clampi(grass.blade_count, 15, 30)
	var x: float = snappedf(grass.position.x, 0.001)
	var z: float = snappedf(grass.position.z, 0.001)
	var yaw: float = snappedf(grass.rotation.y, 0.001)
	var bundle_id := "entity.grass.bundle.%d" % index
	return [
		{
			"id": grass.entity_id,
			"kind": "grass",
			"name": str(kind.get("name", "Long Grass")),
			"place_id": "place.village_center",
			"traits": ["trait.container"],
			"opened": false,
			"contained_item_ids": [bundle_id],
			"states": [],
			"position": {"x": x, "y": 0.0, "z": z},
			"yaw": yaw,
			"manifested": true,
			"presentation": {
				"asset_id": "asset.grass",
				"variant": int(kind.get("variant", 0)),
				"blade_count": blades,
				"hex_authored": true,
			},
		},
		{
			"id": bundle_id,
			"kind": "item",
			"name": "Grass Bundle",
			"template_id": "template.grass_leaf",
			"place_id": "place.village_center",
			"traits": ["trait.herb"],
			"condition": "okay",
			"equipment_slot_id": "slot.herb",
			"attachment": "hip",
			"holder_id": null,
			"container_id": grass.entity_id,
			"equipped_slot_id": null,
			"position": {"x": x, "y": 0.0, "z": z},
			"yaw": yaw,
			"manifested": false,
			"presentation": {
				"asset_id": "asset.grass",
				"variant": int(kind.get("variant", 0)),
				"blade_count": 5,
				"bundle": true,
				"hex_authored": true,
			},
		},
	]


func _rock_record(stone: EtheraScatterStone) -> Dictionary:
	var size: float = snappedf(stone.stone_size, 0.001)
	return {
		"id": stone.entity_id,
		"kind": "world_object",
		"name": "Shapeable Rock",
		"place_id": "place.village_center",
		"traits": ["trait.rock", "trait.shapeable"],
		"states": [],
		"manifested": true,
		"yields_template_id": "template.stone_club",
		"yields_base_color": "slate",
		"position": {
			"x": snappedf(stone.position.x, 0.001),
			"y": 0.0,
			"z": snappedf(stone.position.z, 0.001),
		},
		"yaw": snappedf(stone.rotation.y, 0.001),
		"occupancy": {"radius": snappedf(stone.occupancy_radius(), 0.001)},
		"presentation": {
			"asset_id": "asset.shapeable_rock",
			"hex_authored": true,
			"scale": {"x": size, "y": size, "z": size},
		},
	}


func _next_index(entities: Array, prefix: String) -> int:
	var highest := 0
	for raw in entities:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entity_id: String = str(raw.get("id", ""))
		if not entity_id.begins_with(prefix):
			continue
		if prefix == "entity.grass." and entity_id.begins_with("entity.grass.bundle."):
			continue
		highest = maxi(highest, _suffix_index(entity_id))
	return highest + 1


func _suffix_index(entity_id: String) -> int:
	var parts: PackedStringArray = entity_id.split(".")
	if parts.is_empty():
		return 0
	return maxi(int(parts[parts.size() - 1]), 0)


func _has_entity(entities: Array, entity_id: String) -> bool:
	for raw in entities:
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) == entity_id:
			return true
	return false


func _load_scatter() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCATTER_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _save_scatter(payload: Dictionary) -> void:
	var file := FileAccess.open(SCATTER_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % SCATTER_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.store_string("\n")
