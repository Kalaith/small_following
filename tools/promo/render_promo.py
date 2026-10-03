"""Assemble original promo art, genuine Godot takes, typography and an original score.

Requires the already installed Python/Pillow/NumPy and FFmpeg/ffprobe.
Outputs stay in ignored exports/promo; no services or models are started.
"""
from __future__ import annotations

import concurrent.futures
import json
import math
from pathlib import Path
import shutil
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "exports" / "promo"
ASSETS = OUT / "assets"
REVIEW = OUT / "review"
W, H, FPS = 1920, 1080, 30
FONT = Path("C:/Windows/Fonts")
CREAM = "#fff0d8"
LILAC = "#d4b4fa"
FFMPEG = shutil.which("ffmpeg")
FFPROBE = shutil.which("ffprobe")

# Each title's duration includes its own short dip, keeping exact 72-second timing.
SHOTS = [
    dict(id="intro", duration=7, art="village-key-art.png", title=["Small", "Following"],
         eyebrow="A CUTE INCREMENTAL ADVENTURE", sub="A tiny cultist. A village to convince."),
    dict(id="opening", duration=11, title="Every following starts with a conversation.",
         detail="01  /  MEET THE VILLAGE", label="FRESH START"),
    dict(id="ritual_art", duration=6, art="ritual-key-art.png", title=["A little", "conviction."],
         eyebrow="TURN DONATIONS INTO POSSIBILITY", sub="Inscribe your next advantage."),
    dict(id="ritual", duration=8, title="Speak faster. Persuade harder. Run further.",
         detail="02  /  INSCRIBE YOUR PATH", label="FIRST PURCHASE"),
    dict(id="full_core", duration=11, title="Same eleven seconds. A much bigger following.",
         detail="03  /  MAKE EVERY SECOND COUNT", label="UPGRADED CORE"),
    dict(id="helper", duration=11, title="More neighbours. A helping hand.",
         detail="04  /  GROW YOUR REACH", label="EXPANDED BUILD"),
    dict(id="priest", duration=10, title="Can you convince the Priest of Bramblewick?",
         detail="05  /  WIN THEM OVER", label="FINALE BUILD"),
    dict(id="outro", duration=8, art="village-key-art.png", title=["Small", "Following"],
         eyebrow="SMALL BEGINNINGS. GRAND AMBITIONS.", sub="How far will your words take you?"),
]


def run(args: list[str], name: str) -> None:
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True)
    (REVIEW / f"{name}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"{name} failed: {result.stderr[-3000:]}")


def font(size: int, serif: bool = False, bold: bool = False):
    return ImageFont.truetype(str(FONT / ("georgiab.ttf" if serif and bold else
        "georgia.ttf" if serif else "trebucbd.ttf" if bold else "trebuc.ttf")), size)


def spaced(draw, at, value, size=20, spacing=4, fill=LILAC):
    x, y = at
    face = font(size, bold=True)
    for char in value:
        draw.text((x, y), char, font=face, fill=fill)
        x += draw.textlength(char, font=face) + spacing


def make_overlay(shot):
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    if "art" in shot:
        # Transparent title plate: artwork remains a separate, unmodified source.
        gradient = np.zeros((H, W, 4), dtype=np.uint8)
        gradient[:, :, :3] = [17, 10, 30]
        gradient[:, :, 3] = (np.clip(1 - np.arange(W) / 1320, 0, 1) * 112).astype(np.uint8)
        image = Image.fromarray(gradient)
        draw = ImageDraw.Draw(image)
        spaced(draw, (130, 156), shot["eyebrow"], 19, 3)
        draw.line((132, 217, 224, 217), fill=LILAC, width=3)
        title_size = 122 if shot["id"] != "ritual_art" else 108
        for row, text in enumerate(shot["title"]):
            draw.text((124, 274 + row * 139), text, font=font(title_size, serif=True), fill=CREAM,
                      stroke_width=1, stroke_fill=(40, 22, 52, 180))
        draw.text((132, 620), shot["sub"], font=font(30), fill=CREAM)
        if shot["id"] == "outro":
            spaced(draw, (134, 749), "SMALL FOLLOWING  /  IN DEVELOPMENT", 19, 2)
            draw.text((134, 799), "An original first-map prototype", font=font(24), fill=LILAC)
        spaced(draw, (132, 1006), "PROMOTIONAL ILLUSTRATION", 15, 2, "#c5b6ca")
    else:
        draw.text((192, 20), shot["title"], font=font(33, serif=True), fill=CREAM)
        draw.text((192, 1053), shot["detail"], font=font(16, bold=True), fill=LILAC)
        badge = "PROTOTYPE GAMEPLAY  /  " + shot["label"]
        tw = draw.textlength(badge, font=font(16))
        draw.text((1728 - tw, 1053), badge, font=font(16), fill="#c2b1d2")
        draw.rounded_rectangle((189, 80, 1731, 1043), radius=3, outline="#785b96", width=2)
        chapter = str([s["id"] for s in SHOTS if "art" not in s].index(shot["id"]) + 1).zfill(2)
        draw.text((62, 486), chapter, font=font(45, serif=True), fill=LILAC)
        draw.line((89, 572, 89, 689), fill="#76508e", width=2)
        draw.ellipse((85, 566, 93, 574), fill=LILAC)
    image.save(ASSETS / f"{shot['id']}-overlay.png")


def backdrop():
    y, x = np.mgrid[0:H, 0:W]
    glow = np.clip(1 - np.sqrt(((x-960)/1200)**2 + ((y-480)/800)**2), 0, 1)
    a = np.zeros((H, W, 3), dtype=np.uint8)
    for c, (base, lift) in enumerate([(17, 17), (11, 10), (28, 26)]):
        a[:, :, c] = base + lift * glow
    im = Image.fromarray(a)
    d = ImageDraw.Draw(im)
    for radius in (360, 470, 620, 780, 950):
        d.ellipse((960-radius, 540-radius, 960+radius, 540+radius), outline="#34213e", width=1)
    rng = np.random.default_rng(73)
    for _ in range(90):
        px, py = rng.integers(0, W), rng.integers(0, H)
        d.ellipse((px, py, px+2, py+2), fill="#634c74")
    im.save(ASSETS / "backdrop.png")


def synthesize_score():
    """Original 72s composition: plucked waltz, soft pads, bass and small bells.

    Entirely synthesized here; no samples, borrowed melody, speech or model downloads.
    """
    sr, duration = 48000, 72
    mix = np.zeros((duration * sr, 2), dtype=np.float32)
    rng = np.random.default_rng(73)

    def note(start, length, midi, amp, kind="pluck", pan=0):
        offset = round(start * sr)
        n = min(round(length * sr), len(mix) - offset)
        if n <= 0:
            return
        t = np.arange(n, dtype=np.float32) / sr
        f = 440 * 2 ** ((midi - 69) / 12)
        if kind == "pad":
            signal = (np.sin(2*np.pi*f*t) + .25*np.sin(2*np.pi*f*2.002*t)
                      + .12*np.sin(2*np.pi*f*.998*t))
            env = np.minimum(t/.45, 1) * np.minimum((length-t)/.8, 1)
        elif kind == "bass":
            signal = np.sin(2*np.pi*f*t) + .14*np.sin(2*np.pi*2*f*t)
            env = (1-np.exp(-t*100)) * np.exp(-t*3) * np.clip((length-t)/.09, 0, 1)
        elif kind == "bell":
            signal = np.sin(2*np.pi*f*t) + .3*np.sin(2*np.pi*f*2.756*t)*np.exp(-t*5)
            env = (1-np.exp(-t*150)) * np.exp(-t*2.1) * np.clip((length-t)/.12, 0, 1)
        else:
            signal = sum((1/h**1.9)*np.sin(2*np.pi*f*h*t)*np.exp(-t*h*.45) for h in range(1, 5))
            env = (1-np.exp(-t*200))*np.exp(-t*4.6)*np.clip((length-t)/.08, 0, 1)
        signal = (signal * env * amp).astype(np.float32)
        mix[offset:offset+n, 0] += signal * math.sqrt((1-pan)/2)
        mix[offset:offset+n, 1] += signal * math.sqrt((1+pan)/2)

    # 32 bars of 3/4, 80 bpm: exactly 72 seconds. A minor, F, C, G.
    beat = .75
    chords = [(45, [57, 60, 64]), (41, [57, 60, 65]),
              (48, [55, 60, 64]), (43, [55, 59, 62])]
    melody = [[76, 74, 72], [72, 69, 72], [76, 79, 76], [74, 71, 67],
              [69, 72, 76], [77, 76, 72], [76, 72, 67], [71, 74, 76]]
    for bar in range(31):
        start = bar * 2.25
        bass, chord = chords[(bar // 2) % 4]
        intensity = .8 if start < 7 else 1.0 if start < 32 else 1.18
        if start >= 63:
            intensity = .8
        note(start, 1.7, bass, .17*intensity, "bass")
        for pitch in chord:
            note(start, 2.9, pitch, .032*intensity, "pad", -.25)
        for eighth in range(6):
            pitch = chord[[0, 1, 2, 1, 2, 1][eighth]] + 12
            note(start+eighth*beat/2, 1.3, pitch, .085*intensity, "pluck", (-1)**eighth*.35)
        if bar >= 2:
            for b, pitch in enumerate(melody[bar % 8]):
                note(start + b*beat, 1.8, pitch, .085*intensity, "bell", .2)
        if 7 <= start < 63:
            for b in (1, 2):
                offset = round((start+b*beat)*sr)
                n = int(.07*sr)
                noise = rng.normal(0, .015*intensity, n) * np.exp(-np.arange(n)/sr*70)
                mix[offset:offset+n] += noise[:, None]
    # Gentle A-minor resolution under the final title.
    for pitch in (45, 57, 60, 64, 69, 76, 81):
        note(69.75, 2.25, pitch, .075 if pitch > 60 else .10, "bell" if pitch > 64 else "pad")
    # Sparse glints at editorial cuts.
    for cut in (7, 18, 24, 32, 43, 54, 64):
        for j, pitch in enumerate((81, 88, 93)):
            note(cut+j*.085, 1.8, pitch, .055, "bell", (j-1)*.5)
    dry = mix.copy()
    for delay, level in ((.113, .14), (.227, .09), (.379, .055)):
        n = int(delay*sr)
        mix[n:] += dry[:-n, ::-1] * level
    fade = np.minimum(np.arange(len(mix))/sr/1.8, 1)
    fade *= np.minimum((duration-np.arange(len(mix))/sr)/1.5, 1)
    mix *= fade[:, None]
    mix *= .82/max(.01, float(np.max(np.abs(mix))))
    pcm = (np.clip(mix, -1, 1)*32767).astype("<i2")
    with wave.open(str(ASSETS / "small-following-original-score.wav"), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(sr)
        wav.writeframes(pcm.tobytes())


def render_shot(shot):
    name, duration = shot["id"], shot["duration"]
    args = [FFMPEG, "-y", "-hide_banner", "-loglevel", "warning"]
    if "art" in shot:
        args += ["-loop", "1", "-framerate", str(FPS), "-i", str(ASSETS/shot["art"]),
                 "-loop", "1", "-framerate", str(FPS), "-i", str(ASSETS/f"{name}-overlay.png")]
        zoom = f"1.03+0.055*on/{duration*FPS}"
        filters = (f"[0:v]scale=3840:-1,zoompan=z='{zoom}':x='iw/2-iw/zoom/2':"
                   f"y='ih/2-ih/zoom/2':d=1:s={W}x{H}:fps={FPS},setsar=1[art];"
                   "[art][1:v]overlay=0:0:shortest=1")
    else:
        frames = list((OUT/"capture"/name).glob("*.png"))
        if len(frames) != duration*FPS:
            raise RuntimeError(f"{name}: expected {duration*FPS} frames, got {len(frames)}")
        args += ["-loop", "1", "-framerate", str(FPS), "-i", str(ASSETS/"backdrop.png"),
                 "-framerate", str(FPS), "-i", str(OUT/"capture"/name/"%05d.png"),
                 "-loop", "1", "-framerate", str(FPS), "-i", str(ASSETS/f"{name}-overlay.png")]
        filters = ("[1:v]scale=1536:960:flags=lanczos,setsar=1[game];"
                   "[0:v][game]overlay=192:82:shortest=1[framed];"
                   "[framed][2:v]overlay=0:0:shortest=1")
    filters += f",fade=t=in:st=0:d=0.25,fade=t=out:st={duration-.25}:d=0.25,format=yuv420p[v]"
    args += ["-filter_complex_threads", "2", "-filter_complex", filters, "-map", "[v]",
             "-an", "-t", str(duration), "-r", str(FPS), "-c:v", "libx264", "-crf", "18",
             "-preset", "medium", "-threads", "4", "-movflags", "+faststart", str(OUT/f"{name}.mp4")]
    run(args, name)
    print(f"Rendered {name}: {duration}s", flush=True)


def main():
    if not FFMPEG or not FFPROBE:
        raise RuntimeError("Installed FFmpeg and ffprobe must be on PATH")
    ASSETS.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    backdrop()
    for shot in SHOTS:
        make_overlay(shot)
    synthesize_score()
    print("Title plates and original score ready", flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        list(pool.map(render_shot, SHOTS))
    concat = OUT / "edit-list.txt"
    concat.write_text("".join(f"file '{s['id']}.mp4'\n" for s in SHOTS), encoding="utf-8")
    final = OUT / "Small_Following_Promo.mp4"
    run([FFMPEG, "-y", "-hide_banner", "-loglevel", "warning", "-f", "concat", "-safe", "0",
         "-i", str(concat), "-i", str(ASSETS/"small-following-original-score.wav"),
         "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-b:a", "256k",
         "-af", "loudnorm=I=-16:TP=-1.5:LRA=9", "-ar", "48000", "-t", "72", "-movflags", "+faststart",
         "-metadata", "title=Small Following - A Small Beginning",
         "-metadata", "comment=Original promo illustrations and music. Actual staged prototype gameplay.",
         str(final)], "final-mux")
    probe = subprocess.check_output([FFPROBE, "-v", "error", "-show_format", "-show_streams",
                                    "-of", "json", str(final)], text=True)
    (REVIEW/"ffprobe.json").write_text(probe, encoding="utf-8")
    metadata = json.loads(probe)
    assert float(metadata["format"]["duration"]) >= 72
    video = next(s for s in metadata["streams"] if s["codec_type"] == "video")
    assert (video["width"], video["height"]) == (W, H)
    assert video["nb_frames"] == "2160"
    run([FFMPEG, "-v", "error", "-i", str(final), "-f", "null", "-"], "decode-check")
    start = 0
    timeline = []
    for shot in SHOTS:
        timeline.append({**shot, "start": start, "end": start+shot["duration"]})
        start += shot["duration"]
    (OUT/"timeline.json").write_text(json.dumps(timeline, indent=2)+"\n", encoding="utf-8")
    print(f"VERIFIED: {final} / 72s / 1920x1080 / 30fps / stereo AAC", flush=True)


if __name__ == "__main__":
    main()
