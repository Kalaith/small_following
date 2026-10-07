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
- [ ] Make the helper's obstacle lookup explicit. `helper.gd:31` finds footprints by the node name `"Shape"`, which only works because `village.gd` and `market.gd` both set it and the player's shape is named `FeetCollision`. Three files agree on a string literal with no error if one changes; a prop group or a layer-2 physics query would state the contract.
- [ ] Bound the helper's target search. `_choose_target` runs a fresh A* over the 2,501-cell grid for every eligible unconverted listener, and `_advance_step` may call it on each of up to sixty sub-steps per frame. Finding a target is self-limiting; finding none repeats the full sweep. A searched-and-empty flag per `advance` call would bound it.
- [ ] Add the four missing suites to the verification block in the [development guide](docs/GAME_DEVELOPMENT_GUIDE.md#5-verification-workflow): `test_mixed_audiences.gd`, `test_recruit_economy.gd`, `test_ritual_touch.gd` and `test_touch_movement.gd`. They cover the newest features and pass, but are absent from the documented workflow.
- [ ] Extract cohesive responsibilities from `ritual_screen.gd` (1,338 lines, about a hundred member variables), per the project's own standard. The natural seams are seal/node rendering, the detail panel with branch navigation, and pointer pan/zoom. While there: give `_label`/`_button` an optional parent so five callers stop reparenting with `remove_child`, and stop identifying the demo panel's labels by font size (`:623-626`).
- [ ] Decide whether a window resize should keep the ritual's pan and zoom. `_layout` calls `reset_view` (`ritual_screen.gd:808`), so resizing discards deliberate navigation in a graph that zooms a hundredfold.
- [ ] Remove remaining small couplings and duplication: the hardcoded `"debate_1"` ID in save validation (`progression.gd:551`) could derive from the `encounter_unlock` effect; `scenes/main.tscn`'s authored `Village` node is always destroyed and replaced by `_rebuild_area`; `_oval` is duplicated inside `village.gd`; `village.gd` and `market.gd` repeat the same `WORLD_SIZE`/`_props_built`/`build_props` shape; the `0.000001` phrase epsilon appears unnamed five times; `village_input`'s `-2` no-pointer sentinel is unexplained; `gathering._ready` indexes fixed five-element offset arrays by an unchecked public `listener_count`; `gathering.gd:282` omits the clamp its market twin uses at `:316`; and `game_audio.apply_preferences` indexes `values[channel]` directly, coupling it to `settings_store.DEFAULTS` by convention.

Keep this list outstanding-only and agent-actionable; record delivered behavior
and checks in the README and verification record.
