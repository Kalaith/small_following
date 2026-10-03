# Small Following promo production

The promo uses actual viewport frames from the installed Godot 4.2.2 renderer,
two original promotional illustrations, typeset title plates and an original
procedural instrumental score. It does not change playable scenes or balance.
All media and intermediate files live under ignored `exports/promo/`.

## Capture

From the project root, with a rendering display:

```powershell
& 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe' --fixed-fps 60 --path . --script res://tools/promo/capture_promo.gd -- "--capture-dir=$PWD\exports\promo\capture"
```

The recorder disables persistence before adding each scene to the tree. It
never reads or writes the player's save. Motion uses the real physics path at
60 Hz; every second rendered frame is saved for 30 fps video. Rounds retain
their normal 11-second duration and conversation rules.

| Take | Duration | Staging and checks |
| --- | --- | --- |
| opening | 11 s | Fresh start; garden route earns 3 recruits and 9 donations |
| ritual | 8 s | Spends those donations on Talking I; checks rank 1 and 3 donations remaining |
| full_core | 11 s | Prepared original nine-node maximum ranks; real route recruits all 15 |
| helper | 11 s | Prepared first 16 catalog nodes; expanded route leaves work for helper |
| priest | 10 s | Prepared full catalog, encounter stage 3; verifies actual Priest victory |

Later takes use temporary funded build setup and an explicit boss-stage
fixture. Setup is outside the footage; those takes are labeled upgraded,
expanded or finale builds. This is an edited showcase, not one continuous
save progression or a human playtest. The separate 144-node fixture is absent.

The October 3, 2026 capture exited 0 with 0 failures and 1,530 PNG frames:
3 opening recruits, 15 core recruits, 24 expanded recruits (3 by the helper),
and a convinced Priest with 1 second remaining at the end of the final take.

## Assemble

Place the two source illustrations under `exports/promo/assets/` as
`village-key-art.png` and `ritual-key-art.png`. Their generation prompts and
provenance are recorded in `art-prompts.json`. Preserve the originals.

```powershell
python tools/promo/render_promo.py
```

Uses the already installed Pillow, NumPy, FFmpeg and ffprobe. The Windows
Georgia and Trebuchet fonts are rasterized locally; font files are not copied
or redistributed. No ComfyUI, LLM, voice service, model download or package
installation is needed. `D:\VideoGeneration` was inspected for its existing
FFmpeg workflow; its files and services are unchanged.

The renderer produces a 72-second 1920 x 1080, 30 fps H.264/yuv420p MP4 with
48 kHz stereo AAC, a fast-start header and a -16 LUFS normalization target.
Its original 3/4 instrumental score uses synthesized plucks, bells, pads and
bass, with no samples or borrowed melody. There is no narration.

Final: `exports/promo/Small_Following_Promo.mp4`. Editable timing is in
`render_promo.py`; the render writes `timeline.json`, a source WAV, separate
encoded shots, FFmpeg logs, stream metadata and a full decode check. The
source art and original score are promo assets, not installed game content.
