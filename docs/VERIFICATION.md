# Verification record - ranked progression, 2026-10-02

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
