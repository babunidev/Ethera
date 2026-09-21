# Open implementation gaps

These are not invitations to invent gameplay. Keep them visible until Alex decides or a later milestone specifies them.

## Design decisions Alex has settled

These were open questions. They are now implemented and covered by tests.

- **Echo Imprint new-event recipients.** Both participants learn the new event Shard. Khar-Morr therefore has no record the Fountain lacks afterwards, so the interaction correctly becomes unavailable instead of offering its own event as the next contribution. After one successful imprint each side knows two records.
- **Pickup range.** Khar-Morr walks to the item and takes it on arrival. A click already inside `pickup_reach` takes it immediately with no walk. The displaced club still lands on the clicked club's exact former ground position.
- **Hold-focus movement pace.** Holding left click to open the radial scales her walking speed by `focus_hold_speed_scale`. The cap eases down rather than snapping, and releasing restores the full pace.
- **Right-click during an authored approach.** A new walk destination abandons an approach that has not yet reached its skill phase. The round resolves nothing, so it creates no Shard and no history entry. A skill phase that has already started keeps movement and ignores walk commands.

## Design questions intentionally not implemented

- Discovery hover events (Milestone 2)
- Needs, Divine Orientation, greeting, inhabitation switching, save/reload
- Whether pickup or failed skill attempts enter the 100-entry interaction history
- Fountain permanence flags, retention clocks, archival stones, Echo Cradle
- Combat injuries beyond the blocker-filter shape and healthy body regions
- Random skill-phase pool draw (Milestone 1 interactions specify exact phases)

## Engine work still open

- Navmesh / collision for the real environment
- Animation (idle, walk, Shape Weapon, Echo Imprint)
- Final camera limits after the real silhouette is in
- Hold/drag/click disambiguation polish
- Replacing primitive meshes with GLBs
- Renderer choice after materials exist (project currently uses GL Compatibility)

## Implementation definitions already chosen

- Unmanifested rock keeps `entity.shapeable_rock`
- Echo Imprint auto-selects the first eligible known Shard in insertion order
- Pickup creates no Shard
- Failed skill phases create no Shard and do not apply world results
- Only successful rounds enter the 100-entry interaction history
- Unrecognized requirement condition types fail closed, so a typo hides an action instead of granting it
- Interaction results are applied in `EtheraSimulation`, not authored in `data/interactions.json`. Requirements, targets, approach and skill-phase selection are data. Adding a third interaction means extending the result code as well, so authored effects remain future work relative to the entity-architecture document.
