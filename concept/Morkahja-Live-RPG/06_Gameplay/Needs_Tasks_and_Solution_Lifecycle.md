# Needs, Tasks and Solutions

A Need describes something currently required by a person or undertaking. Tasks organize these requirements into understandable work, and Divine Orientation follows the player's chosen priority.

## A structured Need

Each Need has an identity, an owner, fulfillment requirements and relevant task or quest connections. Its content definition also determines whether it is important enough to highlight.

A Need can accept alternative fulfillment paths. Suitable food may satisfy hunger; healing may be available through an item, a capable person or a particular interaction. Generic requirements find matching solutions, while a specific Need can name an exact relic, person or object.

Each Need completes independently. A task can contain several Needs, and consumptive requirements need sufficient supply for every fulfillment.

The first playable Need is **Stone Weapon**. It exists while the owner does not possess an item with that Trait, and it disappears when that condition becomes true, however the item was legitimately obtained. [Milestone 3](../99_Development/Milestone_3_Need_and_Divine_Orientation.md) uses this Need to exercise the Common Task loop.

## Task eligibility

A task may be generated only for something the character is fundamentally capable of doing. **Acquire a Stone Weapon** is valid for Khar-Morr because she has **Weapon Shaping**. A character who lacks the required permanent capability does not receive that task.

A temporary state is different. An injury or another negative state may block something the character normally can do without removing the underlying capability.

## Finding a solution

1. A Need appears in the character panel and in the relevant task or common task area.
2. The player can pursue a solution they already know, using available supplies, crafting or assistance.
3. A selected quest objective is already placed. Divine Orientation holds an angle toward that object; there is no separate Need to ask the Fountain where a moved object went.
4. If the object was destroyed or used up and no longer exists, a replacement is placed into unused world-node content. The signs then follow that new object.
5. Common-area Needs first use a valid free solution already in the world.

For example, village storage may already contain a salve suited to an injury. If one is free, the player can use it. If none remains anywhere, an appropriate world node receives new content.

When an active Common Task needs a physical objective, search for a **valid free solution**: a valid solution that is not already reserved as another character's active objective. Search the character's current hex first and pick one of those at random if any exist. If none exist, search the rest of the currently existing world and pick one at random there. Only if none remain, place one at an appropriate world node. The Memory Fountain does not create that object or a Shard. The starting hex already has authored shapeable rocks, so **Acquire a Stone Weapon** normally reserves one of those. When no free rock remains, that task's placement replaces the whole occupant of `node.village_001`, the stone container, with a shapeable rock. The container stays while any free rock exists. When that task is the only one, it becomes active as soon as it exists, and the reservation happens then.

The chosen entity receives a temporary character-specific Objective Trait, conceptually **Objective: Khar-Morr**, and the task keeps that entity's id. Divine Orientation tracks that entity's current world position. Movement alone does not select a new objective. If the reserved entity stops being a valid solution, the reservation is released and the free-solution search runs again.

The task definition may know what counts as a valid solution so the task remains solvable. That system knowledge is not automatically a Shard, and it does not teach the character. The task system must not create a Shard merely to make progression easier.

## A dynamic checklist

Tasks display a compact checklist of requirements the character currently knows. Unknown requirements stay hidden until Fountain information or another genuine Shard reveals them. System-only solution knowledge does not appear as if the character already knew it.

A healing task can involve a healing staff, a healer's capability, suitable knowledge and the treatment interaction. Reaching the item fulfills part of the preparation; performing the treatment resolves the injury Need.

When the character lacks information that is not a placed quest objective — a recipe, a person, a common-area Need — the checklist can still direct them to the Memory Fountain. Existing knowledge lets the player continue directly. A moved quest object does not create that Fountain visit.

## Priority belongs to the player

The common task area holds several personal and community tasks. One marker selects the current task or Destiny Quest for guidance. Important Needs glow or pulse so the player can notice them and decide whether to switch.

If at least one task exists, there is normally always one active marked task. The sole task is marked as soon as it exists. Receiving another task does not automatically replace the current active task. Selecting a Need opens its task view and moves the priority stone only when another task is already selected.

A negative state may take the stone only when it makes the chosen task impossible, and only then onto the task that resolves that block. Milestone 3 does not author an injury and does not move the stone for one. Completing the current thread advances to a replacement, using the oldest personal Need and then suitable community work as the default.

## Attainable, continuous routes

Dependency chains can grow through preparation and exchange while remaining acyclic. A requirement that would lead back to its own unresolved prerequisite receives another valid route.

The world preserves unique-object identity and provides enough material for separate consumptive Needs. An undertaking that preserves a unique object and one that consumes or breaks an object need compatible, separately attainable fulfillment.

Existing items stay where the world's events place them. A reward does not relocate a quest object away from someone already pursuing it. Prior discoveries and completed deeds can satisfy later suitable requirements.

## Completion follows the achieved condition

The checklist suggests a logical order and updates around requirements already satisfied. A player can find a material before seeking its location Shard, reach a healer first, or use an alternative valid route. The task completes when its actual completion condition becomes true.

For a healing task, that condition is the healed body part. Relevant knowledge and an item can support self-treatment; a capable healer can supply the expertise. If another player already carries the healing item and has the necessary capability, they can heal the injured person directly and complete that person's task. A suitable station or NPC can provide another authored route.

On completion, the task and its active Needs leave the task interface. The completed task object can be discarded, and another selected or default task becomes the current thread. A separate recent history retains the character's latest 100 interactions, while event Shards supply usable knowledge.

See [Knowledge](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md), [Destiny](Destiny_Quests_and_Progression.md), and [Task Interface](../08_Presentation/Interface_and_Divine_Orientation.md).
