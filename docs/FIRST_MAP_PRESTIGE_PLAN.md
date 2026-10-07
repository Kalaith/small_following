# Bramblewick: a longer first map through Renewal (prestige) - proposal

**Status:** proposal, 2026-10-07. Nothing here is implemented. The user's goal is
recorded under *Confirmed direction*; every name, formula and number after it
is a provisional starting value to be measured and tuned.
[GAME_DESIGN](GAME_DESIGN.md) stays the current design until slices land.

## 0. Scope and decision status

- **Requested outcome:** keep players in Bramblewick for about **30 minutes** before
  they move on to Bellmarket. Today it takes about **10 minutes**, and the cultist
  becomes very strong after a few upgrades. A prestige system is the suggested
  tool (user, 2026-10-07).
- **Confirmed direction:** focus on the first map; extend play time; a
  prestige system is welcome; the level-up (opening Bellmarket) should arrive
  around 30 minutes of play.
- **Provisional (this document):** the Renewal loop, the Devotion currency, the
  Sanctum upgrades, the "three Rites" Bellmarket gate, cost and opponent
  scaling, every number in sections 4-6.
- **Implemented baseline:** 11-second rounds; 33-node / 37-rank village circle
  (1041 gold, 250 recruits); four debate opponents ending with the Priest;
  Bellmarket opens when every village rank is owned; save schema 4.
- **Scope boundary:** Bramblewick only. Bellmarket's balance, catalog and
  pacing are unchanged. No offline or idle earnings. No new art pipeline.

## 1. What the measurements say today

A scratch bot (not committed) played a fresh save through the real scene:
real movement and collisions, real speech, the normal purchase API, fixed
wanderer seed. Each round it walks to the nearest unfinished audience, or to
the debate opponent once one has arrived. Between rounds it buys the cheapest
affordable rank until nothing is affordable. It finished **every village rank
and the Priest in 21 rounds**.

| Round | Donations that round | Ranks owned after shopping | Notable purchases |
| ---: | ---: | ---: | --- |
| 1 | 9 | 1 | Quickened Words I |
| 4 | 21 | 7 | Running II, Beckoning Call I |
| 8 | 39 | 14 | tier-III second ranks done |
| 9 | 42 | 16 | Meadow Invitations, Merchant Invitations |
| 11 | 66 | 20 | Helping Hand |
| 14 | 90 | 27 | Town Debate, Patient Answers, Common Ground |
| 17 | 129 | 34 | Sacred Questions |
| 20 | 183 (Priest +120) | 36 | - |
| 21 | 105 | 37 | Shared Faith: circle complete, 273 gold left over |

**Time model.** The user's ~10 minutes over roughly this many rounds implies
about **28 seconds per round cycle**: 11 s of play plus ~17 s reading the
circle, buying and walking. That ratio is an assumption to confirm with a
stopwatch playtest (section 9). At 28 s per cycle, **30 minutes is about
62-65 rounds**, three times today's count.

**Why the cultist gets strong fast:**

1. **Income multiplies, prices add.** Talking frequency, conviction and
   running each speed up a round, and invitations add audiences. Income grows
   about 14x (9 to ~130 per round by round 17), while prices grow only 11x
   (6 to 66). Each purchase pays for the next one sooner.
2. **The round fills up.** By about round 12 a full route clears every group
   with time to spare, so later stat ranks add little. Power arrives early and
   then flattens: the player is "done" without being "finished".
3. **Recruits rarely gate.** The available-recruit wallet sat at 13-50 spare
   for most of the run; only Sacred Questions and the last Faith nodes waited
   on it briefly.
4. **The Priest falls on the first serious attempt** once his three nodes are
   owned. Rounds 18-19 earned only 57 because the bot spent them failing the
   Priest; that is the only real wall in the map.

Stretching the existing circle alone (higher prices) would turn the extra
20 minutes into waiting. The plan instead adds a **reason to replay the map
stronger** and a **new long-term choice** (prestige), and only gently re-paces
the first run.

## 2. Design pillars

| Pillar | Player-visible behavior | Verification |
| --- | --- | --- |
| Every Rite feels faster at first, then pushes back | After a Renewal the early ranks fly by thanks to Sanctum gifts, then costs and opponents catch up | Campaign probe: rounds per Rite and income curve |
| Prestige is a choice, not a chore | Renewal is offered after the Priest; the screen shows what resets, what stays and how much Devotion it gives | UI capture and a test where a cancelled Renewal changes nothing |
| Permanent power stays legible and distinct | Sanctum gifts each change one named thing; talking, conviction and running stay separate | Progression unit tests per effect |
| The 11-second round and the 3-recruit opening still hold on a fresh save | A new player's first round is unchanged | Existing pacing suite unchanged |
| No dead time | Rounds stay the main activity; no idle accrual or waiting walls | Probe shows no Rite where income stalls for 3+ rounds with nothing affordable |

## 3. Core loop

```text
Rite (one pass through the village circle)
  rounds -> buy ranks -> invitations -> debates -> convince the Priest
      |
      v
  Renewal offered (optional, available from that point on)
      -> gain Devotion; village ranks, gold, recruits and debate stage reset
      -> spend Devotion in the Sanctum (permanent)
      -> next Rite starts at round 1 of the Rite, stronger but facing more resistance
After the third Priest (two Renewals, then a third Priest victory):
  Bellmarket opens ("the town has heard of you")
```

| From -> to | Trigger | Resets | Keeps |
| --- | --- | --- | --- |
| Rite -> Renewal offer | Priest convinced (current `map_complete`) | Nothing | Everything |
| Renewal offer -> Sanctum | Player confirms Renewal on the ritual screen | Village ranks, gold, available recruits, encounter stage, the Rite's round counter | Lifetime recruits, Devotion, Sanctum ranks, Renewal count, settings, total round count |
| Sanctum -> next Rite | "Begin the next Rite" | - | As above; Sanctum gifts apply immediately |
| Third Priest -> Bellmarket | Priest victory with Renewals >= 2 | Nothing | Everything; Bellmarket travel button appears |

The player may keep playing a finished Rite (farming gold) instead of
renewing. The unspent gold is lost on Renewal, and the Renewal screen says so.

## 4. Re-pacing the first Rite (small changes)

Target: the first Priest at **24-27 rounds** for the probe bot (today 21),
about 11-12 minutes for a human. The opening and the first two tiers do not
change, so the "roughly three opening conversions" invariant and the early
pacing evidence survive.

| Lever | Today | Proposed | Why |
| --- | --- | --- | --- |
| Tier IV-VI gold prices (talk/persuade/run 4-6, invitations, merchants 3-4, trials) | 27-66 | x1.4, rounded | Late ranks currently cost less than one round of late income |
| Late recruit assignments | 250 total | +30% on tier IV-VI and Faith | Makes the second wallet a real choice late |
| Priest conviction | 240 | 300 | One more serious attempt; still beatable with all three Priest nodes |
| Encounter rewards | 30 / 45 / 60 / 120 | unchanged | They are the satisfying spikes; keep them |

Expect +4 to +6 rounds. If the probe overshoots 27, lower the multiplier
before touching anything else.

## 5. Renewal and the Sanctum

### 5.1 Devotion

```text
devotion_gained = floor(rite_recruits / 30) + 4
  rite_recruits: recruitment events earned during this Rite (all sources)
  +4: for the Priest victory that unlocked the Renewal
  Keeping playing a finished Rite raises rite_recruits, so farming is allowed
  but slow (~0.5 Devotion per late round).
```

The probe's first Rite earned about 280 recruitment events, so about
**13 Devotion** for the first Renewal. Later Rites earn somewhat more, as
Sanctum gifts raise the per-round counts. Estimate: 13 + 15 + 17, about 45
over three Rites.

### 5.2 Sanctum catalog (permanent, Bramblewick only)

A small separate circle reached from the ritual's centre seal ("Inner
circle"), which already exists as the completion focus. About 40 Devotion buys
most of it by the third Rite, leaving choices rather than a complete set.

| ID | Name | Effect per rank | Ranks | Devotion | Notes |
| --- | --- | --- | ---: | --- | --- |
| `sanctum_welcome` | Remembered Welcome | Start each Rite with 20 / 50 / 90 donations | 3 | 2 / 4 / 6 | Speeds the opening without changing the round |
| `sanctum_rites` | Remembered Rites | Each Rite starts with Words I, Creed I and Running I inscribed | 1 | 4 | Removes the tutorial grind on replays |
| `sanctum_tithe` | Tithe of the Faithful | Ordinary listeners and wanderers give +1 donation | 2 | 3 / 6 | Economy, not speed |
| `sanctum_friends` | Old Friends | +1 lone wanderer per rank | 2 | 2 / 4 | Feeds the running/Beckoning loop the user liked |
| `sanctum_echo` | Echoing Creed | +0.25 conviction per phrase | 2 | 3 / 5 | Small, distinct from tier ranks |
| `sanctum_helper` | Faithful Companion | Helping Hand is owned from round 1 of each Rite | 1 | 5 | Requires the helper node to stay in the circle as normal |
| `sanctum_dusk` | Lingering Dusk | +0.5 s round length | 2 | 4 / 7 | Only after a Renewal; a fresh save keeps 11 s (open decision 3) |
| `sanctum_beckon` | Beckoning Memory | +60 px Beckoning reach (needs Beckoning Call I) | 1 | 3 | |

Total: 14 ranks, 58 Devotion. Effects use new catalog effect keys validated
like the existing ones; each needs a unit test before it ships (project rule:
implement and test an effect before adding it to data).

### 5.3 Each Rite pushes back

Sanctum gifts make early rounds faster, so later Rites need resistance or they
collapse to a few minutes. Provisional, by Renewal count `r` (0 for the first
Rite):

| Value | Formula | Rite 1 / 2 / 3 |
| --- | --- | --- |
| Village rank gold prices | base x (1 + 0.30 r) | x1.0 / 1.3 / 1.6 |
| Opponent conviction | base x (1 + 0.35 r) | Priest 300 / 405 / 510 |
| Opponent rewards | base x (1 + 0.25 r) | Priest 120 / 150 / 180 |
| Recruit assignments | unchanged | - |

Targets, measured with the probe:

| Rite | Target rounds | Approx. minutes at 28 s | Cumulative |
| --- | ---: | ---: | ---: |
| 1 | 24-27 | 11-12.5 | ~12 |
| 2 | 18-21 | 8.5-10 | ~21.5 |
| 3 | 17-20 | 8-9.5 | ~30 |

The third Rite should not be much shorter than the second. If it is, raise the
`r` coefficients before adding Devotion sinks.

### 5.4 Something new each Rite (content, optional slice)

Replaying the same 37 ranks three times risks fatigue. To keep the cost
bounded, each Rite adds one visible change instead of a new map:

- **Rite 2 - Pilgrims:** a group of three travellers walks a slow loop
  through the village and stops at random points. It is speakable while
  stopped, pays 5 each, and is the first moving audience.
- **Rite 3 - The Priest's Choir:** during the Priest debate, three choir members
  stand by the Priest and each restores a little of the Priest's conviction
  until they are converted. This turns the final boss into a small routing
  puzzle instead of a stand-and-talk.

These are proposals; if the user prefers pure numbers, section 5.3 alone is
the minimum.

## 6. Bellmarket gate and existing saves

- **New gate:** Bellmarket opens after the Priest is convinced with Renewals
  >= 2 (the third Priest). The circle no longer has to be complete in that
  Rite. Today's gate (every village rank) is replaced.
- **The password** (`PLZKTKS`) still opens either level, unchanged.
- **Existing saves:** any save that already reached Bellmarket, owns the full
  village circle, or holds the password flag keeps Bellmarket. Schema 5
  records this in an explicit `bellmarket_open` boolean, set once at migration
  from the old rule. No retroactive Devotion is granted. Open decision 5
  covers whether to grant some.
- **Bellmarket balance** is measured against "all village ranks". Sanctum
  effects are Bramblewick-only, so market pacing stays valid (open decision 4).

## 7. Data and persistence

| Item | Where | Notes |
| --- | --- | --- |
| Sanctum nodes | `data/upgrades.json`, `"area": "sanctum"`, plus a `"currency": "devotion"` field | Catalog validation gains the area, the currency and the new effect keys; Sanctum prerequisites stay within the Sanctum |
| Renewal pressure coefficients | Named constants in `progression.gd` | Recorded in PACING with the measured probe |
| Save schema 5 | `devotion`, `renewals`, `rite_recruits`, `sanctum` (rank dict), `bellmarket_open` | Schema 1-4 load with zeros; `bellmarket_open` derived from the old rule; same staged write / backup / `.corrupt` rules |
| Renewal transaction | `progression.try_renew(expected_renewals)` | One snapshot: reset village fields, add Devotion, increment renewals. Stale-request protection like purchases (one confirmation = one Renewal) |
| New game | Existing title flow | Also clears Devotion, renewals and Sanctum. The confirmation text must say so |

Ownership stays as today: `progression.gd` validates and mutates;
`main.gd` coordinates round state and the world rebuild after a Renewal;
`ritual_screen.gd` only requests a Renewal or a Sanctum purchase.

## 8. UI brief

| Phase | Decision | Dominant focus | Supporting facts | Deferred / access |
| --- | --- | --- | --- | --- |
| Ritual after the Priest | Renew now or keep playing | Centre seal glows; "Begin a Renewal" button | Devotion you would gain now; Rite number | Full keep/reset list in the confirmation |
| Renewal confirmation | Confirm / cancel | Two-column "Kept / Begins again" list | Devotion gained, gold that will be lost | - |
| Sanctum | Spend Devotion | Small inner circle, same purple style, sized like the ritual graph | Devotion balance, selected gift's current -> next | Return to the main circle |
| Village HUD | - | World | "Rite 2" next to the round number | - |
| Title | Continue / new game | Unchanged | "Rite 2 of Bramblewick" in the continue line | - |

Keyboard, gamepad and touch paths reuse the ritual graph's existing selection
and buy actions. Captures go to `docs/verification/` only when a slice ships.

## 9. Measurement plan

1. **Promote the scratch probe** to `tests/test_village_campaign.gd`, matching
   `test_market_campaign.gd`: fixed wanderer seed, save disabled, two purchase
   strategies (cheapest-first, branch-balanced), and an automated Renewal and
   Sanctum policy. It reports rounds per Rite, income per round, Devotion,
   and the round of the third Priest.
2. **Acceptance windows** (bot, cheapest-first): Rite 1 at 24-27 rounds;
   total to the third Priest at 58-68 rounds; no Rite with three or more
   consecutive rounds where nothing is affordable and income is flat.
3. **Unchanged guarantees:** `test_pacing.gd` opening routes (3 recruits) and
   full-rank group clears on a fresh save; the Bellmarket suites pass unchanged.
4. **Human stopwatch playtest** at the end of slices 2 and 4: note real time
   at the first purchase, Meadow, Helper, first Priest, each Renewal and
   Bellmarket. This confirms or replaces the 28 s/round assumption, and
   records where the player felt bored or blocked.

## 10. Delivery slices

| Slice | Playable outcome | Checks |
| --- | --- | --- |
| 1. Campaign probe | `test_village_campaign.gd` reproduces today's 21 rounds and logs the curve | Probe result recorded in PACING |
| 2. First-Rite re-pace | Late prices, recruits and Priest raised per section 4; Rite 1 lands at 24-27 rounds | All suites; probe; opening pacing unchanged |
| 3. Renewal core | Schema 5, Devotion, Renewal transaction and confirmation, Rite counter in HUD and title, new Bellmarket gate with migration | Save round trips and migration from 1-4, stale Renewal, failed write, new game clears prestige |
| 4. Sanctum | Inner circle with the 8 gifts and their effects | Per-effect tests, graph selection, captures; probe hits the 58-68 window |
| 5. Rite variety (optional) | Pilgrims in Rite 2, Choir in Rite 3 | Route tests for moving audiences; Choir rules; captures |
| 6. Tuning pass | Coefficients adjusted from the probe and one human playtest | PACING table updated; VERIFICATION entry |

Each slice is committed separately after its checks, per the project's commit
rule.

## 11. Open decisions

1. **Is Renewal required for Bellmarket?** The plan requires three Priests.
   Alternative: Bellmarket opens after the first Priest as today, and Renewal
   is optional depth. That keeps the 10-minute path but misses the 30-minute
   goal for players who move on.
2. **Names:** Renewal / Rite / Devotion / Sanctum are placeholders in the
   game's voice.
3. **Round length:** Lingering Dusk breaks "the round is 11 seconds" after a
   Renewal. Drop it if the 11-second rule should be absolute.
4. **Does the Sanctum follow the player to Bellmarket?** Recommended no, to
   keep market balance; yes would need a market re-measure.
5. **Existing players:** grant a starting Devotion to saves that already beat
   the Priest, or start everyone at zero?
6. **Rite variety (5.4):** build Pilgrims and Choir, or only number scaling?
7. **Music video and promo tools** assume today's circle and route; decide
   whether they get updated or stay pinned to their recorded footage.

## 12. Risks

- **Repetition fatigue** in Rites 2-3. Mitigated by Remembered Rites (skip
  the tutorial ranks), faster early income, and the optional variety slice.
- **Over-tuning to the bot.** The bot shops perfectly and never hesitates.
  Humans are slower, which could push 30 minutes to 40. The stopwatch playtest
  in slice 2 sets the real conversion before slice 4's tuning.
- **Save complexity.** Schema 5 touches the access gate; migration tests must
  cover every existing path into Bellmarket.
- **Power creep back into Bellmarket** if decision 4 goes the other way.
