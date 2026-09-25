# RealmNode and Technical Foundation

September 12 update: the game now explicitly freezes without active simulation and performs no offline catch-up. Snapshot cadence, replicas, and always-on reference nodes remain RealmNode implementation choices. See [World persistence](../09_Technical/World_Persistence_and_RealmNode.md).

The full architecture is [RealmNode: Game-Native Architecture](../09_Technical/RealmNode_Game-Native_Concept.md). The decisions below are settled and govern implementation.

## Settled architecture

Alex settled the following on September 21. They are decisions, not proposals.

### The runtime stack

```text
Godot          presentation, animation, audio, UI, input collection, local prediction
    │ commands / events
Game runtime   Rust — characters, traits, interactions, skill resolution, AI, items,
    │              knowledge, village simulation, destinies, world time, RNG,
    │              persistent consequences. Rules largely authored as data.
    │ state / results
RealmNode      Rust — authority, validator selection, networking, replication,
               transactions, state shards, snapshots, identity, recovery, persistence
```

The game runtime and RealmNode are **separate crates**. RealmNode decides who calculates, who validates and whether state is accepted. The game runtime decides what an interaction means, how AI behaves and what consequences occur. Game rules never live inside the networking layer.

Both a player and a validator execute the same `game-runtime`. A validator must never need to launch Godot.

The prototype is **not** rewritten into Rust now. Instead, authoritative GDScript is treated as temporary: anything describing a game rule becomes authored data where possible, or deterministic runtime logic behind a clean interface. GDScript keeps presentation, input collection, animation, UI, local prediction and prototype glue.

### Determinism

Presentation may use ordinary floats. Authoritative simulation uses deterministic representations: integers or fixed-point for time, resources, damage, distance thresholds, interaction measurements and random results.

`sin()` is not banned visually. Platform-dependent trigonometric results are banned from becoming authoritative hashed truth unless the runtime defines a deterministic implementation or quantizes the result.

Godot physics is not an authoritative distributed simulation and must not be treated as one.

### World clock

The authoritative clock is a fixed **SimTick**, currently 20 ticks per second. World time is derived from the tick count. Frame deltas never enter the simulation. Rendering runs at any frame rate and interpolates.

### Player-skill phases

Validators verify gameplay legality: whether the interaction was available, whether the target was legal, whether the skill phase began, whether the input sequence was structurally valid, whether it fell inside the allowed window, and whether that input produces that result.

Validators do **not** authenticate human dexterity. Proving genuine human participation would require intrusive anti-cheat, trusted hardware or centralized surveillance, none of which suits RealmNode.

The actor never reports an outcome. It submits timestamped input samples and the runtime calculates the score. A cheat can fabricate convincing samples but cannot fabricate an arbitrary game result.

### Two speeds of truth for items

Creating, transferring or changing ownership of an item needs stronger validation, but the player never waits for consensus. The click takes the item immediately; underneath the transaction moves `PENDING → VALIDATING → COMMITTED`, and only a validation failure causes reconciliation. Equipping an already-owned tool affects combat immediately under regional authority while its persistent state commits asynchronously.

### Disconnect during an interaction

A disconnect before the consequence is committed cancels the unfinished round, exactly as a right-click cancel does. A disconnect after the consequence is committed leaves the consequence standing; authoritative results are never reversed merely because the actor vanished afterward. The character then enters the established disconnected/waiting state rather than becoming ordinary AI immediately.

### Active and dormant regions

Simulation fidelity and world progression are different things.

```text
ACTIVE REGION    full simulation: movement, individual AI, interactions,
                 physics, precise positions
DORMANT REGION   abstract simulation: work, food consumption, rest, relationships,
                 resource changes, birth and development, knowledge aging,
                 village processes, important events
```

A village with nobody nearby is living but not ticking every creature every frame. A hunter does not walk thousands of individual navigation steps while nobody can see him; the dormant simulation resolves the activity deterministically. This does not contradict the September 12 rule: with no machines simulating a region at all, the world still freezes and still performs no offline catch-up.

### Hidden knowledge

No single machine owns a Memory Fountain. A Fountain's knowledge is a settlement knowledge shard with a current authority, validators and storage replicas.

A client asks whether its character may currently access an interaction. The authoritative runtime evaluates character knowledge, Fountain knowledge, discovery state and the other requirements, and returns only the permitted result. Clients receive only the knowledge their current character is entitled to observe, plus the bearing of their selected quest objective. Rendering an interaction menu is never a reason to ship every hidden fact to a player's machine.

## Scope and source status

This chapter records the related discussion in “Save concept locally” (task 01a08625-6dc8-7a63-ae78-6a358365be28), alongside the main design interview. It does not claim these statements are interview answers or that software has already been implemented. RealmNode references were read from “RealmNode Overview” and “Design P2P MMO Architecture” in the realmNode project.

## Agreed direction

The user intends Ethera to use a peer network collectively running the world, and confirmed that RealmNode and the game can be developed alongside one another. RealmNode is reusable infrastructure; Ethera is its first proposed custom-game integration. A dedicated permanent central game server is not the assumed target.

Ethera defines gameplay and simulation rules. RealmNode coordinates execution, validation, synchronization, persistence, and responsibility transfer. The game engine handles presentation and player input. Their interface must be explicit so both can progress together. A single local node can support early gameplay while multi-peer behavior is tested separately.

## RealmNode concept relevant to Ethera

Temporary regional simulators with validator groups; authority migration; replicated event history and snapshots; storage/archive nodes; peer discovery through multiple methods; direct connections and volunteer relays; signed publisher rulesets and migrations; separate immediate gameplay and durable transactions. These are architecture concepts, not verified operating guarantees.

World-owned Morkahja characters require temporary exclusive control grants, replacing RealmNode's example of permanent account ownership. A node may need world information its player should not know, creating a specific challenge for hidden knowledge and discovery. Continued simulation requires active machines; archives preserve data but do not by themselves execute ongoing life.

## Engineering review: open requirements

Validator admission and independence; resistance to fake identities; a specified consensus protocol and fault assumptions; safe membership changes; authority generations rejecting stale leaders; behavior during network splits; provisional versus committed outcomes; deterministic arithmetic, input ordering, timing and serialization; atomic regional/item transfers; trusted snapshot recovery and availability; version branches and nonautomatic reconciliation; signed code and resource isolation; relay capacity and internet failure testing.

Signatures identify a sender or publisher, not the truth of a claimed event. A simple '3-of-5' vote alone is not a complete Byzantine consensus design. More peers do not automatically prove MMO scalability or DDoS resistance. These review findings are implementation work, not new gameplay restrictions.

## Selected game tools and proposed RealmNode stack

Rust/Cargo for a standalone RealmNode program; rust-libp2p for connection/discovery/relay building blocks; embedded SQLite for each node's local records. Consensus, game rules, replication, and recovery still need implementation. Rust, Cargo, Git, and Windows C++ Build Tools were found installed during the September 10 review; a full project compilation has not yet been verified.

Godot is selected for the Live RPG game, and Blender for 3D assets. Milestone 1 targets Windows desktop with mouse and keyboard.

The authoritative language question is now settled: the shared deterministic game runtime is Rust, in its own crate beside `realmnode-core`, reached from Godot through a GDExtension or native interface. GDScript is the prototype's temporary stand-in for that runtime and its permanent home for presentation. See Settled architecture above.

## Proposed matching milestones

1. Define one-region commands, identity, ownership/control, and commit/recovery rules for known test peers.
2. One local node with a deterministic tiny world and persistent log.
3. Three local processes sharing an object, simulator loss, reassignment, and reconnection.
4. Failure tests for duplicate/conflicting actions, partitions, delay, and corrupted state.
5. Minimal Ethera integration: inhabitation, movement, pickup, knowledge, and AI handoff.
6. Independent machines and internet connections: relays, latency, bandwidth, and recovery.
7. Public validator admission, Byzantine behavior, multiple regions, secure releases, and scalability.

The known-peer prototype is an engineering recommendation, not a decision to limit the final world to trusted friends. No implementation work or installations were performed as part of this archive update.
