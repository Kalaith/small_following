# More listeners and a helping hand

## Scope and decision status — 2026-10-03

The user requested more NPC groups through upgrades, further speaking and
movement upgrades gated by those groups, and one helper node that sends a
helper to recruit an individual NPC. This explicitly extends the former
nine-node limit. Existing IDs, ranks, effects and saves retain their meaning.
Godot 4.2.2, GDScript and Compatibility remain the baseline.

Provisional implementation choices: two additional five-person gatherings,
two further single-rank tiers each for talking and running, and one helper
unlock. The final catalog has sixteen nodes and nineteen purchases. These
counts, prices and helper timing are tuning choices, not user-confirmed values.

## Loop, player role and invariants

The eleven-second round and direct player movement remain unchanged. Buy a
gathering between rounds; its listeners appear immediately and reset with all
other audiences next round. Expanding the audience opens the next speaking
and running tier. The helper acts only during active time, travels to a single
unconverted listener and speaks to that listener. Player speech and helper
rewards share the gathering's conversion authority to prevent duplicate pay.
Tab, the ritual, next-round reset and intermission movement keep their roles.

## Systems, economy and data

| Addition | Prerequisites | Provisional effect | Cost |
| --- | --- | --- | --- |
| Meadow Invitations | Persuasion III | Five meadow listeners | 24 |
| Quickened Words IV | Meadow + Talking III | +0.5 base phrases/s | 27 |
| Fleet Footsteps IV | Meadow + Running III | +0.3 base running speed | 27 |
| East Lane Invitations | Meadow + Talking IV | Five east-lane listeners | 33 |
| Quickened Words V | East Lane + Talking IV | +0.6 base phrases/s | 36 |
| Fleet Footsteps V | East Lane + Running IV | +0.3 base running speed | 36 |
| Helping Hand | Meadow | One autonomous recruiter | 30 |

Every prerequisite needs rank 1. Existing first-nine full ranks remain the
15-listener pacing benchmark. Extra stat tiers give 3 phrases/s and 396 px/s
at full ranks; conviction remains independently capped at 3 per player phrase.
The helper uses its own fixed travel and phrase timing, documented in PACING.

Catalog definitions remain in `data/upgrades.json`. Unlock effects are explicit
single purchases; validation rejects fractional, repeated or ranked unlocks.
Schema 2 needs no new fields: purchased IDs recreate groups and helper on load.
Transient targets, speech and recruited listeners reset each round. Existing
schema-1 and schema-2 saves grant no new content for free. Failed saves grant
no unlocks. No new town, magic, offline earnings or unique population system.

## World, content and UI brief

The same village gains a meadow gathering at (470, 800) and an east-lane
gathering at (1250, 580), clear of existing prop footprints. Procedural actors
use feet origins and Y sorting. No external assets or original-art edits.

| Phase | Decision / action | Dominant focus | Supporting feedback |
| --- | --- | --- | --- |
| Village | Choose and approach a group | Village and actors | Existing HUD, local speech, visible helper target/progress |
| Ritual | Choose expansion, stat or helper node | Purple connected rings | Stationary price, prerequisites and current-to-next effects |
| Intermission village | Inspect the expanded village | Village | Existing Tab/Enter guidance; helper waits |

New nodes use unused angles and additional rings. Pan, zoom, transformed
selection and recenter remain available. Capture at 1280 × 800; smaller window
support and accessible graph traversal remain open. Human route uncertainty
and graph readability require playtesting separately from scripted checks.

## Implementation ownership and acceptance

1. Groups and stat tiers: progression validates effects and persists purchases;
   main creates gatherings; ritual displays unlock previews. Validate purchase
   guards, reload, group reset, actual expanded routes and rendered graph.
2. Helper: a dedicated actor owns travel/target/phrase state; gathering owns
   conversion; main clamps earning time and resets the helper. Validate travel,
   single-target effort, player races, expiry, resets, saves and visible feedback.

Run editor import, smoke, progression, pacing and displayed viewport captures
for each behavioral slice; inspect logs and pixels. Keep isolated test saves.
Commit each validated slice locally. Record actual evidence in VERIFICATION
and PACING. Human acceptance and larger-town milestones remain outstanding.
