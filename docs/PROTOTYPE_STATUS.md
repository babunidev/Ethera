# Prototype status

Source reviewed on **11 November 2026** at [`5580c70`](https://github.com/babunidev/Ethera/commit/5580c70bdc05c4632082f7ccd71c43c3c5d50256). This page records what the checked-in prototype contains and where it differs from the [first-playable plan](../concept/Morkahja-Live-RPG/99_Development/First_Playable_Scope.md).

| Area | In the prototype | Scope still open |
| --- | --- | --- |
| Shaping and equipment | Shape Trace creates a stone club, equips it, and writes an event Shard. Loose clubs can be picked up and swapped. | Desktop acceptance of timing, animation, and object placement. |
| Discovery and memory | The Ancient Stone Circle can produce a place-discovery Shard. Pickup and container opening record their own events. Echo Imprint gives the Fountain access to existing memories. | The full archival lifecycle and the unresolved transfer rules below. |
| Needs and guidance | Common Tasks, objective reservation, Ground Glint and Ground Wind-Wave, and village deliveries for a stone weapon and Offering Herb. | Acceptance against the original Milestone 3 scenario and the grant rule below. |
| Social play and inhabitation | A greeting with Call and Response, Spectate, and local switching between Khar-Morr and Trakia-Vorr. | Ordinary life under AI between sessions, network handoff, and wider social simulation. |
| Settlement and visuals | Authored terrain, village props, character models, animation, and day/night presentation alongside development overlays and mesh fallbacks. | A fresh visual and performance pass on the documented engine version. |
| Continuity | Local snapshot/restore, state hashing, and command replay support simulation inspection. | Player-facing save/load across launches, distributed persistence, and RealmNode. |

**Source:** [interaction definitions](../game/data/interactions.json), [task definitions](../game/data/tasks.json), [presentation controller](../game/scripts/presentation/game_root.gd), [simulation](../game/scripts/simulation/ethera_simulation.gd), and the [engine changelog](../game/docs/ENGINE_CHANGELOG.md).

## Behavior that needs a design decision

| Topic | Design record | Prototype source |
| --- | --- | --- |
| Stone Weapon Need | [Milestone 3](../concept/Morkahja-Live-RPG/99_Development/Milestone_3_Need_and_Divine_Orientation.md) starts an unarmed Khar-Morr with the Need and activates her sole task. | [Needs data](../game/data/needs.json) requires an explicit grant from a task, Destiny Quest, or state. Being unarmed alone is insufficient. |
| Echo Imprint | The [Shard overview](../concept/Morkahja-Live-RPG/05_Knowledge/Shards_Memory_and_Cultural_Hubs.md) says one record. The [interaction spec](../concept/Morkahja-Live-RPG/05_Knowledge/Echo_Imprint_and_Attunement.md) says up to three. | [Interaction data](../game/data/interactions.json) sets the limit to zero, which the [evaluator](../game/scripts/simulation/ethera_evaluator.gd) treats as unlimited. |
| Echo Attunement | The [interaction spec](../concept/Morkahja-Live-RPG/05_Knowledge/Echo_Imprint_and_Attunement.md) describes receiving a needed Shard. | The authored [interaction](../game/data/interactions.json) grants a village delivery. |

The [decision register](DECISIONS.md) points to accepted rulings and the open questions in the canonical tree.

## Verification

The [headless suite](../game/scripts/tests/ethera_simulation_tests.gd) covers deterministic execution, snapshots, knowledge visibility, equipment, discovery, guidance and tasks, greeting, and local inhabitation. The [September 22 record](../concept/Morkahja-Live-RPG/99_Development/Changelog.md) reports 392 checks passing on that build. The November 11 review inspected source and documentation. The available Godot was 4.6.3, and the project documents 4.7.2. The game and simulation suite were not run for this review.
