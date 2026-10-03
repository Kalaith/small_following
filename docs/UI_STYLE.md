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
| Ritual overview | Find a branch or major unlock, then inspect it | Composed purple seal, distinct branch constellations and main paths | Branch identity, purchase-state cues and visible navigation | Focus/zoom reveals more labels; selection opens full details |
| Ritual selection | Compare the next rank and buy if useful, or start another round | Selected node, prerequisite ancestry and stationary details | Wallet, rank, current-to-next effect, cost and missing requirements | Unrelated cross-branch paths appear only when relevant |
| Completed ritual | Inspect the lit centre or keep playing | Filled violet/lilac centre with a visible Open control | Completion means every current catalog rank is bought | Exact demo message appears on activation |
| Demo message | Dismiss and continue | Exact text: This is the end of the demo | Keep playing button and Esc/Tab/Enter hints | The next area's separate circle remains future work |
| Village between rounds | Walk and inspect, return to ritual or start next round | Visible village with earning stopped | Round-complete state and Tab/Enter guidance | Ritual details return with the ritual |
| Settings | Adjust sound/fullscreen or key bindings, then return | Centered violet panel with Sound & display and Key mapping tabs | Percentages, bindings, conflicts, save status and continuing-timer reminder | Game/upgrade details remain behind the dimmed backdrop |

The settings screen brief and transitions are documented in [SETTINGS](SETTINGS.md).
There is no implemented title screen or town selector.
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

The visible nodes and progression paths form a composed occult seal. The
current eight branch constellations have different silhouettes: Words crescent,
Running broad left hook, Merchants compact loop, Trials diagonal fork, Creed
right curl, Faith lower fork, Village diagonal pair and Followers satellite.
Keep the sequence readable through actual prerequisite paths; a deliberate
local loop can bend inward. Catalog tiers are not mandatory drawing radii.
The 32-node catalog spans six tiers and retains two ranks on the original
tier-III nodes. Layout changes no catalog rules. See the
[readability brief](RITUAL_READABILITY.md) and
[full-circle scope](RITUAL_COMPLETION.md).

Use coherent concentric rim bands, regular invented inscriptions and ticks,
broken interior arcs and quiet offset satellite seals to unite the branches.
The current satellites use a ring/diamond, spiral and four-petal motif. Avoid
arbitrary strokes or repeated identical spokes. Draw ornament below real
paths, nodes and opaque label backgrounds. The central pentagram medallion
is muted until all ranks are bought; only completion earns its strong fill
and glow. These motifs decorate existing content and never imply extra
purchasable nodes or prerequisites.

Decorative lines must not compete with prerequisite edges. Show same-branch
progress by default. On hover or
selection, expose the relevant recursive prerequisite path, including
cross-branch edges, and dim unrelated paths. Hover previews a path without
replacing the selected details; leaving the graph returns to the selection.
Missing requirements stay explicit in the right-hand panel.

Route long links around intervening node silhouettes so they do not imply a
connection to a node they merely pass. Authored detours preserve the real
endpoints, dashed crosslink treatment and direction arrows; they add no
prerequisites.

At a distant overview, prioritize branch identity, state cues and major
unlocks over a wall of captions. Reveal individual labels as the player
focuses or zooms in. Nodes whose captions are reduced must remain reachable
through visible navigation, and full names, ranks, effects and prices must
remain available in the selected details. Check label collisions against the
actual drawing transform, including selected and hovered labels.

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

| Node state | Required visual cue and information |
| --- | --- |
| Locked | Dim diamond and central bar; missing prerequisite and current rank in details |
| Unaffordable | Hollow circle distinct from locked; exact next cost and donation shortfall |
| Affordable | Bright circle and plus mark; next rank, cost and effect |
| Partly ranked | Inner progress arc, with earned/open rank pips in detail views; current/maximum rank and next purchase |
| Maximum rank | Filled circle and check mark with a clear completion label; purchase unavailable |
| Selected | Extra focus ring and corner marks with matching stationary details |

Use a visible legend to explain state marks. Color alone must not distinguish
affordable, unaffordable, locked and complete nodes. Rank pips and text must
remain readable over decoration. Keep selected details
outside the moving graph, including current-to-next stats and maximum-rank
messaging. A rectangular details area is useful support; the upgrade network
itself remains a circle of connected nodes.

The centre stays quiet while any catalog rank is missing. With every rank
purchased, a bright filled seal, lilac rim and glow identify its clickable
state. This is distinct from the Priest's saved Bramblewick-complete message.
Keep the fixed **Inner circle lit / Open** control reachable below the graph
when the centre has been panned out of view. Its incomplete state is disabled
and explicitly says **Inner circle / Earn every rank**. Do not add catalog
nodes or change purchase balance to make the circle appear fuller.

## 5. Input and discoverability

Preserve WASD/arrows/left-stick movement even when ritual controls have focus.
Tab returns to the village between rounds and reopens the ritual. Enter/next
round and U/Inscribe use the same validated actions as their gamepad bindings.
The README owns the complete current control table.

Graph selection currently uses the mouse. Drag empty space with the left
button, or use the middle button, to pan; wheel zoom anchors at the pointer.
Recenter must recover a useful view. Verify that dragging does not accidentally
select/buy, and that drawing and hit testing agree after transforms.

The branch selector above the graph focuses Words, Running, Creed, Village,
Followers, Merchants, Trials or Faith. Smaller catalogs use branch buttons. They show owned nodes/total nodes and a `+` when a rank is affordable;
their tooltips give the exact ready count. With more than six branches, a
dropdown provides branch names and owned/ready counts. The node list below
the graph exposes every upgrade in the selected branch, with its full title,
rank and purchase state, including locked entries. Choosing an entry selects
and centers it at a readable scale. **Focus selected** recovers the current
node after panning; **Recenter** fits the graph while retaining the selection.
**Overview** clears selection/hover and fits the complete branch view. With
no selection, the right panel invites a choice and purchasing is disabled.
These controls provide a visible route to nodes whose graph captions are
reduced at distance.

Clicking the completed centre or its fixed button shows **This is the end of
the demo** with a **Keep playing** action. Esc dismisses this message before
opening settings; Tab returns to the village and Enter starts another round.
The settings button still works and closes the notice. Hiding or reconfiguring
the ritual clears the transient message. Reopening the centre is harmless and
does not grant a reward, save a flag or load another area. Movement remains
independent of the message. The future separate-circle transition is documented
in [the completion brief](RITUAL_COMPLETION.md).

Main progress lines are solid. Contextual cross-branch requirements use dashed
lines and arrowheads so they remain distinguishable from decoration and main
paths. Hover changes the path preview; selection controls the stationary
details and purchase request. Verify mouse exit clears the temporary preview.

Show the reason an action is unavailable. Required information must be
available on selection rather than hover alone. Keep teaching short and name
the actual button or gesture. If help is expanded in future, provide a visible
way to reopen it rather than leaving long instructions across play.

Keyboard/gamepad graph traversal, gamepad rebinding and touch controls are
outstanding work. Physical gamepad behavior is unverified. A future touch
target needs visible movement, selection, navigation and dismissal controls;
the current desktop prototype does not establish touch support.

Keyboard rebinding is available in Settings → Key mapping; [SETTINGS](SETTINGS.md)
owns capture, conflicts and reserved navigation rules. Runtime hints should use
the current Input Map binding rather than a hardcoded remappable key.

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
| Earlier round-end layout | `verification/starter-summary.png` |
| Current composed seal at entry | `verification/ritual-seal-entry.png` |
| First purchase | `verification/ritual-purchased.png` |
| Available second rank | `verification/ritual-rank-available.png` |
| Maximum rank | `verification/ritual-rank-max.png` |
| Full village conversion | `verification/village-full-clear.png` |
| Next round | `verification/starter-next-round.png` |
| Large fixture and distant selection | `verification/ritual-144-fixture.png`, `verification/ritual-fixture-focus.png` |
| Readable branch overview | `verification/ritual-readability-overview.png` |
| Selected and hovered prerequisite paths | `verification/ritual-readability-east.png`, `verification/ritual-readability-hover.png` |
| Dense Priest and Creed prerequisite paths | `verification/ritual-seal-priest-paths.png`, `verification/ritual-seal-creed-paths.png` |
| Mixed purchase states | `verification/ritual-readability-states.png` |
| Large-fixture branch navigation | `verification/ritual-fixture-branch.png` |
| Full circle with ranks missing | `verification/ritual-demo-incomplete.png` |
| Every rank purchased and centre lit | `verification/ritual-demo-ready.png` |
| Exact demo-completion message | `verification/ritual-demo-message.png` |
| Completed circle after dismissal | `verification/ritual-demo-dismissed.png` |

Also exercise locked/unaffordable states, save-error notices, Tab return,
movement with the ritual open, pan/zoom and selection. The capture sequence
does not replace interactive testing of those paths. The fixture is test
content, not a promise of more than 100 implemented upgrades.

- [ ] The current decision and action are clear, with the village or ritual dominant.
- [ ] Each persistent fact helps the current phase and has one clear home.
- [ ] Text, rank marks, costs and selected details are readable.
- [ ] Locked, available, partial and maximum states have cues beyond color.
- [ ] Branch constellations form a coherent seal, local loops retain a readable order, decoration recedes and real paths are distinguishable.
- [ ] Hover/selection reveals required crosslinks without changing the selected purchase details.
- [ ] Distant nodes remain reachable through visible navigation when overview labels are reduced.
- [ ] Motion, sorting and collision look consistent; robe movement settles at rest.
- [ ] Direct movement and round/village/ritual transitions remain usable.
- [ ] Pan, zoom, recenter and transformed selection work on both graph sizes.
- [ ] Centre readiness, transformed activation, fixed-button access and dismissal remain clear without implying Priest victory or a playable second area.
- [ ] Relevant failure states remain understandable and actionable.
- [ ] Reviewed sizes, input methods, actual evidence and limits are recorded.

Update [VERIFICATION](VERIFICATION.md) with what was actually observed. Keep
headless behavior checks, rendered inspection and human playtesting distinct.
Supplied references remain subject to the [transfer blocker](reference/README.md).
