# Presentation and asset contract

The current scene uses **temporary primitives**. Replace them without changing simulation commands.

## Expected Godot models

Export GLB files from Blender into `assets/models/`. Keep editable `.blend` files in `art/`.

| `asset_id` | File | Binds to |
| --- | --- | --- |
| `asset.khar_morr` | `assets/models/khar_morr.glb` | `entity.khar_morr` |
| `asset.trakia_vorr` | `assets/models/trakia_vorr.glb` | `entity.trakia_vorr` |
| `asset.memory_fountain` | `assets/models/memory_fountain.glb` | `entity.memory_fountain` |
| `asset.village_center` | `assets/models/village_center.glb` | Optional environment overlay; not the starting hex |
| `asset.shapeable_rock` | Scattered rocks: `glTF/Rock_Medium_1`–`3`. Other shapeable rocks: `glTF/Pebble_Round_1`–`5` and `glTF/Pebble_Square_1`–`6` | Scattered rocks keep their size steps and sit into the ground, off slopes steeper than 45°. Shape Weapon leaves the rock and marks it Shaped for one minute |
| `asset.stone_club` | `assets/models/stone_club.glb` | Default / umber / slate clubs (`CLUB13D`); tint and glow from `base_color` |
| `asset.stone_club_b` | `assets/models/stone_club_b.glb` | Green club (`CLUB23D`); tint and glow from `base_color` |
| `asset.stone_container` | `assets/models/stone_container.glb` | Unlocked container; placeholder chest until a GLB exists |
| `asset.grass` | generated triangle patch (15–30 blades) or a tied five-blade bundle | Offering Herb. The patch is kind `grass` (walk-through, still opens). The harvested herb at `hip` is the same blades, smaller |
| `asset.stone_circle` | generated hexagon of hip-height stones, center pillar, crystal, discovery ring | `entity.stone_circle` / `place.ancient_stone_circle` |

The starting hex is the authored tile `scenes/terrain/hex_grassland_a.tscn`, streamed at axial 0,0. Sculpt and paint live in `hex_grassland_a_sculpt.res`. Permanent scenery is placed on that scene: `scenes/props/memory_fountain.tscn`, `scenes/props/echo_cradle.tscn`, `scenes/props/stone_circle.tscn`, and ordinary props such as stone benches, `scenes/props/town_hall.tscn` (wall occupancy, walkable door and room, feet on the hall floor, no interactions), `scenes/props/burrow.tscn` (rock-like occupancy, visible interior, no interactions), `scenes/props/bush.tscn` (rock-like occupancy, not an entity), `scenes/props/grass_clump.tscn` (Offering Herb, the small triangle tuft), and `scenes/props/scatter_stone.tscn` (a shapeable rock, using one of the pebble models). Benches occupy like rocks. Echo Cradles occupy and pick like the Fountain. Bushes sit on sampled ground. Stones sit a little into that ground so they grow out of it. A sheathed club stays on the animated `back` node and is pulled in close so the sculpt sits against her, including while she runs. Hex grass and stone markers stay out of play; the existing harvestable grass and shapeable rocks are what you see. The Memory Fountain's gameplay identity stays in world data; its authored transform is the spatial source. Echo Cradles share `definition.echo_cradle`. World Node markers stay editor-only locations. Hex edges stay flat so a neighbor can join. Presentation seats views on sampled terrain height. Simulation positions stay planar. Ground steeper than 50° is unwalkable; Walk and Run stay the authored clips. The simulation already treats the world as one continuous plane with no loading screens; more ground is more hexes in `data/world/hex_layout.json`. The project uses Forward+ so directional shadows follow the camera and the discovery ring can be a projected decal. A visible sun travels an east-to-west arc. Lighting moves through sunrise, morning, midday, afternoon, evening and night in ten real minutes. Once the sun is under the world it stops lighting and casting shadows. That clock is presentation-only. A village-center GLB, when it exists, is content on the hex, not a replacement for it. Grass blades cast shadows. Seeded grass patches (`kind` `grass`) and extra shapeable rocks live in `data/milestone1/landscape_scatter.json`. A grass patch is walk-through: it still opens like a container from stand-off, but it occupies no walking space. Open it, the living tuft sinks fully into the ground, and a five-blade bundle appears beside the patch (not on the opener) for the hip slot. Scatter rocks use the existing Shape Weapon path. The stone container's pick box is the sculpt's bounds, not the smaller placeholder chest. The Ancient Stone Circle is `scenes/props/stone_circle.tscn`, placed on the authored hex and movable in the editor. Its stones and center crystal share one object pick; the discovery aura is visual only. Hovering the center (including from far away) shows an eye beside the cursor. Walking into its ring and hovering the crystal writes a place-discovery Shard and shows a top-of-screen toast. Make Offering is not offered until that discovery Shard exists.

World entity records already store `presentation.asset_id`. `EtheraAssetLibrary` instances a GLB when the file exists and otherwise keeps the placeholder mesh. Drop files into `assets/models/` using the names above; do not rewrite entity ids or commands. If the character GLB contains a child named `back`, equipped clubs take that node's position only. A child named `hip` does the same for a carried grass bundle, with `lean_degrees` tilting it on the hip. Orientation is never taken from the bone rotation. A `sheath` pose in character space (offset plus `diagonal_degrees` from horizontal in the back plane) lays the club on the back as a slash from hip toward the opposite shoulder. The loose club on the ground stays horizontal, including after a swap. Pickup and swap travel is drawn by `EtheraItemHandoff`: the incoming club rises onto the back and turns into the sheath pose, the outgoing club leaves first and then falls, bouncing onto a corner before it lies flat. They may pass through each other. The simulation still owns the rest pose; this is not a second club model and Godot physics does not decide the landing.

## Scene assembly

1. Model the village-center patch and integrated seats in Blender as one environment asset. Leave the Fountain **out** of that mesh; reserve a level center.
2. Model the Fountain from the concept reference sheets as its own asset.
3. Model bare living-stone Khar-Morr. Origin at feet. Include a `back` attach point on the upper spine for Small Weapon. The live GLB already has this node; authored offset remains the fallback.
4. Two club sculpts are presentation variants of the same item type. `base_color` tints the imported texture and adds a living-stone glow in daylight. That glow follows the day; at night the club darkens with the world. It does not create a new gameplay item.
5. Place permanent game objects in the authored hex scene. Temporary or destiny content uses a World Node marker; its occupant still comes from gameplay data. Do not bake temporary quest positions into the hex as scenery.

Forward is −Z or the project’s chosen convention; `yaw` is `atan2(x, z)` in the simulation. Match that when swapping skeletons.

## Controls the presentation must keep

| Input | Command / query |
| --- | --- |
| C | Toggle the centered character panel. The title chrome hides while it is open. The development log stays visible. Data comes from `query_panel()`. Identity, body and equipment sit on the left. Tabs on the right are Traits, Needs, Shards, States and Interactions. The Shards tab lists known records and shows the selected Shard’s action, result, targets, place and time. The States tab lists current states and shows remaining time and effects. Needs lists her current Needs; an important one is marked. Choosing a Need sends `select_need` and replaces the panel contents with Destiny. Interactions lists only interactions she has completed. Hovering one shows a short description and what it requires; selecting it leaves that note in the space beside the list |
| Destiny | Replaces the character-panel contents in the same screen. The title is centered at the top. Common tasks is a button at the bottom of the left quarter; it opens the task list, and choosing one sends `activate_task` and places the priority stone. That quarter then shows the task title, the priority stone, the goal, and known checklist requirements. The right side draws the Destiny Crest: Combat, Trickery, Aid and Social at the bottom, then rings of 8, 16, 8 and 4, then the Knot. Hover names the column, for example Combat quest. Crest nodes are not selectable. Character returns to the panel contents. The Destiny button opens this view and does not move the priority stone |
| Divine Orientation | While an objective is reserved, about every ten seconds the ground shows one sign from `query_orientation()`. The Ground Wind-Wave is a soft shade laid on the terrain just beside her, sliding parallel to the objective. The Ground Glint is a one-meter omni light about 2.5 m ahead, close to the ground; it moves a short way along that direction and eases in and out. No map, arrow, compass, or marker |
| Title / event-log buttons | Collapse those panels to the remaining button |
| Right-click ground or objects | `set_walk_destination` with gait `walk`; stops just before an object rather than standing on it; clicks through Khar-Morr and her equipped items onto the terrain or whatever is visible behind her; also abandons an approach that has not reached its skill phase. Does not pickup, open, or begin an interaction |
| Right double-click ground or objects | `set_walk_destination` with gait `run`; a slower second click in the same place still counts; she builds from a walk into the run, eases back to a walk in the last few metres, then stops; presentation picks the clip from displayed speed |
| Left-drag on Khar-Morr or her equipped items | Camera orbit from above her down toward the ground; capture the cursor in the window while dragging; the pick volume is larger than her silhouette so the drag does not need to be exact; a loose item, swap, or open under that same ray still wins, so hover and left-click reach the object on the floor instead of starting orbit; a tilt that hits the ground pulls the camera in so the orbit can continue without punching through the hex; the camera only pulls toward her when it would sit inside a visible solid, so a sculpt between the camera and her can cover her when the camera itself is clear; it still does not stop on a column of air above a basin or through a stone ring. Grass patches do not block the camera. Equipped items count as her body and do not steal the click. A click that starts inside her pick still counts as her unless that ray is an item on the ground. Orbit does not start, and captured mouse is released, once a skill overlay is up |
| Mouse wheel | Zoom, starting close enough to read her silhouette |
| Hover loose club | `query_hover` → pickup or swap cursor, at any distance |
| Left-click loose club | `pickup_item`; she walks into reach and takes it on arrival |
| Hover closed grass patch | `query_hover` → open cursor; walking ignores the patch |
| Left-click closed grass patch | `open_container`; she walks in close, a discovery Shard is written, the tuft sinks out of sight, and a five-blade bundle appears beside the patch |
| Hover loose grass bundle | `query_hover` → pickup or swap on the herb slot |
| Left-click grass bundle | `pickup_item` into `slot.herb`; attaches at the hip at an angle |
| Hover closed container | `query_hover` → open cursor |
| Left-click closed container | `open_container`; she walks to a stand-off beside it, a discovery Shard is written, and the contents appear to the object's left or right, not on her stand-off |
| Hold left-click on rock/Fountain | Radial opens after a short hold; the object's authored name sits above the hub; slots are circles until the pointer sits on one, then the action name appears outside that slot; `set_focus_hold` with `held: true` on open and `false` on close; release on a named slot to `begin_interaction` |
| During skill | `skill_pointer` / `skill_click` in normalized overlay space; the cursor is shown and kept inside the window as soon as `stage` is `skill` |
| Hover the stone-circle center when it is in sight at its height | `query_hover` → eye cursor beside the mouse; terrain in front hides it |
| Walk into a place discovery ring and hover the center stone | `observe_target`; one Discovery Shard; `Discovered` toast; the ring hides |
| Hold left-click on the center stone with a grass bundle after the place is known | Radial Make Offering; approach, Shard Fit, then consume the bundle, grant Swiftness, write an event Shard |

Automatic approach and facing are simulation-side, and so is the slowed pace while focus is held. Presentation follows `query_world_view()` transforms. Any presentation that opens a radial must report focus hold on both edges, or the character keeps the reduced pace.

## The simulation runs at 20 Hz; rendering does not

The authoritative pose updates twenty times a second and never from a frame delta. Presentation accumulates its own frame time, converts it with `EtheraWorld.ticks_available()`, sends `{"type": "tick", "ticks": n}`, and keeps the remainder.

**Animation and transforms must interpolate.** Reading `query_world_view()` straight onto a node produces visible 20 Hz stepping at any higher frame rate. The current stand-in eases toward the authoritative pose and snaps when the gap is large; a real animation system should do better, but it must do something. Smoothing is presentation-only and never feeds back into simulation state.

Presentation must not read runtime internals — no `simulation.world`, no `simulation.catalog`. Everything needed comes through `apply()` and the `query_*` functions. The authoritative runtime becomes Rust later, and anything that reaches past this boundary breaks then.

## Skill overlays

`query_skill()` carries the running round and a `phase` block with the authored geometry and timer, so the overlay does not read `data/skill_phases.json` itself. Draw angular gold graphics in that 0–1 skill space. The current overlay in `scripts/presentation/game_root.gd` is a development stand-in: replace the look, keep the command mapping.

The round's stage is `stage` (`approaching` or `skill`). Do not confuse it with `phase`, which is the authored skill-phase definition.

Shape Trace: pointer hits checkpoints by proximity; left-click completes only when all are hit. Shard Fit: simulation rotates the symbol; a click succeeds only inside the recess **and** within alignment tolerance. Wrong clicks must not stop the timer.

## What not to invent

- Pickup event Shards
- Echo Cradle / memory-stone props in Milestone 1
- Bronze adornments or cloth on the first Khar-Morr model
- Right-angle masonry language in the village center
- Physics-driven gameplay outcomes: Godot physics is used for mouse picking only and is not authoritative

Environment treatment: continuous shaped stone, broad facets, organic forms, warm daylight. See the concept environment brief.
