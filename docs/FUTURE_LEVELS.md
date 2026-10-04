# Future levels and mixed audiences - proposal, 2026-10-04

## 0. Scope and decision status

**Requested:** begin planning more than two future levels, considering a larger
town and possibly a noble gathering; add different NPCs within a group, with
some groups offering three approachable listeners and two who need unlocks.

**Proposal:** six candidate areas and a reusable mixed-audience system. The
recommended first playable extension is a larger market town. Names, ordering,
NPC mixes, unlocks, costs and completion objectives below are suggestions, not
confirmed content or implemented behavior. The noble gathering remains a
candidate, as requested. This document follows [GDD_TEMPLATE](GDD_TEMPLATE.md);
[GAME_DESIGN](GAME_DESIGN.md) remains the current design.

The implemented baseline is Bramblewick, its 32-node/35-rank circle, homogeneous
ordinary and merchant gatherings, and separate opponents. Individual listeners
already exist visually, but a gathering currently shares a type, conviction
threshold and reward. Area travel and individual listener requirements need new
implementation. See [FIRST_MAP](FIRST_MAP.md) and [ARCHITECTURE](ARCHITECTURE.md).

This planning slice adds no runtime content. Preserve the original three
five-person groups and their pacing benchmark. Start mechanical audience
variety in the next area; a later retrofit to optional Bramblewick gatherings
is a separate choice, not part of this proposal's first implementation.

## 1. High concept

The little cult grows from friendly village conversations into a following
among traders, guilds, courtiers, scholars and pilgrims. Each place changes
who is willing to listen and which route is useful. Familiar faces in a group
provide early progress; specialist inscriptions gradually open the whole group.

Keep the cute overhead perspective, short rounds and directly controlled robed
cultist. Build one useful extension before committing to the whole campaign.
Godot 4.2.2, GDScript and Compatibility remain the baseline. Existing platform
evidence belongs in [VERIFICATION](VERIFICATION.md); none verifies these ideas.

## 2. Design pillars and invariants

| Pillar | Observable result | Check |
| --- | --- | --- |
| New places change route decisions | Each area has a distinct layout and one leading mechanic | Compare at least two useful routes in a human playtest |
| Every group has readable people | Outfit/prop, role label and requirement explain who can listen | Recognize approachable, resistant and locked NPCs without color alone |
| Progress remains attainable | Open listeners can fund required unlocks; unlocked NPCs still need speech | Reach every mandatory gate from its actual entry build and balances |
| The cultist stays in control | Movement, trailing cloth and Tab village return remain available | Exercise active rounds, ritual, return travel and failed transitions |
| Upgrades keep distinct jobs | Frequency changes phrase timing, conviction changes progress, speed changes travel; eligibility changes who can listen | Isolated effects and real route comparisons |

Retain the purple circle made from real nodes and connections, pan/zoom and
readable selected details. Keep overflow, rank validation and save safety.
The original opening target is roughly three conversions through time and
travel, with no arbitrary three-recruit cap. Future locked NPCs must not be
used to manufacture that result in the current village.

## 3. Core loop and transitions

1. Enter an available area and inspect its local groups between rounds.
2. Start a round, choose a route and speak to eligible listeners automatically.
3. Earn donations and recruit events from completed conversions.
4. Use the area's ritual to improve stats or open a particular audience type.
5. Revisit a familiar group with a new capability, or pursue another route.
6. Complete the area's circle and deliberately choose an available destination.

| Transition | Proposed trigger and state | Movement and earning |
| --- | --- | --- |
| Active round -> ritual | Timer ends; keep wallet/ranks, stop earning | Movement continues; Tab reveals the area |
| Ritual -> same area's next round | Next-round action; reset audience, partial speech, helper and entry position | Ordinary control; timed earning resumes |
| Completed centre -> destinations | Explicit centre action between rounds | No automatic travel or reward; village return stays available |
| Destination -> another area | Prepare the destination, validate availability and save the candidate active area before activating it | Arrive between rounds with direct control and no earning until Next round |
| Travel preparation/save failure or cancel -> current area | Keep current area, purchases and wallet | Continue moving and playing; show the reason |

Proposed area access follows the completed circle. Keep Bramblewick's Priest
victory separate; do not silently add it as another travel requirement. Each
area would check its own authored circle, so adding a later area's nodes does
not make an earlier completed circle incomplete. The current demo message
continues unchanged until area travel is implemented.

## 4. Player role and verbs

Keep walking, choosing a gathering and purchasing inscriptions as the main
verbs. Speech remains automatic in range; no per-NPC click sequence is needed
to recruit. Inspecting a role explains a lock without spending anything.
The helper obeys audience requirements and keeps its own speaking/movement
stats. An unlock makes a listener eligible; it does not recruit them instantly.

Maintain keyboard, mouse and touch paths, visible intermission controls and
existing gamepad movement. Do not imply that full gamepad graph navigation is
already implemented. New inspection must not depend on hover.

## 5. Systems, economy and timing

### Mixed five-person groups

An example larger-town group, **Market Steps**, starts with three approachable
listeners. Role and inscription names are provisional.

| Listener | Initial state | Requirement | Once eligible |
| --- | --- | --- | --- |
| Baker | Approachable | None | Ordinary conviction and donation |
| Porter | Approachable | None | Ordinary conviction and donation |
| Shopper | Approachable | None | Ordinary conviction and donation |
| Guild artisan | Locked | Guild Introduction | Higher conviction requirement, then a larger donation |
| Town clerk | Locked | Credible Testimony | Higher conviction requirement, then a larger donation |

Guild Introduction and Credible Testimony are proposed permanent inscriptions,
funded by ordinary repeatable earnings. Either can be the first audience unlock;
neither requires converting its own locked listener. Each should open matching
NPCs in several groups so the purchase creates route choices.

With neither inscription, up to three people in this group are eligible. With
one, four are eligible; with both, all five are eligible. Those are eligibility
counts, not guaranteed conversions per round. Time, travel and conviction still
determine what the player completes. Different groups can use 5 open, 4+1 or
3+2 mixes; do not force every group to follow the same pattern.

**Proposed speech rules:**

- Keep a deterministic authored listener order. Skip locked or converted slots
  rather than letting them block later eligible listeners.
- Choose the nearest gathering with an eligible unfinished listener. A nearby
  group with only locked listeners left must not steal speech from another
  eligible group. It remains inspectable.
- A completed phrase supplies conviction to the next eligible listener's
  threshold. Subtract completed thresholds and carry excess toward the next
  eligible listener in the same gathering. Partial phrase/work persists during
  the round; reset it with audiences at the next round.
- When no eligible listeners remain, stop accruing phrase time and conviction;
  do not bank unlimited work against a lock. Retain any already-earned overflow
  until round reset. Purchases happen between rounds, so it cannot instantly
  convert someone newly unlocked during active play.
- Recheck eligibility in the recruitment authority, not only target selection.
  Player/helper attempts cannot bypass a lock or pay twice for one listener.
  Helpers skip locked targets, retain their separate stats and retarget if the
  player converts their target first.

For the first mixed fixture, use ordinary conviction without new specialist
bonuses. Before mixing existing merchants with other types, define how the
merchant-only bonus is spent: it must benefit merchant work only, while unused
base conviction still carries forward. Keep current merchant groups unchanged
until that allocation has a tested rule.

### Avoiding dead ends and excessive repetition

Every mandatory inscription needs a repeatable income path using currently
eligible listeners, in both donations and available recruits. Test from zero
spendable balances as well as a carried wallet. Optional purchases may delay a
gate but cannot consume an irreplaceable item needed for it. High conviction
and a hard unlock are different barriers: more persuasion helps the former;
the named inscription resolves the latter.

Propose shared donations and available recruits across areas, preserving the
separate lifetime event total. No new currency is needed for the first town.
Repeated conversions still count events; an NPC role is not a permanently
owned person. Start with the existing audience reset policy, explicitly
provisional. Do not add idle income from previous areas in this slice.

Costs, specialist thresholds, map dimensions and future round lengths remain
unset until routes are tested. Begin the second-town experiment with the
existing 11-second timer and the actual carried build. Test a compact district
before enlarging it: more empty walking is not the intended difficulty.
Do not change Bramblewick's timer or promise a whole-town clear in that time.

Record measured conversions, travel time, speaking time and remaining time in
[PACING](PACING.md). Compare entry build, one audience unlock, both unlocks,
full area ranks and incomplete/nonoptimal routes. Include human reaction and
steering allowances; a scripted route alone cannot establish the final pace.

## 6. Data contracts and validation

These are proposed contracts, not new production files or supported effects.

| Resource | Proposed contents | Validation/owner |
| --- | --- | --- |
| Area definitions | Stable area ID, entry point, layout, gathering placements, circle membership and destination requirements | Validate IDs, references, entry reachability and area dependency cycles before activation |
| NPC profiles and group rosters | Stable slot/profile IDs, display role, threshold, donation and optional required upgrade/rank | Positive finite thresholds, bounded rewards, valid rank references, unique slots and supported group capacity |
| `data/upgrades.json` | Actual implemented audience unlocks, area membership and existing rank contracts | Progression owns supported effects, prerequisites, both costs and stale/max-rank protection |
| Save snapshot | Active/unlocked areas and persistent ranks; see next section | Progression validates the entire candidate before applying it |

Use authored deterministic rosters first. Validate that mandatory gates have
reachable funding routes; graph acyclicity alone does not prove affordability.
Reject invalid area/roster content with a visible error rather than granting
access or partially loading it. Keep current gameplay usable where possible.
Preserve existing upgrade IDs; give future IDs an area prefix when authored.
Never seed the real catalog with the candidate inscriptions in this plan.

## 7. World, progression and persistence

**World:** make the larger town a set of compact connected districts, with
clear paths and useful shortcuts. Use feet origins, Y sorting, layer-2 props
and the existing layer-1 player. Camera framing must keep nearby route choices
legible. Props must not create invisible entry or helper path obstructions.

**Carry-over proposal:** keep all earned purchases. Portable stat benefits and
the helper remain available when travelling. World and encounter unlocks stay
attached to their authored area: Meadow/East Lane/merchant spawns and Town
Debate must not reproduce Bramblewick's groups or opponents in the new town.
Returning to Bramblewick restores those local benefits. Define the scope of
every new effect explicitly; audience introductions initially apply to their
own area. Use local audience access and layout
to create progression before adding more general stat tiers. Bramblewick's
late-game build must be the second town's tested entry build, not fresh-save
stats. Shared wallets and returning to easy areas may make farming too strong;
measure reward per round before deciding rewards, costs or any alternative.

**Save plan:** area support needs a versioned migration from the current schema
3, not extra unchecked fields. Older schema-1/2 paths must still preserve
their existing migration results. Old saves default to Bramblewick, retain
all stable ranks, donations, both recruit counters, round and encounter stage.
Derive access to the next area from the implemented travel rule. Reserve the
actual next schema and field names during implementation.

Persist active area, valid unlocked destinations if stored, and per-area
encounter/objective progress only where implemented. Circle completion remains
derived from ranks, scoped to the area; avoid a second inconsistent completion
flag. Per-listener recruitment, partial phrases, conviction, helper targets and
remaining time stay transient. Revisiting starts fresh audiences between rounds.

Prepare the destination scene, roster, collision and entry in an inactive state
before committing travel. Keep the current world until preparation and the
staged save succeed. Activation then switches prepared state without another
file load or reward. Preparation/save failure leaves both runtime and saved area
unchanged. If activation can still fail after commitment, implement and test an
explicit validated rollback or backup-recovery path with a visible notice;
never silently leave runtime and saved active areas inconsistent.

Use staged writes, backup recovery and candidate validation for purchases too;
failed purchases spend neither resource. Newer unsupported saves remain
preserved. Exercise migration and failures with isolated fixture saves, never
ordinary player progression.

## 8. Candidate levels and assets

The following six settings are an idea pool, not a six-level production promise.
Every example roster has five listeners; its first three are approachable and
its last two illustrate potential unlocks. Other groups should vary the mix.

| Candidate | Layout and defining choice | Example group: open three; locked two | Possible unlocks and closing objective |
| --- | --- | --- | --- |
| **Larger market town: Bellmarket** | Market square, guild lane and civic steps; choose a dense modest-income route or a longer specialist route | Baker, porter, shopper; guild artisan, town clerk | Guild Introduction / Credible Testimony; persuade the town speaker at the council steps |
| **Noble garden gathering: Rosecourt** | Compact manor terraces, hedges and salon circles; introductions reveal valuable listeners across nearby groups | Gardener, musician, attendant; minor noble, patron | Courtly Etiquette / Patron's Introduction; win over the host before their closing toast |
| **Harbour and docks: Tidemouth** | Parallel quays linked by a few crossings; plan a loop instead of retracing a long pier | Dockhand, fisher, cook; ship captain, customs officer | Seafarers' Stories / Trade Credentials; persuade the harbourmaster |
| **Travelling lantern fair** | Radial lanes around a performance ring; fixed, signposted intervals make different stalls attractive | Visitor, food seller, stagehand; performer, ringmaster | Shared Refrain / Backstage Introduction; gather support for the closing procession |
| **University and observatory** | Two courtyards connected by a library path; choose quick student groups or sustained scholarly conversations | Student, gardener, bookbinder; lecturer, astronomer | Reasoned Doctrine / Celestial Signs; convince the rector at the observatory |
| **Hilltop pilgrimage abbey** | Terraced paths and a broad central stair; choose a quick outer circuit or a committed ascent | Pilgrim, cook, groundskeeper; archivist, abbess | Shared Tradition / Sacred Testimony; persuade the abbess in the upper courtyard |

Keep their mechanical differences bounded:

- **Bellmarket** teaches mixed eligibility on stationary groups. Its scale comes
  from districts and route choice, with no new moving-audience system.
- **Rosecourt** emphasizes introductions and richer donations in a compact event.
  The toast is presentation for the round boundary, not a real-time appointment
  or missable campaign deadline. The event can be replayed.
- **Tidemouth** adds route topology. Start with stationary audiences and bridges;
  moving boats and timed departures are unnecessary for its first version.
- **The fair** is the first candidate for scheduled audience behavior. Keep basic
  listeners available throughout; announce specialist windows and allow retries.
  Defer it if windows produce waiting rather than decisions.
- **The university** could reuse opening objections or unattended conviction
  decay for selected scholars, after eligibility is readable. Avoid stacking
  both on ordinary group members in its first experiment.
- **The abbey** could combine mastered introductions, sustained speech and helper
  assignment across terraces. Treat it as a later capstone; do not require new
  combat, forced movement or unavoidable movement penalties.

Recommended sequence to evaluate: **Bramblewick -> Bellmarket -> Rosecourt**.
Then compare harbour versus university for the next distinct experience. The
fair and abbey remain later candidates until their extra mechanics earn a place.

Use original procedural role props initially: apron, parcel, ledger, tool belt,
fan or telescope, with silhouettes and text cues rather than coat colors alone.
No new assets are supplied here. Future art needs provenance, license and local
pixel inspection; preserve originals and the [reference blocker](reference/README.md).
The playable places must remain scene objects, never mockup backgrounds.

## 9. UI, screen flow and accessibility

| Phase | Player decision and main focus | Minimum supporting information | More detail/access |
| --- | --- | --- | --- |
| Active mixed group | Stay to speak or choose another route; world dominates | Recruitment count and current eligible/locked status beside the group | Inspect the group for role names and exact missing inscriptions |
| Group with only locked listeners left | Move on or inspect why | For example, `3/5 recruited - 2 need introductions` with lock shapes | Show `Artisan: Guild Introduction` and `Clerk: Credible Testimony`; no hover requirement |
| Ritual selection | Choose an audience unlock | Actual affected roles/groups, next-rank costs and prerequisites | Keep details stationary beside the purple node circle |
| Destinations between rounds | Enter another available area or return | Area name, availability and current-area marker | Visible travel/return controls; failed-save reason alongside travel |

Distinguish eligible, recruited and locked states by icon/shape and text. A
resistant but eligible NPC shows progress, never the hard-lock mark. Locked
listeners can react visually, but must not display a filling persuasion bar.
Inspection must not consume a timed phrase or set a movement destination.

Keep persistent HUD additions minimal. Test mouse and touch inspection and
keyboard access without suppressing movement or fixed Tab/Esc navigation.
Retain graph transformed hit testing and the separate 144-node fixture.
Review 1280 x 800 and the existing tablet landscape case with actual captures;
small-phone readability remains an open limitation, not a new support claim.

## 10. Godot feature mapping

Reuse `CharacterBody2D`, `Node2D`/Y sorting, `Camera2D`, `CanvasLayer`, controls,
signals, JSON validation and `FileAccess`/`DirAccess`. Area scene/data loading
and typed listener requirements are proposed additions. Existing cloth,
audio and movement remain independent of area progress. No new framework,
engine version, tools or export platform is needed to prototype this plan.

## 11. Implementation ownership

| Current owner | Proposed extension |
| --- | --- |
| `gathering.gd` | Per-slot profiles/eligibility, thresholds, ordinary overflow, shared authoritative conversion and local feedback |
| `main.gd` | Select eligible audiences; coordinate area setup, travel, round resets and reward routing |
| `helper.gd` | Use the same eligibility query and conversion guard, with its own pace and safe retargeting |
| `progression.gd` | Validate new data/effects, audience requirements, area-scoped circles, purchases and save migration |
| `ritual_screen.gd` | Show local circle, affected audiences and destination intents; never own unlock/save decisions |
| `village.gd` and area scenes/data | Layout, entry points, props and collision; extract reusable area loading only when needed |

The current `first_unconverted`, shared `npc_type`/threshold and helper target
selection cannot express these rules as-is. A cosmetic NPC change alone would
not implement mixed audiences. See current ownership in
[ARCHITECTURE](ARCHITECTURE.md); update that record when implementation lands.

## 12. Open decisions and risks

| Decision | Starting recommendation | Evidence needed |
| --- | --- | --- |
| First extension and ordering | Larger town first, noble event next | Small mixed-group playtest, then compare route variety |
| Gate density | Mix 5-open, 4+1 and 3+2 groups | Can players explain where to go next without constant inspection? |
| Unlock identity | Shared role introductions that affect several groups | Does each purchase change a route rather than merely remove one obstruction? |
| Carry-over and farming | Retain earned benefits and shared wallets | Entry/return routes, reward rates and time to first useful purchase |
| Round length and map scale | Test 11 seconds in a compact town district first | Actual completions and human steering margin; expand only with evidence |
| Area completion | Area-local full circle opens onward travel | Check missing ranks, old completed saves and separation from encounter victories |
| Retrofits and audience lifecycle | Keep original route and repeatable earnings | Separate decision before mechanical changes to Bramblewick or permanent populations |
| Merchant bonuses in mixed groups | Defer mixing them in the first fixture | Typed bonus allocation preserves base overflow without leaking specialist bonuses |

## 13. Delivery slices and acceptance

These are future implementation steps. None is complete or an instruction to
build all six candidates now. Global milestone status remains in
[MILESTONES](MILESTONES.md).

| Slice | Reviewable outcome | Required evidence |
| --- | --- | --- |
| 1. Mixed-audience fixture | One isolated five-person group with 3 open + 2 independent requirements, per-role feedback and helper support | Actual 3/4/5 eligibility; locked-first ordering; no gate bypass/double rewards; overflow and expiry; useful human understanding |
| 2. Area travel and persistence | Bramblewick and a small town district, separate circles and safe return | Full-circle/missing-rank gates, repeated travel, failed saves, schema-1/2/3 migration, wallet/rank retention and movement in intermission |
| 3. Bellmarket playable slice | A bounded set of groups, two useful audience unlocks and one closing objective | Entry and upgraded routes; repeatable funding from zero balances; completed conversions/time margins; no old-route regression |
| 4. Noble-event experiment | Compact repeatable event using the proven mixed-audience system | Different route/economy decisions, readable introductions and retryable rounds; decide whether it earns the next production slot |
| 5. Select the next setting | Compare harbour and university greyboxes before further content | Human route variety, scope/art cost and measured pace; fair/abbey remain candidates |

For each behavioral slice run the installed-engine import and required suites
from the [development workflow](GAME_DEVELOPMENT_GUIDE.md#5-verification-workflow),
including progression, smoke and real-motion pacing. Extend meaningful coverage
for the new rules. Preserve the original opening route, full original-core
15-listener clear and incomplete/nonoptimal comparisons.

For changed UI/worlds, run `tests/capture_starter.gd` with a rendering display
and inspect actual PNGs. Exercise round -> ritual -> next round, movement and
Tab return, both-resource affordability, prerequisites, max/stale requests,
save recovery and graph pan/zoom with the large fixture. Record diagnostics,
human uncertainty and evidence in VERIFICATION/PACING. Commit each complete,
validated slice locally before starting the next. Publishing remains separate.
