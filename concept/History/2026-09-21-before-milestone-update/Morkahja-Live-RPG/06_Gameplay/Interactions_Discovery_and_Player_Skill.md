# Interactions, Discovery and Player Skill

Interactions connect a character's capabilities to the current situation. Traits, preferences, Needs, Shards, items, body condition, relationships and surroundings determine which actions are possible.

## Authored requirements

Each interaction has complete requirement groups, a target, a player skill phase and results. Conditions within one group must all be satisfied. Alternative groups offer different valid ways to unlock the same action.

Likes Kind on one person and Kind on another can enable a greeting. A climbable surface and a usable climbing capability can enable ascent. A spear interaction can require the weapon, the attack Trait, a healthy body part and an appropriate target.

Several enabling sources still produce one available action. The explanation can show all relevant reasons.

## Discover through play

An interaction becomes known when play reveals it in a fitting situation: a meeting, an exploration, an item, a quest or a combat encounter. Undiscovered actions stay concealed.

Once discovered, the interaction remains in the character's panel. Its entry explains the requirements and any current blockers. Losing a tool or injuring an arm changes current usability while preserving the record of discovery.

## Focus and choice

Right click sets a movement destination. Hover offers a subtle cursor cue. Holding left click selects the focused world entity and opens its radial actions while slowing the participant's pace. The entity is selected before action availability is evaluated.

The wheel contains the discovered actions executable in the current situation. Slots fill dynamically with the current choices. Selecting an action commits the focused entity as its target. The character takes up the intention, approaches and faces that target. Any body-part choice specifies a part of this already selected entity.

The character panel remains the place to inspect known blocked actions. During action selection, the available wheel reflects the present encounter.

## The skill phase

The player performs the interaction's authored challenge. Timing, observation, memory, pattern recognition, sequencing or a suitable response can give an action its character.

A simple interaction can involve applying pressure, setting an angle, moving a lever or following a rhythm. Mountain Strike chooses a random valid body part, or lets a character with Aimed Attacks choose it before performing the timing challenge.

Character capability is checked before the action appears in the wheel. The player-skill phase is the success or failure check during execution. An available reaction then determines whether a successful action produces its intended effect.

## Results and retrying

Results can change state, create or transform items, share Shard references, develop relationships or fulfill Needs. After the skill phase succeeds, reactions resolve and the final world result is applied. Exactly one event Shard records the resolved round, including a prevented effect. A failed skill phase creates no Shard.

If the action remains available, another attempt can follow at the next legal opportunity. In combat this follows its alternating action rhythm. Atranor's judgment has its own terminal outcome.

## Examples

A compatible sword exposes a conditional sword action. An arm injury can block it; the panel still explains the known action and the missing condition.

A tree can offer a different set of interactions on two visits as the person, contents and circumstances change. A newly learned Trait or a carried tool can reveal an action the character had never encountered before.

## Physical initiation

Interactions begin from an entity physically present in the world. The UI presents choices and information within that encounter. Item use requires the appropriate Trait or relevant knowledge, together with the action's other conditions.

For example, Bind Shard begins by focusing an Echo Cradle. Selecting a carried stone and choosing a known Shard are steps within that one world interaction. The stone visibly sockets and returns to inventory on completion.

The [archival interactions](../05_Knowledge/Archival_Stones_and_Echo_Cradles.md) and [Mountain Strike](Mountain_Strike.md) show this structure in full.

## Shared skill challenges

An interaction either names an exact authored player-skill phase or randomly draws one each round from its category/subcategory pool. Each reusable phase has one subcategory. [Player-Skill Phases](Player_Skill_Phases.md) defines the initial twelve pools.

See [Combat](Combat_and_Injuries.md), [First Twelve Interactions](First_Twelve_Grimnir_Interactions.md), and [Interaction Architecture](../09_Technical/Entities_Interactions_and_Content_Authoring.md).
