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

See [Entities and Interactions](Entities_Interactions_and_Content_Authoring.md).
