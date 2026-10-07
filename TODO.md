# Outstanding work

Agent-actionable items only. Human playtests, rendered reviews, asset sourcing
and open design decisions are not listed here; their exit conditions live in
[milestones](docs/MILESTONES.md) and the limits they leave open are stated in
the [verification record](docs/VERIFICATION.md).


## Code health

Recorded by a full-source review on 2026-10-07; all twenty-three suites passed
(1,462 checks, 0 failures) at that commit. These are maintainability and
scaling items, not known gameplay defects.

- [ ] Consider indexing the catalog by ID if refresh cost matters again. The 2026-10-07 pass removed the repeated lookups and sweeps, leaving `update_state` at 0.54 ms for the production catalog and 2.58 ms for the 144-node fixture; the remainder is one linear `find_upgrade` per node in `get_branch_summaries`. An ID index would cut it further, but `catalog` is public and three suites mutate it in place with `append`, `pop_back` and `assign`, so it needs real invalidation rather than a cache keyed on size.
- [ ] `village.gd` and `market.gd` still repeat the same `WORLD_SIZE`/`_props_built`/`build_props` idempotency shape (market already reuses `Village.VillageProp` for the props themselves; only the guard/signature pattern is duplicated). The 2026-10-07 pass fixed the rest of this bullet's items; left this one alone as a deeper structural change for two otherwise-independent, stable world scripts.

Keep this list outstanding-only and agent-actionable; record delivered behavior
and checks in the README and verification record.
