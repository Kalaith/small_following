"""Compose the music video's backing track and beat grid from song.json.

Run: python tools/music_video/compose.py
Writes exports/music_video/audio/backing.wav (48 kHz stereo, 16-bit PCM) and
exports/music_video/beats.json. Original, synthesized and seeded: no samples,
borrowed melodies, voices or model downloads. The plucks, pads, bass and bells
are forked from tools/promo/render_promo.py; drums are synthesized here.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import sys
import wave

import numpy as np
from scipy import signal

import song_data

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "exports" / "music_video"
AUDIO = OUT / "audio"
SR = 48000
SEED = 2026_10_07
BACKING_LUFS = -18.0  # leaves room for the choir; the final mix targets -14
TRUE_PEAK_LIMIT = -1.0

ROLES = {
    "intro": "intro", "verse1": "verse", "verse2": "verse", "pre1": "pre", "pre2": "pre",
    "chorus1": "chorus", "chorus2": "chorus", "chorus3": "chorus", "final_chorus": "chorus",
    "bridge": "bridge", "spoiler": "spoiler", "password": "password",
    "someday": "someday", "or_twenty": "or_twenty", "tag": "tag",
}
INTENSITY = {"chorus1": 1.0, "chorus2": 1.08, "chorus3": 1.16, "final_chorus": 1.22}


class Mix:
    """Stereo dry bus plus a reverb send, addressed in beats."""

    def __init__(self, song: dict):
        self.per_beat = SR * song["frames_per_beat"] // song["fps"]  # 22,400 samples
        self.length = song["bars"] * song["beats_per_bar"] * self.per_beat
        self.dry = np.zeros((self.length, 2), np.float32)
        self.send = np.zeros((self.length, 2), np.float32)
        self.rng = np.random.default_rng(SEED)

    def add(self, beat: float, sound: np.ndarray, gain: float, pan: float = 0.0,
            reverb: float = 0.25) -> None:
        start = round(beat * self.per_beat)
        n = min(len(sound), self.length - start)
        if n <= 0:
            return
        left, right = math.sqrt((1 - pan) / 2), math.sqrt((1 + pan) / 2)
        part = sound[:n] * gain
        for bus, level in ((self.dry, 1.0), (self.send, reverb)):
            bus[start:start + n, 0] += part * left * level
            bus[start:start + n, 1] += part * right * level

    def beats(self, count: float) -> float:
        return count * self.per_beat / SR


# --- instruments (mono float32 arrays) -------------------------------------

def _t(seconds: float) -> np.ndarray:
    return np.arange(max(1, round(seconds * SR)), dtype=np.float32) / SR


def hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


def _release(t: np.ndarray, length: float, fade: float) -> np.ndarray:
    return np.clip((length - t) / fade, 0, 1)


def pluck(midi: float, length: float) -> np.ndarray:
    t, f = _t(length), hz(midi)
    tone = sum((1 / h ** 1.9) * np.sin(2 * np.pi * f * h * t) * np.exp(-t * h * .45)
               for h in range(1, 5))
    return tone * (1 - np.exp(-t * 200)) * np.exp(-t * 4.6) * _release(t, length, .08)


def pad(midi: float, length: float) -> np.ndarray:
    t, f = _t(length), hz(midi)
    tone = (np.sin(2 * np.pi * f * t) + .25 * np.sin(2 * np.pi * f * 2.002 * t)
            + .12 * np.sin(2 * np.pi * f * .998 * t))
    return tone * np.minimum(t / .35, 1) * _release(t, length, .6)


def bass(midi: float, length: float) -> np.ndarray:
    t, f = _t(length), hz(midi)
    tone = np.sin(2 * np.pi * f * t) + .3 * np.sin(4 * np.pi * f * t) + .1 * np.sin(6 * np.pi * f * t)
    return tone * (1 - np.exp(-t * 100)) * np.exp(-t * 2.2) * _release(t, length, .06)


def bell(midi: float, length: float) -> np.ndarray:
    t, f = _t(length), hz(midi)
    tone = np.sin(2 * np.pi * f * t) + .3 * np.sin(2 * np.pi * f * 2.756 * t) * np.exp(-t * 5)
    return tone * (1 - np.exp(-t * 150)) * np.exp(-t * 2.1) * _release(t, length, .12)


def music_box(midi: float, length: float) -> np.ndarray:
    t, f = _t(length), hz(midi)
    tone = (np.sin(2 * np.pi * f * t) + .25 * np.sin(2 * np.pi * f * 3.01 * t) * np.exp(-t * 12)
            + .1 * np.sin(2 * np.pi * f * 5.3 * t) * np.exp(-t * 20))
    return tone * (1 - np.exp(-t * 400)) * np.exp(-t * 2.4) * _release(t, length, .1)


def stab(midis: list[int], length: float, rng: np.random.Generator) -> np.ndarray:
    """A brassy orchestra-hit chord for each OBJECTION."""
    t = _t(length)
    tone = np.zeros_like(t)
    for m in midis:
        f = hz(m)
        tone += sum((1 / h) * np.sin(2 * np.pi * f * h * t) * np.exp(-t * h * 1.2) for h in range(1, 11))
    noise = _filtered(rng.normal(0, 1, len(t)), "bandpass", (300, 3000)) * np.exp(-t * 30)
    return (tone / len(midis) + .5 * noise) * (1 - np.exp(-t * 600)) * np.exp(-t * 4)


def _filtered(x: np.ndarray, kind: str, cutoff, order: int = 4) -> np.ndarray:
    sos = signal.butter(order, cutoff, kind, fs=SR, output="sos")
    return signal.sosfilt(sos, x).astype(np.float32)


def kick(low: float = 48.0) -> np.ndarray:
    t = _t(.4)
    freq = low + 110 * np.exp(-t * 28)
    body = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t * 7)
    click = (1 - np.exp(-t * 4000)) * np.exp(-t * 900) * .4
    return (body + click).astype(np.float32)


def snare(rng: np.random.Generator) -> np.ndarray:
    t = _t(.25)
    tone = np.sin(2 * np.pi * 185 * t) * np.exp(-t * 22) * .5
    noise = _filtered(rng.normal(0, 1, len(t)), "bandpass", (1000, 8000)) * np.exp(-t * 18)
    return (tone + noise).astype(np.float32)


def clap(rng: np.random.Generator) -> np.ndarray:
    t = _t(.3)
    env = sum(np.where(t >= d, np.exp(-(t - d) * 140), 0) for d in (0, .011, .022))
    env = env + np.where(t >= .03, np.exp(-(t - .03) * 14) * .6, 0)
    return (_filtered(rng.normal(0, 1, len(t)), "bandpass", (900, 3200)) * env).astype(np.float32)


def hat(rng: np.random.Generator, open_: bool = False) -> np.ndarray:
    t = _t(.4 if open_ else .08)
    noise = _filtered(rng.normal(0, 1, len(t)), "highpass", 7000)
    return (noise * np.exp(-t * (9 if open_ else 60))).astype(np.float32)


def crash(rng: np.random.Generator) -> np.ndarray:
    t = _t(2.6)
    noise = _filtered(rng.normal(0, 1, len(t)), "highpass", 3500)
    return (noise * (1 - np.exp(-t * 300)) * np.exp(-t * 1.6)).astype(np.float32)


def tick() -> np.ndarray:
    """The HQ's wall clock counting down from 00:11."""
    t = _t(.08)
    return ((np.sin(2 * np.pi * 1800 * t) + .5 * np.sin(2 * np.pi * 2900 * t)) * np.exp(-t * 70)).astype(np.float32)


def stomp(rng: np.random.Generator) -> np.ndarray:
    thud = kick(40.0)
    t = _t(len(thud) / SR)
    floor = _filtered(rng.normal(0, 1, len(t)), "lowpass", 300) * np.exp(-t * 25)
    return (thud + 1.5 * floor).astype(np.float32)


# --- harmony -----------------------------------------------------------------

def triad(root: int, minor: bool, centre: int = 60) -> list[int]:
    """Closest root-position-or-inversion voicing of a triad around a centre note."""
    pcs = [root, (root + (3 if minor else 4)) % 12, (root + 7) % 12]
    notes = []
    for pc in pcs:
        candidates = [pc + 12 * o for o in range(2, 8)]
        notes.append(min(candidates, key=lambda m: abs(m - centre)))
    return sorted(notes)


def bass_root(root: int) -> int:
    note = 36 + root
    return note - 12 if note > 44 else note


# --- arrangement -------------------------------------------------------------

def arrange(song: dict, mix: Mix) -> list[dict]:
    """Play every bar in its section's style. Returns editorial cues."""
    rng, per_bar = mix.rng, song["beats_per_bar"]
    chords = song_data.bar_chords(song)
    cues: list[dict] = []
    for bar in range(1, song["bars"] + 1):
        section = song_data.section_at(song, bar)
        sid, role = section["id"], ROLES[section["id"]]
        local = bar - section["bars"][0]
        last = bar == section["bars"][1]
        root, minor = chords[bar - 1]
        b0 = (bar - 1) * per_bar
        voicing, low = triad(root, minor), bass_root(root)
        beat_s = mix.beats(1)
        level = INTENSITY.get(sid, 1.0)

        def drums(kicks, snares=(), hats=(), claps=(), scale=1.0):
            for b in kicks:
                mix.add(b0 + b, kick(), .7 * scale, reverb=.05)
            for b in snares:
                mix.add(b0 + b, snare(rng), .38 * scale, pan=.05, reverb=.2)
            for b in claps:
                mix.add(b0 + b, clap(rng), .34 * scale, pan=-.05, reverb=.25)
            for i, b in enumerate(hats):
                mix.add(b0 + b, hat(rng), .10 * scale, pan=.3 if i % 2 else .2, reverb=.05)

        def pads(gain, centre=60, beats=4.0):
            for m in triad(root, minor, centre):
                mix.add(b0, pad(m, mix.beats(beats) + .4), gain, pan=-.25, reverb=.5)

        def arpeggio(kind, step, gain, octave=12, beats=4.0):
            pattern = [0, 1, 2, 1]
            count = int(beats / step)
            for i in range(count):
                m = voicing[pattern[i % 4]] + octave
                mix.add(b0 + i * step, kind(m, beat_s * 2.5), gain, pan=(-1) ** i * .35, reverb=.35)

        def roll(start, gain=.3):
            """A snare roll from `start` to the bar line, getting louder."""
            steps = int((per_bar - start) / .25)
            for i in range(steps):
                mix.add(b0 + start + i * .25, snare(rng), gain * (.4 + .6 * i / max(1, steps - 1)), reverb=.2)

        if role == "intro":
            arpeggio(music_box, .5, .11, octave=24)
            if local >= 2:
                pads(.03)
            for b in range(per_bar):  # 00:11 countdown ticks
                mix.add(b0 + b, tick(), .16 if local >= 1 else .08, pan=.4, reverb=.1)
            if last:
                drums([], hats=[3, 3.5])
        elif role == "verse":
            deflated = sid == "verse2" and bar >= 30  # the teal worker slumps
            if deflated:
                pads(.03, centre=55)
                mix.add(b0, bell(voicing[0] + 12, beat_s * 4), .07, pan=.2, reverb=.6)
                mix.add(b0 + 2, bell(voicing[1] + 12, beat_s * 3), .05, pan=-.2, reverb=.6)
                mix.add(b0, bass(low, beat_s * 3.5), .30)
                if last:
                    roll(2, .22)
                    cues.append(cue(song, bar, 3, "snare roll into pre-chorus 2"))
            else:
                drums([0, 2, 2.5], hats=[.5, 1.5, 2.5, 3.5] if sid == "verse2" else [1.5, 3.5])
                for b, note in ((0, low), (1.5, low), (2, low + 7), (3.5, low)):
                    mix.add(b0 + b, bass(note, beat_s * .9), .32)
                arpeggio(pluck, .5, .08)
                pads(.022, centre=57)
                if bar == 29:
                    cues.append(cue(song, bar, 1, "That's enough: band deflates"))
        elif role == "pre":
            drums([0, 2], snares=[1, 3], hats=[x * .5 for x in range(8)])
            for i in range(8):
                mix.add(b0 + i * .5, bass(low, beat_s * .45), .30)
            arpeggio(pluck, .5, .09)
            pads(.03)
            if last:
                roll(2)
        elif role == "chorus":
            if local == 0:
                mix.add(b0, crash(rng), .2 * level, pan=-.2, reverb=.3)
                cues.append(cue(song, bar, 1, f"{sid} downbeat"))
            drums([0, 1, 2, 3], hats=[.5, 1.5, 2.5, 3.5], claps=[1, 3], scale=level)
            for i in range(8):
                mix.add(b0 + i * .5, bass(low + (12 if i % 2 else 0), beat_s * .45), .30 * level)
            arpeggio(pluck, .5, .085 * level)
            pads(.032 * level)
            if sid == "final_chorus":  # the HQ is quietly not humble
                for i, m in enumerate(voicing):
                    mix.add(b0 + i * 1.333, bell(m + 24, beat_s * 3), .05, pan=.4, reverb=.6)
            if sid == "chorus2" and bar == 41:
                mix.add(b0, crash(rng), .26, pan=.2, reverb=.3)
                cues.append(cue(song, bar, 1, "crowd reveal smash cut"))
            if last and sid != "final_chorus":
                mix.add(b0 + 3.5, snare(rng), .3)
        elif role == "bridge":
            if bar == 52:  # "...fine." The room deflates.
                pads(.025, centre=52, beats=3.5)
                cues.append(cue(song, bar, 1, "Priest: ...fine (hold)"))
                mix.add(b0 + 3, kick(), .5)
                mix.add(b0 + 3.5, snare(rng), .35)
                continue
            drums([0], snares=[2] if bar != 51 else [], scale=.9)
            mix.add(b0, bass(low - 12 if low - 12 >= 28 else low, beat_s * 3.8), .38)
            pads(.03, centre=50)
            if local % 2 == 0:  # the staged bell tolls
                mix.add(b0, bell(57, beat_s * 7), .10, pan=.3, reverb=.7)
            if bar in (46, 48, 50):
                for b in (0, .5, 1):
                    mix.add(b0 + b, stab(triad(5, False, 55) + [53 + 12], beat_s * 1.2, rng), .16, reverb=.4)
                cues.append(cue(song, bar, 1, "OBJECTION stabs"))
            if bar == 51:
                roll(0, .3)
        elif role == "spoiler":
            if local == 0:
                cues.append(cue(song, bar, 1, "after the record scratch"))
            if bar == 63:
                mix.add(b0, bass(low, beat_s * .9), .3)
                cues.append(cue(song, bar, 2, "dead air: wrong password (3 beats)"))
                continue
            drums([0, 2] if bar < 64 else [0], scale=.6)
            mix.add(b0, bass(low, beat_s * 1.8), .3)
            if bar < 64:
                mix.add(b0 + 2, bass(low, beat_s * 1.8), .3)
            else:
                mix.add(b0 + 2, pluck(voicing[0] + 12, beat_s * 2), .06, reverb=.4)
        elif role == "password":
            for b in range(per_bar):
                mix.add(b0 + b, stomp(rng), .7, reverb=.15)
                mix.add(b0 + b, bass(low, beat_s * .8), .30)
            drums([], claps=[1, 3], scale=1.1)
            if bar == 67:
                mix.add(b0, crash(rng), .2)
                pads(.04, beats=8)
            if bar == 68:  # the seal opens
                for i, m in enumerate([72, 76, 79, 84, 88, 91, 96]):
                    mix.add(b0 + i * .25, bell(m, beat_s * 4), .06, pan=-.6 + i * .2, reverb=.7)
                cues.append(cue(song, bar, 1, "seal opens shimmer"))
        elif role == "someday":
            if local == 0:
                cues.append(cue(song, bar, 1, "someday: half time"))
            drums([0], scale=.45)
            arpeggio(music_box, 1.0, .10, octave=12)
            pads(.032)
            mix.add(b0, bass(low, beat_s * 3.8), .22)
        elif role == "or_twenty":
            if bar == 81:  # the enormous vision
                mix.add(b0, crash(rng), .3)
                mix.add(b0, kick(), .9)
                for centre in (48, 60, 72):
                    pads(.05, centre=centre)
                mix.add(b0, bass(low, beat_s * 4), .38)
                for m in voicing:
                    mix.add(b0, stab([m, m + 12], beat_s * 3, rng), .12, reverb=.6)
                cues.append(cue(song, bar, 1, "enormous daydream"))
                cues.append(cue(song, bar + 1, 1, "hard cut to silence: Or twenty"))
            else:
                mix.add(b0, music_box(voicing[0] + 24, beat_s * 4), .10, reverb=.5)
                if bar == 84:
                    mix.add(b0 + 2, music_box(voicing[2] + 12, beat_s * 2), .08, reverb=.5)
                    roll(2, .28)
        elif role == "tag":
            if bar == 93:
                pads(.03)
                arpeggio(pluck, 1.0, .07)
                mix.add(b0, bass(low, beat_s * 3.8), .24)
            elif bar < 96:
                pads(.02)
                mix.add(b0, bell(voicing[0] + 12, beat_s * 4), .08, reverb=.6)
            else:
                mix.add(b0, bell(69, beat_s * 4), .09, reverb=.7)
                cues.append(cue(song, bar, 1, "last bell"))
    return cues


def cue(song: dict, bar: int, beat: float, what: str) -> dict:
    index = (bar - 1) * song["beats_per_bar"] + beat - 1
    return {"bar": bar, "beat": beat, "time": round(song_data.seconds(song, index), 6),
            "frame": round(index * song["frames_per_beat"]), "what": what}


# --- mix bus -----------------------------------------------------------------

def reverb(send: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    t = _t(1.8)
    decay = np.exp(-6.9 * t / 1.6)
    wet = np.zeros_like(send)
    pre = round(.018 * SR)
    for channel in range(2):
        ir = rng.normal(0, 1, len(t)).astype(np.float32) * decay
        ir = _filtered(ir, "lowpass", 6000, 2)
        ir[:pre] = 0
        ir /= np.sqrt(np.sum(ir ** 2))
        wet[:, channel] = signal.fftconvolve(send[:, channel], ir)[:len(send)]
    return wet


def vinyl_stop(audio: np.ndarray, start: int, length: int) -> None:
    """Pitch-dive one beat to a halt in place, then silence: the record scratch."""
    n = np.arange(length)
    rate = (1 - n / length) ** 1.6
    position = start + np.cumsum(rate)
    for channel in range(2):
        audio[start:start + length, channel] = np.interp(
            position, np.arange(len(audio)), audio[:, channel]) * (1 - n / length) ** .3


def mute(audio: np.ndarray, start: int, end: int, fade: int = 240) -> None:
    ramp = np.linspace(1, 0, fade, dtype=np.float32)[:, None]
    audio[start:start + fade] *= ramp
    audio[start + fade:end] = 0
    audio[end:end + fade] *= ramp[::-1]


def k_weight(audio: np.ndarray) -> np.ndarray:
    """ITU-R BS.1770 K-weighting at 48 kHz."""
    shelf = ([1.53512485958697, -2.69169618940638, 1.19839281085285],
             [1.0, -1.69065929318241, 0.73248077421585])
    high = ([1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621])
    out = signal.lfilter(*shelf, audio, axis=0)
    return signal.lfilter(*high, out, axis=0)


def loudness(audio: np.ndarray) -> float:
    """Integrated loudness (LUFS), gated per BS.1770-4."""
    weighted = k_weight(audio.astype(np.float64))
    block, hop = round(.4 * SR), round(.1 * SR)
    powers = np.array([np.sum(np.mean(weighted[i:i + block] ** 2, axis=0))
                       for i in range(0, len(weighted) - block + 1, hop)])
    powers = powers[powers > 10 ** ((-70 + .691) / 10)]
    relative = 10 * np.log10(np.mean(powers)) - .691 - 10
    powers = powers[powers > 10 ** ((relative + .691) / 10)]
    return float(10 * np.log10(np.mean(powers)) - .691)


def true_peak(audio: np.ndarray) -> float:
    upsampled = signal.resample_poly(audio, 4, 1, axis=0)
    return float(20 * np.log10(np.max(np.abs(upsampled)) + 1e-12))


def limit(audio: np.ndarray, ceiling_db: float, window: float = .005) -> np.ndarray:
    """True-peak look-ahead brickwall: a min-filtered gain curve, box-smoothed.

    Peaks are detected on a 4x oversampled copy so inter-sample overs count.
    Averaging a min-filtered curve over the same window never exceeds the
    required gain at a peak.
    """
    from scipy.ndimage import minimum_filter1d, uniform_filter1d
    size = max(3, round(window * SR)) | 1
    ceiling = 10 ** (ceiling_db / 20)
    peaks = np.zeros(len(audio))
    for channel in range(audio.shape[1]):
        over = np.abs(signal.resample_poly(audio[:, channel], 4, 1))
        peaks = np.maximum(peaks, over.reshape(-1, 4).max(axis=1))
    needed = np.minimum(1.0, ceiling / (peaks + 1e-12))
    gain = uniform_filter1d(minimum_filter1d(needed, size), size)
    return audio * gain[:, None]


def write_wav(path: Path, audio: np.ndarray) -> None:
    pcm = (np.clip(audio, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())


def beat_grid(song: dict, cues: list[dict]) -> dict:
    per_bar, fpb = song["beats_per_bar"], song["frames_per_beat"]
    total = song["bars"] * per_bar
    beats = [{"index": i, "bar": i // per_bar + 1, "beat": i % per_bar + 1,
              "time": round(song_data.seconds(song, i), 6), "frame": i * fpb}
             for i in range(total)]
    sections = [{"id": s["id"], "bars": s["bars"],
                 "time": round(song_data.seconds(song, (s["bars"][0] - 1) * per_bar), 6),
                 "frame": (s["bars"][0] - 1) * per_bar * fpb} for s in song["sections"]]
    return {"title": song["title"], "bpm": round(song_data.bpm(song), 4), "fps": song["fps"],
            "frames_per_beat": fpb, "beats_per_bar": per_bar, "sample_rate": SR,
            "duration": round(song_data.seconds(song, total), 6), "frames": total * fpb,
            "sections": sections, "cues": sorted(cues, key=lambda c: c["frame"]), "beats": beats}


def main() -> int:
    song = song_data.load()
    errors = song_data.validate(song)
    if errors:
        print("\n".join("ERROR: " + e for e in errors))
        return 1
    AUDIO.mkdir(parents=True, exist_ok=True)
    (OUT / ".gdignore").touch()  # keep Godot from importing generated media

    mix = Mix(song)
    cues = arrange(song, mix)
    audio = mix.dry + .55 * reverb(mix.send, mix.rng)
    audio = signal.sosfilt(signal.butter(2, 30, "highpass", fs=SR, output="sos"), audio, axis=0)

    per_bar, per_beat = song["beats_per_bar"], mix.per_beat
    at = lambda bar, beat: round(((bar - 1) * per_bar + beat - 1) * per_beat)
    vinyl_stop(audio, at(60, 4), per_beat)
    mute(audio, at(61, 1) - 240, at(61, 1))
    cues.append(cue(song, 60, 4, "record scratch (vinyl stop)"))
    mute(audio, at(63, 2), at(64, 1))
    mute(audio, at(82, 1), at(82, 1) + 4800)  # the daydream is cut off mid-ring
    fade = np.minimum((len(audio) - np.arange(len(audio))) / (1.2 * SR), 1)[:, None]
    audio *= fade

    for _ in range(3):  # limiting lowers loudness a little; converge on the target
        audio *= 10 ** ((BACKING_LUFS - loudness(audio)) / 20)
        audio = limit(audio, TRUE_PEAK_LIMIT - .3)
    peak = true_peak(audio)
    if peak > TRUE_PEAK_LIMIT:
        audio *= 10 ** ((TRUE_PEAK_LIMIT - .1 - peak) / 20)
    lufs, peak = loudness(audio), true_peak(audio)

    write_wav(AUDIO / "backing.wav", audio.astype(np.float32))
    grid = beat_grid(song, cues)
    (OUT / "beats.json").write_text(json.dumps(grid, indent=1), encoding="utf-8")
    print(f"backing.wav: {len(audio) / SR:.3f}s, {grid['frames']} frames, "
          f"{len(grid['beats'])} beats, {lufs:.1f} LUFS, {peak:.1f} dBTP")
    print(f"beats.json: {len(grid['sections'])} sections, {len(grid['cues'])} cues")
    return 0


if __name__ == "__main__":
    sys.exit(main())
