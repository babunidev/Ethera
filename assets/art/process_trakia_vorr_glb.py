"""Prepare Trakia-Vorr the Path Maker for the same presentation path as Khar-Morr.

Her sculpt already has a Mixamo rig and her own clips, and she already faces +Z.
The armature is only scaled to the 1.7 m capsule. Walk and run stay in place.
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

REPO = Path(__file__).resolve().parents[2]
SOURCE = (
    REPO
    / "concept"
    / "Morkahja-Live-RPG"
    / "CHARACTER MODEL CONCEPTS"
    / "FEMALE"
    / "Trakia-Vorr the Path Maker"
    / "Trakia-Vorr+the+Path+Maker.glb"
)
DEST = REPO / "game" / "assets" / "models" / "trakia_vorr.glb"
IDLE_CLIPS = (
    ("idle", "Idle"),
    ("standing_relax", "IdleWait"),
    ("wait", "IdleStand"),
)


def _khar():
    spec = importlib.util.spec_from_file_location(
        "process_khar_morr_glb", Path(__file__).with_name("process_khar_morr_glb.py")
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def scale_armature(gltf: dict, khar) -> None:
    factor = khar.HEIGHT_M / khar.mesh_height(gltf)
    for node in gltf["nodes"]:
        if node.get("name") != "Armature":
            continue
        node["scale"] = [factor, factor, factor]
        node.pop("rotation", None)
        return
    raise RuntimeError("Armature node missing")


def main() -> None:
    khar = _khar()
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    gltf, raw = khar.load_glb(SOURCE)
    blob = bytearray(raw)
    scale_armature(gltf, khar)
    walk = khar.find_named(gltf, "walk")
    walk["name"] = "Walk"
    khar.lock_hip_travel(gltf, blob, walk)
    run = khar.find_named(gltf, "run")
    run["name"] = "Run"
    khar.lock_hip_travel(gltf, blob, run)
    names = ["Walk", "Run"]
    for source, dest in IDLE_CLIPS:
        clip = khar.find_named(gltf, source)
        clip["name"] = dest
        names.append(dest)
    khar.keep_named_animations(gltf, names)
    khar.add_back_attachment(gltf, blob)
    khar.add_hip_attachment(gltf, blob)
    khar.write_glb(DEST, gltf, bytes(blob))
    print("Wrote", DEST, "clips", names)


if __name__ == "__main__":
    main()
