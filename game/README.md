# Ethera Godot prototype

Open [project.godot](project.godot) in Godot **4.7.2 standard**, allow assets to import, then press **F5** to run [the main scene](scenes/main.tscn). The documented setup is desktop with mouse and keyboard. The project uses Forward+.

## Explore the village

1. In **Spectate**, select Khar-Morr or Trakia-Vorr and choose **Play**.
2. With Khar-Morr, hold left-click on a shapeable rock and release over **Shape Weapon**. Follow the Shape Trace checkpoints and confirm to shape and equip the club.
3. Return to the Memory Fountain and try **Echo Imprint** to contribute known Shards. The current prototype offers village deliveries through **Echo Attunement**. Follow the ground glint or wind-wave to the supplies, then bring them to the town hall.
4. Visit the Ancient Stone Circle. Approach and hover its center to discover it. You can also greet the other Grimnir or return to Spectate to switch lives.

| Input | Action |
| --- | --- |
| Right-click / right double-click | Walk / run |
| Left-click on a loose item or container | Approach, then take or open |
| Hold left-click on an interaction target | Open the radial, aim at an action, then release |
| Drag from the character / scroll | Orbit / zoom the camera |
| **C** / **J** | Character panel / Destiny |
| **Esc** while inhabiting | Open the menu and return to Spectate |

[Detailed controls and presentation](docs/PRESENTATION_AND_ASSETS.md) · [Prototype status and known design differences](../docs/PROTOTYPE_STATUS.md)

## Run the simulation suite

From the repository root, use the documented Godot version. Replace `godot` with the executable path if needed. Import first so Godot builds its asset and script class caches.

```sh
godot --headless --path game --import
godot --headless --path game --script res://scripts/tests/run_simulation_tests.gd
```

The checked-in [PowerShell wrapper](tools/run_simulation_tests.ps1) uses a specific Windows installation path. The commands above expose the same import and test entry points. See the [test source](scripts/tests/ethera_simulation_tests.gd) for coverage and the [verification record](../docs/PROTOTYPE_STATUS.md#verification) for the evidence available.

## Find your way around

| Path | Purpose |
| --- | --- |
| [data/](data/) | Authored entities, traits, interactions, skill phases, tasks, and world layouts |
| [scripts/simulation/](scripts/simulation/) | Local authoritative state, rules, and command/query interface |
| [scripts/presentation/](scripts/presentation/) and [scenes/](scenes/) | Input, camera, UI, visuals, and world assembly |
| [assets/models/](assets/models/) and [../assets/art/](../assets/art/) | Imported GLBs and editable production sources |
| [docs/](docs/) | Engine architecture, terrain, art contracts, and implementation history |

Read [AGENTS.md](../AGENTS.md) and the [canonical design](../concept/Morkahja-Live-RPG/README.md) before changing gameplay. The [engine architecture](docs/ARCHITECTURE.md) explains how the current GDScript runtime keeps presentation separate from rules.
