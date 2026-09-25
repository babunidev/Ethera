# Milestone 1 Implementation Handoff

Start with the [Milestone 1 specification](Milestone_1_Khar_Morr.md), [environment brief](../08_Presentation/Milestone_1_Environment.md) and [readiness review](Prototype_Readiness_Review.md). The latest main discussion accepts the complete playable loop and a visible low-poly game environment. This package contains design and reference assets; a built game and Blender models still need implementation verification.

## Build sequence

1. Establish a Godot Windows desktop project with stable world/entity data and a local authoritative simulation.
2. Build the small environment and separate Fountain from the visual references. Add bare living-stone Khar-Morr, the shapeable rock and two distinguishable clubs.
3. Connect right-click walking, self-drag camera orbit, mouse-wheel zoom, hold-left-click radial selection, automatic approach/facing and the C character panel.
4. Implement Shape Weapon and Shape Trace, including the result, equipment replacement and immutable event Shard.
5. Implement direct pickup/swap with the displaced club taking the clicked club's exact ground position.
6. Implement Echo Imprint and Shard Fit, reference sharing and the new event record; expose results through the panel and upper-right development log.
7. Run the success/failure and state-inspection checks in the milestone specification and tune timing, distances, collision and camera behavior in play.

This sequence is an implementation arrangement of the agreed scope. Networking remains later work. The Echo Imprint event-recipient inconsistency remains visible in the readiness review rather than being assigned a new rule here.

## Local asset register

| Asset | Local reference | Production role |
| --- | --- | --- |
| Khar-Morr | [Bare low-poly front/side reference](../../Reference_Material/Discussion_2026-09-21/Images/KarrMorrConceptLowPolybare.png) | Selected character shape; almost entirely bare living stone. |
| Earlier Khar-Morr concept | [Concept](../../Reference_Material/Discussion_2026-09-21/Images/KarrMorrConcept.png) and [low-poly variant](../../Reference_Material/Discussion_2026-09-21/Images/KarrMorrConceptLowPoly.png) | Supporting design history. |
| Memory Fountain | [Appearance](../../Reference_Material/Discussion_2026-09-21/Images/MemoryFountain.png) and [modeling views](../../Reference_Material/Discussion_2026-09-21/Images/memoryFountain4Blender.png) | Separate Fountain model; side/top/bottom views support construction. |
| Village center | [Environment brief](../08_Presentation/Milestone_1_Environment.md) | Terrain, continuous shaped-stone structures, integrated seats, paths, sparse plants and warm daylight. |
| Shapeable rock | [Shape Weapon](../06_Gameplay/Shape_Weapon.md) | One Rock + Shapeable world entity supplying the club. |
| Clubs | [Equipment](../07_Items/Items_Equipment_and_Carrying.md) | Same functional definition, different base colors, Small Weapon attachment on back. |
| Shape Trace and Shard Fit | [Skill phases](../06_Gameplay/Player_Skill_Phases.md) | Simple angular golden graphics with integrated visual timers. |

All five named Pictures originals match the archived image bytes. References remain accessible within this folder and its ZIP. The [new source archive](../../Reference_Material/Build_Handoff_2026-09-21/README.md) also contains the original character portrait and supporting naming attachments.

## Asset boundaries and tuning

The environment is modeled with an open Fountain placement area; the assembled milestone includes the Fountain. Build a few stone masses and integrated seats. The assistant suggested 2–4 masses and 3–6 seats as practical planning quantities; these are adjustable, not extra locked content requirements.

Keep right-angle corners, rectangular doorways, masonry seams and chisel marks out of the selected environment treatment. Use broad facets around organic continuous forms. The initial Khar-Morr model omits the earlier bronze-looking adornments and cloth. Animation can improve incrementally.

An Echo Cradle placeholder was discussed in Grimnir Works, then omitted from the main accepted environment brief and explicitly deferred in the final milestone recap. The current environment package does not add that object or memory-stone props to Milestone 1.

## Runtime boundary

One local simulation owns the world state. Stable IDs identify characters, objects, places and Shards. The player controller holds the current inhabitation relationship. Traits, equipment, knowledge and conditions belong to entities; UI and scene objects display that state.

Interaction results flow through the shared system. Shape Weapon updates the rock manifestation, new club, equipment and event record in world state; Godot renders the result. Later RealmNode work can distribute and validate state changes through this boundary. Save/load, replicas, peer discovery, prediction, rollback and consensus belong to subsequent work.
