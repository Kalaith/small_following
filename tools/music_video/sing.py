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
    "priest": {"octave": 0, "formants": .86, "tilt": 1.1, "vibrato": (20, 4.4), "gain": 1.7, "ring": .6},
    "shout": {"octave": 0, "formants": 1.12, "tilt": .65, "vibrato": (0, 5.0), "gain": .75, "ring": 1.2},
    "whisper": {"octave": 0, "formants": 1.0, "tilt": 1.0, "vibrato": (0, 5.0), "gain": .55, "ring": 0},
    # the low ritual singers and the drone
    "bass": {"octave": -24, "formants": .9, "tilt": 1.2, "vibrato": (14, 4.6), "gain": .9, "ring": .3},
}
# Sections that keep sung syllables. The password chant is the one place the
# choir is articulated; everywhere else the singers are wordless.
ARTICULATED = {"password"}
# Wordless vowel arc per section role: (vowel at the first note, at the last).
VOWEL_ARCS = {
    "intro": ("u", "o"), "verse": ("O", "a"), "pre": ("O", "a"), "chorus": ("a", "o"),
    "bridge": ("o", "u"), "spoiler": ("o", "o"), "password": ("a", "o"),
    "someday": ("o", "a"), "or_twenty": ("o", "O"), "tag": ("a", "o"),
}
# Ritual harmony: (octave, diatonic steps) for the singers added to a melody.
LIGHT_PARTS = [(-12, 0), (0, 0), (-12, 0), (-24, 0)]
RITUAL_PARTS = [(-24, 0), (-12, -3), (-12, 0), (-24, 0), (-12, -4), (0, 0), (-24, -3), (-12, 0)]
DRONE_RITUAL = .75
CROWD_GAIN = 2.0  # shouts and the chant cut through the whole-song vocal level  # sections at or above this ritual level get a low drone


def articulated(song: dict, line: dict) -> bool:
    return line["voice"] in ("shout", "whisper") or (
        song_data.section_at(song, line["bar"])["id"] in ARTICULATED)


def diatonic(midi: int, steps: int, transpose: int) -> int:
    """Move a note `steps` scale degrees within C major (plus the section's transpose)."""
    if not steps:
        return midi
    scale = (0, 2, 4, 5, 7, 9, 11)
    octave, pc = divmod(midi - transpose, 12)
    index = min(range(7), key=lambda i: abs(pc - scale[i]))
    o, i = divmod(octave * 7 + index + steps, 7)
    return o * 12 + scale[i] + transpose


def _singer(rng, octave=-12, steps=0, detune=0.0, delay=0.0, pan=0.0, gain=1.0, voice=None,
            shout_midi=55.0, formant_shift=1.0) -> dict:
    return {"octave": octave, "steps": steps, "detune": detune, "delay": delay, "pan": pan,
            "gain": gain, "voice": voice, "shout_midi": shout_midi, "formant_shift": formant_shift}


def copies(song: dict, line: dict, index: int) -> list[dict]:
    """The singers on a line: a lone lead whose choir grows, turning to ritual harmony."""
    section = song_data.section_at(song, line["bar"])
    count = max(1, section["choir_voices"])
    ritual = section.get("ritual", 0.0)
    voice = line["voice"]
    rng = np.random.default_rng([SEED, index])
    if voice == "shout" or (voice == "choir" and articulated(song, line)):
        return _crowd(rng, voice, count)
    if voice not in ("lead", "choir"):
        return [_singer(rng, octave=VOICES[voice]["octave"])]
    lead_gain = (1.0 if voice == "lead" else .8) * (1 - .45 * ritual)
    out = [_singer(rng, gain=lead_gain)]
    extra = count - 1
    if extra <= 0:
        return out
    parts = RITUAL_PARTS if ritual >= .4 else LIGHT_PARTS
    total = .4 + .7 * ritual  # the choir overtakes the lead as the ritual deepens
    for c in range(extra):
        octave, steps = parts[c % len(parts)]
        out.append(_singer(
            rng, octave=octave, steps=steps,
            detune=float(rng.uniform(-1, 1) * (7 + 7 * ritual)),
            delay=float(rng.uniform(-1, 1) * (.012 + .018 * ritual)),
            pan=float(-.75 + 1.5 * c / max(1, extra - 1)) if extra > 1 else 0.0,
            gain=total / math.sqrt(extra) * (1.25 if octave == -24 else 1.0),
            voice="bass" if octave == -24 else "choir",
            formant_shift=float(rng.uniform(.93, 1.05) * (1 - .05 * ritual))))
    return out


def drones(song: dict) -> list[tuple[dict, list[dict]]]:
    """A low, wordless 'ohh' on each bar's chord root (and fifth) in deep ritual sections."""
    chords = song_data.bar_chords(song)
    out = []
    for s_index, section in enumerate(song["sections"]):
        if section.get("ritual", 0) < DRONE_RITUAL:
            continue
        first, last = section["bars"]
        roots = [40 + (chords[bar - 1][0] - 4) % 12 for bar in range(first, last + 1)]  # E2..D#3
        for part, shift in (("root", 0), ("fifth", 7)):
            names = " ".join(f"{_name(r + shift)}:4" for r in roots)
            line = {"bar": first, "beat": 1, "voice": "bass", "syl": " ".join(["oh"] * len(roots)),
                    "notes": names, "drone": True}
            rng = np.random.default_rng([SEED, 900 + s_index, shift])
            singers = [_singer(rng, octave=0, detune=float(rng.uniform(-6, 6)),
                               delay=float(rng.uniform(-.02, .02)), pan=p,
                               gain=(.42 if part == "root" else .26), voice="bass",
                               formant_shift=float(rng.uniform(.92, 1.0)))
                       for p in (-.4, .4)]
            out.append((line, singers))
    return out


def _name(midi: int) -> str:
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    return f"{names[midi % 12]}{midi // 12 - 1}"


def _crowd(rng, voice: str, count: int) -> list[dict]:
    """Articulated crowds: the shouts and the password chant (unchanged from the prototype)."""
    out = []
    if voice in ("choir", "shout"):
        if voice == "shout":
            count = max(3, count)
        for c in range(count):
            first = c == 0
            out.append(_singer(
                rng,
                octave=0 if voice == "shout" else (-12 if c % 2 == 0 else 0),
                detune=0.0 if first else float(rng.uniform(-8, 8)),
                delay=0.0 if first else float(rng.uniform(-.010, .010)),
                pan=0.0 if count == 1 else -.7 + 1.4 * c / (count - 1),
                gain=CROWD_GAIN / math.sqrt(count),
                shout_midi=float(rng.uniform(52, 60)),
                formant_shift=float(rng.uniform(.94, 1.08))))
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
    voice = singer.get("voice") or voice
    spec = VOICES[voice]
    rng = np.random.default_rng(seed)
    per_beat = SR * song["frames_per_beat"] // song["fps"]
    section = song_data.section_at(song, line["bar"])
    transpose = section.get("transpose", 0)
    notes = song_data.parse_notes(line["notes"])
    syls = song_data.syllables(line["syl"])
    speak = articulated(song, line) and not line.get("drone")
    arc = VOWEL_ARCS[compose.ROLES[section["id"]]] if not line.get("drone") else ("o", "u")
    sung_total = sum(1 for note in notes if note["sung"])
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
        if speak:
            s = shape(syls[k])
        else:  # wordless: a slow vowel arc across the line, a hummed 'm' to begin
            pos = k / max(1, sung_total - 1)
            vowel = (1 - pos) * np.array(VOWELS[arc[0]], float) + pos * np.array(VOWELS[arc[1]], float)
            s = {"onset": "n" if k == 0 and not line.get("drone") else "", "vowel": arc[0],
                 "formants": vowel, "coda": ""}
        k += 1
        length = b - a
        t = np.arange(length) / SR
        adjacent = prev_end == a
        next_sung = i + 1 < len(notes) and notes[i + 1]["sung"]

        # pitch
        if note["pitch"] is not None:
            written = diatonic(note["pitch"] + transpose, singer.get("steps", 0), transpose)
            target = compose.hz(written + singer["octave"] + singer["detune"] / 100)
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
        if "formants" in s:
            v2 = None
        f1 = np.array(s.get("formants", VOWELS[v1]), float) * singer["formant_shift"]
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
        floor = (.4 if speak else .6) if next_sung and not s["coda"] else 0.0
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
        cutoff = 5000.0 if voice == "bass" else CUTOFF
        top = int(cutoff / f0.min()) + 1
        for h in range(1, top + 1):
            freq = h * f0
            weight = (h ** -spec["tilt"]) * _cascade(freq, form, scale, spec["ring"])
            weight[freq > cutoff] = 0
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
    cathedral = np.zeros((length, 2))
    lead_env = np.zeros(length)
    jobs = [(index, line, copies(song, line, index)) for index, line in enumerate(song["lines"])]
    jobs += [(1000 + i, line, singers) for i, (line, singers) in enumerate(drones(song))]
    for index, line, singers in jobs:
        if bars and not bars[0] <= line["bar"] <= bars[1]:
            continue
        voice = line["voice"]
        ritual = song_data.section_at(song, line["bar"]).get("ritual", 0.0)
        for c, singer in enumerate(singers):
            start, audio, _ = render_copy(song, line, singer, voice, [SEED, index, c])
            audio = audio * singer["gain"]
            a, b = max(0, start), min(length, start + len(audio))
            part = audio[a - start:b - start]
            left, right = math.sqrt((1 - singer["pan"]) / 2), math.sqrt((1 + singer["pan"]) / 2)
            dry[a:b, 0] += part * left * (1 - .35 * ritual)
            dry[a:b, 1] += part * right * (1 - .35 * ritual)
            wet = .35 if voice in ("choir", "priest", "bass") else .22
            for bus, level in ((send, wet * (1 - ritual)), (cathedral, .55 * ritual)):
                bus[a:b, 0] += part * left * level
                bus[a:b, 1] += part * right * level
            if voice == "lead" and c == 0:
                lead_env[a:b] = np.maximum(lead_env[a:b], np.abs(part))
    wet = compose.reverb(send.astype(np.float32), np.random.default_rng(SEED))
    if np.any(cathedral):
        wet += 1.4 * compose.reverb(cathedral.astype(np.float32), np.random.default_rng(SEED + 1),
                                    seconds=5.0, rt60=4.2)
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

PROTOTYPE_CUTS = {  # listening excerpts cut from the full draft
    "prototype_alone.wav": (5, 24),      # one voice, then the first companion
    "prototype_password.wav": (65, 68),  # the articulated chant, as approved
    "prototype_ritual.wav": (85, 96),    # sixteen voices, organum and drone
}


def prototype(song: dict) -> int:
    """Rethought voice test: the whole song as a draft, plus excerpts."""
    backing = read_wav(compose.AUDIO / "backing.wav")
    vocals, lead_env = render(song)
    bed = duck(backing, lead_env)
    # One vocal gain for the whole song, so the choir's growth is heard as written.
    gain = 10 ** ((compose.loudness(bed) + 1.5 - compose.loudness(vocals)) / 20)
    vocals *= gain
    full = master(bed + vocals)
    compose.write_wav(compose.AUDIO / "prototype_full.wav", full.astype(np.float32))
    print(f"prototype_full.wav: {len(full) / SR:.1f}s, {compose.loudness(full):.1f} LUFS, "
          f"{compose.true_peak(full):.1f} dBTP")
    voc = master(vocals, -16.0)
    compose.write_wav(compose.AUDIO / "prototype_vocals.wav", voc.astype(np.float32))
    print(f"prototype_vocals.wav: {len(voc) / SR:.1f}s (whole song, vocals only)")
    per_bar = song["beats_per_bar"] * (SR * song["frames_per_beat"] // song["fps"])
    for name, (first, last) in PROTOTYPE_CUTS.items():
        a, b = (first - 1) * per_bar, min(len(full), last * per_bar + round(.6 * SR))
        cut = full[a:b].copy()
        cut[:240] *= np.linspace(0, 1, 240)[:, None]
        cut *= np.minimum((len(cut) - np.arange(len(cut))) / (.5 * SR), 1)[:, None]
        compose.write_wav(compose.AUDIO / name, cut.astype(np.float32))
        print(f"{name}: bars {first}-{last}, {len(cut) / SR:.1f}s")
    for stale in ("prototype_chorus.wav",):
        (compose.AUDIO / stale).unlink(missing_ok=True)
    for row in pitch_report(song, [(1, song["bars"])]):
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
