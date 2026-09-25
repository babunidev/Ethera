# First Playable Scope

The first playable grows through small connected milestones. **Milestone 1 follows Khar-Morr the First Carved as she shapes a stone club, handles her equipment and contributes the resulting knowledge to the Memory Fountain.** Godot runs the Windows desktop game; Blender supplies the 3D assets. Input uses mouse and keyboard.

## Milestone 1: Khar-Morr

A small terrain patch contains Khar-Morr, a Memory Fountain near its center, a nearby shapeable rock and a second club for testing pickup and swapping. Open space connects them. Khar-Morr begins healthy with the capabilities for Shape Weapon and Echo Imprint. The Fountain begins empty.

Walk to the rock, choose Shape Weapon through the radial menu, complete Shape Trace and receive an equipped club and an event Shard. Walk to the Fountain and complete Echo Imprint through Shard Fit. The Fountain gains access to the same Shard. A simple character panel and development event log make the result inspectable.

Basic item handling is included in this milestone: pick up the ground club and swap it with the one attached to Khar-Morr's back. The two clubs have different base colors so their movement is easy to follow. The [Milestone 1 specification](Milestone_1_Khar_Morr.md) collects the complete starting state and acceptance checks.

## Milestone 2: discovery and knowledge

Add a discoverable world object such as a stone circle. Hovering the on-screen interactable object automatically creates a Discovery record using the shared event-Shard structure. Bring this knowledge to the Fountain through Echo Imprint. This adds observation as another source of knowledge.

## Working sequence for later milestones

| Milestone | Playable addition |
| --- | --- |
| 3: Need and Divine Orientation | One concrete Need, a tiny task, a knowledge route and an environmental cue; completion follows the achieved condition. |
| 4: another Grimnir and social play | Add a second test character and a simple greeting with visible feedback and an event record. Echo Attunement can retrieve needed knowledge held by the Fountain. |
| 5: inhabitation | Leave a character, spectate and inhabit another. Minimal AI resumes for the person left behind; their state, items and knowledge remain theirs. |
| 6: persistence | Save and reload characters, manifested objects, equipment, Shard references, Fountain knowledge and relevant world state. |

The later order remains adjustable. Persistence should arrive early enough to support development; the discussion also raised bringing it forward around the third step. Milestones 1 and 2 have the explicit current scope above.

## Repeatable test characters

Keep Khar-Morr's initial test configuration available. As features arrive, add Grimnir with configurations suited to exercising them and preserve the earlier configurations. Two characters become necessary for switching. Each person shares the entity architecture and retains an individual identity and state.

## The growing settlement

The wider first-playable direction remains a small Grimnir settlement with social contact, items, discovery, Needs, guidance and inhabitation. Thirty Grimnir is the working settlement population target. A temporary hello bubble can make the first greeting visible; a climbable tree is an expansion example. These belong to later additions.

The intended world uses large modular hexagonal terrain tiles, initially with grass and hills. Tiles contain local places and can take minutes to cross; forests and mountains continue into neighboring areas. Quest content can expand permanent geography. Savanna space, grass and changing wind establish atmosphere while architecture and animation develop.

Adults in the wider game have Destiny threads and community tasks. The initial test character carries only the data needed to exercise her milestone. Read [Prototype Readiness](Prototype_Readiness_Review.md) for the remaining specification questions.
