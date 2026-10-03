# Small Following - ritual readability pass

This records the earlier sixteen-node readability scope. The current
32-node authored magical-seal composition and completion centre are documented
in [RITUAL_COMPLETION](RITUAL_COMPLETION.md); its presentation supersedes the
uniform outward-sector placement below while retaining these navigation and
prerequisite-feedback principles.

## 0. Scope and decision status

**Date:** 2026-10-03. The user approved this presentation pass after reviewing
the expanded ritual. The current design remains [GAME_DESIGN](GAME_DESIGN.md).

**Confirmed direction:** keep the purple occult circle and useful right-hand
details while making progression easier to trace. Words occupies the top,
Running the left, Creed the right, and village invitations/helpers the lower
sectors. Successive tiers progress outward within their sector. Quiet the
decorative rings, runes and central sigil. Show main branch paths by default;
reveal cross-branch requirements when a node is hovered or selected. Selection
emphasizes its prerequisite ancestry and dims unrelated paths. Use node shape,
fill and brightness as well as color to distinguish purchase states.

**Implemented baseline:** sixteen nodes and nineteen purchasable ranks,
including Words I-V, Running I-V, Creed I-III, both gathering invitations and
Helping Hand. Preserve every ID, rank, price, prerequisite, effect and save.

**Provisional presentation choices:** precise sector spacing, label thresholds,
line opacity and focus zoom are implementation choices to inspect in real
renders and revisit after human use. No economy or timing tuning is included.

**Boundary:** view layout, navigation, state feedback, tests and documentation.
No new upgrades, mechanics, production art, save fields or exported release.

## 1. High concept

The cultist follows a readable path through a violet ritual, sees which
inscription is useful next, and can inspect the requirement that blocks it.
This remains a cute incremental prototype using Godot 4.2.2, GDScript and
Compatibility rendering. This pass does not select an export platform.

## 2. Design pillars and invariants

| Pillar | Player-visible behavior | Acceptance evidence |
| --- | --- | --- |
| Stable branches | Each branch stays in one sector as tiers move outward | Current-catalog render and position checks |
| Relevant connections | Main paths remain legible; focus reveals the selected ancestry | Hover/selection checks including cross-branch requirements |
| Legible purchase states | Shape/fill and labels explain locked, available, partial and complete nodes | Mixed-state render and authoritative purchase regressions |
| Navigable scale | An overview reveals branches and major unlocks; visible navigation reaches detail | Separate 144-node fixture, focus and transformed picking checks |
| Preserved game | Movement, round transitions, balance and saved ranks behave as before | Existing integration, progression, pacing and helper suites |

## 3. Core loop and transitions

The round, ritual and next-round transitions are unchanged. Round end stops
earning and opens the ritual; Tab returns to the village or reopens the graph.
Direct movement continues throughout. Selection and navigation alter only the
view. An inscription still requests one validated next-rank purchase, and
Enter starts the next round through the existing action path.

## 4. Player role and verbs

The player remains the directly controlled cultist. In the ritual, pan, zoom,
recenter, select, inspect and inscribe remain available. Branch/overview
navigation must be visible so distant or reduced-detail nodes are reachable.
Required information remains available through selection rather than hover
alone. The [README controls](../README.md#run) describe the delivered inputs.

## 5. Systems, economy and timing

This pass changes no phrase frequency, conviction, movement, helper behavior,
audiences, price, rank limit or round duration. Existing numerical assumptions
and route results remain owned by [PACING](PACING.md). Visual emphasis must not
imply that a locked cross-branch requirement is optional.

## 6. Data contracts and validation

`data/upgrades.json` remains the unchanged catalog authority. Branch and ring
metadata guide view placement; any presentation mapping belongs in the view,
not a rewritten economy definition. Catalog validation and schema-2 saves
remain owned by `progression.gd`. A view must not grant a rank or infer its
purchase permission from color, line visibility or button state.

## 7. World, progression and persistence

No world or persistence change is proposed. Hover, selection, branch focus,
pan and zoom are transient UI state. Keep test saves isolated and retain the
schema-1 migration, staged writes and recovery rules in
[ARCHITECTURE](ARCHITECTURE.md#local-progression-and-recovery).

## 8. Content and assets

The production catalog stays at sixteen implemented nodes. The separate
144-node fixture remains test content. Drawing is procedural Godot geometry;
no generated image or reference screenshot becomes a runtime background.

The parent inspected Library screenshot
`libfile_b5183875d7d08191815ac53c33cbeb62`, filename
`image(20261003-043158).png`, and supplied its visual description. Its pixels
are not available on this Windows executor because of the existing supported
transfer blocker. Local before/after claims must use actual rendered frames,
not imply local pixel matching to that reference. See
[reference status](reference/README.md).

## 9. UI, screen flow and accessibility

| Phase | Decision/action | Dominant focus | Supporting facts | Deferred information and access |
| --- | --- | --- | --- | --- |
| Ritual overview | Choose a branch or major unlock | Ordered violet sectors and main progression paths | Branch identity, purchase-state cues, visible navigation | Detailed labels through zoom/focus; full facts on selection |
| Focused selection | Compare and purchase the next rank | Selected node and relevant ancestry | Fixed right panel: rank, current-to-next effects, cost and missing requirements | Unrelated crosslinks recede until relevant |

Retain the 1280 x 800 capture baseline. A minimum supported size remains open.
Keep the detail panel stationary and readable while graph transforms change.
The overview must not hide interactive state without a visible route to it.
Use reduced detail deliberately at scale; reveal labels as the player focuses
or zooms in. Preserve an understandable maximum-rank state and unaffordable
reason. Keyboard/gamepad graph traversal and touch support remain separate
work; visible mouse navigation does not establish those capabilities.

## 10. Godot feature mapping

Keep the existing `Control` hierarchy and custom graph drawing, sharing one
coordinate transform between rendering and picking. Use ordinary UI controls
for branch navigation and existing action signals for purchases/transitions.
No plugin, engine upgrade, image asset or additional framework is needed.

## 11. Implementation ownership

| Owner | Bounded change |
| --- | --- |
| `scripts/ritual_layout.gd` | Presentation-only branch sectors and outward ring placement |
| `scripts/ritual_screen.gd` | Decoration hierarchy, edge visibility, state drawing, overview/focus navigation |
| `tests/` | Real input/transform regressions, current-catalog and large-fixture coverage, actual viewport captures |
| `docs/UI_STYLE.md`, `docs/ARCHITECTURE.md`, `README.md` | Delivered presentation, controls and ownership |
| `docs/VERIFICATION.md` | Exact checks, inspected captures and limitations |

`main.gd` and progression retain purchase authority. The catalog, player,
gatherings, helper, pacing and saves are regression targets, not redesigns.

## 12. Open decisions and risks

Human use must establish whether branch focus, quiet paths and label density
remain comfortable on a much larger authored tree. A capacity fixture cannot
prove that future content is understandable. Review dense labels, long names,
pointer targets and alternate window sizes before claiming broad support.
Keep outstanding acceptance and accessibility work in [TODO](../TODO.md).

## 13. Slices and acceptance

| Slice | Outcome | Required evidence |
| --- | --- | --- |
| Layout and path hierarchy | Current branches are coherent; focus exposes real requirements | Current-catalog input checks and overview/selection renders |
| Scale and navigation | Overview reaches branches and distant detail without lost state | 144-node focus, pan/zoom/recenter and transformed picking checks |
| Regression and handoff | Existing gameplay, purchases and saves remain intact | Required suites, catalog preservation, inspected captures and current documentation |

Record results only after running the checks in
[VERIFICATION](VERIFICATION.md); this approved brief is not verification.
Human playtesting and the existing editor/import limitation remain distinct
from script and rendered evidence. Local changes do not authorize publishing
or software installation.
