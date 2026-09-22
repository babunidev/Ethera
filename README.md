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
- `09_Technical/RealmNode_Game-Native_Concept.md` and `99_Development/RealmNode_and_Technical_Foundation.md` — required before changing authoritative simulation structure

The concept and reference images remain in their original folder. They have not been modified or duplicated into the game.

## What is established

- Authored Milestone 1 content in `data/` (traits, interactions with results, skill phases, starting world)
- A presentation-independent simulation: entities, matching, walking, pickup/swap, Shape Weapon, Echo Imprint, Shards, character panel data, development log
- A closed command/query boundary: nothing in `scripts/presentation/` reads runtime state directly
- A fixed 20 Hz authoritative clock with quantized authoritative values, so world time and outcomes do not depend on frame rate or platform floating point
- Snapshots, state hashes, a command journal and timestamped skill samples, so a round can be restored or replayed
- Headless tests for the Milestone 1 loop, determinism, authored results, snapshots and the knowledge boundary
- Placeholder scene bindings and asset-name contracts in `docs/`

Read `docs/ARCHITECTURE.md` and `docs/PRESENTATION_AND_ASSETS.md` before replacing placeholders. Engine and presentation work is recorded in `docs/ENGINE_CHANGELOG.md` (Cursor agent). Concept changelog stays in the concept repository.

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

Godot 4.7.2, GDScript, Windows desktop, mouse and keyboard. The project uses the Forward+ renderer so large hex terrain, cascaded directional shadows, and projected decals work. No external packages or services are required.

The local authoritative simulation owns characters, objects, Traits, equipment, knowledge and conditions. UI and scene nodes display that state. Interaction results pass through `EtheraSimulation.apply`. Networking, save/load and RealmNode remain later work.

**The authoritative runtime will be Rust**, in its own crate beside RealmNode, so a validator can run game rules without launching Godot. The GDScript under `scripts/simulation/` is a temporary stand-in for it. New game rules belong in authored data or behind the command/query boundary, not entangled with Godot. See `docs/ARCHITECTURE.md`.

Keep `.blend` sources in `art/` and export `.glb` assets into `assets/models/`. Git tracks source files; `.godot/` and `builds/` are excluded.

## Tests

```
powershell -File tools/run_simulation_tests.ps1
```

## Next presentation work

Replace placeholders with the village center, separate Fountain, Khar-Morr, rock and clubs. Keep the existing commands, ids and panel/log queries.

`docs/OPEN_IMPLEMENTATION_GAPS.md` separates settled rules from what is still deliberately undecided. Do not promote anything from the undecided list without Alex.
