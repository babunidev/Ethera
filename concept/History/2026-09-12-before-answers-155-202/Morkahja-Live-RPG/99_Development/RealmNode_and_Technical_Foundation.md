# RealmNode and Technical Foundation

## Scope and source status

This chapter records the related discussion in “Save concept locally” (task 01a08625-6dc8-7a63-ae78-6a358365be28), alongside the main design interview. It does not claim these statements are interview answers or that software has already been implemented. RealmNode references were read from “RealmNode Overview” and “Design P2P MMO Architecture” in the realmNode project.

## Agreed direction

The user intends Morkahja to use a peer network collectively running the world, and confirmed that RealmNode and the game can be developed alongside one another. RealmNode is reusable infrastructure; Morkahja is its first proposed custom-game integration. A dedicated permanent central game server is not the assumed target.

Morkahja defines gameplay and simulation rules. RealmNode coordinates execution, validation, synchronization, persistence, and responsibility transfer. The game engine handles presentation and player input. Their interface must be explicit so both can progress together. A single local node can support early gameplay while multi-peer behavior is tested separately.

## RealmNode concept relevant to Morkahja

Temporary regional simulators with validator groups; authority migration; replicated event history and snapshots; storage/archive nodes; peer discovery through multiple methods; direct connections and volunteer relays; signed publisher rulesets and migrations; separate immediate gameplay and durable transactions. These are architecture concepts, not verified operating guarantees.

World-owned Morkahja characters require temporary exclusive control grants, replacing RealmNode's example of permanent account ownership. A node may need world information its player should not know, creating a specific challenge for hidden knowledge and discovery. Continued simulation requires active machines; archives preserve data but do not by themselves execute ongoing life.

## Engineering review: open requirements

Validator admission and independence; resistance to fake identities; a specified consensus protocol and fault assumptions; safe membership changes; authority generations rejecting stale leaders; behavior during network splits; provisional versus committed outcomes; deterministic arithmetic, input ordering, timing and serialization; atomic regional/item transfers; trusted snapshot recovery and availability; version branches and nonautomatic reconciliation; signed code and resource isolation; relay capacity and internet failure testing.

Signatures identify a sender or publisher, not the truth of a claimed event. A simple '3-of-5' vote alone is not a complete Byzantine consensus design. More peers do not automatically prove MMO scalability or DDoS resistance. These review findings are implementation work, not new gameplay restrictions.

## Proposed stack, not a final engine selection

Rust/Cargo for a standalone RealmNode program; rust-libp2p for connection/discovery/relay building blocks; embedded SQLite for each node's local records. Consensus, game rules, replication, and recovery still need implementation. Rust, Cargo, Git, and Windows C++ Build Tools were found installed during the September 10 review; a full project compilation has not yet been verified.

Godot/GDScript was recommended for a small client prototype. Unity and Unreal were discussed as alternatives. No engine was selected or installed by that discussion, and none is assumed by the concept archive.

## Proposed matching milestones

1. Define one-region commands, identity, ownership/control, and commit/recovery rules for known test peers.
2. One local node with a deterministic tiny world and persistent log.
3. Three local processes sharing an object, simulator loss, reassignment, and reconnection.
4. Failure tests for duplicate/conflicting actions, partitions, delay, and corrupted state.
5. Minimal Morkahja integration: inhabitation, movement, pickup, knowledge, and AI handoff.
6. Independent machines and internet connections: relays, latency, bandwidth, and recovery.
7. Public validator admission, Byzantine behavior, multiple regions, secure releases, and scalability.

The known-peer prototype is an engineering recommendation, not a decision to limit the final world to trusted friends. No implementation work or installations were performed as part of this archive update.
