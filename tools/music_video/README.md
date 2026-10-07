# Music video tools

Tooling for *Just a Small Following*, the sung music video planned in
[docs/MUSIC_VIDEO.md](../../docs/MUSIC_VIDEO.md). Outputs go to the ignored
`exports/music_video/`, which carries a `.gdignore` so Godot does not import them.

## Reproduce

From the project root (Python 3.11 with NumPy and SciPy; FFmpeg for checks):

```powershell
python tools/music_video/song_data.py   # validate song.json
python tools/music_video/compose.py     # backing.wav + beats.json (about 15 s)
python tools/music_video/sing.py --excerpts   # song.wav + vocals.wav + excerpts, then checks (about 4 min)
python tools/music_video/sing.py --shapes     # syllable shapes used by the articulated chant
```

| Output | Contents |
| --- | --- |
| `exports/music_video/audio/backing.wav` | 179.2 s, 48 kHz stereo 16-bit backing track, -18 LUFS integrated, under -1 dBTP |
| `exports/music_video/beats.json` | 384 beats with time and video frame, section starts, and editorial cues (record scratch, dead air, smash cut, hard cut) |
| `exports/music_video/audio/song.wav` | The final song: backing plus the wordless growing choir, 179.2 s, -14 LUFS, under -1 dBTP |
| `exports/music_video/audio/vocals.wav` | Vocals only, normalized to -16 LUFS for review |
| `exports/music_video/audio/excerpt_*.wav` | Listening excerpts: the lone voice (bars 5-24), the password chant (65-68) and the ritual ending (85-96) |

`sing.py` exits non-zero unless the song is exactly 179.2 s, within
-14±1 LUFS, at or under -1 dBTP (cross-checked with FFmpeg `ebur128`), and
silent only in the planned dead air after the wrong password.

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
- **Vocals:** synthesized by `sing.py` with source-filter synthesis, extending
  the murmur approach in `tools/build_game_audio.py`. A harmonic source with
  portamento, delayed vibrato and slow pitch drift passes through a cascade of
  moving vowel formants (Peterson and Barney style averages). The singing is
  wordless: open vowel arcs grow from one voice into a ritual choir, using
  organum fourths and fifths, a root-and-fifth drone and a synthetic cathedral
  reverb. Only the shouts, whispers and password chant use seeded noise
  consonants. The lyrics appear only in the captions.
- **Measurement:** loudness is measured with an in-script BS.1770-4 meter and
  cross-checked with FFmpeg `ebur128`. Peaks are controlled by a 4x
  oversampled look-ahead limiter.

Scripted checks confirm duration, loudness and reproducibility only. Whether the
track sounds right is a human listening check.
