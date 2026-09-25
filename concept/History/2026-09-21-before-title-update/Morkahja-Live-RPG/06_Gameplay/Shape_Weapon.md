# Shape Weapon

Shape Weapon forms a primitive stone club from a suitable rock in the world. It belongs to **Combat → Weapon Craft** and uses **Shape Trace** for its first implementation.

## Requirements and approach

The actor has **Weapon Shaping** and a healthy usable arm. The focused world object has both **Rock** and **Shapeable**. These Traits identify a suitable source object; the object itself supplies the stone for the weapon. A group of stones can form the visible appearance of that single entity.

The separate negative-state blocker filter checks whether the action and its required capability are usable. Selecting Shape Weapon in the radial menu sends the character to the authored position beside the rock and turns them toward it.

## Execution and result

The player completes [Shape Trace](Player_Skill_Phases.md#shape-trace) within its authored time limit. Success removes the source rock's current manifestation and creates a stone club with **Weapon** and **Stone Weapon** Traits. The club equips in the **Small Weapon** slot, visibly attached to the character's back. If the slot is occupied, its previous item appears on the ground beside the character.

The consumed manifestation leaves reusable world content available for later placement when the world needs a suitable rock. Historical records retain their exact original target and place. A later manifestation must preserve the meaning of those earlier references.

Failure leaves the rock and equipment as they were. A fresh attempt is possible while the requirements remain satisfied.

## The event becomes knowledge

After applying the successful result, create one event Shard with the actor, the specific source rock, Shape Weapon, Reaction None, the created/equipped club result, the place and exact world time. In Khar-Morr's first test, she learns this Shard and can contribute it to the Memory Fountain through Echo Imprint.

See [Milestone 1](../99_Development/Milestone_1_Khar_Morr.md), [Items and Carrying](../07_Items/Items_Equipment_and_Carrying.md), and [Echo Imprint and Attunement](../05_Knowledge/Echo_Imprint_and_Attunement.md).
