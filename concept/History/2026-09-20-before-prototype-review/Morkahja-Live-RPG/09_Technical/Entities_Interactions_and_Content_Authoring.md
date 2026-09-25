# Entities, Interactions and Content Authoring

The game uses a shared entity framework and a common language for interaction requirements. Authored content supplies the behaviors and experiences that the simulation selects and combines.

## Shared entities

Characters, creatures, items, trees, boulders, buildings and memory stones share identity, Traits, state, position and interaction data. Components provide the additional information each entity needs, including body parts, inventory, Needs, Shards, relationships and AI.

Separate permitted content pools guide creation and rewards. Creatures draw appropriate creature qualities; playable people draw from their own pools. Two bears can have different Trait combinations and therefore different attacks, defenses or behavior.

## Flat Trait matching

The evaluator checks exact Traits and conditions. Grimnir, Humanoid, Earth Elemental, Individual, Climbable and other identity or target properties participate alongside capability and preference Traits.

Categories support content organization and selection. Interaction matching uses the actual requirements on the actor, target, carried objects and surrounding context.

## Interaction structure

| Part | Purpose |
| --- | --- |
| Requirements | Traits, Needs, knowledge, items, body, state, relationship and contextual conditions. |
| Target | The matching properties of the entity involved. |
| Skill phase | The action's authored timing, observation, movement, memory or other player challenge. |
| Results | Changes to bodies, state, items, knowledge, relationships or Need completion. |

Conditions inside one requirement group combine with AND. Complete alternative groups combine with OR. One satisfied group makes the interaction available.

A greeting can require Likes Kind on the actor and Kind on the target. A climb can require a climbable surface, the appropriate capability and a usable body. Mountain Strike requires its own attack capability, suitable opponent and healthy arm.

## Authored content and generation

Interactions, Traits and Needs are authored with their requirements and effects. The procedural layer selects, places and assembles this content into creatures, locations and appropriate task sequences. Runtime gameplay uses those definitions.

Each Need definition includes its importance setting for interface highlights. Content is refined through playtesting.

## Cached matches

The first focus between entities compares their relevant data and records matching actions. Later focus checks which data has changed before reusing the result.

Category flags or versions track changes to Traits, inventory, Needs, Shards, states, injuries and relationships. Changed information invalidates affected matches; relevant requirements are recalculated when the interaction is requested.

This internal state supports current action availability while the player sees the resulting contextual choices.

## Resolution records and knowledge holders

Entities with a Shard-holder capability maintain references to stable immutable event records. A successful action and its reactions produce exactly one Shard after the final world result. The record supports multiple actors, targets, reactions and result references around one primary action and one place.

Capability checks establish wheel availability. Execution success comes from the player-skill phase, followed by reaction resolution. Item use checks the relevant Trait or knowledge. Interaction initiation targets a physical world entity; selection panels belong inside that interaction.

Tasks evaluate real completion conditions as relevant world state changes. Completed task objects can be discarded. A separate lightweight history retains 100 recent interactions.

The [Shard data model](Shard_Records_and_Retention.md) defines event identity, holder retention and reference-based deletion.

See [Interaction Design](../06_Gameplay/Interactions_Discovery_and_Player_Skill.md) and [Needs](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md).
