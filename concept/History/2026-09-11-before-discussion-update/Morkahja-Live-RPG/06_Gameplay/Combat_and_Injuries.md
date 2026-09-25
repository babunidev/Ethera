# Combat and Injuries

**Current concept through answer 104 · reorganized 2026-09-10.**

Consolidated concept material, with current rules and unresolved details distinguished.

## Combat

### Meaningful timed interactions

Combat uses the same interaction philosophy as the rest of the game. The player reads an encounter and chooses a fitting action at the right moment. The intended experience is not repeated damage trading until a generic health bar reaches zero.

### Engagement and movement

Lock onto an opponent. While engaged, the game handles facing and most positioning so combatants remain naturally oriented toward each other. The player responds to attacks and openings rather than manually circling or continuously repositioning.

To move independently or flee, disengage and break the lock. This refines the earlier direct-control direction: movement remains direct outside engagement, while combat manages spatial presentation.

### State and response

Against a bear, a perceived attack opens responses such as a dodge or parry if available. A successful response can create an opportunity to attack. Traits, desires, role, equipment, current injuries, and the situation affect the available actions. Recklessness can support an aggressive action that risks injury.

An attack can injure a limb and restrict related actions. The first version uses broad injury states rather than detailed wound simulation. There is no selected numerical health replacement formula yet.

### Defeat remains interactive

When too injured to fight normally, new situation-specific survival interactions open. Fleeing, surrender, capture, help, and other outcomes can continue the story. Enemies and AI creatures follow the same state-dependent rules.

### Baseline and open details

Everyone has ordinary baseline actions; a trait is not required for every attempt. Personal and elemental qualities modify that foundation.

Multiple opponents, timing windows, action presentation, equipment effects, group targeting, accessibility, healing, and final-death transitions remain open. The design is not yet specified as turn-based or as a particular existing game's combat implementation.

See [Injuries](#injuries), [Baseline Actions](../03_Characters/Roles_and_Baseline_Abilities.md), and [Interaction System](Interactions_Discovery_and_Player_Skill.md).

### Skill and recovery

Equipment compatibility opens actions rather than adding hidden success/failure percentages. Execution depends on player skill; individual interactions may test more than timing. Injury remains a functional restriction, and failure creates recoverable Needs rather than permanently closing a quest route. Exact connections to Atranor remain open.

## Injuries

### Initial scope

Use broad, functional injury states. Arm Injured and Leg Injured are explicit examples. Detailed named wounds and a medical simulation are deferred. Torso and head injury states were assistant examples, not a finalized body-part list.

Injuries change available interactions. An injured limb can restrict relevant attacks, movement, carrying, or other actions. Exact restrictions are not yet enumerated. Losing an action temporarily through injury does not erase a permanent character trait.

### Too injured to fight

At a threshold where normal fighting is no longer possible, the encounter changes interaction set rather than simply ending in a death screen. Situation-specific survival actions become available.

Accepted possible actions include crawling away, surrender, calling for help, reaching safety, protecting someone, submitting to capture, playing dead, or a desperate final action. They are context-dependent possibilities, not actions guaranteed in every encounter. Calling for help remains an in-world action, not player voice or text chat.

### Symmetry

Computer-controlled creatures and enemies use the same state-dependent interaction principle. Their injuries and inability to continue can also enable fleeing, capture, being spared, or other nonlethal outcomes.

### Still open

Injury accumulation, thresholds, healing time, recovery interactions, elemental anatomy, and the connection to essence exhaustion and Atranor remain unspecified. Combat incapacity must not be silently equated with final death.

See [Combat](#combat) and [Death and Dissolution](../01_World/Atranor_Death_and_Dissolution.md).

### Recoverable consequences

An injury can generate a treatment Need. Failure must leave a recoverable route, and a created Need has a possible solution. This does not yet specify medical procedures or override Atranor's ultimate judgment. Detailed injury taxonomy remains deferred.

## Example E47: Face the bear and respond

*Illustrative example from the discussion.*

Lock onto the bear and let the game manage facing and positioning. Read its attack, dodge or parry at an appropriate moment, then use an opening. A strike to a limb can prevent a related attack. Break the lock to move away rather than circle-strafing continuously.

Conversation: [turn 63](../../Morkahja-Concept-Sources.md#turn-f76bbdcc-6784-4768-8177-8f834903d85c).

## Example E48: A reckless choice can cost an injury

*Illustrative example from the discussion.*

A reckless person may have an aggressive action that accepts injury risk. Arm Injured or Leg Injured then restricts relevant actions. Broad functional states are the first version; detailed cuts, fractures, and other medical labels remain deferred.

Conversation: [turn 63](../../Morkahja-Concept-Sources.md#turn-f76bbdcc-6784-4768-8177-8f834903d85c), [turn 64](../../Morkahja-Concept-Sources.md#turn-5af3c86e-dd56-45db-92a6-588a44c0eeb9).

## Example E49: Losing the fight need not end the scene

*Assistant-proposed possibilities accepted as contextual options.*

Possible survival actions include crawling away, surrendering, calling for help, protecting someone, reaching safety, capture, playing dead, or a desperate action. They depend on the situation. AI creatures and enemies also have changing state and nonlethal possibilities.

Conversation: [turn 65](../../Morkahja-Concept-Sources.md#turn-96daba95-6cd6-46d8-adad-b752e28eed0f), [turn 66](../../Morkahja-Concept-Sources.md#turn-fba32c20-ac98-4234-86d7-313bcf3eea22).


## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.
