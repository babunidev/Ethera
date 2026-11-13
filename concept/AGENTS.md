# AGENTS.md

Follow [the documentation standard](../docs/DOCUMENTATION.md) for first-person author voice throughout project documentation, factual changelogs, and naming the AI tool and verified model for each contribution.

## Project

This repository contains the game project currently titled **Ethera: The Stonewrought**, set in the world of **Morkahja**. **Ethera** names the game; **The Stonewrought** describes the current Grimnir chapter within that same world.

Read the relevant design documentation before implementing or modifying a system.

The design documents define intended gameplay. The code implements that design.

## Core rule

Do not invent missing gameplay design.

If an implementation requires an undefined decision:

- Make the decision yourself if it is purely technical and does not alter gameplay or established design.
- Ask Alex if the decision changes gameplay, game rules, player experience, lore, progression, balance, presentation intent, or another established design principle.

Do not interrupt development for ordinary implementation details that can safely be resolved technically.

## Design authority

Established design takes priority over implementation convenience.

Do not redesign gameplay because another implementation would be easier.

If you identify a potential flaw or contradiction in the game design, report it separately. Do not silently replace the established design.

Suggestions and experiments are not canonical until Alex approves them.

Clear positive confirmation from Alex counts as approval.

## Conflicting sources

If code and design documentation disagree about intended behavior, stop before resolving the contradiction yourself.

Present the conflict to Alex and obtain a decision.

Do not silently assume that either the newest code or the newest document is correct.

## Technical autonomy

You may independently:

- choose implementation details,
- improve code structure,
- refactor,
- optimize,
- remove dead or obsolete code,
- reduce duplication,
- improve naming and organization,
- improve technical architecture,
- create appropriate tests,
- fix technical defects that do not alter intended gameplay.

Preserve intended behavior while doing so.

Significant architectural or technical decisions should be documented or reported.

## Codebase hygiene

Do not knowingly leave obsolete implementations behind after replacing them.

Remove dead code, unused assets, abandoned temporary systems, and unnecessary compatibility layers when it is safe to do so.

Prefer a coherent codebase over accumulating patches.

Do not perform unrelated large-scale refactors merely because an opportunity exists. Improvements should remain reasonably connected to the current work.

## Before implementing

1. Read this file.
2. Identify the relevant design/specification documents.
3. Read the existing implementation of the affected system.
4. Determine what behavior is already established.
5. Identify genuine contradictions or missing gameplay decisions.
6. Ask Alex only when such a decision is required.
7. Implement.
8. Test the resulting behavior.
9. Clean up obsolete code created or exposed by the change.
10. Update relevant technical documentation when necessary.

## Canonicality

Do not turn brainstorming, comments, TODOs, speculative notes, or agent suggestions into established game design without Alex's approval.

When uncertain whether something is established design or merely an idea, treat it as non-canonical.

## Author identity

The project's human author is **Babuni.dev**. Use that exact name for project authorship and creative direction; retain historical evidence and distinguish AI contributions.
