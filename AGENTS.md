# AGENTS.md

## Workspace

`Ethera/` is the authoritative development workspace for **Ethera: The Stonewrought**, set in the world of **Morkahja**. **Ethera** names the game; **The Stonewrought** describes the current Grimnir chapter within that same world.

Always read this file before development work.

- `game/` contains the implementation. Open it at `game/project.godot`. Godot's `res://` root is `game/`.
- `concept/` contains the canonical game-design documentation. The numbered design tree is `concept/Morkahja-Live-RPG/`.
- `assets/` contains source and reference production assets that Godot does not load directly, such as Blender files. Runtime assets the game loads stay inside `game/`.

## Design authority

Read the relevant design documentation in `concept/` before implementing or modifying a system.

The design documents define intended gameplay. The code implements that design. Implementation must follow established design from `concept/`.

Do not silently redesign gameplay.

## Core rule

Do not invent missing gameplay design.

If an implementation requires an undefined decision:

- Make the decision yourself if it is purely technical and does not alter gameplay or established design.
- Ask Alex if the decision changes gameplay, game rules, player experience, lore, progression, balance, presentation intent, or another established design principle and the answer is not already canonical.

Do not interrupt development for ordinary implementation details that can safely be resolved technically.

Technical implementation decisions that preserve intended gameplay may be made autonomously.

## Established design

Established design takes priority over implementation convenience.

Do not redesign gameplay because another implementation would be easier.

If you identify a potential flaw or contradiction in the game design, report it separately. Do not silently replace the established design.

Suggestions and experiments are not canonical until Alex approves them.

Clear approval from Alex makes a proposed design canonical.

## Conflicting sources

If code and canonical design contradict each other, report the contradiction rather than guessing.

Stop before resolving the contradiction yourself. Present the conflict to Alex and obtain a decision.

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

Keep the repository clean, modular, maintainable, and free of obsolete implementations where practical.

Do not knowingly leave obsolete implementations behind after replacing them.

Remove dead code, unused assets, abandoned temporary systems, and unnecessary compatibility layers when it is safe to do so.

Prefer a coherent codebase over accumulating patches.

Do not perform unrelated large-scale refactors merely because an opportunity exists. Improvements should remain reasonably connected to the current work.

## Before implementing

1. Read this file.
2. Identify the relevant design documents in `concept/`.
3. Read the existing implementation of the affected system in `game/`.
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
