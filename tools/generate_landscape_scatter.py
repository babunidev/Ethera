"""Seeded landscape scatter for Milestone 1. Writes data/milestone1/landscape_scatter.json.

Positions are authored world data so simulation hashes stay deterministic.
Scatter stays on the starting 256 m hex. Fountain and stone-circle pads stay empty.
"""
from __future__ import annotations

import json
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "milestone1" / "landscape_scatter.json"
SEED = 20260922
FLAT_TO_FLAT = 256.0
SIZE = FLAT_TO_FLAT / math.sqrt(3.0)
APOTHEM = FLAT_TO_FLAT * 0.5
STONE_CIRCLE = (108.0, 0.0)

GRASS_KINDS = [
    {"variant": 0, "name": "Long Grass"},
    {"variant": 1, "name": "Soft Tuft"},
    {"variant": 2, "name": "Split Blade"},
    {"variant": 3, "name": "Flat Leaf"},
    {"variant": 4, "name": "Needle Grass"},
]


def edge_clearance(x: float, z: float) -> float:
    best = APOTHEM
    for i in range(6):
        angle = math.radians(60.0 * i)
        best = min(best, APOTHEM - (x * math.cos(angle) + z * math.sin(angle)))
    return best


def in_hex(x: float, z: float, margin: float = 4.0) -> bool:
    return edge_clearance(x, z) >= margin


def dist(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def q(value: float) -> float:
    return round(value, 3)


RESERVED = [
    (0.0, 0.0, 6.0),
    (-5.0, 3.4, 3.5),
    (5.2, 4.6, 3.0),
    (4.6, -3.6, 2.5),
    (-4.2, -4.4, 2.8),
    (STONE_CIRCLE[0], STONE_CIRCLE[1], 8.0),
]


def clear_of_reserved(x: float, z: float, extra: float = 0.0) -> bool:
    for rx, rz, rr in RESERVED:
        if dist((x, z), (rx, rz)) < rr + extra:
            return False
    return True


def sample_in_hex(rng: random.Random, taken: list, spacing: float) -> tuple[float, float] | None:
    for _ in range(50):
        x = rng.uniform(-APOTHEM + 6.0, APOTHEM - 6.0)
        z = rng.uniform(-SIZE + 6.0, SIZE - 6.0)
        if not in_hex(x, z, 6.0) or not clear_of_reserved(x, z, 1.0):
            continue
        if any(dist((x, z), (ox, oz)) < spacing for ox, oz in taken):
            continue
        return x, z
    return None


def grass_entities(index: int, kind: dict, x: float, z: float, yaw: float, blades: int) -> list[dict]:
    bundle_id = f"entity.grass.bundle.{index}"
    patch = {
        "id": f"entity.grass.{index}",
        "kind": "grass",
        "name": kind["name"],
        "place_id": "place.village_center",
        "traits": ["trait.container"],
        "opened": False,
        "contained_item_ids": [bundle_id],
        "states": [],
        "position": {"x": q(x), "y": 0.0, "z": q(z)},
        "yaw": q(yaw),
        "manifested": True,
        "presentation": {
            "asset_id": "asset.grass",
            "variant": kind["variant"],
            "blade_count": blades,
        },
    }
    bundle = {
        "id": bundle_id,
        "kind": "item",
        "name": "Grass Bundle",
        "template_id": "template.grass_leaf",
        "place_id": "place.village_center",
        "traits": ["trait.herb"],
        "condition": "okay",
        "equipment_slot_id": "slot.herb",
        "attachment": "hip",
        "holder_id": None,
        "container_id": f"entity.grass.{index}",
        "equipped_slot_id": None,
        "position": {"x": q(x), "y": 0.0, "z": q(z)},
        "yaw": q(yaw),
        "manifested": False,
        "presentation": {
            "asset_id": "asset.grass",
            "variant": kind["variant"],
            "blade_count": 5,
            "bundle": True,
        },
    }
    return [patch, bundle]


def rock_entity(index: int, x: float, z: float, yaw: float, sx: float, sy: float, sz: float) -> dict:
    span = max(sx, sz)
    return {
        "id": f"entity.shapeable_rock.scatter.{index}",
        "kind": "world_object",
        "name": "Shapeable Rock",
        "place_id": "place.village_center",
        "traits": ["trait.rock", "trait.shapeable"],
        "states": [],
        "manifested": True,
        "yields_template_id": "template.stone_club",
        "yields_base_color": "slate",
        "position": {"x": q(x), "y": 0.0, "z": q(z)},
        "yaw": q(yaw),
        "occupancy": {"radius": q(max(0.16, 0.55 * span))},
        "presentation": {
            "asset_id": "asset.shapeable_rock",
            "scale": {"x": q(sx), "y": q(sy), "z": q(sz)},
        },
    }


def rock_size(rng: random.Random, kind: str) -> tuple[float, float, float]:
    if kind == "tiny":
        return rng.uniform(0.18, 0.28), rng.uniform(0.14, 0.22), rng.uniform(0.16, 0.28)
    if kind == "pebble":
        return rng.uniform(0.28, 0.42), rng.uniform(0.18, 0.34), rng.uniform(0.24, 0.4)
    if kind == "small":
        return rng.uniform(0.45, 0.72), rng.uniform(0.32, 0.62), rng.uniform(0.42, 0.78)
    if kind == "medium":
        return rng.uniform(0.72, 1.12), rng.uniform(0.5, 1.02), rng.uniform(0.68, 1.18)
    return rng.uniform(1.15, 1.7), rng.uniform(0.72, 1.45), rng.uniform(0.95, 1.55)


def main() -> None:
    rng = random.Random(SEED)
    entities: list[dict] = []
    taken: list[tuple[float, float]] = []

    near = [
        (-12.0, 8.0),
        (-11.0, -10.0),
        (8.0, 12.0),
        (12.0, -9.0),
    ]
    grass_index = 0
    for i, (x, z) in enumerate(near):
        if not in_hex(x, z, 6.0) or not clear_of_reserved(x, z):
            continue
        grass_index += 1
        kind = GRASS_KINDS[i % len(GRASS_KINDS)]
        entities.extend(grass_entities(grass_index, kind, x, z, rng.uniform(0, math.tau), rng.randint(18, 28)))
        taken.append((x, z))

    for _ in range(14):
        point = sample_in_hex(rng, taken, 8.0)
        if point is None:
            continue
        grass_index += 1
        kind = GRASS_KINDS[(grass_index - 1) % len(GRASS_KINDS)]
        entities.extend(
            grass_entities(
                grass_index,
                kind,
                point[0],
                point[1],
                rng.uniform(0, math.tau),
                rng.randint(15, 30),
            )
        )
        taken.append(point)

    rock_index = 0
    for _ in range(40):
        point = sample_in_hex(rng, taken, 2.4)
        if point is None:
            continue
        rock_index += 1
        kind = rng.choice(["tiny", "pebble", "small", "small", "medium"])
        sx, sy, sz = rock_size(rng, kind)
        entities.append(rock_entity(rock_index, point[0], point[1], rng.uniform(-1.2, 1.2), sx, sy, sz))
        taken.append(point)

    payload = {
        "schema": "ethera.world.landscape_scatter.v1",
        "notes": "Seeded clutter on the starting 256 m hex. Grass is kind grass and has no occupancy. Fountain and stone-circle pads stay empty.",
        "seed": SEED,
        "flat_to_flat": FLAT_TO_FLAT,
        "entities": entities,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    grass_n = sum(1 for e in entities if e["kind"] == "grass")
    bundle_n = sum(1 for e in entities if e.get("template_id") == "template.grass_leaf")
    rock_n = sum(1 for e in entities if e["kind"] == "world_object")
    print(f"Wrote {OUT} ({grass_n} grass patches, {bundle_n} bundles, {rock_n} rocks)")


if __name__ == "__main__":
    main()
