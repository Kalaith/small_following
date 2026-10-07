# Verification record - ranked progression, 2026-10-02

## 2026-10-07 - Documented the four newest suites in the verification block

`test_mixed_audiences.gd`, `test_recruit_economy.gd`, `test_ritual_touch.gd`
and `test_touch_movement.gd` covered their respective features and passed,
but were absent from the documented command block in
[development guide §5](GAME_DEVELOPMENT_GUIDE.md#5-verification-workflow),
so following that guide literally would skip them. All four now appear
with the same `--fixed-fps 60` flag as the other timing-dependent suites.
Documentation only; every command in the updated block, including these
four, was actually run during this session's other 2026-10-07 changes with
no failures.

## 2026-10-07 - Bounded the helper's empty target search

`_choose_target` ran a fresh A* sweep over every eligible unconverted
listener, and `_advance_step` called it again on every one of up to sixty
1/60s sub-steps `advance()` takes to cover a long frame or a clamped round
boundary. Finding a target is self-limiting (the helper stops searching
once it has one), but finding none repeated the full sweep on every
remaining sub-step. `advance()` now clears a `_search_exhausted` flag at
entry; `_advance_step` skips `_choose_target` once a sweep this call has
already found nothing, and the flag clears again on the next `advance()`
call so a later opportunity is never missed.

A new `search_attempts` counter (diagnostic and test-observable only,
reset alongside the flag) makes the bound directly checkable.
`tests/test_helper.gd` gained a check: a full simulated second with no
reachable listener now sweeps for a target exactly once instead of once
per sub-step. All twenty-three suites pass; helper is now 37 checks.

## 2026-10-07 - The helper's obstacle contract is a group, not a name

`helper.gd`'s `configure_navigation` found footprint shapes with
`find_children("Shape", "CollisionShape2D", true, false)`, which only
worked because `village.gd` and `market.gd` both happened to name their
footprint's `CollisionShape2D` "Shape" and the player's own shape is named
`FeetCollision` instead. Three files agreed on a string literal with no
error if one changed. Both prop scripts now call
`collision.add_to_group("helper_obstacle_shape")` when building a
footprint, and `configure_navigation` finds every `CollisionShape2D` in the
subtree and filters by that group instead of by name, preserving the exact
same per-shape geometry inflation.

`tests/test_helper.gd` gained two checks built on a minimal, disposable
actor tree (not the real village/market scenes): a shape named something
else entirely still blocks pathing once it is in `helper_obstacle_shape`,
and a shape literally named "Shape" no longer blocks anything once it is
not in that group. All twenty-three suites pass; helper is now 36 checks.

## 2026-10-07 - Market presentation follows area, not an ID prefix

`configure` decided `_market_circle` (seal artwork, title, subtitle, legend
and return button) from `catalog[0].id.begins_with("market_")` — a single
string prefix on whichever item happened to sort first. It now reads that
same item's validated `area` field (`"bellmarket"`, defaulting to
`"bramblewick"` like every other area check in `progression.gd`), the same
field `data/upgrades.json` already sets on every market definition.
`progression.active_area` was considered but rejected: `test_market_ritual.gd`
deliberately configures the separate 144-node fixture against a progression
whose `active_area` is still `"bellmarket"` from an earlier step and expects
the generic scalable fallback, not the market seal, so the signal has to
live on the catalog's own entries, not the progression object.

`tests/test_market_ritual.gd` gained two checks: a one-item catalog whose ID
does not start with `market_` but carries `area: bellmarket` still renders
the market seal, and a village-area item whose ID happens to start with
`market_` does not. All twenty-three suites pass unchanged except market
ritual, now 112 checks.

## 2026-10-07 - Guarded effect-text lookup for merchant/trial/faith nodes

`_effect_text` indexed a literal label dictionary with `[key]` for
merchant/trial/faith nodes; a key present in the node's effect but absent
from that dictionary would throw instead of degrading. It now mirrors the
market branch just above it: a `current.has(key)` guard before anything
else, `labels.get(key, key.replace("_", " ").capitalize())` instead of
`[key]`, and `not next.has(key)` added to the existing `complete` check
before reading `next[key]`. All twelve current merchant/trial/faith nodes
still map to their named labels, so this was latent, not an active defect.

`tests/test_ritual_readability.gd` gained a check: a hand-built node whose
single effect key (`speech_frequency`) exists in `effect_preview`'s output
but has no dedicated label now shows a readable capitalized fallback
instead of crashing on selection. All twenty-three suites pass (readability
now 83 checks).

## 2026-10-07 - Typed progression, audio and market-gathering references

The code health review also found `ritual_screen.gd`'s `_progression` typed
as a bare `RefCounted`, checked at every call site with `has_method` before
a reflective `call(...)`. `const Progression = preload("res://scripts/
progression.gd")` works as a static type in Godot 4.2.2, so `_progression`,
`configure`'s parameter, `settings_screen.refresh`'s `audio` parameter (now
`GameAudio`) and `gathering.gd`'s `_market_progression`/`configure_market`
(now `Progression`) are statically typed. `has_method` guards and `.call`
reflection are gone; `is_instance_valid` guards remain where `_progression`
can legitimately be null before `configure()` runs.

`tests/test_mixed_audiences.gd`'s `MarketProgression` test double extended
`RefCounted` and would no longer satisfy `configure_market`'s typed
parameter; it now extends `Progression` and overrides only the two methods
market gatherings call, preserving the same lightweight double without a
real catalog or save. No other fixture duck-typed either parameter.

Behavior is unchanged; all twenty-three suites pass with unchanged check
counts (mixed audiences still 36). The headless import still exits 1 on the
existing unrelated `_EDITOR_GET` condition.

## 2026-10-07 - Keyboard/gamepad ritual graph navigation

The ritual graph had no keyboard or gamepad way to change its selection;
only tap/mouse hit-testing and the mouse-driven branch/node pickers could
move it. Four new Input Map actions (`ritual_nav_up/down/left/right`,
default T/F/G/H or the gamepad D-pad) are rebindable through the existing
`key_bindings.gd`/settings infrastructure like any other action.
`ritual_screen.navigate(direction)` steps from the selected node, or the
centre when nothing is selected, to the closest node whose position falls
within a roughly 70-degree cone of the requested direction, then calls the
existing `focus_node`. The existing `buy_upgrade` action (U / gamepad X)
already purchases whatever is selected, so this closes the gap named in
TODO: "gamepad movement mappings do not yet provide gamepad upgrade-graph
selection."

Wiring lives in `ritual_screen._unhandled_input`, guarded by `visible` and
the same `_pointer_input_enabled` flag `main.gd` already clears while
settings covers the ritual, so navigation cannot move the hidden selection
underneath an open settings page.

`tests/test_ritual_readability.gd` gained nine checks: directional entry
from the unselected centre against the real catalog (talk/faith/run/persuade
for up/down/left/right), moving to a different real node and holding at the
accessible edge without erroring, a zero-direction no-op, and a thirteen-step
walk across every ring of the separate 144-node fixture's sixth branch,
confirming it advances exactly one ring per press and does not wrap past the
outermost ring. `tests/test_key_mapping.gd` gained five checks driving the
actual `T` key and a simulated `InputEventJoypadButton` D-pad press through
real input dispatch, and confirming both are ignored while settings covers
the ritual or the ritual itself is hidden. All twenty-three suites pass:
smoke 92, progression 113, pacing 59, helper 34, encounters 210, readability
82, demo completion 46, audio 27, settings 34, key mapping 78, areas 44,
market progression 94, market pacing 31, market campaign 26, market flow 27,
title 15, market ritual 110, mixed audiences 36, recruit economy 134, ritual
touch 25, touch movement 27, merchants and exit reporting no failures.

Remapping which physical gamepad button fires an action (rather than the
keyboard key) remains outstanding; so does keyboard/gamepad focus navigation
of the settings screen itself. Physical gamepad hardware was not tested; the
simulated `InputEventJoypadButton` proves the action wiring, not real
controller feel. Rendered captures were not rerun: selection changes drawing
through the existing `focus_node`/`select_node` path exercised by every other
suite, and no new geometry or layout was added.

## 2026-10-07 - Preferences schema migration

The code health review also found that `settings_store.valid()` required
every `DEFAULTS` key to be present, so adding a single new preference would
fail validation on every existing `settings.json`, fall through to an
equally outdated backup, and block writes for the session. `valid()` now
checks only the keys actually present in a saved file; an absent key is
treated as a migration and defaulted from `DEFAULTS` on load rather than a
corrupt file. `CURRENT_SCHEMA` moved from a fixed 1 to a named constant
(now 2); saving always writes the full current key set at that schema.
Separately, `save_settings()` no longer overwrites an existing `.corrupt`
recovery file with a second one, matching `progression.gd`'s policy of
preserving the first damaged original.

`tests/test_settings.gd` gained seven checks: a schema-1 file missing a
newer key defaults it and is not treated as recovered/blocked; the migrated
values save forward and read back at the current schema; a present
out-of-range key still fails `valid()`; and a pre-existing `.corrupt` file
blocks a second overwrite and is left byte-for-byte unchanged. All
twenty-three suites pass: smoke 92, progression 113, pacing 59, helper 34,
encounters 210, readability 73, demo completion 46, audio 27, settings 34,
key mapping 73, areas 44, market progression 94, market pacing 31, market
campaign 26, market flow 27, title 15, market ritual 110, mixed audiences 36,
recruit economy 134, ritual touch 25, touch movement 27, merchants and exit
reporting no failures. No UI, save or catalog behavior changed; this is a
preferences-storage fix only. The recorded `_EDITOR_GET` import error is
unrelated and was not rerun in this pass.

## 2026-10-07 - Ritual refresh cost

A full-source review recorded its maintainability findings under TODO's code
health section and fixed the measured one: refreshing the ritual screen asked
progression to re-derive every node's state, and each question repeated the
linear catalog lookup. `purchase_state` now resolves a definition once,
`status` answers from a shared `_definition_status` without building a player
message, `effect_preview` composes from a single `_all_effect_totals` pass
instead of about thirty per-key sweeps, and `_update_branch_navigation`
summarizes once per refresh instead of twice. `_sum_effect` keeps its
allocation-free per-key form for the per-frame speech and conviction calls.

Measured `update_state` with a temporary in-tree probe at 1200x800, twenty
calls per figure, before and after:

| Catalog | Before | After |
| --- | --- | --- |
| Production, 32 nodes | 1.75 ms | 0.54 ms |
| `tests/fixtures` 144 nodes | 11.46 ms | 2.58 ms |

Behavior is unchanged. All twenty-three suites pass with the same check counts
as before the change: smoke 92, progression 113, pacing 59, helper 34,
encounters 210, readability 73, demo completion 46, audio 27, settings 27, key
mapping 73, areas 44, market progression 94, market pacing 31, market campaign
26, market flow 27, title 15, market ritual 110, mixed audiences 36, recruit
economy 134, ritual touch 25, touch movement 27, merchants and exit reporting
no failures. A temporary parity check compared `effect_preview` against the
untouched per-key helpers for every definition across both areas at no ranks,
every first rank and every maximum rank: 372 previews, exact float and type
equality, no mismatches. Both probes were deleted after use.

The recorded `_EDITOR_GET` import error and its exit status 1 persist and are
unrelated to this change. Rendered captures were not rerun: no drawing,
layout or catalog data changed, and the four suites that inspect the graph's
states and labels pass unchanged. Human play feel still needs its own pass.

## 2026-10-05 - Project Roost registration

The publisher now records successful WebHatchery preview and production
deployments using the configured Project Roost API. Godot projects classify as
games and use `/games/<slug>/` links. Deployment events refresh the shared
project timestamp used by recent-update listings; the latest-deployment query
omits archived projects.

Published the backend update through Project Roost's preview and production
publisher, then republished the existing Small Following build to both
WebHatchery targets. The preview and production APIs return Small Following as
a visible `game` with `show_on_homepage=true`, fresh update timestamps and the
expected preview and production URLs. Both APIs have successful deployment
records. The production game URL responded HTTP 200. The old `unknown_project`
profile is archived and hidden, and no longer appears in the production
project list or latest-deployment panel.

`tests/test_publish.ps1`: 24 checks passed. PHP syntax checks and a direct
metadata check passed. `composer run test` could not start because the shared
`vendor/bin/phpunit` executable is absent; no tools were installed. The
configured Project Roost production API uses `webhatchery.au`; this executor
could not resolve `webhatchery.com.au`, so the `.com.au` page itself was not
visually verified.

## 2026-10-03 - Authored magical seal

The parent research environment materialized and inspected the three new
references, then authorized the image-grounded composition brief. The Windows
executor did not view their original pixels and did not retry that transfer.
See [provenance and observed reference features](reference/README.md).

The current 32 nodes now form distinct constellations: a Words crescent,
Running hook, Merchant loop, Trials diagonal fork, Creed curl, Faith fork,
Village pair and Followers satellite. Thin inscription bands, broken arcs,
regular rim ticks and three offset satellite motifs frame a larger pentagram
medallion. Its strong illumination remains exclusive to all-ranks completion.
The data catalog is byte-identical: 35 ranks, 1014 total donations and all
effects/prerequisites unchanged. No save, gameplay or area-transition changes.

Initial pixel review found that some selected crosslinks passed behind
unrelated icons. Nine links now use one authored bend each; their actual
prerequisites remain unchanged. All 40 production prerequisite routes clear
unrelated node centres by at least 36 world pixels and the medallion by 90.
Node separation is at least 85 pixels, with 156.6 pixels of central clearance.
Opaque node/label backgrounds protect their contents from ornament.

Applied-project checks use Godot **4.2.2.stable.mono.official.15073afe3**,
isolated APPDATA/fixture saves, Dummy audio and fixed 60 fps:

| Check | Result |
| --- | --- |
| Five changed GDScript files | `--check-only`: all exit 0 |
| Ritual readability / demo completion | 73 / 46 checks, zero failures, exit 0 |
| Smoke / progression / pacing | 92 / 113 / 59 checks, zero failures, exit 0 |
| Hidden `capture_starter.gd --ritual-only` | 15 PNGs, exit 0, no runtime diagnostics |
| Headless editor import | Existing exit 1 `_EDITOR_GET` error and cursor/Blender-path warnings |

The five suites total **383 passing checks**. All runtime and parse logs are
clean. [Recorded output](verification/ritual-seal-checks.txt) retains the import
failure separately. Pacing still measures three opening conversions and the
original-core 15-listener clear at 10.517 seconds with 0.483 seconds remaining;
incomplete and nonoptimal comparisons pass. Unchanged audio/settings/exit
suites and the full village capture sequence were not repeated in this visual
slice; their earlier completion-slice results remain recorded below.

Actual 1280 x 800 Compatibility/OpenGL captures on the NVIDIA GeForce RTX
4080 SUPER were compared to the parent's explicit inspected-reference brief:
[before](verification/ritual-seal-before.png),
[entry](verification/ritual-seal-entry.png),
[completed medallion](verification/ritual-demo-ready.png),
[message](verification/ritual-demo-message.png),
[East Lane paths](verification/ritual-readability-east.png),
[Priest ancestry](verification/ritual-seal-priest-paths.png) and
[Creed paths](verification/ritual-seal-creed-paths.png).
Varied local geometry and offset satellites now form the composition; the
central sigil and rim unify it. Real paths remain stronger than the ornament.
The message is readable and dismissal preserves the lit centre. The separate
144-node fixture remains navigable and explicitly labelled test content.

These are local render and behavior checks, not original-image pixel matching
or human art-direction acceptance. Alternate sizes, physical gamepad use and
human navigation/feel remain unverified. No publishing, exports, tool changes
or ordinary player-save writes occurred.

## 2026-10-03 - Requested magical-seal art correction: blocked on references

This earlier checkpoint was superseded by the parent inspection and authored
seal slice above; it records the Windows transfer limitation at that time.

The even-sector layout was a mechanical readability/coverage pass. The user
has clarified that it does not yet deliver the intended magical-circle art
direction. The next visual slice must integrate current upgrade nodes into
coherent rings, sigils and interlocking motifs, using quieter decoration and
clear interactive/prerequisite paths. Current spacing checks and screenshots
do not establish acceptance of that composition.

Three new references resolve in Library, but current supported reads return
no image blocks and Windows materialization remains unavailable. No pixels
were inspected and no reference-dependent redraw was attempted. The
[reference record](reference/README.md) retains exact identifiers and metadata.
Actual access and a rendered comparison against those references are pending.

The interrupted completion work was resumed after the user reset usage.
Its applied runtime/render evidence below is retained; local commit
`c2c9205` delivers the centre independently of the pending art correction.
No further gameplay behavior or catalog changes were made for this checkpoint.

## 2026-10-03 - Completed circle and demo message

The all-ranks centre is derived by `Progression.is_circle_complete()` from
the nonempty current catalog. It lights on the last successful purchase and
on a completed-save reload. Clicking it opens the exact text **This is the
end of the demo**. Keep playing/Esc dismiss; Tab returns to the village and
Enter starts another round. A fixed button reaches the centre when it is
panned away. No catalog, balance, schema or saved completion flag changed;
Priest victory remains independent. Future areas remain unimplemented.

Checks ran against the applied D: checkout with the installed
**4.2.2.stable.mono.official.15073afe3** executable. Process-local APPDATA
profiles and isolated fixtures preserve normal progression/settings saves.
All runtime suites used `--headless --audio-driver Dummy --fixed-fps 60`.

| Check | Result |
| --- | --- |
| All 26 GDScript files | `--check-only`, every exit 0, no parse diagnostics |
| New demo-completion suite | 46 checks, zero failures, exit 0 |
| Smoke / progression | 92 / 113 checks, zero failures, exit 0 |
| Pacing / helper / merchants | 59 / 34 / 25 checks, zero failures, exit 0 |
| Encounters / ritual readability | 210 / 84 checks, zero failures, exit 0 |
| Audio / settings | 27 / 27 checks, zero failures, exit 0 |
| Exit Game | Actual viewport button click flushed isolated saves and exited 0 |
| Hidden rendering capture | 40 actual PNGs, exit 0, final logs have no warning/error diagnostics |
| Headless editor import | Existing exit 1 `_EDITOR_GET` error, cursor/Blender-path warnings |

The ten counted suites total **717 passing checks**, plus the separate exit
check. Runtime suite logs contain no warning/error diagnostics.
[Recorded output](verification/ritual-completion-checks.txt) includes every
suite, import and parse run. Import is not claimed clean.

New coverage distinguishes owning every node from buying every rank, rejects
an empty catalog, and includes a newly added fixture entry without changing
completion code. It checks final-rank affordability and failed-save rollback,
reload with currency/recruitment/round/encounter preservation, transformed
centre clicks at three zooms, hover feedback, repeated activation and unchanged
save bytes. WASD remains active with the message open. Esc/settings priority,
Tab return, configuration changes and continuing rounds dismiss it correctly.
The separate 144-node fixture and existing migration/recovery guards pass.

Actual 1280 x 800 PNGs were inspected from hidden Compatibility/OpenGL 3.3
rendering on the NVIDIA GeForce RTX 4080 SUPER, with Dummy audio and fixed
60 fps. [One missing second rank](verification/ritual-demo-incomplete.png)
keeps the centre quiet; the [last rank lights it](verification/ritual-demo-ready.png).
The [message](verification/ritual-demo-message.png) fits with a clear Keep
playing action. [Dismissal](verification/ritual-demo-dismissed.png) restores
the same completed-circle pixels. Focused East Lane and fixture branch
captures retain readable details, node controls and prerequisite paths.
The original-core route still completes 15 conversions at 10.517 seconds,
leaving 0.483 seconds; opening and nonoptimal comparisons are unchanged.
Human play feel and alternate-size acceptance remain outstanding.

An initial capture reported native Ogg playback resources still in use at
shutdown. A verbose reproduction identified Dummy-driver music playback.
The visual fixture now disables audio output before scene startup and frees
the scene before quitting. The final applied capture exits cleanly, and the
four demo PNGs and East Lane remain byte-identical. Production audio is
unchanged and retains its separate passing suite.

The new source reference could not be materialized: the supported Windows
helper failed at `os.setxattr`, leaving no final file. A supported batch upload
of the final ready/message PNGs also stopped with
`library upload failed: Library prepare_uploads is not available`; no Library
attachment IDs were returned. Local PNGs are retained here. No transfer helper
was bypassed. See [reference provenance](reference/README.md).
No tools were installed, normal saves altered, exports rebuilt or publication
performed.

## 2026-10-03 - Fuller ritual layout

Spread the existing branches through eight evenly spaced sectors with a
gentle outward sweep. All 32 catalog nodes, 35 ranks, 1014-donation total,
prerequisites, effects and ring radii remain unchanged. See the scoped
[ritual brief](RITUAL_COMPLETION.md).

Applied-file checks in the requested D: project pass with isolated test saves:
smoke 92, progression 113, pacing 59 and readability 84 checks, all with zero
failures and exit 0. Readability includes angular coverage, node spacing,
hover paths, transformed selection and the separate 144-node fixture.
The installed Godot 4.2.2 headless editor import retains exit 1 with its known
`_EDITOR_GET` error and cursor/Blender-path warnings.

Hidden rendering with Dummy audio and fixed 60 fps exits 0 without runtime
diagnostics. Inspected the actual [full-circle overview](verification/ritual-layout-full-circle.png),
focused East Lane and fixture captures. Branches spread across the circle;
selection details, node browser and paths remain readable. The original-core
capture still converts all 15 listeners at 10.517 seconds with 0.483 seconds
remaining. These are scripted timing and pixel checks, not human acceptance.

The new supplied screenshot remains unavailable through the supported Windows
Library transfer; see [reference status](reference/README.md). No balance,
runtime saves, exports, publishing or installed tools changed.

## Environment and scope

Final project: `D:\WebHatchery\godot\small_following`.
Installed engine: **4.2.2.stable.mono.official.15073afe3**, using GDScript and Compatibility rendering. Actual captures use OpenGL 3.3 on NVIDIA GeForce RTX 4080 SUPER in a hidden window.

The project and its AGENTS/design/save guidance were inspected first. Changes were staged in a writable task directory. SHA-256 comparisons checked for concurrent project changes before copying only changed/new task files. Village geometry, player scene, movement implementation and all nine node IDs remain unchanged.

Automated runs use a process-local APPDATA override to a private task profile. Save tests use unique fixture filenames or disable persistence. They do not read, migrate or overwrite ordinary player progress. No software was installed, global editor settings changed, remote created, pushed or published.

## Final-folder checks

| Check | Result |
| --- | --- |
| All **11 GDScript files**, including tests/fixture | `--check-only`: every exit 0, no parse diagnostics |
| `tests/test_progression.gd` | **89 checks, 0 failures**, exit 0 |
| `tests/smoke_test.gd` | **70 checks, 0 failures**, exit 0 |
| `tests/test_pacing.gd` | **48 checks, 0 failures**, exit 0 |
| Actual OpenGL capture script | **10 PNGs**, exit 0; full-clear frame records 15 recruits with 0.483 seconds remaining |
| Headless editor `--import` | Exit 1 with the existing `_EDITOR_GET` settings error |

The three suites total **207 passing checks**. [Full check output](verification/checks.txt) records per-script statuses and measured routes. Initial sandbox tests also printed a Windows certificate-store diagnostic; final scoped checks are recorded separately in that log.

Integration checks cover movement, normalized diagonals, robe motion, bounds/well collision, speech timing and range exits, round/ritual transitions and movement between rounds. Purchase checks exercise actual UI buttons, current-rank guards, maximum rank, prerequisite/affordability feedback and distinct live effects. A schema-1 save with all nine purchases is loaded into the real scene, its three added ranks are bought, a stale repeated activation is rejected, and relaunch verifies currency, counters and effects.

Save checks cover schema-1 partial/full/backup migration, unchanged first-rank effects, exact prior-save backup bytes, schema-2 round trips, invalid boolean/fractional/out-of-range ranks, unknown IDs and missing prerequisites, future-schema protection, corruption recovery and failed-write purchase rollback. Catalog checks include per-rank costs/effects and malformed/cyclic definitions.

Graph checks cover actual mouse selection, anchored wheel zoom, drag/release recovery and transformed hit testing. All **144 distinct nodes** in the separate 12-ring fixture are focusable and hit-tested, including after pan/zoom. The production catalog still has **nine nodes**, with **twelve total rank purchases**; the fixture is not extra gameplay content.

## Measured full-village completion

The baseline remains **11 seconds**. Tests move the actual `CharacterBody2D` and use actual conversation/round logic at 1/60-second physics steps. A practical route includes 0.20 seconds initial reaction and 0.10 seconds when switching groups, stops inside range and fully converts each audience before leaving.

| Route / progression | Conversions | Full-clear time | Margin |
| --- | --- | --- | --- |
| Unupgraded direct garden, well or market, with reaction allowance | 3 each | - | - |
| Previous nine purchases, garden -> well -> market | 10 / 15 | - | - |
| **Full ranks, garden -> well -> market, 95 px stops** | **15 / 15** | **10.517 s** | **0.483 s** |
| Full ranks, same order, deeper 60 px stops | 15 / 15 | 10.700 s | 0.300 s |
| Full ranks, same order, eight-direction steering | 15 / 15 | 10.583 s | 0.417 s |
| Full ranks, market -> well -> garden | 14 / 15 | - | - |
| Full ranks, longer reaction/switching pauses | 13 / 15 | - | - |

Five of six practical group orders clear the village. The representative route finishes its groups at 3.100, 6.633 and 10.517 seconds and earns the normal 45 donations. No special full-upgrade bonus, hidden recruitment cap, teleport or extended gameplay timer is involved.

Removing only the final talking rank reduces that route to 13 recruits; removing only the final conviction rank gives 12. Removing only the final running rank still permits a 10.750-second clear, but reduces the margin to 0.250 seconds. On the deeper route that omission leaves just 0.033 seconds; the running rank restores 0.300 seconds. It therefore buys travel/positioning tolerance rather than always adding another recruit.

The original nine purchases retain their effects and cost 81 donations. Three added outer ranks cost 18 each: **135 total donations**. Full stats are **1.9 phrases/s, 3 conviction/phrase and 288 px/s**. See [PACING.md](PACING.md) for every route, economic assumptions and human-playtest limits.

## Actual rendered inspection

The capture script uses fixed 60 Hz and persistence-disabled fixtures. All ten images are actual 1280 x 800 viewport frames:

- [Village and speech](verification/starter-runtime.png), [moving robe](verification/starter-moving.png), [round summary](verification/starter-summary.png), [first purchase](verification/ritual-purchased.png) and [next round](verification/starter-next-round.png).
- [Available second rank](verification/ritual-rank-available.png): selected 1/2 node, 1.60 -> 1.90 phrases/s and exact 18-donation next cost.
- [Maximum rank](verification/ritual-rank-max.png): selected 2/2 node, maximum messaging and disabled purchase.
- [Full village conversion](verification/village-full-clear.png): 15 recruits, 45 donations and the rounded 0.5-second remaining HUD.
- [144-node fixture overview](verification/ritual-144-fixture.png) and [distant-node focus](verification/ritual-fixture-focus.png), explicitly labeled test content.

Visual inspection checked partial/max rank marks, readable effects/costs, prerequisite details and the full-clear HUD. It caught overlapping inner running-branch labels; a narrow label-placement adjustment was made before refreshing final captures. Node positions, graph navigation and village geometry remain unchanged.

## Remaining limits

Scripted routes establish repeatable mechanics and timing allowances, not human route discovery or game feel. Ordinary keyboard play, longer hesitation, physical gamepad use, keyboard-only graph traversal, alternate aspect ratios and exported builds still need evaluation. Graph navigation currently uses a mouse. Human acceptance of the narrow full-rank finish remains outstanding.

Save scope remains currency, integer purchased ranks, recruitment-event total and round number. Relaunch starts a fresh timer/audience at the entrance; offline rewards and mid-round resume are not implemented. Damaged saves are preserved. Failed earned-currency writes retain earnings in memory only until saving succeeds.

Headless editor import still reports:

```
ERROR: Condition "!EditorSettings::get_singleton() || !EditorSettings::get_singleton()->has_setting(p_setting)" is true. Returning: Variant()
at: _EDITOR_GET (editor/editor_settings.cpp:1144)
```

A clean editor import is **not claimed**. Earlier ordinary-launch probes reached the starter scene, but `--quit-after` returned 1 without a runtime diagnostic. These installed-engine check limits are separate from passing script/runtime tests and successful rendered captures. No engine repair or installation was attempted.

The supplied image originals remain absent locally. The parent inspected ritual references in the cloud and supplied descriptions; the Windows implementation uses independently authored geometry and does not claim local pixel matching. The previous Windows Library `os.setxattr` transfer failure was not retried. See [reference provenance](reference/README.md).

## Documentation set - 2026-10-03

Reviewed the six supplied RustGames reference documents and authored local
Godot versions of `GAME_DEVELOPMENT_GUIDE.md`, `GDD_TEMPLATE.md`, `UI_STYLE.md`,
`CODE_STANDARDS.md`, `COMMIT_STYLE.md` and `docs/AGENTS.md`. The README links
to the new set, and root agent guidance points to the relevant standards.
The existing game design, pacing decisions, TODO and milestone statuses are
preserved. The [development guide](GAME_DEVELOPMENT_GUIDE.md#7-adaptation-from-the-rust-references)
records which reference ideas were adapted and which Rust-specific rules do
not apply.

Reviewed ownership and examples against `project.godot`, the main/player
scenes, gameplay/progression/ritual scripts, the upgrade catalog and the test
save/capture setup. Checked the eight new or edited documentation entry points:
**73 local links and heading anchors resolved**, Markdown fences were balanced,
files had final newlines and all PowerShell example blocks passed syntax
parsing. This checks example syntax and paths, not successful engine execution.

This change edits documentation only. No runtime tests, editor import or
rendered captures were rerun; the 2026-10-02 results above remain historical
evidence. No gameplay, art, progression data or runtime saves were changed.
The export target, minimum supported window size, accessible graph navigation
and human playtest acceptance remain unresolved. No commit, tool installation,
publishing or remote change was performed.

## Commit cadence and initial repository snapshot - 2026-10-03

Updated root agent guidance, the development workflow and commit style to
require regular local commits for complete, validated feature slices, fixes
and documentation changes. Each slice includes its related tests and docs;
unfinished experiments and unrelated user work stay outside routine commits.
The user explicitly requested the initial commit of the existing project.

This update changes documentation only. Runtime suites and rendered captures
were not rerun; the earlier gameplay results retain their recorded dates and
limitations. The initial snapshot includes the existing project, tests,
documentation and verification images, with caches and local outputs excluded
by `.gitignore`.

Commit preparation verified 34 local links in the four edited documents and
reviewed the 48 staged project files. The edited documents pass
`git diff --cached --check`. The full initial snapshot retains existing blank
lines at EOF in several files and whitespace-only lines in the historical
`verification/checks.txt` log; these produce whitespace diagnostics. Original
assets and historical output were preserved. No runtime caches, player saves
or export outputs are staged.


## 2026-10-03 - village invitations and further stat tiers

Godot 4.2.2 Mono / Compatibility, Windows, 1280 x 800 captures. The requested
extension preserves all original IDs/ranks and adds six functioning nodes.
Commands are the README checks; logs were inspected for diagnostics.

- Headless editor import: exit 1, existing `_EDITOR_GET` / EditorSettings error,
  plus custom-cursor and missing Blender-path warnings. No script parse errors.
- Progression: 109 checks, zero failures, including new unlock validation,
  prerequisite/max/stale guards and schema-2 round trips.
- Smoke: 91 checks, zero failures; invitation purchases create/reset/reload
  actual listeners without duplication. Original movement/transition and
  144-node transformed selection checks still pass.
- Pacing: 54 checks, zero failures. Opening yields remain three; original
  core practical clear remains 15 at 10.517 s (0.483 s left). Expanded full
  player route recruits 23/25; incomplete final tier 19/25; hesitant 20/25.
- Render capture: exit 0, actual OpenGL NVIDIA renderer. Inspected expanded
  village and ritual PNGs. All five groups occupy clear ground; overview
  captions were shortened after inspecting overlap at the fitted zoom.

Human steering, expanded economy and graph discovery remain unverified.
Helper implementation follows in its own slice; no second town or offline work.


## 2026-10-03 - one helper and final expanded catalog

Final catalog: sixteen real nodes, nineteen purchases, 348 donations total.
All original ranks and IDs remain intact. The following commands were run
against the final behavioral changes with the README's installed Godot 4.2.2
Mono executable; all test saves were isolated from normal player progression.

| Command flags after the executable | Result |
| --- | --- |
| `--headless --path . --import` | Exit 1; existing `_EDITOR_GET` / EditorSettings error, custom-cursor and Blender-path warnings; no script errors |
| `--headless --path . --script res://tests/test_progression.gd` | Exit 0; 113 checks, zero failures |
| `--headless --fixed-fps 60 --path . --script res://tests/smoke_test.gd` | Exit 0; 92 checks, zero failures |
| `--headless --fixed-fps 60 --path . --script res://tests/test_pacing.gd` | Exit 0; 59 checks, zero failures |
| `--headless --fixed-fps 60 --path . --script res://tests/test_helper.gd` | Exit 0; 34 checks, zero failures |
| `--fixed-fps 60 --path . --script res://tests/capture_starter.gd -- --capture-dir=<project>/docs/verification` | Exit 0; actual Compatibility/OpenGL NVIDIA output |

All four behavioral suite logs were inspected: **298 checks, zero failures**,
with no runtime warnings/errors. Meaningful helper coverage includes failed
purchase storage, prerequisites, stale/max protection, one spawned actor,
independent movement/speech stats, timed arrival, partial individual effort,
player/target races, single reward authority, out-of-order listener conversion,
conviction overflow, clamped expiry, intermission movement, round reset,
all 25 reachable listener stand cells and a detour checked against the actual
market collider. Smoke reload recreates both new groups and the helper from
schema-2 ranks; schema-1 migration and backup tests still pass.

Pacing retains the original three-recruit opening and 15-listener clear at
10.517 seconds (0.483 remaining). Expanded player upgrades yield 23/25 on the
garden-first route. The meadow-first route improves from 21 to 24 with three
helper conversions; garden-first work overlaps the helper's targets and adds
none. An initial test incorrectly assumed every route would gain helper
conversions; it was corrected to verify that documented competition, without
changing recruitment rules or awarding a hidden helper bonus. Neither expanded
route is claimed to clear all 25. Detailed timing is in [PACING](PACING.md).

Inspected actual 1280 x 800 PNGs: starter ritual, expanded village, expanded
ritual, `ritual-expansion-locked.png`, `ritual-helper.png`, and
`helper-speaking.png`. The fitted graph shows sixteen separate glyphs with
short captions and rank pips; full selected details and the two-prerequisite
locked state remain legible. New listeners stand in open areas. The teal helper,
lilac sash, target ring and local phrase feedback are visible. The unchanged
15-listener capture also reports the same 10.517-second clear.

Automated UI input covers pan/zoom/selection, purchase buttons, next-round
transitions and the 144-node fixture. Human steering, expanded progression
prices, graph discovery and helper usefulness still need playtesting. No
export, installation, remote setup, publishing or player-save changes occurred.


## 2026-10-03 - ritual readability and navigation

The approved [screen brief](RITUAL_READABILITY.md) was implemented against
commit `7cb27cd`, which already contained the village expansion and helper.
The existing sixteen nodes, nineteen purchases, prices, prerequisites,
effects and saves were retained. SHA-256 comparisons verified unchanged
`data/upgrades.json`, progression, main, player, gathering, helper and village
scripts, both scenes and `project.godot`. The new `ritual_layout.gd` derives
view positions without changing the catalog.

Before the pass, all eighteen prerequisite connections and decorative ring
polygons appeared together, with tiers changing angle between rings. The
actual [before capture](verification/ritual-readability-before.png) preserves
that local rendered baseline. The updated [overview](verification/ritual-readability-overview.png)
keeps eleven same-branch progress edges; seven cross-branch links are
conditional on hover/selection ancestry. Solid main paths, dashed crosslinks,
direction marks and lower-contrast decoration distinguish progression from
ornament. Words is above, Running left, Creed right, and village/follower
upgrades below. All sixteen compact labels fit the inspected overview.

The existing detail panel retains effects, costs, ranks and missing
requirements. [East Lane](verification/ritual-readability-east.png) shows
4 -> 5 groups and the original 33-donation price; the
[missing-requirement state](verification/ritual-readability-missing.png) names
Words IV explicitly. The [hover capture](verification/ritual-readability-hover.png)
shows Words V ancestry while retaining East Lane's selected details.
[Mixed states](verification/ritual-readability-states.png) distinguish a locked
diamond/bar, hollow unaffordable circle, bright available circle/plus and
completed fill/check. The [rank capture](verification/ritual-rank-available.png)
also shows partially filled rank arcs. Rank details remain available through
selection and the node picker.

Overview clears selection and hover, fits the graph and disables purchasing.
Recenter fits while retaining selection. Branch controls, a complete per-branch
node list and Focus selected remain reachable outside the moving graph.
Large graphs substitute a branch dropdown with owned/ready counts. Distant
overview labels reduce; nodes remain drawn and pickable, major unlocks retain
priority, and the list provides a navigation alternative. Collision-aware
labels omit an obstructed caption rather than cover another node; selected
facts remain in the fixed panel.

### Final project verification

Engine: **4.2.2.stable.mono.official.15073afe3**, GDScript, Compatibility,
Windows. Commands ran in `D:\WebHatchery\godot\small_following` using the
README executable. A process-local APPDATA test profile and isolated fixture
saves kept ordinary player progress untouched.

| Check | Result |
| --- | --- |
| All 15 GDScript files, including tests and fixture | `--check-only`: all exit 0, no parse errors |
| `tests/test_progression.gd` | 113 checks, 0 failures, exit 0 |
| `tests/smoke_test.gd` | 92 checks, 0 failures, exit 0 |
| `tests/test_pacing.gd` | 59 checks, 0 failures, exit 0 |
| `tests/test_helper.gd` | 34 checks, 0 failures, exit 0 |
| `tests/test_ritual_readability.gd` | 60 checks, 0 failures, exit 0 |
| Actual OpenGL capture script, fixed 60 Hz | 21 PNGs generated, exit 0, no runtime diagnostics |
| Headless editor import | Exit 1, existing `_EDITOR_GET` error and cursor/Blender-path warnings |

**358 checks passed.** [The current log](verification/readability-checks.txt)
contains commands' per-script results and actual route data. Required runtime
suites and captures produced no errors in the final scoped run. Initial sandbox
probes printed the known certificate-store diagnostic; that did not recur in
the final run. The installed editor's import problem remains unresolved and
is not presented as a clean import.

The new suite exercises sector/outward layout, default-hidden crosslinks,
recursive ancestry, dim unrelated edges, explicit missing requirements,
hover/selection isolation and mouse-exit recovery. Actual graph mouse handlers
are checked after three zoom/pan combinations. Actual Overview, Recenter,
branch, node-picker and Focus selected controls are exercised. The suite
checks nonoverlapping overview labels and focuses/picks all 144 distinct
fixture nodes without altering catalog data or purchases.

Existing purchase, failed-write, stale/max-rank, migration, recovery, helper
and round-transition suites remain passing. Pacing is unchanged: the original
full-ranked core clears fifteen at **10.517 s**, with **0.483 s remaining**.
Expanded-route and helper results remain those documented in [PACING](PACING.md);
this UI pass adds no completion rule or balance adjustment.

### Rendered review and delivery

Actual 1280 x 800 frames used OpenGL 3.3 on NVIDIA GeForce RTX 4080 SUPER.
Inspected overview, East Lane affordable/locked selection, mixed purchase
states, hover preview, original rank states and the 144-node overview,
branch navigation and distant focus. The first review caught empty
`RANK 0/0` text and the lack of a visible way to clear path focus; both were
fixed and the final captures inspected again. Final fixture captures retain
their explicit test-only subtitle.

Twenty-one frames were generated in a temporary directory from the actual
project. Only the sixteen ritual-state images were added/refreshed here,
including the preserved before image; unrelated village/robe screenshots
were retained. The Library upload of `ritual-readability-east.png` succeeded
(`libfile_9e00695a0fe48191b1e6fadd8d88a4fd`). The required Windows metadata
helper still lacks `os.setxattr`, so local Library identity metadata was not
written; the saved Library image exists. No unsupported reference transfer
retry or helper bypass was performed.

Human preference, long-session navigation, keyboard/gamepad graph traversal,
alternate viewport sizes and a genuinely authored 100+ node tree remain
unverified. The fixture demonstrates access and transform behavior rather
than a finished large upgrade economy. No installation, export, remote,
push or publishing change was made.

## 2026-10-03 — merchant slice

Added two optional merchant listeners and four working inscriptions. The isolated
merchant suite passed (0 failures), smoke 92/92, progression 113/113, pacing 59/59,
helper 34/34 and ritual readability 60/60. Logs were inspected. Headless import
still reports the existing `_EDITOR_GET` error and exits 1; runtime suites exit 0.
Rendered `capture_starter.gd` completed with exit 0 on Compatibility/NVIDIA.
Inspected `village-merchants.png`: distinct hats/purses, local speech feedback,
visible cultist and compact HUD. Original practical full-clear capture remains
15 conversions in 10.517 seconds, with 0.483 seconds left. Human play is unverified.

## 2026-10-03 — first-map opponents, priest and completed circle

Implemented three opponents (Skeptic, Town Guard, Zealot), the Priest boss,
walking arrivals, distinct resistances, one attempt per round, saved victories
and explicit Bramblewick completion. Added twelve inscriptions after the merchant
slice; production now has 32 nodes / 35 ranks / eight branches / six rings.

### Commands and inspected results

Used the installed Godot 4.2.2 Mono executable from README with Compatibility.
Ran headless `--path . --import`, then each script with `--headless --fixed-fps 60
--path . --script res://tests/<name>.gd`. Inspected all logs, including exit-zero
runs. Latest results:

| Suite | Checks | Failures | Exit |
| --- | ---: | ---: | ---: |
| `smoke_test.gd` | 92 | 0 | 0 |
| `test_progression.gd` | 113 | 0 | 0 |
| `test_pacing.gd` | 59 | 0 | 0 |
| `test_helper.gd` | 34 | 0 | 0 |
| `test_merchants.gd` | 17 assertions | 0 | 0 |
| `test_encounters.gd` | 206 | 0 | 0 |
| `test_ritual_readability.gd` | 67 | 0 | 0 |

Headless import still exits 1 with the previously recorded `_EDITOR_GET` /
EditorSettings error, plus cursor/Blender-path warnings. There are no new script
parse errors. This is an environment limitation, not a clean import result.
After the final branch-selector text fix, reran smoke and readability; all other
runtime results above are from the same gameplay code before that text-only fix.

Encounter coverage includes real arrival time before speech, objections, decay,
complete versus incomplete routes, fresh retries, intermission inactivity, ordered
victories, duplicate prevention, exact saved rewards, full scene reload, older
save defaults, invalid stage fields, backup recovery and failed-storage notices.
New inscriptions reject stale and maximum-rank purchases. Merchant checks cover
thresholds, overflow, duplicate rewards, targeted bonuses, round reset and a
helper needing nine ordinary phrases. Core tests preserve movement during ritual,
round transitions, migration and failure behavior. The separate 144-node fixture
still passes navigation, transformed picking and node reachability.

The original practical route still converts all 15 at 10.517s (0.483s left).
The practical full Priest route walks 28.8px and completes at 9.133s (1.867s left).
The minimum unlock build reaches only 32.5/240; waiting six seconds even at full
ranks reaches 196/240. Both correctly fail and retry. See [PACING](PACING.md).

### Rendered inspection

Ran `tests/capture_starter.gd` with `--fixed-fps 60` and the rendering display,
writing to `docs/verification`; exit 0, Compatibility / NVIDIA RTX 4080 SUPER.
Inspected actual 1280x800 PNG pixels for merchant speech, walking arrival,
Skeptic/Guard/Zealot/Priest, village completion, the full circle and Priest details.
The figures have distinct equipment/silhouettes. Opponent hints sit above their
figures, leaving the cultist visible. Feet sorting naturally occludes the visitor
behind the market awning during arrival. The Faith branch fills the lower circle;
new glyphs distinguish merchant, trial and faith nodes. Overview identifies the
eight-branch browser without implying a selection. The selected Priest upgrade
shows its conviction benefit and completed rank. Village and ritual both display
the saved map-completion state.

New evidence: `opponent-arrival.png`, `opponent-skeptic.png`, `opponent-guard.png`,
`opponent-zealot.png`, `opponent-priest.png`, `village-complete.png`,
`ritual-map-complete.png`, `ritual-priest-details.png`. Existing captures were
regenerated with the expanded catalog. Captures use funded, isolated test states;
they do not modify the player's save or establish a fresh-save human campaign.

No human playtest, alternate-size acceptance, physical gamepad test or exported
build is claimed. Prices, opponent difficulty and time to finish the map remain
provisional. Later maps are deferred. Original art/reference-transfer limitations
are unchanged. No installation, publishing, remote or export settings changed.

## 2026-10-03 - 72-second local promo video

Created `exports/promo/Small_Following_Promo.mp4`: 72.000 seconds, 1920 x 1080,
30 fps, 2,160 H.264/yuv420p frames and 48 kHz stereo AAC. Size: 23,140,670 bytes.
The edit contains 51 seconds of actual staged Godot footage and 21 seconds of
animated promotional illustrations. Titles distinguish prototype gameplay and
prepared builds from the illustrations. Music is an original locally synthesized
instrumental; there is no narration or sampled commercial recording.

The new [capture script](../tools/promo/capture_promo.gd) ran with the installed
Godot 4.2.2 executable, Compatibility rendering and `--fixed-fps 60`, writing
every second rendered frame. It disables persistence before scene startup.
All 1,530 gameplay PNGs were saved; exit 0, 0 capture assertions failed:

- Opening: 3 recruits / 9 donations through real travel and speaking.
- Ritual: actual opening donations buy Talking I; rank 1 and 3 coins remain.
- Original full core: all 15 listeners recruited in the normal 11-second round.
- Expansion: 24 recruits, including 3 completed by the helper.
- Finale: Priest convinced; 1 second remains when the 10-second take ends.

Prepared later builds use normal purchase validation with temporary setup funds.
The finale starts at encounter stage 3. Those take preparations are outside the
footage; this is an edited showcase, not an uninterrupted fresh-save campaign.
No player progression was read or written, and no production gameplay changed.

Ran `tests/capture_starter.gd` again with the rendering display, writing only to
`exports/promo/starter-check`; exit 0. Its core clear still reports 15 recruits
at 10.517 seconds, with 0.483 seconds left. Inspected its actual starter PNG.
Headless import and behavioral suites were not rerun for this media-only work;
the previously documented editor-import limitation remains unresolved.

Ran the [renderer](../tools/promo/render_promo.py) and
[review extractor](../tools/promo/review_promo.py). FFprobe confirms duration,
frame count, resolution and streams. Full FFmpeg decode exits 0 without errors.
Inspected encoded title, ritual, helper and closing frames at full size, plus
16 sampled frames across every segment. Gameplay retains the full viewport;
promo headlines sit outside it. Measured audio is -15.06 LUFS integrated,
-1.84 dBTP, with no silence interval at least 0.5 seconds below -50 dB.
This is programmatic audio verification, not a subjective listening review.

SHA-256: `80b91125e8a37767714493d3e034c10d911cb02e43dbabbfe20c0b8f6f1cca1e`.
Review PNGs, contact sheet, timeline, audio, encoder logs and stream metadata
remain beside the MP4 in ignored `exports/promo/`. Reproduction instructions
and exact built-in image-generation prompts are in [promo notes](../tools/promo/README.md)
and [art provenance](../tools/promo/art-prompts.json). Source illustrations were
copied without replacing existing project art. Fonts were rasterized locally,
not redistributed. The inspected `D:\VideoGeneration` workspace was unchanged.
No service startup, package installation, publishing or game export occurred.

## Publishing scripts and exports, 2026-10-03

- Added preview/default, production (`-p`), FTP and build-only modes;
  separate Butler channels for HTML5 and Windows, remote preview and status.
- Official standard Godot 4.2.2 and selected matching Web/Windows templates
  installed with explicit user approval; SHA-512 checks match official sums.
- Web and Windows release exports exit 0. Inspected both logs: no errors;
  existing custom-cursor and unused Blender importer warnings remain.
- Standard-editor standalone headless import exits 1 with those warnings,
  without an error diagnostic. Export commands import and export successfully;
  a clean standalone import is not claimed.
- PowerShell publisher fixtures: 22 checks pass. Dry-run creates no deployment;
  tampered/incomplete artifacts and contradictory flags fail. Fake Butler
  verifies channel selection, preview dispatch and failure propagation.
- Standard editor: progression 113/113, smoke 92/92, pacing 59/59. Inspected logs.
- Actual Windows executable: the external progression suite runs against the
  embedded pack and passes 113/113, exit 0, empty stderr. Saves use fixture paths.
- Actual Web export served on localhost with isolation headers renders the
  village in Chrome. Console has mix-rate fallback and Emscripten main-thread
  blocking warnings; no missing-script/resource error was observed.
- Human feel, a complete exported playthrough and browser storage recovery
  remain outstanding. No gameplay or screen code changed in this slice.

## First live deployment, 2026-10-03

- Published the verified build to the configured WSL preview folder and
  `F:/WebHatchery/games/small_following`, then uploaded this game's files to
  `/public_html/games/small_following` through the existing FTP account.
- Live browser game: https://webhatchery.au/games/small_following/ . HTTP 200;
  both isolation headers are present. WASM is `application/wasm`, HTTP 200.
  Windows ZIP is HTTP 200, 26,627,450 bytes. Chrome renders the actual village.
- Butler uploaded version `2026.10.03`: HTML5 build 2056421 / upload 19534645,
  Windows build 2056422 / upload 19534649. Both report processing complete.
- https://kalaith.itch.io/small-following is public (unauthenticated HTTP 200).
  Configured HTML kind, playable HTML5 channel, 1280 x 800 embed, fullscreen
  button and SharedArrayBuffer support. Windows remains a separate download.
  Recorded AI-generated code in itch's disclosure. Existing description,
  donation pricing and release-status setting were preserved.
- Inspected actual itch gameplay and round-complete ritual rendering; clicking
  Begin next round returns to an active village round. Proof:
  [published itch page](verification/published-itch.jpg).
- No shared WebHatchery catalog, Git remote or other game was modified.
  Full exported playthrough and browser storage recovery remain outstanding.

## 2026-10-03 - Background score, footsteps and provisional speech

Reused the promo's original source WAV as a quiet 72-second Ogg music loop.
Added original synthesized footsteps and optional nonsense vowel syllables,
with provenance and reproduction in `assets/audio/README.md`. Original promo
files are unchanged. Movement emits actual travel after collision/bounds;
phrase signals are presentation-only. Music continues across ritual/rounds.
M toggles all sound; V toggles speech. Preferences currently last one session.

Using the installed **Godot 4.2.2 Mono / Compatibility** executable:

| Check | Result |
| --- | --- |
| Headless editor `--import` | Exit 1: existing `_EDITOR_GET` / EditorSettings error, plus cursor and missing Blender-path warnings; audio resources import and load in runtime checks |
| `tests/test_audio.gd`, headless at fixed 60 fps | 27 checks, 0 failures, exit 0 |
| `tests/test_audio.gd`, rendering display at real time | 28 checks, 0 failures, exit 0; includes actual playback and seeking near the score end to verify mixer wrap |
| `tests/smoke_test.gd` | 92 checks, 0 failures, exit 0 |
| `tests/test_progression.gd` | 113 checks, 0 failures, exit 0 |
| `tests/test_pacing.gd` | 59 checks, 0 failures, exit 0 |
| `tests/test_helper.gd` | 34 checks, 0 failures, exit 0 |
| `tests/test_merchants.gd` | 0 failures, exit 0 |
| `tests/test_encounters.gd` | 206 checks, 0 failures, exit 0 |
| `tests/test_ritual_readability.gd` | 67 checks, 0 failures, exit 0 |

All headless suites used `--headless --fixed-fps 60 --path . --script
res://tests/<suite>.gd`; the display run omitted `--headless --fixed-fps 60`.
Latest runtime logs contain no errors or warnings. Initial headless playback
created unconsumed voices in Godot 4.2's Dummy driver and reported resource
leaks at exit. The controller now suppresses playback creation on a headless
display while retaining cue scheduling for tests; the display suite exercises
real AudioStreamPlayers. Outputs are stopped/released when the scene exits.

Audio coverage includes idle, running cadence, blocked movement, intermission
movement, phrase completion, leaving range, dropped burst cues, constant voice
pitch, both mute actions, opponent objections and round entrance reset. All
tests disable progression persistence or use existing isolated save fixtures.
Opening practical routes still recruit three. The original-core practical
full-rank route `[2, 0, 1]` still converts 15 at 10.517 seconds, leaving 0.483
seconds; incomplete/nonoptimal comparisons continue passing.

The source Ogg fully decodes with FFmpeg. Playback state and loop behavior are
verified, but subjective sound quality, mix and human route feel are not.
No screen layout changed, so no new pixel captures were required. No exports,
publishing, installation or normal-player-save writes were performed.

## 2026-10-03 - Settings page and fullscreen

Added the requested sound/display page, four volume sliders, two mute switches,
fullscreen and visible Settings/Back controls. Preferences use their own
validated, staged `user://settings.json` with backup recovery. See
[SETTINGS](SETTINGS.md) for the screen brief, input and storage contract.

Verified with the installed Godot 4.2.2 Mono / Compatibility executable:

| Check | Result |
| --- | --- |
| Headless editor import | Exit 1, existing `_EDITOR_GET` error plus cursor/Blender-path warnings; runtime scripts load successfully |
| `tests/test_settings.gd` headless, fixed 60 fps | 27 checks, 0 failures, exit 0 |
| `tests/test_settings.gd` with rendering display | 29 checks, 0 failures, exit 0; actual fullscreen switch and physical F11 mapping restore windowed mode |
| `tests/test_audio.gd` headless, fixed 60 fps | 27 checks, 0 failures, exit 0 |
| Smoke / progression | 92 / 113 checks, 0 failures, exit 0 |
| Pacing / helper | 59 / 34 checks, 0 failures, exit 0 |
| Merchants / encounters | 0 failures / 206 checks with 0 failures, exit 0 |
| Ritual readability including large fixture | 67 checks, 0 failures, exit 0 |
| `tests/capture_starter.gd` with rendering display, fixed 60 fps | Exit 0; refreshed actual village, ritual and settings PNGs |

Runtime and capture logs were inspected and contain no warnings or errors.
Settings tests cover staged replacement, backup recovery, preserved damaged
and future files, range/type validation, failed-save notice, independent gains,
zero volume, switches and physical-key shortcuts. They also exercise direct
movement, continuing round time, expiry beneath settings, Esc and Tab returns,
blocked hidden next-round input and blocked clicks on an affordable ritual
purchase. Test preferences use a dedicated fixture; the normal progression and
preferences files are never loaded or written by these checks.

Inspected actual [village settings](verification/settings-village.png),
[ritual settings](verification/settings-ritual.png),
[compact settings](verification/settings-compact.png), village HUD and ritual
entry-button PNGs. The page has readable labels and percentage values, and its
Back action remains outside the scrolling content. Base captures are 1280 x
800; the compact output is 1024 x 640 after the window's aspect constraints,
not 1024 x 768 as requested by the fixture. Further aspect ratios remain
unverified. Existing stable captures now include the Settings entry button.

Pacing remains unchanged: the practical original-core route converts all 15
at 10.517 seconds, leaving 0.483 seconds. This is automated route evidence,
not a human playtest. No browser/export fullscreen, storage, gamepad or
subjective audio acceptance is claimed. No publishing or installation occurred.

## 2026-10-03 - Exit Game in settings

Added Exit Game beside Back to game in the fixed settings footer. It attempts
settings/progression saves before `SceneTree.quit()`. Esc still returns to play.
Web builds disable the action and explain closing the browser tab via tooltip;
browser export behavior was not exercised.

`tests/test_exit.gd` clicked the actual button through viewport mouse input,
verified the latest volume and donation values in isolated fixture saves before
the preference debounce elapsed, and observed normal process exit 0 both
headless and on a rendering display. The test has a failure watchdog if shutdown
does not occur. Final logs contain no errors or warnings; no normal saves were
read or written.

All regression suites passed at headless fixed 60 fps: settings 27, audio 27,
smoke 92, progression 113, pacing 59, helper 34, encounters 206 and ritual
readability 67 checks, all with 0 failures and exit 0; merchants also reports
0 failures and exit 0. Headless editor import retains the existing exit-1
`_EDITOR_GET` error and cursor/Blender-path warnings.

Ran `tests/capture_starter.gd` on the rendering display (exit 0), and inspected
the updated village, ritual and compact settings PNGs. Exit Game and Back to
game remain fully visible at 1280 x 800 and the 1024 x 640 compact output.
The capture still converts all 15 listeners at 10.517 seconds, leaving 0.483
seconds. No export, publishing or tool installation occurred.

## 2026-10-03 - Brief numeric recruitment rewards

Removed the permanent merchant payout caption. Successful recruitment now
spawns one outlined number per listener, including recruits earned by the
helper. Opponent victories use the same popup with their stage reward. Digits
size the label naturally; no coin icons or currency text are repeated. The
number rises for 0.9 seconds, fades during the second half and frees itself.
Round resets clear listener popups. The contextual gathering title sits higher
to leave room above listeners for their rewards.

Checks used the installed Godot 4.2.2 Mono console executable, with headless
fixed 60 fps for runtime scripts and a rendering display for
`tests/capture_starter.gd`. All runtime suites exited 0 with no diagnostic
warnings/errors: smoke 92, progression 113, pacing 59, helper 34, merchants 25,
encounters 210 and ritual readability 67 checks, all with 0 failures. Added
coverage checks simultaneous ordinary payouts, upgraded/helper merchant
payouts, duplicate protection, four-digit sizing, rise/fade/removal, reset
cleanup and each opponent's payout. Test saves remain isolated.

Headless editor import still exits 1 with the existing `_EDITOR_GET` error and
cursor/Blender-path warnings. Capture exits 0 with no diagnostics. The practical
original-core capture still completes 15 conversions at 10.517 seconds with
0.483 seconds left; gameplay balance is unchanged.

Inspected actual 1280 x 800 PNGs: [merchant payout](verification/merchant-reward.png),
[ordinary and four-digit rewards](verification/recruitment-rewards.png),
[after the flash](verification/recruitment-rewards-settled.png), and
[Priest reward with idle merchants](verification/village-complete.png).
The numbers 3, 18, 120 and 1250 are readable; listener popups disappear, while
recruited-state checks remain. The 1250 payout is a capture-only fixture and
does not change production rewards. Human play feel and alternate resolutions
were not verified. No publishing or tool installation occurred.

## 2026-10-03 - Correct horizontal arrow movement

The serialized Left/Right bindings incorrectly used Right/End. They now use
Godot's Left/Right codes. `test_key_mapping.gd` sends physical key events and
checks actual player travel for all arrows and WASD in village, ritual and
settings, plus End producing no movement: 25 checks, 0 failures.

The installed 4.2.2 Mono engine ran all headless suites at fixed 60 fps:
smoke 92, progression 113, pacing 59, helper 34, encounters 210, readability 73,
demo completion 46, audio 27 and settings 27 checks, all with 0 failures.
Merchants and the actual exit-button test also passed. Every runtime suite
exited 0 with no diagnostic warnings/errors. Headless import still exits 1
with the existing `_EDITOR_GET` error and cursor/Blender-path warnings.
Test saves were isolated; no rendered or human playtest claim for this fix.
The requested mapping tab is the next implementation slice.

## 2026-10-03 - Saved keyboard mapping tab

Settings now has Sound & display and Key mapping tabs. Nine gameplay, movement,
audio and fullscreen actions have primary/alternate physical key slots. A clear
conflict message preserves existing assignments; Restore default keys and
alternate clearing share the validated settings owner. Esc/Tab stay fixed.
Old preference files keep their sound/display choices and receive corrected
keyboard defaults. Staged writes and backup recovery also validate bindings.

Final checks used the installed Godot 4.2.2 Mono executable:

- `test_key_mapping.gd`: 73 checks, 0 failures both headless and rendered.
  Physical arrow/WASD events drive the actual player through village, ritual
  and settings. Coverage includes remapped movement, alternate assignment and
  clearing, conflicts, modifier/echo rejection, Esc cancellation, Tab escape,
  movement during capture, shortcut/hint updates, isolated scene restart,
  legacy preferences, malformed binding data, backup recovery and save failure.
  The display run clicked the actual tab, binding and Clear controls. Headless
  tests use control signals where Dummy font metrics cannot establish geometry.
- All headless regressions passed at fixed 60 fps: smoke 92, progression 113,
  pacing 59, helper 34, encounters 210, ritual readability 73, demo completion
  46, audio 27 and settings 27 checks; merchants and exit also passed.
- Rendered settings checks: 29 checks, 0 failures, including actual fullscreen
  and windowed transitions. All runtime processes exited 0 without diagnostic
  errors or warnings. All fixture saves were separate from normal user saves.
- Headless editor import still exits 1 with the recorded `_EDITOR_GET` error
  and cursor/Blender-path warnings; it is not a clean import.

Ran the complete `tests/capture_starter.gd` display sequence and its new
`--settings-only` sequence, both exit 0 with no diagnostics. Inspected actual
[key mapping](verification/settings-keys.png),
[scrolled shortcuts](verification/settings-keys-shortcuts.png),
[conflict feedback](verification/settings-keys-conflict.png),
[compact mapping](verification/settings-keys-compact.png),
[sound/display](verification/settings-village.png),
[settings over the ritual](verification/settings-ritual.png), and the refreshed
[ritual overview](verification/ritual-readability-overview.png).
The 1280 x 800 and 1024 x 640 output frames retain reachable scrollable mappings,
feedback and footer controls. The full capture still converts all 15 listeners
at 10.517 seconds, leaving 0.483 seconds. Refreshed general captures carry the
updated movement/shortcut hints.

Human movement feel, physical gamepads, keyboard layouts and exported browser
storage/input remain unverified. No publishing or tool installation occurred.

## 2026-10-03 - Publish audio, settings and ritual update

Published source commit `f8dcb75` as version `2026.10.03-f8dcb75`, including
the background score, footsteps, speech, saved sound/display settings, keyboard
mapping and composed ritual diagram. Release artifacts are retained under
ignored `builds/publish/8962f0edeedc49c9bae139842fa22208`.

- Web and Windows exports completed successfully with standard Godot 4.2.2.
  Export logs contain only the existing cursor/unused Blender warnings.
- Published through `publish.ps1 -SkipBuild -FTP` to local production and
  the existing WebHatchery game directory. The live page returns HTTP 200 with
  both isolation headers. Its downloaded `index.pck` matches the release
  SHA-256 `7321A5DA5C353909200E7203EADC5D1638FE08525A0EBC423AD7998E6A22F68A`.
  The Windows download returns HTTP 200, 27,316,147 bytes. An outer command
  wrapper incorrectly reported failure from an unset native exit code after
  the FTP script succeeded; the live file comparison confirms deployment.
- Butler confirms processing complete for HTML5 build **2057540** and Windows
  build **2057542**, both version `2026.10.03-f8dcb75`. Existing itch uploads
  and page settings were retained.
- All twelve existing headless runtime suites passed with no error/warning
  diagnostics. Publisher fixtures passed 22 checks. Standalone Mono import
  retains its documented exit-1 `_EDITOR_GET` error.
- Display checks passed: audio 28, settings 29 and key mapping 73 checks.
  The capture script exited 0; actual ritual, sound settings and key mapping
  PNGs were inspected. The practical original-core route still completed 15
  conversions in 10.517 seconds, leaving 0.483 seconds. These repeat captures
  were not retained as new release artwork. The exported Windows progression
  suite passed 113 checks using isolated fixtures.

The user requested fewer unnecessary/display checks during publication. After
that correction, verification was limited to live delivery and Butler status;
no additional gameplay tests ran. No new live browser playthrough or subjective
audio acceptance is claimed. No tools, shared catalogs or Git remotes changed.


## 2026-10-03 - Recruits support selected inscriptions

The inspected catalog still has 32 nodes, 35 ranks and 1014 donations in gold
prices. All original catalog fields were compared against the starting commit
and match: IDs, descriptions, effects, prerequisites and layout data. New
per-rank recruit costs total exactly **250** across 22 ranks; the other 13
ranks remain gold-only, including every running rank. [PACING](PACING.md#recruit-assignments---2026-10-03)
records the intentional allocation and provisional balance assumptions.

`available_recruits` is spendable; `total_recruits` retains lifetime recruitment
events, including repeats after audience resets. Listener, helper, merchant and
opponent rewards use the existing authorities, crediting both counters once.
Purchases check both resources and persist one candidate before spending or
granting anything. Schema 3 saves the separate balance. Schema-1/2 saves retain
owned ranks and initialize availability from lifetime events with no retroactive
bill. Completion still derives only from all purchased ranks.

The installed **Godot 4.2.2.stable.mono.official.15073afe3** ran the focused
checks below. Headless runtime scripts used `--fixed-fps 60` except the smoke
run, which used its existing timing path. Logs were inspected, not only exit
codes. All runtime suites exited 0 without warning/error diagnostics.

| Check | Result |
| --- | --- |
| `tests/test_recruit_economy.gd` | 134 checks, 0 failures |
| `tests/test_progression.gd` | 113 checks, 0 failures |
| `tests/smoke_test.gd` | 92 checks, 0 failures |
| `tests/test_pacing.gd` | 59 checks, 0 failures |
| `tests/test_demo_completion.gd` | 46 checks, 0 failures |
| `tests/test_ritual_readability.gd` | 73 checks, 0 failures |
| Hidden `tests/capture_starter.gd --economy-only` | 7 PNGs; exit 0, no diagnostics |
| Headless editor import | Exit 1; existing `_EDITOR_GET` error and cursor/Blender warnings |
| Catalog comparison and `git diff --check` | Pass |

The economy suite covers exact total and running exclusions, malformed cost
data, each missing-resource combination, exact rank prices, stale/max/locked
requests, failed-save rollback of both resources, separate counters, large
reward saturation, old-save compatibility, current save round trips, damaged
backup recovery and preservation of future saves. Scene checks exercise actual
listener events/reset repeats, wallet labels, disabled reasons, gold-only
running and both ranks through the purchase button. A full catalog bought with
exact funds reaches zero available recruits while preserving 279 lifetime
events and lighting the centre; a missing rank still blocks completion with
abundant recruits. Other suites retain round transitions/movement, route
conversion timing, completed-save reload, centre activation/dismissal and
transformed selection with the separate 144-node fixture.

Only affected visual states were captured at 1280 x 800 using Compatibility
OpenGL 3.3 on the installed NVIDIA device, with a hidden offscreen window and
Dummy audio. Actual PNGs were inspected: [village wallet](verification/economy-village.png),
[second-rank cost](verification/economy-rank-ready.png),
[recruits missing](verification/economy-recruits-missing.png),
[both resources missing](verification/economy-both-missing.png),
[gold-only running](verification/economy-running.png),
[helper support details](verification/economy-helper.png) and
[demo message at zero available recruits](verification/economy-demo.png).
Wallet text, costs, supporting-role descriptions and missing-resource reasons
fit the existing UI after minor spacing adjustments. The graph drawing and
ritual artwork are unchanged. The node picker now says "needs resources" rather
than incorrectly describing recruit-only shortages as missing donations.

One initial economy test expected the superseded lifetime-label wording; the
assertion was aligned with the final visible label and the full economy suite
then passed. An initial sandbox runtime attempt crashed before startup; the
headless checks above ran successfully outside that sandbox. Import remains a
separate known engine/editor failure, not a successful validation claim.

Tests disabled ordinary progression/settings persistence or used isolated
`user://test_*` fixtures; player progression was not read or migrated. Existing
purchase-setup fixtures were funded with recruits so their original behavior
checks remain meaningful. Audio/helper/merchant/encounter-specific suites and
the blanket screen capture suite were not rerun for this scoped update.
No visible play window, installation, export, push or publishing was used.
Human purchase-order/grind balance, alternate viewport sizes and play feel
remain unverified; 250 is the requested initial spending target, not proven
balance for a fresh playthrough.

## 2026-10-04 - Touch movement and ritual controls

The inspected starting checkout was clean at `e8cb537`. Tap/click village
destinations now use the camera's inverse canvas transform and the existing
physics movement/collision path. Arrival, obstruction, a tap on the cultist,
keyboard/stick takeover, cancellation and focus loss stop the appropriate
pending movement. Repeated taps retarget. No pathfinding, speed, art, economy,
catalog, save schema or round-duration changes were introduced.

Between-round village buttons reopen the ritual and start another round.
The ritual supports tap-release selection/centre activation, finger panning,
visible + / - zoom and larger navigation/selectors. Settings retain ordinary
Godot touch-to-mouse controls, with taller sliders/buttons/dropdown rows.
Raw graph/village handlers ignore emulated mouse duplicates; UI taps cannot
set village destinations. The web preset suppresses browser gestures within
the game canvas. Normal keyboard, mouse and gamepad mappings remain intact.

The installed Mono Godot 4.2.2 ran the following isolated headless suites.
Logs were inspected for diagnostics, not only exit codes. Restricted-sandbox
engine startup hung; successful runs used the approved unsandboxed execution
path and never opened a play window.

| Check | Result |
| --- | --- |
| `tests/test_touch_movement.gd` | 27 checks, 0 failures |
| `tests/test_ritual_touch.gd` | 25 checks, 0 failures |
| `tests/smoke_test.gd` | 92 checks, 0 failures |
| `tests/test_progression.gd` | 113 checks, 0 failures |
| `tests/test_pacing.gd` | 59 checks, 0 failures |
| `tests/test_ritual_readability.gd` | 73 checks, 0 failures |
| `tests/test_demo_completion.gd` | 46 checks, 0 failures |
| `tests/test_settings.gd` | 27 checks, 0 failures |
| Hidden `tests/capture_starter.gd --touch-only` | 6 PNGs; exit 0, no diagnostics |
| Headless editor import | Exit 1; existing `_EDITOR_GET` error and cursor/Blender warnings |

The input suites exercise native synthetic touch press/drag/release/cancel,
multiple fingers, half-size viewport coordinates plus camera zoom, UI guards,
arrival/collision, keyboard takeover and round resets. Graph coverage includes
transformed picking, outside release, demo activation and the separate 144-node
fixture. These are synthetic checks, not real-device acceptance. Existing
progression tests retain rank/price/stale/max/failed-write guards and migration,
round-trip and recovery coverage. Pacing remains unchanged: practical opening
routes yield three recruits, and the core full-rank garden/well/market route
converts all 15 in **10.517 seconds**, leaving **0.483 seconds**. Human tap-route
reaction and accuracy remain unmeasured.

Actual 1280 x 800 PNGs were inspected from Compatibility rendering on the
installed NVIDIA device, with an offscreen hidden unfocusable window and Dummy
audio: [village destination](verification/touch-village.png),
[between-round buttons](verification/touch-between-rounds.png),
[ritual overview](verification/touch-ritual.png),
[purchase](verification/touch-purchase.png),
[settings](verification/touch-settings.png) and
[demo dismissal](verification/touch-demo.png). The settings tab height initially
overlapped its content; theme tab padding corrected it and fresh captures were
inspected. Native captures establish layout only. Larger landscape displays
remain preferable; the existing composition scales text/targets down on phones.

Initial local Web testing used headless installed Chromium and CDP touch
emulation, with an isolated browser profile and localhost origin. Actual touch
taps moved the cultist, earned 2 recruits/6 donations, opened settings, returned
to the village between rounds, selected graph nodes and bought Words I once.
The browser's IndexedDB save recorded `talk_1: 1`, 0 donations, 1 available
recruit and lifetime 2. Touch drag and zoom buttons visibly transformed the
graph without page scrolling. Final exported-build/alternate-size evidence is
recorded below. Real iOS Safari, physical touch
devices, subjective finger comfort and fresh-save completion remain unverified.

The initial implementation phase did not install tools, push, deploy, change
external trackers or touch ordinary player saves. Publication followed the
user's later explicit WebHatchery authorization, recorded below.

### Final local Web build and tablet review

The direct release Web export is at `builds/touch-web/export/index.html`.
It is a local verification artifact, not a deployed build and not the
publisher's `builds/publish/latest.json` artifact. Serve it with the required
isolation headers; the temporary local helper is
`python builds/touch-web/serve_export.py` (localhost port 8064). The installed
standard Godot 4.2.2 editor and already-installed Web template produced it;
no tool installation or upgrade was needed. Self-contained editor data inside
ignored `exports/tooling/` avoided sandbox writes outside the project.

A repeat export initially omitted the transitive player scene and failed in
the browser. Both existing presets now explicitly include `scenes/player.tscn`
alongside the main scene. The final export contains both, exits 0 and launches
successfully. Its log has no script/parse errors, but still reports the sandbox
root-certificate-store error and headless cursor/Blender warnings; it is not
claimed as a diagnostic-free export. `index.pck` SHA-256:
`49a5398b851eb1e4d4deb2a44e9b909ceada373a45ba4e1bc6729d6c1e7e37b2`.

Installed headless Chrome 154.0.8037.93 used CDP `Emulation.setTouchEmulationEnabled`,
mobile viewport metrics and real browser `Input.dispatchTouchEvent` commands
against localhost, not GDScript event injection. Desktop-size touch at
1280 x 800 and tablet landscape at 1024 x 768 exercised village travel and
recruitment, between-round travel, ritual return/next round, graph selection,
pan, + / - zoom, recenter, branch/node dropdowns, purchase and demo dismissal.
An isolated IndexedDB fixture supplied all ranks except Talking III rank 2:
one touch purchase advanced it from 1 to 2 and spent exactly 18 donations and
8 recruits (509/503 -> 491/495), retaining lifetime 503. Two extra taps on the
maximum-rank control spent nothing. Tapping the lit graph centre opened the
exact demo message; Keep playing dismissed it. No browser scroll or viewport
zoom occurred during these gestures.

Tablet testing caught a real popup issue missed by synthetic graph tests:
an upward-opening node list appeared on finger press and selected the row
beneath the same release. Branch and node OptionButtons now open on release.
Browser press/release inspection confirms the list stays open after the first
tap; a separate tap deliberately selects/focuses Words II. After this fix,
the retained native ritual-touch suite passed 25 checks and readability passed
73, without diagnostics. Actual popup acceptance comes from the browser run.

Touch settings changed master volume to 36%, toggled mute, scrolled to the
speech/display controls and returned to the ritual. Fullscreen was not activated.
Inspected browser evidence: [tablet dropdown](verification/touch-web-tablet.png),
[settings scroll](verification/touch-web-settings.png) and
[demo message](verification/touch-web-demo.png). An additional 844 x 390
landscape-phone frame was inspected locally: the aspect-fitted game is only
624 pixels wide, making 56-unit controls about 27 CSS pixels tall. Functionality
does not establish comfortable phone targets or legibility; tablet/larger
landscape use is preferable. Portrait-phone layout, physical touch devices,
iOS Safari and human play feel remain unverified.

The task's browser and localhost server were stopped after review. The temporary
self-contained editor marker and generated publishing Python cache were removed.

## 2026-10-04 - Publish the touch update to WebHatchery

After the touch update was complete, the user explicitly authorized publishing
Small Following to WebHatchery. The release source is commit `9a2b702`, including
the main touch slice `f57fcfc` and browser-discovered dropdown release fix.
The inspected `publish.ps1 -FTP -DryRun` selected only
`F:/WebHatchery/games/small_following` and
`/public_html/games/small_following`. The existing workflow overwrites known
game files, performs no recursive deletion and uploads `index.html` last.
Existing authorized credentials were used without displaying them.

`publish.ps1 -BuildOnly` generated manifest-validated release
`3acac494ee334faf848f5f4990b68914`. Both Web and Windows exports exited 0 with
no error/script-error diagnostics; only the existing headless cursor and unused
Blender warnings remain. This standard-editor run used the normal approved
execution environment and avoided the restricted sandbox certificate-store
error from the earlier direct local export. Earlier passed gameplay/pacing
validation was reused. The existing workflow includes the Windows download
beside the Web game; no itch.io publication was performed.

`publish.ps1 -SkipBuild -FTP` then completed with exit 0. Public game:
[Small Following](https://webhatchery.au/games/small_following/).
Direct HTTP verification returned 200 for the launcher, JavaScript, game pack,
WASM and Windows ZIP. SHA-256 comparisons match the release manifest for
`index.html`, `index.js` and `index.pck`; the latter is 984,944 bytes with hash
`dc04e9642af2e08000cacf24d07841e668f834f161f177b2d1e2aa5f2fffda9f`.
WASM is served as `application/wasm`; the ZIP is 27,320,112 bytes. The launcher
returns `Cross-Origin-Opener-Policy: same-origin`,
`Cross-Origin-Embedder-Policy: require-corp` and cache-revalidation directives.
The web crawler tool could not open this game URL; the direct HTTP comparisons
and actual browser run are the verification authorities here.

Brief **live** touch review used a new isolated headless Chrome 154.0.8037.93
profile at emulated 1024 x 768 with five touch points. The restricted launch
was denied network access before loading the site; the authorized hidden
browser succeeded without firewall, TLS or network configuration changes.
The cold WASM load exceeded the initial 30-second observation window; the
same page finished loading normally. Initial resumed screenshots were already
in the ritual and were not counted as movement evidence.

Actual public-game touch selected Running I, zoomed with +, panned with a
finger, recentered and began the next round. A fresh next-round tap followed
immediately by a Garden-ground tap then moved the cultist from the entrance:
the [inspected live frame](verification/touch-live.png) shows Round 3,
9.5 seconds remaining and **Speaking with Garden club**. No live save fixture
was injected. Browser state confirmed `crossOriginIsolated=true`, canvas
`touch-action: none`, zero page scroll, viewport scale 1 and no fullscreen.
There were no game script errors; normal audio-autoplay, 44,100-Hz mix-rate
fallback and Emscripten main-thread warnings were observed. The browser was
stopped after this bounded smoke check.

No push, itch.io upload, unrelated-site changes or external tracker writes
were performed. The touch update is now live on WebHatchery. Small-phone
legibility/targets and real iOS Safari/physical-device acceptance remain the
limits already recorded above; this was Chromium touch emulation, not a
physical-device playtest.

## 2026-10-04 - Future-level and mixed-audience planning

Added [FUTURE_LEVELS](FUTURE_LEVELS.md), a scoped proposal following the GDD
template. It covers six candidate settings, a five-listener example with two
independent audience requirements, eligibility/overflow/helper rules, proposed
area travel and save ownership, and bounded future implementation slices.
Names, order, unlocks, economy and carry-over remain provisional. The original
three-group pacing benchmark is retained; no new area or unlock is shipped.

Checked the implemented baseline against `scripts/gathering.gd`, `main.gd`,
`helper.gd` and `progression.gd`: audience type/threshold/reward are currently
shared by each group, save schema is 3, and circle completion currently checks
the single catalog independently of Priest victory. These are documented as
extension points rather than existing mixed-audience or travel features.

Documentation review checked local Markdown link destinations, balanced code
fences, final newlines, and consistency with current progression and movement
invariants. `git diff --check` passed; Git emitted its existing LF-to-CRLF
working-copy notices. README and the development map link to the proposal;
GAME_DESIGN records the planning request under open decisions. TODO remains
outstanding-only and milestone completion status is unchanged.

An independent read-only design review identified two ambiguities, now clarified:
portable stat/helper benefits are separate from area-specific group/encounter
unlocks, and destination setup precedes the durable travel commit, with explicit
recovery required for any remaining activation failure.

This is documentation-only work. Godot import, runtime suites, rendered
captures, exports and human playtests were not rerun. No numerical route,
pixel, play-feel or new-platform result is claimed.

## 2026-10-04 - Bellmarket, separate circle and password title entry

Implemented the requested second level locally. Bellmarket has five gatherings
with 25 listeners (18 ordinary, four guild traders, three patrons), independent
introductions and a separate fifteen-node circle. Five equal-price roots lead
to speed, frequency, conviction and two specialist donation paths. Bramblewick
retains its original 32 nodes/35 ranks. The new project entry is
`scenes/title.tscn`; `scenes/main.tscn` remains the direct gameplay scene used by
isolated fixtures. The exact title password `PLZKTKS` reveals both levels.

Normal travel uses the completed Bramblewick circle; the Priest remains a
separate objective. Travel and password access save transactionally in schema
4. Old schema-1/2/3 saves preserve their balances/history/ranks and default to
Bramblewick. Market purchases remain local, while earlier stats/helper carry
forward. No normal player save was loaded or altered by verification.

### Behavioral checks

Used the installed Godot 4.2.2 Mono console executable, GDScript and
Compatibility renderer. Final completed runs below exited zero with no logged
script/runtime errors. Headless commands used `--headless --fixed-fps 60
--path . --script res://tests/<suite>.gd` (tests with their own shutdown still
verify their explicit completion marker).

| Suite | Result |
| --- | --- |
| `smoke_test.gd` | 92 checks, 0 failures |
| `test_progression.gd` | 113 checks, 0 failures |
| `test_recruit_economy.gd` | 134 checks, 0 failures |
| `test_pacing.gd` | 59 checks, 0 failures |
| `test_areas.gd` | 38 checks, 0 failures |
| `test_market_progression.gd` | 54 checks, 0 failures |
| `test_mixed_audiences.gd` | 36 checks, 0 failures |
| `test_market_pacing.gd` | 23 checks, 0 failures |
| `test_market_flow.gd` | 27 checks, 0 failures |
| `test_market_ritual.gd` | 50 checks, 0 failures |
| `test_title_screen.gd` | 15 headless / 17 display checks, 0 failures |
| `test_helper.gd` | 34 checks, 0 failures |
| `test_merchants.gd` | Passed, 0 failures |
| `test_encounters.gd` | 210 checks, 0 failures |
| `test_ritual_readability.gd` | 73 checks, 0 failures |
| `test_ritual_touch.gd` | 25 checks, 0 failures |
| `test_demo_completion.gd` | 46 checks, 0 failures |
| `test_touch_movement.gd` | 27 checks, 0 failures |
| `test_audio.gd` | 27 checks, 0 failures |
| `test_settings.gd` | 27 checks, 0 failures |
| `test_key_mapping.gd` | 73 checks, 0 failures |
| `test_exit.gd` | Actual exit button flushed isolated preferences/progression and shut down |

Coverage includes area membership, five affordable roots at 12 donations,
independent paths, per-role rewards, scope on return, max/stale requests,
both-resource costs, failed-save rollback, old migrations and recovery.
Mixed audiences skip locked slots, conserve overflow across different
thresholds, prevent new banked speech against locks, and share helper
eligibility. All 25 market helper stand cells are reachable.

The flow test types the password through a real LineEdit with its characters
remapped to fullscreen/next-round/buy/audio actions. Enter submits without
starting a hidden round or changing audio. It exercises actual destination and
return buttons, local-circle replacement, movement during intermission/ritual,
nearest locked-only group fallback and failed travel retaining current actors.
Failed destination actions dismiss the modal to expose the existing save-error
message; this was covered by an additional integration regression.
The separate 144-node fixture continues to pass transformed selection and
navigation checks. The generic final-area notice is tested independently of
Bramblewick's new travel modal.

An initial pacing invocation had a test-runner frame limit that stopped it
before completion; the full rerun without that limit passed all 59 checks.
Initial schema-count expectations, remapped shortcut hints, a typed local in
market drawing and a rendered numeric format were corrected and rerun. Final
capture and suite logs were inspected, rather than inferring success from exit
codes alone.

### Route evidence and limits

The original practical garden/well/market core route still converts all 15 at
10.517 seconds with 0.483 seconds remaining; the unchanged opening earns three
recruits. Market movement/conversation measurements are recorded in
[PACING](PACING.md). Fresh password entry earns three ordinary recruits and 12
donations. Carried-build guild and patron routes earn 114 and 157 donations.
Full market ranks finish all 25 at 5.45 seconds (5.55 seconds remaining), while
a deliberately hesitant crossed route finishes 21. This is generous tuning,
not evidence of a tightly balanced market or human play-feel acceptance.

### Actual rendered review

Ran `tests/capture_starter.gd` with a rendering display, fixed 60 FPS, a hidden
window and disabled fixture audio, first with the full existing sequence and
then with `--market-only`. Both final captures exited zero with clean logs on
the installed NVIDIA OpenGL Compatibility renderer. The full sequence also
printed 15 conversions at 10.517 seconds with 0.483 seconds remaining.

Inspected actual title, level selection, market overview/mixed feedback, upgrade
overview/selection/completion, travel modal and compact title/ritual images.
Also inspected the refreshed compact settings footer and original village full
clear. Market role locks, threshold/reward text and required introductions are
visible without hover. The five-petal purple/gold circle differs from the
village while retaining real node geometry, pan/zoom and fixed details. The
travel modal now fits entirely in its viewport after correcting its container
layout. The settings footer provides a return to the title.

- [Title and password selection](verification/title-level-select.png)
- [Compact title](verification/title-compact.png)
- [Market square](verification/market-overview.png)
- [Mixed audience and lock explanations](verification/market-mixed-listeners.png)
- [Five-path market ritual](verification/market-ritual.png)
- [Patron introduction details](verification/market-patron-upgrade.png)
- [Compact market ritual](verification/market-ritual-compact.png)
- [Complete market circle](verification/market-complete-circle.png)
- [Patron conversation](verification/market-patrons.png)
- [Completed village destination](verification/village-market-destination.png)
- [Visible failed-travel save notice](verification/village-travel-save-error.png)

The captures cover 1280 x 800 and 1024 x 768 windows; they do not establish
small-phone, real-touch-device or physical-gamepad acceptance. Distant world
labels can pass beneath the compact HUD while the player moves; nearby
contextual audience details remain the primary explanation.

The required headless `--import` was rerun. It exits 1 with the previously
recorded `_EDITOR_GET` condition, plus headless custom-cursor and unconfigured
Blender-path warnings. This environment limitation remains separate from
passing runtime checks and rendered pixels. No tools were installed, no export
or publication was performed, and human balance/art-direction review remains
outstanding.

## 2026-10-05 - Bellmarket rebalance and expanded circle

Bellmarket now has thirty single-rank nodes across its five existing paths,
with 14,100 total donation cost and 183 assigned recruits. The original fifteen
market IDs and their effects remain; their new prices apply only to future
purchases. The fifteen added ranks start unowned, and schema 4 remains
unchanged. The market campaign uses every Bramblewick rank, actual eleven-second
rounds, real movement/conversation, the helper and normal validated purchases.
Its two fixed purchase orders complete in 35-46 rounds from zero or 1000
carried donations; exact route and wallet results are in
[PACING](PACING.md#bellmarket-rebalance---2026-10-04). This is scripted evidence,
not a human economy or grind assessment.

Installed Godot 4.2.2 Mono, headless fixed 60 fps; saves and shared fixtures are
isolated and the suites ran sequentially:

| Suite | Result |
| --- | --- |
| `smoke_test.gd` | 92 checks, 0 failures |
| `test_progression.gd` | 113 checks, 0 failures |
| `test_pacing.gd` | 59 checks, 0 failures |
| `test_helper.gd` | 34 checks, 0 failures |
| `test_merchants.gd` | Passed, 0 failures |
| `test_encounters.gd` | 210 checks, 0 failures |
| `test_ritual_readability.gd` | 73 checks, 0 failures |
| `test_demo_completion.gd` | 46 checks, 0 failures |
| `test_audio.gd` | 27 checks, 0 failures |
| `test_settings.gd` | 27 checks, 0 failures |
| `test_key_mapping.gd` | 73 checks, 0 failures |
| `test_exit.gd` | Actual exit action flushed isolated state and shut down |
| `test_areas.gd` | 44 checks, 0 failures |
| `test_market_progression.gd` | 94 checks, 0 failures |
| `test_market_pacing.gd` | 31 checks, 0 failures |
| `test_market_campaign.gd` | 26 checks, 0 failures |
| `test_market_flow.gd` | 27 checks, 0 failures |
| `test_title_screen.gd` | 15 headless checks, 0 failures |
| `test_market_ritual.gd` | 110 checks, 0 failures |

The campaign balances both wallets, records lifetime recruitment, verifies
normal purchase validation and compares independent branch choices. Prior
schema-4 market saves keep every original rank and balance; the new ranks begin
unowned. Expanded graph checks cover all thirty nodes, branch focus, pan/zoom
hit testing and a 60-pixel minimum node separation. Headless suites reported no
script/runtime errors.

The required editor import exited 1 again with the recorded `_EDITOR_GET`
condition and the cursor/Blender-path warnings. This is separate from the
passing runtime results.

Ran `tests/capture_starter.gd --market-only` with a rendering display, fixed
60 fps and Godot's NVIDIA Compatibility renderer. Inspected the actual title
level selector, market overview and mixed-audience view, both full and compact
market circles, the selected patron upgrade, the completed 30-node circle and
the village-to-market travel panel. The five-petal composition contains all
thirty real nodes; the selected detail shows its current 120-donation root
price. These captures verify rendered output at the tested 1280 x 800 and
1024 x 768 layouts, not small-phone use, human navigation or balance feel.

No tool was installed and no export, publish or remote change was made. Human
review of market route feel, the 35-46-round purchase curve and possible late
grinding remains outstanding in [TODO](../TODO.md).

## 2026-10-06 - Restore the title scene in published exports

The configured startup scene is `res://scenes/title.tscn`, but the Web and
Windows export presets explicitly listed only `main.tscn` and `player.tscn`.
That left the exported project without its startup scene and produced only the
project's green clear color. Both presets now include the title scene.

- `publish.ps1 -BuildOnly` completed build
  `fd66081ef4994248a365efd6d180f2ff`. Its Web export log contains the compiled
  title scene and ends at `savepack: end`; only the existing cursor and
  Blender-path warnings were emitted.
- `publish.ps1 -SkipBuild -FTP` deployed WebHatchery production and reported
  that Project Roost recorded the production deployment. A direct HTTP fetch
  of `https://webhatchery.au/games/small_following/index.pck` returned 200 and
  its SHA-256 matched this build. The `webhatchery.com.au` hostname did not
  resolve from this executor during verification.
- `publish-itch.ps1` uploaded both channels. `publish-itch.ps1 -Status`
  reported completed HTML5 build 2074386 and Windows build 2074387.
- The local headless Chrome captures stayed at Godot's asset-loading
  indicator, so this deployment record does not claim browser pixel
  verification. The export and live-pack checks confirm the title scene is
  included and delivered; a normal browser reload remains the visual check.

This was an export-configuration fix; gameplay test suites were not rerun.
