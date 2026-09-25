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
| Combat | Weapon Craft | Earthshaping |
| Trickery | Traversal | Cliffhanger's Grasp |
| Trickery | Perception | Stone Sense |
| Trickery | Survival Craft | Mineral Affinity |
| Aid | Healing | Mineral Mend |
| Aid | Restoration | Inner Harmony |
| Aid | Provision | Elemental Sustenance |
| Social | Knowledge | Echo Attunement |
| Social | Resonance | Resonant Touch |
| Social | Adornment | Living Stone Adornment |

The starting library aims for roughly six phases per subcategory. Combat → Attack begins with Timing, Aim / Placement, Movement / Alignment, Rhythm / Sequence, Tracking and Force Control. Playtesting can refine their feel and the use of fixed versus random selection.

The interaction's chosen target and capability rules continue to apply during every challenge. For Mountain Strike, deliberate body-part choice requires Aimed Attacks; its player-skill phase follows that selection or the random body-part assignment.

See [Interactions](Interactions_Discovery_and_Player_Skill.md) and [Mountain Strike](Mountain_Strike.md).
