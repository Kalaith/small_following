# Small Following project guidance

This branch (`game-only`) contains only the game itself: `project.godot`, `scenes/`, `scripts/`, `data/`, `assets/` and the export presets. Documentation, tests, tooling and publishing scripts were deliberately removed. Work only inside this project unless the user explicitly broadens the task. Preserve any user changes.

## Tests

- **Do not write new tests.** Do not add test scripts, fixtures, test runners or a `tests/` directory, and do not reintroduce the deleted ones.
- Verify changes by running the game (`Run.ps1`, or `--headless --editor --quit` for an import/parse check) and inspecting its output.

## Product invariants

- The player is the little robed cultist and can always move directly, including between rounds and while the ritual screen is open. Tab must let the player return to the visible village between rounds.
- The village occupies most of the screen during active rounds. Keep its persistent HUD small and interactions contextual. The ritual upgrade screen is a separate, intentionally large intermission.
- Robe cloth visibly trails movement and settles at rest.
- The upgrade screen is a purple occult circle whose visible nodes and connections form its geometry. Do not replace it with a fixed rectangular skill-card menu.
- Keep talking frequency, conviction per phrase and running speed mechanically distinct. Preserve conviction overflow so upgrades improve cumulative recruitment.
- Keep the upgrade catalog bounded to implemented effects. Do not add fake purchasable nodes.

## Engineering

- Godot 4.2.2 GDScript and Compatibility rendering are the baseline. Do not install or upgrade tools without approval.
- Prefer built-in engine features.
- Use feet origins and Y sorting for 2D actors/props. World collision is layer 2; player is layer 1.
- Keep movement independent of earning, rounds, upgrade UI and automation.
- Balance numbers live in `data/balance.json`; upgrade definitions live in `data/upgrades.json` with stable IDs and supported effect types. Keep purchase validation in the progression owner, never only in button state.
- Store runtime progression under `user://`, using schema validation, staged writes and backup recovery. Purchases must not deduct currency if saving fails.
- Do not overwrite original art.
- Make regular local commits after complete, working changes. Publishing requires separate authorization.
