# Architecture

Read `AGENTS.md` and the concept documents before changing gameplay behavior. This file records **technical** structure for Milestone 1. It does not add game rules.

Canonical concept: `C:/Users/Babun/Documents/Morkahja/Morkahja-Live-RPG-Concept/Morkahja-Live-RPG/README.md`

Architecture that governs this file: `Morkahja-Live-RPG/09_Technical/RealmNode_Game-Native_Concept.md` and the settled decisions in `99_Development/RealmNode_and_Technical_Foundation.md`.

## The target runtime, and what this code is

The authoritative runtime will be Rust, in its own crate beside `realmnode-core`, so a validator can execute game rules without launching Godot.

**The GDScript under `scripts/simulation/` is a temporary stand-in for that runtime.** Treat it as disposable. Two consequences bind current work:

- Anything that describes a game rule belongs in authored data, or in deterministic logic behind the command/query boundary. Do not entangle new rules with Godot types or node lifetimes.
- Presentation may not reach into runtime state. It talks through `apply()` and the `query_*` functions only. That boundary is what makes the eventual swap cheap, and it is enforced by the fact that nothing under `scripts/presentation/` names `simulation.world`, `simulation.catalog` or `simulation.evaluator`.

## Split of work

| Layer | Owns | Does not own |
| --- | --- | --- |
| Authored JSON in `data/` | Stable ids, requirement groups, skill-phase parameters, result lists, event-record recipients, Milestone 1 starting entities | Scene graphs, meshes, animation |
| `EtheraWorld` | All authoritative state, including in-flight rounds, walk motors, focus holds, transactions and snapshots | Rule evaluation, command handling |
| `EtheraResults` | Interpreting authored `selection`, `results` and `record` | Knowing which interaction it is running |
| `EtheraSimulation` | Command handling, availability, fixed-step integration, skill success/failure, the command journal | Camera, meshes, navmesh, gold skill graphics |
| Presentation | Input mapping into commands, rendering `query_world_view()`, interpolation, radial/panel/skill overlays | Inventing world results, reading runtime internals |
| Blender / `art/` | Editable sources exported to `assets/models/*.glb` | Gameplay rules |

Later RealmNode work wraps `EtheraSimulation.apply(command)` and replicates `EtheraWorld`. Because in-flight state lives in the world rather than on the simulation object, a snapshot or a handoff carries an interaction that is still running.

## Determinism

Presentation may use ordinary floats. Authoritative state may not depend on platform-sensitive floating point.

- **The clock is a fixed tick.** `EtheraWorld.TICKS_PER_SECOND` is 20 and `world_time_ms` is derived from `tick`. The `tick` command advances whole ticks; it takes no frame delta. Presentation accumulates real time and converts it with `EtheraWorld.ticks_available()`, keeping the remainder. A stall drops surplus time rather than fast-forwarding, capped by `MAX_TICKS_PER_FRAME`.
- **Stored values snap to a grid.** `EtheraWorld.set_position()` quantizes position to `POSITION_QUANTUM` and yaw to `ANGLE_QUANTUM`. Walk speed snaps to `SPEED_QUANTUM`. The Shard Fit rotation the click reads snaps to `DEGREE_QUANTUM`. The quanta are powers of two, so the snapping itself is exact in binary floating point. This is what keeps `sin()` and `atan2()` differences between platforms out of stored state. `sqrt` and division are IEEE-exact and need no treatment.
- **Godot physics is not authoritative.** It is used for mouse picking only.

Integers or fixed-point remain the target representation in the Rust runtime; quantization is the prototype's equivalent guarantee.

## Command boundary

Presentation and tests send dictionaries:

| `type` | Fields | Effect |
| --- | --- | --- |
| `tick` | `ticks` (default 1) | Advances that many fixed authoritative ticks: world time, walking, timed states, and the active skill timer |
| `set_walk_destination` | `x`, `y`, `z`, optional `entity_id`, optional `gait` (`walk` or `run`) | Right-click walking on ground or objects; a right double-click sends `run`. Does not interact. Abandons an unfinished approach; ignored once a skill phase runs |
| `stop_walking` | optional `entity_id` | Clears a destination, abandoning an unfinished approach |
| `set_focus_hold` | `held`, optional `entity_id` | Presentation reports that the radial is held open; the actor's pace cap drops |
| `pickup_item` | `item_id`, optional `actor_id` | Inherent pickup/swap. Walks into reach first. Writes a pickup Shard known only by the picker; a later pickup of the same item replaces that Shard |
| `open_container` | `target_id`, optional `actor_id` | Inherent open of an unlocked closed container. Writes a discovery Shard known only by the opener and manifests the contents |
| `observe_target` | `target_id`, optional `actor_id` | Inherent place discovery: in-range hover of a landmark with `discovery_radius` |
| `begin_interaction` | `target_id`, `interaction_id` | Starts authored approach, then the skill phase |
| `skill_pointer` | `x`, `y` in 0–1 skill space | Hits Shape Trace checkpoints; positions Shard Fit |
| `skill_click` | none | Confirms Shape Trace or attempts Shard Fit |
| `select_need` | `need_id`, optional `actor_id` | Opens the matching Common Task onto the priority stone only when another task is already selected. The sole task is already active. |
| `activate_task` | `task_id`, optional `actor_id` | Moves the priority stone to one of the character's tasks. Receiving a new task does not do this by itself. |

Queries: `query_available_interactions`, `query_hover`, `query_inhabited_id`, `query_panel`, `query_skill`, `query_dev_log(limit)`, `query_recent_interactions`, `query_world_view`, `query_orientation`, `resolve_shard`. Snapshots: `create_snapshot`, `state_hash`, `restore_snapshot`, `replay`.

`query_panel()` for the inhabited character includes real Need records, Common Tasks, the active task, the checklist of requirements she already knows, and the reserved objective id. `query_orientation()` is that objective's live position and bearing. It is empty when she has no active objective. Another character's panel does not receive her checklist or bearing.

`query_skill()` returns the running round plus a `phase` block carrying the authored shape presentation needs to draw it, so the overlay never reads the content catalog. The round's own stage is `stage` (`approaching` or `skill`); `phase` is always the authored skill-phase definition.

Returned events use `event_time` for the envelope timestamp so a payload's own `world_time` — a Shard's original timestamp — is never overwritten. The development log is capped at `EtheraWorld.DEV_LOG_LIMIT`; pass a limit to `query_dev_log` instead of copying the whole log each frame. Need, task, and objective lines are written there when those sets change. `development_note` appends an observation such as a Divine Orientation sign. It is not a command and is not journaled.

## Authored results

`_succeed_skill` does not branch on interaction id. `data/interactions.json` names a `selection` (optional), a `results` list and a `record`. `EtheraResults` interprets those. An unrecognized type, a missing results list, or a list that cannot be applied fails the round closed and writes nothing. A successful action still produces exactly one event Shard after the final world result, granted to the roles in `record.known_by`.

Skill phases declare a `challenge`. The runtime dispatches on that, never on a phase id, so a new phase of an existing kind is content.

## Snapshots, hashes and the command journal

`EtheraWorld.serialize()` is everything a node needs to continue this world, including an interaction still in progress. The development log is an observation aid and is excluded. `hash_state()` SHA-256s a canonical encoding with sorted keys; ints and whole floats hash identically so a JSON round-trip does not change the fingerprint. `restore_snapshot` resumes from that dictionary and clears the availability cache.

`EtheraSimulation.command_log` records every command with the tick it arrived. It is how this node got here, not part of the hashed world. `replay()` applies a journal onto a fresh simulation. A skill phase also keeps timestamped cursor samples on `active_round.inputs`. The actor never reports a score; the runtime calculates the outcome from those samples.

## Item transactions

Creating, transferring or changing ownership of an item is immediate to the player and committed underneath in the same apply. Locally the same node is the authority, so the stored status is `committed` rather than left pending. The transaction record and `commit_status` on the item are the seam a later validator uses for `PENDING → VALIDATING → COMMITTED`. Reconciliation on failed remote validation is not implemented because there is no remote validator yet.

## What crosses to a client

Hidden knowledge is authoritative state. `query_panel()` serves a character's own Shards and discovered interactions only when the id is the inhabited character; `knowledge_visible` reports which case the caller got. An interaction is offered from authored requirements, whether or not she has used it. Completing it once adds it to `known_interaction_ids` and keeps it there. The panel record includes the requirement phrases. Other entities, including the Memory Fountain, are described by what an onlooker could see.

The evaluator still reads the Fountain's full contents when it decides availability, because it runs inside the runtime. The restriction is on what leaves it.

## Entity and Shard identity

Authored entities keep their JSON ids (`entity.khar_morr`, `entity.shapeable_rock`, …). Runtime clubs and Shards receive `*.runtime.N` ids.

A consumed rock **keeps the same entity id**. `manifested` becomes false. Shape Weapon Shards continue to name that id as target and `place.village_center` as place. This is the implementation answer to manifestation identity; later reuse/placement must not change those historical fields.

## Matching

Requirement groups are AND inside, OR across groups. After a match, negative-state blocker lists apply. Echo Imprint queries the actor’s known Shard ids against target membership (`EtheraEvaluator.eligible_shards`, insertion order, up to three). Availability cache keys are actor+target and invalidate on trait, inventory, needs, shards, states, injuries, relationships, and manifestation versions.

Walking and pickup are inherent and do not use the radial. Hold-to-radial slots are circles until the pointer sits on one; then the interaction name appears outside that slot in a frame sized to that name. The focused object's authored name sits just above the hub.

Place discovery is also inherent. A manifested landmark with `discovery_radius` writes one Discovery Shard when the inhabited character is inside that radius **and** hovers the landmark (`observe_target`). The presentation eye aims at the landmark's height and needs line of sight; it does not show through terrain. The Shard uses Action Discovery, Reaction None, Result Discovered, the landmark as target, and the landmark’s `place_id`. Only that character learns it, once per object id. The Fountain still receives it only through Echo Imprint. The visible aura hides after that discovery.

## Movement rounds

`EtheraWorld.active_round` owns an actor's movement from `begin_interaction` until the round resolves. While its `stage` is `approaching`, a new walk destination or a stop abandons the round: no Shard, no history entry, and `skill_ended` reports `outcome: cancelled`. Once the stage is `skill`, walk commands are ignored so the challenge cannot be walked out of.

This is also the disconnect rule. A round abandoned before its consequence commits leaves nothing behind; a committed consequence is never reversed. When RealmNode arrives, a vanished actor cancels the unfinished round through the same path.

Pickup uses `EtheraWorld.walk_motor` with reason `pickup`. It walks to `pickup_approach_distance` from the item and takes it on arrival, re-checking compatibility at that moment. A click already inside `pickup_reach` skips the walk. Because a pickup walk is an ordinary destination and not a round, right-click simply replaces it.

Manifested world objects occupy space. Fountain, rock, stone containers, landmarks and other characters have an `occupancy` radius. Authored hex scenery that is not a simulation entity — bushes, stone benches, Echo Cradles, burrows, and the town hall — occupies through `place.blockers` the same way. Bushes, benches, and burrows use rock-sized disks from the sculpt. Echo Cradles use Fountain-kind occupancy and pick cylinders sized to each instance, without inventing cradle interactions. The town hall occupies as wall disks from the sculpt so the door and room stay walkable. The gap between double walls is sealed so it is not a path. The floor is not occupancy; presentation seats feet on that floor, not the dirt under it. Grass patches are their own kind and occupy nothing, so a walk goes through them. Ground steeper than `walkable_slope_degrees` (50, the vanilla player line) is also a solid: a click through that face walks up to it and stops. A walk whose straight line hits an occupancy disk is planned with deterministic grid A* (`EtheraWorld.find_walk_path`) using that occupancy plus `walk_clearance`. Right-click ground walks go up to the first solid, then grid around an occupancy disk. They do not invent a path around a hillside. Interaction, pickup and open walks go to their authored stand-off and stop there, so she does not close in and then snap back to the ring. Opening a grass patch uses that same stand-off even though walking can go through the tuft. A right-click on an object walks to a stand-off on the actor's current side, just before the item or occupancy, and does not interact. Authored interactions also approach from the side the actor is already on, at that interaction's `approach.distance` ring. Approach, pickup ignore the target's own occupancy. Opening a stone container does not: it stands off occupancy plus `object_stand_off`, matching a right-click walk. Environment GLBs get mesh collision for picking. The Memory Fountain pick follows its sculpt, so visible objects beside the basin can be clicked. Godot physics still does not decide whether a step is legal. Irregular environment meshes are later work; they are not this occupancy path.

## Presentation smoothing

The authoritative pose updates 20 times a second. `_sync_views()` eases each view node toward it at `VIEW_FOLLOW_RATE` and snaps when the gap exceeds `VIEW_SNAP_DISTANCE`, so a respawn or a teleport does not glide across the map. Loose views take their displayed Y from streamed hex terrain, or from a town hall floor when they are standing on one. The starting tile is the authored 256 m pointy-top hex `hex.grassland.a`. Permanent objects placed on that hex keep their scene transforms; simulation still owns identity and state. The Memory Fountain and the stone circle both sit on that hex. Simulation `y` remains 0. Directional shadows use camera-relative PSSM splits; hex size does not set the shadow distance. Day and night are a ten-minute presentation cycle with a visible sun; they do not advance simulation time. The simulation world itself is already one continuous plane with no loading screens. Growing the playable area means adding hexes to the layout and streaming those scenes. See `docs/WORLD_TERRAIN.md`. Seeded grass patches and authored hex grass are kind `grass`; they open like containers from stand-off and their five-blade bundles occupy `slot.herb`, but they do not occupy walking space. Seeded and authored hex rocks are ordinary manifested shapeable entities. The herb slot is independent of Small Weapon. Item pickup and swap play a short presentation handoff (`EtheraItemHandoff`) from the previous visual pose to the new rest pose; the last third of a drop is a scripted fall and bounce. The camera follows the smoothed view rather than the authoritative pose. Equipped items count as the inhabited body for orbit clicks and do not keep their own pick volume while carried. The orbit pick is larger than her silhouette; a loose item, swap, or open along that same ray still wins, so she is not in the way of a club on the floor beside her. A look-ray against each visible solid stops a zoom-out on the sculpt, not a column of air above it. Grass patches do not block the camera. The Memory Fountain and stone circle picks follow their meshes, so the empty air above or through a ring can be clicked. Smoothing is presentation-only and never feeds back into state.

## Echo Imprint event recipients

Success shares up to **three** existing contributed Shard ids with the Fountain and **creates** a new event Shard. The development log writes one line naming how many Shards transferred. Alex settled the distribution: **both** the actor and the target learn the new event. Nothing contributed is left unshared afterwards if three or fewer were waiting, so availability falls to zero until a genuinely new record appears, which is what acceptance check 8 describes.

## Tuning (not design)

Walk speeds, stop distances, pickup reach and approach distance, walk and run acceleration, the run settle distance, walk clearance, path cell size, walkable slope degrees, the focus-hold speed scale, skill durations, checkpoint radii, Shard Fit oscillation/tolerance, hold-to-radial delay, camera orbit limits, and placeholder mesh sizes live in `data/milestone1/world.json`, `data/skill_phases.json`, and presentation constants. Change them in play without treating the numbers as lore. The rules those numbers express — that pickup approaches, that holding focus slows her, that a run builds speed and eases back to a walk before it stops, that a slope steeper than the vanilla line is a wall — are design and are not tuning.

## Tests

From the game repo, with Godot 4.7.2:

```
C:\Users\Babun\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://scripts/tests/run_simulation_tests.gd
```

Or `tools/run_simulation_tests.ps1`.
