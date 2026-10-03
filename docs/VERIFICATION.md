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
