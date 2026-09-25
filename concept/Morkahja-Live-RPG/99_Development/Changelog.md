# Changelog

## 2026-09-23 — Milestone 3 readiness rulings

Before implementation, the Milestone 3 documents were checked against the approved loop. Four gaps were put to Alex. These answers are now the specification.

- **Activation.** When **Acquire a Stone Weapon** is the only task, it becomes the active task immediately and reserves a free `Rock + Shapeable`. Divine Orientation starts then. Selecting the Need opens the Destiny screen. That selection moves the priority stone only when another task is already selected. Receiving another task still does not replace the current one.
- **Replacement.** If the reserved rock stops being valid and no free shapeable rock remains, the new solution is placed into unused world-node content. The Memory Fountain does not create the object or a Shard. This supersedes the earlier line that the Fountain may create a replacement.
- **Which occupant.** That placement replaces the whole occupant of `node.village_001`, the stone container, with a shapeable rock. The container stays while any free rock still exists.
- **Blocking states.** Milestone 3 does not author an injury and does not move the priority stone because of one. The task system still has to allow the later rule: a negative state takes the stone only when it makes the current task impossible, and only then switches to the task that resolves that block.

## 2026-09-23 — Milestone 3 Need and Divine Orientation

Recorded the first Need → Task → Objective → Divine Orientation loop and Alex's follow-up rulings.

- Added [Milestone 3](Milestone_3_Need_and_Divine_Orientation.md): Need **Stone Weapon**, Common Task **Acquire a Stone Weapon**, reserved free `Rock + Shapeable` objective, dynamic checklist, and Ground Wind-Wave / Ground Glint signs toward its live position.
- **Destiny Quest** replaces Destiny Crest as the current name of the branching Destiny undertaking. Rings, Knot, and categories are unchanged. Historical records may still say Crest.
- A node can hold several replaceable occupants. Reserved task or quest objectives are not replaced. Unused content may be replaced in whole or only inside a container. First use a free thing already in the world; place at a node only when none remain.
- The player moves the priority stone. Important Needs are highlighted. She may keep going injured if the chosen task is still possible; a blocking state redirects. The readiness rulings above settle when the first task activates, who places a missing rock, which occupant is replaced, and that Milestone 3 does not yet move the stone for an injury.
- Destiny opens from Needs, a Destiny button, and later the silhouette. Echo Attunement stays in Milestone 4.

## 2026-09-22 — Character presentation and stone props

Implementation work in `game/` during this task:

### Khar-Morr idle repairs (earlier V3 export)

- Repaired V3 idle processing to retain natural pelvis movement while planting the feet and toes. Baked shared entry/exit poses for smoother transitions between its three standing idles, without replacing the existing character controller.
- Disabled the character's animation import optimizer to preserve the baked contacts. At verification, maximum imported foot/toe drift was approximately 0.56 mm, compared with roughly 17 cm in the worst original idle.
- Moved resting hands forward of the thighs with staggered heights, widened the straighter-arm pose, softened elbow bends and finger curl, and brought the neck/head posture closer to the walking reference.
- Preserved the user's sculpt, rig, materials, equipment attachment and Walk/Run source animation data during that repair.
- **Historical scope:** these repairs applied to `KharMorr3DV3`. The current project has subsequently moved to `KharMorr3DV4` and its authored rest clips, as documented in `docs/KHAR_MORR_MODEL.md`. The V3 contact measurements are not claims about the current V4 clips.

### Shapeable rock

- Replaced the prism placeholder with a single irregular, faceted stone boulder with a flat base, sized for the existing placement and occupancy.
- Added `assets/models/shapeable_rock.glb`, the editable Blender source and its rebuild script. Kept the rock's identity and Shape Weapon behavior intact.

### Stone container

- Replaced the chest placeholder with a smooth oval stone basin, a flowing root-like ground base, a hollow interior and a thick rounded stone-disc lid.
- Added jade crystal clusters at the two ends and a polished central gem in a rounded stone clasp.
- Added a subtle baked stone texture with soft mottling and mineral grain; kept the crystals and clasp gem polished. Retained the texture in the Blender source and rebuild workflow.
- Connected the lid presentation to the existing container opening/reveal flow. Pickup removes the claimed item from the container's remaining-content list, preventing later swaps from reopening it.
- **Final animation:** replaced the initial hinged version with a level sideways slide of 0.16 m: 0.85 seconds out, 0.30 seconds paused, and 0.85 seconds back. It returns automatically after two seconds rather than waiting for pickup. Quick pickup does not interrupt the return, and loading an already-revealed container does not replay the motion.
- Kept the existing interaction sequence: opening reveals the club beside the container, then the player picks it up. Lid motion creates no additional Shards or equipment actions.
- Added editable Blender sources, rebuild scripts, `stone_container_lid.gd`, integration notes in `docs/STONE_CONTAINER.md`, and focused container verification.

### Verification performed

- Reviewed Blender previews and imported the assets into Godot.
- V3 idle-contact and existing character integration checks passed at the time of those repairs.
- The simulation suite reported **392 passed, 0 failed** after the container integration.
- After the final slide revision, container checks passed for level translation, automatic return, no repeated opening, snapshot behavior, presentation/state separation, and quick pickup at 30, 60 and 144 fps. These are recorded results from this task, not a fresh verification of subsequent project changes.

## Echo Imprint batch and presentation

- Echo Imprint now transfers up to three eligible Shards in one success, still in insertion order, and still writes one shared event Shard.
- Milestone 1 camera starts closer; orbiting Khar-Morr hides the cursor. The temporary ground is a large hexagon.

## Destiny expansion, placement and orientation

- Established that every Destiny start (coming-of-age and each completed Knot) places the whole Crest through the Knot and adds exactly one matching puzzle-piece hexagon.
- Rings are 4, 8, 16, 8, 4 plus the Knot; Combat, Trickery, Aid and Social are categories. The new hexagon holds one objective from each ring and the Knot.
- Only player-inhabited lives start Crests. Leftovers are claimed only when no living Crest points at them, stay where they are, and become vacant if that Crest ends.
- Pickup now writes a Shard and replaces the previous pickup Shard for the same item. The Fountain still learns only by Echo Imprint.
- Divine Orientation always holds an angle toward the selected object through world signs. A moved object no longer requires a Fountain visit. A destroyed object may be replaced there. A separate Divine Intervention event is not used.

## Current title

The current title is **Ethera: The Stonewrought**. Ethera names the game; The Stonewrought describes the current Grimnir chapter. Morkahja remains the world. Earlier titles in source transcripts and dated records are historical wording. Existing folder names remain stable so saved paths and references continue to work.

## Technical architecture decisions

- Settled the runtime stack: Godot for presentation, a Rust game runtime for authoritative rules, RealmNode as a separate Rust crate for authority, validation and persistence. Authoritative GDScript is now explicitly temporary.
- Established that authoritative values use deterministic representations and that platform-dependent trigonometry may not reach hashed truth unquantized. Godot physics is not authoritative.
- Replaced the frame-dependent world clock with a fixed twenty-per-second simulation tick; world time is derived from the tick count.
- Drew the validation boundary at gameplay legality rather than human dexterity: actors submit timestamped input samples and the runtime calculates the score.
- Established the two speeds of truth for items and equipment, and the disconnect boundary at consequence commitment.
- Separated simulation fidelity from world progression: regions without players go dormant and resolve life abstractly rather than freezing.
- Established that hidden knowledge stays authoritative and clients receive only what their character is entitled to observe.
- Moved `RealmNode_Game-Native_Concept.md` into `09_Technical/` and linked it from the concept index, the persistence chapter and the technical foundation, so agents cannot miss it.

## Milestone 1 implementation decisions

- Resolved Echo Imprint's event recipients: both participants learn the new record. The earlier single-Shard count example is now source history; its "unavailable afterwards" outcome still holds.
- Left-click pickup walks Khar-Morr into reach before taking the item; a club already within reach is taken at once.
- Holding a radial open slows her pace, bringing the control table in line with the interaction chapter.
- Right-clicking during an authored approach abandons the round without creating an event Shard or a history entry.
- Updated Milestone 1, readiness, handoff, open questions, ideas and the answer-399 reconciliation accordingly.

## Agent instructions

Added Alex’s supplied AGENTS.md verbatim at the package root, linked it from the concept index and implementation handoff, and included it in the ZIP.

## 2026-09-21 — Build handoff and environment

- Added five main turns through answer 403 and the readiness recap; main archive now 438 turns.
- Set C for the character panel and exact clicked-item position for pickup swaps.
- Added environment, local-first architecture, implementation handoff and asset register.
- Incorporated continuous merged-stone architecture and the Ethera development naming structure.
- Recovered two recent Grimnir Works turns from its local log, archived supporting conversations and attachments, and verified the five Pictures references against local copies.
- Updated navigation, readiness, open questions and source history; packaged with a pre-update backup.

## 2026-09-21 — Milestones through answer 399

- Incorporated 53 new turns; full conversation now 433 turns with question 400 unanswered.
- Added dedicated Milestone 1, Shape Weapon and Echo Imprint/Attunement chapters; revised scope and readiness.
- Integrated blockers, inherent pickup/cyclic swapping, hover discovery, Shape Trace/Shard Fit, controls, model direction and Godot/Blender selection.
- Replaced conflicting current rules and preserved their history; retained unresolved event-recipient and input details.
- Archived all five supplied images, exact source messages, raw pages and per-turn coverage. Refreshed navigation and open questions; prepared the updated ZIP and a pre-update backup.

## 2026-09-20 — first-playable specification review

Recovered the agreed first-playable experience from answers 106–111 and compared its requirements with the Live RPG concept. Added the readiness matrix and acceptance checklist, integrated 18 new main turns through answer 358, added reusable skill-phase taxonomy and Cradle creation/naming, preserved the 72-phase draft separately, and updated source coverage, open questions and navigation. This was a design/specification comparison; no executable prototype was playtested. Previous concept backed up and ZIP rebuilt after validation.

## 2026-09-18 — complete through answer 341

Integrated 100 new main-discussion turns after answer 251 and reviewed 13 related turns. Added dedicated Mountain Strike, archival-stone/Echo-Cradle and Shard-record chapters. Updated interaction naming, binary combat, tasks, 100-entry history, shared event references, retention, physical archival flows, item requirements, interface and technical dependencies. Replaced superseded current rules and refreshed open questions, glossary, navigation and per-turn coverage. Preserved exact sources and the preceding saved concept; rebuilt and verified the ZIP. Question 342 remains unanswered.

## 2026-09-15 — editorial cleanup

Reworked the main articles into continuous subject-based descriptions; consolidated repeated examples and removed source blocks and dated update labels from the reading path. Rebuilt navigation, separated unresolved choices and added an archive index. Preserved all 41 earlier documents verbatim alongside the unchanged source collection. Updated the ZIP after checking files and links.

## 2026-09-14 — Grimnir cultural foundation

Reviewed the main Grimnir article, related worldbuilding entries, all 19 turns of Grimnir Works and the knowledge-hubs discussion. Preserved twelve exact article snapshots and both conversations with provenance. Expanded the Grimnir article; added architecture/daily life; enriched terminology, gods, material culture, memory, care and future Skyland context. Explicitly reconciled rest, family, role/economy, Shard/echo and death differences with current RPG rules. Main numbered source remains through answer 251. Updated navigation, open questions and ZIP; prior concept backed up before publication.

## 2026-09-13 — complete through answer 251

Integrated all 49 new turns (answers 203–251), bringing the full source snapshot to 262 turns. Question 252 remains unanswered. Reconciled role powers, preference/Desire migration, branch rewards, chosen body-part combat, voluntary priority and deferred Need solution generation. Added dedicated chapters for the first twelve Grimnir interactions, Needs/tasks/solution lifecycle, and entity/interaction/content architecture. Preserved exact new user detail at its primary topic home and full user/assistant source turns. Updated terminology, navigation, open questions and decision history. The ZIP includes 40 concept Markdown documents, the source transcript and two supplied references. A verified pre-update backup preserves prior files.


## 2026-09-12 — answers 155–202

Integrated all 49 unarchived turns after answer 154. Added dedicated States/Buffs and World Persistence chapters; updated item crafting/repair, community AI and growth, relationships, communal creation, Atranor, queues, guidance, and the stone-board interface. Replaced conflicting earlier rules, retained detailed examples and linked original wording, refreshed open questions and all source coverage. Full source total: 213 turns. Question 203 remains unanswered. The preceding archive is backed up before publication.


## 2026-09-11 — complete new discussion integration

Integrated 51 previously unarchived user/assistant turns after answer 104, through answer 154 and the unanswered Question 155. The cutoff is the archived turn ID, not an approximate clock time.

Added a dedicated Grimnir physiology/care chapter; expanded family development, elemental abilities, participation, terrain, interaction controls, guidance, item knowledge, and first-playable detail. Rewrote current Destiny rules for repeated Crests/Knots, refined rewards and fulfillment safety, and replaced conflicting task-panel wording. Updated open questions, terminology, source coverage, and index. Preserved both supplied attachments and the complete new dialogue, including illustrations and proposals. Back up the preceding archive before publication.

Source: .


## 2026-09-10 — full-chat consolidation and example review

- Reviewed the complete 113-turn design conversation through answer 104; no newer message was present at retrieval.
- Reorganized 64 Markdown files into 33 fuller documents, with explicit Knowledge and Items folders and a clearly named World Nodes chapter.
- Consolidated related systems, removed exact repeated paragraphs and repetitive export footers, and rewrote links to the new homes.
- Added 70 worked examples beside their topics, with source-turn references and status labels.
- Added a coverage map for all 113 turns and a migration map for every previous topic file.
- Kept original conversation wording and the previous folder version in the archive/backup. Preserved current decisions, open questions, and rejected ideas distinctly.

## Previous export history

## 2026-09-10 — second update, answers 60–104

- Archived 45 new turns after the previous exact message boundary, from 04:19 to 09:26 Europe/Stockholm, rather than guessing a rolling five-hour cutoff.
- Replaced early-childhood play and timed adulthood with playable youth, participation, and a coming-of-age rite.
- Integrated converging destiny branches, hidden complexity, recoverable failure, solvable Needs, and local Desire generation priority.
- Set the first playable focus to one Grimnir settlement.
- Added physical carrying, deterministic horizontal crafting, skill-based execution, and interaction discovery documentation.
- Integrated continuously generated cooperative community tasks and direct in-world acceptance.
- Replaced operational priority menus with informational UI and distinguished Divine Orientation from mortal knowledge.
- Updated affected existing pages and added five focused pages; refreshed source archive, README, decisions, and open questions.
- Preserved a backup of the preceding 59-page concept before publication.

## 2026-09-10 — knowledge, desires, interaction, nodes, and combat

- Incorporated 29 new user/assistant turns from 2026-09-10 in Europe/Stockholm, covering interview answers 31–59. Latest retrieved answer: elemental baseline embodiment. Question 60 remains unanswered.
- Replaced shard burden/capacity proposals with unrestricted functional knowledge collection, local interaction-based updates, personal replacement of obsolete information, and retained collective history.
- Added Desires, Needs, and their paired interaction rules, positive relationship development, and the 27-desire origin target.
- Defined persistent node geography and multiple content slots, with history carried in Shards.
- Added exchange-generated Needs and uncapped dependency chains; integrated the character-screen priority system and simple in-world guidance.
- Added engaged combat, broad injuries, survival interactions, AI symmetry, and shared/elemental baseline actions.
- Added eight dedicated topic files and updated affected existing documents, terminology, decisions, open questions, and README links.
- Extended the source conversation archive and regenerated the ZIP. Saved a dated backup of the preceding local concept before applying this update.

## 2026-09-09 — complete concept consolidation

- Created the exact requested structure: README plus 50 topic documents across nine folders.
- Retrieved the complete available “Morkahja live RPG” conversation through all history pages and consulted “Create Morkahja Files” for the intended documentation structure.
- Replaced the initial PDF-only provisional drafts with the actual established game concept.
- Preserved later corrections over earlier ideas, including adulthood timing, no voice/text chat, and follow-only spectators.
- Preserved the supplied PDF's world and peoples lore without changing synced source files.
- Kept broader-world city descriptions distinct from unresolved ancient-era adaptations.
- Saved the complete retrieved design conversation separately as Morkahja-Concept-Sources.md so original wording and assistant interpretations remain reviewable.
- Packaged the topic folder and source transcript together in a ZIP.

## Source scope

The main concept source is the project conversation “Morkahja live RPG.” “Create Morkahja Files” supplies the organizational intent. The local synced source directory contains “Morkahja - World and Peoples.pdf.”

The RPG conversation also includes a user-pasted knowledge-system extract citing the separate worldbuilding project's race notes. This archive preserves that contributed material, without claiming to export the entire separate worldbuilding project.

Earlier assistant-generated interpretations are retained in the source transcript, but only supported design choices are consolidated into the topic documents. Open questions remain explicit.



## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.
