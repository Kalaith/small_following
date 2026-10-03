# Godot game design template for Small Following

Use this structure for a substantial feature proposal or a deliberate future
revision of [GAME_DESIGN](GAME_DESIGN.md). The existing document remains the
current design. Fill prompts only for the requested scope; mark an unresolved
choice as open rather than inventing a user decision. A completed template is
a proposal until its direction is accepted and its implementation verified.

Keep detailed runtime ownership in [ARCHITECTURE](ARCHITECTURE.md), numerical
route evidence in [PACING](PACING.md), milestones in [MILESTONES](MILESTONES.md)
and completed checks in [VERIFICATION](VERIFICATION.md). Link to those records
instead of copying tables that will drift.

## 0. Scope and decision status

- **Proposal title/date:** <Name and date.>
- **Requested outcome:** <What the user wants the player to be able to do.>
- **Confirmed direction:** <Explicit decisions and where they were recorded.>
- **Provisional choices:** <Assumptions to test; include starting values.>
- **Implemented baseline:** <Existing behavior this proposal extends.>
- **Open choices:** <Unknowns and the evidence needed to resolve them.>
- **Scope boundary:** <What this change includes and what remains future work.>

For an actual port or asset replacement, add a carry-over table describing
what is retained, redesigned or removed, plus source/license and art costs.
Small Following is an existing Godot prototype; a web migration is not assumed.

## 1. High concept

- **Pitch:** <One to three sentences describing the play experience.>
- **Genre, perspective and tone:** <How the player sees and acts in the world.>
- **Audience and scope:** <Intended players; prototype, slice or release.>
- **Engine baseline:** Godot 4.2.2, GDScript, Compatibility rendering.
- **Platform evidence:** <Editor/native environments actually checked.>
- **Export target:** <Unselected unless separately decided and verified.>

## 2. Design pillars and invariants

List three to five observable principles and how each will be checked. Preserve
the root [project invariants](../AGENTS.md): direct cultist control, a dominant
village during play, a separate purple node-circle ritual, distinct upgrades,
conviction overflow and honest pacing/content claims.

| Pillar | Player-visible behavior | Verification |
| --- | --- | --- |
| <Principle> | <What the player can observe/do> | <Test or playtest scenario> |

## 3. Core loop and transitions

Write the repeated loop as numbered actions. For each transition, state its
trigger, state changes, preserved state and available player input.

| From -> to | Trigger | Reset/preserve | Movement and earning |
| --- | --- | --- | --- |
| <Phase transition> | <Input/event> | <Exact fields> | <What continues/stops> |

Keep round activity independent from ritual visibility. Explain how the player
returns to the village between rounds and how the next round starts.

## 4. Player role and verbs

- **Player role:** <The little robed cultist; explain any added ability.>
- **Direct controls:** <Movement and action vocabulary.>
- **Automatic behavior:** <Speech or future helper actions and their limits.>
- **Input paths:** <Input Map actions, visible controls and device coverage.>
- **Feedback:** <How the player knows the action happened or was rejected.>

## 5. Systems, economy and timing

For each changed system, define values, units, ownership, formulas and limits.

| Value | Starting value/unit | Owner | Status/rationale |
| --- | --- | --- | --- |
| <Stat> | <Number and unit> | <Constant, catalog field or script> | <Confirmed/provisional and why> |

```text
<Formula, inputs, thresholds, overflow and boundary behavior.>
```

Explain the distinction between phrase frequency, conviction per phrase and
travel speed. For pacing changes, compare unchanged opening routes, practical
full-rank routes and incomplete/nonoptimal routes. Record actual conversions,
completion time and remaining time in PACING; visiting all groups is not a
clear. Keep reaction/steering uncertainty explicit and avoid special completion
rules. The current provisional baseline is an 11-second round.

Define what is deterministic and how any new randomness is owned and seeded
for repeatable tests. Do not introduce randomness merely to fill this section.

## 6. Data contracts and validation

| File/resource | Defines | Loader/owner | Validation and compatibility |
| --- | --- | --- | --- |
| `data/upgrades.json` | Current upgrade catalog | `progression.gd` | Stable IDs, supported effects, ranks, prices and prerequisites |
| <Proposed resource> | <Purpose> | <Existing/new owner> | <Types, bounds, references and failure behavior> |

Add schema examples only for resources the feature needs. Specify defaulting,
invalid-data feedback and whether existing saves reference the changed IDs.
Catalog schema 1 and save schema 2 are separate contracts. Keep the nine real
nodes and their rank limits unless the task explicitly changes that scope.

## 7. World, progression and persistence

- **World layout:** <Routes, feet origins, Y sorting and collision footprints.>
- **Progression:** <Unlock conditions and meaningful player choices.>
- **Saved state:** <Exact fields that survive restart; schema/migration plan.>
- **Transient state:** <Fields reset on round change or relaunch.>
- **Failure/recovery:** <Candidate writes, backup behavior and player feedback.>
- **Save fixtures:** <Isolated paths and protection of normal player progress.>

Keep the event total distinct from a unique follower population. Explicitly
define lifecycle/economy changes before introducing permanent followers,
additional towns, minions, magic or offline earnings.

## 8. Content and assets

| Content type | Implemented baseline | Requested addition | Future/undecided |
| --- | --- | --- | --- |
| <Type> | <Concrete count> | <Bounded count> | <Clearly separate scope> |

Record asset source/license, required dimensions/import choices, placeholder
status and actual local inspection. Original references are preserved; mockup
images never become the playable world. Capacity fixtures belong in tests.

## 9. UI, screen flow and accessibility

Complete the [UI_STYLE](UI_STYLE.md) screen brief for each affected phase:

| Phase | Decision/action | Dominant focus | Supporting facts | Deferred information and access |
| --- | --- | --- | --- | --- |
| <Phase> | <Player decision> | <World/graph/selection> | <Minimum facts> | <How to reveal more> |

- **Layout/camera:** <Normal size, proposed minimum and evidence for each.>
- **Input:** <Keyboard, mouse, gamepad; touch only if part of the target.>
- **Readability:** <Text scale, focus, state cues beyond color, long labels.>
- **Feedback/recovery:** <Success, unavailable actions and failures.>
- **Review states:** <Ordinary, selected, dense, maximum-rank and failure cases.>

The existing capture baseline is 1280 x 800; a minimum supported size remains
open. Do not label keyboard-only graph navigation or touch support complete
without implementing and exercising them.

## 10. Godot feature mapping

Choose engine features that serve this proposal. State whether each is already
used, proposed or unnecessary; do not add a framework solely to complete a row.

| Need | Godot/project mechanism | Status and reason |
| --- | --- | --- |
| Movement/collision | `CharacterBody2D`, Input Map, layers 1/2 | <Decision> |
| World/depth/camera | `Node2D`, Y sorting, `Camera2D`, reusable scenes | <Decision> |
| UI/layout | `CanvasLayer`, `Control`, containers, anchors | <Decision> |
| Ritual graph | Custom drawing and shared pan/zoom coordinate transforms | <Decision> |
| Action requests | Signals connected to the gameplay owner | <Decision> |
| Definitions | Existing JSON catalog; resources where justified | <Decision> |
| Persistence | Existing progression owner, `FileAccess`, `DirAccess`, `user://` | <Decision> |
| Animation/audio | Existing cloth code; built-in nodes when needed | <Decision> |
| Verification | Existing `SceneTree` suites and viewport capture script | <Decision> |

## 11. Implementation ownership

| Scene/script | Current responsibility | Proposed change | Inputs/outputs |
| --- | --- | --- | --- |
| <Path> | <Owner> | <Bounded change> | <Methods/signals/data> |

Describe where validation and mutation happen. Keep views separate from
purchase authority, movement separate from earning, and save fixtures separate
from runtime progression. Record any extraction only when the feature needs it.

## 12. Open decisions and risks

List the highest-impact unknowns, how to investigate each and what is blocked
by the answer. Keep confirmed direction separate from proposed tuning. Record
resolved decisions in the owning design document and keep TODO outstanding-only.

## 13. Milestones and acceptance

| Slice | Playable outcome | Behavioral checks | Visual/human checks | Exit evidence |
| --- | --- | --- | --- | --- |
| <Small complete change> | <Observable result> | <Rules/failures> | <States/routes/input> | <Recorded artifact/result> |

Use the [development verification workflow](GAME_DEVELOPMENT_GUIDE.md#5-verification-workflow).
List checks actually run, results and limitations. Update milestone status only
when its exit conditions are met. Publishing and tool installation require
separate scope; documentation does not authorize them.
