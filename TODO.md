# Outstanding work

Agent-actionable items only. Human playtests, rendered reviews, asset sourcing
and open design decisions are not listed here; their exit conditions live in
[milestones](docs/MILESTONES.md) and the limits they leave open are stated in
the [verification record](docs/VERIFICATION.md).

- [ ] Add gamepad rebinding: remapping which physical gamepad button fires an action. Accessible keyboard/gamepad ritual graph navigation and keyboard rebinding of every action, including the new graph directions, shipped 2026-10-07 ([VERIFICATION](docs/VERIFICATION.md)).
- [ ] Add further accessibility settings and keyboard/gamepad navigation for the settings screen, including saved preferences for each new setting.
- [ ] Resolve the installed editor's `_EDITOR_GET` import-check error and unexplained automatic-shutdown exit status; keep those limitations separate from runtime check results.

## Code health

Recorded by a full-source review on 2026-10-07; all twenty-three suites passed
(1,462 checks, 0 failures) at that commit. These are maintainability and
scaling items, not known gameplay defects.

- [ ] Consider indexing the catalog by ID if refresh cost matters again. The 2026-10-07 pass removed the repeated lookups and sweeps, leaving `update_state` at 0.54 ms for the production catalog and 2.58 ms for the 144-node fixture; the remainder is one linear `find_upgrade` per node in `get_branch_summaries`. An ID index would cut it further, but `catalog` is public and three suites mutate it in place with `append`, `pop_back` and `assign`, so it needs real invalidation rather than a cache keyed on size.
- [ ] Extract cohesive responsibilities from `ritual_screen.gd` (1,338 lines, about a hundred member variables), per the project's own standard. The natural seams are seal/node rendering, the detail panel with branch navigation, and pointer pan/zoom. While there: give `_label`/`_button` an optional parent so five callers stop reparenting with `remove_child`, and stop identifying the demo panel's labels by font size (`:623-626`).
- [ ] Decide whether a window resize should keep the ritual's pan and zoom. `_layout` calls `reset_view` (`ritual_screen.gd:808`), so resizing discards deliberate navigation in a graph that zooms a hundredfold.
- [ ] `village.gd` and `market.gd` still repeat the same `WORLD_SIZE`/`_props_built`/`build_props` idempotency shape (market already reuses `Village.VillageProp` for the props themselves; only the guard/signature pattern is duplicated). The 2026-10-07 pass fixed the rest of this bullet's items; left this one alone as a deeper structural change for two otherwise-independent, stable world scripts.

Keep this list outstanding-only and agent-actionable; record delivered behavior
and checks in the README and verification record.
