# Engine work — Cursor agent

Implementation log for **Ethera: The Stonewrought**. This is the game-repo record of engine and presentation work.

Concept, lore and design rulings stay in the Morkahja concept changelog (`Morkahja-Live-RPG/99_Development/Changelog.md`). Do not copy those entries here.

## 2026-09-23

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
