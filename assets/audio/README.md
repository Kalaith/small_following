# Small Following audio provenance

Added 2026-10-03. These assets are original project-generated audio, with no
third-party recordings, melodies, voices or sample-pack material. No external
asset license or attribution requirement was introduced; use follows the
project's own distribution terms. The synthetic speech is not Sims/Simlish
audio and does not imitate a recorded performer.

| Files | Source and format |
| --- | --- |
| `village-score.ogg` | Original promo WAV composed by `tools/promo/render_promo.py`; 72 seconds, stereo 48 kHz Vorbis, quality 4; normalized to a target -18 LUFS / -3 dBTP before encoding |
| `step-1.wav` through `step-4.wav` | Original seeded noise and soft low tones; 0.12 seconds, mono 24 kHz 16-bit PCM |
| `murmur-1.wav` through `murmur-6.wav` | Original harmonic/formant synthesis; three nonsense vowel-like syllables per clip, 0.44 seconds, mono 24 kHz 16-bit PCM |

Rebuild with the already installed Python/NumPy and FFmpeg:

```powershell
python tools/build_game_audio.py
```

The music source is `exports/promo/assets/small-following-original-score.wav`.
The builder reads it without modifying it. If absent, it can be recreated by
calling `synthesize_score()` in the promo renderer after creating that output
directory. The committed game audio requires no build tools at runtime.

The music retains the promo's gentle opening and closing fades; it repeats as
a complete musical piece, with a quiet breath at the loop boundary. It does
not restart every 11-second round. Runtime loop is enabled on a duplicate of
the imported resource. WAV effects do not loop. Godot import sidecars are
committed, and all playable files live outside ignored promo exports.

Mix/cadence constants live in `scripts/game_audio.gd`. Music, steps and speech
use separate single-voice players at -15, -9 and -15 dB respectively. Effects
and timbre are provisional pending subjective listening on actual speakers.
