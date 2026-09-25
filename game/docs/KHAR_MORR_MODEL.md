# Khar-Morr model integration

Runtime character is Mixamo-rigged sculpt **KharMorr3DV4** from
`CHARACTER MODEL CONCEPTS/FEMALE/Khar-Morr the First Carved/KharMorr3DV4.glb`.

- Source sculpt (concept repo): the GLB above, Tripo mesh, 65-bone Mixamo rig.
- Runtime asset: `assets/models/khar_morr.glb`.
- Rebuild: `art/process_khar_morr_glb.py` (reads the V4 GLB only, writes the runtime file).
- The earlier low-poly Blender stand-in remains in `art/khar_morr.blend` and must not be
  exported over the runtime GLB.

The processor keeps V4 `walk` and `run` in place, and the authored standing rest clips
`idle`, `standing_relax` (the wait), `fold_arms`, and `look_around`. Those rest clips
are not retargeted or replanted. `swagger` travels like a walk, so it is not treated as
idle. Other V4 performances (`greet_02`, `dance_01`, `hit_to_body_01`) stay unused until
something plays them. V4 is authored facing +X; the armature is yawed −90° so forward
matches the game and V3 (+Z). Locomotion root motion is removed so the simulation still
owns travel. The armature is scaled to 1.7 m to match the existing picking capsule. A
`back` node sits on `mixamorig_Spine2`. A `hip` node sits on `mixamorig:Hips` for a carried grass bundle.

`character_animation.gd` plays Walk or Run from displayed displacement and, at rest,
picks a random idle-like clip, then another when that clip ends. A successful pickup
plays `UnarmedPickup`, retargeted from the Explosive skeleton onto this Mixamo rig.
Her heading stays the facing the game already set; the clip does not turn her.
The hips drop with the crouch, vertically only, so her feet stay on the ground.
The clip plays at 0.8 speed.
The clip does not delay the take. Walking off cancels it. Movement, interaction
approach, camera controls and authoritative timing remain owned by the existing systems.
It never accesses simulation internals.

The displayed body sits on sampled hex height. Walk and Run play as authored in-place clips on slopes as well as flats. Ground steeper than 50° is unwalkable. Slope foot-planting is parked; a custom IK pass was breaking Run and leaving her off the ground. Forward is +Z, matching `atan2(x, z)` heading. Equipped clubs
still use the `back` node's position only; a carried grass bundle uses the `hip` node the same way, then leans by authored `lean_degrees`.
Sheath orientation stays in character space.

Open the concept GLB to edit the sculpt or re-export animations. Re-run the processor,
reimport in Godot, and restart the running game to replace an already-instanced model.

Keep the AnimationPlayer import optimizer disabled in `khar_morr.glb.import`.
This setting is specific to this character.

Regression check: run Godot headless with
`-s res://scripts/tests/verify_idle_contacts.gd`
to confirm the idle-like clips imported, then `verify_khar_morr.gd` for existing
movement, arrival, rig, camera and equipment integration checks.
