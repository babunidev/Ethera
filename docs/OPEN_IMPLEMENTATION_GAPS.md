# Open implementation gaps

These are not invitations to invent gameplay. Keep them visible until Alex decides or a later milestone specifies them.

## Architecture decisions Alex has settled

Recorded in the concept under `99_Development/Design_Decisions.md` and `RealmNode_and_Technical_Foundation.md`. The parts that constrain this repository are implemented; the rest constrain future work.

Implemented and covered by tests:

- **Fixed authoritative clock.** 20 ticks per second, world time derived from the tick count, frame deltas rejected. Three real seconds is three world seconds at every frame rate from 24 to 240.
- **Quantized authoritative values.** Position, yaw and the Shard Fit alignment snap to power-of-two grids so platform trigonometry cannot flip an outcome or a hash.
- **In-flight state lives in the world.** `active_round`, `walk_motor` and `focus_hold` moved off `EtheraSimulation` onto `EtheraWorld`, so a snapshot or a handoff carries a running interaction.
- **Hidden knowledge stays authoritative.** `query_panel` serves knowledge only for the inhabited character; the Fountain never hands its contents to a client.
- **Closed presentation boundary.** Nothing under `scripts/presentation/` reads runtime internals.
- **Authored interaction results.** Shape Weapon and Echo Imprint results live in `data/interactions.json`. `EtheraResults` interprets them; a third interaction using existing result types needs no new runtime code. Unrecognized types fail closed.
- **Snapshots, hashes and restore.** `create_snapshot` / `state_hash` / `restore_snapshot` round-trip, including through JSON. Identical command sequences hash identically.
- **Command journal and skill samples.** Every command is recorded with the tick it arrived. A skill phase keeps timestamped cursor samples rather than a reported score. `replay()` reconstructs the world from the journal.
- **Local item commits.** Pickup, swap and shaped equipment apply immediately and store `commit_status: committed` plus a transaction record. Remotely leaving a transfer pending is later work.

Settled, and now constraining how new work is written:

- **The authoritative runtime will be Rust**, in its own crate beside `realmnode-core`. Authoritative GDScript is temporary. New game rules go into authored data or behind the command/query boundary — never into Godot types.
- **Validators verify legality, not dexterity.** A skill phase submits timestamped input samples; the runtime calculates the score. An actor never reports its own outcome.
- **Items commit in two speeds.** Immediate to the player, `PENDING → VALIDATING → COMMITTED` underneath, reconciled only on failure.
- **Disconnect cancels an uncommitted round**, never a committed consequence. This already matches the cancel path in `_cancel_round`.
- **Regions without players go dormant, not frozen**, resolving life abstractly.

## Architecture work this repository still owes

Ordered by what unblocks the most. None of these require a gameplay decision.

1. **Remote validation of item transfers.** Locally a pickup is accepted and committed in the same apply. A networked node should still feel the pickup immediately while the durable transaction can sit at `pending` / `validating` until validators accept it, and reconcile only on failure.
2. **Fixed-point arithmetic.** Quantization bounds the divergence; the Rust runtime should represent these values exactly instead.

## Design decisions Alex has settled

These were open questions. They are now implemented and covered by tests.

- **Echo Imprint new-event recipients.** Both participants learn the new event Shard. Khar-Morr therefore has no record the Fountain lacks afterwards, so the interaction correctly becomes unavailable instead of offering its own event as the next contribution. After one successful imprint each side knows two records.
- **Pickup range.** Khar-Morr walks to the item and takes it on arrival. A click already inside `pickup_reach` takes it immediately with no walk. The displaced club still lands on the clicked club's exact former ground position.
- **Hold-focus movement pace.** Holding left click to open the radial scales her walking speed by `focus_hold_speed_scale`. The cap eases down rather than snapping, and releasing restores the full pace.
- **Right-click during an authored approach.** A new walk destination abandons an approach that has not yet reached its skill phase. The round resolves nothing, so it creates no Shard and no history entry. A skill phase that has already started keeps movement and ignores walk commands.
- **Approach from the current side.** Shape Weapon, Echo Imprint, and later authored interactions stand on the ring at `approach.distance` on the side the actor is already on. A single stand point is not used.

## Design questions intentionally not implemented

- Save/reload. Leaving a life and inhabiting another is in play; the person left behind keeps their own state and does not yet resume an AI routine.
- An authored injury Need. Task selection can already yield the priority stone when a state lists `impossible_task_ids` and `resolving_task_id`. Milestone 3 does not author that state, and clearing it does not move the stone back.
- Whether pickup or failed skill attempts enter the 100-entry interaction history
- Fountain permanence flags, retention clocks, archival stones, Echo Cradle
- Combat injuries beyond the blocker-filter shape and healthy body regions
- Random skill-phase pool draw (Milestone 1 interactions specify exact phases)
- Grass patch refill/regrow after harvest. Empty patches already sink out of sight and would rise if contents and `opened` were restored; no timed growth loop is authored yet.

## Engine work still open

- Pathing across irregular environment meshes. Occupancy-disk A* already routes around the Fountain, the rock, containers, landmarks, other characters, and authored hex scenery (bushes, benches, Echo Cradles). Grass patches occupy nothing. Ground steeper than 50° is a wall on the current slope sampler. Environment GLBs get mesh collision for picking. The starting hex is the authored 256 m tile; simulation `y` stays 0. Growing the map is more authored hexes in the layout, not a second loaded scene. Binding walkable slope to the authored sculpt is later work.
- Dedicated Shape Weapon and Echo Imprint animations. Idle and Walk already play from the Mixamo-rigged sculpt.
- Final camera limits after the real silhouette is in
- Hold/drag/click disambiguation polish
- Replacing primitive meshes with GLBs
- Additional authored hexes and destiny-driven hex spawning. The starting hex is already the sculpted Low Poly tile with locked flat edges.

## Implementation definitions already chosen

- Unmanifested rock keeps `entity.shapeable_rock`
- Echo Imprint auto-selects up to three eligible known Shards in insertion order
- Pickup writes a Shard known only by the picker and replaces the previous pickup Shard for the same item
- Failed skill phases create no Shard and do not apply world results
- Only successful rounds enter the 100-entry interaction history
- Unrecognized requirement condition types fail closed, so a typo hides an action instead of granting it
- Unrecognized result types and missing result lists fail the round closed and write nothing
- Interaction results, selection and event-record recipients are authored in `data/interactions.json` and interpreted by `EtheraResults`
