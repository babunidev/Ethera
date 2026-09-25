# First Playable: Specification and Readiness Review

## Assessment

The first-playable experience was established in the Morkahja live RPG discussion, especially answers 106–111. Its core is inhabitation, simple movement and social contact, item handling, landmark discovery, knowledge return and requirement-driven interaction availability.

Most of that scope was already present in the concept, but it was mixed with later systems and a combat-interaction prototype. The First Playable Scope chapter now brings the original experience together. The concept gives enough direction to begin foundational implementation; several concrete content and behavior definitions are still needed to complete the playable loop without inventing gameplay.

This review compares the agreed prototype specification with the saved Live RPG concept. It does not claim an executable build has been implemented or playtested.

## Coverage and missing definitions

| Prototype element | What is established | What remains to specify |
| --- | --- | --- |
| Initial place | Memory Fountain, placeholder village, nearby discoverable land; savanna/grass/hills atmosphere. | A concrete test-scene layout, positions, walkable routes and distances. |
| Population | Working settlement target of 30; a few nearly identical people suffice for the earliest test. | Exact initial test cast and their starting data. |
| Inhabitation | Each character has an ID and the shared architecture; leave to spectator and inhabit another; AI resumes. | Selection gesture, minimal spectator behavior, switch/cancel behavior during an active interaction. |
| Movement | Right-click destination, character-following orbit/zoom camera, physical world positions. | Navigation/collision approach, stop distance, walk speed and camera/input tuning. |
| Simple greeting | A few people can interact; an initial hello bubble is acceptable. | Exact greeting requirements, skill phase, response and resulting state/Shard. |
| Traits and matching | One or two test Traits can unlock an interaction with an item or matching target; preferences belong in Traits. | Named starting Traits and exact AND/OR requirement groups for the chosen test actions. |
| Item handling | Find an item, pick it up, visibly carry/equip it; logical slots and world persistence. | First item's identity, properties, body slot and use; valid placement/drop positions. |
| Landmark discovery | A stone circle or similar landmark provides discoverable knowledge. | The landmark interaction, its requirements, result and exact event/knowledge record. |
| Knowledge return | Bring learned knowledge to the Memory Fountain through Echo Attunement. | Initial holder contents, precise Fountain contribution selection and the feedback showing successful delivery. |
| Need/task | A tiny Needs model; people normally have an ongoing task; real completion condition governs. | One concrete test Need, its task, solution and completion condition. |
| Divine Orientation | Subtle environmental guidance supports the chosen useful route. | One actual cue, how the player reads it, when it appears and its relation to the test Need. |
| Climbable tree | Suggested concrete interaction in the first-playable discussion. | Whether it belongs in the earliest test; climbing recipe, challenge and movement result if included. |
| AI continuity | Leaving returns the character to AI and preserves that person's state. | A minimal authored routine showing the handoff clearly, without requiring full village simulation. |
| Persistence | Identities and objects belong to the world; simulation freezes without an active simulator. | Save/load format, snapshot boundary, world clock and a chosen local runtime boundary. |
| Visual readability | Unanimated figures, labelled boxes/lines or simple drawings are acceptable. | Feedback for focus, availability, blocked actions, pickup, knowledge gain and handoff. |

## Acceptance checks for the agreed experience

1. Inhabit an existing Grimnir near the Fountain and move through the village to a nearby interactable place.
2. Focus another character and complete the simple greeting, receiving readable feedback.
3. Find an item and pick it up; its world location and visible carrying state change consistently.
4. Demonstrate one interaction that depends on the test character's Trait and/or item. Changing the required data changes its availability, while known blocked actions explain the missing condition.
5. Discover the landmark, acquire the intended knowledge and carry that knowledge back through the character's Shard references.
6. Use Echo Attunement at the Memory Fountain and verify that the Fountain knows the delivered record.
7. Show a simple guidance cue supporting the chosen test task or destination.
8. Leave to spectator mode and inhabit another person. The first keeps their possessions, knowledge and state, and resumes the selected AI routine.

These checks translate the user's experience into observable outcomes. A save/reload check is an additional engineering verification for the concept's persistence requirement.

## Immediate design decisions

The most useful next definitions are a small scene and test cast; one greeting; one discoverable landmark; one carried item with a compatible interaction; one Need and a guidance cue; and the AI handoff behavior. Each included interaction needs a full requirement group, target, selected skill phase or pool and result.

The latest discussion supplies the reusable skill-phase framework, but not complete runnable definitions for those first actions. The requested 72-phase library is a draft. Selecting a small initial set and defining its input, timing, success and failure behavior would make the prototype implementable without requiring the whole library.

## Dependencies on wider design

Event Shards, shared references and knowledge exchange already have a detailed common model. The landmark/Fountain loop must use that model. Clarify who receives its generated event and how Fountain selection guarantees the intended contribution in the test scenario.

Archival stones, Echo Cradle creation, the complete combat system, birth, procedural Destiny and the full society extend the foundation. Their detailed specifications remain available in their own chapters. Their existence in the concept does not establish them as completion criteria for the first playable described in answers 106–111.

Engine selection, local persistence and the interface to RealmNode still need engineering choices. Foundation work can establish shared entities, authored data loading, input/focus and requirement evaluation while the remaining first-scene details are agreed.

See [First Playable Scope](First_Playable_Scope.md), [Open Questions](Open_Questions.md), [Player-Skill Phases](../06_Gameplay/Player_Skill_Phases.md) and the [source review](../../Reference_Material/Prototype_Review_2026-09-20/README.md).
