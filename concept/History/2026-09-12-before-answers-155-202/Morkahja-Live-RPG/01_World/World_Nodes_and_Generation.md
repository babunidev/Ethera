# World Nodes and Generation

**Current concept through answer 154 · updated 2026-09-11.**

A world node is persistent geography with changing content slots. This chapter combines its structure, repopulation, history boundary, and generation rules.

## World Nodes

### Persistent geography and content slots

A node is a persistent piece of geography with multiple kinds of current content. A cave, hill, small forest, or shrine shapes the landscape and does not disappear simply because a quest ends.

A single node may contain a creature, an item, and other content simultaneously. Geography and persistent place-defining traits are distinct from replaceable content slots.

### Repopulation

Some world traits describe current state and can change when the previous content or purpose ends. A dangerous cave whose danger has been removed can later serve a different objective. A creature slot may host a wolf after the previous bear has died and the slot becomes available.

The living bear does not morph into a wolf. The old occupant ends; later generation supplies another occupant, potentially even another bear. This remains distinct from an endless timer-based respawn treadmill.

Changing one content slot does not require deleting the cave or treating every other slot as empty. The exact vacancy and dependency checks are not specified.

### Where history lives

The node maintains its current reality, not a local historical diary. When repopulated, its old associated shard-state leaves the node. Historical knowledge survives in copies held by characters and collective memory.

Collective memory retains outdated shards alongside newer layers. For practical quest guidance it supplies the newest relevant known information. A node can change without every character learning that change immediately.

See [World Generation](#world-generation) and [Collective Memory](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md).

## World Generation

### Stories create world content

Characters' traits, roles, destinies, and side quests bring the required places, creatures, items, and circumstances into the world. A destiny requiring a bear creates an appropriate bear and location; another may require a tree, cave, trail, or important object. Generation establishes the ingredients, while players determine how events unfold.

Later decisions place social roles and destiny at adulthood. The initial birth-generated-content idea therefore becomes a lifetime pipeline: birth defines traits, youth participation reveals them, and the adulthood ritual reveals role and begins destiny. Whether content is secretly prepared earlier or generated at adulthood is still open.

### Reuse and expansion together

Each destiny should expand the world with new content. It must also reuse suitable existing nodes so older areas stay relevant and travel does not become endlessly longer.

A bear site becomes vacant only after the bear and relevant remains have gone. A flower may later grow there, someone may lose a family object there, or a cave may acquire a new occupant. A place persists while its current purpose changes. These are examples of repopulation, not timer-based identical respawns.

### Journey scale

Adventures should remain broadly manageable in size. An early destiny may already point to distant mountains, with routes and intermediate encounters making up the journey. New content does not have to begin beside the village.

Nodes now explicitly combine persistent geography with multiple replaceable content slots. Historical records live in personal and collective Shards, not in a node-local diary. Detailed vacancy checks, conflicting destinies, map boundaries, and placement validation remain open. See [World Nodes](#world-nodes).

Geography such as a cave or shrine persists while creature or item contents can be repopulated. A living bear does not become a wolf; replacement follows the end of the previous occupant. Old node-associated shard-state disappears on repopulation, while preserved external shard copies remain. Collective memory serves the newest relevant known information for current objectives.

Exchange dependencies can grow without an imposed depth limit. The earlier manageable-journey principle concerns content placement and travel, not a hard cap on the number of linked Needs.

### Solvability and local desire pressure

Each new Need must have a possible solution: connect existing content or generate what is missing. Failed attempts create recoverable changes, not permanently closed routes. Unmet Desires can prioritize local world content or matching traits in future newborns; a social counterpart may require waiting for a future person.

This influence remains settlement-local. Start with one Grimnir community. See [First Playable Scope](../99_Development/First_Playable_Scope.md).

## Example E05: A bear site gains another life

*Illustrative example from the discussion.*

After the bear dies and its parts and remains are removed—perhaps wolves carry off the skeleton—the vacant content can be repurposed. A special flower may grow there, or someone may have dropped a valuable family object while carrying the bear away. An early apple-tree example expresses the same reuse principle; later geography/slot rules govern placement.

Conversation: [turn 7](../../Morkahja-Concept-Sources.md#turn-1c7d9168-bd13-41c7-8553-74d1ade544ab), [turn 23](../../Morkahja-Concept-Sources.md#turn-b88a9d87-6545-4123-8898-0a0ee4af1525), [turn 55](../../Morkahja-Concept-Sources.md#turn-7ddb07ab-a574-4f9b-a015-e5e1042efa27).

## Example E06: The mushroom cave and the new occupant

*Illustrative example from the discussion.*

One story sends a person to find a special mushroom in a cave. Later a troll might move in. Another example replaces a departed bear with wolves. The cave persists; no living bear transforms into a wolf. The old occupant must be gone before that content slot is repopulated.

Conversation: [turn 23](../../Morkahja-Concept-Sources.md#turn-b88a9d87-6545-4123-8898-0a0ee4af1525), [turn 55](../../Morkahja-Concept-Sources.md#turn-7ddb07ab-a574-4f9b-a015-e5e1042efa27), [turn 56](../../Morkahja-Concept-Sources.md#turn-1c23e5cb-5009-4735-a587-3959dde62c97).

## Example E07: Several contents at one place

*Assistant illustration of the user’s multi-slot rule.*

A cave may simultaneously hold a creature and an item. The assistant illustrated this as Cave + Bear + Old Charm + Mushrooms + Dangerous, later Cave + Wolves + Lost Hunting Tool + Mushrooms. These sample slot labels explain coexistence; they are not an approved data schema.

Conversation: [turn 56](../../Morkahja-Concept-Sources.md#turn-1c23e5cb-5009-4735-a587-3959dde62c97).

## Example E08: Distant adventures need not wait

*Illustrative example from the discussion.*

An early destiny can already lead to the mountains, with trails and intervening discoveries. Reusing old locations prevents every new adventure being pushed farther from home, while each destiny still introduces new content.

Conversation: [turn 23](../../Morkahja-Concept-Sources.md#turn-b88a9d87-6545-4123-8898-0a0ee4af1525).

## Example E09: An unmet desire shapes future possibilities

*Illustrative example from the discussion.*

If a desired quality can be carried by an item, creature, or location, suitable content can be generated. If it must belong to a person, give the trait priority in future local newborns. Existing people are not rewritten and fulfillment may wait.

Conversation: [turn 84](../../Morkahja-Concept-Sources.md#turn-7b805426-f1b6-4135-b033-4f0c901bf4cc), [turn 85](../../Morkahja-Concept-Sources.md#turn-2e92f520-37b5-4b13-ae8b-26eb5a5f2399).




## Large modular hex tiles and continuing expansion

The world should feel as vast as possible and expand through large modular hexagonal terrain tiles. A tile takes minutes upon minutes to cross and contains many landmarks, objects, and content opportunities; it is not one encounter-sized cell. Begin with one biome, with grassland/savanna and hills, then support more biomes later.

Terrain placement is semi-random with continuity rules. A forest tile raises the probability of adjacent forest; discovering mountains should suggest more mountains behind them. A lake contained within one large tile was suggested; water and shoreline rules remain to be worked out. Tile edges must fit together.

The design direction is approximately a new tile for each quest. A quest may ultimately point somewhere else; the added terrain still remains an expansion that can be explored. This extends the earlier reuse of world content: persistent nodes and their content slots can live within larger terrain tiles. A hex tile, a local content node, and a Destiny Knot are different concepts. Exact allocation frequency and streaming budgets are not specified.

There should be no mandatory unexplored-territory labels or meta notifications. Information may be learned at the cultural knowledge source. Character-specific fog of war was raised as optional, then left undecided; ordinary land without that overlay is acceptable. A player's memory of previous visits need not match the currently inhabited person's knowledge.

Source: [answer 107](../../Morkahja-Concept-Sources.md#turn-0e896415-cfa5-44a8-9a91-65309de7c106), [answer 108](../../Morkahja-Concept-Sources.md#turn-b9fe0a6c-5c05-4f2e-940d-3835baed39d1).

## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.
