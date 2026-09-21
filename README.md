# Ethera: The Stonewrought

Godot project for the first Grimnir chapter, set in Morkahja.

## Open and run

Use Godot **4.7.2 standard**, import `project.godot`, and press **F6** to run the open scene or **F5** to run the project. The main scene is `scenes/main.tscn`.

Milestone 1 simulation data and rules are implemented locally. The 3D view still uses placeholder primitives. Blender models and finished presentation belong in the next pass.

## Design authority

Read `AGENTS.md` before implementation. The canonical local concept is at:

`C:/Users/Babun/Documents/Morkahja/Morkahja-Live-RPG-Concept/Morkahja-Live-RPG/README.md`

Start with these documents under that concept folder:

- `99_Development/Implementation_Handoff.md`
- `99_Development/Milestone_1_Khar_Morr.md`
- `08_Presentation/Milestone_1_Environment.md`
- `99_Development/Prototype_Readiness_Review.md`

The concept and reference images remain in their original folder. They have not been modified or duplicated into the game.

## What is established

- Authored Milestone 1 content in `data/` (traits, interactions, skill phases, starting world)
- A presentation-independent simulation: entities, matching, walking, pickup/swap, Shape Weapon, Echo Imprint, Shards, character panel data, development log
- A command/query boundary for Godot presentation and later RealmNode work
- Headless tests for the Milestone 1 loop
- Placeholder scene bindings and asset-name contracts in `docs/`

Read `docs/ARCHITECTURE.md` and `docs/PRESENTATION_AND_ASSETS.md` before replacing placeholders.

## Structure

- `scenes/`: Godot presentation and world scenes.
- `scripts/simulation/`: world state and interaction rules.
- `scripts/presentation/`: Godot input, camera, HUD, asset loading, temporary meshes.
- `scripts/tests/`: headless simulation checks.
- `data/`: authored entity and interaction definitions.
- `assets/models/`: exported GLB models for Godot.
- `assets/audio/`: sound assets.
- `assets/ui/`: interface assets.
- `art/`: editable Blender sources, excluded from Godot importing via `.gdignore` but retained in Git.
- `docs/`: implementation notes.

## Technical starting choices

Godot 4.7.2, GDScript, Windows desktop, mouse and keyboard. Compatibility rendering keeps the initial project lightweight; renderer selection can be revisited after testing the final materials and lighting on this computer. No external packages or services are required.

The local authoritative simulation owns characters, objects, Traits, equipment, knowledge and conditions. UI and scene nodes display that state. Interaction results pass through `EtheraSimulation.apply`. Networking, save/load and RealmNode remain later work.

Keep `.blend` sources in `art/` and export `.glb` assets into `assets/models/`. Git tracks source files; `.godot/` and `builds/` are excluded.

## Tests

```
powershell -File tools/run_simulation_tests.ps1
```

## Next presentation work

Replace placeholders with the village center, separate Fountain, Khar-Morr, rock and clubs. Keep the existing commands, ids and panel/log queries.

`docs/OPEN_IMPLEMENTATION_GAPS.md` separates settled rules from what is still deliberately undecided. Do not promote anything from the undecided list without Alex.
