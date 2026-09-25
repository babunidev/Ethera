"""Prepare the authored Khar-Morr GLB for the Godot presentation layer.

The live sculpt is KharMorr3DV4 only. Walk and run are kept in place so the
simulation still owns travel. Standing idle-like clips are kept as authored.
The armature is yawed -90 deg so V4 +X forward matches game +Z, then scaled to
the existing 1.7 m capsule. A `back` attachment is added on the upper spine and a `hip` attachment on the hips.
"""
from __future__ import annotations

import json
import math
import struct
from pathlib import Path

from idle_pose_repair import (
    inverse,
    read_channels,
    rest_poses,
    rotate,
    sample,
    world_poses,
)

REPO = Path(__file__).resolve().parents[2]
SOURCE = (
    REPO
    / "concept"
    / "Morkahja-Live-RPG"
    / "CHARACTER MODEL CONCEPTS"
    / "FEMALE"
    / "Khar-Morr the First Carved"
    / "KharMorr3DV4.glb"
)
DEST = REPO / "game" / "assets" / "models" / "khar_morr.glb"
HEIGHT_M = 1.7
# In-place rest clips. V4 has no clip named wait; standing_relax is that wait.
# swagger travels like a walk, so it is not treated as idle.
IDLE_CLIPS = (
    ("idle", "Idle"),
    ("standing_relax", "IdleWait"),
    ("fold_arms", "IdleFoldArms"),
    ("look_around", "IdleLookAround"),
)


def load_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    _magic, _version, length = struct.unpack_from("<4sII", data, 0)
    offset = 12
    gltf = None
    blob = b""
    while offset < length:
        clen, ctype = struct.unpack_from("<I4s", data, offset)
        chunk = data[offset + 8 : offset + 8 + clen]
        offset += 8 + clen
        if ctype[:4] == b"JSON":
            gltf = json.loads(chunk)
        elif ctype[:4] == b"BIN\x00":
            blob = chunk
    if gltf is None:
        raise RuntimeError("GLB has no JSON chunk")
    return gltf, blob


def write_glb(path: Path, gltf: dict, blob: bytes) -> None:
    blob += b"\x00" * ((4 - len(blob) % 4) % 4)
    gltf["buffers"][0]["byteLength"] = len(blob)
    json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
    total = 12 + 8 + len(json_bytes) + 8 + len(blob)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        handle.write(struct.pack("<4sII", b"glTF", 2, total))
        handle.write(struct.pack("<I4s", len(json_bytes), b"JSON"))
        handle.write(json_bytes)
        handle.write(struct.pack("<I4s", len(blob), b"BIN\x00"))
        handle.write(blob)


def accessor_values(gltf: dict, blob: bytes, index: int) -> list[tuple]:
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    fmt = {5126: "f", 5123: "H", 5125: "I", 5121: "B"}[acc["componentType"]]
    size = {"f": 4, "H": 2, "I": 4, "B": 1}[fmt]
    count = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", size * count)
    values = []
    for i in range(acc["count"]):
        values.append(struct.unpack_from("<" + fmt * count, blob, offset + i * stride))
    return values


def write_accessor(gltf: dict, blob: bytearray, index: int, values: list[tuple]) -> None:
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    count = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 4 * count)
    for i, value in enumerate(values):
        struct.pack_into("<" + "f" * count, blob, offset + i * stride, *value)
    acc["min"] = [min(v[i] for v in values) for i in range(count)]
    acc["max"] = [max(v[i] for v in values) for i in range(count)]


def find_named(gltf: dict, name: str) -> dict:
    for anim in gltf.get("animations", []):
        if str(anim.get("name", "")).strip().lower() == name:
            return anim
    raise RuntimeError("No %s animation" % name)


def mesh_height(gltf: dict) -> float:
    mesh = gltf["meshes"][0]
    acc = gltf["accessors"][mesh["primitives"][0]["attributes"]["POSITION"]]
    return float(acc["max"][1]) - float(acc["min"][1])


def lock_hip_travel(gltf: dict, blob: bytearray, anim: dict) -> None:
    nodes = gltf["nodes"]
    for channel in anim["channels"]:
        node = nodes[channel["target"]["node"]]
        if node.get("name") != "mixamorig:Hips" or channel["target"]["path"] != "translation":
            continue
        index = anim["samplers"][channel["sampler"]]["output"]
        keys = [list(row) for row in accessor_values(gltf, blob, index)]
        origin_x, origin_z = keys[0][0], keys[0][2]
        locked = [(origin_x, row[1], origin_z) for row in keys]
        write_accessor(gltf, blob, index, locked)


def orient_armature(gltf: dict, scale: float) -> None:
    # V4 walk/run travel +X. The game and V3 use +Z. A -90 deg yaw puts her
    # facing the same way she moves.
    factor = scale / mesh_height(gltf)
    half = math.sin(-math.pi / 4.0)
    for node in gltf["nodes"]:
        if node.get("name") == "Armature":
            node["scale"] = [factor, factor, factor]
            node["rotation"] = [0.0, half, 0.0, math.cos(-math.pi / 4.0)]
            return
    raise RuntimeError("Armature node missing")


# Character-space mount used when the GLB has no `back` node. Keep the live
# attachment on that same upper-back point after the V4 yaw correction.
BACK_IN_CHARACTER = (0.16, 1.12, -0.28)
HIP_IN_CHARACTER = (0.16, 0.94, 0.04)


def spine_local_translation(gltf: dict, blob: bytes, spine: int, world_point: tuple[float, float, float]) -> list[float]:
    rest = rest_poses(gltf)
    parents = {child: i for i, node in enumerate(gltf["nodes"]) for child in node.get("children", [])}
    idle = find_named(gltf, "idle")
    poses = sample(rest, read_channels(gltf, blob, idle, accessor_values), 0)
    origin, rotation, scale = world_poses(poses, parents)[spine]
    local = rotate(inverse(rotation), tuple(point - origin[i] for i, point in enumerate(world_point)))
    return [local[i] / scale[i] for i in range(3)]


def add_named_attachment(gltf: dict, blob: bytes, bone_name: str, node_name: str, world_point: tuple[float, float, float]) -> None:
    nodes = gltf["nodes"]
    bone = None
    for i, node in enumerate(nodes):
        if node.get("name") == bone_name:
            bone = i
            break
    if bone is None:
        raise RuntimeError("%s missing" % bone_name)
    child_index = len(nodes)
    nodes.append(
        {
            "name": node_name,
            "translation": spine_local_translation(gltf, blob, bone, world_point),
        }
    )
    children = list(nodes[bone].get("children") or [])
    children.append(child_index)
    nodes[bone]["children"] = children


def add_back_attachment(gltf: dict, blob: bytes) -> None:
    add_named_attachment(gltf, blob, "mixamorig:Spine2", "back", BACK_IN_CHARACTER)


def add_hip_attachment(gltf: dict, blob: bytes) -> None:
    add_named_attachment(gltf, blob, "mixamorig:Hips", "hip", HIP_IN_CHARACTER)


def keep_named_animations(gltf: dict, names: list[str]) -> None:
    wanted = set(names)
    kept = [anim for anim in gltf.get("animations", []) if anim.get("name") in wanted]
    if len(kept) != len(wanted):
        raise RuntimeError("Kept %s, expected %s" % ([a.get("name") for a in kept], names))
    gltf["animations"] = kept


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    gltf, raw = load_glb(SOURCE)
    blob = bytearray(raw)
    orient_armature(gltf, HEIGHT_M)
    walk = find_named(gltf, "walk")
    walk["name"] = "Walk"
    lock_hip_travel(gltf, blob, walk)
    run = find_named(gltf, "run")
    run["name"] = "Run"
    lock_hip_travel(gltf, blob, run)
    names = ["Walk", "Run"]
    for source, dest in IDLE_CLIPS:
        clip = find_named(gltf, source)
        clip["name"] = dest
        names.append(dest)
    keep_named_animations(gltf, names)
    add_back_attachment(gltf, blob)
    add_hip_attachment(gltf, blob)
    write_glb(DEST, gltf, bytes(blob))
    print("Wrote", DEST, "from", SOURCE.name, "clips", names)


if __name__ == "__main__":
    main()
