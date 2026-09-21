# Presentation and asset contract

The current scene uses **temporary primitives**. Replace them without changing simulation commands.

## Expected Godot models

Export GLB files from Blender into `assets/models/`. Keep editable `.blend` files in `art/`.

| `asset_id` | File | Binds to |
| --- | --- | --- |
| `asset.khar_morr` | `assets/models/khar_morr.glb` | `entity.khar_morr` |
| `asset.memory_fountain` | `assets/models/memory_fountain.glb` | `entity.memory_fountain` |
| `asset.village_center` | `assets/models/village_center.glb` | Environment; replace `TemporaryGround` |
| `asset.shapeable_rock` | `assets/models/shapeable_rock.glb` | `entity.shapeable_rock` |
| `asset.stone_club` | `assets/models/stone_club.glb` | Clubs; tint with `base_color` `slate` or `umber` |

World entity records already store `presentation.asset_id`. `EtheraAssetLibrary` instances a GLB when the file exists and otherwise keeps the placeholder mesh. Drop files into `assets/models/` using the names above; do not rewrite entity ids or commands. If the character GLB contains a child named `back`, equipped clubs attach there. Otherwise they use the authored back offset.

## Scene assembly

1. Model the village-center patch and integrated seats in Blender as one environment asset. Leave the Fountain **out** of that mesh; reserve a level center.
2. Model the Fountain from the concept reference sheets as its own asset.
3. Model bare living-stone Khar-Morr from the selected low-poly reference. Origin at feet. Include a `back` attach point for Small Weapon (authored offset is `0, 1.15, -0.22` local until the real bone exists).
4. Model one stone club. Color variants are data, not two gameplay item types.
5. Place instances in Godot using simulation positions in `data/milestone1/world.json`. Do not bake those gameplay positions only into Blender.

Forward is −Z or the project’s chosen convention; `yaw` is `atan2(x, z)` in the simulation. Match that when swapping skeletons.

## Controls the presentation must keep

| Input | Command / query |
| --- | --- |
| C | Toggle character panel; data from `query_panel()` |
| Right-click ground | `set_walk_destination`; also abandons an approach that has not reached its skill phase |
| Left-drag on Khar-Morr | Camera orbit; preserve yaw/pitch/distance while she moves |
| Mouse wheel | Zoom |
| Hover loose club | `query_hover` → pickup or swap cursor, at any distance |
| Left-click loose club | `pickup_item`; she walks into reach and takes it on arrival |
| Hold left-click on rock/Fountain | Radial opens after a short hold; `set_focus_hold` with `held: true` on open and `false` on close; move toward an option and release to `begin_interaction` |
| During skill | `skill_pointer` / `skill_click` in normalized overlay space |

Automatic approach and facing are simulation-side, and so is the slowed pace while focus is held. Presentation follows `query_world_view()` transforms. Any presentation that opens a radial must report focus hold on both edges, or the character keeps the reduced pace.

## Skill overlays

`data/skill_phases.json` is the geometry and timer source. Draw angular gold graphics in that 0–1 skill space. The current overlay in `scripts/presentation/game_root.gd` is a development stand-in: replace the look, keep the command mapping.

Shape Trace: pointer hits checkpoints by proximity; left-click completes only when all are hit. Shard Fit: simulation rotates the symbol; a click succeeds only inside the recess **and** within alignment tolerance. Wrong clicks must not stop the timer.

## What not to invent

- Pickup event Shards
- Echo Cradle / memory-stone props in Milestone 1
- Bronze adornments or cloth on the first Khar-Morr model
- Right-angle masonry language in the village center

Environment treatment: continuous shaped stone, broad facets, organic forms, warm daylight. See the concept environment brief.
