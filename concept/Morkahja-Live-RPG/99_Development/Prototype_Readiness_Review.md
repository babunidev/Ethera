# First Playable: Specification and Readiness Review

## Assessment

Milestone 1 has an accepted gameplay scope, a detailed environment brief, a concrete character, two authored interactions, two selected skill phases, equipment behavior, controls and inspection tools. The latest discussion declares it ready to begin implementation. This is a documentation readiness review; no executable implementation or playtest has been verified in this update.

Read the [complete Milestone 1 specification](Milestone_1_Khar_Morr.md) before building. [First Playable Scope](First_Playable_Scope.md) separates later discovery, Needs, social play, inhabitation and persistence.

## Coverage

| Area | Defined for Milestone 1 |
| --- | --- |
| Runtime | Godot presentation; Blender assets; Windows desktop; mouse and keyboard. A fixed twenty-per-second authoritative clock with quantized authoritative values. The authoritative runtime becomes Rust later; the current GDScript simulation is its temporary stand-in. |
| Scene | Small terrain patch, central Fountain, Khar-Morr, one Rock + Shapeable entity and a second club. |
| Character | Female Grimnir; Grimnir, Weapon Shaping, Echo Imprint Trait; healthy Head/Torso/Arms/Legs; zero Shards; empty Small Weapon slot; no negative states. |
| Shape Weapon | Healthy usable arm and Weapon Shaping; target Rock + Shapeable; Shape Trace; remove rock manifestation; create/equip Weapon + Stone Weapon club; create known event record. |
| Equipment | Left-click pickup with a walk into reach; pickup/swap cursor; Small Weapon on back; displaced club on ground; two base colors; shaping also swaps occupied equipment. |
| Echo Imprint | Grimnir + Echo Imprint Trait; target Echo; one actor-known Shard absent from target; automatic selection; Shard Fit; same-ID reference sharing; own event Shard learned by both participants. |
| Movement and camera | Right-click destination, which also abandons an unfinished approach; smooth natural walking; self-drag orbit; wheel zoom; player view preserved; automatic interaction approach and facing. Walking is integrated at the fixed tick and interpolated for display. |
| UI | Hold-left-click radial with a slowed pace, direction/release selection; simple character data panel; upper-right development event log; C toggles the panel. |
| Assets | Supplied bare low-poly Khar-Morr and Fountain designs; animation can develop incrementally. |

## Resolved consistency issue

**Echo Imprint's new event recipients.** Success contributes an existing Shard and creates its own event Shard. **Both participants learn that new event.** Nothing is left unshared, so the interaction becomes unavailable afterwards exactly as the earlier example expected, while the example's single-Shard count is superseded: each side knows two records. Event creation and reference transfer are unchanged.

## Implementation choices and tuning

Scene coordinates, scale, navigation/collision setup, stop distances, movement curves, zoom bounds, click/hold/drag thresholds, checkpoint count/radius, phase durations, Shard Fit alignment tolerance and rotation speed can be chosen and tuned during implementation. They should support comfortable attentive play. These are practical build choices rather than another large interview requirement.

Tuning remains free, but the clock is not among it: world time advances in fixed ticks and never by frame delta, and anything feeding an authoritative comparison must be quantized or exactly represented. See [Technical foundation](RealmNode_and_Technical_Foundation.md).

Choose concrete data serialization, stable ID generation, manifestation/reference handling and refresh hooks for availability. Preserve historical target/place meaning when a rock's content can be manifested again. Keep the character's known-ID or needed-ID set as the query side for Fountain membership checks. Within several eligible Imprint records, the exact automatic selection policy remains a tuning/authoring choice; manual selection is a separate future idea.

## Validation boundary

The milestone's checks exercise successful and failed shaping, occupied and empty equipment, approach before skill execution, shared reference identity, failed and successful imprint, conditional availability, camera behavior and visible inspection. Negative-state filtering belongs in the interaction architecture; the initial cast starts without states, so a full injury/fatigue system is later work.

The earlier village/social/inhabitation experience remains the wider roadmap. Mountain Strike remains an individual combat interaction. The 72-phase draft remains a library proposal to review against the current positioning-and-timing rule.

Source turns, visual references and the reconciliation are available in the [discussion archive](../../Reference_Material/Discussion_2026-09-21/README.md) and [update record](Update_Through_Answer_399.md).

## Latest completion agreement

The accepted check is to move Khar-Morr through the visual game world, shape and equip a club, swap the two colors, inspect data with C, carry the event Shard and imprint it into the initially empty Fountain, with panel/log verification. Ground pickup swaps use the clicked weapon's exact position. The environment and separate Fountain must be visible in the completed scene.

The event-recipient rule is now supplied: both participants learn the new Echo Imprint event. Scene and runtime foundation work proceeds without a pending consistency issue. The [handoff](Implementation_Handoff.md) gathers assets, briefs and architecture in one local entry point.
