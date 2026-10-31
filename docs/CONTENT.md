# Ethera — Content Structure and Provenance

**Author:** Babuni.dev  
**Purpose:** Connect the game's canonical creative material and the implementation without flattening either into a generic portfolio summary.

## Source hierarchy

1. **Canonical vision and specifications:** `concept/Morkahja-Live-RPG/`, including numbered world, peoples, gameplay, presentation, technical and development subjects.
2. **Decision and change history:** `concept/Morkahja-Live-RPG/99_Development/Design_Decisions.md`, `Changelog.md`, `Ideas_and_Superseded_Proposals.md`, and `concept/History/`. Earlier proposals remain visible but must not override current rulings.
3. **Game implementation:** `game/project.godot`, scenes, `game/data/` authored definitions, `game/scripts/simulation/`, presentation scripts and tests.
4. **Art sources:** `assets/art/` stores editable sources (including Blender). Game-ready exports belong in `game/assets/` and other Godot-importable locations.

## First portfolio chapters

- **A world of continuing lives:** inhabitation, AI continuation between sessions, persistent people and community, Traits, Needs, Destiny and shared knowledge — current *design*, not all implemented.
- **Khar-Morr's first milestone:** a shapeable rock, club making, equipment swap, event Shard and Memory Fountain; simulation implementation and its historical test evidence must be shown separately from unfinished presentation.
- **From need to objective:** the specified Stone Weapon Need and subtle Divine Orientation signs; do not describe the third milestone as shipped without implementation/test evidence.
- **Technical experiment:** deterministic fixed-step simulation, knowledge boundaries, snapshots, state hashing and replay, plus the planned migration from temporary GDScript authority to a Rust runtime beside RealmNode.
- **Design as a process:** archived revisions, rejected proposals, creator rulings and separately attributed AI implementations.

## Publication rules

For each item include source file/commit, project status (concept, source-implemented, historically tested, freshly tested), media rights, original author and contributor credits, and any superseded design context. Do not publish private transcripts, account data or internal secrets. Do not infer that an archive note is current canon merely because it remains in Git.

## 2026-10-31 — Publication boundaries

The existing standard documentation is the project source for the future portfolio connection. See [publication preparation](PUBLISHING.md). Preserve contributor credits, canonical-source boundaries and original journals. No private findings, live records or secret values are copied into the portfolio.
