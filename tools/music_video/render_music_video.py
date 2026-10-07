"""Edit the music video from song.json, the song and the plates.

Run (after compose.py, sing.py and postcards.py):
  python tools/music_video/render_music_video.py --animatic
Writes exports/music_video/animatic.mp4 (1920 x 1080, 30 fps, H.264 + AAC),
timeline.json (shots and caption events) and review stills, then checks:
caption syllables start within half a frame of their notes, frame count and
duration, streams, and a clean full decode. Exits 1 on any failure.

The animatic has no game footage yet: each take is a labelled placeholder card
naming the shot, whether it is real gameplay or staged, and its sync event.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys
import textwrap

import numpy as np
from PIL import Image, ImageDraw

import postcards
import song_data
from sprites import CREAM, LILAC, Pen, cultist, font

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "exports" / "music_video"
REVIEW = OUT / "review"
W, H = 1920, 1080
FFMPEG, FFPROBE = shutil.which("ffmpeg"), shutil.which("ffprobe")

ROWS = {"lead": "main", "solo": "main", "priest": "main", "teal": "main",
        "choir": "answer", "shout": "answer", "whisper": "answer"}
STYLE = {  # caption face per voice: (size, serif, bold, italic, sung colour)
    "lead": (54, True, False, False, "#ffe4a1"), "solo": (50, True, False, True, "#ffe4a1"),
    "priest": (54, True, True, False, "#f0b48a"), "teal": (50, False, True, False, "#8fd3c4"),
    "choir": (44, True, False, True, "#e6d3ff"), "shout": (52, False, True, False, "#ffd27a"),
    "whisper": (38, True, False, True, "#c9b8dc"),
}
ROW_Y = {"main": 985, "answer": 905}
STRIP_TOP = 840
LEAD_IN, LINGER = 1.0, 1.5  # beats a caption shows before and after its line


def frame_of(song: dict, beats: float) -> int:
    """Nearest video frame to a beat position (half frames round up)."""
    return int(math.floor(beats * song["frames_per_beat"] + .5))


# --- captions --------------------------------------------------------------------

def caption_lines(song: dict) -> list[dict]:
    """Each lyric line as display pieces with per-syllable start frames and a window."""
    lines = []
    for index, line in enumerate(song["lines"]):
        notes = song_data.parse_notes(line["notes"])
        starts, cursor = [], song_data.line_start(song, line)
        for note in notes:
            if note["sung"]:
                starts.append(cursor)
            cursor += note["beats"]
        pieces, k = [], 0
        for w_index, word in enumerate(line["syl"].split()):
            if word.strip("-") == "":
                pieces.append({"text": "-", "syllable": None, "space": True})
                continue
            for p_index, part in enumerate(piece for piece in word.split("-") if piece):
                pieces.append({"text": part, "syllable": k, "space": p_index == 0 and w_index > 0})
                k += 1
        begin = song_data.line_start(song, line)
        lines.append({
            "index": index, "voice": line["voice"], "row": ROWS[line["voice"]], "pieces": pieces,
            "beats": starts, "frames": [frame_of(song, b) for b in starts],
            "exact": [b * song["frames_per_beat"] for b in starts],
            "show": frame_of(song, max(0.0, begin - LEAD_IN)),
            "hide": frame_of(song, cursor + LINGER),
        })
    for row in ("main", "answer"):  # a new line in the same row replaces the old one
        mine = [line for line in lines if line["row"] == row]
        half_beat = song["frames_per_beat"] // 2
        for a, b in zip(mine, mine[1:]):
            # The old line keeps its last syllable lit for half a beat (if the
            # new line's first note allows), and the new line waits for it.
            keep = min(a["frames"][-1] + half_beat, b["frames"][0])
            a["hide"] = max(min(a["hide"], b["show"]), keep)
            b["show"] = max(b["show"], a["hide"])
    return lines


def caption_checks(song: dict, lines: list[dict]) -> list[str]:
    failures = []
    total = sum(len(song_data.syllables(line["syl"])) for line in song["lines"])
    events = sum(len(line["frames"]) for line in lines)
    if events != total:
        failures.append(f"{events} caption events for {total} sung syllables")
    worst = 0.0
    for line in lines:
        where = f"caption line {line['index'] + 1}"
        for frame, exact in zip(line["frames"], line["exact"]):
            worst = max(worst, abs(frame - exact))
            if abs(frame - exact) > .5 + 1e-9:
                failures.append(f"{where}: syllable at frame {frame}, note at {exact:.2f}")
            if not line["show"] <= frame < line["hide"]:
                failures.append(f"{where}: syllable at frame {frame} outside its window "
                                f"{line['show']}-{line['hide']}")
        if line["frames"] != sorted(line["frames"]):
            failures.append(f"{where}: syllables out of order")
    print(f"captions: {events} syllable events in {len(lines)} lines; worst offset {worst:.2f} frames")
    return failures


def draw_caption(draw: ImageDraw.ImageDraw, line: dict, frame: int) -> None:
    size, serif, bold, italic, sung = STYLE[line["voice"]]
    face = font(size, serif, bold, italic)
    current = sum(1 for f in line["frames"] if f <= frame) - 1
    texts = [(" " if p["space"] else "") + p["text"] for p in line["pieces"]]
    widths = [draw.textlength(t, font=face) for t in texts]
    x = (W - sum(widths)) / 2
    y = ROW_Y[line["row"]]
    pad = 26
    draw.rounded_rectangle((x - pad, y - size * .72, x + sum(widths) + pad, y + size * .62), 16,
                           fill=(16, 10, 26, 150))
    for piece, text, width in zip(line["pieces"], texts, widths):
        k = piece["syllable"]
        if k is not None and k == current:
            fill = sung
        elif k is not None and k < current:
            fill = "#d9c9ee"
        else:
            fill = (255, 240, 216, 120)
        draw.text((x, y), text, font=face, fill=fill, anchor="ls", stroke_width=2,
                  stroke_fill=(20, 12, 30, 200))
        x += width


# --- shots -------------------------------------------------------------------------

def shot_frames(song: dict, shot: dict) -> tuple[int, int]:
    per_bar = song["beats_per_bar"] * song["frames_per_beat"]
    return (shot["bars"][0] - 1) * per_bar, shot["bars"][1] * per_bar


def placeholder(song: dict, shot: dict, backdrop: np.ndarray) -> np.ndarray:
    """A labelled card where slice 6 footage will go."""
    image = Image.fromarray(backdrop).convert("RGBA")
    d = ImageDraw.Draw(image, "RGBA")
    d.rounded_rectangle((240, 120, 1680, 780), 18, fill=(30, 20, 44, 210), outline="#785b96", width=3)
    staged = shot.get("staged", False)
    badge = "STAGED SCENE" if staged else "REAL GAMEPLAY"
    d.rounded_rectangle((300, 170, 300 + d.textlength(badge, font=font(24, bold=True)) + 40, 216), 10,
                        fill="#6f4593" if staged else "#466d75")
    d.text((320, 193), badge, font=font(24, bold=True), fill=CREAM, anchor="lm")
    title = shot["id"].replace("_", " ").title().replace("Hq", "HQ")
    d.text((300, 300), title, font=font(76, serif=True, bold=True), fill=CREAM, anchor="ls")
    # The password card stays compact: the letters slam in over its middle.
    note = "" if shot["id"] == "password" else shot.get("note", "")
    for row, text in enumerate(textwrap.wrap(note, 62)[:4]):
        d.text((302, 370 + row * 50), text, font=font(36, serif=True), fill="#e6d8f2", anchor="ls")
    details = f"take: {shot['take']}   bars {shot['bars'][0]}-{shot['bars'][1]}"
    if "in_event" in shot:
        details += f"   sync: {shot['in_event']} on bar {shot['at_bar']}"
    d.text((302, 700), details, font=font(26), fill=LILAC, anchor="ls")
    d.text((302, 744), "Footage arrives in slice 6 (capture).", font=font(24), fill="#a994bf", anchor="ls")
    if shot["id"] != "password":
        cultist(Pen(image, 1), 1540, 700, 3.2 if staged else 2.6)
    return np.asarray(image.convert("RGB"))


PLATE_SCALE = .8


def framed(plate: np.ndarray, backdrop: np.ndarray) -> np.ndarray:
    """A plate shown smaller and higher on the backdrop, clear of the captions."""
    w, h = round(W * PLATE_SCALE), round(H * PLATE_SCALE)
    image = Image.fromarray(backdrop).copy()
    image.paste(Image.fromarray(plate).resize((w, h), Image.LANCZOS), ((W - w) // 2, 24))
    return np.asarray(image)


def corner_tag(draw: ImageDraw.ImageDraw, text: str) -> None:
    face = font(20, bold=True)
    width = draw.textlength(text, font=face)
    draw.rounded_rectangle((W - width - 70, 36, W - 36, 72), 8, fill=(111, 69, 147, 200))
    draw.text((W - 53 - width / 2, 54), text, font=face, fill=CREAM, anchor="mm")


def push(plate: np.ndarray, progress: float, amount: float) -> np.ndarray:
    """A slow push-in on a plate: progress 0..1, amount = final zoom - 1."""
    zoom = 1 + amount * progress
    if zoom <= 1.0001:
        return plate
    w, h = W / zoom, H / zoom
    box = ((W - w) / 2, (H - h) / 2, (W + w) / 2, (H + h) / 2)
    return np.asarray(Image.fromarray(plate).resize((W, H), Image.BILINEAR, box=box))


# --- password stamps ------------------------------------------------------------------

def password_events(song: dict) -> list[tuple[int, str]]:
    """Each shouted letter of the chant, with the frame its note starts."""
    events = []
    for line in song["lines"]:
        section = song_data.section_at(song, line["bar"])
        if section["id"] != "password" or line["voice"] != "shout":
            continue
        cursor = song_data.line_start(song, line)
        letters = iter(song_data.syllables(line["syl"]))
        for note in song_data.parse_notes(line["notes"]):
            if note["sung"]:
                events.append((frame_of(song, cursor), next(letters).strip("!")))
            cursor += note["beats"]
    return events


def draw_password(draw: ImageDraw.ImageDraw, song: dict, events, frame: int) -> None:
    shown = [(f, letter) for f, letter in events if f <= frame]
    if not shown:
        return
    face_size = 150
    gap = 150
    x0 = W / 2 - gap * (len(events) - 1) / 2
    for i, (f, letter) in enumerate(shown):
        age = frame - f
        scale = 1 + .6 * max(0.0, 1 - age / 5)  # each letter slams in over five frames
        draw.text((x0 + i * gap, 470), letter, font=font(int(face_size * scale), serif=True, bold=True),
                  fill="#ffe4a1", anchor="mm", stroke_width=5, stroke_fill="#2a1838")
    per_bar = song["beats_per_bar"] * song["frames_per_beat"]
    if frame >= 66 * per_bar:  # bar 67: the reading resolves
        draw.text((W / 2, 590), "PLZ · K · TKS  =  please, okay, thanks", font=font(56, serif=True),
                  fill=CREAM, anchor="mm", stroke_width=3, stroke_fill="#2a1838")
    if frame >= 67 * per_bar:  # bar 68
        draw.text((W / 2, 645), "Developer convenience feature", font=font(34, italic=True), fill=LILAC,
                  anchor="mm")
    ribbon = Image.new("RGBA", (520, 70), (196, 71, 90, 230))
    ImageDraw.Draw(ribbon).text((260, 35), "SPOILER", font=font(36, bold=True), fill=CREAM, anchor="mm")
    return ribbon.rotate(18, expand=True, resample=Image.BICUBIC)


# --- the edit --------------------------------------------------------------------------

def animatic(song: dict) -> int:
    failures = []
    lines = caption_lines(song)
    failures += caption_checks(song, lines)
    backdrop = postcards.backdrop_array()
    plates = {p: np.asarray(Image.open(postcards.OUT / f"{p}.png").convert("RGB")) for p in song["plates"]}
    shots = []
    for shot in song["shots"]:
        first, last = shot_frames(song, shot)
        base = plates[shot["plate"]] if "plate" in shot else placeholder(song, shot, backdrop)
        if "plate" in shot:  # plates sit above the caption band
            base = framed(base, backdrop)
        shots.append({**shot, "first": first, "last": last, "base": base})
    total = song["bars"] * song["beats_per_bar"] * song["frames_per_beat"]
    letters = password_events(song)
    per_bar = song["beats_per_bar"] * song["frames_per_beat"]
    section_mid = {(s["bars"][0] - 1) * per_bar + (s["bars"][1] - s["bars"][0] + 1) * per_bar // 2: s["id"]
                   for s in song["sections"]}
    sync_stills = {}  # sample syllables to inspect: (bar, voice, syllable index)
    for bar, voice, j in ((17, "lead", 3), (18, "choir", 1), (47, "priest", 2), (67, "choir", 1)):
        i = next(i for i, l in enumerate(song["lines"]) if l["bar"] == bar and l["voice"] == voice)
        sync_stills[lines[i]["frames"][j]] = f"caption_bar{bar}_{voice}_syl{j + 1}"

    out = OUT / "animatic.mp4"
    REVIEW.mkdir(parents=True, exist_ok=True)
    encoder = subprocess.Popen(
        [FFMPEG, "-y", "-hide_banner", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
         "-s", f"{W}x{H}", "-r", str(song["fps"]), "-i", "-", "-i", str(OUT / "audio" / "song.wav"),
         "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "veryfast", "-crf", "20",
         "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(out)],
        stdin=subprocess.PIPE)
    contact = {}
    timeline = []
    shot_i = 0
    for frame in range(total):
        while frame >= shots[shot_i]["last"]:
            shot_i += 1
        shot = shots[shot_i]
        progress = (frame - shot["first"]) / max(1, shot["last"] - shot["first"] - 1)
        if "plate" in shot:
            amount = .12 if shot["plate"] == "vision-enormous" else .05
            base = push(shot["base"], progress, amount)
        else:
            base = shot["base"]
        image = Image.fromarray(base).convert("RGBA")
        draw = ImageDraw.Draw(image, "RGBA")
        if shot.get("staged"):
            corner_tag(draw, "STAGED")
        if shot["id"] == "password":
            ribbon = draw_password(draw, song, letters, frame)
            if ribbon is not None:
                image.alpha_composite(ribbon, (-40, 40))
                draw = ImageDraw.Draw(image, "RGBA")
        bar = frame // per_bar + 1
        section = song_data.section_at(song, bar)
        draw.text((36, 54), f"ANIMATIC  ·  bar {bar}  ·  {section['id']}  ·  {shot['id']}",
                  font=font(18, bold=True), fill=(212, 180, 250, 170), anchor="lm")
        for line in lines:
            if line["show"] <= frame < line["hide"]:
                draw_caption(draw, line, frame)
        rgb = image.convert("RGB")
        encoder.stdin.write(rgb.tobytes())
        if frame in section_mid:
            contact[section_mid[frame]] = rgb.resize((480, 270))
        if frame in sync_stills:
            rgb.save(REVIEW / f"{sync_stills[frame]}.png")
        if frame == shot["first"]:
            timeline.append({k: v for k, v in shot.items() if k != "base"})
        if frame % 600 == 0:
            print(f"  frame {frame}/{total}", flush=True)
    encoder.stdin.close()
    if encoder.wait() != 0:
        failures.append("FFmpeg encoding failed")

    sheet = Image.new("RGB", (4 * 480, math.ceil(len(contact) / 4) * 270))
    for i, (sid, still) in enumerate(contact.items()):
        sheet.paste(still, ((i % 4) * 480, (i // 4) * 270))
    sheet.save(REVIEW / "animatic_sheet.png")
    (OUT / "timeline.json").write_text(json.dumps({
        "fps": song["fps"], "frames": total, "shots": timeline,
        "captions": [{k: line[k] for k in ("index", "voice", "row", "show", "hide", "frames")}
                     for line in lines],
        "password_letters": letters}, indent=1), encoding="utf-8")
    failures += video_checks(out, total, song["fps"])
    for failure in failures:
        print("FAIL:", failure)
    print("RESULT:", "FAIL" if failures else "PASS")
    return 1 if failures else 0


def video_checks(path: Path, frames: int, fps: int) -> list[str]:
    failures = []
    probe = json.loads(subprocess.run(
        [FFPROBE, "-v", "error", "-count_frames", "-show_entries",
         "stream=codec_type,codec_name,width,height,avg_frame_rate,nb_read_frames,sample_rate,channels"
         ":format=duration", "-of", "json", str(path)], capture_output=True, text=True).stdout)
    video = next(s for s in probe["streams"] if s["codec_type"] == "video")
    audio = next((s for s in probe["streams"] if s["codec_type"] == "audio"), None)
    if int(video["nb_read_frames"]) != frames:
        failures.append(f"{video['nb_read_frames']} video frames, expected {frames}")
    if (video["codec_name"], video["width"], video["height"], video["avg_frame_rate"]) != \
            ("h264", W, H, f"{fps}/1"):
        failures.append(f"video stream {video}")
    if not audio or (audio["codec_name"], audio["sample_rate"], audio["channels"]) != ("aac", "48000", 2):
        failures.append(f"audio stream {audio}")
    duration = float(probe["format"]["duration"])
    if abs(duration - frames / fps) > .05:
        failures.append(f"duration {duration:.3f}s, expected {frames / fps:.3f}s")
    decode = subprocess.run([FFMPEG, "-v", "error", "-i", str(path), "-f", "null", "-"],
                            capture_output=True, text=True)
    if decode.returncode != 0 or decode.stderr.strip():
        failures.append(f"decode errors: {decode.stderr.strip()[:300]}")
    print(f"video: {video['nb_read_frames']} frames, {video['width']}x{video['height']} "
          f"{video['codec_name']} {video['avg_frame_rate']}, audio {audio and audio['codec_name']} "
          f"{audio and audio['sample_rate']} Hz, {duration:.3f}s")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--animatic", action="store_true", help="render the slice 5 animatic")
    args = parser.parse_args()
    song = song_data.load()
    errors = song_data.validate(song)
    if errors:
        print("\n".join("ERROR: " + e for e in errors))
        return 1
    if not (FFMPEG and FFPROBE):
        print("ERROR: ffmpeg and ffprobe are required")
        return 1
    if args.animatic:
        return animatic(song)
    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
