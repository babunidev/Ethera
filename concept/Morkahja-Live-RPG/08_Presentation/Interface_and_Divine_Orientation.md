# Interface and Divine Orientation

The interface supports understanding and intention while the character acts in the world. Stone surfaces, small disks and a movable marker give the Grimnir presentation a tangible form.

## Character panel

The upper-left body silhouette shows injuries, with equipped and carried item slots beneath it. Tabs on the right present Traits, Needs, Shards, States and discovered Interactions. Preferences belong among Traits.

Entries have names and descriptions. Hovering explains relevant actions, enabling conditions and current blockers. Known interactions remain documented when unavailable; latent qualities and undiscovered actions stay concealed.

Clicking the silhouette opens the Tasks and Destiny view. Selecting a Need in the Needs tab also opens that view. If another task already holds the priority stone, that selection places the stone on the corresponding Common Task. When **Acquire a Stone Weapon** is the only task, it is already the active one, so opening the view does not change the selection. There is no silhouette yet, so a **Destiny** button on the character panel opens the same screen. For Milestone 3 that screen may remain simple and primarily text-based; only the Common Task area needs to function.

## The stone board

The board resembles a shaped stone tabletop with branching lines and notched slots. The common task area sits to the left of the Destiny structure. A marker stone selects the active task or an unlocked quest.

The Destiny Quest expands and converges through **4 → 8 → 16 → 8 → 4 → 1 Knot**. Those counts are the rings. Combat, Trickery, Aid and Social are categories. Upcoming slots can be visible while their prerequisites remain locked. Completing a prerequisite makes its next available choices selectable.

The **priority stone** is the marker on this board, not a stone in the landscape. Placing it on a quest reveals that step's work and the next ring. Completing a Knot opens the next Destiny Quest.

## Common tasks and checklists

The common area expands to show several personal and community tasks. A compact lower-left display shows the selected task; hover gives its description, and clicking opens the list.

The first Common Task is **Acquire a Stone Weapon**. It uses a dynamic checklist: the goal and requirements the character currently knows. Unknown requirements stay hidden until Fountain information or another genuine Shard reveals them. An unknown requirement that is not a placed quest object can still direct the character to the Memory Fountain. A selected quest object is followed by Divine Orientation instead.

Selecting a task moves the same priority stone used by Destiny. If at least one task exists, there is normally always one active marked task. The sole task is marked as soon as it exists. Receiving another task does not automatically replace it. Milestone 3 does not author an injury and does not move the stone for one. Later, a negative state may take the stone only when it makes the chosen task impossible, and only then onto the task that resolves that block.

## Important information

The character-panel stone glows or pulses when important information appears. Important Needs and tasks are also highlighted in the list. Importance is set in each authored Need.

The current player-selected priority remains active until the player changes it or the thread completes. Completion advances through remaining Needs, then defaults to the oldest unresolved personal Need or suitable community work.

## Contextual actions

Hover gives a subtle cue; holding left click selects the focused world target and reveals currently available radial actions. Selecting one commits that target and begins the character's approach and interaction. Aimed Attacks enables the subsequent body-part choice before the skill phase. Known blocked actions can be inspected in the character panel.

People are read through bodies, possessions and behavior. Nameplates, health bars, role labels and relationship icons are absent above their heads. A familiar person's cursor can subtly express Recognition, Sympathy or Trust. Recall Knowledge opens the stone disk containing what the current character has learned about them.

## Divine Orientation

The priority stone's selected objective always has an **angle**. This is true for a Common Task objective as well as a Destiny Quest objective. World signs — wind, grass, birds, light and elemental resonance — hold that angle toward the object wherever it is. There is no compass, no map arrow, no quest marker and no permanent glowing path. The player does not see the object move; they see the signs change direction, even when that change is slight.

If the object is in someone's inventory, the signs point at **that person's current place**. A contrary wind can indicate a wrong turn. Signs remain intermittent and quiet, with pauses that leave room for attention.

**Shards represent what the character knows.** Divine Orientation tells the player which direction the currently selected objective lies. It works whether or not the character possesses a relevant Shard.

Milestone 3 implements two signs: a **Ground Wind-Wave** traveling across the ground toward the objective, and a brief **Ground Glint** farther ahead along that direction. For prototype testing, about every ten seconds one of the two is chosen at random. Timing, size, distance and brightness are tuning. Bird guidance remains later work.

This replaces visiting an empty site or the Fountain to learn that an object has only moved. If the object was destroyed or used up, a replacement is placed into unused world-node content and the signs then follow that new object. The Fountain does not create the replacement or a Shard for it.

Taking another person's selected quest objective puts the taker in that character's **observable universe**. The inhabited client receives the bearing and a rough sense of where they are. It does not receive the rest of that region's hidden knowledge.

Divine guidance remains distinct from the character's Shards, which change through observation and knowledge exchange. Orientation for a selected quest objective points at the **object**, not at pickup Shards. Rare unique knowledge that has no object may still need a Shard holder; if several people hold that Shard, pick one at random.

## Nearby discoveries

Signs can also draw attention to a nearby opportunity relevant to another task or person. Sunlight through glass, a bird landing, bent grass or a falling leaf can invite investigation. The player decides whether to follow it or switch priorities.

## Quiet signs in practice

A white bird rises from a bush along a route. Later, reflected light briefly picks out a passage. A Grimnir senses a subtle pull through stone toward the horizon. After a wrong turn, the wind resists their path. The same recognizable language supports every player.

## Knowledge interaction selections

An Echo Cradle supplies the world target for Bind Shard and Absorb Knowledge. The interaction then presents a carried-stone selector. For Bind Shard, the socketed stone is followed by a known-Shard list with authored permanent Shards first. The stone returns to inventory when the action completes.

Memory Binding begins at the Memory Fountain. Its selector shows non-empty carried stones and hover tooltips listing their stored Shards. A warning identifies that the selected whole stone will be consumed before the player proceeds.

These choices remain part of the initiated physical interaction. The character panel displays knowledge and available information about known actions.

## First playable controls and inspection

Hold left-click on a target to open available radial actions, move toward the desired option and release to select it. The character approaches the correct position beside the target and faces it before execution. A direct left-click on a loose compatible item performs pickup or swap. Left-click and drag on the inhabited character controls camera orbit; the mouse wheel controls zoom.

The first character panel uses readable text lists for body condition, Traits, known Shards, interactions and equipment. A development-only event log in the upper-right corner reports starts, results and data changes while the final visual interface develops. **C** opens and closes the character panel in Milestone 1.

See [Tasks](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md), [Destiny](../06_Gameplay/Destiny_Quests_and_Progression.md), and [Knowledge](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md).
