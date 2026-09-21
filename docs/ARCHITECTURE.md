# Architecture

Read `AGENTS.md` and the concept documents before changing gameplay behavior. This file records **technical** structure for Milestone 1. It does not add game rules.

Canonical concept: `C:/Users/Babun/Documents/Morkahja/Morkahja-Live-RPG-Concept/Morkahja-Live-RPG/README.md`

## Split of work

| Layer | Owns | Does not own |
| --- | --- | --- |
| Authored JSON in `data/` | Stable ids, requirement groups, skill-phase parameters, Milestone 1 starting entities | Interaction results, scene graphs, meshes, animation |
| `EtheraSimulation` | World state, availability, walking integration, skill success/failure, item/Shard results, development log | Camera, meshes, navmesh, gold skill graphics |
| Presentation | Input mapping into commands, rendering `query_world_view()`, radial/panel/skill overlays | Inventing world results |
| Blender / `art/` | Editable sources exported to `assets/models/*.glb` | Gameplay rules |

Later RealmNode work should wrap `EtheraSimulation.apply(command)` and replicate the same world dictionaries. Presentation already consumes events and queries rather than mutating entities.

## Command boundary

Presentation and tests send dictionaries:

| `type` | Fields | Effect |
| --- | --- | --- |
| `tick` | `delta_ms` | Advances world time, walking, and the active skill timer |
| `set_walk_destination` | `x`, `y`, `z`, optional `entity_id` | Right-click walking. Abandons an unfinished approach; ignored once a skill phase runs |
| `stop_walking` | optional `entity_id` | Clears a destination, abandoning an unfinished approach |
| `set_focus_hold` | `held`, optional `entity_id` | Presentation reports that the radial is held open; the actor's pace cap drops |
| `pickup_item` | `item_id`, optional `actor_id` | Inherent pickup/swap. Walks into reach first. No Shard is created |
| `begin_interaction` | `target_id`, `interaction_id` | Starts authored approach, then the skill phase |
| `skill_pointer` | `x`, `y` in 0–1 skill space | Hits Shape Trace checkpoints; positions Shard Fit |
| `skill_click` | none | Confirms Shape Trace or attempts Shard Fit |

Queries: `query_available_interactions`, `query_hover`, `query_panel`, `query_skill`, `query_dev_log(limit)`, `query_recent_interactions`, `query_world_view`, `resolve_shard`.

Returned events use `event_time` for the envelope timestamp so a payload's own `world_time` — a Shard's original timestamp — is never overwritten. The development log is capped at `EtheraWorld.DEV_LOG_LIMIT`; pass a limit to `query_dev_log` instead of copying the whole log each frame.

## Entity and Shard identity

Authored entities keep their JSON ids (`entity.khar_morr`, `entity.shapeable_rock`, …). Runtime clubs and Shards receive `*.runtime.N` ids.

A consumed rock **keeps the same entity id**. `manifested` becomes false. Shape Weapon Shards continue to name that id as target and `place.village_center` as place. This is the implementation answer to manifestation identity; later reuse/placement must not change those historical fields.

## Matching

Requirement groups are AND inside, OR across groups. After a match, negative-state blocker lists apply. Echo Imprint queries the actor’s known Shard ids against target membership (`EtheraEvaluator.first_eligible_shard`, insertion order). Availability cache keys are actor+target and invalidate on trait, inventory, needs, shards, states, injuries, relationships, and manifestation versions.

Walking and pickup are inherent and do not use the radial.

## Movement rounds

One `active_skill` record owns an actor's movement from `begin_interaction` until the round resolves. While its phase is `approaching`, a new walk destination or a stop abandons the round: no Shard, no history entry, and `skill_ended` reports `outcome: cancelled`. Once the phase is `skill`, walk commands are ignored so the challenge cannot be walked out of.

Pickup uses the same motor with reason `pickup`. It walks to `pickup_approach_distance` from the item and takes it on arrival, re-checking compatibility at that moment. A click already inside `pickup_reach` skips the walk. Because a pickup walk is an ordinary destination and not a round, right-click simply replaces it.

## Echo Imprint event recipients

Success shares the **existing** contributed Shard id with the Fountain and **creates** a new event Shard. Alex settled the distribution: **both** the actor and the target learn the new event. Nothing is left unshared afterwards, so availability falls to zero until a genuinely new record appears, which is what acceptance check 8 describes.

## Tuning (not design)

Walk speeds, stop distances, pickup reach and approach distance, the focus-hold speed scale, skill durations, checkpoint radii, Shard Fit oscillation/tolerance, hold-to-radial delay, camera orbit limits, and placeholder mesh sizes live in `data/milestone1/world.json`, `data/skill_phases.json`, and presentation constants. Change them in play without treating the numbers as lore. The rules those numbers express — that pickup approaches, that holding focus slows her — are design and are not tuning.

## Tests

From the game repo, with Godot 4.7.2:

```
C:\Users\Babun\AppData\Local\Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://scripts/tests/run_simulation_tests.gd
```

Or `tools/run_simulation_tests.ps1`.
