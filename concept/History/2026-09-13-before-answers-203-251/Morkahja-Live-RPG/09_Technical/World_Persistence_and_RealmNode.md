# Shared saved state and freezing without simulation

**Current concept through answer 202 · updated 2026-09-12.**


## Shared saved state and freezing without simulation

Morkahja's world runs across participating peers. When nobody is running the simulation, world-time stops. There is no hidden offline progress, no catch-up aging, and no last cleanup that walks everyone home. Freeze positions and ongoing actions; resume from persisted state when simulation returns. Example: someone halfway through carrying firewood remains midway, and a creature stays where it was.

This replaces the older 'continues with no players, perhaps slower' rule. If an always-on node is only storing or verifying history, its presence does not by itself imply time advances. Whether a community node also actively simulates must be defined with RealmNode.

One shared world state is saved and replicated on participants' computers. Snapshot intervals, commit boundaries, replica counts, verification, reconnect recovery, and always-on reference nodes belong to RealmNode implementation and remain undecided. Exact freezing is the gameplay intent, not a claim that an abrupt simultaneous crash can preserve uncommitted actions. The recoverable-state guarantee must be established technically.

No hard design population cap is intended; scalability must still be measured. See [RealmNode foundation](../99_Development/RealmNode_and_Technical_Foundation.md).


Source: [answer 164](../../Morkahja-Concept-Sources.md#turn-f17bc380-ebe5-4c62-a38b-dd14251bd490), [answer 165](../../Morkahja-Concept-Sources.md#turn-ff711f88-0fbe-4788-b62c-b5f10d1c7a71), [answer 166](../../Morkahja-Concept-Sources.md#turn-dd3fb0d2-da1f-4431-87fb-0d174dcd03da), [answer 167](../../Morkahja-Concept-Sources.md#turn-8c09ecf3-d31a-4d03-aa08-6039c4621965).


<details>
<summary>Original detail and examples — answer 164</summary>

> Since there will not be a central server, but the game is actually running between the clients. There is no... nothing is gonna happen when there's no one online. Because if no one is running the world, then no one is online. The world doesn't exist if there is no... if there's no one who looks at it, it doesn't exist.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-f17bc380-ebe5-4c62-a38b-dd14251bd490)

</details>


<details>
<summary>Original detail and examples — answer 165</summary>

> It should freeze. It definitely just freeze.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-ff711f88-0fbe-4788-b62c-b5f10d1c7a71)

</details>


<details>
<summary>Original detail and examples — answer 166</summary>

> It is a technical question that is pretty much connected to the Node project, the project that is running the server, and I think it is so technical that we should just decide that when we know how the other tool works, or the tool works that is actually taking these snapshots or saving the world state, because it is pretty much saved on people's computers, because this is a shared network. There is no central server. And there might be, of course, there might be world state servers or some nodes that are constantly on to make sure that there is a reference for the general world state. Even if all the players are gone, there should be some nodes that can verify the world state that the player has, or update the world state that the player that just logs in receives. So it's important that we take that step by step with the tool that we're going to use.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-dd3fb0d2-da1f-4431-87fb-0d174dcd03da)

</details>
