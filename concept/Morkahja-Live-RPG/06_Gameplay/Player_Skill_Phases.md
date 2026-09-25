# Player-Skill Phases

Player-skill phases are reusable authored challenges shared by interactions. Each phase has a category, exactly one subcategory and the challenge itself. An interaction stores its category and skill subcategory, and can specify a particular phase.

## Selection

An explicitly specified phase is used for that interaction. Otherwise, each round randomly selects an authored phase from its matching category and subcategory. Different actions can therefore share a challenge pool while preserving their own requirements and world results.

Character capability establishes whether the interaction is available. The selected skill phase tests execution; reactions then resolve before the final result and event Shard. Pool selection changes the performed challenge while the interaction retains its established effects and targeting rules.

## Initial pools

| Category | Subcategory | Foundational interaction |
| --- | --- | --- |
| Combat | Attack | Mountain Strike |
| Combat | Defense | Stoneborn Resilience |
| Combat | Weapon Craft | Shape Weapon |
| Trickery | Traversal | Cliffhanger's Grasp |
| Trickery | Perception | Stone Sense |
| Trickery | Survival Craft | Mineral Affinity |
| Aid | Healing | Mineral Mend |
| Aid | Restoration | Inner Harmony |
| Aid | Provision | Elemental Sustenance |
| Social | Knowledge | Echo Attunement and Echo Imprint |
| Social | Resonance | Resonant Touch |
| Social | Adornment | Living Stone Adornment |

The starting library aims for roughly six phases per subcategory. Combat → Attack begins with Timing, Aim / Placement, Movement / Alignment, Rhythm / Sequence, Tracking and Force Control. Playtesting can refine their feel and the use of fixed versus random selection.

The interaction's chosen target and capability rules continue to apply during every challenge. For Mountain Strike, deliberate body-part choice requires Aimed Attacks; its player-skill phase follows that selection or the random body-part assignment.

## Attention, positioning and time

Every phase combines mouse positioning and timing within its own authored time limit. Left-click confirms the appropriate position or moment once or several times according to the challenge. The purpose is attentive participation, with comfortable execution for an attentive player. The design also aims to make unattended automation inconvenient.

Simple angular symbols resemble fragments cut from a rough gold or metal plate. Straight edges and low-poly forms keep the graphic legible. Time is visible in the graphic itself: an outline, fill, light or other integrated progression. Expiration quietly grays and fades the component.

## Shape Trace

**Combat → Weapon Craft.** Checkpoints follow the shape of the club. Touch every checkpoint with the mouse; the order is free. Revisit missed points and move off the line freely. The outline around the shape shows the time limit. A tool-like cursor, such as a hammer symbol, can support the visual metaphor.

After tracing the checkpoints, left-click to complete the phase within its time limit. Shape Weapon explicitly uses this phase in its first implementation.

## Shard Fit

**Social → Knowledge.** An angular symbol follows the cursor while automatically rotating or tilting back and forth. Move it over a matching recess and left-click when its position and angle fit. The mouse controls position; the phase controls rotation.

A valid click succeeds. An incorrect click leaves the challenge running with the remaining time. Expiration fails. The target graphic carries its own visual timer. Echo Imprint explicitly uses this phase.

The two selected phases establish the first milestone. Further pool entries follow the same positioning-and-timing principle.

See [Interactions](Interactions_Discovery_and_Player_Skill.md) and [Mountain Strike](Mountain_Strike.md).
