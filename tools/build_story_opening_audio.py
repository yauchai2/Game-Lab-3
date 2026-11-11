#!/usr/bin/env python3
"""Original deterministic sound design for the 18 s boot story opening.

Synthesised layers plus the CC0 Kenney impact/footstep samples already shipped in
godot/audio/open. No recording from the reference video is used. 48 kHz stereo PCM,
noise seed 20261112. Cue times mirror story_opening.gd (IMPACTS / MUSIC_CUT / TITLE_AT).
Music is NOT baked in: the menu track is ducked/cut/returned by the game at runtime.

Run: python3 tools/build_story_opening_audio.py
"""
from pathlib import Path
import hashlib, json, subprocess, wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot/audio/story_opening"
OPEN = ROOT / "godot/audio/open"
RATE = 48000
DURATION = 18.4
rng = np.random.default_rng(20261112)
mix = np.zeros((int(RATE * DURATION), 2))


def sample(name):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(OPEN / name), "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def clock(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def noise(n, low=0.0, high=24000.0, order=6):
    spectrum = np.fft.rfft(rng.normal(0, 1, n))
    freq = np.fft.rfftfreq(n, 1 / RATE)
    shape = 1 / np.sqrt(1 + (freq / max(high, 1.0)) ** order)
    if low > 0:
        shape *= 1 / np.sqrt(1 + (low / np.maximum(freq, 1e-3)) ** order)
    result = np.fft.irfft(spectrum * shape, n=n)
    return result / max(np.std(result), 1e-9)


def band(n, centre, width):
    return noise(n, centre - width * 0.5, centre + width * 0.5, 8)


def env(t, attack, release, duration):
    return np.clip(t / attack, 0, 1) * np.clip((duration - t) / release, 0, 1)


def add(at, signal, gain=1.0, pan=0.0):
    start = int(at * RATE)
    n = min(len(signal), len(mix) - start)
    if n <= 0 or start < 0:
        return
    p = np.asarray(pan, dtype=np.float64)
    if p.ndim:
        p = p[:n]
    angle = (np.clip(p, -1, 1) + 1) * np.pi / 4
    mix[start:start + n, 0] += signal[:n] * gain * np.cos(angle)
    mix[start:start + n, 1] += signal[:n] * gain * np.sin(angle)


def pitched(data, ratio):
    index = np.arange(0, len(data) - 1, ratio)
    return np.interp(index, np.arange(len(data)), data)


def echo(at, signal, gain, pan, taps):
    add(at, signal, gain, pan)
    for delay, level in taps:
        add(at + delay, signal, gain * level, -pan * 0.6)


def kick(at, power, top=120.0, floor=36.0, length=0.9, pan=0.0):
    t = clock(length)
    phase = 2 * np.pi * (floor * t + (top - floor) * 0.045 * (1 - np.exp(-t / 0.045)))
    body = np.sin(phase) * np.exp(-t / (length * 0.28))
    crack = noise(len(t), 600, 9000) * np.exp(-t / 0.012) * 0.5
    add(at, (body + crack) * env(t, 0.002, 0.08, length), power, pan)


METAL_HEAVY = sample("impactMetal_heavy_003.ogg")
METAL_LIGHT = sample("impactMetal_light_000.ogg")
TIN = sample("impactTin_medium_001.ogg")
SOFT = sample("impactSoft_heavy_000.ogg")
PUNCH = sample("impactPunch_heavy_000.ogg")
STEP_A = sample("footstep_concrete_000.ogg")
STEP_B = sample("footstep_concrete_003.ogg")
BELL = sample("impactBell_heavy_003.ogg")

# ---- 0-3 s  City awake: train roar passing, street bed, the dive.
t = clock(3.6)
passing = np.exp(-((t - 0.9) / 1.15) ** 2)
rumble = noise(len(t), 30, 190) * 0.75 + band(len(t), 620, 500) * 0.22
clatter = (np.sin(2 * np.pi * 7.3 * t) > 0.86) * noise(len(t), 900, 5200) * 0.5
add(0.0, (rumble + clatter) * passing * env(t, 0.05, 0.6, 3.6), 0.62, np.linspace(-0.75, 0.8, len(t)))
horn = (np.sin(2 * np.pi * 311 * t) + np.sin(2 * np.pi * 392 * t)) * np.exp(-((t - 0.55) / 0.3) ** 2) * (1 - 0.25 * t)
add(0.0, horn, 0.05, np.linspace(-0.5, 0.7, len(t)))
t = clock(3.3)
street = noise(len(t), 180, 2600, 4) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.7 * t))
add(0.0, street * env(t, 0.3, 0.5, 3.3), 0.09, 0.25 * np.sin(2 * np.pi * 0.3 * t))
for at, f in [(1.25, 520), (1.9, 430), (2.45, 610)]:
    tt = clock(0.16)
    add(at, np.sign(np.sin(2 * np.pi * f * tt)) * env(tt, 0.01, 0.05, 0.16), 0.02, 0.5 if f > 500 else -0.5)
t = clock(2.5)
dive = band(len(t), 500, 420) * np.sin(np.clip(t / 2.5, 0, 1) * np.pi) ** 2
sweep = np.sin(2 * np.pi * np.cumsum(140 + 520 * (t / 2.5) ** 2) / RATE) * 0.15 * np.sin(t / 2.5 * np.pi)
add(0.45, (dive + sweep) * (0.5 + 0.5 * t / 2.5), 0.2, np.linspace(-0.3, 0.3, len(t)))

# ---- 3-6 s  Four lives: whip moves, ratchet, speaker static, straw.
for at in (3.8, 4.9):
    tt = clock(0.34)
    add(at, band(len(tt), 1500, 1800) * np.sin(tt / 0.34 * np.pi) ** 2, 0.2, np.linspace(-0.8, 0.8, len(tt)))
for at in (3.2, 3.42, 3.64):
    for k in range(4):
        add(at + k * 0.032, pitched(METAL_LIGHT, 1.9 + 0.1 * k)[:2600], 0.4, -0.55)
tt = clock(0.75)
hum = sum(np.sin(2 * np.pi * 50 * h * tt) / h for h in (1, 2, 3, 5, 7))
gate = (noise(len(tt), 5, 28) > 0.1).astype(float)
static = hum * 0.5 + noise(len(tt), 2500, 9000) * gate * 0.7
add(4.12, static * env(tt, 0.01, 0.06, 0.75), 0.2, 0.3)
tt = clock(0.12)
add(4.55, np.sign(np.sin(2 * np.pi * 95 * tt)) * noise(len(tt), 800, 6000) * env(tt, 0.002, 0.08, 0.12), 0.26, 0.3)
tt = clock(0.6)
slurp = band(len(tt), 1500, 900) * (0.55 + 0.45 * np.sign(np.sin(2 * np.pi * 31 * tt + np.sin(tt * 40))))
add(5.22, slurp * env(tt, 0.05, 0.12, 0.6), 0.2, 0.6)

# ---- 6-9 s  ZIP returns: steps, then the case and the bass drum land together.
add(6.12, STEP_A, 0.45, 0.0)
add(6.55, pitched(STEP_B, 0.72), 0.75, 0.0)
kick(6.55, 0.42, 90, 40, 0.5)
add(6.98, pitched(STEP_A, 0.85), 0.42, 0.1)
tt = clock(0.3)
add(7.68, band(len(tt), 700, 700) * (tt / 0.3) ** 2, 0.14, 0.0)
kick(8.0, 1.0, 130, 34, 1.1)
add(8.0, METAL_HEAVY, 0.7, 0.0)
add(8.0, pitched(PUNCH, 0.7), 0.5, 0.0)
for k, (delay, ratio) in enumerate([(0.06, 1.5), (0.11, 2.1), (0.17, 1.8), (0.25, 2.5), (0.33, 2.0)]):
    add(8.0 + delay, pitched(TIN if k % 2 else METAL_LIGHT, ratio), 0.12, -0.6 + k * 0.3)

# ---- 9-12 s  Wrong delivery: latches with echo, then only the tubes.
click = pitched(METAL_LIGHT, 2.4)[:5200]
echo(9.15, click, 0.5, -0.35, [(0.17, 0.4), (0.34, 0.2), (0.52, 0.09)])
echo(9.45, click, 0.55, 0.35, [(0.17, 0.42), (0.34, 0.22), (0.52, 0.1)])
tt = clock(0.26)
add(9.5, band(len(tt), 240, 200) * (tt / 0.26) ** 2, 0.08, 0.0)
tt = clock(0.07)
add(9.74, noise(len(tt), 60, 3000) * np.exp(-tt / 0.012), 0.2, 0.0)  # the cut itself
t = clock(2.35)
tube = sum(np.sin(2 * np.pi * 100 * h * t + h) / h ** 1.2 for h in (1, 2, 3, 4, 6)) * 0.5 + noise(len(t), 3000, 9000) * 0.12
flick = np.ones(len(t))
for at in (0.30, 1.45):
    flick[int(at * RATE):int((at + 0.09) * RATE)] = 0.2
add(9.78, tube * flick * env(t, 0.04, 0.2, 2.35), 0.06, 0.0)
for at in (10.05, 11.2):
    echo(at, pitched(TIN, 3.2)[:1500], 0.07, 0.2, [(0.11, 0.3)])

# ---- 12-15 s  Collectors: brake, three doors as one, shoes, glove; a rising floor.
t = clock(0.86)
engine = np.sign(np.sin(2 * np.pi * np.cumsum(84 - 44 * t / 0.86) / RATE)) * 0.4 + noise(len(t), 40, 400) * 0.6
add(12.0, engine * env(t, 0.05, 0.12, 0.86), 0.2, np.linspace(0.85, -0.1, len(t)))
t = clock(0.44)
screech = np.sin(2 * np.pi * np.cumsum(2350 - 800 * t / 0.44) / RATE + np.sin(2 * np.pi * 37 * t) * 2.0) + band(len(t), 2000, 700) * 0.6
add(12.34, screech * env(t, 0.03, 0.1, 0.44), 0.13, np.linspace(0.5, -0.1, len(t)))
add(12.78, pitched(SOFT, 0.8), 0.35, 0.0)
for k, pan in enumerate((-0.6, 0.0, 0.6)):
    add(13.1 + k * 0.006, pitched(PUNCH, 0.62 + k * 0.03), 0.42, pan)
    add(13.1 + k * 0.006, pitched(METAL_LIGHT, 1.3)[:6000], 0.2, pan)
kick(13.1, 0.55, 100, 42, 0.5)
for at in (13.55, 13.85):
    for k, pan in enumerate((-0.5, 0.0, 0.5)):
        add(at + k * 0.004, pitched(STEP_B, 1.15), 0.45, pan)
    kick(at, 0.3, 80, 45, 0.3)
t = clock(0.26)
creak = np.sin(2 * np.pi * np.cumsum(260 + 420 * t / 0.26) / RATE) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 70 * t))) + band(len(t), 1800, 1200) * 0.5
add(14.2, creak * env(t, 0.02, 0.05, 0.26), 0.17, 0.1)
add(14.46, pitched(TIN, 2.6)[:2400], 0.36, 0.1)
kick(14.46, 0.34, 80, 45, 0.3)
# The three sounds become a pulse: door, shoe, shoe, glove, then tighter.
for at in (14.75, 14.98, 15.2, 15.38, 15.54, 15.66, 15.76, 15.84, 15.9, 15.95):
    kick(at, 0.2 + (at - 14.75) * 0.22, 70, 44, 0.22)
t = clock(3.0)
rise = np.sin(2 * np.pi * np.cumsum(30 + 48 * (t / 3.0) ** 2) / RATE) * (t / 3.0) ** 1.6
air = noise(len(t), 1800, 12000) * (t / 3.0) ** 4 * 0.35
add(13.0, (rise + air) * np.clip((3.0 - t) / 0.01, 0, 1), 0.3, 0.0)

# ---- 15-18 s  Title drop: lid slam + metal + bass burst, a held breath, the title.
t = clock(0.5)
stab = sum(np.sign(np.sin(2 * np.pi * f * t)) for f in (55, 55.7, 110.4)) * np.exp(-t / 0.16)
add(15.0, stab, 0.12, 0.0)
t = clock(0.32)
add(15.68, band(len(t), 900, 900) * (t / 0.32) ** 3, 0.3, 0.0)
add(16.0, METAL_HEAVY, 0.95, 0.0)
add(16.0, pitched(METAL_HEAVY, 0.55), 0.6, 0.0)
add(16.0, pitched(PUNCH, 0.55), 0.6, 0.0)
kick(16.0, 1.1, 150, 30, 0.5)
kick(16.1, 1.25, 140, 28, 1.9)
add(16.1, pitched(BELL, 0.5), 0.4, 0.0)
add(16.1, pitched(METAL_HEAVY, 0.8), 0.5, -0.2)
t = clock(2.0)
wash = noise(len(t), 2500, 14000) * np.exp(-t / 0.5)
add(16.1, wash, 0.22, np.linspace(-0.4, 0.4, len(t)))
sub = np.sin(2 * np.pi * 41 * t) * np.exp(-t / 0.9)
add(16.1, sub, 0.3, 0.0)

# The 0.1 s freeze: pull everything down between the slam transient and the title.
gate = np.ones(len(mix))
a, b, c = int(16.035 * RATE), int(16.095 * RATE), int(16.1 * RATE)
gate[a:b] = np.linspace(1.0, 0.12, b - a)
gate[b:c] = np.linspace(0.12, 1.0, c - b)
mix *= gate[:, None]
tail = int(0.35 * RATE)
mix[-tail:] *= np.linspace(1, 0, tail)[:, None]

peak = np.max(np.abs(mix))
out = np.tanh(mix / peak * 2.6) / np.tanh(2.6) * 0.92
OUT.mkdir(parents=True, exist_ok=True)
pcm = (np.clip(out, -1, 1) * 32767).astype("<i2")
with wave.open(str(OUT / "score.wav"), "wb") as handle:
    handle.setnchannels(2)
    handle.setsampwidth(2)
    handle.setframerate(RATE)
    handle.writeframes(pcm.tobytes())
cues = {
    "duration": 18.0,
    "cuts": [0, 3, 6, 9, 12, 15, 18],
    "music": {"radio_in": [0.0, 6.0], "cut": 9.75, "returns_with_title": 16.1},
    "cues": [
        [0.0, "train pass, street bed, dive"], [3.2, "ratchet x3"], [4.12, "speaker static"], [5.22, "straw"],
        [6.55, "heavy step"], [8.0, "case + bass drum"], [9.15, "latch 1"], [9.45, "latch 2"], [9.75, "music cut, tubes only"],
        [12.0, "car in"], [12.34, "brake"], [13.1, "three doors"], [13.55, "shoes"], [13.85, "shoes"], [14.2, "glove"],
        [14.75, "pulse tightens, floor rises"], [16.0, "lid slam"], [16.035, "held breath"], [16.1, "title hit"]],
    "sources": ["synthesis (seed 20261112)", "godot/audio/open Kenney CC0 impacts and footsteps"],
    "sha256": hashlib.sha256(pcm.tobytes()).hexdigest(),
}
(OUT / "cues.json").write_text(json.dumps(cues, indent=2) + "\n")
print(json.dumps({"bytes": (OUT / "score.wav").stat().st_size, "peak_before": float(peak), "sha256": cues["sha256"]}))
