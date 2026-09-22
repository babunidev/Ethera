"""Prepare the authored club GLBs for the Godot presentation layer.

The sculpts stand along +Y. Runtime clubs use +Z as the long axis so the existing
sheath pose and ground rest still apply. Length is 0.7 m, matching the placeholder.
"""
from __future__ import annotations

import json
import math
import struct
from pathlib import Path

CONCEPT = Path(
    r"C:\Users\Babun\Documents\Morkahja\Morkahja-Live-RPG-Concept\Morkahja-Live-RPG\OBJECTS3D"
)
ROOT = Path(__file__).resolve().parents[1]
DEST_DIR = ROOT / "assets" / "models"
LENGTH_M = 0.7
CLUBS = (
    ("CLUB13D.glb", "stone_club.glb"),
    ("CLUB23D.glb", "stone_club_b.glb"),
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


def mesh_bounds(gltf: dict) -> tuple[list[float], list[float]]:
    mesh = gltf["meshes"][0]
    acc = gltf["accessors"][mesh["primitives"][0]["attributes"]["POSITION"]]
    return list(acc["min"]), list(acc["max"])


def process(source: Path, dest: Path) -> None:
    gltf, blob = load_glb(source)
    lo, hi = mesh_bounds(gltf)
    length = hi[1] - lo[1]
    scale = LENGTH_M / length if length > 0.0001 else 1.0
    center = [(lo[i] + hi[i]) * 0.5 for i in range(3)]
    # +90 deg around X: (x, y, z) -> (x, -z, y), so the standing sculpt lies on +Z.
    half = math.sin(math.pi / 4.0)
    rotated_center = [center[0] * scale, -center[2] * scale, center[1] * scale]
    node = gltf["nodes"][0]
    node["name"] = dest.stem
    node["scale"] = [scale, scale, scale]
    node["rotation"] = [half, 0.0, 0.0, half]
    node["translation"] = [-rotated_center[0], -rotated_center[1], -rotated_center[2]]
    write_glb(dest, gltf, blob)
    print("Wrote", dest, "from", source.name, "scale", round(scale, 3), "length", LENGTH_M)


def main() -> None:
    for source_name, dest_name in CLUBS:
        source = CONCEPT / source_name
        if not source.exists():
            raise FileNotFoundError(source)
        process(source, DEST_DIR / dest_name)


if __name__ == "__main__":
    main()
