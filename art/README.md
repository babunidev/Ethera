# Art sources

Keep Blender files here. Godot ignores this folder via `.gdignore`.

Export runtime GLBs to `../assets/models/` using the names in `docs/PRESENTATION_AND_ASSETS.md`.

The current Khar-Morr runtime GLB is produced by `process_khar_morr_glb.py` from
`KharMorr3DV4.glb` only. Do not export `khar_morr.blend` over `assets/models/khar_morr.glb`.

Suggested Blender files:

- `khar_morr.blend` (first low-poly stand-in; not the live character)
- `memory_fountain.blend` (first stand-in; runtime GLB comes from `process_memory_fountain_glb.py`)
- `village_center.blend`
- `shapeable_rock.blend`
- `stone_club.blend` (first stand-in; runtime GLBs come from `process_club_glb.py`)

Concept references stay in the concept repository; do not duplicate them here unless a later packaging step needs a self-contained archive.
