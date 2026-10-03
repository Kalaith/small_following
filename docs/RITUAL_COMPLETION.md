# Small Following - a full ritual circle

## Scope and decision status

Requested 2026-10-03: spread the existing inscriptions around more of the
circle, then light its centre when every current upgrade rank is purchased.
Clicking the completed centre shows the exact message **This is the end of
the demo**. The player can dismiss it and keep playing. In the future this
centre will lead to a new area's separate ritual circle; that area is outside
this change.

The layout slice uses the existing eight branch sectors with gentle outward
fans. The completion interaction is approved and planned for the next slice;
implementation and check results will be recorded in
[VERIFICATION](VERIFICATION.md).

The current production catalog remains 32 nodes and 35 ranks costing 1014
donations. Preserve every ID, price, rank, prerequisite, effect and save field.
The priest objective and its saved **Bramblewick complete** state remain
independent of buying every inscription.

## Layout and screen brief

The purple node network remains the focal area, with useful selection details
in the stationary right panel. Eight evenly spaced semantic sectors retain
Words above, Running left, Creed right, Merchants and Trials on the upper
diagonals, and Followers, Faith and Village below. Successive tiers sweep
gently through their own sector as they move outward. Same-tier siblings use
separate lanes. This fills the seal without adding nodes or inventing edges.

Ring metadata still controls radial depth. Unknown fixture branches keep
their authored sector, narrowing the fan when neighbouring sectors are close.
Decoration stays quiet; main branch edges remain visible and cross-branch
requirements appear on hover or selection. Preserve the branch/node pickers,
overview, recenter, pan, zoom and the existing state shapes.

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

## Acceptance and limits

Check incomplete progress, one missing second rank, the final purchase,
completed-save reload, repeated activation and dismissal. Also check empty or
invalid catalogs, purchase failures and independence from priest victory.
Exercise centre hit testing after pan/zoom alongside existing node selection;
retain the separate large fixture and purchase/save regressions.

Inspect actual incomplete, ready, message and dismissed viewport captures at
the baseline 1280 x 800 size. Human navigation and alternate-size review remain
separate from automated assertions. The supplied screenshot could not be
materialized through the supported Windows Library helper; local visual
decisions use fresh application captures. See [reference status](reference/README.md).

Future area names, unlock rules, travel, separate catalogs and persistence need
a later scoped design. This change only establishes the centre's eventual role.
