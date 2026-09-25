# RealmNode
## A Game-Native Decentralized Runtime for Persistent Online Worlds

## 1. Core Idea

RealmNode is the networking, simulation, validation, and persistence architecture built directly into the game.

There is no traditional dedicated game server that permanently owns the world.

Every running copy of the game contains a RealmNode.

```text
Game
│
├── Rendering
├── Input
├── Audio
├── UI
│
└── RealmNode
    ├── World simulation
    ├── Networking
    ├── Authority
    ├── Validation
    ├── Persistence
    ├── Replication
    ├── Identity
    ├── Security
    └── Recovery
```

A single game instance contains enough logic to run the world locally.

When several players connect, their RealmNodes cooperate and collectively become the server.

The fundamental principle is:

> The world is defined by its rules and state. The participating nodes collectively execute it.

The server is therefore not a particular computer.

The server is the network of RealmNodes.

---

# 2. One Runtime, Multiple Operating Modes

The game should use the same fundamental simulation architecture regardless of whether it is running alone or online.

The difference is how strongly the resulting state is witnessed and validated.

## Local mode

```text
Game
 ↓
Local RealmNode
 ↓
World Simulation
```

One machine performs everything.

This is suitable for:

- development
- testing
- single-player play
- local simulation

There is no independent witness.

Its state is therefore local rather than collectively verified.

## Small cooperative mode

```text
Node A
 ↕
Node B
 ↕
Node C
```

Two to five players may maintain a shared cooperative world.

Actions can be witnessed and replicated between multiple machines, but this state remains separate from the fully validated community realm.

## Community realm mode

The established threshold is six or more participating nodes.

```text
6+ RealmNodes
      │
      ├── simulation
      ├── validation
      ├── persistence
      ├── replication
      └── recovery
```

This creates enough independent participants to distribute authority and validation meaningfully.

Community-realm state does not merge with solo or small-cooperative state.

If the community realm loses the minimum required network participation, verified network progression stops rather than silently allowing insufficiently witnessed state into the verified world.

---

# 3. RealmNode Is the Server

RealmNode should not be designed as a client connecting to some hidden replacement server.

Each node contains the complete rules needed to simulate the game.

Conceptually:

```text
Node A
contains the game rules

Node B
contains the game rules

Node C
contains the game rules
```

Together:

```text
A + B + C + ...
       ↓
distributed world execution
```

A node can therefore calculate:

- movement
- combat
- AI
- interactions
- physics relevant to gameplay
- spawning
- resources
- inventories
- quests
- progression
- world systems
- persistent changes

The network determines which nodes are responsible for calculating and validating particular portions at a particular moment.

---

# 4. World State Must Be Independent From Presentation

The authoritative world must exist as data, not as whatever happens to be visible on one player's screen.

```text
WORLD STATE
│
├── Entities
├── Positions
├── Attributes
├── Inventories
├── Relationships
├── AI state
├── Environment state
├── Progression
└── Persistent events
        │
        ▼
GAME PRESENTATION
├── Models
├── Animations
├── Effects
├── UI
└── Audio
```

Rendering is never authoritative.

UI is never authoritative.

An animation playing does not prove that an attack occurred.

A number shown in an inventory does not prove that an item exists.

The world state is the source of truth.

This separation is essential because different nodes must be able to reproduce and verify the same world without relying on presentation.

---

# 5. Stable Entity Identity

Anything that matters to the persistent world requires a stable identity.

Examples:

```text
Player
Character
Creature
Item
Container
Building
Resource
Quest
Settlement
World object
```

Each receives an identifier that remains meaningful across:

- node changes
- reconnects
- authority handoffs
- snapshots
- saves
- network replication

Example:

```text
Entity ID:
7F22-A910-4D18
```

Network state should refer to IDs rather than scene objects or memory addresses.

---

# 6. Node Roles

Every RealmNode can perform several jobs.

These are logical roles rather than different applications.

## Player Node

Hosts a participating player's game.

## Simulator

Calculates part of the active world.

## Validator

Independently checks simulation results or persistent actions.

## Storage Node

Stores replicated portions of persistent state.

## Archive Node

Keeps durable snapshots and older state needed for recovery.

## Router

Assists with peer discovery and network routing.

## Relay

Forwards encrypted traffic when two peers should not or cannot communicate directly.

A capable machine may perform several simultaneously.

```text
Node A
Player + Simulator

Node B
Player + Validator + Storage

Node C
Player + Validator + Relay

Node D
Player + Storage + Archive
```

Roles are temporary and transferable.

No machine permanently owns one.

---

# 7. User-Controlled Contribution

Running the game should not automatically grant unlimited access to the player's resources.

Contribution roles should support controls such as:

```text
Simulator:
Allow / Ask / Never

Validator:
Allow / Ask / Never

Storage:
Allow / Ask / Never

Relay:
Allow / Ask / Never
```

Roles can additionally specify:

```text
While Playing
Background
Both
```

Resource limits can cover:

- CPU
- memory
- disk space
- upload bandwidth
- download bandwidth
- number of connections
- storage duration

Global defaults can exist, with per-realm or per-save overrides where appropriate.

---

# 8. Temporary Authority

The entire network does not calculate the entire world every frame.

Active portions of the world receive temporary authority.

Example:

```text
World Region X

Primary Simulator
      │
      ├── Validator A
      ├── Validator B
      └── Validator C
```

The primary simulator produces the immediate authoritative simulation.

Validators independently check it.

The primary is temporary.

If it disappears:

```text
Primary disconnects
        ↓
existing state remains replicated
        ↓
eligible node selected
        ↓
authority transferred
        ↓
simulation continues
```

Authority belongs to the network protocol, not the computer.

---

# 9. Dynamic Simulation Regions

The world can be divided into logical simulation regions.

They do not need to correspond permanently to map zones.

A quiet area might use one large region.

```text
Northern Wilderness
    ↓
one simulator group
```

A crowded settlement might split dynamically.

```text
Capital
│
├── District A
├── District B
├── Market
└── Palace
```

Regions can merge and divide according to:

- player population
- AI complexity
- combat activity
- CPU cost
- network latency
- entity density

This allows the simulation to scale with actual activity.

---

# 10. Authority Handoff

Entities frequently move between authorities.

The transition must be explicit.

```text
Authority A
     │
     ▼
Signed State Handoff
     │
     ▼
Authority B
```

A handoff contains enough state to continue deterministic simulation.

For a character this could include:

```text
Entity ID
Position
Velocity
Health
Resources
Effects
Cooldowns
Inventory reference
Current action
Combat state
Relevant AI state
World-state references
```

Authority B verifies the handoff before taking ownership.

Once accepted, Authority A no longer controls that entity.

---

# 11. Deterministic Simulation

RealmNode relies heavily on deterministic game logic.

Given:

```text
same starting state
+
same input
+
same rules
+
same random seed
=
same result
```

This allows another machine to independently verify simulation without trusting the original simulator.

Randomness therefore cannot simply be:

```text
local random()
```

Important random events need deterministic seeds.

Examples:

- loot
- AI choices
- procedural events
- hit outcomes
- critical effects
- world generation
- randomized interactions

The seed becomes part of the reproducible event context.

---

# 12. Input Is a Request, Not a Result

A player controls intentions.

The player's machine does not get to declare authoritative outcomes.

Valid:

```text
I attempt Action X against Entity Y.
```

Not valid:

```text
Action X succeeded and Entity Y lost 500 health.
```

The simulator determines the result according to world state and game rules.

Validators can independently verify it.

This principle applies beyond combat.

A client may request:

```text
Move there
Use item
Craft object
Take resource
Open container
Trade item
Interact
Learn ability
Complete task
```

The player does not directly write the resulting authoritative state.

---

# 13. Two Speeds of Truth

One of the most important RealmNode concepts is that not every action needs the same amount of consensus.

There are two broad paths.

## Immediate simulation

Used for things where latency matters.

Examples:

- movement
- aiming
- locomotion
- ordinary combat
- AI movement
- animations driven by gameplay
- short-lived effects

Priority:

```text
responsiveness
```

## Persistent state

Used for changes that become part of the durable history.

Examples:

- item creation
- item destruction
- inventory changes
- currency
- progression
- quest completion
- ownership
- trades
- construction
- major world changes

Priority:

```text
correctness
+
validation
+
durability
```

Strong consensus must not sit in the middle of every movement frame.

---

# 14. Fast Simulation Path

Moment-to-moment gameplay should begin immediately.

Example:

```text
Player Input
    │
    ├── local prediction
    │
    ▼
Regional Simulator
    │
    ├── authoritative result
    │
    ▼
Validators
```

The player can see movement before every validator has finished its work.

If prediction differs from authority, the local state is corrected.

This eventually supports familiar networking techniques such as:

- prediction
- reconciliation
- interpolation
- rollback where appropriate

The distributed architecture sits beneath these techniques rather than replacing them.

---

# 15. Strong Persistence Path

Durable changes receive stronger verification.

Example:

```text
Creature defeated
       ↓
Loot result calculated
       ↓
Persistent transaction proposed
       ↓
Independent validators verify
       ↓
required threshold reached
       ↓
transaction committed
       ↓
replicas store new state
```

An example validator structure from the original design is:

```text
3-of-5 agreement
```

The exact threshold can vary by operation and network size.

The important principle is that important persistent state should not depend on one machine saying that something happened.

---

# 16. Witnessing

RealmNode distinguishes calculation from witnessing.

A node participating in an event may calculate it.

Other nodes can independently witness or verify it.

This is particularly important for small networks.

```text
Actor Node
     │
     ▼
Simulator
     │
     ├── Witness A
     ├── Witness B
     └── Validator C
```

No networked progression should pretend to possess independent validation when only the actor's own machine exists.

This is why solo operation remains local rather than being treated as equivalent to verified community state.

---

# 17. Persistent State Replication

There is no central database containing the only copy of the world.

Persistent state is replicated.

```text
State Shard 417
│
├── Node A
├── Node C
├── Node F
└── Node J
```

A shard may contain:

- character state
- entities
- inventories
- buildings
- settlements
- world regions
- social structures
- progression
- historical events

Replication levels can adapt according to importance and available nodes.

Losing one storage node therefore does not destroy the world.

---

# 18. State Sharding

The world should not exist as one enormous database copied in full onto every machine.

Persistent state can be divided into shards.

Possible shard boundaries include:

- entity groups
- players
- geographic regions
- settlements
- systems
- object ownership
- historical ranges

Nodes only need the state relevant to the work they perform plus whatever replicas they volunteer to store.

This makes the architecture viable as the world grows.

---

# 19. Snapshots

The network periodically creates verifiable snapshots.

Example:

```text
Snapshot

World Generation: 218
State Height: 583102
State Root: 83A912...
Validator Signatures:
A
B
C
D
```

A snapshot establishes:

> At this point, this was the accepted persistent state.

A newly connected node does not need to replay the world's entire history.

It can:

```text
download recent snapshot
        ↓
verify signatures
        ↓
verify state root
        ↓
download newer changes
        ↓
join current simulation
```

---

# 20. Archives

Archive nodes preserve durable world information even when they are not actively simulating the game.

They may preserve:

- snapshots
- state shards
- historical transactions
- update manifests
- ruleset versions
- migration information

Several archives may exist.

None is uniquely authoritative.

A long-running player machine, dedicated community machine, or lightweight headless RealmNode could all perform this role.

---

# 21. World Dormancy

A persistent world does not have to simulate every creature forever while nobody is online.

When no relevant players are present, regions can become dormant.

Instead of continuous simulation:

```text
Region enters dormancy
       ↓
persistent state saved
       ↓
time advances abstractly where necessary
       ↓
region activated later
```

Upon activation, deterministic rules can resolve whatever background progression the game requires.

Persistence therefore does not imply continuously burning CPU across the network.

---

# 22. Cryptographic Node Identity

Every RealmNode receives a cryptographic identity.

Conceptually:

```text
Public Key
Private Key
```

The private key stays local.

Messages can be signed.

Other peers can verify:

```text
This message came from Node X.
```

A signature does not establish:

```text
Node X is telling the truth.
```

Truth still comes from validation.

Identity and validation solve different problems.

---

# 23. Player Identity

Player or account ownership can use the same cryptographic foundation.

A character or player profile can be associated with a public identity.

```text
Character
Owner Identity: 91FA...
```

Requests affecting that character must be authenticated by its owner.

The network then separately checks whether the requested action is legal.

Ownership therefore means:

```text
permission to issue inputs
```

not:

```text
permission to directly modify state
```

---

# 24. Peer Discovery

RealmNodes need a decentralized method of finding one another.

The design can combine:

- cached known peers
- DHT discovery
- multiple bootstrap addresses
- manual peer entry
- LAN discovery
- peers learned from existing connections

Bootstrap machines only introduce nodes.

They are not authoritative servers.

After discovery, the network should be capable of continuing without them.

---

# 25. Direct Connections

When appropriate:

```text
Node A ←────────→ Node B
```

Direct connections generally provide the lowest latency.

However, direct peers can see each other's network addresses.

Direct communication must therefore not be the only supported topology.

---

# 26. Relays

A RealmNode may volunteer to relay traffic.

```text
Node A
  │
 encrypted
  ▼
Relay
  │
 encrypted
  ▼
Node B
```

A relay transports traffic.

It does not gain simulation authority merely because packets pass through it.

A relay does not decide:

- combat outcomes
- inventory
- movement
- progression
- world state

It is network infrastructure.

---

# 27. Connection Privacy Modes

The established networking model allows user-selectable modes.

## Direct

Prefer peer-to-peer connections.

Lowest expected network overhead.

Peers may see each other's public network addresses.

## Prefer Relay

Use relays where useful or preferred.

Direct paths may still be used.

## Relay Only

Do not directly expose the player's address to ordinary game peers.

All applicable traffic passes through relays.

Users can also prefer particular community or trusted relay providers without making those relays authoritative.

---

# 28. NAT Traversal

Many players cannot accept incoming connections directly.

RealmNode should support traversal methods where available.

Possible paths include:

```text
Direct
NAT traversal
IPv6
Port mapping
Relay
```

The game should automatically determine what connectivity is possible.

Players behind restrictive networks can still participate through outgoing connections to reachable relays.

---

# 29. End-to-End Encryption

Peer traffic should be encrypted.

Relayed traffic remains encrypted between the actual endpoints.

The relay may necessarily observe metadata such as:

- addresses
- timing
- packet volume

It should not need to understand the game payload it forwards.

---

# 30. Hostile Network Assumption

RealmNode must be designed under the assumption that every remote node could be malicious.

A peer may:

- lie
- cheat
- send impossible inputs
- send malformed data
- send conflicting state
- impersonate another node
- spam requests
- consume bandwidth
- consume memory
- consume CPU
- deliberately disconnect
- collude with other peers
- run obsolete rules
- attempt protocol exploits

Network trust is never implicit.

---

# 31. Strict Protocol

RealmNode communication uses explicitly defined message types.

Conceptually:

```text
PLAYER_INPUT
STATE_UPDATE
STATE_HASH
AUTHORITY_HANDOFF
VALIDATION_REQUEST
VALIDATION_RESULT
SHARD_REQUEST
SHARD_RESPONSE
SNAPSHOT
PEER_DISCOVERY
TRANSACTION_PROPOSAL
TRANSACTION_COMMIT
```

Remote peers do not get the ability to request arbitrary code execution.

A RealmNode network message must never mean:

```text
execute this program
load this binary
open arbitrary local file
run shell command
```

The protocol surface stays narrow and auditable.

---

# 32. Sandboxing

Network-facing RealmNode systems should operate with the minimum system privileges they require.

Remote gameplay must not grant access to unrelated:

- user documents
- passwords
- system administration
- browser storage
- SSH credentials
- applications
- arbitrary filesystem locations

Game content and network logic should be isolated from the rest of the computer wherever practical.

---

# 33. Resource Protection

Every remotely triggerable operation requires limits.

Examples:

```text
Maximum requests per second
Maximum simultaneous connections
Maximum bandwidth
Maximum simulation jobs
Maximum validation jobs
Maximum memory allocation
Maximum shard requests
Maximum storage contribution
```

A peer should not be able to crash another player's game simply by asking it to perform unlimited legitimate-looking work.

---

# 34. Sybil Resistance

Distributed validation has a fundamental problem:

```text
Attacker
│
├── Fake Node 1
├── Fake Node 2
├── Fake Node 3
├── Fake Node 4
└── Fake Node 500
```

Five hundred identities do not necessarily represent five hundred independent participants.

RealmNode therefore needs Sybil resistance when selecting authorities and validators.

Possible signals include combinations of:

- long-lived node identities
- historical behaviour
- uptime
- contribution history
- network diversity
- independent connection paths
- resource contribution
- reputation
- randomized selection
- rate limits on new identities

None should be treated as perfect proof of independence.

---

# 35. Validator Selection

Validators should not simply be selected by the player whose action is being validated.

Eligible validators can be chosen according to factors such as:

- latency
- stability
- uptime
- ruleset compatibility
- CPU capability
- available bandwidth
- behaviour history
- network independence
- current load

Selection should include unpredictable elements.

The goal is to make it difficult for one participant to surround itself entirely with cooperating fake validators.

---

# 36. Geographic Locality

Simulation should usually occur reasonably close to the participating players.

For example:

```text
Players
Sweden
Germany
Denmark
Finland

Likely simulation group
Northern/Central Europe
```

Validators do not necessarily have to be located equally close if their work is not directly inside the input latency path.

Authority can migrate as the active population changes geographically.

The world therefore has no permanent physical home.

---

# 37. Adaptive Contribution

RealmNode should recognize that player hardware differs.

Example:

```text
Laptop
Weak upload
Battery powered

Contribution:
Player
Light validation
```

```text
Desktop
Fast fiber
Strong CPU
Long uptime

Contribution:
Player
Simulator
Validator
Storage
Relay
```

The network uses available capacity rather than assuming identical machines.

---

# 38. Scaling Large Activity

When many players enter one area, RealmNode can recruit additional simulation capacity.

```text
Normal Region
2 simulators
4 validators
```

becomes:

```text
Large Event
8 simulators
14 validators
multiple partitions
```

Simulation regions can split temporarily.

When population decreases, they can merge again.

Network capacity therefore grows partly with player participation.

---

# 39. Instances

Temporary enclosed activities fit naturally into the model.

```text
Instance
│
├── participating players
├── temporary simulator
├── validators
└── temporary state
```

When it ends:

```text
temporary simulation discarded
```

while validated persistent consequences remain:

```text
items
progression
injuries
quest state
world consequences
```

---

# 40. Failure Recovery

The architecture assumes:

> Any individual machine may disappear at any moment.

Therefore every critical responsibility must be transferable.

```text
Simulator disappears
→ another simulator takes authority

Validator disappears
→ replace validator

Relay disappears
→ select new path

Storage peer disappears
→ use another replica

Archive disappears
→ use another archive

Discovery peer disappears
→ use other discovery paths
```

Node disappearance is an expected condition rather than an exceptional catastrophe.

---

# 41. DDoS Resilience

Traditional architecture:

```text
Players
   ↓
One Server
```

Destroy connectivity to that server and the world disappears.

RealmNode:

```text
Node A
Node B
Node C
Node D
Node E
...
```

There is no permanent simulation endpoint whose failure necessarily stops the entire world.

Attacks may still disconnect individual players or nodes.

RealmNode provides resilience through:

- replaceable authorities
- replicated state
- multiple relays
- multiple discovery paths
- distributed storage
- transferable responsibilities

It is resilient, not magically immune to network attacks.

---

# 42. No Sacred Infrastructure

A proper RealmNode architecture should avoid accidentally rebuilding a centralized server behind the scenes.

There should be no indispensable:

```text
master server
login server
simulation server
database server
relay
bootstrap server
validator
archive
```

Optional infrastructure can exist.

Nothing should be irreplaceable for the world's continued existence.

---

# 43. Ruleset Identity

All nodes participating in the same simulation must execute exactly compatible rules.

A realm session therefore identifies things such as:

```text
Game Version
Ruleset Version
Ruleset Hash
Protocol Version
World Generation
Persistent State Generation
```

Nodes with incompatible rules cannot participate in the same authoritative simulation.

This protects deterministic execution.

---

# 44. Rules Are Data and Executable Logic

The rules defining a world may consist of:

- configuration
- tables
- formulas
- scripts
- behaviour definitions
- AI rules
- item definitions
- interaction logic
- simulation code

They do not have to be physically hardcoded into the RealmNode networking layer.

Conceptually:

```text
RealmNode Core
      │
      ▼
Game Runtime Rules
      │
      ▼
World
```

The important requirement is that every participating node executes the same verified version.

---

# 45. Rule Distribution

Game rules or data packages may be distributed externally.

For example:

```text
Repository
Mirror
Peer
CDN
Local installation
```

The network does not need to trust the download source.

A release is identified by cryptographic hashes and, where appropriate, signatures.

```text
Download package
      ↓
Verify hash
      ↓
Verify release identity
      ↓
Cache locally
      ↓
Execute
```

The repository is a distribution mechanism.

It is not contacted continuously while the world is running.

Nodes execute their locally cached verified rules.

---

# 46. Updates

A new game version creates a new compatible rules generation.

```text
Generation 17
      ↓
Update
      ↓
Generation 18
```

Nodes only simulate together when their required versions match.

Networking-only improvements that do not alter simulation may remain protocol-compatible.

Changes to actual world logic generally require a new rules generation.

---

# 47. Deterministic Migration

An update may change persistent data structures.

Examples:

- new entity fields
- changed item definitions
- removed properties
- changed progression systems
- new world-state structures

The update therefore supplies deterministic migration logic.

```text
Generation 17 State
        ↓
Migration 17 → 18
        ↓
Generation 18 State
```

Every correct node should obtain the same result from the same starting state.

The migrated state can then be validated like other persistent state.

---

# 48. Network Generation Separation

Different incompatible generations must not silently mix.

```text
Generation 17 Network
        │
        X
        │
Generation 18 Network
```

Both may temporarily exist.

They are simply separate logical histories once their rules diverge.

This prevents older clients from corrupting newer deterministic simulation.

---

# 49. Persistent History

RealmNode does not require a cryptocurrency-style blockchain.

Putting every footstep onto a global blockchain would be unsuitable for real-time gameplay.

Instead:

```text
Real-time state
→ temporary regional authority

Important persistent state
→ validated durable history
```

Ledger-like cryptographic structures are useful for persistent events because they provide:

- ordering
- hashes
- provenance
- validation evidence
- tamper detection

They are a persistence tool rather than the game's entire simulation model.

---

# 50. Economic and Ownership Integrity

Any game system where duplication would damage the persistent world requires stronger validation.

Examples:

```text
Create item
Destroy item
Transfer item
Create currency
Spend currency
Trade
Craft
Change ownership
Claim resource
Gain permanent progression
```

The history should allow RealmNode to establish that persistent assets came from valid state transitions.

---

# 51. Reconnection

A reconnecting node does not assume its local state is current.

Conceptually:

```text
Reconnect
   ↓
identify current world generation
   ↓
find trusted recent snapshot
   ↓
compare local state
   ↓
download missing state
   ↓
verify
   ↓
rejoin simulation
```

Conflicting outdated local state does not overwrite accepted network history.

---

# 52. Partitions

A peer-to-peer network can split temporarily.

Example:

```text
Group A

network interruption

Group B
```

Persistent history must not blindly merge incompatible independently progressed states afterward.

The system needs explicit rules governing which modes are allowed to continue producing mergeable state.

This is one reason the community realm has a minimum validation threshold.

Below that threshold, verified community progression stops rather than creating competing histories that later have to be guessed together.

---

# 53. Graceful Degradation

For non-critical responsibilities, RealmNode should degrade rather than immediately collapse.

Examples:

```text
many nodes
→ high replication
→ many validators
→ broad relay pool

fewer nodes
→ lower redundancy
→ fewer optional replicas
→ consolidated simulation regions
```

However, graceful degradation does not override the verification threshold.

Once there are too few independent nodes to satisfy the rules of the verified community realm, that verified mode stops.

Local or small-cooperative play remains a different state category.

---

# 54. Network Health

RealmNode should internally track:

- connected peers
- eligible simulators
- validators
- available relays
- storage replicas
- archive availability
- regional latency
- authority stability
- ruleset agreement
- persistent-state redundancy
- verification strength

The game can expose this simply to the player while retaining detailed diagnostics for development.

---

# 55. The Core Runtime Interface

The game architecture should present RealmNode with a clean simulation interface.

Conceptually:

```text
initialize_world()

load_state()

apply_input()

simulate_step()

calculate_event()

validate_event()

serialize_state()

deserialize_state()

hash_state()

create_snapshot()

apply_transaction()

migrate_state()
```

RealmNode handles:

```text
who calculates
who validates
where state lives
who receives updates
when authority moves
whether state is accepted
```

The game runtime handles:

```text
what the rules mean
how entities behave
what an interaction does
how combat works
how AI chooses actions
what persistent consequences occur
```

This separation is crucial.

---

# 56. Native Game Architecture

For a game designed around RealmNode from the beginning, the ideal structure is:

```text
┌──────────────────────────────┐
│        Presentation          │
│ graphics / animation / UI    │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│       Gameplay Interface     │
│ inputs / commands / events   │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│    Deterministic Runtime     │
│ entities / rules / AI/state  │
└───────────────┬──────────────┘
                │
                ▼
┌──────────────────────────────┐
│          RealmNode           │
│                              │
│ authority                    │
│ replication                  │
│ validation                   │
│ persistence                  │
│ networking                   │
│ identity                     │
│ recovery                     │
└──────────────────────────────┘
```

The deterministic runtime should not need to know whether it is currently being executed:

- locally
- by another player's machine
- by a validator
- by a background node

It receives state and inputs and produces deterministic results.

That property makes distributed execution possible.

---

# 57. Central Security Invariant

A RealmNode never trusts another node merely because it exists.

Trust comes from combinations of:

```text
Cryptographic identity
+
Deterministic rules
+
Independent witnesses
+
Validation
+
Replication
+
Persistent history
```

---

# 58. Central Availability Invariant

No single machine permanently owns anything necessary for the world to continue.

Responsibilities can be:

```text
replicated
transferred
recalculated
reassigned
recovered
```

---

# 59. Central Simulation Invariant

Players submit intentions.

Authoritative simulation produces consequences.

```text
Input
≠
Result
```

---

# 60. Central Persistence Invariant

Immediate gameplay and permanent history are different problems.

```text
Immediate simulation
→ optimize for responsiveness

Persistent changes
→ optimize for verification
```

---

# 61. Central Determinism Invariant

A simulation event must be reproducible.

```text
State
+
Input
+
Seed
+
Rules
=
Result
```

---

# 62. Central Version Invariant

Only compatible nodes participate in the same authoritative world.

```text
same rules
same generation
compatible protocol
compatible state
```

---

# 63. Central Network Invariant

Any peer may disappear.

Any peer may lie.

Any peer may be hostile.

The architecture must continue operating safely under those assumptions.

---

# 64. Core RealmNode Loop

At the highest level:

```text
PLAYER INPUT
      │
      ▼
LOCAL GAME
      │
      ▼
REALMNODE
      │
      ├── determine authority
      │
      ▼
SIMULATION
      │
      ├── immediate result
      │
      ├── replicate transient state
      │
      ▼
VALIDATION
      │
      ├── reject invalid result
      │
      └── accept valid result
      │
      ▼
PERSISTENT TRANSACTION
      │
      ▼
REPLICATION
      │
      ▼
WORLD STATE
```

For non-persistent events the lower stages may be unnecessary.

For major persistent events the entire chain is used.

---

# 65. What Disappears in the Game-Native Version

The generic RealmNode ecosystem does not need to exist inside this version.

The game-native architecture does not require:

- a game browser
- multiple supported games
- external client adapters
- localhost pretending to be a traditional server
- protocol translation for legacy clients
- expansion/version adapters for unrelated games
- generic publisher discovery
- forks appearing in a launcher
- WoW-specific compatibility infrastructure

Those existed because RealmNode was originally conceived as a general runtime capable of wrapping existing games.

A game built natively around RealmNode can bypass all of that.

---

# 66. What Remains

The actual RealmNode architecture is:

```text
Distributed deterministic simulation
+
Temporary authority
+
Independent validation
+
Replicated persistent state
+
Cryptographic identities
+
Signed communication
+
Peer discovery
+
Direct and relayed networking
+
Dynamic simulation regions
+
Authority handoff
+
Snapshots
+
Archives
+
Ruleset/version agreement
+
Deterministic migrations
+
Failure recovery
+
Sybil resistance
+
Hostile-peer protection
+
Resource contribution controls
```

That is the core technology.

---

# 67. The Final Mental Model

Do not think:

```text
Player clients
      ↓
RealmNode server
```

Think:

```text
        PLAYER A
        Game + Node
            │
            │
PLAYER B ───┼─── PLAYER C
Game + Node │    Game + Node
            │
            │
        PLAYER D
        Game + Node
```

The lines between them collectively form:

```text
THE SERVER
```

Each node contains the knowledge necessary to run the game.

Authority moves between them.

Simulation is reproduced and checked.

Persistent state is distributed between them.

No participating machine is permanently the host.

No participating machine is automatically trusted.

No single participating machine contains the only surviving copy of the world.

RealmNode is therefore not merely peer-to-peer networking.

It is a distributed server architecture in which the server emerges from the participating copies of the game.
