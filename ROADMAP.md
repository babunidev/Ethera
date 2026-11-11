# Ethera — development roadmap

The [first-playable scope](concept/Morkahja-Live-RPG/99_Development/First_Playable_Scope.md) records the working milestone sequence. The [prototype status](docs/PROTOTYPE_STATUS.md) maps it to checked-in code and records where the two diverge.

| Milestone | State after the 11 November 2026 source review |
| --- | --- |
| 1 · Khar-Morr | Shaping, equipment, and Fountain memory sharing are in source. Current desktop acceptance remains open. |
| 2 · Discovery | Place discovery and discovery Shards are in source. |
| 3 · Needs and guidance | Common Tasks, Divine Orientation, and deliveries are in source. The original starting Need scenario differs from the prototype. |
| 4 · Social play | A second Grimnir and greeting are in source. Echo Attunement grants work in the prototype, while its design specifies knowledge retrieval. |
| 5 · Inhabitation | Local Spectate and life switching are in source. AI continuation and remote handoff remain open. |
| 6 · Persistence | Snapshot and replay primitives exist. Player-facing save/load remains open. |

## Open engineering and verification

- Run the [simulation suite](game/README.md#run-the-simulation-suite) and record the engine, platform, commit, and result.
- Verify the village loop in the desktop build, including guidance, character switching, and the current character and terrain presentation. Keep historical V3 animation measurements separate from current V4 evidence.
- The production architecture specifies a separate Rust game runtime beside RealmNode. Remote transfer validation, fixed-point representation, peer admission, and recovery still need engineering. [Technical foundation](concept/Morkahja-Live-RPG/99_Development/RealmNode_and_Technical_Foundation.md) · [Implementation gaps](game/docs/OPEN_IMPLEMENTATION_GAPS.md)
- Portfolio publication tracks rights and provenance separately from source availability. [Publication notes](docs/PUBLISHING.md)

The [October 31 decision](docs/DECISIONS.md#2026-10-31--author-decision--open-project-development) records that Babuni set the experiment aside while focusing on other games. The sequence describes scope and has no delivery dates.
