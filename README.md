# Small Following

A small Godot prototype for a cute incremental game where **you are the robed cultist**: walk between village gatherings, speak, recruit and earn donations. Short rounds lead into a purple ritual-circle upgrade screen with nine working nodes, twelve purchasable ranks and local progression saves. Art is procedural placeholder geometry; this is not a finished game.

## Run

Tested engine: **Godot 4.2.2.stable.mono.official.15073afe3**, using **GDScript** and **Compatibility** rendering. The Mono editor is installed here; the project contains no C# and requires no package installation.

Import `project.godot` in Godot, open `scenes/main.tscn`, and press **F6** (current scene) or **F5** (project). Or run directly in PowerShell:

```powershell
& 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe' --path 'D:\WebHatchery\godot\small_following'
```

From the project folder, `.\Run.ps1` also launches the game; pass `-GodotExe '<installed executable>'` to use another local executable. On another machine, the equivalent is `godot --path <project-folder>`. Only the installed 4.2.2 build is the verified baseline. No software was installed.

| Action | Controls |
| --- | --- |
| Move the cultist | WASD / arrows / gamepad left stick |
| Speak | Stay within range of a gathering |
| Select an upgrade | Click its circle in the ritual |
| Pan the ritual | Left-drag empty graph space, or middle-drag |
| Zoom / restore view | Mouse wheel / Recenter button |
| Buy selected upgrade | U / Inscribe button / gamepad X (left face button) |
| Return to village / reopen ritual | Tab between rounds, or the ritual's village button |
| Start next round | Enter / next-round button / gamepad A (bottom face button) |

Movement remains active during the ritual; Tab reveals the village between rounds. A new round returns the cultist to the starting entrance. Gamepad movement/action mappings exist but were not physically tested; graph selection and navigation currently require a mouse.

## Current loop

- A 1560 x 1100 village with real actors, paths, props, collision footprints and camera.
- A directly movable purple cultist with normalized diagonal speed, world bounds and visibly trailing cloth.
- Three nonblocking gatherings of five listeners each, with local speech feedback and recruitment/donation events.
- **Provisional 11-second rounds**, tuned toward roughly three opening conversions through travel and conversation time. There is no three-recruit cap; [pacing evidence and assumptions](docs/PACING.md) explain the limit and upgraded comparisons.
- A large purple occult upgrade circle: the same nine nodes across three rings/branches, with a second rank on each outermost node. Rank pips, current-to-next details, prerequisite connections and pan/zoom keep progression readable.
- Three distinct upgrade effects: initial talking ranks each add 20% of base phrase frequency, persuasion ranks add 0.5 conviction per phrase, and running ranks add 15% of base movement speed. The outer talking node's second rank adds 30% of base frequency. Initial node prices remain 6, 9 and 12 donations per branch; each outer node's second rank costs 18.
- Full ranks produce 1.9 phrases/second, 3 conviction/phrase and 288 pixels/second movement. The balance target is all 15 listeners across the three groups with a small positive margin on a competent route inside the unchanged 11-second round; [route evidence](docs/PACING.md) records actual timings and limitations.
- Versioned local progression retaining currency, purchased ranks, the recruitment-event total and round number. Existing single-purchase saves keep each old purchase as rank 1.

Base movement is 180 pixels/second. Speech within 105 pixels produces one phrase/second; each phrase adds one conviction, and three conviction recruits a listener for three donations. Extra conviction carries toward the next listener. Partial speech stays with its gathering until round end. A typical three-recruit opening earns nine donations, enough for one first-tier upgrade.

The six inner nodes each have one rank. The three outer nodes each have two; the entire catalog costs 135 donations, including 54 for the three added ranks. A previous node needs rank 1 to unlock its successor. One purchase action buys one rank, and stale selection requests cannot silently buy another. Two fully converted groups earn 30 donations, enough for a new 18-donation late rank; improving the route and speaking stats remains useful before a full village clear.

All audiences reset each round. The cumulative recruited total counts **recruitment events**, including the same villagers on later rounds; it is not a population of unique permanent followers. Restarting preserves progression but begins a fresh timer and audience state. No offline rewards or partial-round continuation are implemented.

The real catalog is `data/upgrades.json`. A separate **144-node validation fixture** exercises graph capacity and navigation; it is not additional purchasable game content. Larger towns, helpers, magic, audio, production assets and an exported release remain future work.

## Local saves

Progression is written to Godot's `user://progression.json`, normally beneath `%APPDATA%\Godot\app_userdata\Small Following` on Windows. Schema 2 stores purchased ranks; valid schema-1 saves migrate each existing purchase to rank 1 without changing coins, recruitment events or round number. Writes use a verified temporary file and prior-save backup. Invalid saves are validated/recovered with a visible notice; newer unsupported saves are preserved. A failed purchase save grants nothing and spends nothing. If saving earned donations fails, they remain in memory but may be lost on exit.

See [save fields and recovery rules](docs/ARCHITECTURE.md#local-progression-and-recovery) before changing IDs or schema. Test scripts isolate their saves from ordinary player progress. Runtime saves do not belong in this repository.

## Design and handoff

- [Godot development guide and documentation map](docs/GAME_DEVELOPMENT_GUIDE.md)
- [GDScript and scene standards](docs/CODE_STANDARDS.md)
- [UI composition and review](docs/UI_STYLE.md)
- [Design proposal template](docs/GDD_TEMPLATE.md)
- [Commit message style](docs/COMMIT_STYLE.md)
- [Confirmed direction and provisional rules](docs/GAME_DESIGN.md)
- [Opening-round timing and route evidence](docs/PACING.md)
- [Visual direction and future asset needs](docs/VISUAL_DIRECTION.md)
- [Staged milestones](docs/MILESTONES.md)
- [Outstanding work only](TODO.md)
- [Architecture, upgrade data and save recovery](docs/ARCHITECTURE.md)
- [Guidance for future agents](AGENTS.md)
- [Exact verification results and environment limitations](docs/VERIFICATION.md)

## Actual rendered prototype

These captures come from the running scene with deterministic test setup; they are not supplied mockups or painted backgrounds.

![Actual village viewport with procedural placeholder art](docs/verification/starter-runtime.png)

![Actual purple ritual upgrade screen](docs/verification/starter-summary.png)

Additional evidence: [moving robe](docs/verification/starter-moving.png), [purchased node](docs/verification/ritual-purchased.png), [available second rank](docs/verification/ritual-rank-available.png), [maximum rank](docs/verification/ritual-rank-max.png), [full village conversion](docs/verification/village-full-clear.png), [next round](docs/verification/starter-next-round.png), and the test-only [144-node graph](docs/verification/ritual-144-fixture.png) and [focused distant node](docs/verification/ritual-fixture-focus.png). The large fixture demonstrates navigation; its nodes are not shipped upgrades.

## Supplied references: local transfer blocked

The two original village mockups remain unavailable locally because the supported Windows Library transfer helper fails at `os.setxattr`. Their pixels were not inspected on this executor. Intended destinations remain:

- `docs/reference/cultist-idle-village-closeup.png`
- `docs/reference/cultist-idle-village-overview.png`

Two new ritual-circle references were inspected by the parent agent in the cloud; this Windows implementation received their visual descriptions. Their originals are absent locally and their canonical filenames are unresolved here. The ritual is independently authored from those descriptions in the requested violet/lilac palette; no local pixel matching is claimed. [Reference IDs, provenance and recovery](docs/reference/README.md).

## Checks

From the project folder:

```powershell
$godotExe = 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe'
& $godotExe --headless --path . --import
& $godotExe --headless --path . --script res://tests/test_progression.gd
& $godotExe --headless --path . --script res://tests/smoke_test.gd
& $godotExe --headless --fixed-fps 60 --path . --script res://tests/test_pacing.gd
& $godotExe --fixed-fps 60 --path . --script res://tests/capture_starter.gd -- "--capture-dir=$PWD\docs\verification"
```

The tests cover movement/cloth/collision, speech timing, round transitions, distinct rank effects, purchase guards, old-save migration, local-save validation/recovery and transformed graph selection. Route tests drive the real scene at a fixed simulated timestep and count complete individual conversions, including full-rank completion time and remaining margin. Captures require a rendering display; headless tests cannot verify pixels. Human movement feel, pacing and large-graph navigation still need playtesting.

Exact latest check counts, rendered inspection results and commands are recorded in [VERIFICATION.md](docs/VERIFICATION.md). The installed Mono build previously returned an `_EDITOR_GET` / `EditorSettings` error during headless editor import and exit 1 during automatic shutdown without a runtime diagnostic. Keep those environment results separate from successful script/runtime tests; do not describe import as clean unless a new run establishes that.

No Git remote was created and no push, publishing, installation or export-platform change was performed.
