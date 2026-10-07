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
python tools/music_video/postcards.py          # plates: six future postcards, map, daydream, end card (about 10 s)
python tools/music_video/render_music_video.py --animatic  # animatic.mp4 + timeline.json, then checks (about 2 min)
```

| Output | Contents |
| --- | --- |
| `exports/music_video/audio/backing.wav` | 179.2 s, 48 kHz stereo 16-bit backing track, -18 LUFS integrated, under -1 dBTP |
| `exports/music_video/beats.json` | 384 beats with time and video frame, section starts, and editorial cues (record scratch, dead air, smash cut, hard cut) |
| `exports/music_video/audio/song.wav` | The final song: backing plus the wordless growing choir, 179.2 s, -14 LUFS, under -1 dBTP |
| `exports/music_video/audio/vocals.wav` | Vocals only, normalized to -16 LUFS for review |
| `exports/music_video/audio/excerpt_*.wav` | Listening excerpts: the lone voice (bars 5-24), the password chant (65-68) and the ritual ending (85-96) |
| `exports/music_video/plates/*.png`, `plates.json` | 1920 x 1080 plates and their labels and design-note sources |
| `exports/music_video/animatic.mp4` | Song, karaoke captions, plates and labelled placeholder cards for footage (H.264 + AAC, 5,376 frames) |
| `exports/music_video/timeline.json` | Shot frame ranges, caption windows and per-syllable frames, password letter frames |
| `exports/music_video/capture/<take>/` | 18 takes of 1920 x 1080 PNG frames at 30 fps, each with `events.json` |
| `exports/music_video/review/` | Contact sheets and caption-sync stills |

`sing.py` exits non-zero unless the song is exactly 179.2 s, within
-14±1 LUFS, at or under -1 dBTP (cross-checked with FFmpeg `ebur128`), and
silent only in the planned dead air after the wrong password.

## Capture (slice 6)

From the project root, with a display (the window mirrors the frames being
captured; leave it open, because closing it ends the run):

```powershell
& 'C:\Program Files\Godot\Godot_v4.2.2-stable_mono_win64_console.exe' --fixed-fps 60 --path . --script res://tools/music_video/capture_music_video.gd -- "--capture-dir=res://exports/music_video/capture"
```

Add `--takes=a,b` to capture only some takes, and `--preview` to save every
8th frame for a quick look. The game renders off-screen at 1920 x 1080: the
game view is widened to 16:9 (1422 x 800 units), so nothing is cropped. Each
take writes `capture/<take>/00000.png...` and `events.json`, which holds frame
counts, song bars, events and checks. The run exits non-zero on any failed
check. Nothing under `scripts/` or `scenes/` is changed. Staged props come from
`mv_set.gd`, and followers and the helper are the game's own classes.

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
- **Plates and postcards:** drawn by `postcards.py` with Pillow. Characters
  come from `sprites.py`, which ports the game's own `_draw()` shapes and
  colours (`scripts/gathering.gd` listeners, `scripts/player.gd` cultist,
  `scripts/helper.gd` helper). Extra props (pie, captain's hat, mortarboard,
  wimple, top hat) are new and drawn in the same style. The backdrop is the
  promo's. Future ideas come only from `docs/FUTURE_LEVELS.md` section 8
  (Rosecourt, Tidemouth, the lantern fair, the university and observatory,
  the hilltop abbey) and `docs/GAME_DESIGN.md` (helpers, minions and magic).
  Each postcard names its source and carries an "IDEA - NOT BUILT YET" stamp.
  Fonts are the system's Georgia and Trebuchet MS.
- **Footage:** real Godot 4.2.2 renders of the game, captured by
  `capture_music_video.gd`. Gameplay takes are real simulation with real
  outcomes, which the script asserts. Staged takes pose the game's own
  characters and capture-only props (`mv_set.gd`, drawn in the game's style),
  and the edit labels them STAGED.
- **Measurement:** loudness is measured with an in-script BS.1770-4 meter and
  cross-checked with FFmpeg `ebur128`. Peaks are controlled by a 4x
  oversampled look-ahead limiter.

Scripted checks confirm duration, loudness and reproducibility only. Whether the
track sounds right is a human listening check.
