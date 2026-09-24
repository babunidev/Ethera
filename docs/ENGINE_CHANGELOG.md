# Engine work — Cursor agent

Implementation log for **Ethera: The Stonewrought**. This is the game-repo record of engine and presentation work.

Concept, lore and design rulings stay in the Morkahja concept changelog (`Morkahja-Live-RPG/99_Development/Changelog.md`). Do not copy those entries here.

## 2026-09-25

- A loaded hex keeps its height grid, and only the chunks, colliders, and scenery within 64 m of her are drawn. Walking occupancy is unchanged.
- The sun shadow map is 4096 with four splits. The 29 village omni lamps still glow and no longer cast shadows.
- The camera starts all the way out, up and behind the character, about 55 degrees, with a narrower view and the path ahead in frame. Drag only turns it. The wheel sets the distance, and that distance sets the angle: scrolling closer lowers the view a little and brings her to the middle.
- Walk speed is 2.016, five percent faster than 1.92. Run speed is unchanged.
- The Interactions tab shows a short description for each known action, with its requirements.
- Offering Herb is the small triangle grass again, a little smaller than the first tufts. The plant models are no longer used for it.
- Picking Offering Herb uses Material Selection (Trickery, Survival Craft): touch the blades, then confirm. Greeting uses Call and Response (Social, Resonance): match the other Grimnir's mark before either of them says Hi.
- A greeting holds her on the other Grimnir. That Grimnir answers Hi a second later. Until the answer ends she cannot walk or turn the view, a ring closes on the cursor, and the camera angle stays where it was.

## 2026-09-24

- Trakia-Vorr the Path Maker stands in the village as a second Grimnir, with the same character structure as Khar-Morr. Switching between them is not in yet. She does not have Weapon Shaping or Echo Imprint. Her own walk, run, and idle clips are used. She already faces +Z.
- Greet is a radial interaction between two manifested Grimnir. It has no skill phase. The speaker shows a short “Hi” above her head, and both of them keep the event record.

## 2026-09-23

- Shape Weapon leaves the rock in place and gives it Shaped for one minute. That state disables Shapeable, so the same rock cannot be shaped again until it ends.
- Scattered rocks use Rock Medium 1–3 at the same footprint, sit down into the ground, and stay off slopes steeper than 45°.
- Shapeable rocks are two to four times their previous size, in ten steps, and their footprints follow.
- Opening an Offering Herb leaves its click box off, so the herb that drops can be picked up.
- Harvestable plants use Plant_1 and Plant_1_Big, and are named Offering Herb. Scattered shapeable rocks use the round and square pebble models. Both stay the same interactions.
- The Ground Wind-Wave follows the sculpted ground, about 10 m long and 5 m to one side. The Ground Glint is a one-meter omni light close to the ground, about 14 m ahead, easing in and out.
- The Interactions tab is a record of interactions she has completed. Nothing is listed until then. Hovering or selecting one shows what it requires. Khar-Morr's traits include Female with Grimnir.
- Destiny replaces the character-panel contents. Common tasks is a bottom-left list for the priority stone, and the right side draws a small Destiny Crest. The development log records a need appearing, being selected, and being fulfilled; a task being chosen, receiving the priority stone, and being fulfilled; an objective being reserved or released; and each Divine Orientation sign. Those lines are observation only.
- Milestone 3: Need Stone Weapon, Common Task Acquire a Stone Weapon, a reserved free shapeable rock, and Ground Wind-Wave / Ground Glint signs toward its live position. The sole task becomes active on load. Selecting the Need opens Destiny and moves the priority stone only when another task is already selected. Possession of any Stone Weapon completes it. If no free rock remains, the whole occupant of `node.village_001` is replaced by a shapeable rock. No injury is authored. A later state can name the task it makes impossible and the task that resolves it.
- Authored props carry a collision shape on the body so the editor does not warn that they have no shape. Play does not rewrite instance scale. A town-hall box is only an editor placeholder; play uses the mesh so the door and room stay open. Godot may still warn about a non-uniform physics scale; that warning is not a reason to change a placed object.
- A run builds from a walk and eases back to a walk in the last few metres before it stops. The clips follow that speed instead of snapping.
- The orbit camera only pulls in when it would sit inside a solid. A rock or building between the camera and her can cover her for a scenic shot. Ground skim is unchanged.
- Walk and run are 20% slower (1.92 and 4.16). The walk clip still follows displayed speed, so the step is less hurried.
- Hex scenery and the town hall floor are bound once when a hex loads, not every frame. Rebuilding wall occupancy and probing the floor for every object was what stayed slow after the lamps were off.
- Authored omni lamps keep the shadow setting you turn on. Play no longer strips those shadows. Many shadowed lamps will still cost the frame.
- A visible sun travels an east-to-west arc. Presentation lighting moves through sunrise, midday, afternoon, evening and night in ten minutes. Simulation time is unchanged. Once the sun is under the world it stops lighting and casting shadows, so night does not throw shadows up onto the mountains or through a floor. The stone club's living-stone glow follows that light, so it does not stay lit at night.
- The burrow is a placeable prop (`scenes/props/burrow.tscn`) with mesh collision, rock-like occupancy, and no interactions. A walk stops at the mound. The inside of the opening stays visible. The sculpt is scaled to about 2.9 m by 2.5 m and 2.0 m tall; rescale the instance when placing it.
- The town hall is a placeable prop (`scenes/props/town_hall.tscn`) with mesh collision and wall occupancy. The door and room stay walkable; walls and the gap between double walls do not. Inside, feet sit on the hall floor, not the dirt under it. Interior faces stay visible and cast double-sided shadows. The sculpt is scaled to about 7.3 m by 7.8 m and 6.6 m tall so it can sit on a hex; rescale the instance when placing it. The eight stone benches on the starting hex use the imported bench sculpt instead of the plain block, at the same spots, about 1.8 m long, with mesh collision.
- Khar-Morr starts next to the Memory Fountain. The stone container occupies `node.village_001` from gameplay data. The Ancient Stone Circle is a placeable hex object on the east edge. Benches and bushes occupy walking space like shapeable rocks. Echo Cradles occupy and pick like the Fountain, sized to each instance. Edge scenery follows hex connections. Hex grass and stone markers stay out of play; the existing harvestable grass and shapeable rocks are what you see, and rocks sit a little into the ground. A sheathed club stays on the animated `back` node at about 46°, sits toward the spine, and sits closer to the body. The stone-circle eye aims at the circle's height and does not show through terrain.
- The playable starting hex is the authored Low Poly tile at `scenes/terrain/hex_grassland_a.tscn`, streamed at axial 0,0. Height and paint live in `hex_grassland_a_sculpt.res`. The tile editor is only a wrapper around that scene.
- Permanent authored objects are reusable scenes (`MemoryFountain.tscn`, `EchoCradle.tscn`) with `EtheraPlacedEntity`. The Fountain keeps its existing gameplay identity; its scene transform is the spatial source. Echo Cradles share `definition.echo_cradle`. Stone benches stay props. World Node markers remain location ids and stay hidden in play.
- TemporaryGround / generated starting-hex mesh is gone. `HexHost` only streams hex scenes.
- Selecting a hex terrain rebuilds the six edge handles on the flats already in the scene. Each handle is named East, Northeast, Northwest, West, Southwest, or Southeast. The handles, labels, and coloured strips are small and sit outside the perimeter, so they do not cover the tile.

## 2026-09-22

- A selected hex terrain shows an editor-only handle on the midpoint of each flat edge. Clicking one assigns Grass, Dirt, Stone or Vegetation. The six values stay on the terrain manager, in the same order as the world hex edges, and they do not change terrain paint.
- Authored hexes can carry World Node markers (`EtheraWorldNodeMarker`). Each marker is a stable `node_id` plus a designer-set transform. The gizmo is visible only in the editor. `collect_from` reads the locations for later world content. Markers are not RealmNodes and do not store an occupant.
- The orbit mask still lets the camera start from a wide click around her, but a loose item, swap, or open under that same ray keeps hover and left-click. She is not in the way of a club on the floor beside her.
- A held radial shows the focused object's name just above the hub, and the selected action name sits outside that slot.
- Object picks and camera stops follow the visible sculpt. The stone circle is the stones and crystal, not a cylinder of air. A small basin no longer pins the camera inside her click volume.

- Low Poly Terrain Builder can author a regular hex tile without giving up rectangle terrains. Hexagon mode clips each chunk's finished triangles to a flat-to-flat hex centred on the manager, holds that perimeter at height 0, and uses the same mesh for rendering, collision and export. Pointy-top is the default, matching the world hexes; flat-top is available beside it.
- A long walk goes up to the first solid, then grids only around that solid, so a click behind a rock or into the stone circle does not stall.
- Scattered five grass looks (long, tuft, split, flat leaf, needle). Opening a patch yields a five-blade bundle into `slot.herb`. The emptied patch sinks fully into the ground so the living tuft reads as becoming the bundle, and would rise again if it were filled later. The bundle sits on the hip at an angle.
- Scattered shapeable rocks in loose formations and as pebbles. Size and yaw vary; occupancy scales with the sculpt. All of them accept Shape Weapon for now and yield the existing club template.
- Landscape clutter is authored from a seeded generator (`tools/generate_landscape_scatter.py` → `data/milestone1/landscape_scatter.json`) so hashes stay deterministic.
- Opening a container now stands off the occupancy the same way a right-click walk does, so she does not walk through the basin.
- Orbit captures the mouse inside the game window so turning the camera does not throw the cursor onto the desktop.
- Grass is thin triangles in patches of 15–30 blades, never a lone square. The harvested bundle follows a `hip` node on the Mixamo hips bone the same way the club follows `back`.
- Scatter rocks are roughly doubled, with small stones kept in groups and a wider size range.
- Starting a skill overlay after camera orbit restores a visible cursor and keeps it inside the game window. Orbit no longer swallows the mouse into the skill phase.
- Opening a container now places its contents to the object's left or right, never on the opener's stand-off, so the item can be clicked.
- Equipped grass is part of the body like the club. Grass occupancy no longer pulls the camera in, and a carried bundle's pick volume is disabled so it cannot steal character clicks.
- The character panel is larger and follows the concept layout in simple text: identity, body and equipment on the left; Traits, Needs, Shards, States and Interactions tabs on the right. The Shards and States tabs list records and show the selected entry.
- Grass patches are their own kind. They still open and sink like a container, but they occupy no walking space, so she walks through them.
- Extra stand-off around stones and other solids is halved (`object_stand_off` 0.35, `walk_clearance` 0.11) so a walk can pass closer.
- An undiscovered stone-circle center shows a filled eye beside the cursor from far away. Discovery still needs the zone plus that hover.
- Make Offering also needs the place-discovery Shard for that object, so an undiscovered stone circle never offers the rite.
- Shard Fit is a little more forgiving: a larger recess, a wider alignment window, and a slower swing.
- Interaction walks stop at their stand-off instead of closing in and snapping back. Grass still occupies nothing for ordinary walking, but opening a patch uses the same stand-off.
- Temporary ground is a streamed 256 m pointy-top hex. The Memory Fountain and stone circle both sit on that starting hex. Square-grid occupancy hills are gone.
- The project uses Forward+. Directional shadows are camera-relative PSSM splits, not one orthogonal map stretched to the hex.
- Custom slope foot-IK is out. It broke Run and left her floating. Walk and Run play as authored again. The test hill is gone; play stays on the flat village pad until a later pass can plant feet without replacing the clips.
- Walkable slope is 50°, matching vanilla. Steeper ground is a wall: a click through it walks to the face. The starting hex and the pathing share one height sampler, so the mesh and the walk agree. Walk and Run stay the authored clips.
- A steep camera tilt stays above the hex, so the ground does not vanish when looking down.
- The stone-circle discovery ring is a projected decal so it follows the terrain.
- Grass blades cast their own shadows.
- Place discovery now needs both the zone and a hover of the center crystal. The aura hides after that character knows the place. The same object id cannot be discovered twice. An undiscovered center shows an eye cursor. The ring stones share one pick volume with the crystal; the aura is visual only.
- Make Offering is a center action on the stone circle. It needs a grass bundle in the herb slot and the Offering Place trait. Arrival opens Shard Fit; a successful fit consumes the bundle, writes an event Shard, and grants Swiftness (1.4× movement for 3 minutes, authored as a state).
