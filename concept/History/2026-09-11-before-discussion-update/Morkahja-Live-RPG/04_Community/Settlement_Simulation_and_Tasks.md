# Settlement Simulation and Tasks

**Current concept through answer 104 · reorganized 2026-09-10.**

One autonomous society: its needs, generated work, population, and AI-controlled everyday life.

## Village Simulation

The village is an autonomous society and the main home of persistent collective progress. It needs residents with meaningful functions, homes, partnership opportunities, resources, health, safety, and social life.

### Development

Community success supports reproduction and therefore more persistent people and playable slots. Food, clean water, warmth, and safety enable gatherings and healthier lives. Failures affect shared circumstances.

Players act through temporarily inhabited people. They have no authority to choose building positions, manage construction, or direct village expansion. The community develops itself.

### Initial settlement and broader cultures

Begin with one earth-aligned Grimnir settlement. The other peoples remain part of the broader concept for later expansion and have not yet met. Roles and practices vary by culture; population sizes and detailed starting content are undecided.

AI residents keep contributing when unplayed; the world continues without any players, potentially more slowly. An early idea of notifying players about an understaffed suffering village remains only an idea, not a finalized pressure or notification system.

Social development currently emphasizes neutral or positive connections, with recognition, sympathy, and trust arising through compatible interactions. Hatred and rivalry inside the young community are outside initial scope. Social bonds support partnership and reproduction; players help create circumstances for these interactions without directing settlement construction.

### Tasks and youth development

Simulation-generated community work supports supplies, well-being, rest, social bonds, and reproduction. It can deliberately involve other people; refusal causes adaptation rather than deadlock. Ordinary participation also develops playable youth toward the final adulthood rite. See [Community Tasks](#community-tasks).

## World Simulation

Morkahja persists when nobody is online. AI residents perform their roles and maintain the settlement rather than freezing between sessions. The simulation can slow down in the absence of players, but should still progress.

### What the simulation sustains

Community needs, homes, food, clean water, warmth, health, safety, social life, partnership, reproduction, and the lives of existing residents. Births add new people and playable slots. Objects and knowledge remain connected to their histories.

AI behaves sensibly and communally, maintaining ordinary life and exploring within endurance limits. It does not pursue personal destiny. Players introduce deliberate adventure, risk, and unusual choices through individual characters.

### Authority

Players do not decide village layout or direct its development. Construction and organization emerge from the society itself. Character actions affect communal conditions without granting settlement-level control.

### Open implementation

Tick rates, offline slowdown, population limits, ecological detail, and how growth maps to technical server capacity remain undesigned. Population-based slots are a game rule, not a claim that hosting capacity has no technical limits.

Active node state and historical knowledge are separated. Persistent geography has multiple content slots; past states survive in shards held by people and collective memory. Knowledge updates through performed interactions rather than global synchronization. See [World Nodes](../01_World/World_Nodes_and_Generation.md).

### Continuous useful work

Community tasks are continuously generated from the settlement's actual state. The knowledge fountain gives suitable work through direct interaction, or generates preparatory work when no urgent need fits. Cooperative tasks adapt if a requested participant declines. See [Community Tasks](#community-tasks).

Early childhood remains in the simulation; player control begins in youth. Youth-to-adult progress requires participation and a final ritual, not merely offline elapsed time.

## Community Needs

The village needs more than quest completion. Its ongoing tasks include food, clean water, warmth at night, homes, health, safety, partners and reproduction, meaningful roles, and opportunities for enjoyment and connection.

Material conditions support social events: a community needs sufficient food, water, warmth, and security to gather comfortably. Celebration and shared activity in turn help sustain its members.

### Player contribution

A hunter brings food, an explorer brings observations, and a character may contribute an object or information about possessing it. Participation matters even when a session does not advance destiny.

General village tasks coexist with personal destiny and side quests. Their benefit belongs to the community rather than the player account.

### Elemental interpretation

The source lore grounds different environmental dependencies: Rokur bodily balance in cold surroundings, Verdani water stewardship, Aevis maintained atmosphere, and Grimnir craft and navigation. How each need operates in primitive settlements remains to be designed; no resource rates or numeric meters have been established.

Character Needs are now explicitly situational requirements paired with Shards; persistent personal motivations are Desires paired with Traits. This terminology complements the broader food, safety, and social requirements here rather than replacing them. Matched interactions build positive bonds and support the community's partnership and population cycle. See [Needs](../03_Characters/Identity_Traits_Desires_and_Needs.md).

### Culture-specific interpretation and delivery

The initial culture is Grimnir. Concrete diet, hunting, and other bodily needs remain to be designed; human-style resource examples illustrate the general system rather than final Grimnir content. Suitable tasks emerge continuously and can provide long-term preparation even without urgent shortages. See [Community Tasks](#community-tasks).

## Community Tasks

### Generated from living conditions

Community tasks are continuous outputs of the autonomous settlement simulation. They respond to actual needs and opportunities, not a static daily quest board. Their benefits include communal health, rest and recovery, supplies, social bonds, reproduction, and shared well-being. Buff values and exact task content remain unspecified.

Destiny quests concern the individual's unfolding purpose. Community tasks are the primary home for deliberately cooperative daily work.

### Suitable work at the knowledge fountain

The character approaches the cultural knowledge fountain and uses an in-world task interaction. The system considers settlement needs and the person's role/capabilities. It provides suitable work; if nothing urgent fits, it generates useful preparatory or future-facing work.

A hunter gathering long-lasting materials or preparing for winter illustrates this principle. It does not establish a Grimnir diet or a mandatory winter system.

Task acceptance is direct: contextual input → cultural animation → accepted task → guidance. Do not open a menu asking which activity genre the player feels like doing. The major choice was inhabiting this role.

### Cooperation without dead ends

A task can consider another character even when they are elsewhere. First find them, then share the task through an interaction. They may accept or decline.

If declined, the task can seek another suitable participant, change requirements, or adapt the objective to one person. Cooperation is encouraged without allowing refusal to permanently block progress.

Ordinary community activity also develops playable youth. Precise assignment rules, concurrent task count, AI responses to invitations, and changing-task reconciliation remain open.

See [Village Simulation](#village-simulation), [Memory Wells](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md), and [Objectives and Side Quests](../06_Gameplay/Destiny_Quests_and_Progression.md).

## AI Control

Uninhabited characters remain active people. AI fulfills their community role at a basic competent level, participates in society, and can explore and gather knowledge.

### Limits

AI does not advance personal destiny. Exploration is limited by tiredness and the ability to return home. Meaningful community participation replenishes a character and keeps them healthy without requiring a player to advance destiny constantly.

The offline society acts sensibly and maintains itself rather than deliberately sabotaging or exploiting the world. Simulation can slow when no players are present.

### Handoff

Manual logout sends the character home under AI. Unexpected disconnection first leaves them waiting in place, until they must depart to get home before excessive fatigue. An opted-in stand-in may temporarily take control when there is a queue.

See [NPC AI](#npc-ai) and [Logout and Handoff](../06_Gameplay/Multiplayer_Characters_and_Handoff.md).

Computer-controlled creatures and enemies use the same state-dependent interaction changes as player-controlled beings. Broad injuries can restrict actions and incapacity can enable alternative outcomes. This does not change the rule that AI does not advance personal destiny. See [Combat](../06_Gameplay/Combat_and_Injuries.md).

## NPC AI

### Responsibilities

Maintain the character's ordinary role and community participation. Residents support settlement needs when no player inhabits them. They can explore and collect knowledge, but only within limits that allow a return home before excessive tiredness.

### Hard narrative boundary

NPC AI does not advance personal destiny. Player inhabitation is required for that part of a life. Community participation sustains AI residents, so an unplayed destiny does not by itself force everyone toward dissolution.

### Absence states

Normal uninhabited life continues under AI. Manual logout starts a return home. Unexpected disconnect begins a waiting phase, followed by return when endurance and distance require it. Temporary stand-in control can interrupt that absence under the queue rules.

### World time

The simulation continues with no players and may slow down. AI acts to maintain its community rather than deliberately exploiting or sabotaging it.

Behavior architecture, pathfinding, danger response while waiting, simulation budgets, and knowledge-sharing schedules have not been selected.

AI entities share the injury and interaction-state rules of player-controlled characters. Available actions change with condition, including nonlethal or survival options when fighting cannot continue. Baseline actions exist before personal traits and roles modify them. See [Injuries](../06_Gameplay/Combat_and_Injuries.md) and [Baseline Actions](../03_Characters/Roles_and_Baseline_Abilities.md).

## Example E22: Material conditions enable communal life

*Illustrative example from the discussion.*

Food, clean water, homes, warmth at night, health, and safety support gatherings, partnership, reproduction, and well-being. The simulation—not a player building interface—manages village development. Specific Grimnir bodily needs remain undesigned.

Conversation: [turn 3](../../Morkahja-Concept-Sources.md#turn-61860fd7-3736-4e34-8e1f-5b2df237dd53), [turn 30](../../Morkahja-Concept-Sources.md#turn-f499dd18-cb30-4b04-8057-289b2fad5f9e), [turn 89](../../Morkahja-Concept-Sources.md#turn-e87391b6-8352-4027-93f7-e0fd79bc5360).

## Example E23: Useful work without a manufactured crisis

*Illustrative example from the discussion.*

A hunter can obtain long-lasting crafting materials or prepare for winter even when no urgent hunt is needed. The fountain supplies work matching the person and real or future communal value. Hunting and winter are examples, not fixed initial Grimnir requirements.

Conversation: [turn 107](../../Morkahja-Concept-Sources.md#turn-32ff16c3-2511-45d0-befd-7c1329f7c78e), [turn 108](../../Morkahja-Concept-Sources.md#turn-694e3f1c-2e47-4657-9385-0c9834cf3952).

## Example E24: Find a collaborator, then ask

*Illustrative example from the discussion.*

A task first leads to another person. Share the task through an interaction; they may accept or decline. On refusal, find another suitable person, adapt requirements, or make it possible alone. The work supports communal recovery, rest, buffs, and reproduction without forcing cooperation.

Conversation: [turn 106](../../Morkahja-Concept-Sources.md#turn-a64040d4-3bcf-4d06-9a17-846dbf358690).

## Example E25: Unplayed life is still purposeful

*Illustrative example from the discussion.*

AI can explore until tired, bring knowledge home, and restore itself by fulfilling a communal role. It does not pursue personal destiny. With nobody online, the settlement continues and may run more slowly.

Conversation: [turn 15](../../Morkahja-Concept-Sources.md#turn-d930f001-c4c9-48dc-983a-78de2b8e4db6), [turn 24](../../Morkahja-Concept-Sources.md#turn-532653fb-0361-4b58-8673-032c4bfb5c82).


## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.
