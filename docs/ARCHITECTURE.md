# Ethera — technical architecture overview

**Author:** Babuni.dev

- `game/` is the Godot 4.7.2 project (`game/project.godot`, `game/scenes/main.tscn`).
- `game/data/` and `game/scripts/` hold authored rules, simulation and presentation interfaces. [Game README](../game/README.md) describes a presentation-independent 20 Hz deterministic-authority model, quantized state, command/query separation, snapshots, state hashes and replay journal.
- `game/scripts/tests/` and addon test files provide headless/simulation checks; none were executed in this audit.
- `concept/Morkahja-Live-RPG/` is the authoritative vision and design tree; `concept/History/` preserves previous states; `assets/` stores editable reference production material.

The current README and source guide are not substitutes for actual runtime verification.

## Source-versus-plan distinction — 2026-10-27

The [game README](../game/README.md) describes the current local implementation: a Godot 4.7.2 desktop project, presentation-independent simulation, a **20 Hz** fixed authoritative step with quantized state, command/query separation, snapshot hashes, replay journal and headless tests. Placeholder 3D presentation remains. These are source-reported features, not newly verified execution.

The [canonical decision register](../concept/Morkahja-Live-RPG/99_Development/Design_Decisions.md) specifies an eventual deterministic **Rust** authority crate alongside RealmNode; its validators should run game rules without Godot. Current GDScript simulation is a stand-in. Similarly, peer-coordinated world continuity, dormant regions and hidden-knowledge ownership are architectural requirements, not confirmed deployed networking. Keep implementation and intended production architecture distinct in all summaries.

The [historical concept changelog](../concept/Morkahja-Live-RPG/99_Development/Changelog.md) records 392 passing simulation tests in a September 22 container/presentation integration, which does not prove the currently checked-out project passes or that Milestone 3 is complete. Fresh commands and evidence remain pending.
