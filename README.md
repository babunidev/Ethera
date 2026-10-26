# Ethera

**Author:** Babuni.dev

Ethera: The Stonewrought is the current Grimnir chapter set in the world of Morkahja.

```
Ethera/
├── game/       Godot implementation
├── concept/    canonical design and specifications
└── assets/     source and reference production assets
```

`game/` is the Godot project. Its `res://` root is `game/`, so scenes, scripts, authored data, and exported models the game loads stay there.

`concept/` is the canonical design. The numbered specifications live in `concept/Morkahja-Live-RPG/`. History snapshots and reference material stay beside that tree.

`assets/` holds editable sources that Godot does not import, including Blender files in `assets/art/`. Exported game-ready files stay in `game/assets/` and the other imported folders inside `game/`.

## Open the game

Open `game/project.godot` in Godot 4.7.2 standard. Press F6 to run the open scene or F5 to run the project. The main scene is `game/scenes/main.tscn`.

Read `AGENTS.md` before changing the game. Implementation follows the design in `concept/`.

## Tests

From `game/`:

```
powershell -File tools/run_simulation_tests.ps1
```

## Development documentation

- [Concept](CONCEPT.md) · [Roadmap](ROADMAP.md) · [Changelog](CHANGELOG.md)
- [Architecture](docs/ARCHITECTURE.md) · [Design evidence](docs/DECISIONS.md) · [Development journal](docs/DEVLOG.md)
- [AI collaborator rules](AGENTS.md)

The journal distinguishes source-based reconstruction, author direction, AI assistance, and independently verified behavior.
