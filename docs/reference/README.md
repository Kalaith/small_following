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

The original Windows Library materialization attempt, including one bounded supported retry, failed because the download helper attempted to use `os.setxattr`, which is unavailable on Windows (`AttributeError`). The image read fallback also reported: `Native image pixels were unavailable; returned extracted text only.`

The current update does not retry that known unsupported path, patch the helper or bypass its required metadata with a raw download. No generated approximation or extracted-text reconstruction replaces any original. Procedural art in the running game is separate from these missing reference files.

## Recovery

When a supported Windows-compatible Library workflow is available, use the current Library skill and materialization guidance to retrieve the exact files. Resolve filenames for the ritual references before assigning their local destinations. Do not treat cloud workspace paths as Windows-local files or guess download URLs. A supported Library download or user-supplied original is also suitable.

After transfer, verify files exist and are readable images; compare the village filenames and expected sizes above. Open and inspect actual pixels, then update the visual direction and status. Preserve originals in this reference folder; future production assets belong in the asset folders. Local project deliverables do not require Library writes.
