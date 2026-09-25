# Milestone 1: Khar-Morr

The first complete playable loop joins movement, a world-object interaction, an equipped item, an event Shard and a contribution to the Memory Fountain. This chapter specifies the intended build; implementation and playtesting still need verification in the Live RPG project.

## Platform and scene

Use **Godot**, with **Blender** for 3D work, on **Windows desktop with mouse and keyboard**. Place a Memory Fountain roughly in the middle of a small terrain patch. Khar-Morr begins nearby. Place one shapeable rock within walking distance and one loose stone club for equipment tests. Leave clear room to move and approach each target.

The rock is one world entity with **Rock** and **Shapeable** Traits. Its authored form already supplies the stone for one club. It can look like a single rock or a small group of stones belonging to that one object. The Fountain has **Memory Fountain** and **Echo** Traits and begins with zero known Shards.

## Khar-Morr's starting data

| Field | Starting value |
| --- | --- |
| Name | Khar-Morr the First Carved |
| People and sex | Grimnir; female |
| Capability Traits | Grimnir, Weapon Shaping, Echo Imprint Trait |
| Body regions | Head, Torso, Arms, Legs; all healthy |
| Negative states and blockers | Empty |
| Known Shards | Empty |
| Equipment | One empty Small Weapon slot; attachment on her back |
| Test purpose | Shape Weapon, equipment pickup/swap and Echo Imprint |

Arms and Legs are combined regions for this milestone. The broader combat model can later use more specific parts. Weapon Shaping supplies the shaping capability. Preserve this minimal configuration as other test characters are introduced.

## Models and motion

Build Khar-Morr from the selected bare low-poly reference, retaining its female Grimnir silhouette and angular mineral masses. Use the supplied Memory Fountain reference sheets. The [asset archive](../../Reference_Material/Discussion_2026-09-21/README.md#visual-references) contains all five original images, including the earlier Khar-Morr variants.

Simple movement and idle presentation are sufficient initially. Locomotion and dedicated Shape Weapon/Echo Imprint animations can improve incrementally. The clubs share their functional definition and differ in base color. Equipped clubs attach to her back.

## Controls

| Input | Behavior |
| --- | --- |
| Right-click ground | Set walking destination. |
| Left-click and drag on Khar-Morr | Orbit the camera around her. |
| Mouse wheel | Zoom from close observation to a broad view. |
| Hold left-click on an interaction target | Open its currently available radial actions; move toward an option and release to select. |
| Left-click a loose compatible item | Pick it up or swap it into the Small Weapon slot. |

The camera follows her position and preserves the angle and zoom chosen by the player. Movement uses a normal base walking pace with smooth acceleration and deceleration. Exact speeds, distances, camera limits and gesture thresholds are implementation tuning.

Selecting Shape Weapon or Echo Imprint automatically approaches the authored position beside the target and faces it before the skill phase starts.

## Shape Weapon and equipment

The actor has Weapon Shaping and a healthy usable arm; the target has Rock and Shapeable. Normal requirements and negative-state blockers determine availability. **Shape Trace**, in Combat → Weapon Craft, is explicitly assigned.

Complete the club-shaped checkpoints in any order within the phase's time limit. Missed checkpoints can be revisited; leaving the outline carries no penalty. After tracing all checkpoints, left-click to complete the phase within its time limit. An integrated outline shows the time remaining; expiration grays and fades the graphic.

Success removes the rock's current world manifestation, creates a stone club with Weapon and Stone Weapon Traits, and equips it in Small Weapon. If occupied, the previous club appears on the ground beside Khar-Morr. The new club attaches to her back. Failure leaves the rock and equipment unchanged and creates no event Shard.

The success record uses the common structure: **Actor Khar-Morr; Target this rock; Action Shape Weapon; Reaction None; Result the club's creation and equipment; Place this location; exact world time**, with stable IDs throughout. Khar-Morr knows this event Shard.

Hovering a loose club shows the pickup/bag symbol for an empty compatible slot or two swap arrows for an occupied slot. A left-click takes it; replacement places the displaced club physically on the ground. Repeating this demonstrates both colors moving between ground and back.

## Echo Imprint

The actor has Grimnir and Echo Imprint Trait. The target has Echo. Khar-Morr must know at least one Shard the Fountain lacks, and the separate blocker filter must permit the action. Query the Fountain only for the character's known IDs.

Automatically choose one eligible Shard. Complete **Shard Fit**, in Social → Knowledge: move the angular cursor symbol over its matching recess and left-click when its automatic rotation aligns. Wrong clicks continue with the remaining time. Expiration fails quietly.

Success grants the Fountain a reference to the same Shape Weapon record. Khar-Morr retains hers. The interaction also creates its own event Shard. The recipients of that new event remain to be clarified: this determines whether Khar-Morr immediately has another eligible contribution. Availability always reflects whether any known Shard is still missing from the Fountain.

## Inspectable feedback

The in-game character panel can begin as text lists. Show identity, body regions/condition, Traits, known Shard references, known interactions and the Small Weapon slot. Keep gameplay data directly inspectable while the final layout develops. Question 400 still asks how to open and close this panel.

A development event log sits in the upper-right corner. List action starts, success/failure, club creation, equipment swaps, Shard creation and the Fountain learning a reference. Blocker changes and resulting availability can be listed when states are introduced. This log supports development; the wider presentation retains its diegetic direction.

## Acceptance checks

1. Start with the exact character and empty Fountain data above; inspect the panel.
2. Walk between the scene objects with natural starts/stops; orbit and zoom, retaining the chosen view during movement and interactions.
3. Open the rock's radial action, select Shape Weapon and verify automatic approach/facing precedes Shape Trace.
4. Let Shape Trace time out: rock, equipment and known Shards remain unchanged. Retry and succeed: one rock manifestation disappears, one club equips and one event Shard records the result.
5. Pick up and repeatedly swap the two colored clubs. Each displaced item remains physically present, and the Small Weapon slot agrees with the visible attachment. Also verify shaping with an occupied slot using an appropriate test setup.
6. Focus the empty Fountain, complete Shard Fit and verify it gains the exact same Shape Weapon Shard ID while Khar-Morr retains access. A wrong click keeps the timer running; a timeout grants no knowledge and creates no successful-round Shard.
7. Verify the separate Echo Imprint event exists. Check recipient/availability behavior against the clarified event-distribution decision; avoid assuming fixed final Shard counts beforehand.
8. With every Shard known by the actor also known by the target, Echo Imprint is unavailable. A newly eligible known record makes it available again.
9. Inspect resulting state in the panel and event log. Stable references continue to resolve the original event even though the rock's manifestation is gone.

Discovery and the stone circle enter Milestone 2. Needs, guidance, additional characters, switching, AI handoff and save/reload follow the [milestone roadmap](First_Playable_Scope.md).
