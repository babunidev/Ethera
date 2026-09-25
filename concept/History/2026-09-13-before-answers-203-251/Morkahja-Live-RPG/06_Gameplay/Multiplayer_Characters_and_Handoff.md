# Multiplayer Characters and Handoff

**Current concept through answer 202 · updated 2026-09-12.**

How players inhabit existing people, meet one another, queue, spectate, leave, disconnect, and hand control back.

## Character Selection

### Choose an existing life

The selection screen presents currently available persistent characters, their identity, social role where applicable, current circumstances, and the currently revealed direction of destiny. The final purpose and latent youth qualities are not spoiled; an adult role is revealed only at the coming-of-age rite. It is a place to provide lore and story context that a conventional quest log might otherwise carry.

Choosing a character means choosing the kind of experience to play today. Availability is limited by the world's actual population and which characters are occupied.

### Queue and stand-ins

A queued player can wait for a normal experience only or also opt into temporary stand-in opportunities for disconnected players. An offer shows the actual character and a recap of what they have been doing.

An offer may go to several queued players with a response timer. Players accept or decline; non-response leaves them queued. When responses or the timer resolve, the earliest eligible accepting player gets the slot. Other players keep waiting.

### Spectating while waiting

Queued players can observe and inspect lore or character information. The final camera rule is follow-only: choose an on-screen character and follow them. The earlier free-flight idea was explicitly removed.

The exact visibility of character sheets, building details, and undiscovered knowledge while following remains to be specified.

### Accepting the life

The major choice of activity identity occurs when choosing the person. Once inhabiting them, live their role through actions rather than repeated activity-selection menus. Youth is the earliest playable phase; early children are unavailable for direct control.

## Multiplayer Interaction

Morkahja is a shared open world with a limited number of simultaneous playable lives. Population growth provides more character slots. No player owns the settlement or directs its development.

### Groups emerge from overlap

One person needs a bear claw, another a heart, and another food. Their objectives connect them to the same adventure. Signs can point in a common direction or become stronger when compatible characters meet.

Small groups form around these intersections rather than through a generic party-finder assignment. The login queue allocates character slots; it is distinct from how adventure groups form.

### Interaction

Roles, traits, relationships, and knowledge determine available actions. Sharing information duplicates a shard. There is no player text or voice chat.

### Continuity

Opted-in queued players can stand in for disconnected participants. Within the approximately ten-minute reclaim window, the original player reclaims control on return, and the stand-in re-enters the queue. With no queue, the disconnected character can remain reserved during the waiting period.

Player counts, permissions over others' belongings, conflict rules, and protection against disruptive play have not been defined.

Matching knowledge creates an opportunity for an in-person cultural exchange; information does not synchronize automatically. The social design builds positive bonds and leaves unmatched characters neutral. Trade can introduce reciprocal Needs and extend an adventure through other people's circumstances. Combat uses automatic facing/positioning while engaged and state-based injury responses for players and AI alike. See [Trade and Exchange](../07_Items/Trade_and_Exchange.md) and [Combat](Combat_and_Injuries.md).

## Logout and Handoff

### Manual logout

The player deliberately ends the session. The character returns to AI control and begins making their way home, where ordinary community life continues.

### Unexpected disconnect

For a crash or unknown loss of connection, the character initially waits where they are. AI considers remaining endurance and the journey home. The character starts returning before waiting would leave too little time or energy to get home without excessive fatigue.

### Stand-in control

Queued players choose either normal slots only or normal slots plus temporary stand-ins. If there is demand, a stand-in can continue a disconnected character's shared adventure. If the original player returns within the reclaim window, they regain control and the stand-in goes back to the queue. With no queue, the character can remain reserved during the waiting period.

### Offering a slot

Show the character and a recap to several eligible queued players. Start a response timer. They accept or decline; non-response leaves them queued. After the response window resolves, the first eligible accepting player in queue order gets the slot. Others continue waiting.

Spectators follow existing characters only; free flight was explicitly rejected.

### Unspecified details

Final timer tuning and origins, queue priority after stand-in service, recap fields, manual early-departure stand-ins, hazards while waiting, and control transfer during a critical action remain open. The conversation fixes the behavior above but not its networking implementation.

## Example E50: A queue offer with context

*Illustrative example from the discussion.*

Several queued players see the same available stand-in character and a recap. They accept or decline during the timer. The earliest eligible accepting player gets control after the offer resolves; the others remain queued. This allocates lives, not adventure-party roles.

Conversation: [turn 33](../../Morkahja-Concept-Sources.md#turn-7b1cc3da-2002-441f-9ce2-377beb5ca3f7), [turn 34](../../Morkahja-Concept-Sources.md#turn-8396c3bc-e526-4a31-9bab-e5d6b2c66d5a).

## Example E51: A disconnect differs from leaving

*Illustrative example from the discussion.*

A deliberate logout sends the person home. A crash leaves them waiting until their return journey requires departure before excessive fatigue. A temporary stand-in may keep a group moving, but an original player returning within the reclaim window reclaims control and the stand-in returns to the queue.

Conversation: [turn 32](../../Morkahja-Concept-Sources.md#turn-8889d78d-b7b8-429c-8a48-f34cf5d65979), [turn 33](../../Morkahja-Concept-Sources.md#turn-7b1cc3da-2002-441f-9ce2-377beb5ca3f7).

## Example E52: Spectating an existing life

*Illustrative example from the discussion.*

While waiting, follow a visible character and inspect permitted character or local lore. The original free-flight suggestion was explicitly replaced with follow-only observation. Exact information restrictions remain open.

Conversation: [turn 34](../../Morkahja-Concept-Sources.md#turn-8396c3bc-e526-4a31-9bab-e5d6b2c66d5a), [turn 35](../../Morkahja-Concept-Sources.md#turn-2dd9a009-ad75-459f-814e-9864ad9cb221).




## Prototype switching between shared character instances

The first playable should allow leaving a Grimnir to AI, entering spectator mode, and inhabiting another eligible Grimnir. All use one underlying character architecture with distinct IDs, state, traits, desires, Needs, Shards, relationships, and carried objects. A few nearly identical characters with shuffled compatible qualities are sufficient to test this. The prototype request does not specify bypasses for the established production logout, combat, or exclusive-control rules.

Source: [answer 111](../../Morkahja-Concept-Sources.md#turn-63c3bb21-878e-4059-9f9b-355dab7c2e17).


## Queue offers and bounded reclaim

Normal takeover and stand-in availability are offered through an organized queue. Show a character sheet with role, mission/current situation, and whether the opportunity is temporary. Offer it to a small group of the oldest eligible queued players; five recipients and a thirty-second timer are examples, not final tuning.

Accepting means willingness, not instant control. Resolve responses/timer and give exclusive control to the first eligible accepting player; others remain queued. The discussion refers both to oldest queued eligibility and who accepted first, so exact tie-breaking must be specified rather than silently chosen.

The original disconnected player has approximately ten minutes to reclaim the character. On return within the window, notify and thank the stand-in, then hand control back. When the window expires, the stand-in becomes the current player for the session and the original has no special reclaim priority. The exact timer origin and safe interruption behavior remain implementation detail.

Deliberate disruption/anti-griefing measures are explicitly deferred until real community behavior can inform them. No new crime or protection system is established by this update.


Source: [answer 170](../../Morkahja-Concept-Sources.md#turn-1c5f07ee-0923-463b-b7d5-0ddc610df420), [answer 171](../../Morkahja-Concept-Sources.md#turn-3c26d04b-0be6-4f88-aa00-04d6824235aa), [answer 172](../../Morkahja-Concept-Sources.md#turn-d3ae404c-7f53-49ca-a63f-b02a6c469e1b).

## Provenance

Consolidated from the prior concept and the [complete design conversation](../../Morkahja-Concept-Sources.md). The [coverage map](../99_Development/Conversation_Coverage_and_Structure_Map.md) records topic migration and source turns. Later user decisions govern; worked examples do not create additional mechanics.


<details>
<summary>Original detail and examples — answer 170</summary>

> So it's important. If a character gets available for a stand-in or for takeover, there will be a pop-up for the others. A little pop-up, and they can agree to take over this character in this little pop-up. It's not a little pop-up. It shows the character and their mission and their role and stuff, a little bit of a character sheet. They can take it. They can accept this, but that doesn't mean that they get it. They can accept it, and if they accepted it, then the game will check who was first. And only the first, of course. Then the first one gets it. Okay? So that way we prevent the instant I take over, even if I actually can't thing that you're talking about. It's more organized. It's not just like hopping in. It's like I'm queued. The available characters popping up. It says if it's a stand-in situation or not, and then I can agree on it. And it's only shown to the oldest five maybe. So then if all of them have agreed or not, or disagreed or not, there's a timer running, and if I'm the oldest one, but I missed the opportunity there, then someone else can have it. If the timer runs out, someone else can take over. Yeah. So that's like a, what, 30-second timer maybe or whatever.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-1c5f07ee-0923-463b-b7d5-0ddc610df420)

</details>


<details>
<summary>Original detail and examples — answer 171</summary>

> The control should return to the original player, of course. Maybe not immediately. I mean, I can't inform the player that is playing right now of that and thank them for the stand-in. But then the original player takes over again, exactly. That is also with a time limit. I can't give them more than ten minutes to take over again, and then the stand-in will become the original player.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-3c26d04b-0be6-4f88-aa00-04d6824235aa)

</details>


<details>
<summary>Original detail and examples — answer 172</summary>

> This is something for later when there is the community, it happens, then we can find a solution for that. So far we don't establish any measures in that regard.

[Full exchange](../../Morkahja-Concept-Sources.md#turn-d3ae404c-7f53-49ca-a63f-b02a6c469e1b)

</details>
