# World Persistence and RealmNode

Morkahja's world runs across participating peers. One shared state preserves its people, places, objects and ongoing activity on participants' computers.

## Active simulation

While peers run the simulation, uninhabited people continue ordinary AI life. Players temporarily take control of available individuals and contribute actions to the same world.

## World time

The authoritative clock is a fixed simulation tick, currently twenty ticks per second. World time is derived from the tick count, so every machine reaches the same timestamps and knowledge retention does not depend on anyone's frame rate. Rendering runs at whatever rate the player's machine manages and interpolates between authoritative poses.

## Simulation fidelity and world progression

A region without players nearby does not freeze. It stops being simulated in full detail.

An **active region** simulates fully: movement, individual AI, interactions, physics and precise positions. A **dormant region** simulates abstractly: work, food consumption, rest, relationships, resource changes, birth and development, knowledge aging, village processes and important events.

A hunter leaving at dawn with nobody watching does not walk thousands of individual navigation steps. The dormant simulation resolves the activity deterministically and he returns with food, an injury or a discovery. The village keeps living; it simply does not tick every creature every frame.

## Pausing and resuming

This is separate from dormancy. When no machine simulates a region at all, world-time freezes there. Positions and ongoing actions remain at their saved state. Resuming continues that state without offline aging or catch-up activity.

A person carrying firewood halfway home remains there when the simulation pauses. A creature stays in its current place. The resumed world continues those lives and actions.

Storage and verification support persistence; world-time advances through active simulation, whether that simulation is full or abstract.

## Game and runtime

RealmNode provides the distributed runtime foundation alongside the game. Ethera supplies the shared entity, content and gameplay rules that operate within it.

[RealmNode: Game-Native Architecture](RealmNode_Game-Native_Concept.md) is the full architecture. It governs authoritative simulation structure, determinism, authority, validation and persistence. Read it before changing how the simulation is organized.

The runtime and RealmNode stay **separate modules**. RealmNode decides who calculates, who validates and whether state is accepted. The game runtime decides what an interaction means, how AI behaves and what consequences occur. Game rules do not live inside the networking layer.

## What a client is entitled to know

Hidden knowledge stays authoritative state. A client receives only what its current character is entitled to observe.

One exception is already designed: the inhabited character always receives the **bearing** of their selected quest objective. If someone takes that object, the taker is in that character's observable universe. The client gets the angle and a rough place, not the rest of the unseen region's hidden facts.

No single machine owns a Memory Fountain; its knowledge is a settlement knowledge shard with a current authority, validators and storage replicas. When a client needs to know whether its character may perform an interaction, it asks, and the authoritative runtime evaluates character knowledge, Fountain knowledge, discovery state and the remaining requirements before returning the permitted result.

Rendering an interaction menu is never a reason to copy every hidden fact onto a player's machine. This matters because Morkahja knowledge is deliberately local, imperfect and culturally stored rather than an omniscient database.

## Items and the two speeds of truth

Creating, transferring or changing ownership of an item needs stronger validation than ordinary movement, but the player never waits for it. The click takes the item at once, while the durable transaction proceeds from pending to validating to committed underneath. Only a validation failure causes reconciliation. Equipment behaves the same way: an already-owned tool affects combat immediately under regional authority while its persistent state commits asynchronously.

A disconnect before a consequence is committed cancels the unfinished round, exactly as a deliberate cancel does. A disconnect afterward changes nothing; a committed consequence is never reversed because the actor vanished.

## Event identity and retention

Persisted state includes immutable Shard records, holder references and original world timestamps. Exchange preserves record identity across holders. Retention uses world time, so the selected freeze of world simulation also freezes the ordinary knowledge-retention clock.

Permanent death removes character-held references; unreferenced Shards can be deleted. Archival stones and the Fountain apply their respective preservation policies. The [Shard model](Shard_Records_and_Retention.md) supplies these game requirements for the distributed runtime.

## Local first milestone

Milestone 1 runs one local authoritative simulation in Godot. Every entity and Shard has a stable identity. The world owns characters and objects; the player controller identifies the person currently inhabited. Traits, equipment, knowledge and state remain on world entities.

UI reads entity data, and interaction outcomes pass through the interaction system. Visual scenes and simulation data remain separable so later RealmNode integration can distribute state changes. Shape Weapon updates manifestation, equipment and the event record in the simulation, then presentation shows the resulting state. Network execution and save/reload enter later milestones.

See [Entities and Interactions](Entities_Interactions_and_Content_Authoring.md).
