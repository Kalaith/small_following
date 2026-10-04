# Bellmarket and the title screen - implementation brief, 2026-10-04

## Scope and decision status

Requested: implement the market as level 2, with its own purple upgrade circle
and frequent choices between three to five useful upgrades. Running a wider
route and targeting richer NPC types must support different play styles. Add
a title screen where the password `PLZKTKS` permits starting any implemented
level. Bramblewick remains level 1. This brief follows the relevant sections
of [GDD_TEMPLATE](GDD_TEMPLATE.md) and advances the Bellmarket portion of
[FUTURE_LEVELS](FUTURE_LEVELS.md); the other proposed settings remain future work.

The five paths, names, prices, role thresholds, layout and 11-second market
round are provisional implementation choices. They are not additional user
decisions. Human route and economy acceptance remain outstanding.

## Play and progression

Bellmarket uses five compact gatherings with open listeners, guild traders and
wealthy patrons. Introductions open their matching role across multiple groups;
speech must still complete each conversion. Open listeners provide repeatable
funding even when both specialist roles are locked. Audiences reset each round.

Five independent three-node paths offer running speed, phrase frequency,
conviction per phrase, guild access/donations and patron access/donations.
All five first purchases cost 12 donations and no recruits. Each path then
costs 24 and 42 donations; selected later ranks also assign recruits. Running
remains gold-only. The catalog has fifteen real market nodes, with no shared
mandatory prerequisite that forces every play style down one chain. Exhausting
a path naturally reduces the remaining choices near completion.

Earned Bramblewick stats and the helper travel with the cultist. Its local
audience and opponent unlocks stay in Bramblewick. Market benefits apply only
in Bellmarket, preserving the original opening and full-core route benchmarks.
Wallets and recruitment history are shared. Password access skips the travel
gate, without granting upgrades or currency, so a fresh market start is also
tested for attainable funding.

Completing every Bramblewick rank opens deliberate travel from its centre to
Bellmarket. The Priest objective remains separate. The market intermission
allows return to Bramblewick. Arrival is between rounds, with direct movement;
the next round resets to that area's entrance. A failed save leaves the current
area and resources intact. No third playable area or idle income is implied.

## Screen brief

| Phase | Decision / primary action | Dominant focus | Supporting information / access |
| --- | --- | --- | --- |
| Title | Play or continue | Small Following title and purple cultist/seal artwork | Password field reveals the two implemented destinations; incorrect input has feedback |
| Market round | Choose a route and audience | Cobbled square, stalls and mixed listeners | Compact existing HUD; nearby role names, lock shapes and required introductions |
| Market ritual | Choose a play style and purchase | Five-part purple node circle, distinct from Bramblewick | Fixed rank/cost/effect details, branch controls, pan/zoom and return travel |
| Completed village centre | Enter Bellmarket or keep playing | Destination message and deliberate travel action | Save errors remain visible; dismissing preserves the current village |

Controls use Godot buttons, labels and input actions with mouse/touch access.
Typing a password must not trigger gameplay shortcuts. During play and ritual,
movement remains independent of menus and earning; Tab reveals the village.
The title has no running round. No extra asset or tool installation is needed.

## Data and ownership

`data/upgrades.json` retains every original ID and adds area-scoped market IDs.
Progression owns catalog membership, effect scope, purchases, completion and
transactional travel. Save schema 4 adds the active area and a validated
level-selection access flag. Schema 1/2/3 migration preserves existing balances,
rank semantics, recruitment events and encounter progress, defaulting to
Bramblewick. The password is a convenience unlock, not a security boundary.

Gatherings own per-listener eligibility, thresholds, overflow and single reward
emission. Helpers obey the same eligibility and recruitment authority. Locked
listeners cannot block later eligible slots or accumulate new speech work.
Specialist upgrades change donations, avoiding specialist conviction leaking
through mixed-group overflow. Main owns area setup and phase transitions;
the title and ritual emit intents only. The market uses actual procedural
actors/props with feet origins, Y sorting and world collision on layer 2.

## Acceptance and evidence

Validate original pacing, all five market paths, zero-balance funding, mixed
eligibility and helper behavior, area-scoped completion, stale/max-rank and
failed-save requests, schema migration/recovery and repeated return travel.
Measure actual conversions through movement and speech for fresh password,
carried village, specialist and upgraded market routes. Keep human steering
uncertainty explicit in [PACING](PACING.md).

Use isolated saves for all tests. Render title, unlocked level selection,
market listeners and the market circle through `tests/capture_starter.gd`;
inspect PNGs, including a compact window. Retain the separate large graph
fixture. Record actual results in [VERIFICATION](VERIFICATION.md), and keep
[TODO](../TODO.md) outstanding-only. No publishing or export change is included.
