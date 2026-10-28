# Small Following project guidance

The project holds only the game: `project.godot`, `scenes/`, `scripts/`, `data/`, `assets/`, export presets. Tests and most docs were removed on purpose. Exception: `docs/MAP_ROADMAP.md` (map order, each map's mechanic, shared rules for new maps) — read it before planning or building a map. A new map's plan may live in `docs/` while being built; delete it once the map is in.

## Product invariants

- The player (the little robed cultist) can always move directly, including between rounds and with the ritual screen open; Tab returns to the visible village between rounds.
- The village fills most of the screen in rounds: small persistent HUD, contextual interactions. The ritual upgrade screen is a separate, deliberately large intermission.
- Robe cloth trails movement and settles at rest.
- The upgrade screen is a purple occult circle whose nodes and connections form its geometry; never a rectangular skill-card menu.
- Talking frequency, conviction per phrase and running speed stay mechanically distinct. Keep conviction overflow so upgrades improve cumulative recruitment.

## Project engineering

- **Compatibility** renderer.
- The shared toolkit `../godot_toolkit` is linked as `res://addons/hatchery/` via `..\godot_toolkit\tools\Link-Toolkit.ps1 -ProjectDir .` (a Git-ignored junction; plain preloaded GDScript, not a plugin). Used: `core/balance.gd`, JSON/data-rule helpers, key/pad bindings, settings store, `JsonSave` (progression), tap-to-walk pointer, display/audio helpers, placeholder shapes. Game policy stays in `scripts/` (`settings_store.gd`: settings, rebindable actions; `progression_save.gd`: save schema, validation, migration; `village_input.gd`: where a tap may walk), plus the settings screen and ritual styling. Change toolkit code in `../godot_toolkit` under its own AGENTS.md.
- Feet origins and Y sorting for 2D actors/props. World collision is layer 2; player is layer 1.
- Movement is independent of earning, rounds, upgrade UI and automation.
- Balance in `data/balance.json`; upgrades in `data/upgrades.json` with stable ids and supported effect types. Purchase validation lives in the progression owner, never only in button state. A purchase never deducts currency if saving fails.
- **No automated checks**: write no tests, scripts, fixtures or runners, and don't restore deleted ones. Verify with the parse/import check and by running the game (`Run.ps1`).

## Commit voice

In this game, describe changes as felt in the village and the ritual, e.g. `Quillmoor University opens: bring the right argument (fourth map)`.

## Publishing

`publish.ps1` and `publish-itch.ps1` need separate authorisation; `.\publish.ps1 -BuildOnly` (export only) is fine for verification.

- They are the shared templates from `../godot_toolkit/templates/`; the work is in `../godot_toolkit/publishing/Publisher.ps1` (override: `-ToolkitDir`), which supplies the Apache `web.htaccess` (`tools/publishing/web.htaccess` here overrides it).
- Exports need the **standard (non-mono)** Godot 4.7.2 console editor matching the installed templates: pass `-GodotExe`, set `GODOT_EXE`, or install at `C:\Program Files\Godot`. `Run.ps1` uses it too.

## Shared WebHatchery Godot standards

Identical in every WebHatchery Godot project's AGENTS.md; change all together. Project-specific rules go above.

### Working

- Stay inside this project unless the user broadens the task; preserve user changes; never overwrite original art.
- No installing/upgrading Godot, export templates, tools, plugins or GDExtensions without approval; prefer built-in features.

### Code

- Godot **4.7.2** GDScript, statically typed everywhere (variables, parameters, returns). `const X = preload("res://...")`. Tabs, LF, UTF-8, final newline.
- Simulation/rules code never touches the scene tree, `Time`, `OS` or global `randi()`/`randf()`; randomness comes from an owned `RandomNumberGenerator` (same seed, same result). Presentation reads state and sends commands, nothing else.
- Balance and catalogs (upgrades, parts, miracles, blocks, ...) live in JSON under `data/` with stable ids (and `schema_version` where present), validated at startup, holding only implemented effects. Missing or mistyped data fails fast and is reported; never default silently in code.
- Persistent state lives under `user://` with schema validation, staged writes and backup recovery. A failed save never loses progress or spends anything.

### Verification

- No `tests/` directory, frameworks or addons. Any automated checks are headless scripts in `tools/`, kept out of the export.
- Checks don't gate commits. At a major feature or milestone, run all checks (plus `--headless --editor --quit`) and fix findings.
- Headless checks can't verify visuals, audio, input or feel: run the game and look. State plainly what was and wasn't checked.

### Verification images

- Only `docs/verification/` (flat; keep its `.gdignore` and `docs/`'s). Reference art: `docs/reference/` or `docs/art/`.
- Capture via the toolkit's `testing/capture_runner.gd` or `testing/capture_paths.gd` (`CapturePaths.file(label)`); never pass an output directory or write elsewhere (`builds/`, `exports/`, OS temp, `user://`).
- Stable names `<label>.png`: no subfolders, timestamps, run/revision/size suffixes, `-final`/`-fix` variants or backups. Recapturing a screen or state overwrites; new labels only for genuinely new ones.
- One window size and UI scale per game. Look at the image before saying a visual change works.

### Size limits (hard rule)

- **Functions ≤ 400 lines; files ≤ 800 lines** (scripts, scenes, data, docs, catalogs). Check: `git ls-files -co --exclude-standard | grep -E '\.(gd|tscn|json|md)$' | xargs wc -l | sort -n | tail`.
- Split scripts by responsibility before they grow. A change that would cross a limit, or touches something already over, brings it under in the same change: split functions into named helpers; move a cohesive responsibility (HUD, settings wiring, area building, save validation, layout, a catalog section, ...) into its own file the original delegates to or loads. Keep public members other scripts use working.
- **Never shrink by deleting blank lines, joining statements, removing comments, minifying or packing entries onto one line.** Move content; don't squeeze it.

### Commits

- **ALWAYS commit each feature slice and bug fix the moment it works. Mandatory.** One slice per commit; never batch, never leave finished work uncommitted, never end a turn with an uncommitted feature or fix. Don't wait to be asked or offer instead of doing it; a later request ("also tweak X") is a new slice.
- Commit **all pending changes**, including modified, added and deleted files you didn't make: review and preserve them, include them in validation, finish with a clean tree.
- **Before the final reply of any turn that touched files:** run `git status --short`; if it prints anything, commit and rerun until empty. A dirty tree means unfinished; the closing summary says the tree is clean.
- Ignore rules still apply; never force-add ignored files or commit secrets. Don't push or publish unless asked.

Message: one present-tense line, no trailing period, under ~100 characters before the tag, saying what changed **as the player feels it** (for the toolkit, as the games using it feel it), then a plain lowercase tag in parentheses for what it technically is (the system touched, `docs`, `refactor` for structural changes, or a milestone id such as `M25`). Fixes and refactors are still described by effect. Add a body only when the reason isn't obvious.

```
The Lantern Fair opens: be more interesting than the fair (third map)
A prayer at the tree now feeds the god's Favour (shrine favour)
Builders no longer wall themselves into the cottage they are raising (site reservation fix)
No script over 800 lines: split main and the ritual screen (refactor)
Every game's saves now survive a torn write (json save)
Scribes set down the covenant: design and building plan (docs)
```
