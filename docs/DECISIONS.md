# Ethera — decision and alternatives navigation

**Author:** Babuni.dev

The actual design decision register already lives at [concept/Morkahja-Live-RPG/99_Development/Design_Decisions.md](../concept/Morkahja-Live-RPG/99_Development/Design_Decisions.md). Superseded approaches are recorded in [Ideas and Superseded Proposals](../concept/Morkahja-Live-RPG/99_Development/Ideas_and_Superseded_Proposals.md). This document intentionally links rather than rewriting historical outcomes.

Key repository boundary observed: `concept/` remains canonical for game rules; `game/` contains implementation; author direction is credited to Babuni.dev, with individual AI contributions documented separately.

No new design choice was approved in the documentation audit.

## Documentation audit #31 — traceable examples

- **Continuing lives:** The [vision](../concept/Morkahja-Live-RPG/00_Core/Game_Vision_and_Principles.md) explicitly establishes that characters, not accounts, retain progress, objects, knowledge and unfinished work. This is canonical author-directed design, not an AI proposal invented by the audit.
- **First proof of play:** The [first playable scope](../concept/Morkahja-Live-RPG/99_Development/First_Playable_Scope.md) focuses on Khar-Morr's club, equipment and Fountain Shards. The [game README](../game/README.md) reports locally implemented Milestone 1 simulation; finished assets and current runtime acceptance remain separate.
- **Need/objective correction:** The [Milestone 3 rulings](../concept/Morkahja-Live-RPG/99_Development/Changelog.md) record Babuni.dev's September 23 corrections: automatically active sole task, existing free rock before replacement, node occupant replacement (not Fountain creation), and no injury priority switch in that milestone. These supersede earlier approaches; Milestone 3 remains a specification until independently shown implemented.
- **Authority architecture:** The [technical decision register](../concept/Morkahja-Live-RPG/99_Development/Design_Decisions.md) settles Rust beside RealmNode as the intended authority. Existing GDScript remains provisional, so neither system should be mistaken for the other.

This audit created no new game-design decision and did not alter the canonical register.

## 2026-10-31 — Canonical repository publication direction

Babuni.dev chose the actual project repository as the intended public source, replacing the earlier documentation-only edition once review and anonymous access succeed. Retain the current public edition during the transition. License and third-party redistribution decisions remain explicit author decisions.

## 2026-10-31 — Author decision — open project development

**Babuni.dev direction and decision:** Babuni.dev intends to develop the actual project openly, replacing the separate public documentation edition after publication review. GitHub visibility remains private as checked on 31 October 2026; this is an intended direction, not a completed public release.

Babuni.dev clarified the experimental workflow: ChatGPT-generated 2D images were converted to 3D models and rigged with Tripo. The extensive concept is not a committed delivery roadmap. Babuni.dev has set the experiment aside to focus on finishing and improving Button Game, Rocket Game 42 and Morkahja. Existing Explosive/Mixamo references still require reconciliation; this account does not establish redistribution permission for every historical asset.

**AI contribution:** Recorded the author’s decision and clarification, separately from observed GitHub visibility. Earlier documentation-only publication was considered and is superseded as the intended long-term source. No root license was selected by this update; public visibility, open-source reuse permissions, media rights and production readiness are separate matters. No runtime testing or behavior change is claimed.

## 2026-11-11 — Design questions raised by the source review

The [prototype status](PROTOTYPE_STATUS.md#behavior-that-needs-a-design-decision) records differences in when the Stone Weapon Need starts, how many Shards Echo Imprint shares, and whether Echo Attunement retrieves knowledge or grants village work. The specifications and current behavior remain available as evidence for Babuni’s decision.
