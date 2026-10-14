# Rosecourt: the King's garden - proposal, 2026-10-14

## 0. Scope and decision status

- **Requested:** plan a later map with one new mechanic, the way Bellmarket
  introduced locked listeners. Maps 1 and 2 are accepted as they stand (user,
  2026-10-14).
- **Confirmed direction (user, 2026-10-14):**
  - The mechanic is **whispered introductions** (option A below).
  - The last person to convince is **the King**. Every highest-tier noble has
    a whisper thread to him.
  - Rosecourt is the **second-last map**, not map 3. The
    [Lantern Fair](LANTERN_FAIR_PLAN.md) is map 3 and the
    [university](UNIVERSITY_PLAN.md) map 4, directly before Rosecourt. The
    **abbey is the final map**, where the last person to convince is the
    Pope.
  - Winning the King gives the cultist his **approval** to go before the
    Pope. This is story only, used for the travel text into the abbey; it
    carries no stat or unlock.
  - The King needs **all** the high nobles converted in the same round, and
    he **arrives late**, not at the start.
- **Provisional:** every name, layout position, threshold, price and round
  count below. Numbers belong in `data/balance.json` and `data/upgrades.json`
  once chosen, and the game reads them from there.
- **Implemented baseline:** two areas (`AREA_IDS` in `scripts/progression.gd`),
  save schema 4, Bellmarket's 35-node circle including its Followers branch
  (teal and amber helpers).
- **Not in scope:** the abbey (final map), any change to earlier maps' balance, idle
  income, prestige/Renewal, a new art pipeline.

## 1. High concept

The little cult is invited to the King's garden party. Rosecourt has terraced
lawns, clipped hedges, a fountain, an orangery and the King's pavilion at the
top. Guests stand in small salon circles. They are polite, slow to commit and
very aware of who has already been seen talking to the cultist.

The cultist arrives with every earlier map's build. Rosecourt's people are
harder again, so the carried build reaches only part of the garden until its
own circle is bought. Map 2 asked "what have you bought?". Rosecourt asks
"who have you already talked to today?".

## 2. The mechanic: whispered introductions

- Some guests are **connected**. A thin rose-coloured thread on the ground
  links them to one or two guests in other salon circles.
- Converting a connected guest sends a **whisper** along each thread. The
  linked guest starts with a head start (for example 50% of their conviction
  already filled), shown on their bar.
- **Nobles are reserved:** they won't listen until someone they trust has been
  converted *this round*. Once whispered to, they stay eligible for the rest
  of the round. Next round they are reserved again. There is no permanent
  lock.
- Threads, head starts and openings reset every round, like audiences do.
- The helper's conversions whisper too, so sending it to the far end of a
  chain is a real choice.

The decision this creates is the **order of the route**. Start with the
Gardener because she knows the Poet on the terrace, who knows the Baroness?
Or take the easy lawn income first?

**Readability:** keep two or three chains per salon, fade threads that are
already spent, and mark reserved nobles with a closed-fan icon plus text
("Waiting for an introduction"), never by colour alone. Inspecting a noble
names who can introduce them.

## 3. The King (finale)

- The King sits in the pavilion, attended by the **highest-tier nobles**
  (provisionally three: a Duke, a Duchess and the Lord Chancellor). Each has
  a thread to the King, and the King has no other threads.
- The King is **reserved** until **all** of those nobles are converted in
  the same round (confirmed). Each noble's whisper also fills a
  share of the King's conviction, so a strong route arrives with the King
  already part-way won.
- Because those nobles are themselves reserved, reaching the King means
  walking a full chain from the lawn to the pavilion in one round. That
  chain is the map's final exam.
- He works like the Priest of Bramblewick: an encounter with a large
  conviction requirement, a donation reward, and a lasting victory that
  doesn't depend on the circle. Whether he also answers phrases or loses
  conviction when left alone is a tuning choice to make in playtests.
- **He arrives late** (confirmed): the pavilion throne stays empty until most
  of the rose circle is bought, the way Bramblewick's Priest comes after the
  other opponents. The exact trigger (for example, owning a last-ring node)
  is set in slice 5. Until then the high nobles are ordinary rich, reserved
  guests.

## 4. Layout and guests

| Place | Feel | Role in routes |
| --- | --- | --- |
| Lower Lawn | Entrance, open grass, gardeners and staff | Easy, repeatable income and the start of most chains |
| Rose Walk | Long path between two hedge rows | Connects lawn and terraces; hedges shape routes |
| Fountain Terrace | Central round terrace, musicians | Crossroads where chains cross |
| Orangery | Glasshouse on one flank, quieter guests | A detour holding a useful link |
| King's Pavilion | Top terrace, top nobles and the King | Highest thresholds, end of every chain |

| Role | Example people | Threads |
| --- | --- | --- |
| Staff (open) | Gardener, Footman, Musician | Start chains; repeatable funding from zero balance |
| Guest (open) | Cousin, Poet, Companion | Middle links; higher thresholds than staff |
| Noble (reserved) | Baroness, Heir, Dowager | Need one whisper; rich donations |
| High noble (reserved) | Duke, Duchess, Lord Chancellor | Need a noble's whisper; each threads to the King |
| The King | - | Needs the high nobles |

Five or six salon circles of four to five guests. Props on layer 2 with feet
origins and Y sorting, as in `market.gd`. Hedges are real collision, with
gaps wide enough for the helper's pathing.

## 5. Economy and progression

- Thresholds are set so the full carried build reaches about **7 to 9 open
  guests** in an 11-second round before any Rosecourt rank. The rule worked
  for Bellmarket.
- Own circle of about **36 nodes in six petals of six** (a rose seal). Paths:
  running, phrase frequency, conviction, and three whisper paths:
  - **Lingering Whispers:** a bigger head start.
  - **Wide Circles:** threads reach one more guest.
  - **Trusted Name:** start each round with one noble already whispered to.
- Rosecourt effects apply only in Rosecourt. Stats and the helper travel in.
- Access comes from completing the university's circle, the map before it
  in the [chosen order](MAP_ROADMAP.md).
  The password list shows every implemented area.
- Saves: add `"rosecourt"` to `AREA_IDS` with a schema bump, so older builds
  preserve the save as newer and unsupported. Whisper state is transient;
  only the King's victory persists, in the same way as encounter progress.

## 6. Delivery slices

| Slice | Outcome | Check by playing |
| --- | --- | --- |
| 1. Whisper rule | Threads, a reserved noble and the helper on a greybox | Head start, reserved until whispered, per-round reset, no double reward, the helper whispers too |
| 2. Area and travel | Greybox garden, schema bump, travel in and back, password list | Travel both ways; an old save still loads; a failed save keeps the current area |
| 3. Roster and balance | Full guests and threads in `balance.json` | The carried build reaches about 7-9 open guests |
| 4. Rose circle | About 36 nodes in `upgrades.json`, six-petal layout | Purchases, area-scoped completion, the seal reads well |
| 5. The King | High-noble threads, King encounter, lasting victory | He arrives late; he listens only after every high noble is won that round |
| 6. Campaign pacing | Tune prices and thresholds | Rosecourt takes about as long as Bellmarket |

This branch carries no tests and agents must not add any (see
`AGENTS.md`). Check each slice by running the game (`Run.ps1`, plus
`--headless --editor --quit` as an import/parse check) and playing the
checks above, using a password start to reach the map quickly. Earlier
maps must play as before.

## 7. Mechanics considered and set aside

- **Chaperones' gaze:** watchers on patrol whose cones pause speech, blocked
  by hedges. It suited the garden but risked waiting rather than deciding.
- **Quadrille:** guests change salon on a chime, carrying their conviction.
  This needs a per-person conviction model, which is the largest refactor.
  It could suit a later, larger map.

## 8. Open decisions

None from the user at present. Tuning (thresholds, head-start size, the
King's arrival trigger) is settled in playtests.
