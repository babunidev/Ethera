# One entity framework and authored content

**Current concept through answer 251 · updated 2026-09-13.**


## One entity framework and authored content

Characters, bears, spears, trees, boulders, houses, shrines, Memory Stones and dropped objects share a technical entity framework. Identity, Traits, state, position and interactions are common concepts; optional components hold body parts, inventory, Needs, Shards, relationships, AI and other relevant data. Separate content definitions and spawn/reward pools keep creature abilities, playable-person qualities, item properties and building properties appropriate. Two spawned bears can draw different authored Trait combinations and therefore different attacks, defenses and behaviors.

Traits use one flat matching system. Identity tags (Grimnir, Humanoid, Earth Elemental, Individual), capability tags, preferences and target properties (Climbable, Opponent/Attackable) use the same evaluator. Categories can organize authoring and random selection without becoming special matching logic. Separate permitted pools remain necessary even though the matcher is generic.

All interactions share requirements, a Trait-defined target, a manually authored player skill phase, and authored results. Results may injure a body part, copy a Shard, change relationship/state, create or transform an item, or fulfill a Need. Requirements may concern actor, target, carried item, environment, body, knowledge, relationship and lasting shared facts.

Within one complete requirement group, required conditions combine with AND. Complete alternative groups combine with OR. Any one satisfied group unlocks the interaction; two matching groups do not double its strength.

Examples: Likes Kind on actor + Kind on target enables a greeting. Climbable on a boulder plus the actor's climbing capability and usable body permits climbing. Mountain Strike can require a Grimnir, a qualifying attack Trait, a healthy arm and a valid opponent. Warrior/Furious alternatives were recipe illustrations, not an approved universal combatant/anger system. A role title called Warrior supplies no capability by itself; an explicitly authored Trait would.

The game selects, assembles and instantiates hand-authored content. It does not use runtime AI/LLMs to invent new interactions, Traits, Needs or story verbs. Procedural work distributes authored creatures/items/locations and composes appropriate quest steps. AI-assisted development/content creation is permitted; an admin authoring tool is an envisaged workflow, not an already chosen product or implementation.

Each Need definition includes an author-controlled important/highlight setting. Authors tune it after playtesting; the runtime does not invent urgency judgments. Begin with Needs supporting the chosen twelve interactions and injury/recovery, then expand.

Source: [answer 216](../../Morkahja-Concept-Sources.md#turn-76e802b1-4f62-484a-be2d-14841d5f8fd5), [answer 235](../../Morkahja-Concept-Sources.md#turn-40edeb55-41ba-4769-948a-1d23fbb0a165), [answer 236](../../Morkahja-Concept-Sources.md#turn-91d60c66-de1f-46ef-9996-aa246a46973c), [answer 237](../../Morkahja-Concept-Sources.md#turn-586fbd55-ba94-458e-ad78-09ceddef5758), [answer 238](../../Morkahja-Concept-Sources.md#turn-c2b28c15-4156-44bf-8f67-b593ec19c209), [answer 240](../../Morkahja-Concept-Sources.md#turn-21206fec-5c51-455d-9925-95cc0669ba29).


## Cache interaction matches and invalidate lazily

Compare relevant entity data on the first encounter/focus and remember matching interactions for that pair. On later focus, check what changed before reusing the result. Relevant changes include Traits, inventory, Needs, Shards, states/injuries and relationships.

Use fine-grained invisible change flags or versions for those categories. Changes invalidate affected cached results for observers; do not eagerly recalculate every pair across the world. On actual focus/request, re-evaluate the relevant requirements. The player sees contextual actions, not flags or internal categories.

Implementation must also account for changing environment/context and interaction definitions where those affect requirements. Version representation, cache lifetime, multiplayer authority and revalidation at action commitment remain implementation choices. These are engineering implications of reliable matching, not additional user-selected mechanics. Invalidating knowledge-dependent matches is not permission to reveal or copy hidden Shards to other players.

Source: [answer 241](../../Morkahja-Concept-Sources.md#turn-341e9a20-80c3-4edc-ada7-f273c333deca), [answer 242](../../Morkahja-Concept-Sources.md#turn-66e54ed8-91f7-4228-a8d5-87d2d3da11b6), [answer 243](../../Morkahja-Concept-Sources.md#turn-3b9565b5-789d-456d-bb26-5b3b4e84cb9d).


<details>
<summary>Original detail and examples — answer 216</summary>

> The interactions will be definitely hand-authored. Because they're gonna have animation. They're gonna have, you know, they're gonna be something. They're gonna be the soul of the game, the interactions. Yeah, pretty much the soul of the game, right? So they need to be hand-authored. So we go step by step introducing basic interactions, and then go step by step in all the actions: social, aid. And I think I put crafting into aid as well, right? Crafting is a little bit like aid. Social aid, trickery, and, well, crafting can be trickery as well. Can be a little bit everywhere maybe. Maybe crafting is something that everyone does, like Warcraft. Weapon crafting is more in combat, and then tool crafting is more in trickery. And then what do we have in aid? We have maybe something like medicine crafting, and then in social we have maybe something like cooking. That's a social craft, right? Which is social: cooking and brewing and stuff. It's super social. Yeah, something like that. But yeah, this is gonna be introduced step by step. No generated interactions. No. I don't think so. Or, I mean, I really don't think so. What could be a procedurally generated new interaction? No, that would mean we would have to introduce, like something like AI inside the game. I don't want to do that. I want it to be a simple simulation. And I'm gonna work with AI on this one, of course. Like seeing, like, hey, we need another interaction for the social sector. We have this dataset now, and then so it gets balanced and good, and, and, and. Yeah. No. No procedurally generated new interactions and combinations. It's a little bit silly. There's no procedurally generated traits or no generated needs and stuff. It's only the... What is generated is the locations for where the things are put geographically. Like, what's generated is, like, a randomized geographical extension. What's generated is which creature or which content is inside the node, and so on. That is. So we're gonna have a big set of content for the content generator to distribute in the world. Okay.

Source: [answer 216](../../Morkahja-Concept-Sources.md#turn-76e802b1-4f62-484a-be2d-14841d5f8fd5).

</details>


<details>
<summary>Original detail and examples — answer 235</summary>

> Each need will, of course, be handmade. Yes. We might want to start with some needs fitting to the interactions that we have, so that we can initiate interactions, or that we can actually initiate adventures. So far, then also, since we can already be attacked and attack, we probably also need the injury. But that is a setting on the need itself that we should be able to change stuff. So we don't need to go too much into that now. We can have needs, and then if we notice, ah, this should be a prioritized need, or a need that the player should be knowing about and pay attention to, then we can change that. Right now we don't really need to. It doesn't need—the game doesn't need to decide that. The content manager, the content creation will fix that and decide that this is important. And that also needs some game testing and stuff. So it is. You seem to be out of questions that are actually important about the project. Can you go a little bit more into the technical side of things? Or do we not have any questions there? I mean, this is quite technical, all of it actually. You can just continue like you do. But you could also get some clarity in how we want to build this thing.

Source: [answer 235](../../Morkahja-Concept-Sources.md#turn-40edeb55-41ba-4769-948a-1d23fbb0a165).

</details>


<details>
<summary>Original detail and examples — answer 236</summary>

> I do like the idea of doing that, that the bear has traits as well and stuff. We just gonna separate creature traits and stuff with player traits, so we don't get the bear traits as a player. But yeah, every creature when it's created should have different traits as well because some should have... not all creatures should have the same. Creatures should not always have the same combat abilities or abilities in general when they're being spawned or when they're being created. They can randomize that as well. So in a way I imagine separate content for characters, creatures, items, buildings, world objects, but the same technical system, I think, is fine, is nice because then we just, we can just work with these pairs. Okay, this and this and this and this. I think it's...

Source: [answer 236](../../Morkahja-Concept-Sources.md#turn-91d60c66-de1f-46ef-9996-aa246a46973c).

</details>


<details>
<summary>Original detail and examples — answer 237</summary>

> You forget the interactions themselves. They are always based on a trait, a desire, or need, or solution slash shard pair. So it will... the interaction would be Mountain Strike, for example. It would mean I have the trait Mountain Strike. The creature has the trait opponent that unlocks the Mountain Strike. If I have a spear strike or whatever, or spear attack, then my attack, my spear attack, plus the spear, plus the attackable target trait, plus... so the requirements. Okay, that is the requirements, yes. Target type. Target type that is specified by traits. The type of a person itself is specified by traits. The Grimnir, for example, has the trait, an underlying general trait of Grimnir, and he also has the trait, underlying general trait of humanoid, maybe, then of earth elemental, then of Individuum, then of... so, and all these things will then be... So these traits plus the ones that they get from their parents and the ones that they get when they use. So there's a lot of room to combine traits, like a Grimnir plus a combatant or warrior trait enables, is a requirement for Mountain Strike, for example. People who do not have the warrior trait cannot use Mountain Strike, or there are different requirements for Mountain Strike, for example. It can be Grimnir and angry, or furious, maybe. That unlocks the Mountain Strike. So one interaction can have several requirements, but they should all work in the same way, yes. So they should, like I say, a target type would also... yeah. But player skill phase, that is also, that is designed by... that is in the interaction itself. So we say, for example, for Mountain Strike it will be this. This player skill phase, and for climbing it will be a different player skill phase. What do you mean with result state changes? Result... yeah, okay, that is state changes, yeah, like getting injured or... yeah, okay. So yeah, actually, yes. Exactly. So the interaction itself is pretty much the same thing, yeah. It has a requirement, it has a target type that is made by the traits. The rock, the boulder can have a trait climbable, for example, and then the climbing interaction can be used there or is unlocked there. A player skill phase is always connected to the interaction itself, and we authored that manually, and result changes also is also... we choose that, right? Injury and so on and so on. So yeah.

Source: [answer 237](../../Morkahja-Concept-Sources.md#turn-586fbd55-ba94-458e-ad78-09ceddef5758).

</details>


<details>
<summary>Original detail and examples — answer 241</summary>

> Well, it's good. The first time I meet them, it could check. The second time I meet them, it could check if there is something changed.

Source: [answer 241](../../Morkahja-Concept-Sources.md#turn-341e9a20-80c3-4edc-ada7-f273c333deca).

</details>


<details>
<summary>Original detail and examples — answer 242</summary>

> Yeah, think that's a good idea. Yeah, that's good. I thought the same thing, like when I make a change in my character, that my character gets flagged for everyone. And so everyone who already has my character updates a little bit of the whole thing. Yeah, that's good.

Source: [answer 242](../../Morkahja-Concept-Sources.md#turn-66e54ed8-91f7-4228-a8d5-87d2d3da11b6).

</details>


<details>
<summary>Original detail and examples — answer 243</summary>

> Yeah, it can have different flags. You're right. So each, yeah, it category pretty much everything that's important for the... This is only happening when I actually click on them, right? So let's, yeah, give them little flags, invisible flags, like you said, like inventory, change, trades, and so on and so on. Of course, makes sense. Do what makes sense.

Source: [answer 243](../../Morkahja-Concept-Sources.md#turn-3b9565b5-789d-456d-bb26-5b3b4e84cb9d).

</details>
