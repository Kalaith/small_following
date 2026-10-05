# Small Following - game design

## Purpose and scope

Small Following is a cute, village-scale incremental game. The player **is the little robed cultist**, walking between groups of villagers, talking, gathering followers and earning donations. Repeated rounds build progression toward larger towns, helpers and magic.

This project is a bounded two-area prototype of movement, short earning rounds, upgrades, a persuadable village priest and mixed market audiences. Bramblewick and Bellmarket have separate circles. The playable world consists of actual actors, props and collisions. Mock screenshots are references only.

## Confirmed direction

- The cultist remains directly movable, including between rounds.
- Make village movement and required menus usable by touch, especially in the web build (requested 2026-10-04). Tap-to-move is the selected implementation; keyboard/mouse play, economy and pacing remain intact.
- Small villages contain groups of NPCs to visit, talk to, recruit and receive donations from during rounds.
- An ordinary opening round should allow roughly three conversions and be too short to clear the village. This is a pacing target, not a hard recruitment cap.
- Round end opens a large occult ritual-circle upgrade screen, using purple, violet and lilac rather than the references' red.
- The initial upgrades improve talking speed, persuasion effectiveness and running speed through distinct mechanics.
- Selected existing upgrade ranks cost recruits as well as gold, with followers supporting audiences and shared preaching. Running upgrades remain gold-only. Preserve a separate lifetime-recruited statistic and existing purchased upgrades without retroactive charges (requested 2026-10-03).
- Preserve the original ranked progression. With full ranks on the original nine nodes, a competent practical route should fully convert all three groups inside the round with little time to spare; merely reaching the groups does not meet this target.
- The upgrade structure must accommodate over 100 future upgrades/layers through data and navigable rings or branches.
- Spread the existing inscriptions more fully around the circle. Every local upgrade rank lights the inner circle. The original demo message allowed continued play (requested 2026-10-03); the implemented village centre now leads deliberately to Bellmarket's separate circle.
- Implement the market level with its own similar but distinct purple circle and frequent choices among three to five upgrades, supporting faster routes and richer NPC specializations. Add a title screen where `PLZKTKS` permits starting any implemented level (requested 2026-10-04).
- Double Bellmarket's upgrades to thirty and increase their cost, balancing around a player with all level-1 upgrades. Preserve the circle design the user likes (follow-up 2026-10-04).
- The circle should form a composed purple magical ritual seal: coherent concentric rings, sigils and interlocking geometric motifs with existing upgrade nodes integrated. Even spacing alone is insufficient. Keep decoration quiet and prerequisite paths and interactions clear; avoid arbitrary visual noise (clarified 2026-10-03).
- Add purchasable NPC groups, further speaking and moving tiers gated by group unlocks, and one helper that travels to individual NPCs to recruit them (requested 2026-10-03).
- Progression eventually reaches larger, more populated towns. Later minions and magic reduce travel demands while preserving direct control.
- Robes visibly trail and flap as the cultist moves.
- During village play, the playable space dominates and the HUD remains minimal and contextual.
- Recruitment briefly shows the numeric coin payout near the recruited character; merchants have no permanent payout label (requested 2026-10-03). Use digits rather than repeated coin symbols for larger rewards.
- The tone is cute. The title is **Small Following**.

- Add merchants, three persuadable enemy types, a town-center priest boss, related ritual upgrades and a persistent first-map finish (requested 2026-10-03). Areas beyond Bellmarket remain future work.

## Provisional rules in this build

These are current implementation defaults, not previously confirmed balance decisions.
The table describes Bramblewick; Bellmarket's audience, donation and catalog
values are documented below and in [PACING](PACING.md#bellmarket-rebalance---2026-10-04).

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
| Recruit assignments | 250 recruits across village ranks and 183 across market ranks; running costs zero recruits | Village target began from the user's roughly 279 lifetime events; both area economies need playtesting. |
| Ranked progression | Original six inner nodes with one rank, three tier-III nodes with two; 23 additional single-rank nodes | Preserve the original clear and extend progression through populated groups. |
| Audience lifecycle | Reset all groups each round | The same villagers may be recruited again; the total counts events, not unique followers. |
| Round boundary | Earning stops and the ritual screen opens; the player starts the next round | Allows unhurried decisions. Movement input stays available. |

The timer and travel/conversation costs limit the opening yield; no rule stops recruitment at three. Timing evidence and its limits belong in the verification documentation. Movement skill, route choice and time spent away from audiences can change results.

## Core loop and round transitions

1. Walk to a gathering and enter speaking range.
2. Read the local audience and phrase/conviction feedback; stay to recruit or move to another gathering.
3. Receive donations and one available recruit for each recruitment event until time expires; increment lifetime recruitment history separately.
4. Browse the purple ritual circle, select a node, inspect its rank-specific donation/recruit costs and effect, and buy if both resources are affordable and prerequisites are met.
5. Press Enter or use the next-round button to begin again with purchased improvements.

The ritual screen is a deliberate full-screen intermission. Tab returns to the visible village between rounds and reopens the circle; earning remains stopped. WASD, arrows and the movement stick continue to steer the cultist while the screen is open. A new round restores the starting position. Do not pause the movement controller to implement menus or future automation.

Village ground accepts tap/click destinations. Travel uses the existing speed
and collisions, stops on arrival or obstruction, and allows immediate retargeting
or keyboard/stick takeover. Tapping the cultist stops travel. This is straight-line
movement, with manual taps around props. Between-round village buttons reopen the
ritual or begin another round; ritual selection, panning, zoom buttons, purchases
and demo dismissal are available without a keyboard. Exact target sizes and tap
tolerance are provisional interface choices, not new balance rules.

## Bounded upgrade content

The original progression retains **nine real nodes**: three tiers in each of three branches. The six inner nodes each have one rank; the three outer tier-III nodes each have two. Those nodes contain twelve purchases. A node in the next ring requires at least rank 1 of the previous node in its branch. Initial node costs remain 6, 9 and 12 donations respectively; the second rank of each outer node costs 18. Each rank is permanent for the local save.

| Branch | Effect per purchased rank | Distinct result |
| --- | --- | --- |
| Talking speed | +20% of base phrase frequency for each initial node; +30% for outer node rank 2 | Phrases arrive more often; their conviction value is unchanged. |
| Persuasion | +0.5 conviction per phrase | Each phrase contributes more recruitment progress; movement and phrase frequency are unchanged. |
| Running speed | +15% of base movement speed | Reaching and changing audiences takes less time; speaking itself is unchanged. |

Effects within a branch add to its base value. Full ranks in the original core give 1.9 phrases/second, 3 conviction/phrase and 288 pixels/second running speed. All first-rank effects retain their original values, so existing purchases keep their benefits. Conviction above the threshold carries toward the next listener, so stronger phrases retain their full cumulative value.

The original nine purchases cost 81 donations; the three new ranks cost 54 more, for 135 total. A late round that fully converts two groups earns 30 donations, enough for an 18-donation rank. The new talking rank shortens every phrase interval; the new persuasion rank reaches one complete listener per phrase; the new running rank reduces the time spent crossing the village. Exact prices, increments and rank limits remain provisional tuning, while the goal of a close full-village conversion is confirmed. See [route measurements](PACING.md) for the full-clear budget and incomplete-build comparisons.

One purchase action buys one rank. Nodes show current/maximum ranks, and selected details show current and next effects, both rank-specific costs and prerequisites. Purchases require both resources together; missing donations or recruits are explained without spending either. Maximum-rank and stale purchase requests spend nothing. Locked, unaffordable, available, partially ranked and maximum-rank states must be readable through labels and shape treatment as well as color.

Recruits assigned to selected inscriptions support the cultist: they warm up the next audience, share testimony, organize invitations or help with communal preaching. This explanation adds no new actor or automatic conversion. Assignments are permanent purchase costs, spent from available recruits while the lifetime event count remains intact. All running ranks and selected personal-technique upgrades remain gold-only. The current 32-node, 35-rank catalog retains its effects and 1014-donation total and adds exactly 250 recruits; [PACING](PACING.md#recruit-assignments---2026-10-03) owns the provisional allocation. No new timing or stat bonus accompanies the cost change.

The graph is authored in `data/upgrades.json`, with stable IDs, ring/branch placement, rank limits, rank costs, prerequisites and supported stat effects. Its nodes and connections form the ritual geometry. Dragging pans the graph; the mouse wheel zooms; selection opens readable details outside the moving graph. A separate large validation fixture exercises more than 100 nodes without presenting unfinished upgrades as purchasable content.

The current seal uses eight authored constellations with distinct crescents,
curls, forks, a compact loop and a satellite. These replace the interim equal
sector fans. The overall composition expands around the centre; a branch's
local loop can turn inward while real prerequisite paths retain its sequence.
Catalog rings remain upgrade tiers rather than mandatory drawing radii.
This presentation changes no catalog definition, price, prerequisite or effect.

The parent agent inspected all three newly supplied references and provided
the visual brief. Original pixels remain unavailable on this Windows executor;
fresh local application captures verify the implementation. Human acceptance
of the composed-seal art direction remains outstanding. The completed-centre
behavior is preserved.

Adding a definition is appropriate only when its effect is implemented and tested. A large graph is a content capacity, not a promise that hundreds of upgrades are already designed or fun.

### Expanded village (implemented)

The earlier expansion adds seven single-rank nodes, reaching sixteen nodes and nineteen purchases before the finale. Meadow Invitations and East Lane Invitations each add five listeners; each opens another talking and running tier. The new tiers preserve distinct frequency and movement effects. This earlier catalog costs 348 donations; its player upgrades give 3 phrases/s, 3 conviction/phrase and 396 px/s. Existing ranks and saves retain their benefits. Exact prerequisites, costs and provisional choices are in [VILLAGE_EXPANSION](VILLAGE_EXPANSION.md).

New groups appear on purchase, reset each round and are recreated from saved upgrades after relaunch. The original 15-listener route remains the earlier progression benchmark. Expanded-route evidence is recorded separately in [PACING](PACING.md). Helping Hand unlocks a teal-robed recruiter after Meadow Invitations. It chooses the nearest reachable unconverted listener, walks around prop footprints at 150 px/s and speaks once per second, with three phrases required per listener. It repeats during active time, rests during intermission and resets each round. The helper has its own fixed stats. If the player finishes its target first, the helper drops that target's effort and finds another; recruitment pays once through the same gathering authority.

## Progression and save scope

Schema-4 local progression keeps donations, available recruits, all purchased upgrade ranks, lifetime recruitment events, round number, village encounter progress, active area and explicit level-selection access. Each ordinary, specialist, merchant, helper or opponent recruitment adds one to both recruit counters through its existing reward authority. Purchases subtract only available recruits. Valid schema-1/2/3 saves retain their values and default to Bramblewick; schema-1/2 available recruits initialize from lifetime history, and schema-1 purchases become rank 1. A restart opens the title, then starts fresh audiences and time in the saved area when continued. It does not resume partial conversations or award offline income.

Bellmarket access derives from the full village circle or the password shortcut. Unique persistent followers, mid-round continuation, cloud saves, prestige and offline accrual are not implemented. Available recruits are an assignment resource; neither recruit counter represents a unique persistent population.

The ritual centre's readiness derives from every validated rank in its own
area being at maximum, with an empty catalog never complete. Neither resources
nor Priest victory determine completion; no completion flag is stored. The last
successful purchase lights the centre, and reload derives the same state.
Bramblewick's centre offers Bellmarket travel; opening the offer grants nothing
and does not travel until selected. Bellmarket's completed circle permits
continued play and return travel, with no third destination. Keep playing or
Esc dismisses the message; Tab reveals the area and Enter starts another round.
See [the full-circle scope](RITUAL_COMPLETION.md).

## Bellmarket and level selection

Bellmarket is implemented as five stationary mixed gatherings: Bread Court,
Cart Crossing, Guild Row, Silk Arcade and Patron Steps. Eighteen ordinary
listeners are always eligible; four guild traders and three patrons require
their own introductions. Locks skip ineligible slots so they do not obstruct
the open listeners. Each recruited person pays once through the shared
gathering authority; the helper respects the same eligibility.

The separate market circle has five independent six-node paths for running,
phrase frequency, conviction, guild access/donations and patron access/donations.
All five roots cost 120 gold and no recruits. Each path continues at 200, 320,
480, 700 and 1000 gold; selected ranks assign recruits, and running stays
gold-only. Total market cost is 14,100 gold and 183 recruits. There are five
next branch choices when funded, declining naturally as paths finish. The
approved five-petal composition retains the original fifteen node positions.
Exact costs, effect sizes and audience thresholds remain provisional;
[PACING](PACING.md#bellmarket-rebalance---2026-10-04) records actual round income
and repeated-round purchase measurements with all village upgrades.

Normal market balance assumes all village stats and the helper carry into
Bellmarket. Existing purchases keep their benefits at the new prices, with no
retroactive charge; the added ranks begin unowned. Village audience
and opponent spawns stay local; market bonuses apply only in Bellmarket.
Travel shares wallets, ranks, history and round number, and arrives between
rounds. A failed save leaves the current area intact. The title password
`PLZKTKS` reveals both implemented levels without granting money or ranks.
Its access flag persists only after successful level selection/travel; typing
alone is session state. Play / Continue resumes the saved area with fresh time
and audiences. Full scope is in [MARKET_LEVEL](MARKET_LEVEL.md).

The first helper recruits individual listeners. Later minions may collect donations, attract villagers or preach to assigned audiences. Magic may extend reach or provide temporary gathering effects. Helpers should leave useful movement choices for the player. Earlier towns providing idle income remains an optional hypothesis. Stamina, if introduced, must not disable ordinary walking.

## Readability and feedback

Keep village HUD information to time, donations and available recruits. Show lifetime recruitment history separately in the ritual, along with both available resources and a short explanation of follower assignments. Put speech progress beside the active gathering. Use robe movement and small local audience reactions, with a brief numeric payout only when recruitment succeeds. The current payout rises and fades over 0.9 seconds; this duration is provisional visual tuning. Helper recruits share the listener feedback, and opponent victories show their donation reward beside the opponent's head.

During upgrade selection, the ritual itself is the main composition: concentric rings, connected node circles, intersecting lines and restrained rune-like marks in violet light. Rank pips and current/maximum labels distinguish a partly upgraded node from a finished one. Details must show the selected rank, current-to-next effect, cost, prerequisite and purchase state at a readable scale. The node glyphs need room to breathe; pan/zoom is for future scale, not a substitute for a readable initial layout.

## Open decisions

The 2026-10-04 future-level plan proposed six settings and mixed audiences.
Bellmarket, introductions, area travel and carry-over are now implemented.
[Future levels and mixed audiences](FUTURE_LEVELS.md) retains five additional
settings as proposals, including the noble gathering. Preserve the original
opening route and full-core 15-listener benchmark while evaluating later areas.

- How quiet should the promo score and footsteps sit, and does the prototype
  nonsense-syllable voice suit the cultist at both opening and full talking ranks?

- Does human play support the unchanged 11-second round, roughly three opening conversions and a close full-rank clear of all 15 listeners? How much steering/reaction allowance feels fair?
- Should later rounds restore the starting position or keep the cultist's position?
- Should villagers recruit once, recover interest, or reset each round? What does a permanent following represent?
- Are donations tied only to recruitment, periodic, or both?
- Which costs, effect sizes and branch combinations create worthwhile route choices?
- How many rings remain understandable before the graph needs search, filtering or branch navigation?
- Does Bellmarket's expanded progression offer useful three-to-five-way purchase decisions without excessive grinding, with all village upgrades and carried savings? Refine its costs, specialist rewards and route challenge from human play.
- Which area should follow Bellmarket, and what automation stays interesting?

Resolve these through short playable tests before expanding content. See [milestones](MILESTONES.md) and the [outstanding task list](../TODO.md).

## Audio direction and provisional implementation

Requested 2026-10-03: reuse the promo audio in the game's background and add
small pitter-patter footsteps. Sim-style nonsense language was suggested as a
possible speech treatment, especially as talking becomes faster; the precise
voice treatment is not a confirmed final design.

Implemented prototype: the original promo score loops across play/intermission,
footsteps follow actual player travel, and six original synthetic vowel phrases
provide optional speech feedback. Player phrase completion drives speech; the
helper remains silent. One voice, unchanged sample pitch and a 0.65-second
minimum onset gap drop excess cues without changing any gameplay phrases.
Music fades at the end of its full 72-second piece before repeating. Mix, timbre,
40-pixel footstep spacing and the 0.14-second step limit remain provisional.
M toggles all audio; V toggles speech alone. The requested settings page
(2026-10-03) now provides separate master/music/footsteps/speech sliders,
mute switches and fullscreen. Esc opens/closes the page; F11 toggles fullscreen.
Preferences persist separately from progression. Movement and the timer remain
active, with this behavior explained on the page. [Scope and screen brief](SETTINGS.md).

The settings footer also includes the requested Exit Game action (2026-10-03).
Desktop exit flushes pending preference/progression writes before quitting;
relaunch retains the existing fresh-round policy. Browser users close the tab.

Requested 2026-10-03: correct horizontal arrow movement and add a separate key
mapping tab in settings. Implemented: two physical keyboard slots for movement
and gameplay/audio/fullscreen shortcuts, conflict feedback, restore defaults
and saved bindings. Esc and Tab stay fixed for navigation; direct movement and
the timer remain active during key capture. These interaction details are local
implementation choices. [Mapping and persistence rules](SETTINGS.md).

## First-map finale

See [FIRST_MAP](FIRST_MAP.md) for the scoped design and provisional encounter rules. Implemented: two optional merchants, four merchant inscriptions, three opponents and a priest boss who walk to the center, twelve further inscriptions, and saved first-map completion. The village catalog has 32 nodes and 35 ranks. Town Debate opens the ordered encounters after East Lane Invitations. One opponent is attempted per round; victory persists, while partial conviction resets. The Priest ends the first map's objective. Separately, the completed village ritual centre opens Bellmarket and its own circle. Costs, names, resistances and numerical balance are provisional.
