"""Prepare the Memory Fountain sculpt for the Godot presentation layer."""
from __future__ import annotations

import json
import struct
from pathlib import Path

SOURCE = Path(
    r"C:\Users\Babun\Documents\Morkahja\Morkahja-Live-RPG-Concept\Morkahja-Live-RPG\OBJECTS3D\MemoryFountain.glb"
)
DEST = Path(__file__).resolve().parents[1] / "assets" / "models" / "memory_fountain.glb"
# Occupancy radius is 2.5 m. The sculpt is 1 m across and 0.58 m tall.
SCALE = 5.0


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


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(SOURCE)
    gltf, blob = load_glb(SOURCE)
    gltf["nodes"][0]["name"] = "MemoryFountain"
    gltf["nodes"][0]["scale"] = [SCALE, SCALE, SCALE]
    write_glb(DEST, gltf, blob)
    print("Wrote", DEST, "scale", SCALE)


if __name__ == "__main__":
    main()
