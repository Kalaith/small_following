# Music video tools

Tooling for *Just a Small Following*, the sung music video planned in
[docs/MUSIC_VIDEO.md](../../docs/MUSIC_VIDEO.md). Outputs go to the ignored
`exports/music_video/`, which carries a `.gdignore` so Godot does not import them.

## Reproduce

From the project root (Python 3.11 with NumPy and SciPy; FFmpeg for checks):

```powershell
python tools/music_video/song_data.py   # validate song.json
python tools/music_video/compose.py     # backing.wav + beats.json (about 15 s)
```

| Output | Contents |
| --- | --- |
| `exports/music_video/audio/backing.wav` | 179.2 s, 48 kHz stereo 16-bit backing track, -18 LUFS integrated, under -1 dBTP |
| `exports/music_video/beats.json` | 384 beats with time and video frame, section starts, and editorial cues (record scratch, dead air, smash cut, hard cut) |

## Provenance

- **Song data:** `song.json` holds the lyrics, melody, per-bar chords, sections
  and shot list, fitted from the user's [beat sheet](BEAT_SHEET.md). Lyrics and
  title approved by the user on 2026-10-07.
- **Backing track:** original composition, fully synthesized by `compose.py`
  with a fixed seed. Plucks, pads, bass and bells are forked from
  `tools/promo/render_promo.py`. Drums, stabs, ticks and the stomp are
  synthesized from sine sweeps and filtered seeded noise. The reverb is a seeded
  noise impulse response. No samples, recordings, borrowed melodies, voices,
  song generators or model downloads are used.
- **Measurement:** loudness is measured with an in-script BS.1770-4 meter and
  cross-checked with FFmpeg `ebur128`. Peaks are controlled by a 4x
  oversampled look-ahead limiter.

Scripted checks confirm duration, loudness and reproducibility only. Whether the
track sounds right is a human listening check.
