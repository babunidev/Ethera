# Ethera — technical architecture overview

**Creative:** Babuni

- `game/` is the Godot 4.7.2 project (`game/project.godot`, `game/scenes/main.tscn`).
- `game/data/` and `game/scripts/` hold authored rules, simulation and presentation interfaces. [Game README](../game/README.md) describes a presentation-independent 20 Hz deterministic-authority model, quantized state, command/query separation, snapshots, state hashes and replay journal.
- `game/scripts/tests/` and addon test files provide headless/simulation checks; none were executed in this audit.
- `concept/Morkahja-Live-RPG/` is the authoritative vision and design tree; `concept/History/` preserves previous states; `assets/` stores editable reference production material.

The current README and source guide are not substitutes for actual runtime verification.

## Follow an interaction through the runtime

1. Godot collects an action and calls `EtheraSimulation.apply()`. Skill overlays send timestamped input samples.
2. The runtime checks eligibility against the actor, target, and authored rules. It resolves the skill phase on the fixed 20 Hz clock.
3. The result interpreter updates world state, writes records such as event Shards, and exposes the result through queries. Presentation interpolates movement between authoritative updates.
4. The command journal and snapshots let tests replay an interaction or restore its state. Character knowledge is filtered at the query boundary.

[Detailed engine architecture](../game/docs/ARCHITECTURE.md) · [Runtime source](../game/scripts/simulation/) · [Prototype status](PROTOTYPE_STATUS.md)

## Planned distributed authority

The [canonical decision register](../concept/Morkahja-Live-RPG/99_Development/Design_Decisions.md) specifies an eventual deterministic **Rust** authority crate alongside RealmNode; its validators should run game rules without Godot. Current GDScript simulation is a stand-in. Similarly, peer-coordinated world continuity, dormant regions and hidden-knowledge ownership are architectural requirements, not confirmed deployed networking. Keep implementation and intended production architecture distinct in all summaries.

The [verification record](PROTOTYPE_STATUS.md#verification) tracks historical test results and the scope of the latest source review.
