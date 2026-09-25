# Shard Records and Retention

Shards are immutable historical records shared by reference. Each successfully resolved action/reaction round creates one record after applying its final world result.

## Record structure

| Field | Content |
| --- | --- |
| Shard ID | Unique stable identity of this event. |
| Actor IDs | One or several specific world entities performing the primary action. |
| Target IDs | One or several specific entities involved as targets. |
| Action ID | Exactly one primary authored interaction. |
| Reaction IDs | The reaction interaction IDs that occurred, or explicit None. |
| Result IDs | One or several stable references describing the factual result. |
| Place ID | One shared place for the whole round. |
| World Time | The exact world timestamp of the event. |

Reaction IDs form a compact collection without participant-to-reaction mapping. Place records meaningful location at the place level. Items and tools are checked as interaction requirements; they have no additional general log field. A success field is unnecessary because failed player-skill attempts create no Shard.

The UI translates stable references into readable names and descriptions. A later name change does not alter an event's identity. Distinct events receive distinct IDs even when their participants and action are otherwise alike.

## Resolution and transfer

The sequence is **skill succeeds → reactions resolve → final world result applies → one event Shard is created**. Preventing an attack's injury still leaves a successfully performed action and a factual resolved result to record.

Results usually contain one reference. An exchange can contain several: Echo Attunement may teach one existing Shard in each direction, and the new exchange record references both. Absorb Knowledge records only the Shards newly learned. Bind Shard records the selected knowledge and archival destination; Memory Binding records the stone's transfer to the Fountain.

Authored definitions determine how events yield useful knowledge. Successful learning uses the first version's automatic acquisition model. Each holder maintains unique references to known Shard IDs; repeated access to an already-known ID adds nothing.

## Holder policies

| Holder | Retention |
| --- | --- |
| Character | Ordinary knowledge expires one world week after original creation. |
| Ordinary memory stone or other ordinary holder | The same creation-based one-week window. |
| Memory Fountain | One week for ordinary Shards; indefinite retention of learned authored permanent Shards. |
| Archival stone | Indefinite preservation of any deposited Shard; three slots. |

Authored permanence describes retention at the Fountain. Continued existence depends on references. Transfer or Memory Binding leaves the original timestamp intact. An old ordinary archived record transferred to the Fountain can therefore already fall outside its retention window.

## References and deletion

A record remains while a character, Fountain, object, task or another system references it. Permanent death removes the character's references. Expiration removes the affected holder's references. A Shard with no remaining references can be deleted.

Archival redundancy is allowed: several stones can refer to the same record. Consuming a stone through Memory Binding transfers its knowledge before removing the stone's holding role.

## Recent interaction history

A separate lightweight history holds the character's latest 100 interactions. Entry 101 discards the oldest. Its initial fields are interaction type, time or order, and involved entities, with a structure that can accept future fields.

Completed task objects can be discarded after their completion condition is satisfied. Recent history and usable Shard knowledge provide the retained account of events. Their retention policies serve different purposes.

See [Knowledge](../05_Knowledge/Shards_Memory_and_Cultural_Hubs.md), [Archival Interactions](../05_Knowledge/Archival_Stones_and_Echo_Cradles.md), and [Entity Architecture](Entities_Interactions_and_Content_Authoring.md).
