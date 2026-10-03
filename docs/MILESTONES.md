# Small Following - staged milestones

Each stage has a bounded exit condition. Implemented parts and verified checks are recorded in the [verification record](VERIFICATION.md); an implemented feature alone does not complete a stage that still needs human acceptance or a blocked environment check.

## 0. Runnable starter

Implemented baseline: Godot 4.2.2 GDScript with Compatibility rendering, one small village, a directly controlled cultist, trailing robe, camera, three NPC gatherings and a compact village HUD.

Exit checks: scripts parse; movement, collisions, audience interaction and round transitions pass integration checks; actual rendered frames show scene objects rather than mockup backgrounds; environment limitations are recorded. The installed editor import error remains an explicit exception, not a clean import result. Preserve this baseline as subsequent systems grow.

## 1. Short round and ritual upgrades

Implemented scope: a provisional 11-second round targeting roughly three opening conversions, automatic speech with separate frequency/conviction effects, a purple ritual screen, nine real upgrade nodes with twelve total ranks, prerequisite/affordability protection and a clear return to the village or next round. The second rank on each outer node targets a close conversion of all 15 listeners at full progression without adding graph nodes. Data-driven rings/branches and pan/zoom are exercised with a separate 144-node fixture.

Exit checks:

- Representative routes exercise actual movement and conversation timing; the target is achieved without a three-recruit cap.
- Full-rank practical routes completely convert all three groups inside the unchanged timer with a small positive margin; incomplete or nonoptimal routes are compared using the same logic.
- A player can finish a round, inspect a node, buy an eligible upgrade and see its documented effect in another round.
- Invalid, maximum-rank, stale and unaffordable purchases do not alter currency or stats; one input buys one rank and current-to-next details explain its distinct benefit.
- Round transitions preserve direct movement; the village remains accessible between rounds.
- Pan/zoom selection works for the initial catalog and the large test fixture; rendered captures show readable details and a coherent purple seal.
- Human playtesting confirms opening pace, a close full-rank clear, readable controls and useful early/late choices at supported window sizes.

Status: bounded implementation supplied; retain human pacing/navigation acceptance as outstanding. Do not equate automated route evidence with a human playtest.

## 2. Local progression

Implemented scope: schema-2 local donations, purchased node ranks, recruitment-event total and round number, with schema-1 purchases migrated to rank 1 while preserving counters. Writes use a temporary file and backup; invalid data is rejected and recovery is explicit. Failed purchases must leave the prior economy intact. Restarting begins a new timed round rather than resuming a partial conversation.

Exit checks: missing, valid, malformed, unsupported-version and backup save paths behave predictably; valid schema-1 saves migrate without losing progress; saved ranks reapply the correct stats; failed writes cannot spend currency; tests use isolated save locations. Verify restart, migration and recovery in the eventual export as well.

This is a bounded local-save milestone with one implemented migration. Unique persistent followers, town data, settings, mid-round continuation and offline rewards are not implied. Further schema changes require explicit migrations.

## First-map finale (implemented; human acceptance outstanding)

Merchants, three town opponents and the Priest complete Bramblewick's playable
objective. The circle contains 32 working nodes / 35 ranks. Automated routes,
saved victories and rendered captures are documented in VERIFICATION.

Exit checks: actual player speech defeats each opponent, failed attempts retry,
completion survives reload/recovery, direct movement and village rounds remain
available, and human play confirms difficulty, economy and the full ritual's
readability. Human checks remain open; the later-map direction is deferred.

## 3. A second town (future direction)

Define a town unlock rule and implement a second, more populated town. Move town definitions into appropriately owned data and extend the save only for implemented state. Decide the audience lifecycle and what a permanent following means before expanding its counters.

Exit: a fresh-save session reaches the unlock, both towns remain navigable, town transitions preserve purchases and currency, and rewards are neither duplicated nor lost. Human routes demonstrate meaningful choices in each town.

## 4. Bounded automation

A first helper now travels to individual listeners and recruits them during active rounds. Two purchasable gatherings extend the existing village; they do not implement the second-town milestone. Add a second behavior or one spell only after the first creates a useful choice. Decide whether earlier towns earn idle income before building offline accrual.

Status: bounded helper implementation supplied; human usefulness and application-focus policy remain open.

Exit: the helper performs its documented task, rewards are counted once and the player can still steer and affect the round. A paused or inactive game follows an explicit earnings policy. Offline income, if adopted, has defined limits and clock-change behavior.

## 5. Production assets and a small release

Resolve missing original references, choose the production art treatment and replace placeholders in small batches. Add essential audio, input rebinding, accessible graph navigation, volume controls and readable focus states. Define the first export platform before platform-specific setup.

Exit: asset provenance is recorded; the exported game launches on the chosen target; purchases, restart and recovery work there; and a complete fresh-save session reaches an intended stopping point. Build a small complete slice before expanding to hundreds of upgrades, towns or spells.
