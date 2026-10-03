# Bramblewick's final encounters — 2026-10-03

## Scope and decision status

The requested direction is merchants who give more gold but resist persuasion,
three enemy types, a priest boss who comes to the town center, related upgrades,
and a first-map completion state. Later maps remain future work. Names, numbers,
arrival timing and unlock requirements below are implementation choices to test.

## Experience and invariants

The cultist wins arguments through ordinary proximity speech. Movement remains
available in every phase. The original 15 listeners, their route, eleven-second
round and nine-node core remain intact. Additional audiences and encounters are
unlocked through the ritual. No damage, forced movement or combat controls.

## Loop, timing and state

Merchant Invitations adds two merchants near the market, each requiring nine
conviction and giving twelve donations. They reset with other listeners. Their
own upgrades add targeted conviction and donations; helpers respect their higher
threshold but do not receive the player's bonuses.

Town Debate unlocks one visiting opponent each round after East Lane Invitations.
Opponents walk along the clear east path to the center, then accept speech.
The Skeptic, Town Guard, Zealot and Priest appear in order. An unfinished opponent
returns with fresh conviction next round. A victory advances saved progress;
the next opponent arrives next round. The Priest ends the map's objective;
ordinary rounds remain playable afterwards. Nothing opens another map yet.

Provisional identities: the Skeptic needs sustained conviction; the Guard ignores
the first two phrases; the Zealot loses conviction while unattended; the Priest
combines a larger threshold with opening rebuttals and lost conviction when left.
Upgrades improve general or opponent-specific conviction while keeping phrase
frequency and movement distinct. Runtime constants own encounter balance.

## Data, persistence and ownership

`data/upgrades.json` retains stable IDs and adds only implemented effects.
`gathering.gd` owns typed audience thresholds/rewards; `encounter.gd` owns arrival,
rebuttals and conviction. `main.gd` selects speech targets and coordinates rounds.
`progression.gd` validates purchases and a saved encounter stage from zero to four.
The optional schema-2 field defaults to zero for old saves. Victory rewards and
stage advance are one earned-progress snapshot, with visible storage errors.
Partial encounters are transient. Test saves use isolated paths.

## Content and UI brief

The target is 32 real nodes, 35 ranks, across seven sectors and six rings. Merchant
and Trials sectors fill the upper diagonals; existing sectors retain direction.
Every node has a real benefit and visible selection details. Pan/zoom, overview,
branch navigation and the separate 144-node fixture remain supported.

During play the village is dominant. A local opponent label shows identity,
conviction and resistance; the existing context line gives the current objective.
During intermission the ritual subtitle reports the next opponent or map victory.
Completion is explicit, persistent and leaves Tab/Enter and movement available.
New figures use original procedural placeholder shapes, authored in this project;
no external artwork or reference pixels are incorporated.

## Verification and delivery slices

1. Merchant audience and four working inscriptions: threshold, overflow, reward,
   helper behavior, save compatibility, existing suites and rendered merchant.
2. Opponent progression and remaining twelve inscriptions: arrival, each mechanic,
   failure/retry, victory/save recovery, full and incomplete routes, completion,
   existing suites, large graph and rendered opponents/ritual/completion.

Human steering, economy pacing, alternate sizes and the overall time to finish
the map need playtesting. Automated route timings are evidence about the scripted
routes only. See PACING and VERIFICATION for actual results.
