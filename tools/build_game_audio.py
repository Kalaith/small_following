"""Build original game audio with installed NumPy/FFmpeg; preserve promo source."""
from pathlib import Path
import json
import subprocess
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/audio"
SR = 24000


def save(name, samples):
    with wave.open(str(OUT / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SR)
        output.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    source = ROOT / "exports/promo/assets/small-following-original-score.wav"
    subprocess.run([
        "ffmpeg", "-y", "-v", "error", "-i", str(source),
        "-af", "loudnorm=I=-18:TP=-3:LRA=9", "-ar", "48000",
        "-c:a", "libvorbis", "-q:a", "4", str(OUT / "village-score.ogg"),
    ], check=True)
    rng = np.random.default_rng(731)
    for index in range(4):
        t = np.arange(int(SR * .12)) / SR
        noise = rng.normal(0, 1, len(t))
        noise = np.convolve(noise, np.ones(9) / 9, mode="same")
        sound = (.34 * noise + .18 * np.sin(2 * np.pi * (145 + index * 12) * t))
        sound *= (1 - np.exp(-t * 900)) * np.exp(-t * 48)
        sound *= np.minimum((.12 - t) / .025, 1)
        save(f"step-{index + 1}.wav", sound)
    # Original vowel-like syllables: harmonic excitation shaped by formants.
    # These are synthetic murmurs, not recordings or imitations of Sims assets.
    vowels = [(700, 1200), (400, 1900), (350, 800), (550, 1600)]
    for index in range(6):
        sound = np.zeros(int(SR * .44))
        for syllable in range(3):
            duration = .105 + .012 * ((index + syllable) % 3)
            t = np.arange(int(SR * duration)) / SR
            f0 = 155 + 16 * ((index * 2 + syllable * 3) % 7)
            phase = 2 * np.pi * f0 * (t + .06 * t * t / duration)
            formants = vowels[(index + syllable) % len(vowels)]
            voice = np.zeros(len(t))
            for harmonic in range(1, 27):
                frequency = harmonic * f0
                weight = .16 / harmonic + sum(
                    np.exp(-.5 * ((frequency - formant) / 160) ** 2)
                    for formant in formants
                ) / harmonic ** .45
                voice += weight * np.sin(harmonic * phase)
            voice *= np.sin(np.pi * t / duration) ** 1.3
            offset = int(syllable * .145 * SR)
            sound[offset:offset + len(t)] += voice
        sound *= .42 / max(.01, np.max(np.abs(sound)))
        save(f"murmur-{index + 1}.wav", sound)
    print(json.dumps({"output": str(OUT), "music_seconds": 72,
                      "steps": 4, "murmurs": 6}))


if __name__ == "__main__":
    main()
