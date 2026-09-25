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
| Skill phase | The action's authored mouse-positioning and timing challenge with its own time limit. |
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

Capability checks establish wheel availability. Execution success comes from the player-skill phase, followed by reaction resolution. Authored item abilities check the relevant Trait or knowledge. Inherent walking and pickup use their direct controls. Interaction initiation targets a physical world entity; selection panels belong inside that interaction.

Tasks evaluate real completion conditions as relevant world state changes. Completed task objects can be discarded. A separate lightweight history retains 100 recent interactions.

The [Shard data model](Shard_Records_and_Retention.md) defines event identity, holder retention and reference-based deletion.

## Reusable skill definitions and object requirements

Interactions refer to separately authored skill-phase definitions through category and subcategory, with an optional exact phase. Without an exact phase, selection draws randomly from the matching pool each round. A phase belongs to one subcategory and contains its authored challenge.

Target requirements match Traits on world entities. Bind Shard requires an entity carrying Echo Cradle, alongside the actor capability, stone and known Shard requirements. The same evaluator can support another entity bearing that Trait. Create Echo Cradle consumes its defined inputs and replaces the suitable source object with a new authored Cradle entity at the source location.

## State filters and inherent actions

Negative-state definitions hold blocked interaction IDs and/or blocked Trait IDs. Evaluate normal requirement groups, then apply this filter. Trait blocking changes usability while preserving identity and possession of the Trait. State removal invalidates the affected availability results so matching can be recomputed.

Walking and compatible-item pickup are inherent actions. Hover discovery creates its common event record directly. These entry points share entity identity, item state and knowledge infrastructure with authored interactions while using their own inputs.

Shape Weapon matches Weapon Shaping, a healthy usable arm, Rock and Shapeable; success replaces the rock manifestation with an equipped club. Echo Imprint queries the actor's known Shard IDs against target membership. Echo Attunement queries needed IDs against target membership. Their selected transfer keeps the same Shard ID and original timestamp.

The [Milestone 1 specification](../99_Development/Milestone_1_Khar_Morr.md) supplies concrete initial data, fixed phase assignments, scene contents and observable results.

See [Interaction Design](../06_Gameplay/Interactions_Discovery_and_Player_Skill.md) and [Needs](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md).

See [Player-Skill Phases](../06_Gameplay/Player_Skill_Phases.md) and [Archival Interactions](../05_Knowledge/Archival_Stones_and_Echo_Cradles.md).
