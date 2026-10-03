# Opening and full-rank pacing

The round remains **11 seconds**. The opening target is roughly three individual conversions; the user now also wants a competent full-upgrade route to finish **all five NPCs in each of the three groups**, with little time left. These targets come from the user. The duration, ranks, effects, costs and route allowances below are provisional tuning choices, not final human-tested balance. There is no recruitment cap or special full-upgrade completion rule.

## Timing model

Base movement is 180 world pixels/second. Automatic speech begins within 105 pixels of a gathering. One phrase takes one second and adds one conviction; three conviction recruits one listener for three donations. Conviction overflow carries toward the next listener. Three groups of five listeners provide fifteen conversions per round.

The cultist starts at `(780, 680)`. Direct approach timing is `(distance to gathering center - 105) / 180`; speech can begin while finishing the approach. The standard route stops 95 pixels from the center, ten pixels inside range. A separate deeper-positioning route stops at 60 pixels.

| Initial destination | Gathering center | Distance from spawn | Ideal base arrival in range |
| --- | --- | --- | --- |
| Garden club | `(850, 850)` | 183.85 px | 0.438 s |
| Wellside neighbours | `(560, 540)` | 260.77 px | 0.865 s |
| Market regulars | `(1050, 480)` | 336.01 px | 1.283 s |

Base recruitment needs 45 seconds of speech alone to clear the village. Four baseline recruits require twelve one-second phrases, already longer than the round. This produces the opening limit through timing. Upgrades can exceed it normally.

## Selected nodes gain ranks

The original progression core contains nine nodes. The six inner/middle nodes remain single-rank; each outer node has two ranks. Every previously available purchase retains its cost and effect. Only the second ranks below are new.

| Existing outer node | Rank 1, unchanged | New rank 2 | Rank 2 cost | Fully upgraded branch |
| --- | --- | --- | --- | --- |
| Quickened Words III | +0.20 base phrase frequency | +0.30 base phrase frequency | 18 donations | 1.90 phrases/s; interval 0.5263 s |
| Compelling Creed III | +0.5 conviction/phrase | +0.5 conviction/phrase | 18 donations | 3 conviction/phrase |
| Fleet Footsteps III | +0.15 base running speed | +0.15 base running speed | 18 donations | 288 px/s |

Talking changes phrase frequency, persuasion changes conviction per phrase, and running changes travel. The prior nine purchases produced 1.6 phrases/s, 2.5 conviction/phrase and 261 px/s. At that strength each five-person group needs six phrases, so clearing three groups needs **11.25 seconds of speech alone**, before any travel. Full ranks reduce this to fifteen phrases, approximately **7.895 seconds of speech**, leaving room for movement.

The stronger second talking rank is deliberate: an increment of only +0.20 produced a measured 0.033-second margin on the practical route, too fragile for the requested close but usable finish. The chosen +0.30 gives the measured margins below without lengthening the opening round.

## Reproducible actual-scene simulation

`tests/test_pacing.gd` instantiates the real scene with persistence disabled. It drives `player.step_motion` through real `CharacterBody2D` collision movement and calls `advance_round` at 1/60-second physics steps. Every upgraded comparison buys through the normal purchase API and starts a fresh round. A test-only wallet funds setup; normal earnings, conversation thresholds and movement then apply unchanged. No player save is read or written.

Practical routes wait **0.20 seconds before moving**, wait **0.10 seconds when switching audiences**, and fully convert a group before leaving. Stops are inside the range, not perfectly optimized tangent points. All six group orders are compared. Further cases test deeper entry, eight-direction movement and longer hesitation. Eight-direction steering quantizes the desired direction to the same normalized axes/diagonals available from keyboard controls; it is scripted steering, not a human keyboard recording.

```powershell
& 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe' --headless --fixed-fps 60 --path . --script res://tests/test_pacing.gd
```

Measured on 2026-10-02 with **Godot 4.2.2.stable.mono.official.15073afe3**: **48 checks passed, 0 failed; exit 0**. The sandbox run also printed the known Windows certificate-store diagnostic. See [overall verification](VERIFICATION.md) for final environment results.

The completion time is the timestamp of the fifteenth recruitment event, not the round-expiry timestamp. A successful full clear also asserts the individual group counts are `[5, 5, 5]` and earnings are 45 donations. Events are logged at the end of a physics step. Range detection after movement can credit up to one 1/60-second slice on entry; analytical arrival estimates and measured results differ by at most one step.

## Opening remains unchanged

| Scripted opening | Individual recruits | Final recruit time | Donations |
| --- | --- | --- | --- |
| Garden, no initial pause | 3 | 9.433 s | 9 |
| Well, no initial pause | 3 | 9.850 s | 9 |
| Market, no initial pause | 3 | 10.283 s | 9 |
| Practical garden, including 0.20 s reaction | 3 | 9.633 s | 9 |
| Practical well, including 0.20 s reaction | 3 | 10.050 s | 9 |
| Practical market, including 0.20 s reaction | 3 | 10.483 s | 9 |
| One garden recruit, then well; no pauses | 3 | 10.717 s | 9 |
| Attempt one recruit at each group; no pauses | 2 | 7.717 s | 6 |
| Garden with Talking I; no pause | 4 | 10.433 s | 12 |
| Garden with Persuasion I; no pause | 5 | 10.433 s | 15 |
| Garden with Running I; no pause | 3 | 9.367 s | 9 |

The existing test-only sixty-second baseline tour still converts all fifteen at **48.550 seconds**, proving that the opening yield is not a hidden cap. Running I still shortens garden arrival from 0.450 to 0.383 seconds without changing speech cadence.

## Full-rank routes: actual complete groups

All rows below use full ranks, the 11-second round, 0.20-second reaction, 0.10-second switching pauses and 95-pixel interior stops.

| Order | Conversions | Full-clear time | Time remaining |
| --- | --- | --- | --- |
| **Garden -> well -> market** | **15 / 15** | **10.517 s** | **0.483 s** |
| Garden -> market -> well | 15 / 15 | 10.617 s | 0.383 s |
| Well -> garden -> market | 15 / 15 | 10.633 s | 0.367 s |
| Well -> market -> garden | 15 / 15 | 10.817 s | 0.183 s |
| Market -> garden -> well | 15 / 15 | 10.900 s | 0.100 s |
| Market -> well -> garden | 14 / 15 | Not completed | - |

The garden -> well -> market route converts its groups at **3.100, 6.633 and 10.517 seconds**, traversing 681.6 pixels. Full conversion is tested, not merely entering each audience's range. The automated target for this representative route is 0.20-0.80 seconds remaining. That band is a tuning check for this scenario, not an in-game rule.

| Garden -> well -> market variation | Conversions | Full-clear time | Time remaining |
| --- | --- | --- | --- |
| Deeper stops, 60 px from group centers | 15 / 15 | 10.700 s | 0.300 s |
| Eight-direction movement, 95 px stops | 15 / 15 | 10.583 s | 0.417 s |
| Hesitation: 1.20 s initially, 0.30 s at each switch | 13 / 15 | Not completed | - |
| Previous nine purchases only, standard practical allowances | 10 / 15 | Not completed | - |

The deeper route traverses 840 pixels and still completes; success does not depend on staying exactly at the range boundary. Poorer ordering or longer hesitation can still prevent a clear.

## Late-rank usefulness and cost

These comparisons remove only the stated second rank while retaining all other purchases and the same practical garden -> well -> market route.

| Omitted rank | Conversions | Full-clear time | Meaning of buying it |
| --- | --- | --- | --- |
| Quickened Words III rank 2 | 13 / 15 | Not completed | More frequent phrases convert the last two listeners. |
| Compelling Creed III rank 2 | 12 / 15 | Not completed | Three conviction per phrase reaches the one-phrase-per-listener threshold. |
| Fleet Footsteps III rank 2 | 15 / 15 | 10.750 s | Saves 0.233 s, raising the finish margin from 0.250 to 0.483 s. |
| Fleet Footsteps III rank 2, deeper 60 px route | 15 / 15 | 10.967 s | Saves 0.267 s, raising the deeper-route margin from 0.033 to 0.300 s. |

The last running rank buys positioning tolerance rather than a guaranteed extra recruit on every route. It remains useful, but the three branches are not claimed to have equal rewards in every situation. The first ranks are similarly distinct: on the nearest-group route persuasion gains two recruits, talking gains one, and running primarily reduces travel.

The original nine purchases cost **81 donations**. The three new ranks cost **54**, for **135 total donations across twelve purchases**. Each late rank costs six recruitment events, and the previous full-upgrade practical route earns 30 donations in a round, enough for one new rank from an empty wallet. A three-recruit opening still earns nine and can afford a six-donation initial node. Prices remain adjustable; these checks establish reachability and useful effects, not an optimized purchase order or a final grind length.

## Limits and next playtest

The scripted routes verify mechanics, realistic positioning allowances and repeatable timing. They do not establish human reaction speed, route discovery, animation readability, input comfort or enjoyment. The simulation runs at fixed 60 Hz; rendered frame pacing and longer human pauses should be tested separately. It does not call a hidden clear-village action, teleport between groups or grant an all-upgrades bonus.

The next human playtest should confirm roughly three opening conversions without coaching, then try full ranks on garden -> well -> market with ordinary keyboard movement. Check that all five listeners at each group visibly finish and that the remaining fraction of a second feels close but fair. Track hesitation, overshoot and selected route alongside the result before changing duration. If margins are too strict in human play, tune the added rank effects or movement/feedback with fresh evidence; do not silently extend the 11-second base round or add a special full-upgrade win condition.


## Expanded village - 2026-10-03

Two optional invitations add five listeners each at (470, 800) and (1250, 580).
The eleven-second round and all opening/core-rank routes are unchanged. Six
new purchases cost 183 donations (318 including the original core). Full
player stats become 3 phrases/s, 3 conviction/phrase and 396 px/s. Exact costs
and prerequisites are in [VILLAGE_EXPANSION](VILLAGE_EXPANSION.md).

Measured real motion and conversation with the same practical allowances:

| Expanded route: garden / meadow / well / market / east | Recruits / 25 | Donations | Completion |
| --- | --- | --- | --- |
| All player ranks | 23 | 69 | Incomplete; last recruit at 10.900 s |
| Without Talking V and Running V | 19 | 57 | Incomplete |
| All player ranks, longer hesitation | 20 | 60 | Incomplete |

The full player route walks 1135.2 px. More listeners do not imply an automatic
25-person clear; routes and additional speaking capacity remain relevant.
The original core still clears its 15 listeners at 10.517 s with 0.483 s left.
These are deterministic simulations, not human playtest results.


### Helper timing and route choice

Helping Hand adds one fixed-speed recruiter for 30 donations, bringing the
catalog total to 348. It walks at 150 px/s and uses three one-second phrases
per listener. Travel and separate target effort matter; player upgrades do
not alter helper stats. It earns only during the same clamped 11-second round.

| Full player upgrades, practical route | Helper conversions | Total / 25 | Donations |
| --- | --- | --- | --- |
| Garden / meadow / well / market / east, with helper | 0 | 23 | 69 |
| Meadow / well / market / east / garden, without helper | 0 | 21 | 63 |
| Meadow / well / market / east / garden, with helper | 3 | 24 | 72 |

The meadow-first route leaves the garden to the helper while the player works
elsewhere. The helper finishes listeners at 4.267, 7.667 and 10.900 seconds;
the player completes 21. The garden-first route repeatedly overtakes helper
targets and wastes its partial effort, yielding no extra conversions. This
is a deliberate route-choice limitation, not guaranteed passive income.
Neither measured full-catalog route clears 25; full-clear time and margin
remain undefined for those runs. The original core 15-person target retains
its existing verified margin. Human enjoyment and price acceptance are open.

## 2026-10-03 — merchants and first-map finale

The original core route and 11-second boundary are unchanged: 15 conversions in
10.517 seconds, 0.483 seconds remaining on the practical garden–well–market route.
The earlier opening, incomplete-core and expanded-route comparisons still pass.

### Provisional content values

Merchants are an optional pair at (1020, 650), each requiring 9 conviction and
paying 12 donations (18 with Generous Purses). Targeted upgrades add 3 merchant
conviction in total; full general stats give 5, so full merchant phrases contribute
8. Two 9-point listeners therefore need three full-strength phrases, retaining
overflow. A helper still needs nine one-second phrases per merchant.

Town Debate opens after East Lane Invitations. One opponent walks from (1470, 630)
via (1000, 630) to (790, 570) at 220 px/s, about 3.129 seconds before speech can
begin. Arrival consumes active round time. The player starts about 110.5px from
the center and must move into the ordinary 105px speech radius.

| Opponent | Conviction | Opening phrases rebutted | Conviction lost per second out of range | Victory donations |
| --- | ---: | ---: | ---: | ---: |
| Skeptic | 42 | 0 | 0 | 30 |
| Town Guard | 72 | 2 | 0 | 45 |
| Zealot | 108 | 0 | 6 | 60 |
| Priest | 240 | 3 | 9 | 120 |

The 32-node / 35-rank catalog costs 1014 donations. Finale stat nodes raise the
cultist to 3.5 phrases/s, 5 base conviction/phrase and 432 px/s. Opponent bonuses
raise phrases to 10 for Skeptic/Guard, 11 for Zealot and 14 for Priest. Neither
movement nor talking frequency is folded into conviction.

### Actual encounter measurements

`tests/test_encounters.gd` uses the live scene, fixed 1/60-second steps, actual
movement/collision and completed opponent conversion. All saves are isolated.

| Scenario | Result | Time used | Time remaining | Conviction at end |
| --- | --- | ---: | ---: | ---: |
| Full priest, 0.2s reaction then move to an 85px stop | Priest convinced | 9.133s | 1.867s | 240 |
| Minimum debate unlock build, same route | Incomplete | 11.000s | 0 | 32.5 |
| Full priest, wait 6s before moving into range | Incomplete | 11.000s | 0 | 196 |

Both full-build movement routes cover 28.8px; the slower minimum build covers
27px. No teleport is used in these three route cases. A separate staged campaign
fixture places the cultist near the center to verify victory ordering and reloads:
Skeptic completes at 4.567s, Guard at 6.000s, Zealot at 6.000s and Priest at 9.133s.
Those campaign times include opponent arrival but do not establish player travel.

The late route proves full purchases alone cannot auto-complete the boss. Failed
attempts reset next round; victories advance once and the Priest saves map completion.
The player can keep earning after completion. Human steering, merchant versus
villager route value, time to afford the whole circle and overall difficulty still
need playtesting; the numbers above are implementation defaults, not user-approved
balance or evidence of human play feel.
