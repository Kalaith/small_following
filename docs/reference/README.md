# Supplied visual references

The originals exist in the user's ChatGPT Library. They are visual references, never playable scene backgrounds. No exact original is currently present on this Windows executor.

## Village mock screenshots

| View | Canonical filename | Library file | Expected size |
| --- | --- | --- | --- |
| Closer | `cultist-idle-village-closeup.png` | `libfile_f15b3c5fa66c8191b5f3f6c19594591b` | 2,733,709 bytes |
| Wider | `cultist-idle-village-overview.png` | `libfile_3b1a6b5544b0819187f93df40ab92762` | 3,159,483 bytes |

**Neither PNG is present locally, and neither image's pixels were inspected on this Windows executor.** Their intended destinations remain:

- `docs/reference/cultist-idle-village-closeup.png`
- `docs/reference/cultist-idle-village-overview.png`

## Ritual-circle references

| Library file | Description supplied after parent inspection in the cloud |
| --- | --- |
| `libfile_0cbc504784a881918b26f5cf3fcb53a0` | Dark red hand-drawn floor seal: concentric circles, large intersecting star/polygon lines, perimeter rune-like ticks and small candles |
| `libfile_37a80cce194c8191adf4af155d184a44` | Luminous red-on-black seal: central thorn-like sigil, concentric borders and runic band, connected satellite circles at star points and smaller inner circles |

Canonical filenames and sizes have not been resolved on this executor; none are invented here. The parent inspected these pixels in the cloud. This Windows implementation received the description above and **did not inspect local pixels**. The user requested purple rather than red, so the independently authored procedural ritual uses violet/lilac geometry. It does not copy image pixels or claim exact visual matching.

## Transfer blocker

### Magical-seal composition references, 2026-10-03

The user subsequently clarified that evenly distributing nodes is insufficient:
the ritual should be a deliberately composed purple magical seal. Actual
reference pixels are required before the next visual redesign.

| Library file | Resolved original | Reported dimensions | Bytes |
| --- | --- | --- | --- |
| `libfile_589bc943fb4881919e95da7df2057d61` | `image(20261003-103904).png` | 640 x 666 | 359,246 |
| `libfile_b3c863f134f48191b8a08bfe8afef572` | `image(20261003-103904-1).png` | 1000 x 651 | 553,652 |
| `libfile_1ebed7e4e6848191936e90de962b28ee` | `image(20261003-103905).png` | 580 x 533 | 140,646 |

Current image reads returned captions and asset pointers, not image blocks.
Preparation for an explicitly Windows-local destination returned no local
paths. The required metadata operation still lacks Windows support
(`os.setxattr` is absent), so the known failing download was not repeated.
No original was installed locally and none of these pixels were inspected.
Captions and reported dimensions are not visual evidence.

The parent research environment subsequently materialized and inspected all
three originals and explicitly authorized implementation from its
image-grounded brief. This supplies the visual understanding needed for the
art pass; the Windows executor has still not viewed the original pixels.
No further transfer retry is needed for this change.

The parent inspection identified these compositional properties:

- First reference: a large circular constellation around a luminous central
  medallion, with varied loops, diamonds, arcs and flower-like local clusters.
- Second reference: offset satellite circles of unequal size, internal rings
  and spirals, narrow connecting routes and purple emphasis over quiet grey.
- Third reference: near-black violet, nested thin guides, a ticked rim and
  central pentagram, unequal curved spokes, diagonal chains and lilac nodes.

The authorized adaptation uses the current upgrade nodes in authored
constellations, restrained inscription bands and satellite motifs, and a
layered central sigil. Real unlock paths remain clearer than decoration.
Procedural artwork is original code, not copied image pixels or a mockup
background. Local rendered captures are reviewed against this explicit
inspected-reference brief; exact pixel matching to the originals is not
claimed. The all-ranks centre and dismissible message remain independent of
these presentation changes.

### Fuller-circle reference, 2026-10-03

The newly supplied `libfile_f75084b9c8c88191a60b3ddb2b39514f` resolves to
`image(20261003-101119).png`, file
`file_000000004a7481fd8bda56630479b6fe`, version 0, 170,993 bytes.
For this explicitly requested transfer, the current Library skill and fresh
unchanged transfer helper were used, including one bounded supported retry
to an explicitly Windows-local task destination. The retry reached required
metadata handling and failed with:

```
AttributeError: module 'os' has no attribute 'setxattr'
```

The atomic transfer left no final PNG; local existence was checked and was
false. No pixels of this reference were inspected locally, no metadata was
bypassed, and no substitute was generated. The latest layout and completion
work use fresh rendered application captures, recorded in
[VERIFICATION](../VERIFICATION.md).

### Earlier supplied references

The original Windows Library materialization attempt, including one bounded supported retry, failed because the download helper attempted to use `os.setxattr`, which is unavailable on Windows (`AttributeError`). The image read fallback also reported: `Native image pixels were unavailable; returned extracted text only.`

The earlier originals were not retried during the current update. The helper
was not patched and its required metadata was not bypassed with a raw download.
No generated approximation or extracted-text reconstruction replaces any
original. Procedural art in the running game is separate from these missing
reference files.

## Recovery

When a supported Windows-compatible Library workflow is available, use the current Library skill and materialization guidance to retrieve the exact files. Resolve filenames for the ritual references before assigning their local destinations. Do not treat cloud workspace paths as Windows-local files or guess download URLs. A supported Library download or user-supplied original is also suitable.

After transfer, verify files exist and are readable images; compare the village filenames and expected sizes above. Open and inspect actual pixels, then update the visual direction and status. Preserve originals in this reference folder; future production assets belong in the asset folders. Local project deliverables do not require Library writes.
