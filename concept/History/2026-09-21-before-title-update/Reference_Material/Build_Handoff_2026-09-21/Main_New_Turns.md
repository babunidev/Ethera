# New main discussion

## Turn a98e2a42-f0cb-4ad5-8ae5-1b89d1c0853e

### User

We are gonna have a key, keybind. We bind the key C for the character panel. Very, very traditional.

### Assistant

Good. **C opens and closes the character panel** for Milestone 1. Simple and familiar.

That means we have the panel input settled without needing the HUD stone/button yet.

### Question 401

One implementation detail we should lock down for item handling:

When Khar-Morr **left-clicks a weapon on the ground and swaps it with her equipped club**, where should the old club appear?

My assumption is **exactly where the picked-up weapon was lying**, so visually the two weapons simply exchange places.

## Turn 281de008-696f-4fdf-ade1-965da4e3828a

### User

That is functional script. I think we do it like that. It swaps it to the exact position of the one that we pick up.

### Assistant

Yes. Then the pickup/swap rule is settled:

**left-click ground weapon → equipped weapon moves to the exact world position of the clicked weapon → clicked weapon takes the Small Weapon slot.**

So visually they really exchange places.

At this point, I think we have answered nearly all the gameplay questions that actually block **Milestone 1**. I would not keep drilling into tiny implementation details that can simply be tuned in Godot.

The one thing I still need to make the milestone unambiguous is its **completion condition**.

### Question 402

When do we declare **Milestone 1 successful**?

My reading is: Khar-Morr can move around, Shape Weapon from the rock, equip/swap the two colored clubs, inspect her data with **C**, carry the resulting event Shard, successfully **Echo Imprint** it into the initially empty Memory Fountain, and the development log/panel verifies the resulting state.

Is that the complete acceptance test?

## Turn 6d3c4d6a-1b71-4955-9b10-a494def2b6d0

### User

Yeah, that sounds good. And of course, it includes the assets, the... yeah, so we can see stuff. We can see the fountain, simple landscape, and we... yeah, we are in a game world. Do we now already need to think about that it's gonna be a peer-to-peer multiplayer experience? Or can we first make, like, the architecture for a single-player environment? Or does it even matter now?

### Assistant

Yes, we can absolutely build **Milestone 1 as a local single-player experience first**. We do **not** need to implement realmNode, networking, replication, validation, peer discovery, or multiplayer handoff yet.

But there is one important distinction:

**Build it single-player, but don’t architect it as a single-player game.**

For Milestone 1, Godot can have one local simulation running everything. We just preserve a few boundaries now so we do not have to tear the game apart later.

The important ones are:

- Every world entity already has a **stable ID**. Khar-Morr, Fountain, rock, clubs, Shards, etc.
- The **world owns the characters and objects**, not the local player.
- The player controller merely says, effectively, *“I currently inhabit Khar-Morr.”*
- Interactions modify the **world state**, not some private player inventory/state.
- Shards, Traits, equipment and entity states live on the entities themselves.
- UI reads that data but does not become the authoritative source of it.
- Interaction outcomes go through the interaction system rather than arbitrary scripts directly changing ten different objects.
- The visual scene and the underlying entity/state data should be separable enough that later realmNode can replicate the **state**, rather than trying to synchronize Godot objects themselves.

For example, when Shape Weapon succeeds, we should think:

**World simulation:**  
Rock entity is no longer manifested → club entity is manifested/equipped → Khar-Morr equipment changes → event Shard is created.

Then Godot simply **shows** those changes.

Later, realmNode can eventually be the thing that distributes and validates that same state change between machines.

What we should **not** do yet is start building a fake multiplayer layer, networking messages, prediction, rollback, validators, peer consensus, etc. That would slow Milestone 1 enormously before we even know whether walking up to a rock and shaping a club feels good.

So I’d say:

**Milestone 1 = local authoritative simulation.**  
**Architecture = world/entity based and networkable later.**  
**Actual P2P = later milestone.**

That is enough preparation for now.

And yes, the Milestone 1 acceptance test also includes the actual visual game space: **Khar-Morr’s low-poly model, the Memory Fountain, simple terrain, rocks, clubs, camera, interaction graphics, and enough environmental presentation that it feels like standing inside an early piece of Morkahja rather than debugging gray boxes.**

### Question 403

Before implementation, I think the next thing we genuinely need is the **basic visual/environment direction for that little terrain patch**. Do you want it already to resemble the early Grimnir savanna/rocky settlement atmosphere, just extremely simple and low-poly?

## Turn 54e07eb5-d9c9-4289-8793-69bc6e3a27ed

### User

environment brief:

- **Composition:** A small village-center terrain patch, with an open gathering space reserved for the **Memory Fountain**, placed later as its own object.
- **Architecture:** Low, organically shaped stone structures partially enclosing the gathering space. Walls flow into supports, seats, and shallow alcoves. Joined stone becomes one continuous mass.
- **Style:** **Low-poly**, using broad, deliberate facets to describe rounded, flowing silhouettes. Avoid right-angle corners, rectangular doorways, masonry seams, and chisel marks.
- **Ground:** Uneven exposed bedrock blending into compacted earth, scattered gravel, and worn footpaths converging on the fountain space. Keep the central placement area relatively level.
- **Supporting objects:** A few seats shaped into the surrounding stone.
- **Nature and light:** Sparse grass, small patches of moss in sheltered cracks, warm daylight, and open sky.

**Overall feeling:** grounded, intimate, and gently magical—a place shaped through patient care, with continuous stone forms rising naturally from the terrain.

### Assistant

Locked in.

## Milestone 1 Environment Brief

### Scene purpose
A **small village-center terrain patch** that serves as the first playable space.  
Its main purpose is to frame and support the **Memory Fountain**, which will be placed later as its own separate object.

---

## 1. Spatial composition

- The scene is a **small central gathering area**.
- At the center is a **relatively level open placement space** reserved for the Memory Fountain.
- Around that center, the terrain and structures create a **soft partial enclosure**, not a hard ring.
- The place should feel like a **settlement heart**, not a wild isolated ruin.
- The player should be able to read it immediately as:
  - central communal place
  - shaped by inhabitants
  - still early and simple

---

## 2. Architecture

- Use **low, organically shaped stone structures**.
- Structures should feel as though they were **grown or shaped from continuous stone**, not built from blocks.
- Walls, seats, supports, edges, and alcoves should **flow into each other**.
- Stone should appear as a **continuous mass**, with smooth transitions between architectural functions.

### Architectural rules
Avoid:
- right-angle corners
- rectangular doorways
- visible masonry seams
- brick/block logic
- carved chisel-mark aesthetics
- “stacked stone hut” look

Prefer:
- rounded or faceted curved silhouettes
- shallow openings and recesses
- broad, grounded forms
- continuous transitions from terrain into architecture

---

## 3. Style

- **Low-poly**
- Use **broad, deliberate facets**
- The forms should still read as **soft and rounded in silhouette**, even though they are polygonal
- The low-poly look should feel intentional and aesthetic, not placeholder-random

### Style target
- low geometric density
- clear silhouette
- readable planes
- restrained detail
- no noisy surface treatment

---

## 4. Ground treatment

The ground is a blend of:

- uneven exposed **bedrock**
- compacted **earth**
- scattered **gravel**
- worn **footpaths**

### Ground rules
- The terrain should not be flat overall
- The fountain placement area should be **comparatively level**
- Footpaths should visibly **converge toward the fountain space**
- Ground transitions should feel natural, not tiled or sharply bordered

---

## 5. Supporting objects

Include only a few simple supporting environmental elements:

- a few **stone seats**
- seats should be **integrated into surrounding stone**, not separate furniture objects
- shallow resting ledges / alcove-like sitting places are good

Do not clutter the scene with extra props yet.

---

## 6. Nature

Keep nature sparse and restrained.

Include:
- sparse grass
- small moss patches in sheltered cracks
- open sky feeling
- a little softness in the environment without overwhelming the stone identity

Do not include:
- dense vegetation
- large trees
- lush fantasy overgrowth
- busy flora dressing

---

## 7. Light and atmosphere

- **Warm daylight**
- Open and calm
- Clear visibility
- Slightly sacred feeling, but subtle
- The place should feel:
  - grounded
  - intimate
  - gently magical
  - patient
  - communal

It should not feel:
- grandiose
- ruined
- harsh
- militarized
- urban
- heavily decorated

---

## 8. Visual identity statement

This is a place shaped through **patient care**.  
The stone is not merely construction material. It is a living, continuous medium of settlement, memory, and gathering. The environment should feel like the earliest stable expression of Grimnir communal life.

---

## 9. Implementation-ready asset scope for Milestone 1

### Terrain / environment pieces
- 1 small terrain patch
- 1 central fountain placement area
- 2–4 low stone structure masses
- 3–6 integrated stone seat forms
- ground material variation for:
  - bedrock
  - compacted earth
  - gravel
  - path wear
- sparse grass and moss dressing

### Excluded for now
- finished Memory Fountain model integration logic
- advanced VFX
- animated environmental effects
- large village expansion
- detailed interior spaces
- dense settlement population dressing

---

## 10. Practical build reading

If someone builds this for Milestone 1, the result should be:

- a small playable outdoor scene
- clearly centered around an empty place for the Memory Fountain
- readable as early Grimnir settlement architecture
- low-poly and stylized
- simple, calm, and usable for testing movement, camera, interaction, and world presence

## Short version

**Build a small low-poly Grimnir village-center.**  
Use continuous shaped stone architecture around a level central fountain space.  
Blend exposed bedrock, earth, gravel, and worn paths.  
Add a few integrated stone seats, sparse grass, small moss patches, warm daylight, and an open sky feeling.  
Keep the place intimate, grounded, and gently magical.

## Turn 90404de4-b4ff-4be8-863e-dec09d645823

### User

All right, is there anything else missing, or are we ready for this milestone?

### Assistant

Yes. **Milestone 1 is ready to build.** I don’t see another gameplay-design decision that needs to block implementation.

What we have now is enough to hand to the implementation side without asking it to invent game rules.

### Milestone 1: locked scope

**World**
- Windows desktop, mouse + keyboard
- Godot
- small low-poly Grimnir village-center environment
- Memory Fountain at the center
- one `Rock + Shapeable` object
- second differently colored stone club on the ground for swap testing

**Khar-Morr**
- female Grimnir using the bare low-poly reference
- body regions: `Head`, `Torso`, `Arms`, `Legs`
- starts healthy
- Traits:
  - `Grimnir`
  - `Weapon Shaping`
  - `Echo Imprint Trait`
- no Shards
- no negative states
- one empty `Small Weapon` slot
- equipped small weapon appears on her back

**Movement / camera**
- right-click destination movement
- smooth acceleration and deceleration
- normal walking tempo
- no player-controlled walk/run/sprint modes
- left-drag on Khar-Morr rotates camera
- camera never automatically rotates or corrects itself
- mouse wheel zoom
- broad zoom range

**Interaction controls**
- hover interactable object
- hold left mouse → radial menu
- only currently valid interactions appear
- release toward interaction to select
- character automatically approaches, positions and faces target

**Shape Weapon**
- Actor requirement: `Weapon Shaping`
- healthy usable `Arms`
- Target Traits: `Rock` + `Shapeable`
- Combat → Weapon Craft
- first skill phase: **Shape Trace**
- Shape Trace:
  - symbolic low-poly/golden graphic
  - checkpoints across the weapon shape
  - checkpoints can be touched in any order
  - missed points can be revisited
  - visual integrated timer
  - failure only if not completed before time expires
- successful rock disappears from its current manifestation
- creates stone club
- club Traits:
  - `Weapon`
  - `Stone Weapon`
- club equips immediately
- occupied slot → previous club appears on ground
- successful interaction creates its Event Shard

**Event Shards**
Already-established common format:
- unique Shard ID
- Actor ID(s)
- Target ID(s)
- one Action ID
- Reaction ID(s) or `None`
- Result ID(s)
- Place ID
- exact world time

No Shard if the player-skill phase fails.

**Memory Fountain**
- starts with zero Shards
- has `Echo`
- Khar-Morr can use **Echo Imprint**

**Echo Imprint**
- Actor: `Grimnir` + `Echo Imprint Trait`
- Target: `Echo`
- available only when Khar-Morr knows at least one Shard the Fountain does not
- automatically chooses one eligible Shard
- Fountain gains access to the **same Shard**, not a duplicate
- Khar-Morr keeps it
- first skill phase: **Shard Fit**
- position symbolic shard over matching recess
- shard angle moves
- click when position/alignment is correct
- wrong click simply continues
- visual integrated timer
- Echo Imprint itself creates an Event Shard

**Pickup / swapping**
- inherent action, not Trait interaction
- left-click ground weapon
- empty slot → pick up
- occupied slot → swap
- old weapon takes the exact ground position of the clicked weapon
- swap cursor makes this clear
- only Small Weapon slot needed for now

**UI / development feedback**
- `C` opens/closes simple character panel
- text/list presentation is enough
- panel exposes enough data to inspect:
  - Traits
  - body/state
  - Shards
  - known interactions
  - Small Weapon slot
- top-right development event log
- real radial interaction menu included

**Assets**
- Khar-Morr low-poly model from your references
- Memory Fountain from your existing reference
- low-poly environment from the environment brief
- simple shapeable rock
- two visually distinguishable stone clubs
- very simple Shape Trace and Shard Fit graphics

### Explicitly deferred

We do **not** need for Milestone 1:
- second Grimnir
- greeting/social NPC interaction
- Discovery
- Needs/tasks
- Divine Orientation
- spectator/inhabitation switching
- AI routines
- save/load persistence
- RealmNode/P2P networking
- full locomotion animation
- other inventory slots
- Echo Attunement
- archival stones/Echo Cradles
- full 72-skill-phase library

Networking should be kept in mind structurally, meaning stable entity IDs and world-owned state, but **nothing networked needs to be built yet**.

The remaining unknowns are things like exact walking speed, acceleration curve, interaction distances, skill-phase timer lengths, collision dimensions, camera zoom limits, polygon counts, and so forth. Those are **implementation/playtest tuning**, not missing design.

So yes: **Milestone 1 has crossed from design into buildable specification.**
