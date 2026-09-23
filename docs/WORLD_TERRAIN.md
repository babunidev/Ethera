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

Presentation samples the loaded hex (`terrain_height`), including the authored Low Poly sculpt when one is present. Simulation `y` stays 0. Walkable-slope checks still use `EtheraTerrain` until a later pass binds slope to the sculpt. Ground steeper than **50°** (`walkable_slope_degrees`, the vanilla player line) is unwalkable. A click through that face walks up to it, the same way a click through a rock walks to the rim. Walk and Run stay the authored in-place clips; there is no body lean and no foot IK. The test hill is gone. Foot planting on slopes is later work (`TwoBoneIK3D` after the mixer, not pose overrides).

## Authoring

The runtime starting hex is `scenes/terrain/hex_grassland_a.tscn` (`hex.grassland.a` at axial 0,0). Height and paint live beside it in `hex_grassland_a_sculpt.res`. `scenes/tools/hex_tile_editor.tscn` mounts that hex as a live editor tree so Low Poly Terrain Builder can sculpt it; saving writes the hex scene and the sculpt resource. You can also open the hex scene itself.

`LowPolyTerrainManager` authors the tile directly. Terrain Shape `Hexagon` keeps the addon's square height grid and chunks, then clips the generated triangles to a regular hex centred on the manager. Flat-to-flat defaults to 256 m. Pointy-top is the default orientation (a flat edge faces +X); flat-top is the other option. Every point on the six outer edges is height 0, including vertices created where a triangle crosses the boundary. Brushes do not move that perimeter, and they ignore samples outside the hex. Collision is baked from the clipped mesh at load. Neighbor blending, streaming and world generation are unchanged.

Permanent scenery is placed as reusable scenes on the hex. `EtheraPlacedEntity` binds a visual (GLB) to `definition_id` and, when needed, an instance `entity_id`. The Memory Fountain, Echo Cradles, and the Ancient Stone Circle are those objects. Stone benches, bushes, and the town hall stay ordinary props. Authored grass clumps are the existing harvestable grass patches. Authored scatter stones are the existing shapeable rocks. Bushes and benches occupy walking space like rocks. The town hall occupies as walls so you can walk through the door and into the room. Echo Cradles occupy and pick like the Memory Fountain, sized to each instance. Grass occupies nothing. Bushes and grass seat on sampled terrain height. Stones use the shapeable-rock sculpt at varied scale, sit a little into the ground, and may sit on the lower slopes. Edge dressing follows the six authored connections: grass on grass, bushes on vegetation, stones on dirt and stone, then a lighter mix toward the village. `tools/sync_hex_landscape.gd` writes those hex objects into `landscape_scatter.json`. Simulation still owns identity, traits, interactions and persistent state. The authored transform is the spatial source for a placed object. Play does not rewrite instance scale; resize in the hex scene and save.

A World Node is an authored location on a hex, not a RealmNode and not a spawn point for one kind of object. The Godot marker is `EtheraWorldNodeMarker` (`scenes/tools/world_node_marker.tscn`). Place instances under a `WorldNodes` node on the hex. The persistent id is the marker's `node_id` (`node.village_001`), not its scene-tree name and not the current occupant. An occupant such as the stone container stores `world_node_id` in gameplay data and is seated at the marker transform at load. Removing that occupant later must not remove the marker.

### Authoring the next hex

1. Duplicate `scenes/terrain/hex_grassland_a.tscn` (and its `_sculpt.res`) or create a new `EtheraHexTile` with a `LowPolyTerrainManager` in hex mode.
2. Open that hex scene, not the editor wrapper, and sculpt, paint, and assign the six edge connections.
3. Place permanent game objects (`memory_fountain.tscn`, `echo_cradle.tscn`, `stone_circle.tscn`, `town_hall.tscn`, `burrow.tscn`, benches, bushes, grass clumps, scatter stones) and World Node markers. The town hall is a prop with wall occupancy and no interactions; the door and room stay walkable. The burrow is a prop with rock-like occupancy and no interactions. The stone circle is a movable hex object; drag its root in the hex scene. Grass clumps and scatter stones are the existing harvestable grass and shapeable rocks; `tools/sync_hex_landscape.gd` writes them into landscape data. Edge scenery can be regenerated with `tools/place_hex_edge_scenery.gd`.
4. Save. The manager writes height/paint back into the external sculpt resource.
5. Register the tile in `data/world/hex_library.json` and place it in `data/world/hex_layout.json`.
6. Keep authoring in `scenes/tools/hex_tile_editor.tscn` or in the hex scene itself. Do not instance the hex inside another scene and expect the terrain plugin to work; Godot treats that manager as a placeholder.

## Shadows

Directional shadows use PSSM splits. `max_distance` follows the orbit camera, not the hex diameter. Local omni and spot lamps keep the shadow setting you author. Many shadowed lamps will cost the frame.
