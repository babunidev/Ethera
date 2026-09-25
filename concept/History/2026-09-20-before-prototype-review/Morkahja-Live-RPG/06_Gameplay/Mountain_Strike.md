# Mountain Strike

Mountain Strike is the foundational Grimnir unarmed attack. A focused strike with the mineral body can injure one body part. It provides a compact prototype connecting entity requirements, focus, player skill, reactions, persistent condition and knowledge.

## From focus to execution

**Hover opponent → hold left click to focus → choose Mountain Strike → choose or randomize body part → approach and perform timing challenge → reaction → result → event Shard.**

Focusing selects the opponent before the wheel is evaluated. Selecting Mountain Strike commits that entity as the action target. All capability requirements are checked before the action appears: its attack capability, a usable arm, an appropriate target and a legal combat opportunity. Known but blocked Mountain Strike remains inspectable in the character panel with its blocker explained.

Aimed Attacks enables choosing the body part after action selection and before the skill phase. A character without that Trait receives a random valid body-part target. Approach and facing bring the character into position for the authored challenge.

## Skill, reaction and result

The timing challenge is the attack's success check. Failure ends the attempt without creating a Shard. Success gives the defender the opportunity to perform an available reaction.

For a Grimnir defender, Stoneborn Resilience can prevent the injury when its successful protection covers the targeted part. Choosing that protected part requires the appropriate perception or targeting Trait; otherwise protection is random.

After reaction resolution, the targeted part either becomes Injured or the injury is prevented. The final state changes subsequent availability. One resolved-round Shard records the actual action, reaction and result, with stable participant and place IDs and world time. Combat then gives the other participant their action turn.

## Example

An attacker with Aimed Attacks selects the opponent's left arm and succeeds at the timing challenge. The defender's protection covers their right arm, so the left arm becomes Injured. Actions that require it become unavailable, while an action supported by the healthy right arm can remain possible. The event Shard preserves what happened.

## Prototype content

The actor needs identity, Traits, discovered interactions, body parts and condition, position and combat-turn state. The target supplies its body, condition and eligible reactions through the shared entity framework.

The Mountain Strike definition supplies requirements, valid targets, discovery rules, body-part targeting with Aimed Attacks support, the timing challenge, injury result, animation, sound and event-record output. A small encounter between a Grimnir and an opponent with simple anatomy is sufficient to exercise the complete chain.

See [Combat and Injuries](Combat_and_Injuries.md), [First Twelve Interactions](First_Twelve_Grimnir_Interactions.md), and [Entity Architecture](../09_Technical/Entities_Interactions_and_Content_Authoring.md).
