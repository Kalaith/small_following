# Small Following - game design

## Purpose and scope

Small Following is a cute, village-scale incremental game. The player **is the little robed cultist**, walking between groups of villagers, talking, gathering followers and earning donations. Repeated rounds build progression toward larger towns, helpers and magic.

This project is a bounded first-map prototype of movement, short earning rounds, upgrades and a persuadable priest finale. The playable world consists of actual actors, props and collisions. Mock screenshots are references only.

## Confirmed direction

- The cultist remains directly movable, including between rounds.
- Small villages contain groups of NPCs to visit, talk to, recruit and receive donations from during rounds.
- An ordinary opening round should allow roughly three conversions and be too short to clear the village. This is a pacing target, not a hard recruitment cap.
- Round end opens a large occult ritual-circle upgrade screen, using purple, violet and lilac rather than the references' red.
- The initial upgrades improve talking speed, persuasion effectiveness and running speed through distinct mechanics.
- Preserve the original ranked progression. With full ranks on the original nine nodes, a competent practical route should fully convert all three groups inside the round with little time to spare; merely reaching the groups does not meet this target.
- The upgrade structure must accommodate over 100 future upgrades/layers through data and navigable rings or branches.
- Add purchasable NPC groups, further speaking and moving tiers gated by group unlocks, and one helper that travels to individual NPCs to recruit them (requested 2026-10-03).
- Progression eventually reaches larger, more populated towns. Later minions and magic reduce travel demands while preserving direct control.
- Robes visibly trail and flap as the cultist moves.
- During village play, the playable space dominates and the HUD remains minimal and contextual.
- The tone is cute. The title is **Small Following**.

- Add merchants, three persuadable enemy types, a town-center priest boss, related ritual upgrades and a persistent first-map finish (requested 2026-10-03). Later maps are future work.

## Provisional rules in this build

These are current implementation defaults, not previously confirmed balance decisions.

| Rule | Prototype value | Reason to revisit |
| --- | --- | --- |
| Round duration | 11 seconds | Target roughly three opening conversions; validate with human routes as well as simulation. |
| Starting position | World position (780, 680), restored at each new round | Makes opening routes repeatable; decide whether later rounds should preserve position. |
| Gatherings | Three initial groups, five listeners each; two unlockable groups and an optional merchant pair | A small route-choice sample; initial capacity is 15 and expanded capacity is 25. |
| Talking range | 105 world pixels | One nearest unfinished audience receives phrases. |
| Base talking | One phrase per second | Talking speed changes phrase frequency. |
| Base persuasion | One conviction per phrase; three conviction recruits a listener | Persuasion changes work done per phrase. |
| Base movement | 180 world pixels per second | Running upgrades change travel time while preserving ordinary direct movement. |
| Donations | Three per ordinary listener; 12 per merchant before upgrades | A typical opening round can afford an initial six-donation upgrade. |
| Ranked progression | Original six inner nodes with one rank, three tier-III nodes with two; 23 additional single-rank nodes | Preserve the original clear and extend progression through populated groups. |
| Audience lifecycle | Reset all groups each round | The same villagers may be recruited again; the total counts events, not unique followers. |
| Round boundary | Earning stops and the ritual screen opens; the player starts the next round | Allows unhurried decisions. Movement input stays available. |

The timer and travel/conversation costs limit the opening yield; no rule stops recruitment at three. Timing evidence and its limits belong in the verification documentation. Movement skill, route choice and time spent away from audiences can change results.

## Core loop and round transitions

1. Walk to a gathering and enter speaking range.
2. Read the local audience and phrase/conviction feedback; stay to recruit or move to another gathering.
3. Receive donations for each recruitment event until time expires.
4. Browse the purple ritual circle, select a node, inspect its price and effect, and buy if affordable and unlocked.
5. Press Enter or use the next-round button to begin again with purchased improvements.

The ritual screen is a deliberate full-screen intermission. Tab returns to the visible village between rounds and reopens the circle; earning remains stopped. WASD, arrows and the movement stick continue to steer the cultist while the screen is open. A new round restores the starting position. Do not pause the movement controller to implement menus or future automation.

## Bounded upgrade content

The original progression retains **nine real nodes**: three tiers in each of three branches. The six inner nodes each have one rank; the three outer tier-III nodes each have two. Those nodes contain twelve purchases. A node in the next ring requires at least rank 1 of the previous node in its branch. Initial node costs remain 6, 9 and 12 donations respectively; the second rank of each outer node costs 18. Each rank is permanent for the local save.

| Branch | Effect per purchased rank | Distinct result |
| --- | --- | --- |
| Talking speed | +20% of base phrase frequency for each initial node; +30% for outer node rank 2 | Phrases arrive more often; their conviction value is unchanged. |
| Persuasion | +0.5 conviction per phrase | Each phrase contributes more recruitment progress; movement and phrase frequency are unchanged. |
| Running speed | +15% of base movement speed | Reaching and changing audiences takes less time; speaking itself is unchanged. |

Effects within a branch add to its base value. Full ranks in the original core give 1.9 phrases/second, 3 conviction/phrase and 288 pixels/second running speed. All first-rank effects retain their original values, so existing purchases keep their benefits. Conviction above the threshold carries toward the next listener, so stronger phrases retain their full cumulative value.

The original nine purchases cost 81 donations; the three new ranks cost 54 more, for 135 total. A late round that fully converts two groups earns 30 donations, enough for an 18-donation rank. The new talking rank shortens every phrase interval; the new persuasion rank reaches one complete listener per phrase; the new running rank reduces the time spent crossing the village. Exact prices, increments and rank limits remain provisional tuning, while the goal of a close full-village conversion is confirmed. See [route measurements](PACING.md) for the full-clear budget and incomplete-build comparisons.

One purchase action buys one rank. Nodes show current/maximum ranks, and selected details show current and next effects, price and prerequisites. Maximum-rank and stale purchase requests spend nothing. Locked, unaffordable, available, partially ranked and maximum-rank states must be readable through labels and shape treatment as well as color.

The graph is authored in `data/upgrades.json`, with stable IDs, ring/branch placement, rank limits, rank costs, prerequisites and supported stat effects. Its nodes and connections form the ritual geometry. Dragging pans the graph; the mouse wheel zooms; selection opens readable details outside the moving graph. A separate large validation fixture exercises more than 100 nodes without presenting unfinished upgrades as purchasable content.

Adding a definition is appropriate only when its effect is implemented and tested. A large graph is a content capacity, not a promise that hundreds of upgrades are already designed or fun.

### Expanded village (implemented)

The earlier expansion adds seven single-rank nodes, reaching sixteen nodes and nineteen purchases before the finale. Meadow Invitations and East Lane Invitations each add five listeners; each opens another talking and running tier. The new tiers preserve distinct frequency and movement effects. This earlier catalog costs 348 donations; its player upgrades give 3 phrases/s, 3 conviction/phrase and 396 px/s. Existing ranks and saves retain their benefits. Exact prerequisites, costs and provisional choices are in [VILLAGE_EXPANSION](VILLAGE_EXPANSION.md).

New groups appear on purchase, reset each round and are recreated from saved upgrades after relaunch. The original 15-listener route remains the earlier progression benchmark. Expanded-route evidence is recorded separately in [PACING](PACING.md). Helping Hand unlocks a teal-robed recruiter after Meadow Invitations. It chooses the nearest reachable unconverted listener, walks around prop footprints at 150 px/s and speaks once per second, with three phrases required per listener. It repeats during active time, rests during intermission and resets each round. The helper has its own fixed stats. If the player finishes its target first, the helper drops that target's effort and finds another; recruitment pays once through the same gathering authority.

## Progression and save scope

Versioned local progression keeps donations, purchased upgrade ranks, the recruitment-event total, round number and the number of town opponents convinced. Existing schema-1 single-purchase saves migrate each purchased node to rank 1 without changing those counters; new ranks must still be earned. A restart begins a fresh timed round with the retained values; it does not resume a partial conversation or award offline income. The cumulative total deliberately includes repeat recruitment of the same prototype villagers.

Town unlocks, unique persistent followers, mid-round continuation, cloud saves, prestige and offline accrual are not implemented. Choose an audience lifecycle and an economy before treating the event total as a persistent population.

The first helper recruits individual listeners. Later minions may collect donations, attract villagers or preach to assigned audiences. Magic may extend reach or provide temporary gathering effects. Helpers should leave useful movement choices for the player. Earlier towns providing idle income remains an optional hypothesis. Stamina, if introduced, must not disable ordinary walking.

## Readability and feedback

Keep village HUD information to time, donations and the explicitly named recruitment count. Put speech progress beside the active gathering. Use robe movement and small local audience reactions for feedback rather than a field of floating numbers.

During upgrade selection, the ritual itself is the main composition: concentric rings, connected node circles, intersecting lines and restrained rune-like marks in violet light. Rank pips and current/maximum labels distinguish a partly upgraded node from a finished one. Details must show the selected rank, current-to-next effect, cost, prerequisite and purchase state at a readable scale. The node glyphs need room to breathe; pan/zoom is for future scale, not a substitute for a readable initial layout.

## Open decisions

- Does human play support the unchanged 11-second round, roughly three opening conversions and a close full-rank clear of all 15 listeners? How much steering/reaction allowance feels fair?
- Should later rounds restore the starting position or keep the cultist's position?
- Should villagers recruit once, recover interest, or reset each round? What does a permanent following represent?
- Are donations tied only to recruitment, periodic, or both?
- Which costs, effect sizes and branch combinations create worthwhile route choices?
- How many rings remain understandable before the graph needs search, filtering or branch navigation?
- What unlocks a town, how are previous towns revisited, and what automation stays interesting?

Resolve these through short playable tests before expanding content. See [milestones](MILESTONES.md) and the [outstanding task list](../TODO.md).

## First-map finale

See [FIRST_MAP](FIRST_MAP.md) for the scoped design and provisional encounter rules. Implemented: two optional merchants, four merchant inscriptions, three opponents and a priest boss who walk to the center, twelve further inscriptions, and saved first-map completion. The full catalog has 32 nodes and 35 ranks. Town Debate opens the ordered encounters after East Lane Invitations. One opponent is attempted per round; victory persists, while partial conviction resets. The Priest ends the first map's objective; later maps await new direction. Costs, names, resistances and numerical balance are provisional.
