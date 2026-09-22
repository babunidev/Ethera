# Grown-stone container

User-directed design: a smooth oval basin flowing into a root-like ground base,
with a thick rounded stone lid, jade crystals at the two long-axis ends and one
polished gem in the front stone clasp. No masonry joints or angular stone facets.

- Runtime model: `assets/models/stone_container.glb`.
- Editable model: `art/stone_container.blend`.
- Rebuild using Blender's background mode and `art/build_stone_container.py`.
- Existing entity, placement, occupancy and asset ID are retained.
- The separate `LidPivot` slides 0.16 m along local X and returns, staying level. Collision children
  follow the same hierarchy for picking. A body-level pick box matches the
  sculpt's bounds so the whole basin is clickable.

The existing open action still discovers and reveals the green club beside the
container, on the object's left or right rather than on the opener. `contained_item_ids` now tracks revealed contents still awaiting their
first pickup; a successful pickup removes its ID. The discovery flag `opened`
remains true after collection, so closing an empty lid does not offer discovery
again. No extra Shard or equipment action is created by lid movement.

`query_world_view()` exposes `container_lid_open` as the existing reveal signal,
not a persistent visual lid position. `stone_container_lid.gd` plays once on the
signal's rising edge: 0.85 seconds sliding sideways, 0.30 seconds paused, then
0.85 seconds returning. The disc stays level. It closes without waiting for pickup;
a quick pickup does not interrupt the motion. Loading an already-revealed container
starts at rest. No simulation rules, geometry or material changes are needed.

Validation: `scripts/tests/verify_stone_container.gd` checks the imported disc's
translation, unchanged rotation, automatic return, no repeated animation, snapshot
behavior, and quick pickup at 30/60/144 fps.
Stone surfaces use a packed 1024px baked albedo with subtle mottling and mineral grain. The build script calls art/stone_surface.py to retain the texture on rebuild. Crystals and clasp gem keep their polished materials.

