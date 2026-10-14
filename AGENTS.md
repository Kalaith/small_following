# Small Following project guidance

This project contains only the game itself: `project.godot`, `scenes/`, `scripts/`, `data/`, `assets/` and the export presets. Tests and most documentation were deliberately removed. The exception is `docs/`, which holds only the plans for new maps (start with `docs/MAP_ROADMAP.md`); read the relevant plan before building a map. The shared standards at the end of this file apply as well as everything here.

## Product invariants

- The player is the little robed cultist and can always move directly, including between rounds and while the ritual screen is open. Tab must let the player return to the visible village between rounds.
- The village occupies most of the screen during active rounds. Keep its persistent HUD small and interactions contextual. The ritual upgrade screen is a separate, intentionally large intermission.
- Robe cloth visibly trails movement and settles at rest.
- The upgrade screen is a purple occult circle whose visible nodes and connections form its geometry. Do not replace it with a fixed rectangular skill-card menu.
- Keep talking frequency, conviction per phrase and running speed mechanically distinct. Preserve conviction overflow so upgrades improve cumulative recruitment.
- The upgrade catalog stays bounded to implemented effects. Do not add fake purchasable nodes.

## Project engineering

- **Compatibility** renderer.
- The shared WebHatchery Godot toolkit (`../godot_toolkit`) is linked in as `res://addons/hatchery/` by `..\godot_toolkit	ools\Link-Toolkit.ps1 -ProjectDir .` (a junction, ignored by Git). It is plain preloaded GDScript, not an editor plugin. Small Following uses its balance facade (`core/balance.gd`), JSON and data-rule helpers, key and pad bindings, the settings store, `JsonSave` for the progression file, the pointer tap behind tap-to-walk, display and audio-level helpers, and the placeholder shapes. The game keeps its policy in `scripts/` (`settings_store.gd`: settings and rebindable actions; `progression_save.gd`: the save schema, validation and migration; `village_input.gd`: where a tap may walk) and keeps its own settings screen and ritual styling. Change toolkit code in `../godot_toolkit` under its own AGENTS.md.
- Use feet origins and Y sorting for 2D actors/props. World collision is layer 2; player is layer 1.
- Keep movement independent of earning, rounds, upgrade UI and automation.
- Balance numbers live in `data/balance.json`; upgrade definitions live in `data/upgrades.json` with stable IDs and supported effect types. Keep purchase validation in the progression owner, never only in button state.
- Purchases must not deduct currency if saving fails.

## Project checks

- This project has **no automated checks**. Do not write new tests, test scripts, fixtures or runners, and do not reintroduce the deleted ones.
- Verify changes with the parse/import check and by running the game (`Run.ps1`) and inspecting its output.

## Commit voice

Commit lines describe what changed as it is felt in the village and the ritual. Use `refactor` for structural changes.

```
Quillmoor University opens: bring the right argument (fourth map)
```

## Publishing

Publishing (`publish.ps1`, `publish-itch.ps1`) requires separate authorisation. `.\publish.ps1 -BuildOnly` (export only, no deploy) is fine for verification.

- `publish.ps1` and `publish-itch.ps1` are the shared templates from `../godot_toolkit/templates/`; the work lives in `../godot_toolkit/publishing/Publisher.ps1` (override the location with `-ToolkitDir`), which also supplies the Apache `web.htaccess`. A `tools/publishing/web.htaccess` here would override it.
- Exports need the **standard (non-mono)** Godot 4.2.2 console editor, matching the installed export templates: pass `-GodotExe`, set `GODOT_EXE`, or place it at `exports/tooling/Godot_v4.2.2-stable_win64_console.exe`. `Run.ps1` uses the installed mono editor for playing.

## Shared WebHatchery Godot standards

This section is identical in the AGENTS.md of every WebHatchery Godot project (`bound_god`, `small_following`, `spiritwright`, `godot_toolkit`). Change it in all four together; project-specific rules go in the sections above.

### Working

- Work only inside this project unless the user explicitly broadens the task. Preserve any user changes.
- Do not install or upgrade Godot, export templates, tools, plugins or GDExtensions without approval. Prefer built-in engine features.
- Do not overwrite original art.

### Code

- Godot **4.2.2** GDScript. The renderer is set per project (see above).
- Static typing everywhere: variables, parameters and return types.
- Load dependencies with `const X = preload("res://...")`.
- Tabs, LF, UTF-8, final newline (`.editorconfig`).
- Split scripts by responsibility before they grow. Size limits are below.
- Simulation and rules code never touches the scene tree, `Time`, `OS` or the global `randi()`/`randf()`. All randomness comes from an owned `RandomNumberGenerator`, so the same seed gives the same result. Presentation reads that state and sends commands; it never changes it any other way.
- Balance numbers and catalogs live in JSON under `data/` with stable ids (and `schema_version` where a catalog has one), validated at startup. Missing or mistyped data fails fast: report it, never silently default in code.
- Keep every catalog (upgrades, parts, miracles, blocks and so on) bounded to implemented effects. Do not add entries the code does not support.
- Persistent state lives under `user://` with schema validation, staged writes and backup recovery. A failed save must never lose progress or spend anything.

### Verification

- Do not create a `tests/` directory, test frameworks or test addons. Automated checks, where a project has them, are headless scripts in `tools/`, kept out of the exported game.
- Checks do not gate commits. Run the full set (the project's checks, if any, and a parse/import check with `--headless --editor --quit`) when a major feature or milestone is finished, and fix what they find before calling it done.
- Headless checks do not verify visuals, audio, input or feel. Verify anything visual by running the game (`Run.ps1`) and looking at it.
- Say plainly what was and was not checked.

### Size limits (hard rule)

- **No function may exceed 400 lines.**
- **No file may exceed 800 lines**: scripts, scenes, data, docs and text catalogs. Check with `git ls-files -co --exclude-standard | grep -E '\.(gd|tscn|json|md)$' | xargs wc -l | sort -n | tail`.
- When a change would push a function or file past its limit, or one is already over, **bring it below the limit in the same change**. Split a long function into well-named helpers; shrink a file by moving a cohesive responsibility (HUD, settings wiring, area building, save validation, layout, a catalog section and so on) into its own file and having the original delegate to or load it.
- **Never shrink a function or file by deleting blank lines, joining statements, removing comments, minifying or packing several entries onto one line.** Blank lines between functions and the existing comment density stay as they are. Line count comes down by moving content, not by squeezing it.
- Keep public members that other scripts use working, either in place or through a delegating function.

### Commits

- Commit early and often: after every complete, working step (a system, a fix, a data pass), not at the end of a milestone. Commits do not wait on checks (see Verification).
- Commit **all pending project changes**, including modified, added and deleted files you did not make yourself. Do not leave user changes or another agent's changes uncommitted because you did not touch them: review and preserve their contents, include them in the validation, and finish with a clean working tree.
- Existing ignore rules still apply to generated files, local tooling and credentials. Never force-add ignored files or commit secrets.
- Do not push or publish unless the user asks.

Message style: one line describing what changed **as it is felt by the player** (for the toolkit, by the games that use it), then a short plain tag in parentheses saying what it is technically.

```
Neris raises a ward whenever she is struck (spirit trait)
A prayer at the tree now feeds the god's Favour (shrine favour)
The Lantern Fair opens: be more interesting than the fair (third map)
Every game's saves now survive a torn write (json save)
Scribes set down the covenant: design and building plan (docs)
```

- Present tense, no trailing period, under ~100 characters before the tag where possible.
- Fixes and refactors are still described by their effect: `Builders no longer wall themselves into the cottage they are raising (site reservation fix)`, `No script over 800 lines: split main and the ritual screen (refactor)`.
- Tags are lowercase and plain: the system touched, `docs`, `refactor`, or a milestone id such as `M25`.
- Add a body only when the reason is not obvious from the line.
