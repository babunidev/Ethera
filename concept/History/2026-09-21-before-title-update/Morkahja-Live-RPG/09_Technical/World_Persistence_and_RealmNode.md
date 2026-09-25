# World Persistence and RealmNode

Morkahja's world runs across participating peers. One shared state preserves its people, places, objects and ongoing activity on participants' computers.

## Active simulation

While peers run the simulation, uninhabited people continue ordinary AI life. Players temporarily take control of available individuals and contribute actions to the same world.

## Pausing and resuming

When active simulation stops, world-time freezes. Positions and ongoing actions remain at their saved state. Resuming continues that state without offline aging or catch-up activity.

A person carrying firewood halfway home remains there when the simulation pauses. A creature stays in its current place. The resumed world continues those lives and actions.

Storage and verification support persistence; world-time advances through active simulation.

## Game and runtime

RealmNode provides the distributed runtime foundation alongside the game. Morkahja supplies the shared entity, content and gameplay rules that operate within it.

## Event identity and retention

Persisted state includes immutable Shard records, holder references and original world timestamps. Exchange preserves record identity across holders. Retention uses world time, so the selected freeze of world simulation also freezes the ordinary knowledge-retention clock.

Permanent death removes character-held references; unreferenced Shards can be deleted. Archival stones and the Fountain apply their respective preservation policies. The [Shard model](Shard_Records_and_Retention.md) supplies these game requirements for the distributed runtime.

## Local first milestone

Milestone 1 runs one local authoritative simulation in Godot. Every entity and Shard has a stable identity. The world owns characters and objects; the player controller identifies the person currently inhabited. Traits, equipment, knowledge and state remain on world entities.

UI reads entity data, and interaction outcomes pass through the interaction system. Visual scenes and simulation data remain separable so later RealmNode integration can distribute state changes. Shape Weapon updates manifestation, equipment and the event record in the simulation, then presentation shows the resulting state. Network execution and save/reload enter later milestones.

See [Entities and Interactions](Entities_Interactions_and_Content_Authoring.md).
