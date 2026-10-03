# Small Following - a full ritual circle

## Scope and decision status

Requested 2026-10-03: spread the existing inscriptions around more of the
circle, then light its centre when every current upgrade rank is purchased.
Clicking the completed centre shows the exact message **This is the end of
the demo**. The player can dismiss it and keep playing. In the future this
centre will lead to a new area's separate ritual circle; that area is outside
this change.

Implemented: eight authored constellations integrate the existing upgrades
into a composed purple seal, and a fully ranked catalog lights the clickable
centre. The completion message is dismissible and repeatable. Recorded checks
and actual captures belong in
[VERIFICATION](VERIFICATION.md); human usability and alternate-size acceptance
remain outstanding.

The user clarified that even spacing is insufficient: the intended visual
result is a composed purple magical seal with coherent concentric rings,
sigils, interlocking geometric motifs and integrated upgrade nodes. Keep
decoration quiet and real interactions and prerequisite paths clear, without
arbitrary visual noise. The authored composition replaces the interim fan
layout. The parent agent materialized and inspected all three new reference
images and provided an image-grounded brief for this authorized redesign.
Original pixels remain unavailable on this Windows
executor because supported Library materialization failed, but local transfer
is no longer a design blocker and no further retries are needed. This executor
uses fresh rendered application captures for verification. The completed-centre
interaction remains delivered and must be preserved.

The current production catalog remains 32 nodes and 35 ranks costing 1014
donations. Preserve every ID, price, rank, prerequisite, effect and save field.
The priest objective and its saved **Bramblewick complete** state remain
independent of buying every inscription.

## Current composition and screen brief

The purple node network remains the focal area, with useful selection details
in the stationary right panel. Words forms a crescent above the centre,
Running a broad left hook, Merchants a compact upper-left loop and Trials an
upper-right fork. Creed curls to the right; Faith forks below, Village forms
a diagonal pair and Followers sits within a small lower-left satellite.
These are authored positions for the existing stable IDs, not new content.

Thin nested inscription bands and a ticked outer rim contain the composition.
Broken interior arcs leave space for branches; offset satellites use a
ring/diamond, a spiral and four petals. The central source is a pentagram
medallion whose strong fill and glow appear only after all ranks are purchased.
Ornament is quiet beneath actual edges, node fills and label backgrounds.

The parent's reference brief identified three complementary ideas: varied
radial clusters around a luminous medallion; offset circles of unequal sizes
linked by narrow routes; and a near-black violet seal with nested guides,
rim ticks, a central pentagram and unequal curved/diagonal paths. The current
procedural geometry is an interpretation of those inspected references,
not a pixel copy or a claim of final human acceptance.

Catalog rings remain upgrade tiers; local loops may turn inward. Unknown
fixture content retains the scalable sector/ring fallback and receives no
production satellites. Main prerequisite edges stay visible and cross-branch
requirements appear on hover or selection. Branch/node pickers, overview,
recenter, pan, zoom and state shapes remain available.

| State | Decision/action | Feedback and retained access |
| --- | --- | --- |
| Ranks still missing | Inspect inscriptions and buy useful ranks | Centre remains quiet; normal graph and detail controls stay available |
| Every current rank bought | Inspect the lit centre | A visible completion cue and clickable centre identify the new action |
| Demo message open | Dismiss and continue | Exact requested message; no purchase, progression reset or area transition |

## Completion contract

The progression owner derives readiness from a successfully loaded, nonempty
catalog: every entry's current rank must equal its validated maximum rank.
Do not hardcode the present node/rank totals, count only owned nodes, or
substitute priest victory. The final successful rank purchase and an existing
completed-save reload must both make the centre ready. A failed purchase must
not light it.

No persistent completion flag or save schema change is needed. Message
visibility is transient. Reopening it repeats the same harmless information;
dismissing it preserves purchases, currency, opponents and round state.
Direct movement remains available, including with the ritual open.

`Progression.is_circle_complete()` owns the predicate. The ritual centre uses
the same pan/zoom transform as graph picking. The fixed **Inner circle lit /
Open** button provides access when the centre is outside the view; while
incomplete it is disabled and says **Inner circle / Earn every rank**.

**Keep playing** or Esc dismisses the message. Tab reveals the village; Enter
begins another round. Opening settings or hiding/reconfiguring the ritual also
closes the notice. Reopening the ritual keeps its completed appearance but
does not automatically reopen the message.

## Acceptance and limits

`tests/test_demo_completion.gd` covers incomplete progress, missing second
ranks, the final purchase, completed-save reload, repeated activation and
dismissal. It also checks an empty catalog, a newly added catalog entry,
purchase failures and independence from priest victory. Centre picking is
exercised after pan/zoom alongside the existing readability suite and isolated
purchase/save regressions. Catalog validation stays with the progression suite.

Actual baseline 1280 x 800 captures show [incomplete ranks](verification/ritual-demo-incomplete.png),
[the lit centre](verification/ritual-demo-ready.png),
[the exact message](verification/ritual-demo-message.png) and
[the circle after dismissal](verification/ritual-demo-dismissed.png).
Human art-direction acceptance, navigation and alternate-size review remain
separate from automated assertions. The originals were inspected by the parent;
supported Windows Library materialization remains unavailable here. Local
verification uses fresh application captures. See [reference status](reference/README.md).

Future area names, unlock rules, travel, separate catalogs and persistence need
a later scoped design. This change only establishes the centre's eventual role.
