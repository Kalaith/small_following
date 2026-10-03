# Project architecture

## Runtime ownership

The project targets Godot 4.2.2, GDScript and Compatibility rendering. It has no packages, plugins, servers, external fonts or C# dependency. The installed Mono editor runs the GDScript project; no .NET project is created.

| File | Responsibility |
| --- | --- |
| `scenes/main.tscn` | Playable scene, ground, sorted actors and player instance |
| `scripts/main.gd` | Round timing, nearest audience, reward events, progression integration and compact village HUD |
| `scripts/player.gd`, `scenes/player.tscn` | Direct CharacterBody2D movement, feet collision, camera, drawn cultist and trailing cloth |
| `scripts/gathering.gd` | Five listeners, phrase timing, conviction, local feedback and recruitment signal |
| `scripts/progression.gd` | Catalog validation, authoritative purchase checks, stat calculations and versioned local progression |
| `scripts/ritual_screen.gd` | Procedural ritual geometry, pan/zoom, selection, readable details and action signals |
| `data/upgrades.json` | Nine real upgrade definitions with stable IDs, per-rank effects/prices, rank limits, prerequisites and graph coordinates |
| `scripts/village.gd` | Deterministic ground/props and collision footprints |
| `tests/` | Isolated economy/save checks, scene integration, route simulation and rendered captures |
| `assets/` | Project icon; reserve future subfolders for licensed production assets |
| `docs/reference/` | Reference provenance and transfer status; never a runtime background source |

The map is 1560 x 1100 world pixels, with a 1280 x 800 base viewport. These are top-down coordinates, not an isometric grid. Feet are the actor origin and sorting anchor; actors and props share Y sorting. Collision layer 1 is the player, layer 2 is world obstacles. Listeners do not block movement. Cloth is purely visual.

Movement never checks round activity or ritual visibility. Round logic chooses only the nearest unfinished gathering within range. The ritual emits action requests; it does not award upgrades directly. `main.gd` enforces between-round purchasing, while `progression.gd` validates the next rank, its cost, prerequisites and the request's expected current rank. Disabled buttons are feedback, not the economy's only guard.

## Round and speech model

The provisional round lasts 11 seconds. Each new round returns the cultist to `(780, 680)` and resets each audience. Three groups of five listeners provide a maximum village capacity of 15, but the opening timer permits roughly three baseline conversions on representative direct routes. There is no three-recruit cap. See [timing assumptions and route evidence](PACING.md).

Each audience owns its phrase timer and conviction progress. Base speech produces one phrase per second, adding one conviction; three conviction recruits a listener and awards three donations. Partial phrase time and conviction stay with the gathering while the player leaves range. Conviction above the recruitment threshold carries to the next listener. Round reset clears both values.

Talking upgrades add to a base phrase-frequency multiplier: interval = `1 / (1 + sum(purchased speech_speed_add))`. The three first ranks each add 0.2; `talk_3` rank 2 adds 0.3. Each persuasion rank adds 0.5 conviction per phrase. Each running rank adds 0.15 to the base 180-pixel/second speed multiplier. Full ranks therefore give 1.9 phrases/second, 3 conviction/phrase and 288 pixels/second. These are distinct axes; do not collapse them into one generic persuasion-rate stat.

Full-village success follows only from ordinary travel, phrase intervals and conviction. There is no full-upgrade completion shortcut, extra time or conversion cap. The pacing test records the actual completion time of all 15 listeners on practical routes and compares partial/nonoptimal builds with the same 11-second boundary.

Round end clamps earned time to the remaining timer, stops audience work and opens the ritual. Tab hides/reopens the ritual while earning remains stopped. Enter or the next-round action resets audiences and position, advances the round number and resumes earning. World movement continues even while the overlay obscures the village.

The cumulative `total_recruits` value counts **recruitment events**, including repeat conversions after audience resets. It does not represent unique permanent villagers. The same counter now persists across sessions; retain its explicit meaning until a real audience lifecycle is designed.

## Upgrade data and graph expansion

Catalog schema 1 contains an `upgrades` array. Each definition supplies `id`, `title`, `description`, `branch`, `ring`, `angle_degrees`, `cost`, `requires` and an `effect` dictionary. Ranked definitions add `max_rank` and `rank_costs`; optional `rank_effects` supplies a different effect dictionary for each rank. Supported effect keys are `speech_speed_add`, `conviction_add` , `run_speed_add`, `meadow_unlock` and `east_unlock`. Unlock effects must have value 1, one rank and one occurrence per catalog. IDs are save references and must remain stable.

An omitted `max_rank` defaults to 1; valid limits are integers from 1 to 100. `rank_costs` must match the rank count, contain positive bounded integers and begin with the original `cost`. When present, `rank_effects` must match the rank count, contain supported positive effects and begin with the original `effect`; otherwise every rank repeats `effect`. Keeping first-rank values stable preserves the benefit of old purchases. The current catalog uses a distinct second effect only for `talk_3`. Catalog loading also rejects duplicate IDs, invalid coordinates/costs/effects, missing/self/duplicate prerequisites and prerequisite cycles.

If catalog loading fails, the scene shows its notice and disables rounds/save writes without loading or replacing existing progression. Repair the definitions before resuming.

The original catalog core retains three branches with three nodes each. The six inner nodes have one rank; `talk_3`, `persuade_3` and `run_3` have two. First-rank costs remain 6, 9 and 12 donations by ring; each second rank costs 18. This core is twelve purchases costing 135 donations. Six new single-rank nodes add two gathering unlocks and two stat tiers for talking/running, making eighteen purchases costing 318 donations. `main.apply_upgrades` creates each unlocked gathering exactly once; save reload reconstructs them from the same ranks. A prerequisite requires at least rank 1, not all ranks, of its referenced node.

`try_purchase(id, expected_rank = -1)` validates the requested node and next rank. UI requests include the selected current rank; a stale request after a previous purchase is rejected. One input buys one rank, a maximum-rank request spends nothing, and a failed candidate save grants nothing. The optional expected rank supports programmatic purchases without weakening the maximum-rank, prerequisite or affordability checks. Stats sum effects only through each saved purchased rank.

The ritual computes node positions from ring radius and angle, draws the node network as the seal, and keeps selection details in stationary UI. Rank pips and labels distinguish partial and maximum ranks; details show the next price and current-to-next stat effect. Pan and zoom affect drawing and hit testing through the same coordinate conversion. The mouse wheel anchors zoom at the cursor; dragging changes pan. Recenter restores a fitted view. Do not couple node count to fixed UI slots.

A separate 144-node test fixture stresses placement, navigation and transformed selection without entering the production catalog or save. Large-scale test success does not prove that hundreds of authored upgrades will be readable or balanced. New content still needs sensible angular spacing, meaningful effects and human navigation review. Keyboard/gamepad graph traversal, filtering and search are future work.

## Local progression and recovery

`user://progression.json` stores schema 2 with `coins`, `purchased` (an ID-to-integer-rank dictionary), `total_recruits` and `round_number`. Purchased entries must be integers from 1 through that node's `max_rank`; unpurchased IDs are absent, not stored as rank 0. Counters are bounded integers; purchased IDs must exist in the catalog and include their prerequisites. Nothing in a save is executable. On ordinary Windows Godot installations, `user://` resolves beneath `%APPDATA%\Godot\app_userdata\Small Following`; use the engine's user-data location when running with custom settings.

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

There is no dialogue system, helper AI, magic, second town, audio, export preset or release build. Window resizing scales the canvas; accessible UI scaling and input rebinding remain future work. Application focus does not implement a pause/earnings policy.

Split reusable props, villagers, HUD and town definitions into scenes/resources as content grows. Town definitions should own stable IDs, positions, capacities and unlock rules; mutable town progress belongs in the save. Extend schema only for implemented features. Keep reward ownership centralized so future player speech, minions and spells cannot pay the same event twice.

Unique followers, settings, town unlocks, mid-round state and timestamps are not current save fields. If offline income is adopted, define limits, clock-change handling and one-time application before implementation. No cloud or backend architecture is required.

## Verification strategy

Run headless editor import and inspect logs, then the progression, scene and pacing tests listed in the README. Keep test saves isolated from normal player progress. Cover reward boundaries, distinct rank effects, per-rank affordability/prerequisites/max and stale-request guards, failed writes, valid and invalid rank saves, schema-1 migration, backup recovery and retained purchased stats.

Route simulation drives the actual player motion/collision and round/conversation code. It can establish a timing budget and demonstrate upgraded yields; it cannot establish human reaction time or enjoyment. Rendered captures verify composition and readability, not input feel. Inspect village and ritual frames, then human-test walking, cloth at upgraded speed, graph dragging/zooming, node selection, village return and next-round controls at supported window sizes.

Use the 144-node fixture for graph coverage, without saving fixture IDs into ordinary progression. Export checks become relevant once a platform and templates are selected. Record exact engine, commands, results and known environment failures in [VERIFICATION.md](VERIFICATION.md).
