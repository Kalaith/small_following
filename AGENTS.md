# Small Following project guidance

Work only inside this project unless the user explicitly broadens the task. Read README.md, docs/GAME_DESIGN.md and TODO.md first. The game name is Small Following. Preserve any user changes.

## Development documentation

- Use `docs/GAME_DEVELOPMENT_GUIDE.md` for the local Godot workflow and document map.
- Follow `docs/CODE_STANDARDS.md` for implementation and read `docs/UI_STYLE.md` before changing screens.
- Use `docs/GDD_TEMPLATE.md` for substantial design proposals; `docs/GAME_DESIGN.md` remains the current design.
- Follow `docs/COMMIT_STYLE.md` and make regular local commits after complete, validated feature slices, fixes and documentation changes. Commit each coherent slice before starting the next; do not wait for a whole major feature. Preserve unrelated user changes. Publishing and tool installation require separate authorization.
- `docs/AGENTS.md` adds documentation-maintenance guidance. This root file retains the project-wide invariants and required checks.

## Product invariants

- The player is the little robed cultist and can always move directly, including between rounds and while the ritual screen is open. Tab must let the player return to the visible village between rounds.
- The village occupies most of the screen during active rounds. Keep its persistent HUD small and interactions contextual. The requested ritual upgrade screen is a separate, intentionally large intermission.
- An ordinary opening round targets roughly three conversions through travel and speaking time. Do not implement an arbitrary three-recruit cap.
- Bramblewick opens with three small groups (4 / 3 / 4) plus five lone wanderers scattered each round clear of prop art (requested 2026-10-07). Full ranks should let a competent practical route convert all eleven group listeners inside the same 11-second round with time left to chase wanderers. Measure actual completed conversions and remaining time; visiting groups alone is insufficient. Keep human route uncertainty explicit.
- Robe cloth visibly trails movement and settles at rest.
- The upgrade screen is a purple occult circle whose visible nodes and connections form its geometry. Do not replace it with a fixed rectangular skill-card menu.
- Keep talking frequency, conviction per phrase and running speed mechanically distinct. Preserve conviction overflow so upgrades improve cumulative recruitment.
- Keep the real catalog bounded to implemented effects. More than 100 nodes in a test fixture demonstrates capacity, not shipped content.
- Mockups are references only. Never load a mock screenshot as a playable background.
- Confirmed direction and provisional tuning are separate in the design document. Do not rewrite guesses as user decisions.

## Engineering

- Godot 4.2.2 GDScript and Compatibility rendering are the tested baseline. Do not install or upgrade tools without approval.
- Prefer built-in engine features; this is not a Rust, npm, PHP or web project.
- Use feet origins and Y sorting for 2D actors/props. World collision is layer 2; player is layer 1.
- Keep movement independent of earning, rounds, upgrade UI and automation. Minions and magic must preserve control.
- Author upgrade definitions in `data/upgrades.json`, with stable IDs and supported effect types. Keep purchase validation in the progression owner, never only in button state.
- Preserve the original nine-node core while extending it for the requested village expansion. The outer tier-III nodes have two ranks; inner nodes have one. Validate rank bounds, per-rank price and stale expected-rank requests. One input buys one rank; maximum-rank purchases must spend nothing.
- Extend the graph through data and ring/branch placement; retain pan/zoom, transformed hit testing and readable selection details. Do not add dozens of fake purchasable nodes to production data.
- Use typed GDScript where useful. Keep balance in named constants and catalog data, with assumptions recorded in `docs/PACING.md`.
- Store runtime progression under `user://`, using explicit schema validation, staged writes and backup recovery. Purchases must not deduct currency if saving fails. Never store runtime saves or secrets in source.
- Schema 2 stores integer ranks; valid schema-1 purchases migrate to rank 1 with coins, recruitment events and round number preserved. Preserve stable upgrade IDs and test migration with isolated fixture saves.
- The saved recruitment total counts recruitment events, including repeats after audience resets. It is not a unique follower population.
- Isolate test saves from the player's normal save. Do not clear or migrate user progression for a routine verification run.
- Do not overwrite original art. Record provenance/license when adding assets.
- No remote, publishing or export-platform changes are implied by local edits.

## Checks and handoff

Use the installed Godot executable described in README. After behavioral changes, run a headless editor import, `tests/smoke_test.gd`, `tests/test_progression.gd` and `tests/test_pacing.gd`. Inspect logs even on exit 0. For visual changes, run `tests/capture_starter.gd` with a rendering display and inspect the actual PNG output. Do not claim headless runs verify pixels or human play feel. Add tests for meaningful behavior, not every reversible visual edit.

Exercise round-to-ritual-to-next-round transitions, movement while between rounds, rank affordability/prerequisites/max and stale-request protection, save round trips/migration/recovery, and pan/zoom selection with the separate large graph fixture. Pacing checks must use movement and conversation timing, not merely assert a configured duration. Compare unchanged opening routes, practical full-rank clears and incomplete or nonoptimal routes; do not add hidden full-upgrade completion rules.

Keep TODO.md outstanding-only and agent-actionable; human playtests, rendered reviews, asset sourcing and open design decisions belong to milestone exit criteria and the verification record's stated limits, not to that list. Put delivered behavior and evidence in README/docs/VERIFICATION.md. Update milestones only when their exit checks are met. `docs/reference/README.md` records the Windows Library transfer blocker. Do not retry unsupported raw downloads or modify the helper to bypass required metadata. Preserve exact originals when a supported transfer is available, and inspect local pixels before claiming local visual fidelity.
