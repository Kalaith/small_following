# Small Following - Godot code standards

Use with the root [AGENTS](../AGENTS.md), current
[ARCHITECTURE](ARCHITECTURE.md) and [development guide](GAME_DEVELOPMENT_GUIDE.md).
These standards apply to this Godot 4.2.2 GDScript project.

## 1. Keep code understandable

- Follow existing style and `.editorconfig`: UTF-8, LF, final newline and tabs
  in GDScript.
- Use `snake_case` for scripts, variables, methods and signals, `PascalCase`
  for class names and scene node names, and `SCREAMING_SNAKE_CASE` for constants.
- Type parameters, return values, state and collections where this clarifies
  ownership or catches mistakes. Use syntax supported by Godot 4.2.2; the
  current validated JSON boundaries use `Dictionary` and `Variant`.
- Explain assumptions, units and non-obvious constraints in comments. Remove
  unused code; prefix unused callback parameters only when the signature needs
  them.
- Keep methods focused and extract cohesive responsibilities as scripts grow.
  Avoid unrelated refactors or splitting files merely to meet a line count.
- Keep tunable balance in named constants or the catalog and explain it in
  [PACING](PACING.md). Do not duplicate purchase formulas in UI code.

## 2. Scene and state ownership

Use the current ownership table in [ARCHITECTURE](ARCHITECTURE.md). Keep node
lifecycle work in the appropriate Godot callbacks, cache stable node references
and connect signals at a clear setup point. Avoid duplicate signal connections
when rebuilding UI or changing scenes.

`main.gd` coordinates the round; `progression.gd` owns the economy and saves;
each gathering owns its phrase and conviction progress. A view may own
selection, hover, pan and zoom. It must request gameplay changes through the
owner rather than directly mutating coins or ranks.

Prefer reusable scenes for repeated world objects and `RefCounted` or
`Resource` types for data/logic where useful. Introduce an autoload only when a
real cross-scene lifetime requires one. Avoid global mutable state for local
scene responsibilities.

## 3. Movement, time and input

- Use Input Map actions from `project.godot`. Preserve existing keyboard and
  gamepad bindings; shortcuts should use the same action path as buttons.
- Physics movement belongs in `_physics_process`. Keep `velocity` in pixels
  per second and preserve the existing `move_and_slide()` path. Test motion on
  physics frames through `step_motion`.
- Normalize or limit directional input so diagonals do not gain speed.
- Keep movement independent of `round_active`, earning, ritual visibility and
  future automation. Do not pause the tree to show upgrades.
- Use feet origins and Y sorting for actors/props. Player collision is layer 1;
  world collision is layer 2. Cloth is visual and settles after movement.
- Preserve the round's clamped usable delta at expiry. No conversation work
  may use time beyond the round boundary.
- Keep talking frequency, conviction per phrase and running speed distinct.
  Preserve conviction overflow and the audience's partial phrase progress.
- Ignore echoed key events for one-shot actions. One purchase activation buys
  one rank; input handling must not double-apply the same action.

Current round updates run through `advance_round` from `_process`; pacing
tests drive that same method at fixed steps. Do not silently replace either
timing path while changing unrelated code.

## 4. UI and rendering

Read [UI_STYLE](UI_STYLE.md) before changing a screen. Use `Control`, containers,
anchors and `CanvasLayer` for interface layout. Custom `_draw()` geometry is
appropriate for the ritual and existing placeholder art. Rendering may read
state; it must not award currency, advance a round or write a save.

Keep pointer coordinates consistent with drawing. The ritual's
`world_to_screen` and `screen_to_world` conversions must agree after pan,
cursor-anchored zoom, recenter and resize. Keep stationary details readable.
Set control mouse filtering deliberately and preserve direct player input
while the ritual has focus. Test both button activation and shortcuts.

Use signals for action requests. Existing purchase requests include a stable
ID and the rank the player saw. `main.gd` checks that purchasing is allowed in
the phase; progression rechecks price, prerequisites, rank bounds and stale
requests. Disabled controls only explain these rules.

## 5. Catalog and content validation

Author upgrades in `data/upgrades.json`, whose catalog schema is currently 1.
The save schema is independently versioned at 2. Preserve stable IDs and the
original nine-node core with one rank on inner nodes and two on tier-III nodes; the requested village expansion adds implemented nodes.

Validate definitions before making them available: nonempty unique IDs,
supported positive finite effects, valid coordinates, rank bounds, one price
and effect per rank, and existing acyclic prerequisites. `cost` and `effect`
must agree with the first rank. Supported effects are `speech_speed_add`,
`conviction_add`, `run_speed_add`, `meadow_unlock`, `east_unlock` and `helper_unlock`; implement and test a new effect before
adding it to production data.

Keep fixture content under `tests/fixtures/`. Tests of 144 nodes must not
change production counts, unlock rules or player progression. Catalog errors
must remain visible and prevent unsafe progression writes.

## 6. Save contract and errors

Use `user://` and Godot file APIs for runtime persistence. Schema 2 stores
`coins`, integer `purchased` ranks, `total_recruits` and `round_number`.
Unpurchased entries are absent; stored ranks begin at 1. Validate types, finite
numbers, bounds, IDs and prerequisites before applying a snapshot.

`total_recruits` counts recruitment events across audience resets. It is not a
unique follower population. Restarting begins a fresh timer/audience; position,
partial phrases and remaining time are not persisted.

Preserve these transaction and compatibility rules:

1. Build and validate a candidate purchase snapshot.
2. Write and flush a temporary file, read it back for validation, preserve the
   prior valid save as backup and promote the candidate.
3. Apply the purchase to memory only after saving succeeds. Failure grants
   nothing and spends nothing.
4. Load valid schema-1 boolean purchases as rank 1 with currency, event total
   and round number unchanged. Keep migration tests isolated.
5. Preserve unsupported future saves and damaged originals. Follow existing
   backup/`.corrupt` rules rather than deleting files to suppress a notice.

Staged replacement supports recovery but does not guarantee survival of every
filesystem failure. Earned donations have a different failure policy: they
remain in memory after a failed save and may be lost on exit. Surface the
notice honestly. Keep detailed recovery behavior in
[ARCHITECTURE](ARCHITECTURE.md#local-progression-and-recovery).

Use explicit return values and meaningful diagnostics for fallible operations.
Validate untrusted JSON before casts; do not rely on assertions as runtime
save validation. Do not catch or ignore errors just to report a successful run.

## 7. Tests and verification

Keep tests and test-only helpers in `tests/`. Use the existing `SceneTree`
scripts and meaningful behavior assertions; no extra framework is required.
Test shared runtime methods instead of rewriting game formulas in a test.

| Area | Required evidence when changed |
| --- | --- |
| Movement/rounds | Collision, diagonals, cloth, earning boundary, transitions and between-round control |
| Purchases | Affordability, prerequisites, distinct effects, rank limits, stale requests and failed writes |
| Saves | Round trip, schema-1 migration, malformed/future versions and backup recovery |
| Pacing | Real motion and conversation, each completed conversion, full-clear margin and comparison routes |
| Graph | Selection after pan/zoom/recenter, actual input path and the separate large fixture |
| Visuals | Rendered PNG inspection and relevant interactive checks |

Set `persistence_enabled = false` before adding a scene to the tree for
non-save tests. Persistence integration tests must set `save_path_override`
before `_ready()` can load anything. Progression unit fixtures use dedicated
paths. Never clear or migrate the normal `user://progression.json` for tests.

Run the import and three suites after behavioral changes; run rendered
captures for visual changes. Exact commands live in the
[development guide](GAME_DEVELOPMENT_GUIDE.md#5-verification-workflow).
Inspect logs even on exit 0. Preserve useful regression coverage without an
arbitrary case quota. Human play feel and visual correctness require their
own evidence.

## 8. Assets and repository hygiene

Keep source scenes, scripts, catalog and asset metadata under version control.
The `.gitignore` excludes engine caches and local build outputs; retain source
`.import` and `.uid` files when generated. Runtime saves and secrets do not
belong in source.

Preserve original art and record provenance/license for additions. Store actual
verification images directly under `docs/verification/` with stable state
names. Do not use reference screenshots as playable backgrounds. Keep the
documented Windows Library transfer blocker intact until supported recovery
is available.

Work within this project, preserve user changes and review Git status without
moving or deleting unrelated files to make it clean. Use the real checkout for
checks. Export, publishing, remote changes and engine/tool upgrades require
their own task scope.
