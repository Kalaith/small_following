# Project architecture

## Runtime ownership

The project targets Godot 4.2.2, GDScript and Compatibility rendering. It has no packages, plugins, servers, external fonts or C# dependency. The installed Mono editor runs the GDScript project; no .NET project is created.

| File | Responsibility |
| --- | --- |
| `scenes/main.tscn` | Playable scene, ground, sorted actors and player instance |
| `scripts/main.gd` | Round timing, nearest audience, reward events, progression integration and compact village HUD |
| `scripts/player.gd`, `scenes/player.tscn` | Direct CharacterBody2D movement, feet collision, camera, drawn cultist and trailing cloth |
| `scripts/helper.gd` | One autonomous recruiter, grid travel, individual targets and independent phrase effort |
| `scripts/gathering.gd` | Typed villager/merchant audiences, phrase timing, conviction, local feedback and recruitment signal |
| `scripts/encounter.gd` | Opponent arrival, objections, conviction decay and one victory signal |
| `scripts/progression.gd` | Catalog validation, authoritative purchase checks, stat calculations and versioned local progression |
| `scripts/ritual_screen.gd` | Procedural ritual geometry, pan/zoom, selection, readable details and action signals |
| `scripts/ritual_layout.gd` | Authored production-node positions and satellite envelopes; generic branch/ring placement for other content |
| `data/upgrades.json` | 32 real upgrade definitions with stable IDs, per-rank effects/prices, rank limits, prerequisites and graph coordinates |
| `scripts/village.gd` | Deterministic ground/props and collision footprints |
| `scripts/game_audio.gd` | Promo music loop, distance-based footsteps, throttled phrase cues and per-channel sound controls; no gameplay authority |
| `scripts/settings_screen.gd`, `scripts/settings_store.gd`, `scripts/key_bindings.gd` | Sound/display and key mapping tabs, validated preference storage and keyboard Input Map application; see [settings contract](SETTINGS.md) |
| `tests/` | Isolated economy/save checks, scene integration, route simulation and rendered captures |
| `assets/` | Project icon and original music/footstep/synthetic speech assets with provenance |
| `docs/reference/` | Reference provenance and transfer status; never a runtime background source |

The map is 1560 x 1100 world pixels, with a 1280 x 800 base viewport. These are top-down coordinates, not an isometric grid. Feet are the actor origin and sorting anchor; actors and props share Y sorting. Collision layer 1 is the player, layer 2 is world obstacles. Listeners do not block movement. Cloth is purely visual.

Movement never checks round activity or ritual visibility. Round logic chooses the arrived undefeated opponent when in range, otherwise the nearest unfinished gathering. The ritual emits action requests; it does not award upgrades directly. `main.gd` enforces between-round purchasing, while `progression.gd` validates the next rank, its cost, prerequisites and the request's expected current rank. Disabled buttons are feedback, not the economy's only guard.

## Round and speech model

The provisional round lasts 11 seconds. Each new round returns the cultist to `(780, 680)` and resets each audience. Three initial groups of five listeners provide capacity for 15, growing to 25 through two invitation purchases, but the opening timer permits roughly three baseline conversions on representative direct routes. There is no three-recruit cap. See [timing assumptions and route evidence](PACING.md).

Each audience owns its phrase timer and conviction progress. Base speech produces one phrase per second, adding one conviction; three conviction recruits a listener and awards three donations. Partial phrase time and conviction stay with the gathering while the player leaves range. Conviction above the recruitment threshold carries to the next listener. Round reset clears both values.

Talking upgrades add to a base phrase-frequency multiplier: interval = `1 / (1 + sum(purchased speech_speed_add))`. The three original first ranks each add 0.2; `talk_3` rank 2 adds 0.3. Each persuasion rank adds 0.5 conviction per phrase. Each original running rank adds 0.15 to the base 180-pixel/second speed multiplier. Full ranks in the original core therefore give 1.9 phrases/second, 3 conviction/phrase and 288 pixels/second. The two new talking tiers add 0.5 and 0.6 base phrases/s; each new running tier adds 0.3 of base speed. Before finale inscriptions, player stats reach 3 phrases/s, 3 conviction/phrase and 396 px/s; the final catalog reaches 3.5 phrases/s, 5 conviction/phrase and 432 px/s before specialist bonuses. These are distinct axes; do not collapse them into one generic persuasion-rate stat.

Full-village success follows only from ordinary travel, phrase intervals and conviction. There is no full-upgrade completion shortcut, extra time or conversion cap. The pacing test records the actual completion time of all 15 listeners on practical routes and compares partial/nonoptimal builds with the same 11-second boundary.

Round end clamps earned time to the remaining timer, stops audience work and opens the ritual. Tab hides/reopens the ritual while earning remains stopped. Enter or the next-round action resets audiences and position, advances the round number and resumes earning. World movement continues even while the overlay obscures the village.

The cumulative `total_recruits` value counts **recruitment events**, including repeat conversions after audience resets. It does not represent unique permanent villagers. The same counter now persists across sessions; retain its explicit meaning until a real audience lifecycle is designed.

## Upgrade data and graph expansion

Catalog schema 1 contains an `upgrades` array. Each definition supplies `id`, `title`, `description`, `branch`, `ring`, `angle_degrees`, `cost`, `requires` and an `effect` dictionary. Ranked definitions add `max_rank` and `rank_costs`; optional `rank_effects` supplies a different effect dictionary for each rank. Supported effect keys are enumerated in `Progression.EFFECT_KEYS`: frequency, conviction, running, invitations/helper, merchant conviction/donations, debate unlock and general or type-specific opponent conviction. Merchant donation increments must be whole numbers. Unlock effects must have value 1, one rank and one occurrence per catalog. IDs are save references and must remain stable.

An omitted `max_rank` defaults to 1; valid limits are integers from 1 to 100. `rank_costs` must match the rank count, contain positive bounded integers and begin with the original `cost`. When present, `rank_effects` must match the rank count, contain supported positive effects and begin with the original `effect`; otherwise every rank repeats `effect`. Keeping first-rank values stable preserves the benefit of old purchases. The current catalog uses a distinct second effect only for `talk_3`. Catalog loading also rejects duplicate IDs, invalid coordinates/costs/effects, missing/self/duplicate prerequisites and prerequisite cycles.

If catalog loading fails, the scene shows its notice and disables rounds/save writes without loading or replacing existing progression. Repair the definitions before resuming.

The original catalog core retains three branches with three nodes each. The six inner nodes have one rank; `talk_3`, `persuade_3` and `run_3` have two. First-rank costs remain 6, 9 and 12 donations by ring; each second rank costs 18. This core is twelve purchases costing 135 donations. Six new single-rank nodes add two gathering unlocks and two stat tiers for talking/running, making eighteen purchases costing 318 donations before the single-rank, 30-donation helper. That earlier village expansion has sixteen nodes, nineteen purchases and costs 348 donations. The first-map finale adds sixteen nodes; the complete catalog has 32 nodes and 35 ranks. `main.apply_upgrades` creates each unlocked gathering exactly once; save reload reconstructs them from the same ranks. A prerequisite requires at least rank 1, not all ranks, of its referenced node.

`try_purchase(id, expected_rank = -1)` validates the requested node and next rank. UI requests include the selected current rank; a stale request after a previous purchase is rejected. One input buys one rank, a maximum-rank request spends nothing, and a failed candidate save grants nothing. The optional expected rank supports programmatic purchases without weakening the maximum-rank, prerequisite or affordability checks. Stats sum effects only through each saved purchased rank.

`ritual_layout.gd` stores presentation-only positions for the current 32 stable
IDs in `VILLAGE_POSITIONS`. The eight branches have unequal silhouettes:
Words crescent, Running left hook, Merchants compact loop, Trials diagonal
fork, Creed right curl, Faith lower fork, Village diagonal pair and Followers
satellite. Catalog rings still describe upgrade tiers; a local loop need not
increase its radius on every step. Placement changes no catalog coordinates,
effects, prices or prerequisites.

Other content uses the generic branch/ring fallback: known branch directions,
or the first authored angle for an unknown branch, with tier fans and sibling
lanes limited by neighbouring sectors. The 144-node fixture uses this fallback
and receives no production satellites. `satellite_seals(catalog)` supplies three
decorative envelopes around existing content, without adding nodes or edges.
Graph fit uses actual node extents so authored positions remain navigable.

`ritual_screen.gd` draws this node network above quiet decorative rings and
keeps selection details in stationary UI. The edge model distinguishes
same-branch progress from cross-branch requirements. Main edges remain
visible; hovering or selecting a node exposes its recursive prerequisite
ancestry, including crosslinks, and dims unrelated main paths. Hover is a
transient path preview and does not replace the selected purchase or details.
The right panel still names missing prerequisites and shows the next price,
current-to-next effect, rank and purchase state.

`Layout.edge_path(from_id, to_id, node_positions)` adds presentation-only
waypoints to links that would cross another node. The renderer shares the
normal pan/zoom transform, clips each end at its node rim and keeps solid main
paths, dashed contextual crosslinks and direction arrows. The catalog and
prerequisite model remain unchanged.

The backdrop contains a thin concentric inscription rim with regular invented
glyphs/ticks, broken inner arcs and the layout's three offset satellites
(ring/diamond, spiral and petals). These shapes never enter the edge model.
Real edges draw above ornament; node fills and label backgrounds mask strokes.
The centre uses a double-annulus pentagram medallion with muted incomplete
styling and completion-only strong fill/glow. Fit uses actual authored node
extents plus padding. The detail panel calls catalog depth **Tier**, since a
node's drawing radius need not match its catalog ring.

State drawings combine brightness, fill, outline/marks and rank pips rather
than color alone. Overview labels reduce with zoom; selected details and
visible navigation retain access to every node. Branch summaries drive a dropdown
for the eight production branches; catalogs with six or fewer use buttons. They report owned-node and affordable-purchase counts. A separate
node picker lists every entry in the selected branch, including locked nodes,
and focuses the chosen node. `focus_node` centers selection at a readable zoom;
`focus_branch` chooses a useful starting node in that branch. These operations
do not purchase or persist anything. Pan and zoom affect drawing,
label placement and hit testing through the same coordinate conversion. The
mouse wheel anchors zoom at the cursor; dragging changes pan. Recenter restores
a fitted view while preserving selection; Overview also clears selection and
hover, leaving purchase disabled until a node is selected. Do not couple node
count to fixed UI slots. See
[the presentation brief](RITUAL_READABILITY.md) and
[UI controls and review](UI_STYLE.md).

A separate 144-node test fixture stresses placement, overview/detail
navigation and transformed selection without entering the production catalog
or save. Large-scale test success does not prove that hundreds of authored
upgrades will be readable or balanced. New content still needs sensible
spacing, meaningful effects and human navigation review. Keyboard/gamepad
graph traversal, filtering and search are future work.

## Ritual completion centre

`Progression.is_circle_complete()` derives completion from a nonempty current
catalog with every saved rank equal to its validated maximum. It is independent
of `map_complete()`, which records Priest victory. Do not replace this predicate
with a hardcoded node count, an owned-node count or encounter progress. No new
save field is needed: ordinary purchase/reload state is its source of truth.
The staged purchase writer still determines whether a last rank is granted.

`ritual_screen.gd` changes the quiet centre to a filled, glowing violet/lilac
seal when ready and enables the fixed **Inner circle lit / Open** button. The
button remains accessible if the drawn centre is outside the panned view.
Centre picking shares the graph's world/screen transform. Activation opens a
single reusable overlay with the exact title **This is the end of the demo**
and a **Keep playing** button. Repeated activation creates no duplicate UI,
rewards, saves or new area. Message visibility is transient.

`main.gd` gives dismissal priority over the usual Esc settings shortcut. Tab
returns to the village and Enter begins the next round through their existing
paths. Hiding/reconfiguring the ritual or opening settings dismisses the notice;
reopening the ritual does not resurrect it. Direct movement and the scene tree
remain active. A future area may use this centre to open its own separate
circle, but no such area, transition or save contract is implemented now.
See [the scoped design](RITUAL_COMPLETION.md).

## Helper ownership and shared conversions

`helper.gd` owns one nonblocking Node2D actor under the Y-sorted Actors node.
Its AStarGrid2D uses 24-pixel cells and the actual static prop circle/rectangle
footprints, conservatively inflated by a half-cell diagonal plus a 7px body
radius. It chooses the shortest reachable path to a cell beside an unconverted
listener. Village props are static; navigation is built once on creation.
Future moving props would require rebuilding it. Every current listener is
reachable in the implemented static layout.

Main creates the actor only after a saved `helper_unlock` purchase (or reload),
passes only clamped active-round time, stops it at expiry and resets it at the
next entrance. The helper advances travel and phrases in at most 1/60-second
substeps, preserving travel time before speech even on long render frames.
It owns a group/index target, phrase timer and target-specific conviction;
these are transient and separate from the player's group-level overflow.

`gathering.recruit_listener(index)` is the single conversion/reward authority.
It checks the listener's state before marking and paying. Player speech chooses
the first remaining listener, skipping any helper conversions; partial group
conviction still carries forward. If the player finishes a helper target, that
helper effort resets before retargeting. Main routes both kinds of recruitment
through the same donations/event-total callback. Helper unlocks persist as
ordinary schema-2 ranks; no target or per-round audience data is saved.

## Local progression and recovery

`user://progression.json` stores schema 2 with `coins`, `purchased` (an ID-to-integer-rank dictionary), `total_recruits`, `round_number` and optional `encounter_stage`. Purchased entries must be integers from 1 through that node's `max_rank`; unpurchased IDs are absent, not stored as rank 0. Counters are bounded integers; purchased IDs must exist in the catalog and include their prerequisites. Nothing in a save is executable. On ordinary Windows Godot installations, `user://` resolves beneath `%APPDATA%\Godot\app_userdata\Small Following`; use the engine's user-data location when running with custom settings.

The schema-1 migration accepts the earlier ID-to-true purchase dictionary and maps each true value to rank 1. Currency, recruitment-event total and round number are preserved exactly; new second ranks are not granted. Loading alone leaves the valid old file untouched. The first successful schema-2 write retains the original schema-1 file as `.bak` through the ordinary staged writer. Schema-1 backups can also be validated and migrated for recovery. Routine tests use isolated fixture saves and do not migrate the player's live save.

Donations are saved as earned; round transitions save progression too. Purchases build and validate a candidate snapshot, save it, then apply it in memory. If saving fails, the purchase grants nothing and deducts nothing. Already-earned rewards stay in memory after a write failure, and a save notice appears in the UI; they may be lost if the application closes before a successful write.

The writer flushes a `.tmp` file, reads it back for validation, rotates the prior valid canonical file to `.bak`, then renames the verified temporary file into place. This staged replacement supports recovery if the canonical file disappears between renames; it is not a guarantee against every filesystem or power failure.

Loading follows these rules:

- No save or backup: use new-game defaults.
- Valid canonical save: restore its progression.
- Missing canonical with valid backup: restore the backup.
- Invalid canonical with valid backup: restore the backup and preserve the damaged original as `.corrupt` on a successful later save.
- Invalid canonical without a valid backup: start fresh in memory and preserve the damaged original as `.corrupt` before replacing it.
- A newer schema, invalid backup without a canonical file, or an existing conflicting `.corrupt` recovery file is preserved; saving is blocked as appropriate and the UI explains the problem.

Do not delete recovery files automatically to silence a notice. Schemas 1 and 2 are supported for loading; current writes use schema 2. Removing or renaming a purchased catalog ID, lowering a rank cap below saved progress or changing a purchased effect requires a deliberate compatibility/migration plan.

Restarting restores currency, purchases, the event total and saved round number, then begins a fresh timed round from the entrance. It does not resume remaining time, partial speech, player position or per-round recruits. There is no offline earning or quit penalty. This forgiving prototype policy is provisional and can be exploited by restarting for fresh audiences; decide the intended policy before a larger economy.

## Boundaries for future work

There is no dialogue system, magic or second town. Audio and independently
saved settings are implemented; Web/Windows export workflows are documented
in [PUBLISHING](PUBLISHING.md). Window resizing scales the canvas; accessible
UI scaling and gamepad rebinding remain future work. Keyboard bindings use the
separate settings store described in [SETTINGS](SETTINGS.md). Application focus does not
implement a pause/earnings policy.

Split reusable props, villagers, HUD and town definitions into scenes/resources as content grows. Town definitions should own stable IDs, positions, capacities and unlock rules; mutable town progress belongs in the save. Extend schema only for implemented features. Keep reward ownership centralized so future player speech, minions and spells cannot pay the same event twice.

Unique followers, town unlocks, mid-round state and timestamps are not current
progression save fields. Settings use their own [preference store](SETTINGS.md).
If offline income is adopted, define limits, clock-change handling and one-time
application before implementation. No cloud or backend architecture is required.

## Verification strategy

Run headless editor import and inspect logs, then the progression, scene and pacing tests listed in the README. Keep test saves isolated from normal player progress. Cover reward boundaries, distinct rank effects, per-rank affordability/prerequisites/max and stale-request guards, failed writes, valid and invalid rank saves, schema-1 migration, backup recovery and retained purchased stats.

Route simulation drives the actual player motion/collision and round/conversation code. It can establish a timing budget and demonstrate upgraded yields; it cannot establish human reaction time or enjoyment. Rendered captures verify composition and readability, not input feel. Inspect village and ritual frames, then human-test walking, cloth at upgraded speed, graph dragging/zooming, node selection, village return and next-round controls at supported window sizes.

Use `tests/test_ritual_readability.gd` for authored/fallback placement, contextual edges,
hover/selection separation, label bounds and transformed navigation. Exercise
branch and node controls on the 144-node fixture without saving its IDs into
ordinary progression. `tests/test_demo_completion.gd` exercises catalog-driven
completion, final-rank purchase, save reload, transformed centre picking and
message dismissal separately from Priest victory. Inspect rendered states
separately from the graph-model checks. Record exact engine, commands, results
and known environment failures in [VERIFICATION.md](VERIFICATION.md). Export
checks follow the existing [publishing workflow](PUBLISHING.md).

## First-map opponents and typed listeners

`gathering.gd` preserves its ordinary five listeners / three conviction / three
reward defaults. The optional merchant pair uses nine conviction and twelve
base donations. `main` applies purchased merchant donation bonuses and targeted
player conviction. Helpers read the audience threshold and keep their own stats.

`encounter.gd` owns four profiles and a two-segment clear path from the eastern
entrance to (790, 570). It subtracts actual travel time before accepting speech,
then applies whole-phrase objections, conviction and unattended decay. Opponents
are nonblocking actors under the existing Y-sorted parent. Helpers do not target
them. Main supplies only clamped active-round time, prioritizes an arrived opponent
in speech range, and creates at most one opponent per round.

`Progression.complete_encounter(expected_stage)` rejects duplicates, missing unlocks
and out-of-order results. It increments the stage, recruitment-event total and
fixed victory reward together, then saves. Earned victory follows the existing
in-memory retention policy on failed storage; a notice warns it may be lost on
exit. `map_complete()` means stage four, earned through normal Priest persuasion.
It does not require every upgrade or complete other listeners automatically.

The optional schema-2 `encounter_stage` is an integer 0–4 and defaults to zero in
older schema-1/2 saves. Nonzero values require the saved `debate_1` unlock with its
usual prerequisites. Stage four suppresses further opponents on reload and shows
the completed-map UI. Stage zero through three starts the next attempt on a fresh
round. Conviction, objections, arrival and partial speech are never persisted.
