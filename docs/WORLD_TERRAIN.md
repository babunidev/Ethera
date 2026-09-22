# World terrain (presentation)

The hex tile is an authored, streamed spatial unit. It is not a simulation region, a RealmNode shard, or an occupancy kind.

```text
World data (entities, places)
    → hex layout (axial q,r + tile id + rotation)
        → streamed hex scenes (current hex + neighbors)
            → terrain mesh, placed landmarks, scatter
```

## Settled for this repository

- Renderer is **Forward+**. Compatibility cannot give camera-based directional shadows or projected decals on large terrain.
- Milestone 1 village (Memory Fountain and stone circle) lives on the **starting hex**. The old “next square east” layout was a 64 m grid artifact.
- Starting scale is **256 m flat-to-flat**, pointy-top, so +X is a real east edge.
- Exact size remains testable. Destiny-driven hex spawning is settled design and is not implemented here.

## Streaming

`EtheraHexStreamer` loads `data/world/hex_layout.json` against `data/world/hex_library.json`. It instantiates the player’s current hex plus ring 1, and only those hexes that exist in the layout. Distant hexes unload. Authoritative state does not depend on whether a hex scene is loaded.

## Edges

Each library tile stores six edge types, clockwise from east. Rotation is a 60° step. Neighbor placement must match the touching edge; that check is for when a second hex is authored.

On a pointy-top hex those six flats are indexed to match `EtheraHexCoords` neighbors, starting at the east flat (+X):

| Index | Flat | Opposite |
| --- | --- | --- |
| 0 | East | 3 West |
| 1 | Northeast | 4 Southwest |
| 2 | Northwest | 5 Southeast |
| 3 | West | 0 East |
| 4 | Southwest | 1 Northeast |
| 5 | Southeast | 2 Northwest |

Opposite is always `index + 3` modulo 6. Flat-top uses the same indices, turned 30° so index 0 is still a flat edge. A handle marks the midpoint of the flat, never a corner, and sits just outside the perimeter so the sphere and the coloured strip do not cover the tile. Selecting the terrain manager builds those six handles. Each one is named for its flat — East, Northeast, Northwest, West, Southwest, or Southeast — and the label also shows the assigned connection.

`LowPolyTerrainManager` stores each edge's connection as `grass`, `dirt`, `stone`, or `vegetation`. That metadata is not a paint layer: painting the surface does not change an edge, and assigning an edge does not repaint the surface. `get_hex_edge_connections()` returns the six ids in this order. `LowPolyTerrainHex.connections_match` is true when two touching edges carry the same id. The hex library's existing `grassland` entries are a separate record and are not rewritten by the editor handles.

## Height

Presentation samples the loaded hex (`terrain_height`). Simulation `y` stays 0. Height itself is shared: `EtheraTerrain` is the starting-hex sampler for both the mesh and walking, so a slope is the same wall in both. Ground steeper than **50°** (`walkable_slope_degrees`, the vanilla player line) is unwalkable. A click through that face walks up to it, the same way a click through a rock walks to the rim. Walk and Run stay the authored in-place clips; there is no body lean and no foot IK. The current grassland maxes around 1–2°, so the village pad stays fully walkable. The test hill is gone. Foot planting on slopes is later work (`TwoBoneIK3D` after the mixer, not pose overrides).

## Authoring

`LowPolyTerrainManager` can author that tile directly. Terrain Shape `Hexagon` keeps the addon's square height grid and chunks, then clips the generated triangles to a regular hex centred on the manager. Flat-to-flat defaults to 256 m. Pointy-top is the default orientation (a flat edge faces +X); flat-top is the other option. Every point on the six outer edges is height 0, including vertices created where a triangle crosses the boundary. Brushes do not move that perimeter, and they ignore samples outside the hex. Collision and glTF export use the clipped mesh, so neither includes the rectangular grid around it. Neighbor blending, streaming and world generation are unchanged.

A World Node is an authored location on a hex, not a RealmNode and not a spawn point for one kind of object. The Godot marker is `EtheraWorldNodeMarker` (`scenes/tools/world_node_marker.tscn`). Place instances under a `WorldNodes` node on the hex. The persistent id is the marker's `node_id` (`node.001`), not its scene-tree name. The hex tile id stays on the hex (`hex.grassland.a` on `EtheraHexTile`). `EtheraWorldNodeMarker.collect_from(hex_root)` returns those definitions in hex-local space: `id`, `tile_id`, `position`, and `rotation` (Euler radians, YXZ). The gizmo is editor-only. Occupation and what appears there are later work.

## Shadows

Directional shadows use PSSM splits. `max_distance` follows the orbit camera, not the hex diameter.
