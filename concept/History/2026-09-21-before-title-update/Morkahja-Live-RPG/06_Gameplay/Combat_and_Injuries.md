# Combat and Injuries

Combat follows an alternating rhythm: **A attacks → B reacts → B attacks → A reacts**. Authored actions, functional body parts and player execution shape each exchange.

## Availability and engagement

The player hovers an opponent and holds left click to focus them. That selects the entity before the radial wheel opens. Character requirements, usable body parts, necessary materials or items and the legal combat opportunity determine which discovered actions appear.

Selecting an action commits the focused target and the attack intention. The game manages approach, facing and positioning during engagement. The player disengages to move independently or flee.

All character capability checks belong to availability. Once execution begins, the player-skill phase determines whether the attack succeeds. Target defense is resolved afterward in the reaction phase.

## Mountain Strike and Aimed Attacks

Mountain Strike is an unarmed attack using the Grimnir's mineral body. It requires a usable striking arm and a suitable physical opponent.

The **Aimed Attacks** Trait enables deliberate body-part selection after choosing Mountain Strike and before its skill phase. Without it, the action selects a random valid body part. The focused opponent remains the target throughout; the body-part choice specifies where the strike goes.

The player performs the selected player-skill challenge. Success completes the attack and gives the defender their reaction opportunity. Failure ends the attempt and creates no event Shard.

## Reaction and protection

Stoneborn Resilience is the Grimnir defensive interaction. It protects one body part. The relevant perception or targeting Trait enables reading the incoming location and choosing the protected part; otherwise the protected part is selected randomly.

If the defense succeeds and protects the struck part, it prevents the injury. Otherwise the successful strike injures that part. Creature reactions come from that creature's own authored abilities.

## Functional injury

Each body part is injured or uninjured. A successful unprevented Mountain Strike sets its targeted part to **Injured**. The state determines which dependent actions remain possible.

An injured arm closes actions requiring that arm; another usable arm can satisfy an appropriate alternative. An injured leg restricts actions requiring that leg. The body's functional condition drives combat without an HP layer.

As actions become unavailable, fitting contextual alternatives can include crawling away, surrender, help, capture, protection, reaching safety, playing dead or a desperate response. AI creatures use the same functional-state principle. Treatment creates or resolves the relevant healing Need through an authored interaction.

## The resolved round

After the reaction and final world update, a successful attack round creates one immutable event Shard containing its action, reaction and actual result. A prevented injury is still a resolved round with a record. Failed player-skill attempts create none.

A Grimnir with Aimed Attacks chooses another Grimnir's left arm and succeeds at Mountain Strike. The defender's Stoneborn Resilience protects that arm and succeeds, preventing injury. One Shard records the whole exchange, and the defender then receives the next attack turn.

Mountain Strike belongs to **Combat → Attack**. It uses a specified phase when one is authored, otherwise a random phase from that pool. Timing remains an available starting challenge. See [Player-Skill Phases](Player_Skill_Phases.md).

See [Mountain Strike](Mountain_Strike.md), [Interactions](Interactions_Discovery_and_Player_Skill.md), and [Shard Records](../09_Technical/Shard_Records_and_Retention.md).
