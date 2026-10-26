# Ethera — technical architecture overview

**Author:** Babuni.dev

- `game/` is the Godot 4.7.2 project (`game/project.godot`, `game/scenes/main.tscn`).
- `game/data/` and `game/scripts/` hold authored rules, simulation and presentation interfaces. [Game README](../game/README.md) describes a presentation-independent 20 Hz deterministic-authority model, quantized state, command/query separation, snapshots, state hashes and replay journal.
- `game/scripts/tests/` and addon test files provide headless/simulation checks; none were executed in this audit.
- `concept/Morkahja-Live-RPG/` is the authoritative vision and design tree; `concept/History/` preserves previous states; `assets/` stores editable reference production material.

The current README and source guide are not substitutes for actual runtime verification.
