# Game Vision and Principles

The settlement guarantees a safe baseline; players create flourishing and major growth. World-time freezes when no peer runs the simulation. See [Community](../04_Community/Settlement_Simulation_and_Tasks.md) and [Persistence](../09_Technical/World_Persistence_and_RealmNode.md).

**Current concept through answer 202 · updated 2026-09-12.**

The purpose of the game, ownership of progress, and the rules that guide every system.

## Game Vision

### The experience

Morkahja Live RPG is a shared, persistent 3D world for temporary roleplay. A player enters an existing life, chooses from available characters, and inhabits one for a session. The character already has a place in society, qualities, knowledge, and a history. The world owns that person; the player does not create or permanently own an avatar.

The same person is an NPC under AI control and a player character while inhabited. Logging out leaves the person in the world, where life continues and another player may later take over. Sessions should feel like joining a tabletop roleplaying adventure: immersive, meaningful, and temporary, without pressure to stay for hours.

### What persists

Characters, community, knowledge, objects, and world history persist. The village benefits from a hunt, discovery, or successful adventure and also shares the effects of failure. Character development exists, but its gains belong to that person in the world, not to the account currently controlling them.

The account has no permanent gameplay possessions or progression. A lightweight diary of past participation remains an optional idea.

### Setting and scope

This is the same Morkahja as the existing game world, in a far earlier age of small isolated elemental communities and emerging magic. It is a multiplayer RPG, not a settlement-building game. Players act as people within an autonomous society.

See [Core Game Loop](Game_Loop_and_Sessions.md), [Ancient Morkahja](../01_World/Ancient_World_and_Magic.md), and [Character Selection](../06_Gameplay/Multiplayer_Characters_and_Handoff.md).

The interaction foundation is now explicit: persistent Traits and Desires, situational Shards and Needs, and ordinary humanoid/elemental baseline actions. Knowledge and positive social bonds spread through performed local interactions. Combat uses timed responses and broad functional injuries, while exchange objectives can form long emergent chains. See [Interaction System](../06_Gameplay/Interactions_Discovery_and_Player_Skill.md).

### First experience and player attention

Begin with one Grimnir settlement. Playable life starts in youth; community participation culminates in a ritual revealing role and beginning destiny. The player chooses a life before inhabiting it and then acts through the world; the panel explains the person and permits prioritizing an existing task or quest.

The experience is quiet, curious, and dreamlike. Exploration rewards attention; physical carrying and deterministic craft sustain material continuity. Interactions are discovered through play and executed through player skill. See [First Playable Scope](../99_Development/First_Playable_Scope.md).

## Design Principles

1. **The world owns its people.** Players temporarily inhabit persistent characters.
2. **Play a person.** Settlement growth, construction, and organization arise autonomously; players have no village management interface.
3. **Keep sessions voluntary.** Players can enter when a character is available and leave without maintaining a personal MMO avatar.
4. **Progress horizontally.** Binary traits add possibilities and diversity. Existing traits do not decay or disappear.
5. **Let lives generate adventures.** Traits inform roles; roles and destinies generate side quests and the world content needed for them.
6. **Keep goals stable and routes dynamic.** “Obtain a bear claw” can remain valid after the bear dies and the claw changes hands.
7. **Preserve physical continuity.** Objects exist independently of quest acceptance and remain after objective completion unless consumed or otherwise physically changed.
8. **Expand and reuse.** Every destiny adds new content while vacant nodes gain new purposes, keeping journeys manageable.
9. **Embody information.** Character condition, direction, and interaction should be readable through bodies and the world, with minimal UI.
10. **Make community participation meaningful.** Shared work, knowledge, celebration, and relationships sustain people and society.
11. **Reserve destiny progression for players.** AI maintains life and explores within endurance limits.
12. **Communicate in the world.** Context, traits, roles, relationships, and matching knowledge generate interactions. There is no player voice or text chat.

Simplicity is a repeated priority. The design avoids numerical trait ranks, routine trait loss, and a competing account progression system. Large metaphysical consequences exist through dissolution and corruption.

- Keep knowledge functional and local. No shard burden, capacity, or automatic global update.
- Define counterparts: Desire ↔ Trait and Need ↔ Shard, across people and the wider world.
- Preserve geography while repopulating content; keep historical knowledge in collective memory.
- Let the character screen explain Needs; task acceptance and other choices happen through in-world actions.
- Build neutral-to-positive social bonds first; defer negative relationship drama.
- Make combat a readable sequence of actions and injuries with continuing choices after incapacity.
- Start with ordinary embodied actions, then expand or restrict them through character state.
- Let exchange chains grow without a fixed depth limit; do not confuse this with travel-placement constraints.

### Additional design rules

- Begin with one functioning Grimnir settlement before adding cultures.
- Simulate early childhood; make youth participation, not time, lead to the adulthood rite.
- Let quests expand and converge toward one purpose, with switchable approaches and hidden complexity.
- Failure creates detours; every Need has a possible solution.
- Apply unmet-Desire generation priority locally, without rewriting existing people.
- Keep physical objects visible and crafting deterministic; more traits create compatibility rather than universal power.
- Make character capability determine possibilities and player skill determine execution.
- Hide unknown interactions completely; document them permanently after discovery.
- Use UI for information and world actions for choices.
- Keep Divine Orientation current but subtle and intermittent, distinct from mortal knowledge.

## Example E01: Whose success is it?

*Illustrative example from the discussion.*

A successful hunt feeds the village, not the player account. A discovered resource helps future inhabitants. Leaving the session does not remove the person or their contribution. The optional personal diary would remember participation without improving the next character.

Conversation: [turn 3](../../Morkahja-Concept-Sources.md#turn-61860fd7-3736-4e34-8e1f-5b2df237dd53), [turn 4](../../Morkahja-Concept-Sources.md#turn-68bb30f7-c1fd-45a2-a0d0-3a3cb10ec323), [turn 31](../../Morkahja-Concept-Sources.md#turn-b5d78ee2-e851-4993-a9e1-f4ba83873ceb).


## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.
