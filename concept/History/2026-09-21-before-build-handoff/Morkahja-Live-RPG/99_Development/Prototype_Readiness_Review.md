# First Playable: Specification and Readiness Review

## Assessment

Milestone 1 now has a concrete character, scene, two authored interactions, two selected skill phases, equipment behavior, controls and inspection tools. Its design is substantially specified. This is a documentation readiness review; no executable implementation or playtest has been verified in this update.

Read the [complete Milestone 1 specification](Milestone_1_Khar_Morr.md) before building. [First Playable Scope](First_Playable_Scope.md) separates later discovery, Needs, social play, inhabitation and persistence.

## Coverage

| Area | Defined for Milestone 1 |
| --- | --- |
| Runtime | Godot; Blender assets; Windows desktop; mouse and keyboard. |
| Scene | Small terrain patch, central Fountain, Khar-Morr, one Rock + Shapeable entity and a second club. |
| Character | Female Grimnir; Grimnir, Weapon Shaping, Echo Imprint Trait; healthy Head/Torso/Arms/Legs; zero Shards; empty Small Weapon slot; no negative states. |
| Shape Weapon | Healthy usable arm and Weapon Shaping; target Rock + Shapeable; Shape Trace; remove rock manifestation; create/equip Weapon + Stone Weapon club; create known event record. |
| Equipment | Left-click pickup; pickup/swap cursor; Small Weapon on back; displaced club on ground; two base colors; shaping also swaps occupied equipment. |
| Echo Imprint | Grimnir + Echo Imprint Trait; target Echo; one actor-known Shard absent from target; automatic selection; Shard Fit; same-ID reference sharing; own event Shard. |
| Movement and camera | Right-click destination; smooth natural walking; self-drag orbit; wheel zoom; player view preserved; automatic interaction approach and facing. |
| UI | Hold-left-click radial, direction/release selection; simple character data panel; upper-right development event log. |
| Assets | Supplied bare low-poly Khar-Morr and Fountain designs; animation can develop incrementally. |

## Decisions still needed

1. **Character-panel input — question 400.** Choose the HUD stone/button, a keyboard key or another explicit opening/closing input. The panel's required information is already settled.
2. **Echo Imprint's new event recipients.** Success contributes an existing Shard and creates its own event Shard. The latest example says Khar-Morr still has only one Shard afterward and the interaction is unavailable. If she also learns the newly created event while the Fountain lacks it, she immediately has another eligible contribution. Define who knows the new event before treating that example's counts and availability as acceptance criteria. Keep event creation and reference transfer intact meanwhile.

## Implementation choices and tuning

Scene coordinates, scale, navigation/collision setup, stop distances, movement curves, zoom bounds, click/hold/drag thresholds, checkpoint count/radius, phase durations, Shard Fit alignment tolerance and rotation speed can be chosen and tuned during implementation. They should support comfortable attentive play. These are practical build choices rather than another large interview requirement.

Choose concrete data serialization, stable ID generation, manifestation/reference handling and refresh hooks for availability. Preserve historical target/place meaning when a rock's content can be manifested again. Keep the character's known-ID or needed-ID set as the query side for Fountain membership checks. Within several eligible Imprint records, the exact automatic selection policy remains a tuning/authoring choice; manual selection is a separate future idea.

## Validation boundary

The milestone's checks exercise successful and failed shaping, occupied and empty equipment, approach before skill execution, shared reference identity, failed and successful imprint, conditional availability, camera behavior and visible inspection. Negative-state filtering belongs in the interaction architecture; the initial cast starts without states, so a full injury/fatigue system is later work.

The earlier village/social/inhabitation experience remains the wider roadmap. Mountain Strike remains an individual combat interaction. The 72-phase draft remains a library proposal to review against the current positioning-and-timing rule.

Source turns, visual references and the reconciliation are available in the [discussion archive](../../Reference_Material/Discussion_2026-09-21/README.md) and [update record](Update_Through_Answer_399.md).
