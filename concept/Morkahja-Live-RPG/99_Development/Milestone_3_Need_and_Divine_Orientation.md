# Milestone 3: Need and Divine Orientation

Add the first functioning **Need → Task → Objective → Divine Orientation → Completion** loop.

This milestone proves that a character can develop a Need, pursue it through the Destiny and Common Task system, receive subtle directional guidance toward a real solution in the world, and complete the task because the required world condition actually becomes true.

The first test reuses systems already implemented. The full Destiny Quest board does not need to operate yet. Only the **Common Task area** needs to function. The Destiny screen may remain simple and primarily text-based.

Echo Attunement stays in Milestone 4.

See [Needs and Tasks](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md), [World Nodes](../01_World/World_Nodes_and_Generation.md), and [Interface and Divine Orientation](../08_Presentation/Interface_and_Divine_Orientation.md).

## Test Need

**Need: Stone Weapon**

The Need exists while Khar-Morr does not possess an item with the Trait **Stone Weapon**. The Need disappears when that condition becomes true.

The Need does not care how the condition was achieved. If she shapes a weapon from the reserved objective, picks up a Stone Weapon somewhere else, receives one through another valid source, or otherwise legitimately obtains one, the Need completes.

She begins Milestone 1 with an empty Small Weapon slot, so a fresh start has this Need. If she already holds a Stone Weapon, the Need is not present.

## Task eligibility

Tasks may only be generated for things the character is fundamentally capable of doing.

Khar-Morr already has **Weapon Shaping**, so **Acquire a Stone Weapon** is a valid task for her. A character who does not possess the permanent capability required to complete a task should not receive that task.

Temporary states are different. An injury or another negative state may temporarily block something the character normally can do without removing their underlying capability.

## Character panel and Destiny screen

The Character Panel contains a **Needs** section. For this milestone it shows **Stone Weapon**.

When **Acquire a Stone Weapon** is the only task, it is already the active task. The rock is reserved then, and Divine Orientation has already started. Selecting the Need opens the Destiny screen and shows that task. It places the priority stone on the matching Common Task only when another task is already selected.

The same Destiny screen also opens from a **Destiny** button on the character panel. The later silhouette click opens that same view. There is no silhouette yet, so Milestone 3 uses the button and the Needs list. The button opens the screen. It does not move the stone.

## Common Task and dynamic checklist

**Acquire a Stone Weapon**

The task presents the goal. A **dynamic checklist** shows requirements the character currently knows. Unknown requirements stay hidden until Fountain information or another genuine Shard reveals them. The checklist does not list system-only solution knowledge as if Khar-Morr already knew it.

The authored task definition knows what constitutes a valid solution so the task remains solvable. That is not automatically a Shard, and it is not a quest recipe on the board.

For this task, a valid world solution is an available entity satisfying the requirements needed for **Shape Weapon**, including **Rock** and **Shapeable**.

The player can still complete the Need by any legitimate route. The checklist suggests order around what is already known and already satisfied. It does not prescribe mandatory steps.

## Active task and blocking states

Important Needs are highlighted. The player moves the priority stone.

If at least one task exists, there is normally always one active marked task. The sole task is marked as soon as it exists, and its physical objective is reserved then. Receiving another task does not automatically replace the current active task.

Milestone 3 does not author an injury and does not move the priority stone because of one. The selection model still has to allow the later rule. A negative state may take the stone only when it makes the current task impossible, and only then switch to the task that resolves that block. When that block is gone, the player can return the stone to the earlier task. This milestone does not build that injury, or a broader priority system.

## Shards and mortal knowledge

Shards represent actual knowledge learned through the world. The task system must not create a Shard merely to make progression easier.

The Memory Fountain does not invent knowledge. It only stores and redistributes Shards that have genuinely entered the knowledge system.

If Khar-Morr already possesses relevant knowledge, that knowledge may help determine the useful objective and may appear on the checklist. If neither she nor the Fountain possesses useful knowledge, no fake knowledge is generated. Divine Orientation can still hold an angle toward the reserved objective.

## Objective selection

When an active task requires a physical objective, the system searches for a **valid free solution**: a valid solution that is not already reserved as another character's active objective.

Selection order:

1. Search the character's current hex for valid free solutions.
2. If one or more exist, select one randomly.
3. If none exist, search the rest of the currently existing world.
4. Select a random valid free solution there.
5. If no valid free solution exists anywhere, place one through the ordinary world-node content system. It does not appear beside the player. The Memory Fountain does not create the object or a Shard.

The starting hex already contains authored shapeable rocks, so this test normally reserves one of those. Placement at a node is only for when every usable stone is already gone.

A node can hold several replaceable occupants. Content that is an objective for any task or Destiny Quest is not replaced. Content unused by any task or quest may be replaced: either what is inside a container, or the whole occupant. The replacement can be another container, a creature, a climbable tree, or other fitting authored content.

For this task, that fallback replaces the **whole occupant** of `node.village_001`. That occupant is the stone container, and the replacement is a shapeable rock in its place. Leave the container alone while any free rock remains.

That reserved entity becomes the active objective. For Milestone 3 this is normally a specific entity with **Rock** and **Shapeable**.

## Objective marker

The chosen entity receives a temporary character-specific Objective Trait. Conceptually: **Objective: Khar-Morr**. The task also keeps a reference to the target entity ID.

Keeping the objective inside the normal Trait system lets it participate in later gameplay. Another character could theoretically detect that an item is Khar-Morr's objective. That future interaction is outside Milestone 3.

## Moving and invalid objectives

Divine Orientation tracks the actual objective entity, not the coordinates where it was originally selected. If the objective moves, is carried, or otherwise changes position while remaining valid, later cues follow its current world position. No new objective is selected merely because the entity moved.

If the selected objective stops being a valid solution — for example because a consumable objective is used and disappears:

1. The old objective reservation is removed.
2. The free-solution search runs again.
3. Another valid free solution is selected or, if none remain, placed at an appropriate world node.
4. The Objective Trait is assigned to the replacement.
5. Divine Orientation begins tracking the replacement.

## Divine Orientation cues

Divine Orientation is the game's general replacement for conventional quest navigation. It works whether or not the character possesses a relevant Shard.

**Shards represent what the character knows.** Divine Orientation tells the player which direction the currently selected objective lies.

The game does not use quest arrows, minimap quest markers, compass markers, GPS-like navigation, or permanent glowing paths. It communicates through intermittent environmental signs.

Milestone 3 implements two signs:

### Ground Wind-Wave

A subtle stylized wave travels across the ground in the direction of the current objective. The effect should fit the low-poly visual language. It can be produced through a shader, decal, projected texture, or other Godot-side visual effect. It does not require dense animated grass.

### Ground Glint

A small, brief spark or light appears farther ahead along the direction toward the current objective. It should remain subtle and low-stimulation. It is not a permanent marker.

Bird guidance remains later work.

## Cue scheduling

For prototype testing, approximately every 10 seconds Divine Orientation produces one cue. Each cue event randomly chooses Ground Wind-Wave or Ground Glint. Only one occurs per cue event.

The exact timing, size, distance, brightness, and visual treatment are tuning values rather than fixed design requirements.

## Gameplay loop

1. Khar-Morr lacks a Stone Weapon. The Character Panel displays **Need: Stone Weapon**.
2. **Acquire a Stone Weapon** is her only task, so it becomes active immediately. A valid free **Rock + Shapeable** entity is selected and reserved for her. Divine Orientation starts.
3. The player may select the Need, or press Destiny. The Destiny screen opens on that already active task. The dynamic checklist shows the goal and any already-known requirements. Selecting the Need moves the priority stone only when another task already holds it.
4. At the prototype interval, the system randomly produces either a Ground Wind-Wave or a Ground Glint toward the current position of that objective.
5. The player follows the signs or finds another legitimate route.
6. At a valid rock, the normal interaction system reveals **Shape Weapon** because its requirements are satisfied.
7. Existing Milestone 1 Shape Weapon behavior applies: Shape Trace, consume the rock's current manifestation, create and equip a Stone Club, write the normal event Shard.
8. She now possesses an entity with **Stone Weapon**.
9. The Need is removed. The Common Task completes and leaves the task interface. The Objective Trait is removed. Divine Orientation stops because the completed task no longer has an active objective.

## Alternate completion

The task is not a scripted sequence. The final world condition is authoritative.

If she obtains a Stone Weapon through another legitimate route before reaching the reserved rock:

- the Need immediately completes
- the task completes
- the reserved objective is released
- Divine Orientation stops

The player is never required to follow the suggested route if reality has already satisfied the Need.

**Tasks guide toward outcomes. They do not prescribe mandatory quest steps.**

## Out of scope

Do not require: a second Grimnir, spectator switching, social AI, the complete Destiny Quest board, complex task chains, the Stone Circle / Swiftness Need, food Needs, social Needs, archival stones, Echo Cradle, Echo Attunement, bird guidance, map, compass, persistence, RealmNode / P2P networking, or a broad autonomous task-priority system.

The Stone Circle / Swiftness Need is a useful later test because it can exercise a more complex multi-stage objective structure.

## Acceptance checks

1. Khar-Morr lacks a Stone Weapon and receives **Need: Stone Weapon**.
2. The Need appears in the Character Panel and is highlighted as important if authored that way.
3. While it is the only task, **Acquire a Stone Weapon** is already active and a rock is already reserved before Destiny is opened. Selecting the Need opens the Destiny screen. It moves the priority stone only when another task is already selected.
4. The Destiny button opens the same screen and does not move the stone.
5. The Common Task shows a dynamic checklist: the goal and currently known requirements, not hidden system-only solution knowledge.
6. A valid free `Rock + Shapeable` entity is selected and reserved.
7. Divine Orientation periodically produces either a Ground Wind-Wave or Ground Glint toward its live position.
8. Moving the objective causes later cues to follow its new position.
9. Invalidating or consuming the objective causes another valid free solution to be selected. If none remain, the whole occupant of `node.village_001` is replaced by a shapeable rock. The container stays while a free rock exists. The Fountain does not create the replacement.
10. She can reach a valid rock and use the existing **Shape Weapon** interaction.
11. Acquiring any valid `Stone Weapon` completes the Need regardless of route.
12. The Common Task disappears/completes.
13. The objective reservation is removed.
14. Divine Orientation stops for that task.
15. Milestone 3 does not author an injury and does not move the stone because of one. The selection model can later let a negative state take the stone only when the current task is impossible, and only then switch to the task that resolves that block.

## Implementation sequence

Implementation belongs in `game/`. Keep new game rules in authored data and the command/query boundary. Presentation draws what the simulation already decided. There is no `Crest` identifier in the current game code; new ids use **quest**, **task**, and **need**.

1. **Authored data.** Add Need `need.stone_weapon` (owner condition: no possessed item with `Stone Weapon`; important) and Common Task `task.acquire_stone_weapon` (requires `Weapon Shaping`; completion: possess `Stone Weapon`; hidden valid solution: manifested `Rock` + `Shapeable`). Add the temporary Objective Trait family. Do not invent Echo Attunement or Destiny-board quests.
2. **Need and task state.** On load and whenever inventory, equipment, traits, or manifestation change, refresh Khar-Morr's Needs and eligible Common Tasks. `query_panel` already returns `needs`; serve real Need records, plus tasks, the active task, the checklist the character currently knows, and the reserved objective id.
3. **Player commands.** On refresh, if tasks exist and none is selected, mark the sole task and reserve its objective. `select_need` opens the Destiny screen. It moves the priority stone only when a different task is already active. A separate activate-task command lets the Destiny screen move the stone without inventing an operational priority menu. Receiving another task does not steal the stone. The Destiny button opens the screen and does not move the stone.
4. **Objective reservation.** When the Stone Weapon task becomes active, search current hex, then the existing world, for a free valid rock. Reserve it with `Objective: Khar-Morr` and store the entity id. Track that entity's live position. If it stops being valid, release and search again. Only if no free rock remains, replace the whole occupant of `node.village_001` with a manifested `Rock` + `Shapeable`. Do not place beside the player. Do not replace an occupant that is already a task or quest objective. Leave that container alone while free rocks exist. The Fountain creates neither the object nor a Shard.
5. **Later blocking states.** Do not author an injury, and do not move the stone for one, in this milestone. Keep selection able to accept the later rule: a negative state may take the stone only when the active task is impossible, and only onto the task that resolves that block.
6. **Destiny presentation.** Add a Destiny button on the character panel. Clicking Needs or that button opens a simple text Destiny screen: Common Task area, priority stone, dynamic checklist. No Destiny Quest board yet. No silhouette yet.
7. **Divine Orientation.** Simulation exposes the active objective's current bearing and position. Presentation plays one cue about every ten seconds, randomly Ground Wind-Wave or Ground Glint, toward that live position. Tuning stays in data or presentation constants. No map, compass, arrow, or bird.
8. **Completion.** Any legitimate `Stone Weapon` in her possession ends the Need, completes the task, clears the Objective Trait, and stops cues. Shape Weapon stays the existing Milestone 1 interaction.
9. **Tests.** Headless checks for Need appear/disappear, the sole task activating and reserving without a click, eligibility without Weapon Shaping, reservation and live tracking, invalid-objective reselect, container replacement only when no free rock remains, alternate completion by pickup, checklist hiding unknown solution knowledge, and cue scheduling. Do not require an injury. Then play the village loop.
10. **Cleanup.** Remove any temporary debug overlay that duplicates the Destiny screen. Update game-repo technical notes only for the new commands and queries.

Cue dimensions, glint distance, exact timing, visual intensity, and search performance are playtest tuning, not further design blockers.
