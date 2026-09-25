# Combat and Injuries

If defeat leads to Atranor, its capability-matched player challenge is terminal: success restores the person safely with possessions; failure dissolves them. This is an exception to ordinary retry rules. See [Atranor](../01_World/Atranor_Death_and_Dissolution.md).

**Current concept through answer 251 · updated 2026-09-13.**

Consolidated concept material, with current rules and unresolved details distinguished.

## Combat

### Meaningful timed interactions

Combat uses the same interaction philosophy as the rest of the game. The player reads an encounter and chooses a fitting action at the right moment. The intended experience is not repeated damage trading until a generic health bar reaches zero.

### Engagement and movement

Lock onto an opponent. While engaged, the game handles facing and most positioning so combatants remain naturally oriented toward each other. The player responds to attacks and openings rather than manually circling or continuously repositioning.

To move independently or flee, disengage and break the lock. This refines the earlier direct-control direction: movement remains direct outside engagement, while combat manages spatial presentation.

### State and response

Against a bear, a perceived attack opens responses such as a dodge or parry if available. A successful response can create an opportunity to attack. Traits, preferences,  equipment, current injuries, and the situation affect the available actions. Recklessness can support an aggressive action that risks injury.

An attack can injure a limb and restrict related actions. The first version uses broad injury states rather than detailed wound simulation. There is no HP/damage layer: a successful unblocked attack injures its selected body part; a failed attack causes no injury.

### Defeat remains interactive

When too injured to fight normally, new situation-specific survival interactions open. Fleeing, surrender, capture, help, and other outcomes can continue the story. Enemies and AI creatures follow the same state-dependent rules.

### Baseline and open details

Everyone has ordinary baseline actions; a trait is not required for every attempt. Personal and elemental qualities modify that foundation.

Multiple opponents, timing windows, action presentation, equipment effects, group targeting, accessibility, healing, and final-death transitions remain open. The selected rhythm is live alternating exchanges: attacker acts, opponent responds/acts, then back again. It is not unrestricted action spam; multi-combatant scheduling remains open.

See [Injuries](#injuries), [Baseline Actions](../03_Characters/Roles_and_Baseline_Abilities.md), and [Interaction System](Interactions_Discovery_and_Player_Skill.md).

### Skill and recovery

Equipment compatibility opens actions rather than adding hidden success/failure percentages. Execution depends on player skill; individual interactions may test more than timing. Injury remains a functional restriction, and failure creates recoverable Needs rather than permanently closing a quest route. Exact connections to Atranor remain open.

## Injuries

### Initial scope

Use broad, functional injury states. Arm Injured and Leg Injured are explicit examples. Detailed named wounds and a medical simulation are deferred. Answer 222 explicitly adds head and torso consequences alongside limbs; exact per-creature anatomy remains authored content.

Injuries change available interactions. An injured limb can restrict relevant attacks, movement, carrying, or other actions. Exact restrictions are not yet enumerated. Losing an action temporarily through injury does not erase a permanent character trait.

### Too injured to fight

At a threshold where normal fighting is no longer possible, the encounter changes interaction set rather than simply ending in a death screen. Situation-specific survival actions become available.

Accepted possible actions include crawling away, surrender, calling for help, reaching safety, protecting someone, submitting to capture, playing dead, or a desperate final action. They are context-dependent possibilities, not actions guaranteed in every encounter. Calling for help remains an in-world action, not player voice or text chat.

### Symmetry

Computer-controlled creatures and enemies use the same state-dependent interaction principle. Their injuries and inability to continue can also enable fleeing, capture, being spared, or other nonlethal outcomes.

### Still open

Injury accumulation, thresholds, healing time, recovery interactions, elemental anatomy, and the connection to essence exhaustion and Atranor remain unspecified. Combat incapacity must not be silently equated with final death.

See [Combat](#combat) and [Death and Dissolution](../01_World/Atranor_Death_and_Dissolution.md).

### Recoverable consequences

An injury can generate a treatment Need. Failure must leave a recoverable route; solution search/generation can wait for fountain consultation. This does not yet specify medical procedures or override Atranor's ultimate judgment. Detailed injury taxonomy remains deferred.

## Example E47: Face the bear and respond

*Illustrative example from the discussion.*

Lock onto the bear and let the game manage facing and positioning. Read its attack, dodge or parry at an appropriate moment, then use an opening. A strike to a limb can prevent a related attack. Break the lock to move away rather than circle-strafing continuously.

Conversation: [turn 63](../../Morkahja-Concept-Sources.md#turn-f76bbdcc-6784-4768-8177-8f834903d85c).

## Example E48: A reckless choice can cost an injury

*Illustrative example from the discussion.*

A reckless person may have an aggressive action that accepts injury risk. Arm Injured or Leg Injured then restricts relevant actions. Broad functional states are the first version; detailed cuts, fractures, and other medical labels remain deferred.

Conversation: [turn 63](../../Morkahja-Concept-Sources.md#turn-f76bbdcc-6784-4768-8177-8f834903d85c), [turn 64](../../Morkahja-Concept-Sources.md#turn-5af3c86e-dd56-45db-92a6-588a44c0eeb9).

## Example E49: Losing the fight need not end the scene

*Assistant-proposed possibilities accepted as contextual options.*

Possible survival actions include crawling away, surrendering, calling for help, protecting someone, reaching safety, capture, playing dead, or a desperate action. They depend on the situation. AI creatures and enemies also have changing state and nonlethal possibilities.

Conversation: [turn 65](../../Morkahja-Concept-Sources.md#turn-96daba95-6cd6-46d8-adad-b752e28eed0f), [turn 66](../../Morkahja-Concept-Sources.md#turn-fba32c20-ac98-4234-86d7-313bcf3eea22).




## Deliberate focus and condition-based retries

Refer to [Interaction controls](Interactions_Discovery_and_Player_Skill.md): hover alone does not slow movement; holding left click opens focus and current radial actions. Automatic approach/facing supports the skill phase; Mountain Strike specifically starts its targeting/timing display during approach. The discussion favors slower participant pacing for action selection and a possible closing-ring response cue, not a shared world-time bubble. How this affects another player, incoming attacks, or multiple opponents remains open.

If a failed fight or climb leaves an interaction possible, retry immediately; injury or changed conditions may remove it. Exhaustion can similarly block demanding physical or mental interactions. It does not automatically remove every action. Use “opponent” rather than assuming every encounter is an enemy.

Source: [answer 127](../../Morkahja-Concept-Sources.md#turn-60d7d431-e018-468c-99e8-d4fe6e1dde97), [answer 128](../../Morkahja-Concept-Sources.md#turn-8739848d-292a-4453-a66d-8630792a6159), [answer 132](../../Morkahja-Concept-Sources.md#turn-166ae15f-604f-4b6b-ba5c-a9a94ee6b891), [answer 133](../../Morkahja-Concept-Sources.md#turn-ae7d146b-dd5b-4b80-8c56-c36d3f815448).


## Mountain Strike: chosen body part and live exchange

Attack availability needs an appropriate reason/context (a Need, resource/knowledge/task objective or relevant authored preference/circumstance), a valid opponent and capability. The user floated hateful/vengeful Traits as future examples, not an adopted hostility system. Foundational identity alone is not unlimited permission to attack everything.

Hold left mouse on the creature. The character and target slow for focus and the available interactions emerge from the target. Select Mountain Strike; the character rapidly closes into combat range. The small cursor-adjacent QTE begins while approaching. An abstract body diagram shows head, torso and limbs appropriate to that creature, using connected circles/lines; a four-legged target gets an appropriately shaped diagram. Choose a body part and click at the right moment to strike. Not clicking wastes the action/round and does not perform the attack. Missing the timing also wastes it.

Answer 223 replaces answer 222's random hit location with player-selected anatomy. All body parts are equally difficult to hit by default. Different defenses and protection, rather than a smaller head timing window, change the result. Closing rings, converging fists or a moving timing marker are visual proposals, not a final QTE graphic.

If the attack succeeds and is not defended, injure the selected part. There is no numerical HP damage. Failure produces no injury. The attacker needs a usable arm for Mountain Strike. Actions relying on an injured limb become unavailable without deleting the underlying Trait. A bear might still claw with its other functional claw if its authored attack permits that.

User consequence examples: head hit can knock out; injured leg removes running/escape that depends on it; torso hit stuns/paralyzes for the next round, preventing its attack or escape; claw/arm injury blocks dependent attacks. These require per-creature recipes and are not an automatic rule that every head hit kills.

Combat is a live alternating exchange, compared loosely to Neverwinter Nights. The opponent can use an available defensive reaction and then takes its own action. Automatic facing/positioning remains; independent movement/fleeing requires disengagement. Exact overlap of attack and defense QTEs, AI decision timing, group combat and network pacing remain unresolved.

Source: [answer 220](../../Morkahja-Concept-Sources.md#turn-90466a4e-be55-4903-b1b0-d42561a0b16d), [answer 222](../../Morkahja-Concept-Sources.md#turn-45fde0c8-8824-494b-81e5-6f38d9242f90), [answer 223](../../Morkahja-Concept-Sources.md#turn-01f1ada6-ccdb-40f8-b5a2-bf19bba52434), [answer 224](../../Morkahja-Concept-Sources.md#turn-20ee5e9f-3662-472c-9f2b-b439fa6162c6).


## Defense, attack reading and protection proposals

Stoneborn Resilience focuses reinforcement on a body region. Correctly protecting the attacked region can absorb/block the attack; choosing another region leaves the targeted area exposed. Defense also has a player execution challenge. Without a separate attack-reading Trait, the target location is not automatically disclosed: read the animation or choose a region. A learned attack-reading Trait can reveal the targeted body part. This is separate from the ability to defend and is obtained through the current Destiny reward route, not automatically inherited as universal knowledge.

Answer 224 explores avoiding endless blocking: creature-specific protected areas; inability to protect the same area on successive rounds; a sturdy body absorbing one attack before vulnerability; armor permitting one/two/three protections before an injury; a shield covering torso/arms and a helmet protecting the head. These are alternatives and scaling examples, not one finalized cooldown, charge or armor-durability rule. Exact recovery/reset behavior remains open. They do not introduce numerical HP or erase the established Okay/Broken item model.

Incapacity can still lead to crawling, surrender, help, capture, being spared or a desperate action where authored context permits. It is not automatically dissolution. If the story reaches Atranor, its skill challenge and terminal failure rule still apply. Treatment Needs now use the deferred fountain resolution lifecycle.

Source: [answer 224](../../Morkahja-Concept-Sources.md#turn-20ee5e9f-3662-472c-9f2b-b439fa6162c6), [answer 225](../../Morkahja-Concept-Sources.md#turn-e7529f73-e584-496d-8016-c93c266e7e75), [answer 226](../../Morkahja-Concept-Sources.md#turn-7daa74a0-4884-47b0-87e3-abfa2d650db5).

## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.


<details>
<summary>Original detail and examples — answer 222</summary>

> When the player performs it, so I see this creature. I interact with it by holding my mouse, left mouse. Time slows, or actually my character and the target slows, and I get the interactions wheel. The available interactions pop out of the target. I choose Mountain Strike. My character moves quickly. It's a combat scenario, right? We are starting combat here. Moves quickly to the target and attacks. If the target can, it might have something like a reaction that reacts to an attack. Something like a dodge. If it can, then it does that. But let's say it cannot. It might be a bear, for example. They don't really dodge, do they? Boom. We hit the bear. The bear has limbs like we, like body parts. The bear has body parts. A random body part is chosen and injured by the attack. The player gets a quick time. A random body part is chosen. The player gets a quick time event, has to click at the right moment. There's maybe some... maybe a fist meets another fist, and they have to click when it meets, or something like that. Or they have to click before it meets. So that's a little UI. It's a little UI element. Small, and like around the mouse pointer, cursor. When it's successful, the aimed body part gets injured. The creature cannot use that body part anymore. Every attack that it has, or actions that it has that needs this body part, will be out of function. And it's also important that our body part is part of the need for this. Yeah, so we need the capability to attack with a certain body part. So that in this case, it would be one of our arms needs to be healthy to do this Mountain Strike, right? Boom. We injured the bear. It might be the claw. It cannot use its claw attack anymore, or maybe it can use the claw attack with one claw as well, so then it can still use a claw attack. But at least we injured it. If we hit the head, maybe they're just immediately knocked out, and so on. If we hit the leg, with the leg they cannot run away. If we hit the torso, they are stunned. They are paralyzed for the next round, so they cannot run or they cannot attack themselves. Okay? The whole thing, I mean, it looks like the whole thing is round-based, because we don't want this. But it's live rounds. It's a little bit, maybe a little bit like a Neverwinter Nights, but we are actually taking turns after another. So I attack and they attack. I attack and they attack, and so on. Yeah, so and if they attack, I can, if I have a dodge, for example, or a defensive interaction, I can brace myself with Stoneborn Resilience if I hit. So I activate it when I get attacked. If I get the quick time event right, boom, I block the attack, or I mitigate the attack. There's no damage or anything. It's just: is the attack successful? A body part gets injured. Is the attack unsuccessful? Nothing happens. Okay? So yeah, so did I describe it sufficiently?

Source: [answer 222](../../Morkahja-Concept-Sources.md#turn-45fde0c8-8824-494b-81e5-6f38d9242f90).

</details>


<details>
<summary>Original detail and examples — answer 223</summary>

> Yeah, I know what you mean. I like it. I think we do this, the quick time event for these attacks. Show the body parts. And it is pretty much like a circle in the middle, and a line to another circle. That is one body part, and then the more body parts they have, I can choose one of them. The quick time event will have kind of the shape of a four-legged creature, for example. And if I choose the right leg, for example, then I get the... then I try to hit the leg. So all this happens after choosing. So you click on mount and strike, boom. The quick time event starts while my character moves to the target and attacks, or moves to the target. When I click, it attacks. When I don't click, it doesn't. I waste my round. And yeah, then I need to click in the right moment, I guess. How do quick time events work? It's like something is moving somewhere, something is moving somewhere, and then I have to click in the right moment, right?

Source: [answer 223](../../Morkahja-Concept-Sources.md#turn-01f1ada6-ccdb-40f8-b5a2-bf19bba52434).

</details>


<details>
<summary>Original detail and examples — answer 224</summary>

> I already thought about that one. So the thing is that we will have creatures with a small head, for example. Hopefully creatures in general would protect the head a little bit more than other body parts, right? So there will be a defensive reaction that the creature can use to protect the head. Okay? Now we gotta limitate all this a little bit, because if we have it now that I attack the head and they can protect the head, we can go just there and back and there and back. I use my defensive ability, they use their defensive ability all the time, all the time. When I hit them, they resist my attack, right? So either we limit creatures to only have maybe random. Maybe some creatures can protect the head, some can protect their feet, some can protect their torso, so that the player sometimes fails with their attack, or I mean the creatures sometimes succeed with their attack. But it should not be so. That is one thing. Otherwise we could say that a defensive ability can only be used one time for the same area. So if I protect my head in this turn, it cannot be two times in a row used for the same area. So I use, I protect my head, then I cannot protect my head next round. That goes mostly for creatures. What does it go for? If it would go for myself, for my player character, then the question is: how do I know which body part to protect? Do I know that, or do I have to guess? And then also do I have abilities that are a little bit broader? Maybe if I, for example, have a shield, I protect several body parts, like torso, arms, and, yeah, torso and arms. If I have a helmet, I protect my head. If I have legs, I protect my legs from immediate attacks, but I can only do that one time, or it always only is one time, and the next round they can be injured somehow, right? If you take a leg two times, even if there’s armor on it, it probably is gonna hurt and get injured at some point. So we say there are the options, like when I have a lot of armor, for example, or have extra defense on my leg, maybe I can protect it two times and then only after two times it doesn’t work. If I have just a little armor on my leg, it works that I protect it one time and then next time I get injured. If I have more armor, maybe I can protect it three times and only on the fourth time I get injured. So like this is interesting for later when we want to be more resilient and increase the resilience in fights. But in the beginning I think it’s good to just say, okay, I have a sturdy hard body. I can absorb one attack, and then after that one attack I have to take one attack to whatever body part the opponent is attacking. Then also: can I choose the body part in my reaction, and do I have an indicator what body part is attacked? Yes, maybe. That could also be two different skills. One skill, maybe like a basic beginner defense, is to just try my luck and try to dodge, for example, or try to just take it, and if I focus on the right body part with this— what did we call it? —with this stoneborn resilience? If I focus on, I’m like hardening part of my body. If I focus on the right part, for example we can say if we focus on the head, arms, torso, or legs, then I will absorb the damage. Yeah, so yeah. Difficult to hit. So yes, they’re all equally difficult to hit, but it always depends on what defense ability the target has and if it can react to my attack. If I attack the head, it can react to my attack on the head.

Source: [answer 224](../../Morkahja-Concept-Sources.md#turn-20ee5e9f-3662-472c-9f2b-b439fa6162c6).

</details>


<details>
<summary>Original detail and examples — answer 225</summary>

> So this could be a trait. Should be a skill that I can learn or unlock, or already know. Because this is perfect, because, yeah, you understand? The ability to identify the reaction, to identify what of my body parts is targeted should depend on the skills and the, yeah, should on the skill that I have. So I don't have that inherited. I have that if I have unlocked it, or if I trained it, or if I have somehow learned this trait to be able to, yeah, to be able to identify where the target is targeting me. Because that gives me a very good... Oh, that is not good. Aha. Wait, so wait for this. Ah, yeah, yeah. I think I said what I wanted to say, but did it make sense?

Source: [answer 225](../../Morkahja-Concept-Sources.md#turn-e7529f73-e584-496d-8016-c93c266e7e75).

</details>


<details>
<summary>Original detail and examples — answer 226</summary>

> So I say that again because it didn't work. The traits can be learned, for example in the combat quest destiny chain. So that is the main way to learn traits, like we said before. And in the future maybe there will be things like that I can find someone that I can learn a trait from somewhere out there, adventuring or something like that. But for now all traits are learned randomly by doing these quests. So I do a combat quest and I might learn a trait, or I do a destiny and I might actually get several traits and one of them might be this one.

Source: [answer 226](../../Morkahja-Concept-Sources.md#turn-7daa74a0-4884-47b0-87e3-abfa2d650db5).

</details>
