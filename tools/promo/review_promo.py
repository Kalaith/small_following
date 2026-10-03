"""Extract review frames, a contact sheet, audio measurements and a delivery hash."""
import hashlib
import json
from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[2] / "exports" / "promo"
REVIEW = OUT / "review"
VIDEO = OUT / "Small_Following_Promo.mp4"
TIMES = [3, 10, 16, 21, 25, 29, 34, 39, 42, 45, 50, 53, 55, 59, 63.5, 68]


def main():
    sheet = Image.new("RGB", (1920, 1200), "#110b1c")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype("C:/Windows/Fonts/trebuc.ttf", 18)
    for i, at in enumerate(TIMES):
        path = REVIEW / f"frame-{at:05.1f}.png"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-ss", str(at), "-i", str(VIDEO),
                        "-frames:v", "1", str(path)], check=True)
        with Image.open(path) as frame:
            sheet.paste(frame.resize((480, 270), Image.Resampling.LANCZOS),
                        ((i % 4) * 480, (i // 4) * 300))
        draw.text(((i % 4)*480+12, (i // 4)*300+275), f"{at:04.1f} seconds", font=font, fill="#ead8fa")
    sheet.save(REVIEW / "contact-sheet.jpg", quality=94)
    result = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(VIDEO), "-af",
        "loudnorm=I=-16:TP=-1.5:LRA=9:print_format=json,silencedetect=noise=-50dB:d=0.5",
        "-vn", "-f", "null", "-"], capture_output=True, text=True, check=True)
    (REVIEW / "audio-analysis.log").write_text(result.stderr, encoding="utf-8")
    summary = dict(duration_seconds=72, resolution="1920x1080", fps=30,
                   video_frames=2160, gameplay_seconds=51, illustration_seconds=21,
                   bytes=VIDEO.stat().st_size, sha256=hashlib.sha256(VIDEO.read_bytes()).hexdigest())
    (REVIEW / "delivery.json").write_text(json.dumps(summary, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    print(result.stderr[result.stderr.rfind("{"):])


if __name__ == "__main__":
    main()
