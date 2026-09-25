# Items Equipment and Carrying

**Current concept through answer 251 · updated 2026-09-13.**

The physical life of items: persistence, possession, clothing, visible carrying, and direct equipping.

## Objects and Persistence

Objects exist in the world independently of quest acceptance. A bear has its claw before someone needs it. Loot is not withheld simply because a relevant quest is inactive.

### Persistent history

If a bear dies, its existing claw may be taken, sold, lost, or carried elsewhere. A later seeker follows that object's history rather than receiving a replacement bear. If the seeker already possesses a suitable claw, the requirement can already be satisfied.

Completing an objective does not automatically delete the object. It remains available for later uses and stories. Consumption and physical change are exceptions: food can be eaten, and materials can be used or transformed.

### Community knowledge

A character can keep an object while reporting that they have it. Others can then discover who possesses what they need. This separates the physical object from knowledge about it.

### World continuity

Locations become available for new content when their prior use genuinely ends. Existing objects and remains should not disappear merely because a quest completed.

Taking items and binary repairable equipment are specified below. Exact interchangeability, storage, consumption, and decomposition remain implementation questions.

Items and places can carry traits sought by preference Traits. Knowledge of an item's changing owner travels in Shards; collective consultation can redirect a Need to its known holder. Obtaining it through trade requires a reciprocal match, or generates a new exchange objective. Persistent geography remains when replaceable content slots change. See [Trade and Exchange](Trade_and_Exchange.md) and [World Nodes](../01_World/World_Nodes_and_Generation.md).

### Physical carrying and craft

Objects must be physically carried and visibly affect the loadout; bags contain small objects and large items occupy space on the person. Picking up a weapon equips it without a separate inventory operation. Clothing is rare, materially crafted, and can break.

Materials/tools and flat applicable crafting traits deterministically shape output traits. More qualities mean broader compatibility, not universal higher-level gear. See [Equipment and Carrying](#equipment-and-carrying) and [Crafting](Crafting_and_Item_Traits.md).

## Equipment and Carrying

### A physical loadout

Carried objects must have a believable place on the body. Bags hold small objects; weapons and tools are carried or worn; large objects occupy physical carrying capacity. There is no invisible inventory for hoarding large quantities.

The loadout changes visible appearance. Bags, weapons, bundles, and large carried objects should be readable on the character. Items inside a bag need not each be separately exposed; the carrying arrangement must remain credible.

Capacity limits what is worth bringing home and can create reasons for cooperation. The hunter carrying meat is an example, not confirmation of Grimnir hunting, diet, or role content.

### Direct equipment actions

Picking up a weapon is its equip action. The inventory list can record what is carried, but there is no separate slot-rearrangement or drag-and-drop equip workflow. Actions occur in the world; UI explains the current person and loadout.

Anyone can wear or use an item without a matching character build. Compatibility with Traits (including preferences), Needs, items and state opens additional potential. The current design favors new interactions or equipment-dependent capabilities rather than hidden success-rate bonuses.

### Persistent clothing

Clothing is scarce, crafted from actual materials with care and labor. Appearance is constrained by what exists rather than freely selected from a cosmetic menu. Clothing can break; repair or replacement may be necessary. Repair requires its own Trait, tools, and materials and restores the previous condition.

Items carry traits, and richer crafted quality means more possible matches, not universal numerical superiority. Player skill decides execution once an interaction is available.

Logical body slots and containers replace weight accounting; slot replacement leaves the old item in the world. Exact catalogue, attachments, and elemental fit remain open.

See [Crafting](Crafting_and_Item_Traits.md) and [Objects and Persistence](#objects-and-persistence).

## Example E53: The claw survives its quest

*Illustrative example from the discussion.*

A claw can be looted, sold to a merchant, taken elsewhere, or lost. Handing it over for a requirement does not delete it. Physical consumption or transformation can end an object, as with eaten food; simply finishing a quest cannot.

Conversation: [turn 6](../../Morkahja-Concept-Sources.md#turn-45e8f44d-6c98-49ef-9d33-0dc3efb402ba), [turn 7](../../Morkahja-Concept-Sources.md#turn-1c7d9168-bd13-41c7-8553-74d1ade544ab).

## Example E54: What is worth carrying home?

*Illustrative example from the discussion.*

Small objects fit in an actual bag; a bow or weapon must be on the body. Bringing meat or an animal home may leave little capacity for unrelated finds and may invite help. The hunter example is logistical, not settled Grimnir diet lore.

Conversation: [turn 89](../../Morkahja-Concept-Sources.md#turn-e87391b6-8352-4027-93f7-e0fd79bc5360), [turn 90](../../Morkahja-Concept-Sources.md#turn-7107c60c-f1ab-491d-afc1-89efa0f76120).

## Example E55: A weapon is equipped by taking it

*Illustrative example from the discussion.*

Pick up a weapon in the world and it becomes equipped. A list may record it, but the player does not next move an icon into an equipment slot. An occupied logical slot is replaced by leaving its previous item behind; detailed hand-animation rules remain open.

Conversation: [turn 109](../../Morkahja-Concept-Sources.md#turn-46fdc006-e145-42e2-b980-0b4ac4c8da69).

## Example E56: Clothing costs effort

*Illustrative example from the discussion.*

A garment requires ingredients, care, and crafting. A community might have a maker or people might make their own. Clothes can break and perhaps be repaired; replacing them is not a free style choice. Garment production organization remains undecided.

Conversation: [turn 91](../../Morkahja-Concept-Sources.md#turn-786f1f3a-aedd-4c96-bf89-8132841a01da).





## Locally recovered Grimnir object vocabulary

The older local solutions database provides concrete material references: **Earthshaker Pickaxe** (tool and weapon), **Stonecrusher Mace** (solid-rock head), **Skyforge Key** (worked metal and geometric motifs), **Anchorstone Keystone** (dense hexagonal dark-stone relic), **Grimnir Runeblade**, and **Grimnir Boltcaster** (ironwood stock with boar/huntsman carving). Baneglaive, Banebow, Sturdy Net and Hornbane also occur in Grimnir-named asset records, but those filenames alone do not prove exclusive cultural origin.

These are vocabulary and future object-design references, not automatic starting equipment or approved powers. The Runeblade's magic-cutting claim and enchanted ranged weapons need their own authored recipes if adopted. The Glacial Halberd record explicitly says Rokur-crafted despite a Grimnir-prefixed image, so it is not recategorized as Grimnir lore. See the [local database excerpts](../../Reference_Material/Grimnir_Lore_2026-09-14/README.md#additional-local-database-search).

## Provenance, curiosity, and unidentified use

Crafting an object creates knowledge of its making for the crafter. Information about maker or possession spreads by Exchange Knowledge and contribution to the cultural source. It is not an omniscient ownership label visible to every person. Maker, current holder, and any entitlement are not necessarily the same thing; taking possessions is allowed, with missing-item recovery through Needs and Shards rather than a crime system.

An unfamiliar object with relevant existing knowledge can create a Need to learn whose it is or who made it, paired with the corresponding Shard. Characters may already know through prior exchange or the source, and the abandoned spear is only an example, not a claim that crafters routinely leave items lying around.

**An unidentified object is usable immediately.** Identification is not a gate on ordinary physical use. The user suggested that some item Traits, assistance, or specialized interactions might only become available through understanding the item, giving curiosity practical value. This extra-benefit mechanism remains a proposal. Answer 155 rejects a separate discovery process for each item quality; knowing the item reveals its Traits.

Source: [answer 152](../../Morkahja-Concept-Sources.md#turn-bbb2108d-baeb-43ef-b2b8-6ef272b436fa), [answer 153](../../Morkahja-Concept-Sources.md#turn-bbb21b7a-9905-4648-84b5-58c34bc89d5e), [answer 154](../../Morkahja-Concept-Sources.md#turn-bbb210ef-cbfb-4fb8-b04f-bf6019f5e780).


## Simple identification and possession recovery

An item has its Traits; knowing the item reveals its qualities without a separate discovery process for every quality. Unknown items remain physically usable. This settles Question 155 by rejecting further per-trait item archaeology; it does not specify a detailed identification bonus formula.

Taking another person's item is allowed without a crime, morality, or automatic social-penalty system. If their spear goes missing, the former holder gets a Need to find it. A witness who knows the spear can acquire knowledge of its current holder. The seeker checks the fountain, follows a knowledgeable person if necessary, exchanges knowledge, then pursues the next objective: obtain the spear from its holder. This is a normal Need/Shard chain. No global ownership information is revealed, and a lack of a report at the fountain does not override the guaranteed-fulfillment rule.

First successful physical interaction obtains a contested object. Other players see it gone or carried by the successful character. The network must enforce one result, but the presentation shows the changed world.


Source: [answer 155](../../Morkahja-Concept-Sources.md#turn-7e378bca-6998-4f89-92ad-920ca6519620), [answer 156](../../Morkahja-Concept-Sources.md#turn-82ab2c2c-cd51-4351-b594-fd4d7563bff3), [answer 169](../../Morkahja-Concept-Sources.md#turn-0ae1f637-06c9-49a9-b083-25f0afb24b47).


## Logical body slots and binary item condition

Carrying uses a small number of meaningful slots, not a weight statistic or exact geometric packing. Examples: small weapon, large weapon, ranged weapon, knife/tool, food, camping gear, backpack/bag. Small items use containers. A camping slot might also hold an extra weapon; the final slot catalogue and expansion rules remain to be specified.

Taking a replacement for an occupied slot leaves the old item at that location. Inventory remains lightweight and physical; the character panel may display slots without introducing inventory rearrangement as the equipping workflow. Rare weapons can be found in ancient caves from civilizations of earlier world cycles; this world has existed through previous rounds. Their history remains for later development.

Equipment condition is binary: Okay or Broken. Broken objects remain and can be left behind or repaired; they are unavailable for actions requiring functional equipment. No equipment destruction or disappearance at zero durability. Existing food consumption and material transformation are separate uses, not durability deletion; detailed resource lifecycle rules remain distinct.


Source: [answer 157](../../Morkahja-Concept-Sources.md#turn-c7d7c4d9-2a20-4a3b-9bb8-2572c44fca33), [answer 160](../../Morkahja-Concept-Sources.md#turn-ad8bf87a-dd61-4650-8eed-7be663a87c1d).

## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.


<details>
<summary>Original detail and examples — answer 155</summary>

> We can. That's, that is enough. We can let the spear has its qualities. Let the spear has its traits. We don't need to complicate things. Keep it simple.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-7e378bca-6998-4f89-92ad-920ca6519620)

</details>


<details>
<summary>Original detail and examples — answer 156</summary>

> We let that action happen. Someone who knows the spear, for example, and who knows that it's someone else's spear. They will then see the spear is on this person. So if the other person misses their spear, the spear is gone. They should get a need. So if I take someone else's item, this person should get a need, a hidden need. No? This person should get a need to find their spear. They lost the spear. Suddenly they remember, Oh, I lost my spear. And then they can go to the fountain, to the knowledge fountain, and see if it's there, if there's some information about it. And if not, it turns into a quest kind of. They can click it and they can maybe there's a person who knows. So the quest will lead them to this person. They can exchange knowledge with this person, and then they know, aha, this person has my spear. So they can, the objective, the next objective in this quest is get the spear from this person.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-82ab2c2c-cd51-4351-b594-fd4d7563bff3)

</details>


<details>
<summary>Original detail and examples — answer 169</summary>

> Yes. Exactly.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-0ae1f637-06c9-49a9-b083-25f0afb24b47)

</details>


<details>
<summary>Original detail and examples — answer 157</summary>

> We will limit the items to things that I actually... that we can actually carry. So we don't really need, like, weight. And then we will have slots on the body for weapons. There's a small weapon slot, a big weapon slot, a ranged weapon slot, maybe a knife slot, and then we will have bag slots, and we will have a tent slot. We will have, like, or, like, yeah, camping slot, kind of. We will have a food slot. So everything, all the items will have a slot. Yeah, so the inventory is just one slot for each type of item, and then we can replace the item we have, leave the old one there. And we could have a backpack slot, or, for example, a camping slot can also add another weapon slot, so we can stash away a weapon inside the camping slot. But yeah, I want to keep it all pretty lightweight. There aren't too many weapons to find or something anyways. Maybe that happens once in a while in an ancient cave where we discover, like, some remains of an old civilization, civilization before this cycle, because that actually exists in the world. Very old civilization. This is not the first round in this world. There have been others before us. But that's a story for another day. I think, yeah, we stay with a few slots and a few containers for the small items that we pick up. It's not what can visibly fit, but what can, what, yeah, what is kind of logical.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-c7d7c4d9-2a20-4a3b-9bb8-2572c44fca33)

</details>


<details>
<summary>Original detail and examples — answer 160</summary>

> I think we don't need to do that. I think it's fine. It's broken or it's okay. We don't need to destroy things. I mean, people can always leave a broken axe, just leave it behind if they want. But there's no reason for it actually. But yeah, we don't need to destroy objects. We don't want to have something anymore, then we just leave it. But yeah, no destroying items.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-ad8bf87a-dd61-4650-8eed-7be663a87c1d)

</details>
