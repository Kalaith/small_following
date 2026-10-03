# Small Following - UI style and review

This document turns the [visual direction](VISUAL_DIRECTION.md) into screen
and interaction guidance. Read it with [GAME_DESIGN](GAME_DESIGN.md) and
[CODE_STANDARDS](CODE_STANDARDS.md). The village dominates active play; the
purple ritual is a separate, intentionally large intermission.

## 1. Screen brief

Before a substantial screen change, record the current decision, dominant
focus, primary action, supporting facts, deferred information, layout and
input/feedback in the design proposal. The current baseline is:

| Phase | Decision and primary action | Dominant focus | Supporting information | Deferred information |
| --- | --- | --- | --- | --- |
| Active round | Choose a gathering; move into speaking range | Village routes, cultist and listeners | Time, donations, recruitment count and local phrase progress | Upgrade details appear between rounds |
| Ritual | Compare the selected next rank and buy if useful, or start another round | Connected purple node circle | Wallet, rank, current-to-next effect, cost and prerequisite | Other node details appear on selection |
| Village between rounds | Walk and inspect, return to ritual or start next round | Visible village with earning stopped | Round-complete state and Tab/Enter guidance | Ritual details return with the ritual |

There is no implemented title screen, settings screen or town selector.
Describe new screens as proposals until built and verified.

## 2. Composition and information hierarchy

Give each phase one clear focal area. During active play, keep the persistent
HUD compact and let routes and listeners occupy most of the screen. Place
speech feedback beside the affected group. Keep detailed upgrade information
in the intermission.

Use scale, contrast, spacing and alignment before adding boxes. Reserve strong
emphasis for actionable information and meaningful changes. Avoid repeating
the same counter or instruction in several panels. Place costs and disabled
reasons beside the relevant action. Utilities should not compete with play.

For an existing screen, first remove duplicate facts, redundant headings and
unnecessary borders. Recompose the remaining content and camera framing.
Add a new persistent element only when it helps the current decision.

## 3. Village and character feedback

Use warm ground/house colors, readable footpaths and clear gathering spaces.
The purple cultist needs a distinct hood, face and robe at gameplay scale.
Feet origins, Y sorting and collision footprints must agree visually.

The robe trails travel and settles at rest, including after upgraded movement.
Recruitment feedback belongs near the listener or gathering. Current state
must remain understandable after a temporary animation ends. Use text or
shape along with color for important distinctions.

Keep labels accurate: cumulative recruitment is a count of events, including
repeat conversions. Do not describe it as the number of unique villagers
following the cultist.

## 4. Ritual geometry and rank states

The visible node circles and prerequisite connections form the occult seal.
Use rings, intersecting lines and restrained rune-like marks to support that
network. Preserve the purple/violet/lilac direction and the original nine-node
core. The expanded catalog adds seven single-rank nodes across five rings.
The original tier-III nodes retain two ranks. At fitted overview zoom, short
node captions and rank pips keep glyphs clear; selected details always show
full names, ranks, effects and prices. Zooming in reveals full graph labels.

Current colors in `scripts/ritual_screen.gd` provide a starting palette:

| Token | Hex | Role |
| --- | --- | --- |
| `INK` | `#110d1c` | Dark ground |
| `PANEL` | `#191124` | Detail surface |
| `LINE` | `#66468d` | Quiet graph structure |
| `VIOLET` | `#a873eb` | Emphasis |
| `LILAC` | `#d7b9ff` | Bright geometry and labels |
| `MUTED` | `#9786af` | Secondary text |
| `WHITE` | `#f1e5ff` | Primary text |

These are existing implementation values, not measured contrast guarantees.
Judge readability in rendered frames at the actual display size.

| Node state | Required information |
| --- | --- |
| Locked | Missing prerequisite and current rank |
| Unaffordable | Exact next cost and available donations |
| Available | Next rank, cost and effect |
| Partly ranked | Current/maximum rank and the remaining purchase |
| Maximum rank | Clear completion label; purchase unavailable |
| Selected | Visible focus and matching stationary details |

Rank pips and text must remain readable over decoration. Keep selected details
outside the moving graph, including current-to-next stats and maximum-rank
messaging. A rectangular details area is useful support; the upgrade network
itself remains a circle of connected nodes.

## 5. Input and discoverability

Preserve WASD/arrows/left-stick movement even when ritual controls have focus.
Tab returns to the village between rounds and reopens the ritual. Enter/next
round and U/Inscribe use the same validated actions as their gamepad bindings.
The README owns the complete current control table.

Graph selection currently uses the mouse. Drag empty space with the left
button, or use the middle button, to pan; wheel zoom anchors at the pointer.
Recenter must recover a useful view. Verify that dragging does not accidentally
select/buy, and that drawing and hit testing agree after transforms.

Show the reason an action is unavailable. Required information must be
available on selection rather than hover alone. Keep teaching short and name
the actual button or gesture. If help is expanded in future, provide a visible
way to reopen it rather than leaving long instructions across play.

Keyboard/gamepad graph traversal, input rebinding and touch controls are
outstanding work. Physical gamepad behavior is unverified. A future touch
target needs visible movement, selection, navigation and dismissal controls;
the current desktop prototype does not establish touch support.

## 6. Viewport and layout

The configured base viewport and initial window are **1280 x 800** with
`canvas_items` stretch. The world is **1560 x 1100**. Existing capture evidence
covers 1280 x 800. A minimum supported window size and alternate aspect-ratio
acceptance have not been established.

For resize work, record candidate sizes and inspect each before calling them
supported. Keep the primary action and selected details reachable; reflow or
defer secondary content before shrinking text. Exercise long labels, larger
wallet values, dense graphs and expanded details. Check camera framing and
pointer alignment after resize and display scaling.

Use Godot anchors/containers for controls and a shared transform for graph
drawing/picking. A screenshot without overlap does not establish readable text
or comfortable click targets.

## 7. Visual and interaction review

Use the [capture command](GAME_DEVELOPMENT_GUIDE.md#5-verification-workflow)
with a rendering display. Inspect actual PNG output. Match the affected states
to the existing evidence:

| State | Stable capture |
| --- | --- |
| Village and local speech | `verification/starter-runtime.png` |
| Moving robe | `verification/starter-moving.png` |
| Ritual after round end | `verification/starter-summary.png` |
| First purchase | `verification/ritual-purchased.png` |
| Available second rank | `verification/ritual-rank-available.png` |
| Maximum rank | `verification/ritual-rank-max.png` |
| Full village conversion | `verification/village-full-clear.png` |
| Next round | `verification/starter-next-round.png` |
| Large fixture and distant selection | `verification/ritual-144-fixture.png`, `verification/ritual-fixture-focus.png` |

Also exercise locked/unaffordable states, save-error notices, Tab return,
movement with the ritual open, pan/zoom and selection. The capture sequence
does not replace interactive testing of those paths. The fixture is test
content, not a promise of more than 100 implemented upgrades.

- [ ] The current decision and action are clear, with the village or ritual dominant.
- [ ] Each persistent fact helps the current phase and has one clear home.
- [ ] Text, rank marks, costs and selected details are readable.
- [ ] Locked, available, partial and maximum states have cues beyond color.
- [ ] Motion, sorting and collision look consistent; robe movement settles at rest.
- [ ] Direct movement and round/village/ritual transitions remain usable.
- [ ] Pan, zoom, recenter and transformed selection work on both graph sizes.
- [ ] Relevant failure states remain understandable and actionable.
- [ ] Reviewed sizes, input methods, actual evidence and limits are recorded.

Update [VERIFICATION](VERIFICATION.md) with what was actually observed. Keep
headless behavior checks, rendered inspection and human playtesting distinct.
Supplied references remain subject to the [transfer blocker](reference/README.md).
