# Small Following music video - plan

**Status:** proposal, 2026-10-07. Nothing here is implemented yet. Lyrics,
timings and mix values are provisional until the user accepts them.

A comedic, sung music video about the cult, in the style of a short
"song about the product" video: a catchy original song whose lyrics follow the
cultist from three garden-club converts to the Priest of Bramblewick and on to
Bellmarket, cut on the beat to real in-engine footage.

This is a **new project**, separate from the 72-second promo. The promo's
tooling (`tools/promo/`) and outputs (`exports/promo/`) stay unchanged; the
music video may read the promo's helpers as reference but forks what it needs.

## 0. Confirmed direction and open choices

| Item | Status |
| --- | --- |
| Voice approach | **Confirmed (user, 2026-10-07):** on-brand and fully original. A synthesized formant "cult choir" sings vowel-matched nonsense syllables; the real lyrics appear as karaoke captions. No recorded voices, samples, song generators, voice services or model downloads. |
| Separate project | **Confirmed:** new `tools/music_video/` and ignored `exports/music_video/`. |
| Game content shown | **Confirmed:** current build, which has changed since the promo (see section 2). |
| Song title, lyrics | Open: draft in section 4; user approval is the first gate. |
| Length | Provisional: 68 bars at 120 BPM = 2:16. A 30-second chorus cut ships first. |
| Aspect | Provisional: 16:9 1920 x 1080, 30 fps. A 9:16 short is a later, optional cut. |
| Staging labels | Open: how visibly to mark choreographed (non-gameplay) shots. Proposed: small corner tag plus an end-card line. |
| Showing `PLZKTKS` | Open: the level-select password on screen is a spoiler; default is not to show it. |
| Distribution | Not authorized. Uploading to YouTube, itch.io or WebHatchery is a separate decision. |

## 1. Constraints carried from the project

- No tool installation. Available and checked 2026-10-07: Python 3.11,
  NumPy 2.4.4, Pillow 12.2.0, SciPy 1.17.1, FFmpeg/ffprobe 8.0, Godot 4.2.2.
- Capture never reads or writes the player's save (`persistence_enabled =
  false`, as in `tools/promo/capture_promo.gd`).
- **No edits to `scripts/` or `scenes/` for the video.** Choreography is applied
  from the capture script to public node properties. If a take genuinely needs a
  game-side hook, stop and propose it separately.
- Audio provenance is recorded like `assets/audio/README.md`: original,
  synthesized, seeded and reproducible.
- Honest claims: gameplay takes are real simulation; dance moves, conga lines
  and speed ramps are staged and labelled as such. No human listening or
  viewing acceptance is claimed by scripted review.
- Generated media stays under ignored `exports/`. The capture script writes a
  `.gdignore` into `exports/music_video/` so Godot does not import thousands of
  frames (the promo's assets picked up `.import` sidecars this way).

## 2. What is new since the promo (shot material)

The promo (commit `42f559f`) shows only Bramblewick. Since then the game has
added material that the video should feature:

- The title screen (`scripts/title_screen.gd`) with its procedural art.
- Authored ritual constellations: eight named branches, a nested seal and
  the central pentagram medallion; branch selector and focus/overview views.
- The lit ritual centre on full completion and the travel offer.
- **Bellmarket**: cobbled market, bunting, five districts (Bread Court, Cart
  Crossing, Guild Row, Silk Arcade, Patron Steps), guild traders in caps and
  aprons, patrons with feathered hats and fans, locked-listener marks, and
  its separate five-petal circle.
- Donation popups rising above each recruit.
- Recruits as a cost: followers are "spent" on inscriptions.
- Town Debate opponents: Skeptic, Town Guard (2 rebuttals), Zealot, Priest
  (3 objections, 240 conviction).
- The in-game nonsense speech, which the choir extends into song.

## 3. Song structure and shot list

The tempo is 120 BPM in 4/4. One beat = 0.5 s = **15 frames**, and one bar =
2 s = 60 frames, so every cut lands on a whole frame. The key is A minor/C
major, matching the village score, so the intro can quote its waltz motif.

| Bars | Time | Section | Footage | Real / staged |
| --- | --- | --- | --- | --- |
| 1-4 | 0:00 | Intro: music-box quote of the village score, straightened into 4/4 | Live title screen, slow push in; title card | Real screen |
| 5-12 | 0:08 | Verse 1: "three little converts" | Fresh Bramblewick round: walk out, Garden club, 3 recruits; `+3` popups aligned to downbeats | Real gameplay |
| 13-16 | 0:24 | Pre-chorus | Ritual: Talking I selected on beat 1, inscribed on the bar-16 downbeat | Real ritual actions, beat-timed |
| 17-24 | 0:32 | Chorus 1 | Full-core round, 15 recruits; listeners hop on the beat; cut every bar | Real route + staged hops |
| 25-32 | 0:48 | Verse 2: "I hired a friend" | Meadow/East Lane groups, merchants and purses, teal helper recruiting | Real gameplay |
| 33-36 | 1:04 | Pre-chorus 2 | Constellation tour: one branch focused per beat across all eight | Real ritual views, beat-timed |
| 37-44 | 1:12 | Chorus 2 | Expanded round; recruited listeners form a conga line behind the cultist | Staged choreography |
| 45-52 | 1:28 | Bridge: half-time call and response | Town Debate: Skeptic, Guard, Zealot cut by bar; the Priest's three objections land on "Objection!" | Real encounter, real victory |
| 53-64 | 1:44 | Final chorus, key change up a tone | Lit centre, travel to Bellmarket, guilds and patrons, five-petal circle | Real screens and route |
| 65-68 | 2:08 | Outro | Wide Bellmarket pull-back; end card | Real + title plate |

Total: 68 bars, 136 s, 4,080 frames.

The choir grows with the story. One lead voice (the cultist) sings verse 1.
Backing voices are added as the scene's following grows (1, 3, 6, then about
12 layered voices by the final chorus). The joke is literally a small following
getting louder.

## 4. Draft lyrics (provisional, for approval)

Working title: **"Just a Small Following"**

> **Verse 1**
> Woke up in Bramblewick, robe on, hood up,
> eleven seconds on the clock and a heart full of hope.
> Talked to the garden club, they said "well, maybe" -
> three little converts and nine little coins.
>
> **Pre-chorus**
> Take it to the circle, light a little line,
> Talking One, inscribed, now I'm talking all the time.
>
> **Chorus**
> It's just a small following (small following),
> nothing to fear, we've got snacks and a robe.
> It's just a small following (small following),
> eleven more seconds and we'll ask you again.
>
> **Verse 2**
> Bought a new gathering, merchants with purses,
> hired a friend in teal and he does his own verses.
>
> **Bridge** (the Priest, low choir voice; the cultist answers)
> Priest says no - *Objection!*
> Priest says no - *Objection!*
> Priest says no - *Objection!*
> Priest says... *...fine.*
>
> **Final chorus** (key change)
> It's a medium following (medium following),
> Bellmarket's waiting with feathers and fans...

Rough edges (verse 2's second half, the final-chorus tail, the outro tag)
are left for the lyric pass in slice 1.

## 5. Pipeline

```text
song.json ──► compose.py ──► backing.wav + beats.json
    │                  │
    ├────────► sing.py ┴──► vocals.wav ──► mix ──► song.wav (-14 LUFS)
    │
    ├────────► capture_music_video.gd ──► capture/<take>/*.png + events.json
    │
    └────────► render_music_video.py ──► captions, beat cuts, mux ──► MP4
                                              │
                                review_music_video.py (contact sheet, loudness, decode)
```

### 5.1 `song.json` (single source of truth)

```json
{
  "bpm": 120, "beats_per_bar": 4, "key": "A minor",
  "sections": [{"id": "verse1", "bars": [5, 12], "choir_voices": 1, "shot": "opening"}],
  "lines": [
    {"bar": 5, "beat": 1, "text": "Woke up in Bramblewick",
     "notes": [{"syl": "Woke", "midi": 69, "beats": 0.5}, {"syl": "up", "midi": 71, "beats": 0.5}]}
  ],
  "shots": [{"id": "opening", "bars": [5, 12], "take": "opening", "in_event": "first_recruit", "at_bar": 7}]
}
```

A validator in the tools checks that note beats fill each line, sections
tile all 68 bars, shot ranges cover the timeline without gaps, and every take
named by a shot exists in the capture plan.

### 5.2 `compose.py`: backing track

- Fork `note()` from `tools/promo/render_promo.py` (pluck, pad, bass, bell).
  Add synthesized drums: kick (pitch-dropping sine), snare/clap (filtered noise
  burst), hats (high-passed noise ticks). Seeded RNG.
- Section-driven arrangement: intro music box; verse with sparse plucks and
  kick; chorus at full band; bridge in half-time with bass and choir; final
  chorus up a whole tone.
- Writes `backing.wav` (48 kHz stereo) and `beats.json` (time of every beat
  and bar) for the editor and capture.

### 5.3 `sing.py`: the formant choir

Extends the approach in `tools/build_game_audio.py` (harmonic series weighted
by Gaussian formant peaks) into a singing voice:

- **Pitch per note** from `song.json`, with portamento between legato notes
  and delayed vibrato (about 5.5 Hz, ±30 cents, after 150 ms).
- **Vowel-matched nonsense:** each lyric syllable is reduced to its vowel class
  (a/e/i/o/u/schwa, using F1-F3 tables), with a consonant chosen from a small
  fixed onset set. The choir sings shapes that track the lyric without
  pronouncing English, so it stays clearly synthetic and close to the game's
  murmurs.
- **Consonants:** short shaped noise bursts (s, sh, k, t, p) before vowel onsets.
- **Choir:** N copies with seeded ±8-cent detune, ±10 ms timing jitter and
  stereo spread; N follows `choir_voices` per section.
- **Characters:** the cultist (current murmur range, about 155-250 Hz);
  the Priest (formants and f0 lowered about an octave, slower vibrato); the
  "Objection!" shout as a spoken, unpitched burst.
- Light ducking of the backing under the lead; master normalized to -14 LUFS
  integrated, -1 dBTP (provisional YouTube-style target; the promo used -16).

**Risk:** additive formant singing can sound buzzy. Slice 3 is a deliberately
small 8-bar listening test before any further vocal work.

### 5.4 `capture_music_video.gd`: takes and choreography

Same isolation pattern as `capture_promo.gd`: fixed 60 Hz physics, every
second frame saved, funded build setup cut away, persistence disabled.

- **Resolution:** run at 1920 x 1200 (16:10, the project's aspect), then crop
  to 1920 x 1080 in the edit. A capture-side "clean" mode hides `hud_layout`
  and the settings button for village shots. Ritual shots need a check that
  the crop does not cut off text; if it does, those shots use the promo's
  framed layout instead.
- **Event log:** each take writes `events.json` with frame numbers for
  recruits, phrases, purchases, rebuttals and victory. The editor uses it to
  shift a take's in-point so that a chosen real event lands on a downbeat.
  This keeps gameplay timing real while still syncing it to the music.
- **Beat-timed ritual actions:** `select_node`, `focus_node`, `reset_view` and
  `purchase_button.pressed` are fired on frames taken from `beats.json`.
- **Staged choreography (labelled):** listener hops and sways via each
  listener's `position`/`rotation` on the beat; a conga line that moves
  recruited listeners onto the cultist's position history; small cultist
  side-steps through `step_motion` so the robe cloth swings for real.
- **Takes:** `title`, `opening`, `ritual_first`, `full_core_dance`,
  `expansion_helper`, `constellation_tour`, `conga`, `debate` (stages 0-3),
  `centre_lit`, `bellmarket` (via `travel_to("bellmarket", true)` after a full
  village setup), `bellmarket_wide`.
- **Checks, as in the promo:** opening earns 3 recruits; full core earns 15;
  the helper recruits at least 1; the Priest is actually convinced; Bellmarket
  loads its five districts; the capture has 0 failures.

### 5.5 `render_music_video.py`: edit

- Builds the edit from `song.json` shots and `beats.json`. Every cut is on a bar
  line; punch-in zooms and brightness flashes go on chosen downbeats
  (`zoompan`, `eq`). Speed ramps are allowed only on labelled staged shots.
- **Karaoke captions:** a lower-third line rendered with Pillow (Georgia and
  Trebuchet, cream and lilac, as in the promo), with the active syllable
  highlighted by note timing. Frames are piped to FFmpeg as an RGBA overlay
  stream.
- Title and end cards reuse the promo plate style. The two promo key-art
  illustrations may be reused, since they are this project's own art (record it).
- Output: `exports/music_video/Small_Following_Just_a_Small_Following.mp4`,
  1920 x 1080, 30 fps, H.264/yuv420p, 48 kHz stereo AAC, fast start, plus
  `timeline.json` and FFmpeg logs.

### 5.6 `review_music_video.py`

Frame count equals duration x 30. It also runs a full decode check, makes a
contact sheet of one frame per section, takes measured LUFS/true peak, checks
for silence gaps, makes per-section stills of the caption sync, and records a
SHA-256. Visual and musical acceptance remain human checks.

## 6. Files

| Path | Purpose |
| --- | --- |
| `tools/music_video/README.md` | Reproduction commands, provenance, verification record |
| `tools/music_video/song.json` | Lyrics, melody, sections, shot list |
| `tools/music_video/song_data.py` | Load and validate `song.json`; shared timing helpers |
| `tools/music_video/compose.py` | Backing track and beat grid |
| `tools/music_video/sing.py` | Formant choir vocals and final mix |
| `tools/music_video/capture_music_video.gd` | Isolated takes, choreography, event log |
| `tools/music_video/render_music_video.py` | Edit, captions and mux |
| `tools/music_video/review_music_video.py` | Automated review |
| `exports/music_video/` | Ignored outputs (WAVs, frames, shots, final MP4) |

## 7. Slices

Commit each slice when it is complete and validated (see
[COMMIT_STYLE](COMMIT_STYLE.md)).

| # | Slice | Outcome | Checks | Human gate |
| --- | --- | --- | --- | --- |
| 1 | Song data | `song.json` with full lyrics, melody, sections and shots; validator | Validator passes; 68 bars tile | **User approves lyrics and title** |
| 2 | Backing track | `backing.wav` + `beats.json` | Duration 136 s; 272 beats; loudness measured | Listen |
| 3 | Voice prototype | 8-bar chorus with choir | Pitch tracks notes (measured); no clipping | **User listening test: keep, retune or rethink** |
| 4 | Full vocals and mix | `song.wav` | -14 LUFS ±1, ≤ -1 dBTP | Listen |
| 5 | Animatic | Song + captions over the backdrop, no footage | Caption timings match note starts | Sing-along check |
| 6 | Capture | All takes + `events.json` | Promo-style recruit/victory assertions; 0 failures | Inspect contact frames |
| 7 | 30 s chorus cut | Bars 17-32 edited | Frame count; cuts on bar frames | **First real review** |
| 8 | Full video | 2:16 MP4 | Full review script | Watch-through |
| 9 | Handoff | README section, VERIFICATION entry, provenance | Link check | - |

## 8. Risks

- **Synth vocals sound bad.** Mitigated by the slice 3 gate. The fallback is a
  bigger instrumental lead with the choir only on hooks ("small following",
  "Objection!").
- **Real events do not land near beats.** Mitigated by in-point shifting from
  `events.json`; staged shots carry the tightest sync.
- **Choreography edits private state.** Restricted to listener and player
  transforms and existing public methods; if a capture script breaks because
  game internals change, the capture fails loudly rather than drifting.
- **16:9 crop clips ritual text.** Checked in slice 6, with the framed layout
  as a fallback.
- **Render time and disk use.** About 4,000 frames at 1920 x 1200 PNG is
  roughly 8-12 GB in ignored exports. Delete capture frames after encoding
  shots if space is tight.
