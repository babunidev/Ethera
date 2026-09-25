# Interactions — source conversation

Thread: 6aa87c2d-9e64-83ed-876d-fabb84b62be7

## Turn bd081ee5-23df-47d1-8246-1643b6df72d3

### User

i will give you informations about the feature we design here and you will for now jsut say "got it" until i instruct you further

### Assistant

Got it.

## Turn c9856be7-74ea-4c15-9710-28264a85f991

### User

# Interactions, Discovery and Player Skill

Interactions connect a character's capabilities to the current situation. Traits, preferences, Needs, Shards, items, body condition, relationships and surroundings determine which actions are possible.

## Authored requirements

Each interaction has complete requirement groups, a target, a player skill phase and results. Conditions within one group must all be satisfied. Alternative groups offer different valid ways to unlock the same action.

Likes Kind on one person and Kind on another can enable a greeting. A climbable surface and a usable climbing capability can enable ascent. A spear interaction can require the weapon, the attack Trait, a healthy body part and an appropriate target.

Several enabling sources still produce one available action. The explanation can show all relevant reasons.

## Discover through play

An interaction becomes known when play reveals it in a fitting situation: a meeting, an exploration, an item, a quest or a combat encounter. Undiscovered actions stay concealed.

Once discovered, the interaction remains in the character's panel. Its entry explains the requirements and any current blockers. Losing a tool or injuring an arm changes current usability while preserving the record of discovery.

## Focus and choice

Right click sets a movement destination. Hover offers a subtle cursor cue. Holding left click focuses a target and opens its radial actions while slowing the participant's pace.

The wheel contains the discovered actions executable in the current situation. Slots fill dynamically with the current choices. Select through the displayed input, and the character takes up the intention, approaches and faces the target.

The character panel remains the place to inspect known blocked actions. During action selection, the available wheel reflects the present encounter.

## The skill phase

The player performs the interaction's authored challenge. Timing, observation, memory, pattern recognition, sequencing or a suitable response can give an action its character.

A simple interaction can involve applying pressure, setting an angle, moving a lever or following a rhythm. Combat can involve body-part selection and timing. Mountain Strike's display begins during approach, with the click committing the attack.

Character capabilities determine what can be attempted. Player execution determines how the action resolves.

## Results and retrying

Results can change state, create or transform items, copy knowledge, develop relationships or fulfill Needs. Failure costs time and can change the situation through injury or another consequence.

If the action remains available, another attempt can follow at the next legal opportunity. In combat this follows its alternating action rhythm. Atranor's judgment has its own terminal outcome.

## Examples

A compatible sword exposes a conditional sword action. An arm injury can block it; the panel still explains the known action and the missing condition.

A tree can offer a different set of interactions on two visits as the person, contents and circumstances change. A newly learned Trait or a carried tool can reveal an action the character had never encountered before.

See [Combat](Combat_and_Injuries.md), [First Twelve Interactions](First_Twelve_Grimnir_Interactions.md), and [Interaction Architecture](../09_Technical/Entities_Interactions_and_Content_Authoring.md).

### Assistant

Got it.

## Turn 936dd474-393a-42d8-8916-d8d60e61ca4a

### User

# First Twelve Grimnir Interactions

The first interaction set gives Grimnir elemental abilities a concrete expression across Combat, Trickery, Aid and Social. Each action has its own requirements, player skill phase, animation, sound and results.

## Combat

| Interaction          | Function                                                                                |
| -------------------- | --------------------------------------------------------------------------------------- |
| Mountain Strike      | An unarmed attack using the mineral body, with body-part selection and timed execution. |
| Stoneborn Resilience | Active defense through focused bodily reinforcement.                                    |
| Earthshaping         | Shape suitable stone or minerals into a simple weapon.                                  |

## Trickery

| Interaction         | Function                                                             |
| ------------------- | -------------------------------------------------------------------- |
| Cliffhanger's Grasp | Climb and traverse suitable rocky surfaces.                          |
| Stone Sense         | Track movement and physical disturbances through material contact.   |
| Mineral Affinity    | Recognize and assemble useful natural materials into a survival kit. |

## Aid

| Interaction       | Function                                                        |
| ----------------- | --------------------------------------------------------------- |
| Mineral Mend      | Treat an injury with suitable mineral material and capability.  |
| Replenish Essence | Prayer-like care supporting mind, motivation and individuality. |
| Feed and Nourish  | Prepare or provide nourishment through Grimnir culinary craft.  |

## Social

| Interaction     | Function                                                         |
| --------------- | ---------------------------------------------------------------- |
| Echo Attunement | Exchange knowledge through Grimnir memory practices.             |
| Resonant Touch  | Share resonance music and rhythmic social practice.              |
| Body Shaping    | Create a lasting enhancement by working the living mineral body. |

## From foundation to action

The nine innate capacities provide a vocabulary of sensing, shaping, reinforcing, gripping, mending, settling, touching and attuning. The complete recipe of an action determines how that capacity can be used in a particular situation.

Mountain Strike requires a usable arm and a suitable target. A future spear attack has its own weapon and body requirements and its own execution. A climbing action combines the person's capability with a suitable surface and current physical condition.

Knowledge exchange can be useful when either person has information matching the other's Need. Performing the exchange carries that information into the recipient's knowledge.

## Care and lasting change

Replenishing Essence connects aid to the gods and the support of companions or the village. It helps sustain the individuality that gives movement, thought and purpose their coherence.

Body Shaping works like a lasting bodily enhancement: shaping, setting or refining mineral structure changes what the body can support. It extends the same relationship between touch, craft and material seen in tools and architecture.

See [Innate Capacities](../03_Characters/Roles_and_Baseline_Abilities.md), [Combat](Combat_and_Injuries.md), and [Grimnir Care](../03_Characters/Grimnir_Physiology_and_Care.md).

### Assistant

Got it.

## Turn 4b39039d-65a5-474d-89e4-17d4e3ffd443

### User

# Entities, Interactions and Content Authoring

The game uses a shared entity framework and a common language for interaction requirements. Authored content supplies the behaviors and experiences that the simulation selects and combines.

## Shared entities

Characters, creatures, items, trees, boulders, buildings and memory stones share identity, Traits, state, position and interaction data. Components provide the additional information each entity needs, including body parts, inventory, Needs, Shards, relationships and AI.

Separate permitted content pools guide creation and rewards. Creatures draw appropriate creature qualities; playable people draw from their own pools. Two bears can have different Trait combinations and therefore different attacks, defenses or behavior.

## Flat Trait matching

The evaluator checks exact Traits and conditions. Grimnir, Humanoid, Earth Elemental, Individual, Climbable and other identity or target properties participate alongside capability and preference Traits.

Categories support content organization and selection. Interaction matching uses the actual requirements on the actor, target, carried objects and surrounding context.

## Interaction structure

| Part         | Purpose                                                                                |
| ------------ | -------------------------------------------------------------------------------------- |
| Requirements | Traits, Needs, knowledge, items, body, state, relationship and contextual conditions.  |
| Target       | The matching properties of the entity involved.                                        |
| Skill phase  | The action's authored timing, observation, movement, memory or other player challenge. |
| Results      | Changes to bodies, state, items, knowledge, relationships or Need completion.          |

Conditions inside one requirement group combine with AND. Complete alternative groups combine with OR. One satisfied group makes the interaction available.

A greeting can require Likes Kind on the actor and Kind on the target. A climb can require a climbable surface, the appropriate capability and a usable body. Mountain Strike requires its own attack capability, suitable opponent and healthy arm.

## Authored content and generation

Interactions, Traits and Needs are authored with their requirements and effects. The procedural layer selects, places and assembles this content into creatures, locations and appropriate task sequences. Runtime gameplay uses those definitions.

Each Need definition includes its importance setting for interface highlights. Content is refined through playtesting.

## Cached matches

The first focus between entities compares their relevant data and records matching actions. Later focus checks which data has changed before reusing the result.

Category flags or versions track changes to Traits, inventory, Needs, Shards, states, injuries and relationships. Changed information invalidates affected matches; relevant requirements are recalculated when the interaction is requested.

This internal state supports current action availability while the player sees the resulting contextual choices.

See [Interaction Design](../06_Gameplay/Interactions_Discovery_and_Player_Skill.md) and [Needs](../06_Gameplay/Needs_Tasks_and_Solution_Lifecycle.md).

### Assistant

Got it.

## Turn aad6dee5-a012-4c14-8615-8a6acf1c956e

### User

Okay, now tell me if all this makes sense, and create a very brief summary of all the information i gave you and tell me that you understand all this.

### Assistant

Yes. It all makes sense, and I understand the system as one coherent interaction framework.

- **Entities** share a common structure: identity, Traits, state, position, interaction data, plus components such as body parts, inventory, Needs, Shards, relationships, and AI.
- **Interactions are authored recipes** with requirement groups, a target, a player-skill phase, and results. Requirements inside a group use AND; alternative groups use OR.
- **Traits and conditions unlock actions contextually.** The evaluator checks the actor, target, items, body condition, relationships, Needs, Shards, surroundings, and other state.
- **Interactions are discovered through play.** Once discovered, they remain known to that character. The character panel shows known actions and blockers, while the radial wheel only shows actions currently executable.
- **Player control is physical and contextual.** Focus a target, choose an available action, approach and face it, then perform that interaction’s specific skill challenge.
- **Character capability determines what can be attempted; player skill determines the result.**
- **Results modify the simulation**, including injuries, state, items, knowledge, relationships, Needs, and other persistent world information.
- **Grimnir currently have twelve foundational interactions** across Combat, Trickery, Aid, and Social, including Mountain Strike, Stone Sense, Mineral Mend, Echo Attunement, and Body Shaping.
- **Procedural generation does not invent arbitrary mechanics at runtime.** It selects and combines authored Traits, Needs, creatures, interactions, locations, and task content from permitted pools.
- **Different Trait combinations create meaningful entity variation.** Two creatures of the same type can therefore behave differently.
- **Interaction matching is cached**, and only relevant changed data such as injuries, Traits, inventory, Needs, Shards, or relationships forces recalculation.

The central idea is clear: **the simulation determines what is possible, authored interactions determine how it works, and the player personally performs the meaningful part of the action.**

## Turn 8aa2e96a-4320-44f7-b198-8bd011880ce9

### User

I want you to take the first combat combat interaction, combat action, and make a concept of what, of the whole thing, with everything that it should, that it should have. A complete prototype.

### Assistant

# Mountain Strike
## Complete Prototype Concept

**Mountain Strike** is the first Grimnir combat interaction and the reference implementation for the entire interaction system.

It demonstrates the complete chain:

**Entity state → requirements → discovery → availability → focus → intention → approach → player skill → resolution → Shard → changed world state**

Its purpose is not merely to provide a basic attack. It should prove that the interaction architecture works.

---

## 1. Core fantasy

A Grimnir attacks using the weight and hardness of their living mineral body.

They do not summon magic or equip an abstract attack ability. They physically commit part of their body to a strike.

The player chooses **where to strike** and must execute the attack with appropriate timing.

A Mountain Strike can therefore:

- hit or miss,
- strike different body parts,
- cause different injuries,
- expose the attacker,
- be blocked or defended against,
- fail because the required arm is damaged,
- produce persistent historical information through a Shard.

---

# 2. Interaction identity

**Name:** Mountain Strike  
**Category:** Combat  
**Interaction type:** Targeted physical attack  
**Actor:** Grimnir character  
**Target:** Suitable hostile or attackable physical entity  
**Range:** Melee  
**Primary capability:** Mountain Strike / appropriate innate striking capability  
**Required body:** At least one usable striking arm  
**Player skill:** target selection + timing  
**Primary result:** physical impact/injury

Mountain Strike itself is binary as known content: the character either knows the interaction or does not.

Its effectiveness comes from the character, target, body state and player execution rather than from Mountain Strike levels.

---

# 3. Discovery

Mountain Strike begins undiscovered unless the character has already encountered circumstances that taught it.

Possible discovery situations include:

- a childhood practice encounter,
- observing another Grimnir strike something,
- being attacked,
- a combat-oriented task,
- encountering a hostile creature,
- training with another member of the community.

When discovered:

**Mountain Strike is permanently recorded in that character's known interaction panel.**

Discovery does not guarantee usability.

Example:

> Mountain Strike  
> Strike an opponent with the weight of your mineral body.  
> Requires: usable striking arm and suitable target.

If the arm later becomes injured:

> Mountain Strike  
> Unavailable: right arm cannot currently perform the strike.

The interaction remains known.

---

# 4. Requirements

The authored interaction contains complete requirement groups.

### Basic requirement group

**Actor**
- Grimnir
- has Mountain Strike capability
- conscious / capable of intentional action
- has at least one usable striking arm
- not currently prevented from acting

**Target**
- physical entity
- valid attack target
- within reachable navigation space
- possesses a hittable physical structure/body

**Context**
- actor can approach target
- combat state permits an action
- Mountain Strike is not currently in an unresolved previous action

All conditions inside this group use **AND**.

Future alternative groups could allow modified forms of Mountain Strike, but the prototype only needs one complete basic group.

---

# 5. Availability

Three distinct states matter.

### Unknown

The character has never discovered Mountain Strike.

It appears nowhere.

### Known but blocked

The character knows Mountain Strike, but something prevents its use.

Examples:

- injured arm,
- unconscious,
- target inappropriate,
- target inaccessible,
- combat turn unavailable.

The character panel explains why.

### Available

Every current requirement is satisfied.

Mountain Strike can appear on the focused target's radial wheel.

---

# 6. Target focus

The player moves normally using right click.

Hovering an attackable entity gives only a subtle cursor indication.

Holding left click focuses the entity.

While focused:

- player movement slows,
- the target becomes subtly emphasized,
- contextual interactions are evaluated,
- the radial action wheel opens.

If Mountain Strike is currently executable, it occupies one dynamic wheel slot.

The wheel does not show unavailable actions.

---

# 7. Selecting Mountain Strike

Selecting Mountain Strike establishes an **intention**.

The character does not instantly deal damage.

The game records:

- actor,
- target,
- interaction,
- chosen striking arm if multiple are available,
- current target position,
- current combat action state.

The character then:

1. turns toward the target,
2. approaches to valid striking range,
3. maintains the attack intention,
4. begins the Mountain Strike skill display during approach.

This means preparation and execution form one continuous action rather than a disconnected UI sequence.

---

# 8. Body-part targeting

Mountain Strike introduces localized combat.

The target's available body regions become readable during the skill phase.

For a humanoid example:

- head,
- torso,
- left arm,
- right arm,
- left leg,
- right leg.

A bear or another creature uses its own body structure.

The prototype does not require every body part to have unique mechanics immediately. It only requires the framework to support different target parts.

The selected body part becomes part of the interaction resolution.

Example:

**Mountain Strike → Bear → Left foreleg**

---

# 9. Player skill phase

The Mountain Strike challenge begins while the character approaches.

Its prototype should remain simple.

### Display

A timing indicator represents the developing strike opportunity.

It moves through several qualitative regions:

**Poor → Good → Excellent → Good → Poor**

The exact presentation can be visual, physical, or partially diegetic, but it should remain minimal.

The player simultaneously chooses the desired target body part.

### Commitment

The player clicks to commit the strike.

That moment freezes:

- selected body part,
- timing quality,
- attacker state,
- defender state.

The character completes the physical strike animation.

This makes the player's contribution:

**Where do I strike?**  
**When do I commit?**

---

# 10. Character capability vs player skill

Mountain Strike establishes a central rule.

The character determines the **possible envelope**.

The player determines the **execution inside that envelope**.

Character factors can include:

- relevant Traits,
- physical body condition,
- body material,
- injuries,
- target size,
- target defense,
- target body material,
- current state.

Player timing does not allow an incapable character to perform an impossible action.

Excellent execution improves the outcome of something the character could genuinely attempt.

---

# 11. Resolution

After commitment, the interaction resolver receives a snapshot similar to:

**Actor**
- identity
- relevant Traits
- striking arm
- arm condition
- current state

**Target**
- identity
- selected body part
- target material/body properties
- current injuries
- defensive state

**Interaction**
- Mountain Strike

**Player skill**
- timing result

**Context**
- positioning
- active defense
- relevant combat state

The resolver determines the result.

---

# 12. Prototype outcomes

The first prototype only needs a small outcome vocabulary.

### Miss

No meaningful contact occurs.

Possible causes:

- very poor timing,
- target movement,
- defensive action.

Result:
- time/action consumed,
- no target injury.

### Glancing hit

Contact occurs but transfers little force.

Result:
- minor impact,
- possibly no lasting injury.

### Solid hit

Successful normal Mountain Strike.

Result:
- target body part receives physical injury.

### Powerful hit

Excellent execution combined with favorable conditions.

Result:
- stronger injury to selected part.

### Bad commitment

A poor attack can expose the attacker.

Possible result:

- temporary vulnerable state,
- loss of positioning,
- minor self-stress if appropriate.

The prototype should avoid a large damage-number system if injuries can communicate the result directly.

---

# 13. Injury creation

Mountain Strike should create an actual body-state consequence.

Example:

> Bear  
> Left foreleg  
> Bruised / fractured / damaged

The injury belongs to that body part.

It can subsequently affect interaction requirements.

A damaged foreleg might interfere with:

- movement,
- attacking,
- climbing,
- fleeing,
- other interactions requiring that limb.

This demonstrates that combat feeds directly back into the shared interaction system.

---

# 14. Defense interaction

Mountain Strike must be able to interact with another authored action.

The natural prototype partner is **Stoneborn Resilience**.

If the target activates an appropriate defense before resolution, the Mountain Strike result reads that state.

Example:

**Mountain Strike**
vs.
**Stoneborn Resilience**

The defense can reduce, redirect or prevent injury according to its own authored result.

Mountain Strike itself does not need special knowledge of every defense.

It only reads relevant target state.

That keeps interactions composable.

---

# 15. Alternating combat rhythm

Combat proceeds through legal action opportunities.

After Mountain Strike resolves, the attacker cannot simply spam another attack immediately.

The combat rhythm advances.

If Mountain Strike remains available when the character's next opportunity arrives, it can be attempted again.

Failure therefore costs **time and opportunity**, not an arbitrary cooldown meter.

---

# 16. Animation

The prototype animation needs distinct phases.

### Intention
Character visibly prepares while approaching.

### Wind-up
The chosen striking arm pulls into position.

### Commitment
The animation becomes non-cancellable at the authored commitment point.

### Impact
The striking limb physically connects with the selected body region.

### Recovery
The Grimnir regains posture before another legal action.

Material weight should define the motion.

The attack should look heavy rather than fast and weightless.

---

# 17. Sound

Mountain Strike should communicate material interaction.

Sound layers can include:

- shifting stone from the Grimnir's movement,
- mineral tension during wind-up,
- impact based on target material,
- fragments, cracks or resonance where relevant,
- target reaction.

A strike against flesh should not sound identical to a strike against stone, wood or another Grimnir.

The interaction definition can request an impact class while the target supplies its material response.

---

# 18. Visual feedback

Feedback remains primarily in-world.

Possible cues:

- selected body part highlight,
- subtle timing indicator,
- physical recoil,
- chips or dust,
- altered target posture,
- visible injury,
- changed movement after limb damage.

Large floating damage numbers are unnecessary for this prototype.

The player should understand:

**I hit the bear's leg badly**

rather than merely:

**-27 HP**

---

# 19. Shard creation

Every resolved Mountain Strike creates factual historical information.

A successful strike could create a Shard containing:

- actor,
- interaction,
- target,
- target body part,
- place,
- time,
- result.

Example conceptual record:

> Grimnir A  
> Mountain Strike  
> Bear  
> Left foreleg  
> Northern Ridge  
> 14:32  
> Foreleg injured

A miss also constitutes a factual event if the system records attempted interactions:

> Mountain Strike  
> Bear  
> Missed

The Shard records **what happened**, not interpretation.

---

# 20. Knowledge implications

The Shard and knowledge systems remain separate but connected.

The event exists historically because the Shard exists.

Whether another person knows about that event depends on how the information reaches them.

A witness could know:

> Grimnir A struck the bear and injured its foreleg.

Later Echo Attunement or another knowledge-transfer system could carry that information elsewhere.

---

# 21. Interaction panel entry

Once discovered, the character panel could contain:

### Mountain Strike

**Combat**

Use the force of your mineral body to strike a physical opponent.

**Requires**
- usable striking arm
- suitable physical target
- ability to reach the target
- legal combat action opportunity

**Current status**
- Available

or:

**Blocked**
- Right arm injured

The panel describes the known interaction.

It does not serve as the combat action menu.

---

# 22. Radial wheel entry

During focus:

**Mountain Strike**

appears only when executable now.

If both arms eventually support distinct versions, the next stage could allow the player to choose which limb during targeting rather than cluttering the wheel with:

- Left Mountain Strike
- Right Mountain Strike

One interaction should remain one interaction.

---

# 23. Entity data required for the prototype

### Grimnir actor

Needs:

```text
Entity ID
Traits
Known Interactions
Body
  Left Arm
  Right Arm
Body-part condition
Position
Current action state
Combat state
Shards
```

### Target

Needs:

```text
Entity ID
Traits
Body structure
Body-part conditions
Position
Physical/material properties
Current defensive state
Combat state
```

### Mountain Strike definition

Needs conceptually:

```text
Interaction ID
Name
Category
Discovery conditions
Requirement groups
Target requirements
Range
Approach behavior
Skill-phase definition
Valid target body parts
Resolution rules
Result definitions
Animation references
Sound references
Shard template
```

---

# 24. Requirement prototype

Conceptually:

```text
MountainStrike

Actor Requirements:
- Trait: Grimnir
- Capability: Mountain Strike
- BodyPart:
    type = Arm
    usable = true
- State:
    conscious = true

Target Requirements:
- Physical = true
- Attackable = true
- HasTargetableBody = true

Context Requirements:
- Reachable = true
- CombatActionAvailable = true
```

The actual implementation can remain data-driven.

---

# 25. Result prototype

Conceptually:

```text
Timing: Poor
Possible result:
- Miss
- Glancing Hit

Timing: Good
Possible result:
- Glancing Hit
- Solid Hit

Timing: Excellent
Possible result:
- Solid Hit
- Powerful Hit
```

These are not absolute guarantees.

Character and target conditions still participate in resolution.

An excellent click against an extraordinarily resistant target does not magically produce catastrophic injury.

---

# 26. State changes to test

The prototype should prove dynamic requirement invalidation.

### Test A
Mountain Strike available.

Character injures right arm.

Result:
- cached interaction state invalidated,
- Mountain Strike recalculated,
- left arm can still satisfy the requirement if usable.

### Test B
Both arms unusable.

Result:
- Mountain Strike remains known,
- disappears from radial wheel,
- panel reports body requirement failure.

### Test C
Arm healed.

Result:
- body-state version changes,
- Mountain Strike becomes available again.

### Test D
Target walks away.

Result:
- attack intention approaches if still reachable,
- cancels or fails cleanly if target becomes invalid.

---

# 27. First combat prototype scenario

A very small test arena is enough.

### Entities

**Player Grimnir**
- Mountain Strike discovered
- healthy body
- no weapon required

**Training opponent / creature**
- basic body structure
- six or fewer target regions
- one simple defensive behavior

### Flow

1. Player moves with right click.
2. Player focuses opponent with held left click.
3. Radial wheel appears.
4. Mountain Strike is shown.
5. Player selects it.
6. Grimnir approaches.
7. body-part targeting appears.
8. timing phase begins.
9. player chooses a part.
10. player commits with click.
11. strike animation resolves.
12. opponent reacts.
13. body part receives appropriate state change.
14. Shard is generated.
15. combat opportunity changes sides.
16. opponent acts.
17. player receives another legal opportunity.
18. Mountain Strike availability is recalculated.

That is the complete playable loop.

---

# 28. What this single prototype proves

If Mountain Strike works properly, it validates nearly the entire foundation of the game:

**Shared entities**  
Actor and target use the common entity architecture.

**Traits**  
Identity and capability contribute to requirements.

**Bodies**  
Body parts matter both as requirements and targets.

**Discovery**  
The action can exist unknown, known and blocked.

**Contextual interaction matching**  
The target determines whether Mountain Strike appears.

**Radial interaction UI**  
Only executable actions appear during play.

**Player skill**  
Execution changes the result.

**Character capability**  
The simulation constrains what the player can attempt.

**Persistent state**  
Injuries remain on bodies.

**Interaction chaining**  
The injury changes future available actions.

**Defense**  
Another interaction can alter the result without rewriting Mountain Strike.

**Shards**  
The action becomes historical fact.

**Knowledge**  
That fact can later become information known by other characters.

**Combat rhythm**  
Failure and success consume meaningful opportunities rather than simply triggering ability cooldowns.

Mountain Strike is therefore a good first vertical slice because one apparently simple action touches almost every major system in Morkahja.

## Turn 656624a5-b0fe-4ad2-a046-42a61db6c68f

### User

Okay, one detail. The player can only choose the body part that they aim for if they have a trait. Let's call it Aimed, Aimed Attacks. That unlocks this feature. So someone who didn't unlock this feature or this addition to the fight will not be able to choose the body part that they are aiming for. So, yeah, that is important, that we don't... not every attack can have it, but this feature itself is only unlocked with this trait. Then also they would choose the body part first, and then they would click Mountain Strike, choose body part, then have the player skill phase. Character capability and player skill. If I have the... if I am able to execute the ability, then the ability works. The only way it can fail is by failing the player skill phase. There's no character capability check about... yes, so you can take point ten. That is made up by you. There's no foundation in the concept for this. So this is absolutely unnecessary. The character determines the possible envelope. The character determines if it's possible or not, but before we execute the activity, the interaction. Okay, maybe I misunderstood this. I just want to make sure that all the character capability checks are before we actually show the ability in the interaction wheel. And then yes, of course, it needs to have the traits and the physical condition and eventually materials. And it is okay. We cannot do it if we are injured. Target size does not matter at all, take that away. Target defense does not matter at all when we check if we have the possibility to use this. The target defense comes after we use it because it's a reaction phase. The target has a reaction phase. So we use it, we land it, doesn't mean that they cannot defend against it. So we do it, and then they react to it. If they have a defensive ability, they can use that one in that reaction phase. And the current state, I don't know what you mean by that. Target body material, I don't know what you mean by that. That is all made up. Then also, there's no miss, glancing hit, or solid hit. No, all this is made up by you. I don't understand why. The only thing that can happen is that we fail it by not succeeding in the player skill phase. Otherwise there's no other checks. So number twelve is weird, and I don't understand why you make up things. I mean, why you make up things that are not part of the concept. Yes, injury creation, that is correct. The Mountain Strike will create an extra body state consequence, but it is not bruised, fractured, or damaged. It is injured. It is injured or not injured. Okay? There's no different injuries. Natural protective part is stoneborne resilience, yes. Defense interaction, exactly. The defense cannot reduce or redirect. It can only prevent injury. So this is also an... You make it more complicated than it should be. The defense creature also is pretty much... If I use stoneborne resilience, I would not be able to know where the Mountain Strike comes from without a keen eye, or what's it called? Yeah, some trait that gives me the possibility to see where the attack comes from. But like Mountain Strike will not automatically have it aimed at one body part, but actually choose a random body part if I don't have the trait to choose it myself. The stoneborne resilience will do the same. If I don't have the trait to see or to choose the body part that I want to protect, then it will protect a random body part. Combat proceeds through the... To number fifteen, alternating combat rhythm. It will always be I attack, you defend, you attack, I defend, I attack, you defend, you attack, I defend.

### Assistant

Understood. Your corrections make the combat model much cleaner.

The corrected Mountain Strike logic is:

1. **All capability checks happen before the interaction appears.**
   - Required Trait/capability
   - Required usable body part
   - Required item/material if the interaction needs one
   - Appropriate target/context
   - If any requirement fails, Mountain Strike is not available in the interaction wheel.
   - There is no later hidden capability roll.

2. **Aimed Attacks is a separate Trait.**
   - Without **Aimed Attacks**, Mountain Strike targets a **random valid body part**.
   - With **Aimed Attacks**, selecting Mountain Strike first opens body-part selection.
   - The player chooses the body part.
   - Then the Mountain Strike player-skill phase begins.

3. **Player skill is the only success/failure check for the attack itself.**
   - If Mountain Strike is available, the character is capable of performing it.
   - Succeed at the authored skill phase: the attack lands.
   - Fail the skill phase: the attack fails.
   - No miss tables, glancing hits, solid hits, damage quality tiers, size modifiers, resistance calculations, or secondary character checks.

4. **Successful Mountain Strike causes one body-state result:**
   - **Injured**
   - There are no bruised/fractured/damaged severity categories in this system.

5. **Defense happens after the successful attack, as a reaction.**
   - Attack phase: attacker executes Mountain Strike.
   - Reaction phase: defender may execute an available defensive interaction.
   - A successful defense can **prevent the injury**.
   - It does not reduce or redirect the injury.

6. **Stoneborn Resilience follows the same targeting principle.**
   - Without the appropriate perception/targeting Trait, it protects a **random valid body part**.
   - With the relevant Trait, such as the eventual **Keen Eye** concept, the defender can identify where the attack is directed and choose the body part to reinforce.
   - This is especially meaningful against an attacker who possesses **Aimed Attacks**.

7. **Combat rhythm is strictly alternating:**

**A attacks → B reacts/defends → B attacks → A reacts/defends → A attacks → B reacts/defends...**

The reaction is part of every opposing attack turn, rather than a separate free-form combat opportunity.

So the fundamental rule is:

**Requirements determine whether an interaction can be attempted.  
The player-skill phase determines whether the attempted interaction succeeds.  
The opponent's reaction determines whether a successful attack actually produces its injury.**

That is the model I will use going forward.

## Turn bc1fa7c3-2d49-4f52-85af-5a3e18f1ea0b

### User

Rewrite the whole thing and make it a little bit more compact. It's the same information, but it don't need to be spread out, formatted, spread out like this. It can be a little bit more dense.

### Assistant

Here is the tighter rewrite.

:::writing{id="38142" variant="document"}
# Mountain Strike

Mountain Strike is the first Grimnir combat interaction and should act as the reference prototype for how combat interactions work in Morkahja.

It follows the full chain:

**requirements → availability → focus (hold left mouse button)→ selection → targeting → player skill → reaction → result → Shard**

Mountain Strike is an unarmed physical attack using the Grimnir's mineral body. It requires the interaction itself, a usable striking arm, an appropriate physical target, and a legal combat opportunity. All character capability checks happen before the action appears in the radial interaction wheel. If the requirements are not met, Mountain Strike cannot be selected. There is no additional character capability check after execution begins.

Once discovered, Mountain Strike remains permanently known to the character. If it later becomes unusable because of an injured arm or another missing requirement, it remains visible in the character panel with the current blocker explained. The radial wheel only shows it when it can actually be performed.

The player focuses a target by holding left click. The radial wheel shows all currently executable discovered interactions. Selecting Mountain Strike establishes the attack intention and the character approaches the target if necessary.

## Aimed Attacks

Without the **Aimed Attacks** Trait, Mountain Strike automatically selects a random valid body part on the target.

With **Aimed Attacks**, selecting Mountain Strike opens body-part selection first. The player chooses the intended body part and then begins the Mountain Strike player-skill phase.

For example:

**Mountain Strike → select left arm → skill phase**

Without Aimed Attacks:

**Mountain Strike → random body part → skill phase**

## Player skill phase

Once Mountain Strike begins, the interaction performs its authored player challenge. For the prototype this is a timing-based strike.

The player must execute the timing correctly. This is the only success or failure check for the attack itself.

If the player fails the skill phase, Mountain Strike fails.

If the player succeeds, the attack lands on the selected or randomly determined body part.

The character requirements determine whether the attack can be attempted. The player determines whether it is successfully executed.

## Reaction phase

A successful attack does not immediately create an injury. The defender receives a reaction phase.

Combat follows a strict alternating rhythm:

**A attacks → B reacts → B attacks → A reacts → A attacks → B reacts**

If the defender has an available defensive interaction, they may use it during their reaction.

For the Grimnir, the first defensive interaction is **Stoneborn Resilience**.

Stoneborn Resilience protects one body part. Without the appropriate Trait for identifying or choosing the incoming attack location, it protects a random valid body part. With the relevant perception or targeting Trait, such as the planned **Keen Eye** concept, the defender can identify where the attack is directed and deliberately protect that body part.

If Stoneborn Resilience successfully protects the body part struck by Mountain Strike, the injury is prevented.

Defense does not reduce, redirect, or partially absorb the injury. It either prevents it or it does not.

## Result

If Mountain Strike succeeds and the reaction does not prevent the result, the struck body part becomes:

**Injured**

Injury is binary for this system. A body part is injured or it is not.&#32;

That injury immediately becomes part of the entity's state and can affect future interaction requirements. An injured arm may prevent interactions requiring that arm. An injured leg may prevent interactions requiring a usable leg.

This allows one interaction to directly alter which interactions become possible afterward.

## Interface flow

A complete Mountain Strike sequence is:

1. Player focuses an opponent.
2. Mountain Strike appears if all requirements are currently satisfied.
3. Player selects Mountain Strike.
4. If the character has **Aimed Attacks**, the player selects a body part. Otherwise one is chosen randomly.
5. The character approaches and faces the target as necessary.
6. The Mountain Strike player-skill phase begins.
7. Player succeeds or fails the skill challenge.
8. On failure, the attack ends unsuccessfully.
9. On success, the defender receives their reaction phase.
10. A defensive interaction may prevent the injury.
11. If not prevented, the targeted body part becomes **Injured**.
12. The event is recorded as a Shard.
13. Combat passes to the other participant's action phase.

## Shard

The completed interaction produces factual historical information.

A successful unresolved Mountain Strike could record:

**Actor:** Grimnir A  
**Interaction:** Mountain Strike  
**Target:** Bear  
**Body part:** Left foreleg  
**Place:** Northern Ridge  
**Time:** event timestamp  
**Result:** Injured

If  the target's defense prevents the result, the Shard records that outcome instead.

If the skill phase fails, the attempt can likewise be recorded as a failed Mountain Strike.

The Shard records what actually happened.&#32;

## Prototype data

Mountain Strike needs only the information required by its authored interaction:

**Actor**

- identity and Traits
- known interactions
- body parts
- injury state
- position
- combat turn state

**Target**

- identity and Traits
- body parts
- injury state
- position
- available reaction interactions

**Mountain Strike definition**

- requirements
- valid target type
- discovery conditions
- targeting behavior
- Aimed Attacks support
- player-skill challenge
- injury result
- animation
- sound
- Shard output

The prototype should demonstrate the fundamental combat rule:

**Requirements decide whether an action is available. Player skill decides whether the action succeeds. The defender's reaction decides whether a successful attack produces its result.**
:::

## Turn bbb214ff-adf9-4fe8-9e30-07ddba1cedc4

### User

Define when the target is selected

### Assistant

The **target is selected at the moment the player focuses an entity by holding the left mouse button on it**.

So the sequence is:

**Hover entity → hold left mouse button → entity becomes the selected/focused target → radial interaction wheel opens for that target → choose Mountain Strike → choose/randomize body part → skill phase**

The target therefore exists **before Mountain Strike is selected**, because the game needs that target to determine which interactions are currently available in the radial wheel.

Once Mountain Strike is chosen, that focused entity becomes the interaction's committed target. The later **Aimed Attacks** step selects only the **body part**, not the target itself.
