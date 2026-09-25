# Combat

**Status:** Established concept, updated 2026-09-10. Later user decisions supersede earlier brainstorms; unresolved details are marked.

## Meaningful timed interactions

Combat uses the same interaction philosophy as the rest of the game. The player reads an encounter and chooses a fitting action at the right moment. The intended experience is not repeated damage trading until a generic health bar reaches zero.

## Engagement and movement

Lock onto an opponent. While engaged, the game handles facing and most positioning so combatants remain naturally oriented toward each other. The player responds to attacks and openings rather than manually circling or continuously repositioning.

To move independently or flee, disengage and break the lock. This refines the earlier direct-control direction: movement remains direct outside engagement, while combat manages spatial presentation.

## State and response

Against a bear, a perceived attack opens responses such as a dodge or parry if available. A successful response can create an opportunity to attack. Traits, desires, role, equipment, current injuries, and the situation affect the available actions. Recklessness can support an aggressive action that risks injury.

An attack can injure a limb and restrict related actions. The first version uses broad injury states rather than detailed wound simulation. There is no selected numerical health replacement formula yet.

## Defeat remains interactive

When too injured to fight normally, new situation-specific survival interactions open. Fleeing, surrender, capture, help, and other outcomes can continue the story. Enemies and AI creatures follow the same state-dependent rules.

## Baseline and open details

Everyone has ordinary baseline actions; a trait is not required for every attempt. Personal and elemental qualities modify that foundation.

Multiple opponents, timing windows, action presentation, equipment effects, group targeting, accessibility, healing, and final-death transitions remain open. The design is not yet specified as turn-based or as a particular existing game's combat implementation.

See [Injuries](../03_Characters/Injuries.md), [Baseline Actions](../03_Characters/Baseline_Actions.md), and [Interaction System](../06_Systems/Interaction_System.md).


## Skill and recovery

Equipment compatibility opens actions rather than adding hidden success/failure percentages. Execution depends on player skill; individual interactions may test more than timing. Injury remains a functional restriction, and failure creates recoverable Needs rather than permanently closing a quest route. Exact connections to Atranor remain open.

## Source

[Morkahja live RPG](https://chatgpt.com/c/6aa08555-1c60-83eb-ae68-d3555edd8d7f), design discussion through 2026-09-10, including answers 31–104. See the [preserved conversation](../../Morkahja-Concept-Sources.md) for exact wording and intermediate ideas. Examples are illustrative, not exhaustive implementation lists.
