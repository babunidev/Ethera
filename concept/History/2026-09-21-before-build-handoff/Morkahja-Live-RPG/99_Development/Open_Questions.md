# Open Questions

## Latest unanswered question

**Question 400:** which input opens and closes the Milestone 1 character panel: the HUD stone/button or a keyboard key?

## Milestone 1 decisions to finish

- Who receives the new event Shard created by Echo Imprint? Its own event is agreed, as is retaining the contributed reference in Khar-Morr. A later example shows her retaining only one Shard and Imprint becoming unavailable. If she learns the new event and the Fountain does not, another contribution is immediately eligible. Resolve the recipients and expected counts explicitly.
- Define manifestation identity so consumed/reused rock content preserves historical target and place references. Tune placement, navigation, camera, input thresholds and skill timings during implementation.

See [Milestone 1](Milestone_1_Khar_Morr.md) and [Prototype Readiness](Prototype_Readiness_Review.md) for the settled scope and build choices.

## Knowledge and archival edge cases

- Absorb Knowledge can recover an old archived Shard, while ordinary character knowledge expires one world week from original creation. How long is an already-expired archived record usable after reading? The current decisions do not specify a grace period or exception.
- How does the Fountain's generated solution/location Shard fit the immutable factual event model when no earlier mortal observation exists? Define what the consultation event establishes and how its solution reference supports guidance.
- Specify direct character-to-character teaching after the split into Fountain contribution by Echo Imprint and retrieval by Echo Attunement. The former bidirectional Attunement rule is superseded. The exact automatic tie-break among several eligible Imprint or needed Attunement records remains an authoring choice.
- Which participants, observers or objects gain the newly created event Shard? What happens when a known event references another Shard the recipient has never learned?
- Which links count as retention references, especially event-to-event results? Decide cycle handling and retention for records still referenced by task or history data without treating them as known by the character.
- Does a failed attempt enter the separate 100-entry interaction history? It creates no event Shard. Define log entry timing and its relation to the immutable event store.
- Can a duplicate of a Shard already in the same archival stone occupy another slot? Preservation in multiple different stones is explicitly allowed.
- What are ordinary memory-stone capacity and filling rules? The three-slot rule is selected for archival stones.
- How are interrupted socketing, carried-stone reservations and return to inventory handled? What happens if a stone is lost, its holder disconnects, or an Echo Cradle changes during an interaction?
- Define empty-transfer availability for Absorb Knowledge. Echo Imprint requires an actor-known Shard the target lacks; Echo Attunement requires available needed knowledge.
- Which event definitions carry authored Fountain permanence? Permanent relationship states and knowledge retention must remain consistently represented.

## Combat and interaction execution

- Later milestone content: exact greeting, Need/task/guidance example, spectator controls and minimal AI handoff routine. Milestone 1 scene/cast/actions and Milestone 2 discovery scope are established.
- Final name and exact requirements for the defensive perception/targeting Trait; Keen Eye remains a working suggestion. Aimed Attacks is named and selected.
- Skill challenge timing, visuals, accessibility, AI execution and target selection. Sequence is selected: availability, action, targeting, skill, reaction, world result, Shard.
- Several-participant combat scheduling, timeouts, interruption, disengagement and multiplayer slowdown.
- Body diagrams, repeated injuries, treatment and transitions to incapacity or Atranor. Mountain Strike produces binary injury; older stun/knockout side effects are not current Mountain Strike rules.
- Whether any protection reset/resource limit remains necessary under the selected reaction-per-attack model. Earlier armor-count and protected-region alternatives remain historical proposals.
- Exact requirements, skill phases, animation and sound for the other foundational interactions; separate spear attacks; Living Stone Adornment effects, limits and removal; Inner Harmony requirements and relation to fatigue.
- Cancellation when world circumstances invalidate an intended action, keeping capability eligibility distinct from the skill success check.

## Characters and community

- Preference inheritance and youth expression within the retained 27 personal Traits; initial reveals and birth duplicate/reroll policy.
- Dynamic role scoring, ties and title catalogue.
- Youth support allocation, adulthood ritual participation, reproduction interruption and resumed Destiny.
- Direction/counting of distinct relationship matching pairs, age-specific interactions and choreography; Recall Knowledge layout and teaching provenance.
- Temporary-state values, refresh, outing boundaries, reconnect handling and recovery; Essence replenishment rates.

## Tasks, progression and the world

- Reservations and revalidation of shared solutions, unique-object loss, consumed supplies and concurrent Needs.
- Final-branch reward timing relative to Knot completion; Crest merge prerequisites and generation weights.
- Priority fallback after completion/cancellation, checklist detail and acknowledgment of highlighted Needs. Task steps are suggested order; actual completion conditions govern.
- Tile size, adjacency, density and allocation, streaming budgets, ruins/ecology and construction impacts.
- Item body slots, containers, physical attachments and crafting contributions.
- Camera/focus gesture conflict, radial overflow, quick keys, optional fog of war and screenshot framing.
- Interpreting available event records into useful current knowledge, source-versus-exact-object solution locators and optional personal clearing.

## Technical foundation and multiplayer

- Concrete entity/data formats, editor, validation and reproducible generation; stable ID generation and synchronization across RealmNode.
- Cache versions, dependencies, definition changes and precise invalidation when Shards expire or are learned.
- RealmNode authority, consensus, replicas, commits, snapshots, recovery and reference nodes; world-time retention during active simulation and frozen periods.
- Godot version, runtime configuration, measured capacity and integration details. Godot and Blender are selected; installation/build status needs verification in implementation work.
- Queue offer size, timer and ordering; approximately ten-minute reclaim timing and stand-in interruption.
- Atranor challenge content, repeat visits, AI defeat and exact drop location.
- Deliberate-disruption protections, deferred until actual community behavior informs them.

## Grimnir worldbuilding

- Echo Cradle physical/visual/audio design and detailed production settings for the selected Memory Fountain references. The Fountain's basin, crystal/stone form, water, palette, light and sound direction are established.
- Sacred motifs and awakening knowledge, including Khar-Morr and the Spiral Forge-Ring; first-settlement chronology.
- Detailed homes, work spaces, nursery bath, resting stones and gathering areas.
- Birth stability, shared final shaping and support-gated youth.
- Funerary memory relative to Atranor, ancestral echo status, stonebound recovery and Crumblegheist corruption.
- Later Skylands, Skykeepers, clans, Convergence institutions and contact with other peoples.
- Northern versus southwestern/Celesterra geography and Convergence Core's exact form.

The [update reconciliation](Update_Through_Answer_341.md) records resolved and replaced rules. Original discussion remains in the [source archive](Source_Archive.md).

## Reusable skill phases and Cradle authoring

- Difficulty policy from the earlier unanswered question 359, phase-specific tuning, accessibility, empty-pool behavior and random-selection weights. The number 359 was reused when prototype questioning began; the earlier difficulty question was never answered.
- Final phase or pool assignment for Bind Shard, Absorb Knowledge, Memory Binding and Echo Attunement. Shard Fit is selected for Echo Imprint; Shape Trace is selected for Shape Weapon.
- Review the requested 72-phase draft before treating each candidate as an approved implementation. The twelve subcategories and approximate six-per-pool target are selected.
- Exact Create Echo Cradle suitability/capability Traits, knowledge alternatives and material recipe. Its world-object replacement behavior is settled.

## Discovery and later milestones

- Is Discovery created once per character/entity, or can subsequent hovers create new observations? The question was deferred when discovery was assigned to Milestone 2.
- Does inherent pickup create an event Shard, and what are its record/recipient rules? Pickup is settled as a direct action; no new Shard rule is assumed from that classification.
- Complete the later milestone recipes, choose persistence placement in the working sequence and define save/reload boundaries.
- Define full-bag capacity and the initial/continued cyclic swap pointer. The first milestone only uses the Small Weapon slot.
