# World Nodes and Generation

Morkahja combines persistent geography with changing inhabitants, objects and purposes. Quests connect characters to this shared world and create opportunities for it to grow.

## Terrain tiles

Large modular hexagonal tiles form the landscape. Crossing one takes several minutes, with many landmarks, objects and encounters along the way. The first settlement is mostly grassland, with smaller rock formations, water and rivers among it.

Tiles are authored puzzle pieces. Each of a hexagon's six edges has a landscape type. Touching edges must match: grassland to grassland, forest to forest, river to river. One tile can carry different types on different edges.

**Every Destiny start adds exactly one hexagon.** Look at unused edges of existing tiles, collect the authored pieces whose touching edge or edges match those neighbors, pick one of those pieces at random, and attach it. A pocket that touches two existing edges needs a piece that matches **both**. The first expansion uses the same rule against the starting settlement; it is not forced to be a pure grassland tile.

A tile added this way remains part of the world even if that Destiny Quest later ends or the character dies. Early adventures can already lead toward distant mountains, with routes and discoveries forming the journey.

## World nodes

A node is a local place within the terrain: a cave, shrine, resource site or another persistent feature. Each can hold several replaceable occupants at once. A cave might contain a bear, an old charm and mushrooms, together with current properties such as Dangerous.

Those occupants can be a container, what is inside a container, a creature, a climbable tree, a rock, or other authored content. The place stays while its contents change.

## When content may be replaced

Content that is an objective for any Common Task or Destiny Quest is not replaced.

Content unused by any task or quest may be replaced. The world may replace what is inside a container, or replace the whole occupant. The new occupant can be a different container, a creature, a climbable tree, or whatever the authored need requires.

A leftover unused by any living task or Destiny Quest may be claimed where it already lies. The first quest or task that can use it claims it. A second cannot share it; it creates or claims something else. Nothing is moved merely to become a reward.

If the character dies after a Destiny Quest is placed, the hexagon and the objects stay. They lose that Quest's objective binding and become vacant content a later destiny can bind. Everything that is created stays.

## Reuse and continuity

A bear site becomes available for another purpose after the bear and relevant remains are gone. Wolves might carry away the skeleton; a special flower might later grow nearby; a traveler might lose an object while returning from the hunt. Another cave can continue supplying mushrooms after a different creature moves in.

When a Destiny Quest is created, every quest through its Knot is placed. The new hexagon must hold **one objective from each ring** (4, 8, 16, 8, 4) **and the Knot**. The rest may use old vacant ground.

Objects and deeds retain their history. A claw collected before a task appears can satisfy a suitable later requirement.

## Generation from authored content

Actual Traits, Needs, items and circumstances determine which authored content is selected and instantiated. Creatures, locations, interactions and quest pieces combine into a fitting adventure. Personal Destiny unfolds as adulthood and later development open new possibilities.

A Common Task or Destiny Quest first uses a **valid free** solution already in the world. Only when none remains does the world place a new solution at an appropriate node. It does not appear beside the player.

If a selected objective has been **destroyed or used up** and no longer exists, a replacement is placed into unused node content. Divine Orientation then follows that new object. It does not create extra solutions for objects that have only moved. The Memory Fountain does not create that object or a Shard for the placement.

For **Acquire a Stone Weapon**, that fallback replaces the whole occupant of `node.village_001`, the stone container, with a shapeable rock, and only when no free rock remains. The container stays while a free rock exists.

Each fulfillment route remains attainable. Separate consumptive requirements receive sufficient supply, and dependency chains remain acyclic. Existing unique objects keep their identity through ownership changes and task updates.

## Current state and remembered history

The node holds the current state of its geography and contents. When a slot is repopulated, its associated current information changes. Older knowledge survives in Shards held by characters and communal memory.

A traveler can therefore remember a bear in a cave that now contains wolves. Learning about the change requires observation or exchange. The Memory Fountain supplies relevant retained knowledge, while archival stones and authored permanent Fountain records preserve selected historical layers. Ordinary reports expire one world week after their creation.

See [Knowledge](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md) and [Needs and Tasks](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md).
