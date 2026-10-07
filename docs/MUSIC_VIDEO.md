# Small Following music video - plan

**Status:** accepted, 2026-10-07. The user approved the lyrics, title and
password gag (slice 1 gate) and settled the open choices below. Timings and
mix values stay provisional until their own listening gates.

A comedic, sung music video about the cult, in the style of a short
"song about the product" video: a catchy original song whose lyrics follow the
cultist from three garden-club converts to the Priest of Bramblewick and on to
Bellmarket. It then gives away the level-select password as a joke and ends by
daydreaming about where the cult might go next. It is cut on the beat to real
in-engine footage.

This is a **new project**, separate from the 72-second promo. The promo's
tooling (`tools/promo/`) and outputs (`exports/promo/`) stay unchanged; the
music video may read the promo's helpers as reference but forks what it needs.

## 0. Confirmed direction and open choices

| Item | Status |
| --- | --- |
| Voice approach | **Revised (user, 2026-10-07, after the slice 3 listening test):** fully original and synthesized, but **wordless**. The first prototype mimicked lyric syllables; it sounded off, and its consonant bursts made an annoying noise. Now one voice sings the melody on open vowels and grows into a choir, which becomes a churchy, satanic ritual choir by the end. The lyrics appear only as karaoke captions. The articulated password chant is kept as approved. No recorded voices, samples, song generators, voice services or model downloads. |
| Separate project | **Confirmed:** new `tools/music_video/` and ignored `exports/music_video/`. |
| Game content shown | **Confirmed:** current build, which has changed since the promo (see section 2). |
| Length | **Confirmed (user):** about 3 minutes: 96 bars at 128.57 BPM (14 frames per beat) = 179.2 s. A 30-second chorus cut is reviewed first. |
| Password | **Confirmed (user):** `PLZKTKS` is shown on screen as a deliberate joke/spoiler (section 3, bars 61-68). |
| Future direction | **Confirmed (user):** included. Shown strictly as ideas from [FUTURE_LEVELS](FUTURE_LEVELS.md) and [GAME_DESIGN](GAME_DESIGN.md), marked as not built (section 2.1). |
| Song title, lyrics | **Approved (user, 2026-10-07):** *Just a Small Following*, fitted from the user's [beat sheet](../tools/music_video/BEAT_SHEET.md) into `song.json`. "Talking One" stays as a sung nickname; the real upgrade is Quickened Words I, and captions and notes never call it a real upgrade name. |
| Aspect | **Confirmed (user, 2026-10-07):** 16:9 1920 x 1080, 30 fps. A 9:16 short is a later, optional cut. |
| Staging labels | **Confirmed (user, 2026-10-07):** a small corner tag on staged shots plus an end-card line. |
| Distribution | **Confirmed (user, 2026-10-07):** published on YouTube as a music video. The upload itself is done or confirmed by the user at handoff; other destinations are not authorized. |

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
- Honest claims: gameplay takes are real simulation; dance moves, conga lines,
  the unmasked password field and speed ramps are staged and labelled. Future
  places are never shown as gameplay. No human listening or viewing acceptance
  is claimed by scripted review.
- Generated media stays under ignored `exports/`. The capture script writes a
  `.gdignore` into `exports/music_video/` so Godot does not import thousands of
  frames (the promo's assets picked up `.import` sidecars this way).

## 2. What is new since the promo (shot material)

The promo (commit `42f559f`) shows only Bramblewick. Since then the game has
added material that the video should feature:

- The title screen (`scripts/title_screen.gd`) with its procedural art,
  password field, travel-seal feedback and level choices.
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

### 2.1 Future direction (ideas, not features)

These come only from existing design documents and are presented as daydreams,
never as footage of unbuilt content:

| Idea | Source | Postcard motif |
| --- | --- | --- |
| **Rosecourt** noble garden gathering (the recommended next place) | FUTURE_LEVELS section 8 | Hedges, salon circle, a fan and a raised toast |
| **Tidemouth** harbour and docks | FUTURE_LEVELS section 8 | Quays and bridges, a captain's hat, an anchor |
| **Travelling lantern fair** | FUTURE_LEVELS section 8 | Radial lanes, lanterns, a ringmaster |
| **University and observatory** | FUTURE_LEVELS section 8 | Two courtyards, a telescope, the rector |
| **Hilltop pilgrimage abbey** | FUTURE_LEVELS section 8 | A terraced stair, the abbess |
| **Minions and magic** | GAME_DESIGN, MILESTONES section 4 | Several teal helpers, a glowing reach ring |

Each idea gets a **"future postcard"**: an illustrated plate drawn in Python
with Pillow, using the game's own procedural shape language (the listener body
and role-prop silhouettes from `gathering.gd`, the lilac palette, a seal
border). Each postcard carries a stamp reading **"IDEA - NOT BUILT YET"**.
Nothing is generated by a model or service.

The section ends with a joke: the end card says **"Some of these may happen.
None of them are promises."** This keeps the honest-claims rule from
README.md.

## 3. Song structure and shot list

The user's [beat sheet](../tools/music_video/BEAT_SHEET.md) (2026-10-07) is
the creative direction. `tools/music_video/song.json` is the authoritative
lyrics, melody and shot list derived from it; this section summarizes it.

The tempo is **128.57 BPM in 4/4**: one beat = **14 frames** at 30 fps
(0.4667 s), so every cut and lyric lands on a whole frame. 96 bars =
5,376 frames = **179.2 s**, about 3:00. The key is A minor/C major, matching the
village score; chorus 3 goes up a whole tone.

| Bars | Section | Story beat (lyric) | Main footage | Real / staged |
| --- | --- | --- | --- | --- |
| 1-4 | Intro | Folding-table HQ, wake-up, **00:11** countdown | `hq_wake` set | Staged set |
| 5-12 | Verse 1 | Garden club, "three said maybe", nine coins, Gerald's pie | Real opening round (3 recruits, 9 donations), then the `coins_pie` set | Real + staged |
| 13-16 | Pre-chorus | Wonky circle; "Talking One, inscribed, now I can't stop talking!" | Real ritual and Quickened Words I purchase; the edit tilts the frame | Real |
| 17-24 | Chorus 1 | Four people, tiny fire, one biscuit, "plus one!" | `chorus_hq` set, then a real recruit on the shout | Staged + real |
| 25-32 | Verse 2 | Merchants' stall; the teal cultist yells "Join us! Join us!"; on "That's enough", cut to the teal worker slumped and dejected, held through the instrumental | `stall_teal` set with the real teal helper | Staged |
| 33-36 | Pre-chorus 2 | Bigger circle, chairs, "worldwide" map | The real 32-node circle; three-pin map plate | Real + plate |
| 37-44 | Chorus 2 | Tight framing, NOTHING ALARMING banner, robe racks, square takeover | `crowd` / `crowd_wide` sets | Staged |
| 45-52 | Bridge | Priest "No." / cult "OBJECTION!" x3 / "...fine." | Real Priest encounter (it really has 3 objections) plus staged lectern and bell | Real + staged |
| 53-60 | Chorus 3 (key change) | Procession, statue, Bellmarket, clipboard: "stop counting" | Procession set, real Bellmarket, clipboard set | Staged + real |
| 61-64 | Spoiler | "Psst... don't tell the dev"; wrong entry; "...right. Not that one." | Real title screen and real seal error | Real UI, staged entry |
| 65-68 | Password chant | P! L! Z! K! T! K! S! / PLEASE! OKAY! THANKS! | Letters typed on beat; the seal opens; "Developer convenience feature" subtitle | Real UI, staged unmasking |
| 69-80 | Someday | Garden, harbour, fair, stargazers, abbey, helpers and magic | Six future postcards, each stamped **IDEA - NOT BUILT YET** | Plates |
| 81-84 | "Or twenty" | Enormous daydream, then "Or twenty. Twenty would be nice." | `vision-enormous` plate (labelled DAYDREAM), then `hq_humble` | Plate + staged |
| 85-92 | Final chorus | The HQ is quietly not humble; golden idol; pull-back; industrial biscuit tin | `hq_final` and `pullback` sets | Staged |
| 93-96 | Tag | Procession over bridge and hill; distant "...for now."; QUEUE plank sign | `pullback`, then the end-card plate | Staged + plate |

**Password interpretation:** in the game, `PLZKTKS` works on the first try.
To keep the beat sheet's failed first attempt truthful, the note is held
upside down and read as `SKTKZLP`. That entry produces the game's real
"That password did not open the seal. Try again." The lead says
"...right", turns the paper the right way up, and the chant enters the real
password.

**Departure from the beat sheet (user, 2026-10-07):** the VERY SMALL
FOLLOWING sign and its lyric are cut from verse 2. Bars 29-32 instead
hold on the dejected teal worker after "That's enough".

**Real-game rhymes kept deliberately:**
- The opening round really earns 3 recruits and 9 donations.
- The teal cultist is the real teal-robed helper.
- The Priest really raises three objections.
- "Make the circle bigger" plays over the real circle, which grew to 32 nodes.

The choir grows with the story (user, 2026-10-07). One wordless voice carries
verses 1 and 2. A second voice joins in chorus 1, then 4 in chorus 2, 6 in the
bridge, 8 in chorus 3, 12 for the password chant and 16 in the final chorus and
tag. A per-section `ritual` amount (0 to 1) turns the added voices from
doublings into ritual harmony:
- low singers an octave down;
- parallel fourths and fifths, which sometimes land on the tritone;
- a low "ohh" drone on each chord root and fifth;
- a cathedral reverb.

The spoiler, "someday" and "Or twenty" fall back to one to three voices. The
final "...for now" is a single voice over the dying ritual drone.

## 4. Lyrics

The singable lyrics are in `tools/music_video/song.json` (64 lines,
369 syllables, 7 voices: lead, choir, Priest, shout, whisper, solo and teal).
They follow the beat sheet's wording, with small changes to fit syllables to
the melody. For example, "nothing alarming, we've got biscuits and a robe" and
"three of them said maybe" are kept. The verse-1 line "I counted them twice"
moves the coin gag into the lyric. "Please, okay, thanks" as the reading of
`PLZKTKS` was confirmed by the user on 2026-10-07.

**Lyric polish (user, 2026-10-07):** dense lines were loosened toward a
lyric + response shape, so it sings rather than raps:
- "Nothing alarming, / we've got biscuits and a robe." is split with a full
  beat of breath. Chorus 2's "please ignore the extra robes" uses the same rhythm.
- "...so that everyone could fit" becomes "We only moved the tables, / just
  to squeeze a few more in."
- Verse 1 opens with "Woke up in Bramblewick, face down on the desk", so the
  lead's incompetence shows from the first line.
- The pre-chorus names the upgrade: "Talking One, inscribed, now I can't stop
  talking!" It sounds like a cursed software install.
- The final chorus repeats "a perfectly small following" from chorus 3 instead
  of "a funny little following". The denial escalates over the giant pull-back.
- "Don't tell the dev" moves half a bar earlier. That leaves three beats of
  silence after the wrong entry before "...right."

The spoiler stays four bars, and the someday verse gets no extra jokes. Its
postcards carry the humour, and its sweetness sets up "Or twenty."

**Holds:** give the gags air instead of adding more. The edit holds on
Gerald's pie, the slumped teal worker, the Priest's "...fine.", the clipboard
turned face-down, the wrong password and "Or twenty". The crowd reveal is the
one smash cut. Keep the mix of real gameplay and staged shots; not every
second needs a designed gag.

`python tools/music_video/song_data.py` validates the song:
- syllable and note counts match;
- pitches are in range;
- sections and shots tile all 96 bars;
- no voice overlaps itself;
- every take and plate named by a shot is known;
- future ideas are labelled plates, never gameplay.

### 4.1 Staged set pieces

Most beat-sheet gags need things the game does not contain. They are built
**inside the real renderer during capture only**, using a capture-side
`mv_set.gd` that draws props in the game's own procedural shape language
(the outlines, palette and listener bodies from `gathering.gd` and
`player.gd`). Nothing is added to `scripts/` or `scenes/`.

| Element | How it is staged |
| --- | --- |
| Folding-table HQ (table, candle, handwritten sign, robe on a hook, biscuit tin, three mismatched chairs) | `mv_set.gd` props on an empty patch of the Bramblewick map |
| Gerald and the pie | A capture-spawned listener with a pie prop, reused in every Gerald beat |
| Countdown, FOLLOWERS: 3, +1 FOLLOWER | Edit overlays; the countdown starts from the game's real 11 seconds |
| Confetti (one piece), tiny fire, a single spark, lightning, the explosion | `CPUParticles2D` or drawn props during capture, or flashes in the edit |
| Crowds of 30, then hundreds; robe racks; the NOTHING ALARMING banner; the statue; tables everywhere | Extra capture-spawned listeners and props; never counted as game recruits |
| Lectern, bell, smoke and dark lighting in the bridge | Props and a `CanvasModulate` around the real Priest encounter |
| Clipboard, chairs, the industrial biscuit tin, golden idol | Props, plus close-ups made in the edit |
| Teal "wind machine" spotlight | A light-cone prop and robe cloth driven by real `step_motion` |
| Map with three pins, the enormous vision, the queue sign | Pillow-drawn plates in the same style as the postcards |

Staged shots carry the corner tag. The video never says that crowds, the HQ or
Gerald are game features.

## 5. Pipeline

```text
song.json ──► compose.py ──► backing.wav + beats.json
    │                  │
    ├────────► sing.py ┴──► vocals.wav ──► mix ──► song.wav (-14 LUFS)
    │
    ├────────► capture_music_video.gd ──► capture/<take>/*.png + events.json
    │
    ├────────► postcards.py ──► future postcard plates (PNG)
    │
    └────────► render_music_video.py ──► captions, beat cuts, mux ──► MP4
                                              │
                                review_music_video.py (contact sheet, loudness, decode)
```

### 5.1 `song.json` (single source of truth)

```json
{
  "fps": 30, "frames_per_beat": 14, "beats_per_bar": 4, "key": "A minor",
  "sections": [{"id": "verse1", "bars": [5, 12], "choir_voices": 1, "shot": "opening"}],
  "lines": [
    {"bar": 5, "beat": 1, "text": "Woke up in Bramblewick",
     "notes": [{"syl": "Woke", "midi": 69, "beats": 0.5}, {"syl": "up", "midi": 71, "beats": 0.5}]}
  ],
  "shots": [
    {"id": "opening", "bars": [5, 12], "take": "opening", "in_event": "first_recruit", "at_bar": 7},
    {"id": "rosecourt", "bars": [73, 74], "plate": "postcard-rosecourt", "label": "IDEA - NOT BUILT YET"}
  ]
}
```

A validator in the tools checks that:
- note beats fill each line;
- sections tile all 96 bars;
- shot ranges cover the timeline without gaps;
- every take named by a shot exists in the capture plan;
- every future-direction shot is a `plate` with the not-built label, never a `take`.

### 5.2 `compose.py`: backing track

- Fork `note()` from `tools/promo/render_promo.py` (pluck, pad, bass, bell).
  Add synthesized drums: kick (pitch-dropping sine), snare/clap (filtered noise
  burst), hats (high-passed noise ticks). Seeded RNG.
- Section-driven arrangement:
  - intro: music box;
  - verse: sparse plucks and kick;
  - chorus: full band;
  - bridge: half-time, bass and choir;
  - chorus 3: up a whole tone;
  - spoiler: drop to kick and bass with a vinyl-stop "record scratch" (pitch-dive on the mix bus);
  - password chant: stomp-clap on every beat;
  - "someday": music box and pads at half time;
  - final tag: thins to one bell.
- Writes `backing.wav` (48 kHz stereo) and `beats.json` (time of every beat
  and bar) for the editor and capture.
- **Built 2026-10-07 (slice 2).** The harmony is a per-bar `chords` list on
  each `song.json` section, with `transpose` applied. The backing track is
  normalized to -18 LUFS under -1 dBTP with a true-peak look-ahead limiter
  (`limit()`), which `sing.py` reuses. Gags have their own arrangement moments:
  - the band deflates after "That's enough";
  - OBJECTION stabs;
  - the band drops out on "...fine";
  - a vinyl stop into the spoiler;
  - three beats of dead air after the wrong password;
  - a shimmer as the seal opens;
  - the enormous daydream is cut off for "Or twenty".

  These moments are listed as `cues` in `beats.json`.

### 5.3 `sing.py`: the growing wordless choir

Extends the approach in `tools/build_game_audio.py` into source-filter singing.
A harmonic source with continuous phase passes through a cascade of moving
vowel formants, computed per sample.

- **Pitch per note** from `song.json`, with portamento between legato notes,
  delayed vibrato (about 5.5 Hz, ±30 cents, after 150 ms) and slow drift. The
  lead sings the written melody (up to E5). On high notes it opens the vowel,
  keeping F1 above the pitch, as singers do.
- **Open, human timbre:** wide resonances, a bright source (about -21 dB from
  2 to 8 kHz), a singer's ring near 3 kHz and audible breath. Fast pitch
  jitter and slow loudness shimmer keep sustained notes from sounding like a
  pure tone.
- **Wordless:** each line is sung on a slow vowel arc (for example "oh" to
  "ah" in the verses, "ah" to "oh" in the choruses). It re-articulates notes
  with soft dips, not consonants. Lyrics appear
  only in the captions.
- **Growth:** the section's `choir_voices` sets the singer count. Below ritual
  0.4, the added singers double the lead at the unison or an octave apart.
  From 0.4 on, they become organum: an octave below and diatonic fourths and
  fifths below, sung by darker `bass` voices. Above 0.75, a two-part drone
  holds each bar's chord root and fifth. Each singer has its own
  vibrato rate, phase and depth, its own pitch wander and vocal-tract size, and
  up to ±50 ms of timing spread, so the copies do not phase-lock into one
  thick voice. Detune, stereo width, choir level and cathedral reverb send all
  grow with `ritual`, while the lead recedes into the choir. The final chorus
  is the loudest vocal section.
- **Articulated exceptions:** the password chant, the shouts ("plus one!",
  "OBJECTION!") and the whispers keep their syllables and consonant bursts.
  The password chant was approved in the first listening test.
- **Characters:** the Priest sings low and wordless; the teal helper is a
  brighter wordless voice.
- **Mix:** one vocal gain for the whole song, so the growth is heard as
  written. Light ducking of the backing under the lead. The master is
  normalized to -14 LUFS integrated, under -1 dBTP, with the true-peak limiter
  from `compose.py`.

**Slice 3 history.** The first prototype (`a115f80`) sang vowel-matched
syllables. The user rejected that direction and asked for the version above.
The second prototype renders the whole song as a draft (`prototype_full.wav`)
plus excerpts. The user's notes on it were a nasal, "blocked nose" tone, a lead
that never reached the high notes, and an ending that did not sound like 16
singers. The third prototype adds the brighter timbre, the written-pitch lead
and the independent singers described above.

### 5.4 `capture_music_video.gd`: takes and choreography

Built 2026-10-07 (slice 6). Same isolation pattern as `capture_promo.gd`:
fixed 60 Hz physics, every second step saved for 30 fps, funded build setup
cut away, and persistence disabled before each scene enters the tree.

- **Resolution:** the game renders off-screen in a 1920 x 1080 `SubViewport`.
  The game view is widened from 1280 x 800 to 1422 x 800, so the output is
  native 16:9 and nothing is cropped. The ritual and title screens lay out in
  full. The capture does not depend on the monitor size: a 1920 x 1200 window
  was clamped by this display. The visible window mirrors the frames being
  captured; closing it ends the capture.
- **Clean frames:** `hud_layout` and the settings button are hidden. Village
  takes also hide the ritual overlay. Staged cameras are clamped to the map,
  so no frame shows the void past its edge.
- **Event log:** each take writes `events.json`, which holds:
  - its frame count;
  - for staged takes, the first and last song bar and the two-beat handles;
  - frame-stamped events (recruits, `third_recruit`, `helper_recruit`, `purchase`, `objection`, `priest_convinced`, `wrong_password`, `letter_*`, `seal_open`, `travel`, `teal_step_forward`, `teal_slump`, `statue_lifted` and the other staged beats);
  - the take's checks.

  The editor shifts each real take's in-point so that its `in_event` lands on
  the shot's `at_bar`.
- **Staging (labelled):** everything staged uses public properties, the game's
  own classes (`Gathering.Listener` followers, the `Helper`) and capture-only
  props from `tools/music_video/mv_set.gd` in the game's flat style. Those
  props include the HQ table, chairs, candle, sign, robe hook, biscuit tins,
  ceremonial bowl, pie, fire, banners, robe racks, lectern, bell, spotlight,
  stone statue, golden idol, clipboard, rug and flags. Gerald is a listener
  with a pie and a name tag. No file under `scripts/` or `scenes/` changes.
- **The helper, featured (user, 2026-10-07):**
  - the plus-one round (bars 21-24) is a real round with the helper unlocked; the camera keeps the cultist and the recruiting helper in frame;
  - the teal helper is one of the four at the chorus HQ;
  - it stands by the cultist in the crowd;
  - it takes the spotlight at the stall;
  - it walks with the carried statue and idol;
  - it sits in at the humble HQ.

  The helper appears without its status caption (user, 2026-10-07):
  - staged takes draw the game's teal-helper shape from `mv_set.gd`, and the game's own idle helper is hidden;
  - in real rounds, the real helper keeps working, hidden, while an identical caption-free double follows its position every frame, so its behaviour on screen is unchanged.

  Gerald keeps his name tag, which the pie joke needs.
- **The statue is carried (user, 2026-10-07):** followers lift the statue
  onto their shoulders and carry it on poles, both in the Bellmarket
  procession and in the closing procession. The closing column goes around
  the east side of the village well, never through it.
- **Password take:** the title screen with `password_input.secret = false`
  (staged, labelled), so the letters are readable.
  1. `SKTKZLP` (the note held upside down) is typed one character per beat and submitted through the real `text_submitted` path on bar 63, which shows the real error.
  2. The field clears on "Not that one."
  3. `PLZKTKS` is typed one letter per shouted beat and submitted on bar 68, which opens the seal.
  4. `2 · Bellmarket` is pressed, and the game really travels.
- **Takes (18, all named by `song.json`):**
  - real gameplay:
    - `opening`;
    - `full_core_dance` (the helper round);
    - `ritual_first` (the real first inscription);
    - `constellation_tour` (32 inscribed nodes);
    - `debate`: a real Priest encounter on a staged set with a lectern, a bell and Gerald, framed close so the Priest reads clearly, after 4.5 s of establishing set;
    - `bellmarket`: a real round after the real unlock;
  - staged:
    - `hq_wake`, `coins_pie`, `chorus_hq`, `stall_teal`, `crowd`, `crowd_wide` (same crowd, same seed), `bellmarket_procession`, `clipboard`, `hq_humble`, `hq_final`, `pullback`;
    - `password` (real UI, staged timing and unmasking).
- **Checks:**
  - the opening earns 3 recruits and 9 donations;
  - Quickened Words I is bought with those real donations;
  - the helper is unlocked and really recruits, and the round recruits at least 15;
  - the circle has 32 inscribed nodes;
  - the Priest is really convinced;
  - the completed Bramblewick circle unlocks Bellmarket, travel succeeds and Bellmarket has five districts;
  - the wrong password fails, `PLZKTKS` opens the seal and level 2 lands in Bellmarket;
  - the bowl gets nine coins;
  - every frame is 1920 x 1080;
  - the run ends with 0 failures.

### 5.5 `postcards.py`: future direction plates

- Draws six 1920 x 1080 plates with Pillow: parchment card, lilac seal
  border, place name in Georgia, a small scene built from procedural
  silhouettes (listener bodies with the motif props in section 2.1), and a
  slightly rotated "IDEA - NOT BUILT YET" rubber stamp.
- Motion comes in the edit (slow zoompan, card slides in on the downbeat);
  the plates themselves stay static, original and reproducible.
- The source lines for each idea are recorded in `tools/music_video/README.md`,
  so the video never overstates the roadmap. If FUTURE_LEVELS changes before
  rendering, the postcards follow it.

### 5.6 `render_music_video.py`: edit

- Builds the edit from `song.json` shots and `beats.json`. Every cut is on a bar
  line; punch-in zooms and brightness flashes go on chosen downbeats
  (`zoompan`, `eq`). Speed ramps are allowed only on labelled staged shots.
- **Karaoke captions:** a lower-third line rendered with Pillow (Georgia and
  Trebuchet, cream and lilac, as in the promo), with the active syllable
  highlighted by note timing. Frames are piped to FFmpeg as an RGBA overlay
  stream.
- **Password stamps:** each letter of `PLZKTKS` slams in large and
  centre-screen on its beat, then the full word resolves into
  "PLZ · K · TKS = please, okay, thanks", with a "SPOILER" ribbon.
- Title and end cards reuse the promo plate style. The two promo key-art
  illustrations may be reused, since they are this project's own art (record it).
- Output: `exports/music_video/Small_Following_Just_a_Small_Following.mp4`,
  1920 x 1080, 30 fps, H.264/yuv420p, 48 kHz stereo AAC, fast start, plus
  `timeline.json` and FFmpeg logs.

**Built for slice 7.** `render_music_video.py --cut chorus` (or `--cut full`)
edits from the captured takes:
- a real shot with an `in_event` is shifted so that event lands on its `at_bar`; a beat-timed take starts after its two-beat handle;
- the editor fails if a shot would need frames its take does not have, or if a cut falls off a bar line.

It draws:
- `song.json` `overlays` ("FOLLOWERS: 3" in the game's HUD panel style, a rising "+1 FOLLOWER" like the game's donation popups);
- a STAGED corner tag on staged shots;
- a shot's own `tag`, such as the debate's "REAL GAMEPLAY · STAGED SET" (user, 2026-10-07).

Captions and password stamps are shared with the animatic.

### 5.7 `review_music_video.py`

The script checks that:
- the frame count is 5,376 (179.2 s x 30), and a full decode reports no errors;
- loudness and true peak meet the targets, with no silence gaps.

It also produces:
- a contact sheet of one frame per section;
- per-section stills showing caption sync;
- a frame from each future postcard, to confirm the not-built stamp is visible;
- a SHA-256 of the final file.

Visual and musical acceptance remain human checks.

## 6. Files

| Path | Purpose |
| --- | --- |
| `tools/music_video/README.md` | Reproduction commands, provenance, future-idea sources, verification record |
| `tools/music_video/song.json` | Lyrics, melody, sections, shot list |
| `tools/music_video/song_data.py` | Load and validate `song.json`; shared timing helpers |
| `tools/music_video/compose.py` | Backing track and beat grid |
| `tools/music_video/sing.py` | Formant choir vocals and final mix |
| `tools/music_video/capture_music_video.gd` | Isolated takes, choreography, password take, event log |
| `tools/music_video/postcards.py` | Future-direction postcard plates |
| `tools/music_video/render_music_video.py` | Edit, captions and mux |
| `tools/music_video/review_music_video.py` | Automated review |
| `exports/music_video/` | Ignored outputs (WAVs, frames, plates, shots, final MP4) |

## 7. Slices

Commit each slice when it is complete and validated (see
[COMMIT_STYLE](COMMIT_STYLE.md)).

| # | Slice | Outcome | Checks | Human gate |
| --- | --- | --- | --- | --- |
| 1 | Song data | `song.json` with full lyrics, melody, sections and shots; validator | Validator passes; 96 bars tile; future shots are plates | **User approves lyrics, title and the password gag** |
| 2 | Backing track | `backing.wav` + `beats.json` | Duration 179.2 s; 384 beats; loudness measured | Listen |
| 3 | Voice prototype | Whole-song draft of the wordless growing choir (revised after the first 8-bar test), plus the "P-L-Z" chant | Pitch tracks notes (measured); no clipping | **User listening test: keep, retune or rethink** |
| 4 | Full vocals and mix | `song.wav` (built 2026-10-07; `sing.py` checks pass: 179.200 s, -14.0 LUFS, -1.3 dBTP, FFmpeg agrees, only the planned dead air) | -14 LUFS ±1, ≤ -1 dBTP | Listen |
| 5 | Animatic | Song + captions + postcards over the backdrop, no footage (built 2026-10-07: `animatic.mp4`; 369 syllables within half a frame of their notes; 5,376 frames, 179.200 s, clean decode) | Caption timings match note starts | Sing-along check |
| 6 | Capture | All takes + `events.json` (built 2026-10-07: 18 takes, 6,275 frames, 0 failures; every shot fits its take) | Promo-style recruit/victory assertions; password and travel assertions; 0 failures | Inspect contact frames |
| 7 | 30 s chorus cut | Bars 17-32 (29.9 s) edited (built 2026-10-07: `chorus_cut.mp4`, 896 frames, 5 shots cut on bar lines; the helper's recruit lands on "plus one!", and the stall camera pushes in on the helper's spotlight) | Frame count; cuts on bar frames | **First real review** |
| 8 | Full video | 179.2 s MP4 | Full review script | Watch-through |
| 9 | Handoff | README section, VERIFICATION entry, provenance | Link check | - |

## 8. Risks

- **Synth vocals sound bad.** Mitigated by the slice 3 gate. The fallback is a
  bigger instrumental lead with the choir only on hooks ("small following",
  "Objection!", the password chant).
- **Real events do not land near beats.** Mitigated by in-point shifting from
  `events.json`; staged shots carry the tightest sync.
- **Future section read as promises.** Mitigated by the not-built stamp on
  every postcard, plates rather than footage, a validator rule and the end-card
  line. The ideas come only from the existing design docs.
- **The password spoils the progression.** This is accepted by the user as the
  joke. It grants no upgrades in-game, and the video says so: "your upgrades
  come with you".
- **Choreography edits private state.** Restricted to listener and player
  transforms, `password_input.secret` and existing public methods. If a
  capture script breaks because game internals change, the capture fails
  loudly rather than drifting.
- **16:9 crop clips ritual or title text.** Resolved in slice 6: the capture
  renders native 16:9 by widening the game view, so nothing is cropped.
- **Render time and disk use.** The slice 6 capture is 6,275 frames at
  1920 x 1080 PNG, 1.5 GB in ignored exports, in about 15 minutes. Delete capture frames
  after encoding shots if space is tight.
