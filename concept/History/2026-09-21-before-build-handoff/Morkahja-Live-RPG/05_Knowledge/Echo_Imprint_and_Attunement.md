# Echo Imprint and Echo Attunement

The Memory Fountain receives knowledge through **Echo Imprint** and supplies needed knowledge through **Echo Attunement**. Each use grants one existing Shard reference. The source retains access to the same immutable record.

## Echo Imprint: contributing knowledge

The actor requires **Grimnir** and **Echo Imprint Trait**. The target requires **Echo**. At least one Shard known by the actor must be unknown to the target. Normal requirement matching is followed by the negative-state blocker filter.

The interaction automatically chooses one eligible Shard. Successful **Shard Fit**, from Social → Knowledge, grants the target that Shard ID. The character retains their reference. This first form uses automatic selection; selection among several eligible records follows the authored implementation policy.

For example, Khar-Morr shapes a club and learns the Shape Weapon event. An empty Fountain gains access to that exact event after Echo Imprint. The action becomes unavailable whenever every Shard the character knows is also known by the Fountain.

## Echo Attunement: receiving needed knowledge

The actor requires **Grimnir**, the target requires **Echo**, and the Fountain holds a Shard needed by the character. The separate blocker filter must allow the interaction. One needed available Shard is selected automatically and learned on success. When several are needed, repeated successful uses retrieve them one at a time.

Knowledge then supplies the character's task or quest with its relevant information. Echo Attunement belongs to Social → Knowledge; its exact initial phase assignment is a later implementation choice.

## Focused matching

For Echo Imprint, check the character's known IDs for membership in the Fountain's knowledge. For Echo Attunement, check the character's needed IDs against the Fountain. These focused queries work with the relevant character-sized sets.

The Fountain's **Memory Fountain** Trait describes its identity; **Echo** supplies the capability matched by these interactions. The same requirement vocabulary can describe other authored Echo-bearing targets.

## Event records and preservation

A successful interaction creates its own event Shard after the transfer result. That record identifies the actual learned Shard reference and participants using the common event fields. 

Knowledge retains its original timestamp and holder-specific retention policy. [Memory Binding](Archival_Stones_and_Echo_Cradles.md) separately transfers an archival stone's stored knowledge and consumes that stone.

See [Shards and Cultural Hubs](Shards_Memory_and_Cultural_Hubs.md), [Skill Phases](../06_Gameplay/Player_Skill_Phases.md), and [Shard Records](../09_Technical/Shard_Records_and_Retention.md).
