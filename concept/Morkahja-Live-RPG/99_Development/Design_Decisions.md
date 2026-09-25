# Design Decisions

## Current title

The current title is **Ethera: The Stonewrought**. Ethera names the game; The Stonewrought describes the current Grimnir chapter. Morkahja remains the world. Earlier titles in source transcripts and dated records are historical wording. Existing folder names remain stable so saved paths and references continue to work.

## Technical architecture decisions

Settled September 21. These govern how the authoritative simulation is built. The full architecture is [RealmNode: Game-Native Architecture](../09_Technical/RealmNode_Game-Native_Concept.md); the implementation consequences are recorded in [Technical foundation](RealmNode_and_Technical_Foundation.md).

| Decision | Consequence |
| --- | --- |
| The authoritative game runtime is **Rust, in its own crate beside RealmNode**. | RealmNode decides who calculates, who validates and whether state is accepted. The runtime decides what interactions, AI and consequences mean. A validator runs the runtime without launching Godot. |
| Authoritative GDScript is **temporary**. | Game rules move into authored data or deterministic logic behind a clean interface. GDScript keeps presentation, input, animation, UI, local prediction and prototype glue. Nothing new that describes a game rule may become entangled with Godot. |
| Authoritative values use **deterministic representations**; presentation may use ordinary floats. | Integers or fixed-point for time, resources, damage, distance thresholds, measurements and random results. Platform-dependent trigonometry may not reach hashed truth unless the runtime defines it or quantizes the result. Godot physics is not authoritative. |
| World time is a **fixed simulation tick**, currently twenty per second. | Frame deltas never enter the simulation. Knowledge retention no longer depends on frame rate. Rendering runs at any rate and interpolates. |
| Validators verify **gameplay legality, not human dexterity**. | The actor submits timestamped input samples, never an outcome; the runtime calculates the score. Proving genuine human participation is explicitly out of scope. |
| Item and equipment changes are **immediate to the player, validated underneath**. | The click takes the item at once while the durable transaction moves from pending to validating to committed. Only a validation failure reconciles. |
| A disconnect **before** a consequence commits cancels the round; **after**, the consequence stands. | Reuses the deliberate-cancel behaviour. An authoritative result is never reversed because the actor vanished. The character enters the disconnected/waiting state. |
| Regions without players go **dormant, not frozen**. | Active regions simulate fully; dormant regions resolve work, food, rest, relationships, resources, development, knowledge aging and important events abstractly. Total absence of simulating machines still freezes the world. |
| Hidden knowledge stays **authoritative state**. | Clients receive only what their current character is entitled to observe. No machine owns a Memory Fountain; its knowledge is a replicated settlement shard queried through the runtime. The inhabited character also receives the bearing of their selected quest objective. |

## Milestone 3 Need and orientation

Settled September 23 from Alex's Need and Divine Orientation brief and the follow-up rulings.

| Decision | Consequence |
| --- | --- |
| The first Need is **Stone Weapon**. | It exists while the owner has no item with that Trait, and ends when they do, by any legitimate route. |
| **Acquire a Stone Weapon** is a valid Common Task only if the character has **Weapon Shaping**. | Temporary states may block current use without removing the capability. |
| The Common Task uses the **dynamic checklist**. | Known requirements appear. Unknown ones stay hidden until Fountain information or another genuine Shard reveals them. System-only solution knowledge is not shown as known. |
| A Common Task first reserves a **valid free solution** already in the world. | Search the current hex, then the existing world. The reserved entity receives a character-specific Objective Trait. |
| When **Acquire a Stone Weapon** is the only task, it is active immediately. | The rock is reserved then, and Divine Orientation starts. Selecting the Need opens the Destiny screen. It moves the priority stone only when another task is already selected. Receiving another task does not steal the stone. |
| If no free rock remains, replace the whole occupant of `node.village_001`. | That occupant is the stone container. Leave it alone while any free rock exists. The replacement is a shapeable rock in that node's place. The Fountain does not create the object or a Shard. |
| Unused node content may be replaced; reserved objectives may not. | A node holds several replaceable occupants. Unused content can be swapped in whole or only inside a container. The Stone Weapon fallback above is the whole occupant. |
| Divine Orientation tracks the reserved entity, not its original coordinates. | Movement does not reselect. An invalid or consumed objective releases the reservation and searches again. |
| The player moves the priority stone among existing tasks. | Important Needs are highlighted. Milestone 3 does not author an injury and does not move the stone for one. Later, a negative state may take the stone only when it makes the current task impossible, and only then onto the task that resolves that block. |
| Destiny opens from the silhouette, the Needs list, and a Destiny button. | There is no silhouette yet, so Milestone 3 uses the button and Needs. |
| The task system does not invent Shards. | The Fountain only redistributes knowledge that already entered the system. Guidance can run with no useful Shard. Echo Attunement stays in Milestone 4. |
| Milestone 3 signs are **Ground Wind-Wave** and **Ground Glint**. | About every ten seconds one of the two is chosen. Birds, map and compass stay out. Cue size and timing are tuning. |
| **Destiny Quest** is the current name for the branching Destiny undertaking. | Earlier documents called it Destiny Crest. Rings, Knot, and categories are unchanged. |

## Destiny expansion, placement and orientation

Settled September 21 from Alex's expansion clarification. These govern where earlier wording about Fountain visits, hidden quest objects and shardless pickup conflicts.

| Decision | Consequence |
| --- | --- |
| A Destiny Quest starts at coming-of-age and again when a Knot is completed. | Completing a Knot opens a new Destiny Quest (4 → 8 → 16 → 8 → 4 → Knot), not another ring on the same Quest. |
| Only a **player-inhabited** life starts a Destiny Quest. | Uninhabited lives do not advance Destiny and do not add land. They work common-area tasks and Needs. |
| At Destiny start, every quest through the Knot is **placed**, and **exactly one hexagon** is added. | Objects are manifested and discoverable. Other people may pick them up. The board still locks the next ring. |
| Combat, Trickery, Aid and Social are **categories**. Rings are **4, 8, 16, 8, 4**, then the Knot. | The new hexagon holds one objective from each ring plus the Knot. The rest may use old vacant ground. |
| Hexes are authored **puzzle pieces** whose touching edges must match. | A two-edge pocket needs both types. The first expansion uses the same rule on the starting settlement. |
| Leftovers are claimed only when **no living task or Destiny Quest** still points at them. | The first claim takes the leftover where it already lies. The next quest creates or claims something else. Nothing is moved. |
| Death after placement leaves the hexagon and objects. | They lose that Quest's objective binding and become vacant content. Everything created stays. |
| Every pickup writes a Shard; the same item **replaces** the previous pickup Shard. | **Only the picker** receives it. Taking from a container is a pickup. Opening a container writes a discovery Shard for the opener. The Fountain learns either only through Echo Imprint. |
| A destroyed quest objective is replaced in **unused world-node content**. | Not beside the player, and not by taking another reserved objective. The whole occupant or only its contents may change. |
| Divine Orientation **always** holds an angle toward the selected object. | World signs, not a compass. This includes a Common Task objective. Inventory points at the carrier. A taker enters the owner's observable universe. Moved objects do not send the player to the Fountain. |
| The Fountain does not create a replacement object. | Superseded 23 September 2026. A destroyed or used-up objective is replaced in unused world-node content. The Fountain does not invent that object or a Shard. Moved objects are not replaced. |

## Milestone 1 implementation decisions

Four questions raised while building the local simulation are decided. They govern where earlier wording conflicts.

| Decision | Consequence |
| --- | --- |
| The event Shard created by Echo Imprint is learned by **both** participants. | No leftover contributed record stays unshared. One success transfers up to three eligible Shards, then writes the imprint event. Imprint becomes unavailable until a genuinely new record appears. |
| Left-click pickup **walks her into reach** and takes the item on arrival. | Inherent pickup gains an approach like an authored interaction. A club already within reach is taken at once. The displaced club still uses the clicked club's exact former ground position. |
| Holding a radial open **slows her pace**, as the interaction chapter states. | The reduction is part of Milestone 1 rather than later polish. |
| Right-clicking during an authored approach **abandons the round**. | The round resolves nothing, so no event Shard and no history entry. A skill phase that has already begun keeps movement and ignores walk commands. |

## Build handoff refinements

C toggles the panel. Pickup swaps put the displaced club at the clicked club's exact ground position; crafting replacement still uses Khar-Morr's position. The environment uses organic continuous merged stone and a separate Fountain asset. Milestone 1 runs locally with world-owned entity data, stable IDs and UI/presentation separated from state. The local [handoff](Implementation_Handoff.md) assembles the current build references. The Ethera naming discussion is incorporated separately from gameplay scope.

## Current milestone decisions

[Reconciliation through answer 399](Update_Through_Answer_399.md) records the current first playable, Godot/Blender selection, Shape Weapon, separate Echo directions, state blockers, inherent actions, skill phases and controls. The tables below preserve earlier decision history and are read with this later reconciliation.

## Prototype review and answers 342–358

Create Echo Cradle is a separate interaction replacing suitable world material with a new Cradle entity carrying only its own authored Traits. Cradle matching uses the Echo Cradle Trait. Bind Shard is the action; Shard Binding and Knowledge Absorption are capability Traits. Player-skill definitions are reusable, belong to one subcategory and are selected by exact override or random matching-pool draw. Twelve pools and roughly six phases each are selected; the requested full library remains a draft. This earlier source snapshot ended at the original difficulty question 359; the milestone update extends coverage through answer 399.

The first playable now follows the milestone sequence through answer 399. Milestone 1 is Khar-Morr shaping a club, handling equipment and contributing knowledge through Echo Imprint. The experience in answers 106–111 supplies the wider village, discovery, social and inhabitation roadmap. Mountain Strike remains an individual combat interaction. This project works exclusively on Morkahja Live RPG; MorkahjaStandalone and MorkahjaWebApp are separate projects and must not be accessed or modified for this work.

## Current decision reconciliation — through answer 341

The [update ledger](Update_Through_Answer_341.md) records replacements to task ordering, history, names, combat, Shard identity and retention, item capability and archival interactions. Current topic chapters incorporate these decisions. Earlier dated entries below remain historical records.

## Editorial policy

Main chapters describe the established game directly, with coherent headings and useful examples. Source quotations, dated updates, rejected alternatives and revision explanations belong in the archive. Unresolved design choices belong in Open Questions; possible future additions belong in Ideas. Editorial simplification must preserve the distinction between settled rules and open choices.

The complete pre-cleanup chapters are retained in the [source archive](Source_Archive.md).

For current rules, use the September 13 reconciliation below and the topic chapters. Earlier dated entries preserve decision history.

## September 12 — current replacements and additions

- Safe village baseline replaces starvation or misery from neglected tasks; players drive major growth and reproduction, AI supplies helpful basic life.
- No active simulation means exact freeze, replacing offline continuation/slowdown. Snapshot implementation remains RealmNode work.
- Logical body slots replace weight/packing; equipment persists Okay/Broken; independent repair restores it fully. Basic craft needs no recipe; knowledge enriches it.
- Permanent exact pairwise bonds; no global reputation, regression, exclusive couples, or permanent parent role. Creation ends in shared final shaping; inheritance stays 9+9+9 and youth Desires mostly random.
- Atranor is a solvable player challenge; failure is terminal, success returns safely with items. Personal progress ends on dissolution, community Needs return, possessions drop.
- Queue offers and approximately ten-minute reclaim; anti-griefing intentionally deferred.
- Village buffs affect everyone present, distinct effects coexist, same types refresh, duration uses outings consumed on re-entry. Oldest state is shown, all states act mechanically.
- The stone board now explicitly uses 4 → 8 → 16 → 8 → 4 → 1. Common slot selects oldest personal Need and then community fallback. Guidance is always targeted.
- Question 203 remains unanswered. The user requested questions elicit their design rather than smuggle in assistant proposals; the first proposed Question 193 was replaced, not answered. Consolidation continues in this local archive.


The September 12 additions are the latest record. Earlier dated decisions, counts, and mappings are historical where superseded; current rules are in the topic chapters.

**Current concept through answer 202 · updated 2026-09-12.**

Consolidated concept material, with current rules and unresolved details distinguished.

Later explicit user statements override earlier brainstorms and assistant summaries.

| ID | Current decision | Conversation basis |
| --- | --- | --- |
| D001 | Persistent world characters are temporarily inhabited; players do not own avatars. | Opening concept. |
| D002 | Shared multiplayer RPG with autonomous settlements; no building management by players. | Explicit settlement-control correction. |
| D003 | Population growth adds available character slots. | Community and reproduction discussion. |
| D004 | Objects exist before objectives and remain afterward unless physically used or changed. | Bear claw and earlier-loot examples. |
| D005 | Objectives follow goals and existing objects, not mandatory repeated kills. | Dynamic bear objective example. |
| D006 | Reuse vacant nodes and add new content with every destiny. | Expansion and repopulation clarification. |
| D007 | Traits are binary and never routinely lost. | Interview answers on trait ranks and decay. |
| D008 | Birth pool is 27 traits: 9 from each parent and 9 global, without category balancing; later local unmet-Desire priority can affect future generation. | Trait-count and random-draw answers. |
| D009 | Early childhood is simulated; youth is playable, with progress-based development and a final adulthood ritual. | Growth explanation. |
| D010 | Role and destiny begin at adulthood. | Explicit later timing corrections. |
| D011 | Roles grant abilities and unique interactions; exact lists are culture-specific and deferred. | Hunter tracking and culture discussions. |
| D012 | Side quests can add relevant permanent traits. | Climber and herb-learning examples. |
| D013 | AI maintains life and explores within endurance limits but never advances destiny. | AI destiny answer. |
| D014 | World continues offline and may slow down. | Offline simulation answer. |
| D015 | Atranor judgment permits continuation or dissolution; role and destiny can return to the pool. | Death explanation. |
| D016 | Account owns no persistent gameplay advantage; diary remains optional. | Account progression correction. |
| D017 | Manual logout returns home; unexpected disconnect waits until return becomes necessary. | Logout distinction. |
| D018 | Optional queued stand-ins; original player reclaims the character on return. | Stand-in answer. |
| D019 | Timed multi-recipient offers resolve to the earliest accepting eligible queued player. | Queue offer explanation. |
| D020 | Spectators follow characters only, no free flight. | Explicit spectator correction. |
| D021 | No proximity voice or text chat. | Two successive communication corrections. |
| D022 | Interactions depend on relationships, roles, traits, and matching knowledge. | Interaction-depth answer. |
| D023 | Direct sharing duplicates; no memory burden or capacity. Newer received information replaces obsolete personal shards, while communal history persists. | Updated 2026-09-10; replaces the earlier lightening concept. |
| D024 | First playable scope is one Grimnir settlement; broader peoples remain separate and have not encountered one another. | Culture and social-role answer. |

No numeric balance values, technical architecture, complete trait catalogue, or role roster are implied by this record.

| ID | Decision | Basis in today's interview |
| --- | --- | --- |
| D025 | No shard weight, capacity, or oldest-first forgetting. | Answer 33 supersedes answers 31–32. |
| D026 | Shards are functional information, not general autobiography. | Answer 34. |
| D027 | Updates require performed local exchange or hub consultation; replace obsolete personal information on receipt. | Answers 35–37. |
| D028 | Relationships are neutral/positive; recognition, sympathy, trust can unlock deeper actions. | Answers 37–38. |
| D029 | Persistent Traits/Desires; situational Shards/Needs. | Answers 39–40. |
| D030 | Target 27 Desires: 9 inherited total, 9 birth-generated, 9 experiential. Exact acquisition timing open. | Answer 41. |
| D031 | Desire ↔ Trait and Need ↔ Shard have defined counterparts; own Traits and Desires may overlap. | Answers 42–43. |
| D032 | Matching extends to traits on creatures, objects, and places; start with manageable interaction variety. | Answers 44–45. |
| D033 | Persistent geography has multiple repopulatable content slots; living occupants do not morph into replacements. | Answers 46–47. |
| D034 | Nodes keep current state; collective knowledge retains historical layers and supplies newest relevant knowledge. | Answers 48–49. |
| D035 | Exchanges can generate further Needs; dependency chains have no imposed depth cap. | Answers 49–50. |
| D036 | Character UI explains known state; choices/task acceptance occur through in-world actions, not an operational priority menu. | Answer 51. |
| D037 | Priority shifts world signs; no map arrows, quality tiers, or added reaction subsystem. | Answers 51–53. |
| D038 | Combat locks facing/positioning and uses timely actions, injuries, and disengagement. | Answer 54. |
| D039 | Broad functional injuries first; incapacity opens context-specific survival actions. | Answers 55–56. |
| D040 | AI creatures and enemies share state-dependent interaction rules. | Answer 57. |
| D041 | Shared humanoid baseline with elemental abilities; personal qualities and state modify actions. | Answers 58–59. |

Question numbers identify the question answered by the user's reply; the following assistant question may have the next number. Question 60 was resolved by the later playable-youth decision; Question 105 was unanswered at that historical snapshot and has since been resolved. The 2026-09-09 snapshot is retained in the backup archive rather than left as contradictory active rules.

## Decisions from answers 60–104

| ID | Current rule | Answers |
| --- | --- | --- |
| D042 | Play begins in youth with full elemental baseline; latent traits/desires stay hidden. | 60–61 |
| D043 | Ordinary participation develops youth; final coming-of-age quest/ritual reveals role and begins destiny. | 62–66 |
| D044 | Destiny expands then converges on one final purpose; four approaches remain switchable. | 67–68 |
| D045 | Quest complexity follows capabilities and combinations; no visible tiers or advance solution lists. | 69–71 |
| D046 | Failure never permanently closes a route; changed circumstances create Needs with possible solutions. | 72–74 |
| D047 | Unmet Desires prioritize local content or future newborn traits; no immediate social guarantee. | 75–76 |
| D048 | One Grimnir settlement first, with quiet dreamlike wonder and attention-based exploration. | 77–79 |
| D049 | Physical visible loadout; scarce crafted clothing; objects share the trait system. | 80–83 |
| D050 | Crafting is deterministic; independent applicable craft traits contribute together; quality is compatibility. | 84–87 |
| D051 | Anyone can use equipment; compatibility opens actions, not hidden success rolls. Skill tests vary by interaction. | 88–90 |
| D052 | Discovered interactions persist with explanations/blockers; undiscovered ones have no hints. Discovery through play. | 91–95 |
| D053 | Quests use current capabilities or supply attainable preparation. Cooperation primarily serves community tasks. | 96–97 |
| D054 | Tasks continuously follow settlement conditions; fountain provides suitable current/preparatory work. | 98–99 |
| D055 | UI is informational; direct world inputs accept tasks and equip items. | 100–101 |
| D056 | Unified Divine Orientation can follow current reality separately from knowledge; signs are subtle/intermittent. | 102–104 |

Question 105 is not a decision. Earlier contradictions remain only in historical source/backup records, not as active rules.




## September 11: answers 105–154

Current decisions: a 30-person settlement working target and tiny switchable placeholder prototype; large modular hex terrain; subtle nearby-opportunity guidance; four-part Grimnir nourishment and healthy resonant sleep; safe surface stone and background-only stonebound lore; parental Reproduction Destinies and support-gated youth; broad participation and unconditional care; seven modest elemental capacities; right-click movement, orbit camera, hold-focus dynamic radial and skill phase; exact matches, no Trait stacking, independent Needs with fitting acyclic fulfillment; task priority selection; repeating Destiny Quests culminating in communal Knots; milestone growth with restrained ordinary rewards; accurate observations and interaction-based provenance sharing; unidentified physical use allowed.

These supersede earlier contradictory entries rather than coexisting as alternate current rules. Detailed examples and status distinctions live in the relevant topic chapters. Question 155 was subsequently resolved; see the September 12 update.

Source: .


## September 14 — Grimnir lore integration boundaries

The user requested direct review of the MorkahjaWorldBuilding folder and Grimnir Works, and alignment of the Live RPG with Grimnir lore. The concept now includes a fuller people article, a dedicated architecture/daily-life chapter and distributed cultural detail.

| Source difference | Integrated treatment |
| --- | --- |
| Skyland civilization and existing inter-people diplomacy | Preserve as mature/future lore; first settlement stays surface-based and cultures initially separate. |
| Broad claim that stillness harms identity | Later Grimnir Works correction governs: sleep and surface rest are healthy; prolonged deep-earth living risks regression. |
| Parent-centered bath/nursery account | Keep two-creator origin and bath physiology; later communal shaping/upbringing remains current gameplay. |
| Craft clans, credit and reputation | Cultural history, not automatic classes, currency or global reputation. |
| Echoes of ancestors and practical Shard accuracy | Interpretive ancestral experience is distinct from accurately observed factual Shards; no instant Trait download. |
| Ritual memory preservation and Atranor | Cultural record can persist; final dissolution stays terminal. Ritual timing and echo status remain open. |
| Legacy choose-race/choose-role character creation | Different source game model; not imported into temporary inhabitation. |
| Historical twelve abilities / seven capacities / nine innate names | Preserve provenance and purposes; the selected twelve Live RPG functions remain the active content target. |
| Early starvation illustration | Current guaranteed basic sustenance governs; retain culinary and physiological detail. |

No worldbuilding source was modified. The source archive preserves both conversation decisions and older conflicting wording. Architectural adaptation examples are labeled rather than claimed as previously approved assets.

Sources and reconciliation: [Grimnir lore source archive](../../Reference_Material/Grimnir_Lore_2026-09-14/README.md).

## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.


## Current reconciliation — answers 203–251 (2026-09-13)

This section governs older entries where they conflict. Earlier dated entries are a decision history, not simultaneous current rules.

| Older rule or intermediate idea | Current replacement | Answers |
| --- | --- | --- |
| Role grants powers or filters Destiny | Actual Traits/capabilities govern; title is dynamic flair recognized at fountain | 203–207 |
| Inspect other people via public labels | Embodied clues, performed exchange, Recall Knowledge stone disk | 208–212 |
| Unlimited routine relationship transcript | Recent history plus lasting important facts; no deletion of functional knowledge or relationship level | 213–215 |
| Procedurally invented gameplay content | Hand-authored definitions, procedural selection/placement/composition | 216, 235–240 |
| Generic twelve / inspiration / flirt candidates | Twelve Grimnir-themed functions; replenish Essence and lasting body shaping selected | 217–221 |
| Random hit part; unspecified damage model | Player selects body part, timing execution, binary injury, no HP | 222–224 |
| Universal target-intent display | Separate learned attack-reading Trait | 225–226 |
| Vague/behavior-based Trait payout | One random unowned Trait per fully completed branch; general non-Trait fallback if exhausted | 226–232 |
| Automatically prioritize urgent Needs (233) | Highlight and let player move priority stone voluntarily (234) | 233–235 |
| Separate technical classes for every entity type | Common entity framework, separate permitted content pools | 236–240 |
| Separate persistent Desire system and quotas | Positive preference Traits plus temporary Needs | 238–240 |
| Full repeated interaction comparisons | Cache first comparison; category versions/flags refresh lazily on focus | 241–243 |
| Needs only tags or always bound exact items | Structured Needs; OR solutions; usually generic matching, exact identity when authored | 244–246 |
| Generate every missing solution when Need appears | Resolve/create at active fountain exchange, reuse valid free existing content | 247 |
| Move world quest objects into fallback rewards | Never relocate another pursued solution as a reward | 232 |
| Bypass information or force every new solution through an unknown holder | Fountain resolves location/solution Shard; ordinary history still contribution-based | 248–249 |
| Show unknown task requirements as already known | Dynamic checklist: acquire fountain information, then reveal learned requirements | 250–251 |

See [Needs and tasks](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md), [combat](../06_Gameplay/Combat_and_Injuries.md), [identity](../03_Characters/Identity_Traits_Desires_and_Needs.md) and [architecture](../09_Technical/Entities_Interactions_and_Content_Authoring.md). Defense charge/cooldown proposals and final content naming remain open, not silently selected.
