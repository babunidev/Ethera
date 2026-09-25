# Settlement Simulation and Tasks

**Current concept through answer 202 · updated 2026-09-12.**

One autonomous society: its needs, generated work, population, and AI-controlled everyday life.

## Village Simulation

The village is an autonomous society and the main home of persistent collective progress. It needs residents with meaningful functions, homes, partnership opportunities, resources, health, safety, and social life.

### Development

Community success supports reproduction and therefore more persistent people and playable slots. Food, clean water, warmth, and safety enable gatherings and healthier lives. Failures affect shared circumstances.

Players act through temporarily inhabited people. They have no authority to choose building positions, manage construction, or direct village expansion. The community develops itself.

### Initial settlement and broader cultures

Begin with one earth-aligned Grimnir settlement. The other peoples remain part of the broader concept for later expansion and have not yet met. Roles and practices vary by culture; the working starting population is 30 Grimnir, while detailed content remains under refinement.

AI residents contribute while a simulation node is active; without one the world freezes. The earlier suffering-village alert idea is superseded by guaranteed baseline survival.

Social development currently emphasizes neutral or positive connections, with recognition, sympathy, and trust arising through compatible interactions. Hatred and rivalry inside the young community are outside initial scope. Social bonds support partnership and reproduction; players help create circumstances for these interactions without directing settlement construction.

### Tasks and youth development

Simulation-generated community work supports supplies, well-being, rest, social bonds, and reproduction. It can deliberately involve other people; refusal causes adaptation rather than deadlock. Ordinary participation also develops playable youth toward the final adulthood rite. See [Community Tasks](#community-tasks).

## World Simulation

Morkahja persists as saved shared state. AI acts while a peer runs the simulation; without active simulation the world freezes exactly, with no offline progress or cleanup.

### What the simulation sustains

Community needs, homes, food, clean water, warmth, health, safety, social life, partnership, reproduction, and the lives of existing residents. Births add new people and playable slots. Objects and knowledge remain connected to their histories.

AI behaves sensibly and communally, maintaining ordinary life and exploring within endurance limits. It does not pursue personal destiny. Players introduce deliberate adventure, risk, and unusual choices through individual characters.

### Authority

Players do not decide village layout or direct its development. Construction and organization emerge from the society itself. Character actions affect communal conditions without granting settlement-level control.

### Open implementation

Tick rates, snapshot/commit timing, ecological detail, and how uncapped design growth maps to technical capacity remain undesigned. Offline slowdown is superseded by freezing when no simulation runs. Population-based slots are a game rule, not a claim that hosting capacity has no technical limits.

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

The initial culture is Grimnir. Food, minerals, water, and geomancy now define Grimnir nourishment; hunting examples still do not establish a required role roster. Suitable tasks emerge continuously and can provide long-term preparation even without urgent shortages. See [Community Tasks](#community-tasks).

## Community Tasks

### Generated from living conditions

Community tasks are continuous outputs of the autonomous settlement simulation. They respond to actual needs and opportunities, not a static daily quest board. Their benefits include communal health, rest and recovery, supplies, social bonds, reproduction, and shared well-being. Buff values and exact task content remain unspecified.

Destiny quests concern the individual's unfolding purpose. Community tasks are the primary home for deliberately cooperative daily work.

### Suitable work at the knowledge fountain

The character approaches the cultural knowledge fountain and uses an in-world task interaction. The system considers settlement needs and the person's role/capabilities. It provides suitable work; if nothing urgent fits, it generates useful preparatory or future-facing work.

A hunter gathering long-lasting materials or preparing for winter illustrates this principle. It does not establish a Grimnir diet or a mandatory winter system.

Task acceptance is direct: contextual input → cultural animation → accepted task → guidance. Do not open a menu asking which activity genre the player feels like doing. The major choice was inhabiting this role.

### Cooperation without dead ends

A task can consider another character even when they are elsewhere. First find them, then share the task through an interaction. Player-controlled recipients may accept or decline; capable AI cooperates.

If declined, the task can seek another suitable participant, change requirements, or adapt the objective to one person. Cooperation is encouraged without allowing refusal to permanently block progress.

Ordinary community activity also develops playable youth. Exact assignment scoring, concurrent task count, and reconciliation remain open. Capable AI pauses ordinary work to cooperate; player-controlled recipients may decline.

See [Village Simulation](#village-simulation), [Memory Wells](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md), and [Objectives and Side Quests](../06_Gameplay/Destiny_Quests_and_Progression.md).

## AI Control

Uninhabited characters remain active people. AI fulfills their community role at a basic competent level, participates in society, and can explore and gather knowledge.

### Limits

AI does not advance personal destiny. Exploration is limited by tiredness and the ability to return home. Meaningful community participation replenishes a character and keeps them healthy without requiring a player to advance destiny constantly.

Unoccupied people perform basic communal activity while simulation runs. When the last simulation node stops, time and activity freeze.

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

The world freezes without an active simulation node. While running, AI maintains ordinary community activity without initiating reproduction or pursuing Destiny.

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

A task first leads to another person. Share the task through an interaction; player-controlled recipients may accept or decline, while capable AI cooperates. On refusal, find another suitable person, adapt requirements, or make it possible alone. The work supports communal recovery, rest, buffs, and reproduction without forcing cooperation.

Conversation: [turn 106](../../Morkahja-Concept-Sources.md#turn-a64040d4-3bcf-4d06-9a17-846dbf358690).

## Example E25: Unplayed life is still purposeful

*Illustrative example from the discussion.*

AI can explore until tired, bring knowledge home, and restore itself by fulfilling a communal role. It does not pursue personal destiny. The earlier offline-continuation example is superseded: with no active simulation node, the world freezes.

Conversation: [turn 15](../../Morkahja-Concept-Sources.md#turn-d930f001-c4c9-48dc-983a-78de2b8e4db6), [turn 24](../../Morkahja-Concept-Sources.md#turn-532653fb-0361-4b58-8673-032c4bfb5c82).




## Support, care, and broad participation

The first settlement's working population target is **30 Grimnir**, to be refined against resources, roles, and task availability. This is a society target, not a requirement to populate the earliest control test with thirty complete characters.

Food, minerals, water, rest, and nurturing support communal life. Prepared meals create opportunities for hunger-related interactions and temporary well-being. Stable nesting places support parental quests; available housing and provisions gate children becoming playable, and existing surplus counts. See [Grimnir physiology and care](../03_Characters/Grimnir_Physiology_and_Care.md) and [Birth, Youth and Adulthood](../03_Characters/Birth_Youth_and_Adulthood.md).

Roles express dominant traits but do not lock duties. The source offers tasks matching all usable traits, including capabilities outside the dominant role. Knowledge, stories, wandering, creativity, and care are contributions; belonging never depends on ability to work. A person unable to contribute remains cared for.

At takeover, an adult usually already has community activity and an available Destiny thread. AI still does not advance personal destiny. The player can continue the current task or select another existing thread in the panel. Accepting a new task from the cultural source remains an in-world interaction.

Source: [answer 106](../../Morkahja-Concept-Sources.md#turn-25a023af-5c41-43a5-aab6-4c8d8127c958), [answer 109](../../Morkahja-Concept-Sources.md#turn-6925b17c-b666-43cf-be30-828048602e2f), [answer 113](../../Morkahja-Concept-Sources.md#turn-df6e2a5d-a76f-4540-a674-8716eb21cd37), [answer 120](../../Morkahja-Concept-Sources.md#turn-c9486a85-b694-4148-8d0a-75a5de77a268), [answer 121](../../Morkahja-Concept-Sources.md#turn-ee03fc9f-f44e-4a19-953d-7c52f8acd3bb), [answer 122](../../Morkahja-Concept-Sources.md#turn-dcfbdf7a-f13b-41cc-ba5e-1f7b1c6c75d7).


## A safe baseline with player-led flourishing

Basic survival is guaranteed. The settlement does not enter starvation, misery, or collapse because a supply task was neglected. The village provides the basics; tasks create surplus, cultural life, joy, comfort, rituals, celebration food, and support for growth. A child can wait for the support needed to become playable without dying of inadequate surplus.

Everyone can participate in ordinary community tasks; role/trait specialists do them more efficiently. Example: a hunter returns a larger deer or more yield while an inexperienced contributor brings a smaller result. Favor suitable people, then allow others or several contributors when the activity matters and specialists are unavailable. This baseline participation does not abolish special-interaction compatibility requirements.

AI animates unoccupied children, youths, and adults through ordinary gathering, carrying, resting, and community activity. It can return with a real item or Shard that becomes a quest objective. Major growth and new reproduction are player-led; AI does not initiate reproduction or progress Destiny Crests/Knots. A stable village need not automatically generate an escape from stagnation. Player activity improves life above a secure baseline.

Capable AI pauses ordinary work to help when approached. It does not reject a player simply because it is busy. Knowledge exchange is a participating cultural ritual, not instant copying. Possible expressions discussed include resonant rhythm, a small stomping dance, or vibrating floating sand carrying memory between bodies; none is final choreography. A player-controlled partner still decides whether to accept.


Source: [answer 161](../../Morkahja-Concept-Sources.md#turn-b69557d1-1bf7-4566-bfc3-c923c6d872b3), [answer 162](../../Morkahja-Concept-Sources.md#turn-11a3c22d-afb3-4307-957b-e73d6f808906), [answer 163](../../Morkahja-Concept-Sources.md#turn-a92dcfd6-cd0d-4df4-bff6-0e4071d78a88).


## Expansion and contributing to construction

There is no desired arbitrary population cap. Growth depends on created support; actual hardware and RealmNode limits remain technical constraints, not a promise of infinite capacity.

Expand horizontally over hex-based outskirts first. Add houses and needed workspaces; a person's home can also house their craft workplace. Higher or floating houses are later possibilities, not early Skylands. The simulation determines what is needed and where it is placed; players do not become settlement planners.

Construction can be a simple site with visible stages. Stone-shapers and others make, bring, install, or shape required components. Each contribution makes visible progress and can fulfill a desire to build/contribute; completion makes the site usable. Automatic placement does not require an elaborate building editor. The transition from an initial 'just appears' idea to contribution-based completion is preserved here. Rules for replacing important outskirts objects or terrain remain to be specified.


Source: [answer 167](../../Morkahja-Concept-Sources.md#turn-8c09ecf3-d31a-4d03-aa08-6039c4621965), [answer 168](../../Morkahja-Concept-Sources.md#turn-ca780595-fc2b-4035-9a14-79d8922ce656).

## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.


<details>
<summary>Original detail and examples — answer 161</summary>

> I can in general only do. Okay, I can in general do all the tasks that are, that there is in the community, all the needs the community has. Everyone can do that. But of course, the ones with the traits are much more efficient. So if a hunter that actually has the role of a hunter, so he has several traits that are good for hunting. If a hunter goes out and brings back a deer, the deer is much more. It's bigger. Okay. If a hunter, if someone goes hunting that doesn't know how to hunt, then it will be small and it will be little. But yeah, so I shouldn't override it and pull almost everyone, anyone in. I should in general see everyone and then favor and prioritize to give tasks to the right roles and the traits. But if there is none available and it's urgent, then I should give it to everyone, of course. Then they might give it to several people. Yeah. But I also want to say one thing, that we're not gonna go into the negative. So we're not gonna die from not having enough food. Very important. We're not gonna grow up our kids when we don't have enough food. That is important. But everyone will survive if we don't have enough food. So there will be no starving. There will be no misery. Okay. The village works well in its basic form. They have everything they need. But what we are working on in the community is to improve. Okay? To not optimize, but improve. So we want to have it a little bit better. We want, of course, we want to have a little bit more people with us. We want maybe we as a village in the culture, we want to grow. We want to strive. So everything that we work on is to give that little extra, to give extra joy, to give extra security, to make life something that is not just surviving. Because surviving we do. We do survive. That's not a question. We're not gonna not hunger or whatever. When I eat something, it's a grimnir. I know that I just give me a temporary buff. A little bit like the food buff in World of Warcraft. I eat a special food, I get a buff for a time because I'm fed. I'm well fed. If I don't eat that, I still gonna survive. Because in the world there is everything that I need. I can survive on just extracting the minerals from the ground pretty much and just soaking in the rainwater. So in general, we are fine, and we have enough food in the community to feed everyone. Everything that we do with the tasks is to reach a higher level of taking care of each other, to actually make each other more happy, to make each other more satisfied, to not only cover the bare minimum, but make it a cultural, to have food for celebrations, to have herbs for ritual. We need a little extra if we want to do that. We need a little more than just what we need for our consumption. And that's where the activities of the community in this game come from. Not from urgent survival needs, but from it's urgent because we want to have this celebration, this ritual in the future. We want to prepare that we have enough food for the next baby that is crying, that we have enough housing, enough materials for houses, so we can accommodate a new member of the community. So that's, yeah, it's a distinction there. Do we have? Yes, we always have enough. We always have the basics. We are working on the little extra on top.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-b69557d1-1bf7-4566-bfc3-c923c6d872b3)

</details>


<details>
<summary>Original detail and examples — answer 162</summary>

> So I think it should just. Okay, I think the AI should participate by doing some village-related tasks, like collecting firewood. But I think the big steps and the growth that you're talking of, the big steps should come from the players. Like only the players should decide to reproduce. Okay? The village itself should not do that. That should be a player effort, because it's a player experience. And the same goes for the destiny quests. The AI should not go for those. The player should, because it's a player experience, with all the divine guidance and stuff like this, and the seeing places, and this is for the players, right? The AI should just bring a little bit of life into characters that are not occupied right now, from children to the grown-ups, and the half-grown-ups when they are not controlled right now. They should still move around and do the basic tasks. They can just do the basic tasks. It doesn't matter, just so they have something to do, and it's not weird that they stand around or something. Okay? But in that regard they don't play a very important part. They just play the part where they should, yeah. They should just be active, seem active, seem like they do something meaningful. And then at the same time, of course, when they collect something outside the village and they come back, they might be a quest objective, because they have a certain item or a certain knowledge that they have inside them. So a player could approach them, interact with them, and do it like... And that is important. If I interact with your character and say exchange knowledge, then your character has to accept this, of course, because it is a little ritual that takes some time. I imagine, like, the green magic coming from one hand to another, like connecting them in a magical way. But I'm not sure. I'm not sure yet how the Khudimni do that. Probably with a lot of vibration, rhythm. Maybe they do a little stomping dance thing that establishes a telepathic connection between the two. Or they energize sand. They then make float to each other, so they connect in a very physical way, but through sand that is vibrating, that is floating in the vibration of the air between the two, and actually exchange the matter that holds the memory. Because that's the thing with the Khudimni, that they hold memory inside the matter, inside the stones, inside the crystals. But yeah, basic stuff. They do basic stuff. And the players choose to push it in a direction: grow the population, grow the knowledge, grow the materials, the stash, fill the stash, things like that. Yeah.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-11a3c22d-afb3-4307-957b-e73d6f808906)

</details>


<details>
<summary>Original detail and examples — answer 163</summary>

> They're just gonna, not occupied with doing something else. What do you mean? Silly question. No, of course they're gonna pause whatever they're occupied with, and they're gonna help the player, like they would help any other community member. So yeah, as long as they have the capability, as long as they have the traits or the shards or the items that the player needs, they're gonna help the player to fulfill their needs. They might ask something in return when it's a trading situation. But yeah. And by asking something in return, I think we should think broad. We shouldn't trade item for item, but it can also be an item for a hug, depending on how the compatibility between the people is, how the trust level is. What do we have? Acquainted, sympathetic, and trusting, right? So depending on that, we can say, okay, they actually exchange this item also for just a hug, or a kiss, or whatever else they desire or need and we might have to give.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-a92dcfd6-cd0d-4df4-bff6-0e4071d78a88)

</details>


<details>
<summary>Original detail and examples — answer 167</summary>

> And that is also a technical question, right? I would like it to be possible to grow indefinitely, to just grow and grow and grow, to just house more and more people. We will have to, of course, see how the logistic work there, but I think Realm Node can manage to distribute the tasks indefinitely. So in general, I would like it to be able to grow and grow and grow. And maybe the settlement itself doesn't only grow horizontal, but also they just build higher houses, and maybe then they will have floating houses on top. But first, I think we make it grow horizontal. Just add another house in the outskirts, boom. Add another house, add another house, another house. And also we use hexagons: boom, house. Boom, crafting node, whatever is needed for. Maybe if someone gets a role, a crafting role, they need a workplace. It will just be placed somewhere. Boom, they have a workplace. Nothing too fancy and complicated. Just provide all the tools for the different roles in a simple way. Maybe they get the workplace inside their house. Maybe the house that they live in also houses the workplace of their role. I think that's the best thing, actually. And that's also very much like a tribe, little house. Everyone is doing their profession at their home place. That's very primal. Yeah, but I would like the community to grow. And it's only about if I want to reproduce, I need to bring these and these ingredients, materials. That's the need for this. So if I have a partner that I unlock the interaction with, that is depending on the traits and desires that each other have and the trust level, then there is an interaction that, boom, recreation, boom, this starts a quest. It should start a quest with different needs, different objectives. And then these different objectives, we put them all, we achieve them all, fulfill all the needs. Then we can make this baby, create the ritual where we actually put it into our crypt, into our nesting place, into this little stone basin where it can grow. And then we bring it more and more, like more material and more things, knowledge and whatever, to give it, give to it. But yeah, so my house is added. The new house is added in the outskirts and replacing whatever is there before. So that we can expand the village indefinitely, can just expand, expand, expand.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-8c09ecf3-d31a-4d03-aa08-6039c4621965)

</details>


<details>
<summary>Original detail and examples — answer 168</summary>

> That's an interesting question, building. I think, I think this for now, it just automatically builds. It just comes to be. We will see how it is, what we need for the different roles to fulfill. For example, the stone shaper probably needs something to do, right? They probably need something to make, something to create, and they usually are the ones that are creating accommodations, I guess. So either they just create parts that are necessary for the building, or they are actually actively working on the building itself. Maybe they create a part and then they bring it to the building, and they see a little bit of progress on the building, so that they feel satisfied. It satisfies their desire to contribute, their desire to build. And if they do it a few times, or if a few of them do it, then the new building is there. So it could be like a work in progress, like a construction site. And then the people have to bring the different parts to it to then make it an actual place.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-ca780595-fc2b-4035-9a14-79d8922ce656)

</details>
