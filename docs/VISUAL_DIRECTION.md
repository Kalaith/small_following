# Small Following - visual direction

## Reference status

The user liked a cute village mockup direction and supplied close and wide Library views. Their pixels could not be inspected on this Windows executor because supported materialization failed; neither original is present locally. See [reference provenance and recovery](reference/README.md).

Two further references establish the ritual's structure. The parent agent inspected them in the cloud and supplied this description: one is a dark red hand-drawn floor seal with concentric circles, intersecting stars/polygons, perimeter ticks and small candles; the other is a luminous red-on-black seal with a central thorn-like sigil, a runic band and satellite circles linked at star points. Those files are also absent locally. The implementation is independently authored from that description and the user's requested purple palette; it does not claim local pixel matching.

## Village direction

Use a warm, friendly village with simple houses, soft ground colors, clear footpaths and small clusters of villagers. A top-down or lightly elevated view should make routes easy to read. Reserve the strongest character contrast for the purple cultist, with a recognizable hood and a robe silhouette that remains legible at normal gameplay scale.

During a round, the village should occupy most of the viewport. The camera serves movement and orientation. Keep gatherings open enough that the cultist visibly stands with an audience. The village art remains honest procedural placeholder shapes; production pixel art, painted sprites and exact reference styling are not yet chosen.

## Ritual upgrade screen

Round end switches attention to a large ritual circle on a dark ground. Use violet, lilac and pale lavender for concentric rings, intersecting lines, connected satellite circles and restrained rune-like ticks. The node circles and prerequisite connections belong to the seal itself. Avoid placing an ordinary grid of rectangular upgrade cards over an unrelated occult background.

The real catalog retains three branches across three rings. Each branch has a consistent symbol/name, and purchased ranks visibly mark progression. The outermost node of each branch has two ranks; the inner six each have one. Keep available, unaffordable, prerequisite-locked, partially ranked and maximum-rank states distinguishable with text and shape treatment as well as color. Rank pips and current/maximum labels belong beside the circular nodes, so the new progression does not add more graph nodes or replace the seal with cards.

A readable stationary details area names the selected node and rank, shows its current-to-next effect, next-rank price and prerequisite, and clearly marks maximum rank. The purchase label must identify the next rank; a partly ranked node must not look permanently finished. This area supports the ritual rather than replacing it.

Mouse dragging pans the graph and the wheel zooms it. Labels and hit areas must remain usable as the circle grows. Fit/reset controls should provide a way back after exploring. A separate 144-node fixture exercises large layouts; those test nodes are not part of the game's upgrade catalog. More branches, search and accessible keyboard/gamepad graph navigation remain content and UX work.

The full-screen ritual is an intentional intermission, while the normal village HUD remains small. Tab returns to the visible village and reopens the ritual. Movement continues in either view, and the screen must clearly state how to start the next round.

## Character motion

Movement pulls the robe behind the travel direction with a small wave and lets it settle after stopping. Diagonal travel should neither increase speed nor cause abrupt cloth direction changes. The robe is a visual appendage, not a collision footprint. Keep its motion readable at the increased running speeds unlocked by upgrades.

Villagers need enough variation to distinguish gatherings without requiring portraits. Recruitment feedback should stay local: a gesture, icon or momentary emphasis. A visible cue and optional sound should supplement color changes. Later animation can add steps, idle breathing and a speaking gesture while preserving the cultist silhouette.

## World and interface

- Build the ground, roads, houses, props and actors as scene content. Never use reference screenshots as game backgrounds.
- Use paths and building spacing to lead the eye between gatherings; leave room to steer.
- Keep village HUD text compact and readable against the world; place speaking feedback near the affected group.
- Let decorative ritual marks support the node structure without obscuring labels or purchase state.
- Favor quiet ambient sound, soft footsteps and short recruitment/donation cues when audio is added.

## Future asset needs

| Asset | Minimum useful production set |
| --- | --- |
| Cultist | Hood/body, directional walking, idle/speaking poses, trailing robe treatment |
| Villagers | Readable body/outfit variants, idle/listening/recruited reactions |
| Village | Ground/path pieces, houses, trees, fences, signs and gathering props |
| Interface | Donation/recruitment icons, focus/hover states, licensed legible font |
| Ritual | Cohesive branch symbols, node states, restrained rune vocabulary, optional subtle effects |
| Effects | Local recruitment, donation, speaking and later magic cues |
| Audio | Movement/reward cues, village ambience, optional music loop |

Record sources, licenses, dimensions and import choices when art arrives. Check sprite scale in the camera before producing a large set. Ritual geometry can remain procedural if it meets the chosen art direction; the references do not imply importing their pixels.

## Visual review checklist

Inspect captures of the running village and ritual separately from supplied references. Check player contrast, robe motion, traversable roads, local speech feedback and unobtrusive HUD. In the ritual, check that the seal dominates, the palette is purple, rank pips and selected current-to-next details remain readable, partial/maximum/locked states are clear and navigation returns from distant rings. Verify both the initial catalog and the large fixture at supported window sizes. Rendered captures verify composition; human interaction is still needed to judge navigation and movement feel.

## 2026-10-03 merchant and opponent placeholders

Merchant hats and purses, Skeptic spectacles/book, Guard helmet/shield, Zealot hood
and medallion, and Priest mitre/stole/crozier are original procedural geometry in
`gathering.gd` and `encounter.gd`. They add no external asset or license dependency.
No original artwork was replaced and no mockup pixels were incorporated.
Actual rendered states are `verification/village-merchants.png`,
`verification/opponent-{skeptic,guard,zealot,priest}.png` and
`verification/village-complete.png`. These remain prototype placeholders.
