"""Sing song.json with a synthesized formant choir.

Run: python tools/music_video/sing.py --prototype
Writes, under exports/music_video/audio/:
  prototype_chorus.wav    bars 17-24 (chorus 1), vocals over the backing track
  prototype_password.wav  bars 65-68 (the P-L-Z chant), vocals over the backing
  prototype_vocals.wav    both excerpts, vocals only
and prints a pitch report measured from the rendered lead and choir.

The voice is source-filter synthesis: a harmonic source with continuous phase,
portamento and delayed vibrato, shaped per sample by a cascade of moving vowel
formants. Each syllable is reduced to a vowel shape plus a consonant from a
small fixed set, so the choir tracks the lyric without pronouncing English.
No recordings, samples, voice services or model downloads are used.
"""
from __future__ import annotations

import argparse
import math
import re
import sys
import wave

import numpy as np
from scipy import signal

import compose
import song_data

SR = compose.SR
SEED = 2026_10_08
CUTOFF = 7500.0  # highest harmonic kept, Hz

# F1, F2, F3 in Hz: Peterson and Barney style averages, opened slightly for singing.
VOWELS = {
    "a": (730, 1090, 2440),   # father
    "ae": (660, 1720, 2410),  # cat
    "e": (530, 1840, 2480),   # bed
    "i": (290, 2250, 2950),   # see
    "I": (400, 1950, 2560),   # sit
    "o": (570, 860, 2410),    # law
    "O": (480, 900, 2400),    # go (start of the glide)
    "u": (310, 870, 2240),    # boot
    "U": (600, 1170, 2390),   # up, schwa
    "er": (490, 1350, 1690),  # her
}
DIPHTHONGS = {"ai": ("a", "I"), "ei": ("e", "I"), "ou": ("O", "u"), "au": ("a", "u"), "oi": ("o", "I")}
NASAL = (280, 1300, 2500)
GLIDE_SHAPES = {"w": (330, 750, 2300), "r": (380, 1100, 1600), "l": (380, 1300, 2700), "y": (280, 2200, 2900)}
BANDWIDTHS = (70, 95, 130)  # narrow, singerly resonances

WORDS = {
    "a": "U", "the": "U", "i": "ai", "my": "ai", "by": "ai", "pie": "ai", "now": "au",
    "down": "au", "how": "au", "you": "u", "to": "u", "could": "U", "would": "U",
    "one": "U", "of": "U", "some": "U", "come": "U", "said": "e", "they": "ei",
    "there's": "e", "there": "e", "were": "er", "psst": "", "why": "ai", "o": "ou",
    "move": "u", "moved": "u", "do": "u", "nough": "U", "bour": "er", "world": "er", "hired": "ai",
}
LETTERS = {"p": ("p", "i"), "l": ("", "e"), "z": ("s", "i"), "k": ("k", "ei"),
           "t": ("t", "i"), "s": ("", "e")}


def shape(syl: str) -> dict:
    """Reduce a lyric syllable to onset, vowel (or diphthong) and coda."""
    word = re.sub(r"[^a-z']", "", syl.lower())
    if syl.strip("(.!?,)").isupper() and len(word) == 1 and word in LETTERS:
        onset, vowel = LETTERS[word]
        return {"onset": onset, "vowel": vowel, "coda": "s" if word == "s" else ""}
    letters = word.replace("'", "")
    head = re.match(r"[^aeiouy]*", letters).group(0) if letters else ""
    onset = "s" if re.match(r"c[eiy]", letters) else _onset(head)
    coda = "s" if re.search(r"(s|ce|se|ts)$", letters) and not letters.endswith("ss") else \
        "t" if re.search(r"[td]$", letters) else "k" if re.search(r"(k|ck|[^n]g)$", letters) else \
        "p" if re.search(r"[pb]$", letters) else ""
    vowel = WORDS.get(word, WORDS.get(letters)) or _vowel(letters)
    return {"onset": onset, "vowel": vowel or "U", "coda": coda}


def _onset(head: str) -> str:
    if not head:
        return ""
    if head.startswith(("sh", "ch")) or head[0] == "j":
        return "sh"
    if head.startswith("th") or head[0] in "fvh":
        return "h"
    first = head[0]
    if first == "c":
        return "k"  # soft c (circle) is caught by the caller below
    for group, sound in (("sz", "s"), ("kqg", "k"), ("td", "t"), ("pb", "p"),
                         ("mn", "n"), ("w", "w"), ("r", "r"), ("l", "l"), ("y", "y")):
        if first in group:
            return sound
    return ""


def _vowel(w: str) -> str:
    rules = (
        (r"tion$", "U"), (r"age$", "I"), (r"ough", "o"), (r"alk", "o"), (r"ew", "u"),
        (r"igh|ight|ind$|ire", "ai"), (r"oo", "u"), (r"ee|ea|ie$|ey$", "i"),
        (r"ay|ai|eigh", "ei"), (r"oi|oy", "oi"), (r"ow$|oa|old", "ou"), (r"ou|ow", "au"),
        (r"ar", "a"), (r"or|all|al$|aw|au", "o"), (r"er|ir|ur", "er"),
        (r"[^aeiou]les?$", "U"), (r"^[^aeiou]e$", "i"),
        (r"a[^aeiou]es?$", "ei"), (r"i[^aeiou]es?$", "ai"), (r"o[^aeiou]es?$", "ou"), (r"u[^aeiou]es?$", "u"),
        (r"[^aeiou]y$|^y$", "i"),
    )
    for pattern, vowel in rules:
        if re.search(pattern, w):
            return vowel
    for letter, vowel in (("a", "ae"), ("e", "e"), ("i", "I"), ("o", "o"), ("u", "U"), ("y", "I")):
        if letter in w:
            return vowel
    return "U"


# --- voices ------------------------------------------------------------------

VOICES = {
    # octave shift, formant scale, source tilt, vibrato (cents, Hz), gain
    "lead": {"octave": -12, "formants": 1.0, "tilt": 1.0, "vibrato": (30, 5.5), "gain": 1.0, "ring": 1.4},
    "solo": {"octave": -12, "formants": 1.0, "tilt": 1.1, "vibrato": (22, 5.0), "gain": .8, "ring": .8},
    "choir": {"octave": -12, "formants": 1.0, "tilt": 1.05, "vibrato": (26, 5.3), "gain": .7, "ring": .9},
    "teal": {"octave": -12, "formants": 1.1, "tilt": .8, "vibrato": (15, 6.5), "gain": .9, "ring": 1.6},
    "priest": {"octave": 0, "formants": .86, "tilt": 1.1, "vibrato": (20, 4.4), "gain": 1.1, "ring": .6},
    "shout": {"octave": 0, "formants": 1.12, "tilt": .65, "vibrato": (0, 5.0), "gain": .75, "ring": 1.2},
    "whisper": {"octave": 0, "formants": 1.0, "tilt": 1.0, "vibrato": (0, 5.0), "gain": .55, "ring": 0},
}
CHORUS_ROLES = {"chorus", "password"}


def copies(song: dict, line: dict, index: int) -> list[dict]:
    """The singers on a line: the lead alone (doubled in choruses), crowds for the rest."""
    section = song_data.section_at(song, line["bar"])
    count = max(1, section["choir_voices"])
    voice = line["voice"]
    rng = np.random.default_rng([SEED, index])
    out = []
    if voice in ("choir", "shout"):
        if voice == "shout":
            count = max(3, count)
        for c in range(count):
            first = c == 0
            out.append({
                "octave": 0 if voice == "shout" else (-12 if c % 2 == 0 else 0),
                "detune": 0.0 if first else float(rng.uniform(-8, 8)),
                "delay": 0.0 if first else float(rng.uniform(-.010, .010)),
                "pan": 0.0 if count == 1 else -.7 + 1.4 * c / (count - 1),
                "gain": 1 / math.sqrt(count),
                "shout_midi": float(rng.uniform(52, 60)),
                "formant_shift": float(rng.uniform(.94, 1.08)),
            })
        return out
    out.append({"octave": VOICES[voice]["octave"], "detune": 0.0, "delay": 0.0, "pan": 0.0,
                "gain": 1.0, "shout_midi": 55.0, "formant_shift": 1.0})
    role = compose.ROLES[section["id"]]
    if voice == "lead" and role in CHORUS_ROLES and count > 1:
        for c in range(count - 1):  # the choir doubles the lead, quietly
            out.append({"octave": -12 if c % 2 else 0, "detune": float(rng.uniform(-8, 8)),
                        "delay": float(rng.uniform(-.012, .012)), "pan": float(rng.uniform(-.6, .6)),
                        "gain": .32 / math.sqrt(count - 1), "shout_midi": 55.0,
                        "formant_shift": float(rng.uniform(.95, 1.1))})
    return out


# --- one singer on one line ---------------------------------------------------

PRE = round(.09 * SR)   # consonants start before the beat
TAIL = round(.35 * SR)


def _smooth(x: np.ndarray) -> np.ndarray:
    return x * x * (3 - 2 * x)


def _cascade(freq: np.ndarray, formants: np.ndarray, scale: float, ring: float) -> np.ndarray:
    """Magnitude of a cascade of vowel resonances (unity at DC) plus fixed F4/F5."""
    gain = np.ones_like(freq)
    tracks = [(formants[i] * scale, BANDWIDTHS[i]) for i in range(3)]
    tracks += [(3300 * scale, 220), (3900 * scale, 280)]
    for centre, width in tracks:
        c2 = centre * centre
        gain *= c2 / np.sqrt((c2 - freq * freq) ** 2 + (freq * width) ** 2)
    if ring:  # the singer's formant: a little ring near 2.9 kHz
        gain *= 1 + ring * np.exp(-.5 * ((freq - 2900 * scale) / 350) ** 2)
    return gain


def _noise(rng: np.random.Generator, seconds: float, kind: str, band) -> np.ndarray:
    n = max(8, round(seconds * SR))
    return compose._filtered(rng.normal(0, 1, n), kind, band)


CONSONANTS = {  # (filter kind, band, length s, level, lead-in s)
    "s": ("highpass", 4500, .075, .55, .075),
    "sh": ("bandpass", (1800, 5000), .07, .5, .07),
    "h": ("bandpass", (900, 4000), .05, .18, .05),
    "k": ("bandpass", (1400, 3200), .028, .7, .03),
    "t": ("bandpass", (3000, 7500), .022, .7, .025),
    "p": ("lowpass", 1600, .018, .8, .02),
}


def render_copy(song: dict, line: dict, singer: dict, voice: str, seed) -> tuple[int, np.ndarray, list]:
    """Mono audio for one singer, its first sample, and the pitched notes (for checks)."""
    spec = VOICES[voice]
    rng = np.random.default_rng(seed)
    per_beat = SR * song["frames_per_beat"] // song["fps"]
    section = song_data.section_at(song, line["bar"])
    transpose = section.get("transpose", 0)
    notes = song_data.parse_notes(line["notes"])
    syls = song_data.syllables(line["syl"])
    total = round(sum(n["beats"] for n in notes) * per_beat)
    start = round(song_data.line_start(song, line) * per_beat + singer["delay"] * SR) - PRE
    n = PRE + total + TAIL

    f0 = np.zeros(n)
    amp = np.zeros(n)
    form = np.zeros((3, n))
    events = []  # (sample, consonant, level)
    pitched = []
    cursor, k = PRE, 0
    prev_hz, prev_end, prev_form = None, -1, None
    whisper = voice == "whisper"
    for i, note in enumerate(notes):
        a, b = cursor, cursor + round(note["beats"] * per_beat)
        cursor = b
        if not note["sung"]:
            continue
        s = shape(syls[k])
        k += 1
        length = b - a
        t = np.arange(length) / SR
        adjacent = prev_end == a
        next_sung = i + 1 < len(notes) and notes[i + 1]["sung"]

        # pitch
        if note["pitch"] is not None:
            target = compose.hz(note["pitch"] + transpose + singer["octave"] + singer["detune"] / 100)
            if voice == "priest":
                target = compose.hz(note["pitch"] + transpose + singer["detune"] / 100)
            glide = min(round(.07 * SR), length // 3)
            curve = np.full(length, target)
            origin = prev_hz if adjacent and prev_hz else target * 2 ** (-.4 / 12)
            ramp = _smooth(np.linspace(0, 1, glide))
            curve[:glide] = origin * (target / origin) ** ramp
            depth, rate = spec["vibrato"]
            if length > .3 * SR and depth:
                onset = np.clip((t - .15) / .2, 0, 1)
                curve *= 2 ** (depth * onset * np.sin(2 * np.pi * rate * t) / 1200)
            drift = np.cumsum(rng.normal(0, 1, length)) / math.sqrt(SR) * 2.5  # cents
            curve *= 2 ** ((drift - drift.mean()) / 1200)
            pitched.append((a, b, target))
        else:  # spoken shout: a falling contour around a crowd member's pitch
            base = compose.hz(singer["shout_midi"] + transpose)
            fall = np.clip(t / max(.05, min(length / SR, .45)), 0, 1)
            curve = base * 2 ** ((2.5 - 5.5 * fall) / 12)
            target = float(curve[-1])
        f0[a:b] = curve
        prev_hz = float(curve[-1])

        # vowel formants with coarticulation
        v1, v2 = DIPHTHONGS.get(s["vowel"], (s["vowel"], None))
        f1 = np.array(VOWELS[v1], float) * singer["formant_shift"]
        if voice == "shout":
            f1[0] *= 1.15
        lead_in = None
        if s["onset"] == "n":
            lead_in = np.array(NASAL, float)
        elif s["onset"] in GLIDE_SHAPES:
            lead_in = np.array(GLIDE_SHAPES[s["onset"]], float)
        origin = lead_in if lead_in is not None else (prev_form if adjacent and prev_form is not None else f1)
        form[:, a:b] = f1[:, None]
        hold = round(.03 * SR) if lead_in is not None else 0
        move = min(round(.05 * SR), max(1, (length - hold) // 3))
        form[:, a:a + hold] = origin[:, None]
        ramp = _smooth(np.linspace(0, 1, move))
        form[:, a + hold:a + hold + move] = origin[:, None] * (1 - ramp) + f1[:, None] * ramp
        if v2:
            f2 = np.array(VOWELS[v2], float) * singer["formant_shift"]
            g0, g1 = a + round(length * .5), a + round(length * .85)
            ramp = _smooth(np.linspace(0, 1, g1 - g0))
            form[:, g0:g1] = f1[:, None] * (1 - ramp) + f2[:, None] * ramp
            form[:, g1:b] = f2[:, None]
        prev_form = form[:, b - 1].copy()

        # loudness envelope
        plosive = s["onset"] in ("k", "t", "p")
        attack = round((.008 if plosive or voice == "shout" else .028) * SR)
        coda_cut = round(.045 * SR) if s["coda"] else 0
        env = np.ones(length)
        if voice == "shout":
            env = np.exp(-t * 2.2)
        elif length > .4 * SR:
            env = 1 - .12 * np.clip((t - .2) / 1.0, 0, 1)
        env[:attack] *= np.linspace(0, 1, attack) if not adjacent or plosive else np.linspace(.4, 1, attack)
        if lead_in is not None and s["onset"] == "n":
            env[:hold] *= .5
        release = round(.04 * SR)
        end = length - coda_cut
        floor = .4 if next_sung and not s["coda"] else 0.0
        env[max(0, end - release):end] *= np.linspace(1, floor, min(release, end))
        env[end:] = floor if floor else 0
        if not next_sung and not s["coda"]:  # let the last vowel ring a little past the note
            tail = min(round(.12 * SR), n - b)
            amp[b:b + tail] = env[end - 1] * np.linspace(1, 0, tail) if end > 0 else 0
            f0[b:b + tail] = f0[b - 1]
            form[:, b:b + tail] = form[:, b - 1:b]
        amp[a:b] = env
        prev_end = b

        if s["onset"] in CONSONANTS:
            events.append((a, s["onset"], 1.0))
        if s["coda"] in CONSONANTS:
            events.append((b - coda_cut, s["coda"], .7, True))

    # fill silent gaps so phase and formants stay continuous
    voiced = np.flatnonzero(f0)
    if len(voiced) == 0:
        return start, np.zeros(n), pitched
    f0 = np.interp(np.arange(n), voiced, f0[voiced])
    for row in range(3):
        filled = np.flatnonzero(form[row])
        form[row] = np.interp(np.arange(n), filled, form[row][filled])

    scale = spec["formants"]
    if whisper:
        out = _whisper(form, amp, scale, rng)
    else:
        phase = 2 * np.pi * np.cumsum(f0) / SR
        out = np.zeros(n)
        top = int(CUTOFF / f0.min()) + 1
        for h in range(1, top + 1):
            freq = h * f0
            weight = (h ** -spec["tilt"]) * _cascade(freq, form, scale, spec["ring"])
            weight[freq > CUTOFF] = 0
            out += weight * np.sin(h * phase)
        out *= amp
        breath = compose._filtered(rng.normal(0, 1, n), "bandpass", (1200, 6000)) * amp
        level = np.sqrt(np.mean(out[amp > .5] ** 2)) if np.any(amp > .5) else 1.0
        out += breath * level * (.18 if voice == "shout" else .05)

    level = np.sqrt(np.mean(out[amp > .5] ** 2)) if np.any(amp > .5) else 1.0
    for event in events:
        where, kind, strength = event[0], event[1], event[2]
        coda = len(event) > 3
        filt, band, seconds, gain, lead = CONSONANTS[kind]
        burst = _noise(rng, seconds, filt, band)
        burst *= np.sin(np.linspace(0, np.pi, len(burst))) ** (.5 if kind in ("s", "sh", "h") else .2)
        burst /= np.max(np.abs(burst)) + 1e-9
        at = where if coda else where - round(lead * SR)
        at = max(0, min(at, n - len(burst)))
        out[at:at + len(burst)] += burst * level * gain * strength * (1.4 if voice == "shout" else 1)
    return start, out * spec["gain"], pitched


def _whisper(form: np.ndarray, amp: np.ndarray, scale: float, rng) -> np.ndarray:
    """Breathy noise through the same vowel resonances, block by block."""
    n = len(amp)
    noise = rng.normal(0, 1, n)
    out = np.zeros(n)
    block = 480
    window = np.hanning(2 * block)
    for start in range(0, n - block, block):
        seg = noise[start:start + 2 * block]
        if len(seg) < 2 * block or amp[start:start + 2 * block].max() == 0:
            continue
        spectrum = np.fft.rfft(seg * window)
        freq = np.fft.rfftfreq(2 * block, 1 / SR)
        shape_ = _cascade(np.maximum(freq, 1.0), form[:, start + block][:, None] * np.ones((1, len(freq))),
                          scale, .5) * np.clip(freq / 600, 0, 1)
        out[start:start + 2 * block] += np.fft.irfft(spectrum * shape_) * window
    return out * amp / 2


# --- whole-song rendering ----------------------------------------------------

def render(song: dict, bars: tuple[int, int] | None = None) -> tuple[np.ndarray, np.ndarray]:
    """Stereo vocals (dry + reverb) for lines starting inside `bars`, and the lead's envelope."""
    per_beat = SR * song["frames_per_beat"] // song["fps"]
    length = song["bars"] * song["beats_per_bar"] * per_beat
    dry = np.zeros((length, 2))
    send = np.zeros((length, 2))
    lead_env = np.zeros(length)
    for index, line in enumerate(song["lines"]):
        if bars and not bars[0] <= line["bar"] <= bars[1]:
            continue
        voice = line["voice"]
        for c, singer in enumerate(copies(song, line, index)):
            start, audio, _ = render_copy(song, line, singer, voice, [SEED, index, c])
            audio = audio * singer["gain"]
            a, b = max(0, start), min(length, start + len(audio))
            part = audio[a - start:b - start]
            left, right = math.sqrt((1 - singer["pan"]) / 2), math.sqrt((1 + singer["pan"]) / 2)
            dry[a:b, 0] += part * left
            dry[a:b, 1] += part * right
            wet = .35 if voice in ("choir", "priest") else .22
            send[a:b, 0] += part * left * wet
            send[a:b, 1] += part * right * wet
            if voice == "lead" and c == 0:
                lead_env[a:b] = np.maximum(lead_env[a:b], np.abs(part))
    wet = compose.reverb(send.astype(np.float32), np.random.default_rng(SEED))
    return dry + .6 * wet, lead_env


def duck(backing: np.ndarray, lead_env: np.ndarray, depth_db: float = -3.0) -> np.ndarray:
    """Lower the backing gently under the lead (50 ms attack/release smoothing)."""
    from scipy.ndimage import uniform_filter1d
    active = (uniform_filter1d(lead_env, round(.05 * SR)) > 1e-3 * (lead_env.max() + 1e-12)).astype(float)
    gain = 10 ** (depth_db * uniform_filter1d(active, round(.1 * SR)) / 20)
    return backing * gain[:, None]


def read_wav(path) -> np.ndarray:
    with wave.open(str(path)) as wav:
        data = np.frombuffer(wav.readframes(wav.getnframes()), "<i2").reshape(-1, 2)
    return data.astype(np.float64) / 32768


def master(audio: np.ndarray, target: float = -14.0) -> np.ndarray:
    for _ in range(3):
        audio = audio * 10 ** ((target - compose.loudness(audio)) / 20)
        audio = compose.limit(audio, compose.TRUE_PEAK_LIMIT - .3)
    peak = compose.true_peak(audio)
    if peak > compose.TRUE_PEAK_LIMIT:
        audio *= 10 ** ((compose.TRUE_PEAK_LIMIT - .1 - peak) / 20)
    return audio


# --- checks ------------------------------------------------------------------

def yin(segment: np.ndarray, low: float = 70, high: float = 1000, threshold: float = .12) -> float | None:
    """Fundamental frequency by the YIN difference function, or None."""
    w = len(segment) // 2
    lags = np.arange(int(SR / high), min(int(SR / low), w))
    if len(lags) < 3:
        return None
    x = segment - segment.mean()
    taus = np.arange(1, lags[-1] + 1)
    d = np.array([np.sum((x[:w] - x[tau:tau + w]) ** 2) for tau in taus])
    cmnd = d * taus / np.maximum(np.cumsum(d), 1e-12)
    for i in range(lags[0] - 1, len(cmnd) - 1):
        if cmnd[i] < threshold and cmnd[i] <= cmnd[i + 1]:
            tau = i + 1
            if 1 <= i < len(cmnd) - 1:  # parabolic refinement
                a, b, c = cmnd[i - 1], cmnd[i], cmnd[i + 1]
                tau += .5 * (a - c) / (a - 2 * b + c + 1e-12)
            return SR / tau
    return None


def pitch_report(song: dict, bars_list) -> list[str]:
    rows, errors = [], []
    for index, line in enumerate(song["lines"]):
        if not any(lo <= line["bar"] <= hi for lo, hi in bars_list):
            continue
        if line["voice"] not in ("lead", "choir"):
            continue
        singer = copies(song, line, index)[0]
        _, audio, pitched = render_copy(song, line, singer, line["voice"], [SEED, index, 0])
        for a, b, target in pitched:
            mid = (a + b) // 2
            half = max(round(.03 * SR), (b - a) // 4)
            seg = audio[mid - half:mid + half]
            est = yin(seg, low=target / 1.6, high=target * 1.6) if len(seg) > 600 else None
            if est is None:
                continue
            errors.append(1200 * math.log2(est / target))
    if not errors:
        return ["pitch: no measurable notes"]
    errors = np.array(errors)
    return [f"pitch: {len(errors)} notes measured (lead and first choir voice, middle of each note)",
            f"pitch: median |error| {np.median(np.abs(errors)):.1f} cents, "
            f"95th percentile {np.percentile(np.abs(errors), 95):.1f}, max {np.max(np.abs(errors)):.1f}"]


# --- entry points ------------------------------------------------------------

def excerpt(song, bars, backing, vocals, lead_env) -> tuple[np.ndarray, np.ndarray]:
    per_bar = song["beats_per_bar"] * (SR * song["frames_per_beat"] // song["fps"])
    a, b = (bars[0] - 1) * per_bar, bars[1] * per_bar + round(.6 * SR)
    b = min(b, len(backing))
    voc = vocals[a:b]
    bed = duck(backing[a:b], lead_env[a:b])
    # Vocals sit about 2 LU above the bed before mastering.
    voc_gain = 10 ** ((compose.loudness(bed) + 2 - compose.loudness(voc)) / 20)
    fade = np.minimum((len(voc) - np.arange(len(voc))) / (.5 * SR), 1)[:, None]
    return (bed + voc * voc_gain) * fade, voc * voc_gain * fade


def prototype(song: dict) -> int:
    windows = [(17, 24), (65, 68)]
    backing = read_wav(compose.AUDIO / "backing.wav")
    vocals = np.zeros_like(backing)
    lead_env = np.zeros(len(backing))
    for bars in windows:
        v, e = render(song, bars)
        vocals += v
        lead_env = np.maximum(lead_env, e)
    names = {(17, 24): "prototype_chorus.wav", (65, 68): "prototype_password.wav"}
    voice_parts = []
    for bars in windows:
        mix, voc = excerpt(song, bars, backing, vocals, lead_env)
        clipped_before = float(np.max(np.abs(mix)))
        mix = master(mix)
        compose.write_wav(compose.AUDIO / names[bars], mix.astype(np.float32))
        print(f"{names[bars]}: bars {bars[0]}-{bars[1]}, {len(mix) / SR:.2f}s, "
              f"{compose.loudness(mix):.1f} LUFS, {compose.true_peak(mix):.1f} dBTP "
              f"(pre-master peak {20 * math.log10(clipped_before + 1e-12):.1f} dBFS)")
        voice_parts += [voc, np.zeros((round(.75 * SR), 2))]
    voc = master(np.concatenate(voice_parts), -16.0)
    compose.write_wav(compose.AUDIO / "prototype_vocals.wav", voc.astype(np.float32))
    print(f"prototype_vocals.wav: {len(voc) / SR:.2f}s, {compose.loudness(voc):.1f} LUFS")
    for row in pitch_report(song, windows):
        print(row)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--prototype", action="store_true", help="render the slice 3 listening test")
    parser.add_argument("--shapes", action="store_true", help="print each syllable's vowel shape")
    args = parser.parse_args()
    song = song_data.load()
    errors = song_data.validate(song)
    if errors:
        print("\n".join("ERROR: " + e for e in errors))
        return 1
    if args.shapes:
        for line in song["lines"]:
            parts = [f"{s}={shape(s)['onset']}/{shape(s)['vowel']}/{shape(s)['coda']}"
                     for s in song_data.syllables(line["syl"])]
            print(f"{line['bar']:>3} {line['voice']:<7} " + " ".join(parts))
        return 0
    if args.prototype:
        return prototype(song)
    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
