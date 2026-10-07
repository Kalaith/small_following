"""Load and validate song.json, the music video's single source of truth.

Run directly to validate: python tools/music_video/song_data.py
Uses only the standard library. Timing helpers are shared by later tools.
"""
from __future__ import annotations

import json
from pathlib import Path
import re
import sys

SONG = Path(__file__).resolve().with_name("song.json")
NOTE = re.compile(r"^([A-G])(#|b)?(-?\d)$")
CHORD = re.compile(r"^([A-G])(#|b)?(m)?$")
SEMITONE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
PITCH_RANGE = (40, 84)  # E2..C6: the Priest's low notes up to the choir's top
FUTURE_LABEL = "NOT BUILT"


def midi(name: str) -> int:
    match = NOTE.match(name)
    if not match:
        raise ValueError(f"bad note name {name!r}")
    letter, accidental, octave = match.groups()
    shift = {"#": 1, "b": -1}.get(accidental or "", 0)
    return 12 * (int(octave) + 1) + SEMITONE[letter] + shift


def parse_notes(text: str) -> list[dict]:
    """'A4:.5 r:1 x:.5' -> [{pitch: 69|None, beats, sung}]; r rests, x unpitched."""
    notes = []
    for token in text.split():
        name, _, length = token.partition(":")
        beats = float(length)
        if beats <= 0:
            raise ValueError(f"non-positive length in {token!r}")
        if name == "r":
            notes.append({"pitch": None, "beats": beats, "sung": False})
        elif name == "x":
            notes.append({"pitch": None, "beats": beats, "sung": True})
        else:
            notes.append({"pitch": midi(name), "beats": beats, "sung": True})
    return notes


def syllables(text: str) -> list[str]:
    """Words split on spaces, then hyphens; '-' standing alone is a dash."""
    parts = []
    for word in text.split():
        if word.strip("-") == "":
            continue
        parts.extend(piece for piece in word.split("-") if piece)
    return parts


def caption(text: str) -> str:
    """Display text: syllable hyphens joined, standalone dashes kept."""
    return " ".join(word if word.strip("-") == "" else word.replace("-", "")
                    for word in text.split())


def chord(name: str) -> tuple[int, bool]:
    """'Am' -> (pitch class 9, minor); 'F#' -> (6, major)."""
    match = CHORD.match(name)
    if not match:
        raise ValueError(f"bad chord {name!r}")
    letter, accidental, minor = match.groups()
    shift = {"#": 1, "b": -1}.get(accidental or "", 0)
    return (SEMITONE[letter] + shift) % 12, bool(minor)


def bar_chords(song: dict) -> list[tuple[int, bool]]:
    """One (pitch class, minor) per bar, with each section's transpose applied."""
    chords = []
    for section in song["sections"]:
        shift = section.get("transpose", 0)
        for name in section["chords"].split():
            root, minor = chord(name)
            chords.append(((root + shift) % 12, minor))
    return chords


def section_at(song: dict, bar: int) -> dict:
    return next(s for s in song["sections"] if s["bars"][0] <= bar <= s["bars"][1])


def line_start(song: dict, line: dict) -> float:
    return (line["bar"] - 1) * song["beats_per_bar"] + (line["beat"] - 1)


def bpm(song: dict) -> float:
    return 60.0 * song["fps"] / song["frames_per_beat"]


def seconds(song: dict, beat: float) -> float:
    """Beats are a whole number of video frames, so cuts land on exact frames."""
    return beat * song["frames_per_beat"] / song["fps"]


def load(path: Path = SONG) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _tiles(ranges: list[list[int]], total: int, what: str, errors: list[str]) -> None:
    expected = 1
    for first, last in ranges:
        if first != expected or last < first:
            errors.append(f"{what}: expected a range starting at bar {expected}, got {first}-{last}")
            return
        expected = last + 1
    if expected != total + 1:
        errors.append(f"{what}: ends at bar {expected - 1}, song has {total} bars")


def validate(song: dict) -> list[str]:
    errors: list[str] = []
    total, per_bar = song["bars"], song["beats_per_bar"]
    sections = song["sections"]
    _tiles([s["bars"] for s in sections], total, "sections", errors)
    _tiles([s["bars"] for s in song["shots"]], total, "shots", errors)
    for section in sections:
        names = section.get("chords", "").split()
        length = section["bars"][1] - section["bars"][0] + 1
        if len(names) != length:
            errors.append(f"section {section['id']}: {len(names)} chords for {length} bars")
        for name in names:
            if not CHORD.match(name):
                errors.append(f"section {section['id']}: bad chord {name!r}")

    def section_of(bar: int) -> dict | None:
        return next((s for s in sections if s["bars"][0] <= bar <= s["bars"][1]), None)

    voice_end: dict[str, float] = {}
    for index, line in enumerate(song["lines"]):
        where = f"line {index + 1} (bar {line['bar']})"
        if line["voice"] not in song["voices"]:
            errors.append(f"{where}: unknown voice {line['voice']!r}")
        if not 1 <= line["beat"] <= per_bar:
            errors.append(f"{where}: beat {line['beat']} outside the bar")
        try:
            notes = parse_notes(line["notes"])
        except ValueError as error:
            errors.append(f"{where}: {error}")
            continue
        sung = [n for n in notes if n["sung"]]
        words = syllables(line["syl"])
        if len(sung) != len(words):
            errors.append(f"{where}: {len(words)} syllables but {len(sung)} sung notes")
        for note in sung:
            if note["pitch"] is not None and not PITCH_RANGE[0] <= note["pitch"] <= PITCH_RANGE[1]:
                errors.append(f"{where}: pitch {note['pitch']} outside {PITCH_RANGE}")
        start = line_start(song, line)
        end = start + sum(n["beats"] for n in notes)
        section = section_of(line["bar"])
        if section is None:
            errors.append(f"{where}: not inside any section")
        elif end > section["bars"][1] * per_bar + 1e-9:
            errors.append(f"{where}: runs past the end of section {section['id']}")
        if start < voice_end.get(line["voice"], 0) - 1e-9:
            errors.append(f"{where}: overlaps the previous {line['voice']} line")
        voice_end[line["voice"]] = end

    for overlay in song.get("overlays", []):
        where = f"overlay {overlay.get('text', '?')!r}"
        if overlay.get("style") not in ("counter", "pop"):
            errors.append(f"{where}: unknown style {overlay.get('style')!r}")
        start = (overlay["bar"] - 1) * per_bar + overlay["beat"] - 1
        if start < 0 or start + overlay["beats"] > total * per_bar:
            errors.append(f"{where}: runs outside the song")

    for shot in song["shots"]:
        where = f"shot {shot['id']}"
        has_take, has_plate = "take" in shot, "plate" in shot
        if has_take == has_plate:
            errors.append(f"{where}: needs exactly one of take or plate")
        if has_take and shot["take"] not in song["takes"]:
            errors.append(f"{where}: take {shot['take']!r} is not in the capture plan")
        if has_plate and shot["plate"] not in song["plates"]:
            errors.append(f"{where}: plate {shot['plate']!r} is not listed")
        if "at_bar" in shot and not shot["bars"][0] <= shot["at_bar"] <= shot["bars"][1]:
            errors.append(f"{where}: at_bar {shot['at_bar']} outside the shot")
        future = any(s.get("future") and s["bars"][0] <= shot["bars"][0] <= s["bars"][1]
                     for s in sections)
        if future and (has_take or FUTURE_LABEL not in shot.get("label", "")):
            errors.append(f"{where}: future ideas must be labelled plates, never gameplay takes")
    return errors


def main() -> int:
    song = load()
    errors = validate(song)
    for error in errors:
        print("ERROR:", error)
    if errors:
        return 1
    per_bar = song["beats_per_bar"]
    duration = seconds(song, song["bars"] * per_bar)
    sung = sum(len(syllables(line["syl"])) for line in song["lines"])
    frames = song["bars"] * per_bar * song["frames_per_beat"]
    print(f"VALID: {song['title']} / {bpm(song):.2f} BPM / {song['bars']} bars / "
          f"{duration:.1f}s / {frames} frames / "
          f"{len(song['lines'])} lines / {sung} syllables / {len(song['shots'])} shots")
    return 0


if __name__ == "__main__":
    sys.exit(main())
