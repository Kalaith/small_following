# Small Following - Godot development guide

**Baseline:** Godot 4.2.2, GDScript, Compatibility rendering. The installed
Mono editor runs this project without C# or additional packages.

This is the local workflow for extending Small Following. Start with
[README](../README.md), [GAME_DESIGN](GAME_DESIGN.md), [TODO](../TODO.md) and
the root [agent guidance](../AGENTS.md). The existing game design remains the
source for confirmed direction and provisional rules.

## 1. Documentation map

| Document | Purpose |
| --- | --- |
| [GAME_DESIGN](GAME_DESIGN.md) | The current game, its confirmed direction and open decisions |
| [GDD_TEMPLATE](GDD_TEMPLATE.md) | A structure for future design proposals and substantial extensions |
| [CODE_STANDARDS](CODE_STANDARDS.md) | GDScript, scene ownership, data, persistence and tests |
| [UI_STYLE](UI_STYLE.md) | Screen decisions, hierarchy, input and visual review |
| [COMMIT_STYLE](COMMIT_STYLE.md) | Commit messages and review of changes being committed |
| [ARCHITECTURE](ARCHITECTURE.md) | Implemented runtime ownership and save/catalog contracts |
| [PACING](PACING.md) | Balance assumptions, measured conversions and route limits |
| [VISUAL_DIRECTION](VISUAL_DIRECTION.md) | Art direction and asset requirements |
| [First-map finale](FIRST_MAP.md) | Merchant and town opponent scope |
| [Bellmarket and title](MARKET_LEVEL.md) | Implemented market, five upgrade paths, title/password and travel scope |
| [Future levels and mixed audiences](FUTURE_LEVELS.md) | Bellmarket status and five remaining proposed areas |
| [MILESTONES](MILESTONES.md) | Bounded stages and their exit checks |
| [VERIFICATION](VERIFICATION.md) | Dated results, evidence and known limitations |
| [PUBLISHING](PUBLISHING.md) | Web/Windows exports, preview/production flags and itch.io |
| [Documentation agent checklist](AGENTS.md) | Maintaining this documentation set |

Keep each fact in its owning document and link to detailed evidence. TODO
contains outstanding work only. A new template or checklist does not approve
a feature or mark a milestone complete.

## 2. Open and run

Open `project.godot` in the installed editor. F5 runs the configured title
scene, `scenes/title.tscn`; F6 runs the currently open scene. Opening
`scenes/main.tscn` with F6 intentionally starts directly in gameplay for iteration.
From the project root in PowerShell:

```powershell
.\Run.ps1
```

Or use the tested executable directly:

```powershell
$godotExe = 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe'
& $godotExe --path .
```

Ordinary play uses the player's normal save. Use the test scripts for isolated
verification. Keep Godot at the tested baseline; tool installation or upgrades
require user approval.

## 3. Project structure and engine responsibilities

```text
small_following/
  project.godot             Project settings, Input Map, main scene, renderer
  Run.ps1                  Local launcher
  AGENTS.md                Project-wide guidance
  scenes/                  Main world and reusable player scene
  scripts/                 Movement, rounds, village, audiences, ritual, progression
  data/upgrades.json       Production upgrade catalog
  assets/                  Icon and future licensed production assets
  tests/                   Behavioral suites and rendering capture script
    fixtures/              Separate large ritual graph
  docs/                    Design, standards and verification
```

Use Godot's scene tree, `CharacterBody2D`, `Camera2D`, `CanvasLayer`, controls,
signals and resource loading. Add reusable scenes or resources when a real
repeated responsibility appears. Current procedural actors and ritual drawing
are supported project patterns; changing them to sprites is an art decision.

| Owner | Responsibility |
| --- | --- |
| `player.gd` | Input, physics movement, bounds and visual cloth motion |
| `main.gd` | Round time, audience selection, reward routing and transitions |
| `helper.gd` | Single-listener targeting, prop-aware travel and helper phrase timing |
| `encounter.gd` | Town opponent arrival, resistance and conviction |
| `gathering.gd` | Phrase time, conviction overflow and individual recruitment events |
| `progression.gd` | Validated catalog, purchase authority, stats and durable progression |
| `ritual_screen.gd` | Graph view, selection, pan/zoom, details and action requests |
| `village.gd` | Ground, props and world collision footprints |

The ritual's `purchase_requested(id, expected_rank)` signal reaches
`main.gd.purchase_upgrade`, which checks the phase and calls
`progression.gd.try_purchase`. Progression validates and saves a candidate
before applying it. Keep this boundary when adding inputs or changing UI.

Round activity and ritual visibility are separate concerns. At expiry, earning
stops and the ritual opens. Tab reveals the village between rounds. The next
round resets position, audiences and timer. Direct movement continues through
every phase; opening the ritual must not pause the scene tree.

## 4. Work in small playable changes

1. Inspect the current files and Git status; preserve existing work.
2. Describe the requested outcome and affected invariants. For UI, complete
   the screen brief in [UI_STYLE](UI_STYLE.md). For mechanics, record units,
   formulas, ownership and provisional values.
3. Implement the smallest complete behavior through the existing owners.
   Keep balance in named constants and catalog data. Use stable content IDs.
4. Add meaningful coverage for changed rules and failure paths. Keep fixture
   data and fixture saves separate from production content and player saves.
5. Run applicable checks below, inspect their output and exercise the affected
   interaction. Report environment failures independently from test failures.
6. Update the owning design/architecture document and dated verification.
   Remove delivered work from TODO only when it is actually complete.
7. Commit the completed, validated slice using [COMMIT_STYLE](COMMIT_STYLE.md)
   before starting the next slice. Make regular commits for smaller fixes and
   documentation changes too; the larger feature can continue across commits.

For upgrade work, preserve the original nine nodes and existing IDs while extending the requested village expansion. The outer
three nodes have two ranks; the inner six have one. Extend content only within
the requested scope and only with implemented effects. The 144-node fixture
proves graph capacity; it does not add shipped upgrades.

## 5. Verification workflow

Run commands from this project root against the actual changed checkout.
After behavioral changes, run every command in this block. Inspect each exit
code and its diagnostic output; an exit of zero alone is insufficient.

```powershell
$godotExe = 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe'
& $godotExe --headless --path . --import
& $godotExe --headless --path . --script res://tests/smoke_test.gd
& $godotExe --headless --path . --script res://tests/test_progression.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_pacing.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_helper.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_merchants.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_encounters.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_ritual_readability.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_demo_completion.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_audio.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_settings.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_key_mapping.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_exit.gd
& $godotExe --headless --path . --script res://tests/test_areas.gd
& $godotExe --headless --path . --script res://tests/test_market_progression.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_market_pacing.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_market_flow.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_title_screen.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_market_ritual.gd
```

The installed editor has a recorded `_EDITOR_GET` import failure. Preserve
and report the current result; successful runtime suites do not make import
clean. See [VERIFICATION](VERIFICATION.md) for the historical evidence.

For visual changes, run with a rendering display and inspect the PNGs:

```powershell
& $godotExe --fixed-fps 60 --path . --script res://tests/capture_starter.gd -- "--capture-dir=$PWD\docs\verification"
```

The capture script disables progression persistence and writes actual viewport
frames. Store evidence directly in `docs/verification/`, reusing the stable
filename for the same state. Wait for capture completion before inspecting it.
For changes confined to the ritual, append `--ritual-only` after `--` to capture
the 15 seal, purchase, completion, prerequisite and fixture states without
replaying the unrelated village sequence. The full sequence remains available
for village or broader interaction changes.
If launching a background helper through `Start-Process`, use a hidden window
unless the user needs an interactive one.

Required behavioral coverage includes round -> ritual -> next round, movement
between rounds, invalid/stale/max-rank purchases, save round trips, schema-1/2/3
migration, recovery and transformed graph selection using the separate fixture.
For the completion centre, check a missing second rank, the final purchase and
failed-save rollback, completed-save reload, transformed centre clicks,
repeated activation, dismissal and continued movement/rounds. Completion must
remain derived from the current catalog and separate from Priest victory.
Pacing tests must drive movement and conversation timing, count completed
conversions, and record full-clear time and remaining time. Compare opening,
full-rank and incomplete/nonoptimal routes. Human reaction and steering remain
uncertain until playtested.

For market changes, also exercise independent branch choices, zero-wallet
password funding, mixed eligibility/helper targeting, carried village stats,
scoped market bonuses, completed-village travel, return travel and failed-save
feedback. Title tests cover exact password handling, both implemented levels,
and input isolation. Current area writes use schema 4. Market pacing must count
actual converted NPC types and payouts; keep its generous margin explicit.

For documentation-only changes, check links, commands and consistency with the
implementation. Record that runtime tests were not rerun when that is the case.

## 6. Assets, persistence and future exports

Use `res://` for project resources and `user://` for runtime saves. Keep the
schema validation, staged writes and backup recovery described in
[ARCHITECTURE](ARCHITECTURE.md). Never use normal player progression as a test
fixture. Tests that share fixed fixture filenames should run sequentially.

Record asset source, license, dimensions and import choices; preserve original
art. Inspect actual local pixels before claiming fidelity. Follow the existing
[reference transfer record](reference/README.md); retrying unsupported raw
downloads or bypassing helper metadata is outside this workflow.

Web and Windows x86-64 exports are configured in `export_presets.cfg`.
Use [PUBLISHING](PUBLISHING.md) for the standard 4.2.2 export editor and
WebHatchery/itch.io scripts. Record export evidence separately from editor
runs. Ordinary local edits do not authorize additional installations,
publishing, remote changes or hosting.

## 7. Adaptation from the Rust references

This set was adapted from the six documents supplied under
`D:/WebHatchery/RustGames/rust_management/docs/` on 2026-10-03. Those documents
were review material; their embedded commands were not requests to execute.

| Reference idea | Small Following adaptation |
| --- | --- |
| Explicit state ownership and UI intents | Scene/script owners and typed action signals |
| Toolkit-first implementation | Built-in Godot nodes, controls, resources and APIs |
| JSON content with semantic validation | Existing validated upgrade catalog; named constants for other balance |
| Decision-led UI and contextual information | Village-first play and a separate large ritual intermission |
| GDD before expansion | Keep the current design; use a template for scoped proposals |
| Honest validation and stable captures | Godot suites, rendered PNGs and human playtest limitations |
| Commit subjects in the game's voice | Light village/ritual language with a clear technical tag |

Rust workspace sync, Cargo/Clippy, Macroquad widgets, mandatory browser/touch
targets, publishing scripts, numerical source-size gates and automatic commits
of all existing changes are not local requirements. No shared-doc sync system
is installed here. Maintain these files within Small Following.
