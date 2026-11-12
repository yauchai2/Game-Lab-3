#!/usr/bin/env python3
"""Deterministic score and sound design for the 18 s boot story opening.

An original 160 BPM half-time beat (one shot = two bars, so every cut lands on a
downbeat) is written here from scratch and baked together with the diegetic sound.
Sources: synthesis, the CC0 Kenney impacts in godot/audio/open, and CC0 BigSoundBank
field recordings and drum hits in references/story-opening-audio (see provenance.json
there; fetched by tools/fetch_story_opening_sources.py). Nothing is taken from any
reference video. 48 kHz stereo PCM, noise seed 20261112.

Cue times mirror story_opening.gd (IMPACTS / MUSIC_CUT / SLAM_AT / TITLE_AT). The menu
track stays silent under this score and fades back in after the title hit.

Run: python3 tools/build_story_opening_audio.py
"""
from pathlib import Path
import hashlib, json, subprocess, wave
import numpy as np
from scipy import signal

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot/audio/story_opening"
OPEN = ROOT / "godot/audio/open"
SRC = ROOT / "references/story-opening-audio"
RATE = 48000
DURATION = 18.4
N = int(RATE * DURATION)
STEP = 60.0 / 160.0 / 4.0  # one sixteenth = 0.09375 s
BAR = STEP * 16  # 1.5 s
MUSIC_CUT, SLAM_AT, TITLE_AT = 9.75, 16.0, 16.1
rng = np.random.default_rng(20261112)
STEMS = {name: np.zeros((N, 2)) for name in ("kick", "drums", "bass", "music", "sfx", "amb", "hits")}


# ------------------------------------------------------------------ helpers
def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def unit(data):
    return data / max(np.max(np.abs(data)), 1e-9)


def src(name):
    return unit(decode(SRC / f"{name}.ogg"))


def kenney(name):
    return unit(decode(OPEN / name))


def clock(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def faded(data, attack=0.003, release=0.02):
    data = data.copy()
    a, r = min(int(attack * RATE), len(data) // 2), min(int(release * RATE), len(data) // 2)
    if a:
        data[:a] *= np.linspace(0, 1, a)
    if r:
        data[-r:] *= np.linspace(1, 0, r)
    return data


def cut(data, start, length, attack=0.003, release=0.02):
    return faded(data[int(start * RATE):int((start + length) * RATE)], attack, release)


def onsets(data, floor_db=-30.0, rise_db=10.0, gap=0.09):
    window = int(RATE * 0.01)
    frames = data[:len(data) // window * window].reshape(-1, window)
    level = 20 * np.log10(np.sqrt(np.mean(frames ** 2, axis=1)) + 1e-9)
    found, last = [], -1000
    for i in range(3, len(level)):
        if level[i] > floor_db and level[i] - level[i - 3] > rise_db and i - last > gap / 0.01:
            found.append(max(0, (i - 2) * window))
            last = i
    return found


def events(data, length, count=None):
    """Loudest distinct hits of a recording, loudest first, each starting on its attack."""
    ranked = sorted(onsets(data), key=lambda i: -np.max(np.abs(data[i:i + int(0.08 * RATE)])))
    return [faded(data[i:i + int(length * RATE)], 0.001, min(0.05, length / 3)) for i in ranked[:count]]


def lead_in(data, threshold=0.08):
    """Drop silence before the first real sample so hits can be placed on the grid."""
    above = np.nonzero(np.abs(data) > threshold * np.max(np.abs(data)))[0]
    return data[max(0, above[0] - int(0.002 * RATE)):] if len(above) else data


def sos(kind, freq, order=4):
    return signal.butter(order, freq, kind, fs=RATE, output="sos")


def lowpass(data, freq, order=4):
    return signal.sosfilt(sos("low", freq, order), data, axis=0)


def highpass(data, freq, order=4):
    return signal.sosfilt(sos("high", freq, order), data, axis=0)


def bandpass(data, low, high, order=2):
    return signal.sosfilt(sos("band", [low, high], order), data, axis=0)


def pitched(data, ratio):
    index = np.arange(0, len(data) - 1, ratio)
    return np.interp(index, np.arange(len(data)), data)


def noise(n):
    return rng.normal(0, 1, n)


def drive(data, amount):
    return np.tanh(data * amount) / np.tanh(amount)


def add(stem, at, data, gain=1.0, pan=0.0):
    start = int(round(at * RATE))
    if start < 0:
        data, start = data[-start:], 0
    n = min(len(data), N - start)
    if n <= 0:
        return
    p = np.asarray(pan, dtype=np.float64)
    if p.ndim:
        p = np.resize(p, len(data))[:n]
    angle = (np.clip(p, -1, 1) + 1) * np.pi / 4
    STEMS[stem][start:start + n, 0] += data[:n] * gain * np.cos(angle)
    STEMS[stem][start:start + n, 1] += data[:n] * gain * np.sin(angle)


def room(stereo, seconds, wet, low=250.0, high=7000.0):
    """Decorrelated noise-tail reverb; returns dry + wet."""
    t = clock(seconds)
    out = stereo.copy()
    for channel in range(2):
        tail = noise(len(t)) * np.exp(-t / (seconds / 5.0))
        tail = bandpass(tail, low, high)
        tail /= np.sqrt(np.sum(tail ** 2))
        out[:, channel] += signal.fftconvolve(stereo[:, channel], tail)[:len(stereo)] * wet
    return out


# ------------------------------------------------------------------ instruments
SNARES = [lead_in(src("snare_a")), lead_in(src("snare_b")), lead_in(src("snare_c"))]
HATS = [lead_in(src("hat_a")), lead_in(src("hat_b")), lead_in(src("hat_c"))]
HAT_OPEN = lead_in(src("hat_open"))
CRASH_A, CRASH_B = lead_in(src("crash_a")), lead_in(src("crash_b"))
TOM_LOW, TOM_MID = lead_in(src("tom_low")), lead_in(src("tom_mid"))
SCRATCH = [lead_in(src(f"scratch_{k}")) for k in "abcd"]
WHOOSH = [src(f"whoosh_{k}") for k in "abcd"]
METAL_HEAVY = kenney("impactMetal_heavy_003.ogg")
METAL_LIGHT = kenney("impactMetal_light_000.ogg")
TIN = kenney("impactTin_medium_001.ogg")
PUNCH = kenney("impactPunch_heavy_000.ogg")
NOTE = {"Eb1": 38.89, "F1": 43.65, "Gb1": 46.25, "Ab1": 51.91, "C2": 65.41, "F2": 87.31}


def kick(at, gain=1.0, length=0.3, top=230.0, floor=58.0):
    t = clock(length)
    phase = 2 * np.pi * (floor * t + (top - floor) * 0.022 * (1 - np.exp(-t / 0.022)))
    body = np.sin(phase) * np.exp(-t / (length * 0.33))
    click = highpass(noise(len(t)), 2500) * np.exp(-t / 0.004) * 0.35
    knock = bandpass(noise(len(t)), 150, 900) * np.exp(-t / 0.02) * 0.25
    add("kick", at, faded(drive(body * 2.2, 1.8) + click + knock, 0.0005, 0.03), gain * 0.8)


def sub(at, note, steps, gain=1.0, glide_to=None, glide=0.5):
    """808-style bass: pitch-dropped attack, long sine, driven so small speakers hear it."""
    length = steps * STEP
    t = clock(length + 0.06)
    freq = np.full(len(t), NOTE[note])
    if glide_to:
        u = np.clip((t / length - glide) / (1 - glide), 0, 1)
        freq = NOTE[note] * (NOTE[glide_to] / NOTE[note]) ** (u * u * (3 - 2 * u))
    freq = freq + 70.0 * np.exp(-t / 0.018)
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    wave_ = np.sin(phase) * 0.55 + np.sin(2 * phase) * 0.6 + np.sin(3 * phase) * 0.3
    shaped = drive(wave_ * (1.0 + 1.6 * np.exp(-t / 0.25)), 2.6)
    envelope = np.clip(t / 0.004, 0, 1) * np.clip((length + 0.06 - t) / 0.06, 0, 1) * (0.72 + 0.28 * np.exp(-t / 0.35))
    add("bass", at, lowpass(shaped, 1400) * envelope, gain * 0.5)


def snare(at, gain=1.0, which=0, clap=True, pan=0.0):
    hit = SNARES[which % 3][:int(0.42 * RATE)]
    add("drums", at, faded(hit, 0.0005, 0.08), gain * 0.95, pan)
    add("drums", at, faded(pitched(SNARES[(which + 1) % 3], 0.84)[:int(0.3 * RATE)], 0.0005, 0.08), gain * 0.5, pan)
    if clap:
        t = clock(0.22)
        burst = sum(np.where(t >= d, np.exp(-(t - d) / 0.011), 0.0) for d in (0.0, 0.011, 0.023)) + np.where(t >= 0.03, np.exp(-(t - 0.03) / 0.07), 0.0)
        add("drums", at, bandpass(noise(len(t)), 900, 3800) * burst, gain * 0.5, pan)


def hat(at, gain=1.0, which=0, pan=0.45):
    add("drums", at, faded(highpass(HATS[which % 3][:int(0.11 * RATE)], 5000), 0.0005, 0.03), gain * 0.62, pan)


def open_hat(at, gain=1.0, length=0.28):
    add("drums", at, faded(highpass(HAT_OPEN[:int(length * RATE)], 4000), 0.001, 0.08), gain * 0.5, -0.5)


def crash(at, gain=1.0, which=0, length=2.6):
    data = (CRASH_A, CRASH_B)[which][:int(length * RATE)]
    wide = highpass(data, 900) * np.exp(-clock(len(data) / RATE)[:len(data)] / (length * 0.45))
    add("drums", at, faded(wide, 0.001, 0.3), gain * 0.55, -0.6)
    add("drums", at + 0.011, faded(wide, 0.001, 0.3), gain * 0.55, 0.6)


def stab(at, gain=1.0, steps=2, cutoff=1500.0, pan=0.0):
    """Detuned minor-ninth stab, the hook of the underground radio."""
    t = clock(steps * STEP + 0.12)
    tone = np.zeros(len(t))
    for freq in (174.61, 207.65, 261.63, 311.13, 392.0):  # F3 Ab3 C4 Eb4 G4
        for detune in (-0.006, 0.0, 0.007):
            f = freq * (1 + detune)
            tone += signal.sawtooth(2 * np.pi * f * t + rng.uniform(0, 6.28))
    tone = lowpass(tone / 9.0, cutoff) * np.exp(-t / 0.13) * np.clip(t / 0.003, 0, 1)
    for k, level in enumerate((1.0, 0.42, 0.2, 0.09)):  # dotted-eighth delay
        side = -0.8 if k % 2 else 0.8
        add("music", at + k * 3 * STEP, tone, gain * level * 0.75, pan - 0.5 if k == 0 else side)
        add("music", at + k * 3 * STEP + 0.013, tone, gain * level * 0.6, pan + 0.7 if k == 0 else -side)


def pluck(at, freq, gain=1.0, pan=0.0):
    t = clock(0.3)
    tone = (signal.square(2 * np.pi * freq * t, 0.3) + signal.square(2 * np.pi * freq * 1.004 * t, 0.5)) * np.exp(-t / 0.06)
    tone = bandpass(tone, 500, 4200) * np.clip(t / 0.002, 0, 1)
    for k, level in enumerate((1.0, 0.35, 0.14)):
        add("music", at + k * 2 * STEP, tone, gain * level * 0.5, pan * (1 if k % 2 == 0 else -1.6))


def scratch(at, which, gain=1.0, length=None, ratio=1.0, pan=0.15):
    data = pitched(SCRATCH[which], ratio)
    if length:
        data = data[:int(length * RATE)]
    add("music", at, faded(highpass(data, 250), 0.001, 0.03), gain * 0.8, pan)


def reverse_swell(at_end, data, length, gain, stem="hits", pan=0.0, curve=2.0):
    piece = data[:int(length * RATE)][::-1].copy()
    piece *= np.linspace(0, 1, len(piece)) ** curve
    add(stem, at_end - len(piece) / RATE, piece, gain, pan)


def riser(at_end, length, gain, low=300.0, high=9000.0):
    t = clock(length)
    u = t / length
    sweep = np.zeros(len(t))
    raw = noise(len(t))
    # Time-varying band: a stack of bands faded in from low to high.
    edges = np.geomspace(low, high, 7)
    for k in range(6):
        sweep += bandpass(raw, edges[k], edges[k + 1]) * np.clip(1 - np.abs(u * 6 - k - 0.5) / 1.5, 0, 1)
    tone = np.sin(2 * np.pi * np.cumsum(110 * 2 ** (u * 2.0)) / RATE) * 0.3
    add("hits", at_end - length, (sweep + tone) * u ** 2.2, gain, np.linspace(-0.5, 0.5, len(t)))


# ------------------------------------------------------------------ the beat
def beat_bar(start, variant, first=0, last=16, energy=1.0):
    """One 1.5 s bar of the half-time groove. Kick on one, snare on the third beat."""
    patterns = {
        "a": {"kick": [0, 10], "sub": [(0, "F1", 6, None), (10, "F1", 3, None), (13, "Ab1", 3, "F1")], "roll": [14, 15], "open": [6]},
        "b": {"kick": [0, 3, 10, 11], "sub": [(0, "F1", 3, None), (3, "F1", 5, "Eb1"), (10, "Gb1", 2, None), (12, "F1", 4, "C2")], "roll": [6, 7, 15], "open": [12]},
        "c": {"kick": [0, 6, 10, 13], "sub": [(0, "F1", 6, None), (6, "Ab1", 2, None), (10, "F1", 3, None), (13, "Eb1", 3, "F1")], "roll": [3, 14, 15], "open": [6]},
    }
    p = patterns[variant]
    inside = lambda s: first <= s < last
    for s in p["kick"]:
        if inside(s):
            kick(start + s * STEP, energy)
    for s, note, steps, glide in p["sub"]:
        if inside(s):
            sub(start + s * STEP, note, min(steps, last - s), energy, glide)
    if inside(8):
        snare(start + 8 * STEP, energy, which=0)
    if variant != "a" and inside(15):
        snare(start + 15 * STEP, energy * 0.35, which=2, clap=False, pan=0.2)
    for s in range(16):
        if not inside(s):
            continue
        swing = 0.012 if s % 2 else 0.0
        if s in p["roll"]:
            for k in range(3 if s == 15 else 2):  # 32nd / triplet rolls
                gap = STEP / (3 if s == 15 else 2)
                hat(start + s * STEP + k * gap, energy * (0.55 + 0.2 * k), which=k, pan=0.25 + 0.15 * k)
        else:
            hat(start + s * STEP + swing, energy * (1.0 if s % 4 == 0 else (0.75 if s % 2 == 0 else 0.45)), which=s % 2)
    for s in p["open"]:
        if inside(s):
            open_hat(start + s * STEP, energy)


def hook(start, variant, first=0, last=16, energy=1.0):
    marks = {"a": [(3, 1.0), (11, 0.8)], "b": [(3, 1.0), (9, 0.7), (11, 0.8)], "c": [(3, 1.0), (11, 0.8), (14, 0.6)]}[variant]
    for s, level in marks:
        if first <= s < last:
            stab(start + s * STEP, energy * level, cutoff=1300 + 500 * level, pan=-0.2)
    riff = {"a": [(4, 349.23), (6, 415.3), (7, 349.23), (12, 523.25)], "b": [(4, 349.23), (6, 415.3), (7, 466.16), (12, 392.0), (14, 349.23)], "c": [(4, 523.25), (6, 466.16), (7, 415.3), (12, 349.23)]}[variant]
    for s, freq in riff:
        if first <= s < last:
            pluck(start + s * STEP, freq, energy, pan=0.4)


# ================================================================== 0-3 s  City awake
# The elevated train roars past, the street is alive, and a radio finds the beat.
tram = src("tram_pass")
t = clock(3.6)
passing = np.exp(-((t - 0.95) / 1.2) ** 2)
add("amb", 0.0, highpass(tram[int(1.6 * RATE):int(5.2 * RATE)], 45) * passing, 1.9, np.linspace(-0.8, 0.85, len(t)))
rumble = lowpass(noise(len(t)), 110) * 6.0
add("amb", 0.0, rumble * passing, 0.8, np.linspace(-0.6, 0.6, len(t)))
street = src("street_bus_stop")
add("amb", 0.0, faded(highpass(street[:int(3.4 * RATE)], 150), 0.3, 0.5), 0.55, 0.2 * np.sin(2 * np.pi * 0.3 * clock(3.4)))
add("amb", 2.02, faded(src("dog"), 0.005, 0.05), 0.07, 0.7)
sweep = src("radio_sweep")
add("sfx", 0.18, faded(bandpass(sweep[:int(1.25 * RATE)], 500, 5000), 0.02, 0.12), 0.3, np.linspace(-0.4, 0.2, int(1.25 * RATE)))
beat_bar(0.0, "a", first=8)
hook(0.0, "a", first=8)
beat_bar(BAR, "b")
hook(BAR, "b")
riser(3.0, 2.3, 0.4)
reverse_swell(3.0, CRASH_A, 1.4, 0.3, pan=-0.2)
add("sfx", 2.35, pitched(WHOOSH[0], 0.6), 0.4, np.linspace(-0.3, 0.3, 4000))

# ================================================================== 3-6 s  Four lives
# The drop: the full beat, with the garage playing along (ratchet, wrench, static, scratch, straw).
crash(3.0, 1.0, 0)
beat_bar(2 * BAR, "a")
hook(2 * BAR, "a")
beat_bar(3 * BAR, "c")
hook(3 * BAR, "c")
ratchet = src("ratchet")
clicks = events(ratchet, 0.07, 6)
for k in range(5):  # two ratchet runs, each locked to the sixteenths
    add("sfx", 3.0 + 2 * STEP + k * STEP / 2, clicks[k % len(clicks)], 0.5, -0.55)
for k in range(4):
    add("sfx", 3.0 + 6 * STEP + k * STEP / 2, clicks[(k + 2) % len(clicks)], 0.45, -0.5)
wrench = src("impact_wrench")
add("sfx", 3.0 + 9 * STEP, cut(wrench, 0.3, 0.26), 0.3, -0.45)
for at, which in ((3.8, 2), (4.9, 3)):  # whip pans
    add("sfx", at - 0.12, WHOOSH[which], 0.34, np.linspace(-0.8, 0.8, len(WHOOSH[which])))
crackle = src("radio_crackle")
add("sfx", 4.125, cut(crackle, 0.4, 0.36), 0.36, 0.3)
scratch(4.5, 0, 0.9, length=0.42)
scratch(4.5 + 6 * STEP, 3, 0.7, length=0.3, ratio=1.15)
straw = src("straw_end")
add("sfx", 5.3, cut(straw, 0.1, 0.5), 0.42, 0.6)
scratch(6.0 - 4 * STEP, 1, 1.0, length=4 * STEP - 0.01)  # LOOP's fill into the cut

# ================================================================== 6-9 s  ZIP returns
# The beat sinks under the floor for the giant sole, drops out, and the case brings it back.
sub(6.0, "F1", 14, 0.55)
for s in (0, 4, 8, 12):
    hat(6.0 + s * STEP, 0.55, which=s // 4)
steps = events(src("shoe_concrete"), 0.4, 4)
add("sfx", 6.12, steps[2], 0.4, -0.1)
add("sfx", 6.0 + 6 * STEP, pitched(steps[0], 0.62), 0.95, 0.0)  # the giant sole, 6.56 s
add("hits", 6.0 + 6 * STEP, faded(pitched(TOM_LOW, 0.55)[:int(0.9 * RATE)], 0.001, 0.3), 0.6, 0.0)
kick(6.0 + 6 * STEP, 0.8, 0.5, 120, 38)
add("sfx", 6.98, pitched(steps[1], 0.8), 0.5, 0.12)
kick(6.98, 0.35, 0.3, 100, 42)
# Bar 6: half a second of held breath, then the slam at 8.0 and the beat back on the snare.
riser(8.0, 0.5, 0.7, 500, 11000)
reverse_swell(8.0, CRASH_B, 0.55, 0.32)
for k in range(8):
    snare(7.5 + k * 0.0625, 0.12 + 0.08 * k, which=k, clap=False, pan=-0.3 + 0.08 * k)
case = events(src("suitcase"), 0.5, 3)
add("hits", 8.0, src("explosion_b"), 0.9, 0.0)
add("hits", 8.0, METAL_HEAVY, 0.6, 0.0)
add("hits", 8.0, pitched(PUNCH, 0.7), 0.55, 0.0)
add("sfx", 8.0, pitched(case[0], 0.8), 0.7, 0.0)
sub(8.0, "F2", 2.4, 1.25, "F1", 0.0)
kick(8.0, 1.2, 0.45, 210, 40)
tink = src("cartridge")
for k, (delay, ratio) in enumerate([(0.06, 1.0), (0.11, 1.4), (0.17, 0.8), (0.25, 1.7), (0.33, 1.2)]):  # tools jump
    add("sfx", 8.0 + delay, pitched(tink if k % 2 else TIN, ratio)[:int(0.3 * RATE)], 0.16, -0.6 + k * 0.3)
crash(7.5 + 8 * STEP, 0.9, 1)
beat_bar(5 * BAR, "c", first=8, energy=1.08)
hook(5 * BAR, "c", first=8)

# ================================================================== 9-12 s  Wrong delivery
# Half a bar of full beat under the latches, then the music is ripped out on the third beat.
beat_bar(6 * BAR, "b", last=8, energy=1.08)
hook(6 * BAR, "b", last=6)
latch = events(src("briefcase"), 0.22, 4)
tail_taps = [(0.17, 0.42), (0.34, 0.22), (0.52, 0.1)]
for at, pan, which in ((9.15, -0.35, 0), (9.45, 0.35, 1)):
    add("sfx", at, latch[which], 0.85, pan)
    add("sfx", at, pitched(METAL_LIGHT, 2.4)[:5200], 0.32, pan)
    if at > 9.3:  # only the second latch rings into the silence
        for delay, level in tail_taps:
            add("sfx", at + delay, latch[which], 0.85 * level, -pan * 0.6)
neon = src("neon")
t = clock(2.35)
flicker = np.ones(len(t))
for at in (0.30, 1.45):
    flicker[int(at * RATE):int((at + 0.09) * RATE)] = 0.15
add("amb", 9.78, highpass(neon[:len(t)], 80) * flicker * faded(np.ones(len(t)), 0.03, 0.25), 0.2, 0.0)
tone = np.sin(2 * np.pi * 6100 * t) * np.exp(-t / 0.7)  # the ears ring where the music was
add("amb", 9.78, tone, 0.02, 0.0)
add("sfx", 10.08, tink, 0.22, 0.25)  # something small settles
add("sfx", 11.2, pitched(tink, 0.8), 0.12, -0.2)
for at, level in ((11.25, 0.3), (11.625, 0.42)):  # two heartbeats before the street answers
    kick(at, level, 0.3, 70, 40)

# ================================================================== 12-15 s  Collectors
# No beat: the car, three doors as one, shoes and glove become the rhythm over a rising floor.
arrival = src("car_arrival")
t = clock(1.0)
add("sfx", 11.9, faded(highpass(arrival[int(4.0 * RATE):int(5.0 * RATE)], 60), 0.25, 0.25), 2.2, np.linspace(0.85, -0.1, len(t)))
tires = src("tires")
add("sfx", 12.34, cut(tires, 1.55, 0.42, 0.01, 0.12), 0.8, np.linspace(0.5, -0.1, int(0.42 * RATE)))
add("amb", 12.0, faded(highpass(street[int(3.4 * RATE):int(6.9 * RATE)], 200), 0.2, 0.8), 0.3, 0.0)
add("sfx", 12.78, pitched(kenney("impactSoft_heavy_000.ogg"), 0.8), 0.3, 0.0)
doors = events(src("car_door"), 0.6, 3)
for k, pan in enumerate((-0.6, 0.0, 0.6)):
    add("sfx", 13.1 + k * 0.006, doors[k], 1.1, pan)
kick(13.1, 0.75, 0.5, 110, 40)
sub(13.1, "F1", 4, 0.6)
march = events(src("marching"), 0.3, 6)
for n, at in enumerate((13.55, 13.85)):
    for k, pan in enumerate((-0.5, 0.0, 0.5)):
        add("sfx", at + k * 0.004, march[(n * 3 + k) % len(march)], 0.95, pan)
    kick(at, 0.5, 0.3, 85, 42)
t = clock(0.26)
creak = np.sin(2 * np.pi * np.cumsum(260 + 420 * t / 0.26) / RATE) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 70 * t))) + bandpass(noise(len(t)), 1200, 2400) * 0.5
add("sfx", 14.2, creak * faded(np.ones(len(t)), 0.02, 0.05), 0.3, 0.1)
add("sfx", 14.46, lead_in(src("loading")), 0.9, 0.1)  # the glove snaps tight
kick(14.46, 0.5, 0.3, 85, 42)
# The pulse tightens: door, shoe, shoe, glove, then faster and faster into the lid.
pulse = (14.75, 14.98, 15.2, 15.38, 15.54, 15.66, 15.76, 15.84, 15.9, 15.95)
for k, at in enumerate(pulse):
    level = 0.3 + 0.07 * k
    kick(at, level, 0.22, 80, 43)
    add("sfx", at, march[k % len(march)][:int(0.15 * RATE)], level * 0.9, 0.5 * (-1) ** k)
    hat(at, 0.6 + 0.1 * k, which=k, pan=-0.5 * (-1) ** k)
t = clock(4.0)
u = t / 4.0
drone = np.zeros(len(t))
for freq, level in ((43.65, 0.45), (87.31, 0.8), (92.5, 0.45), (130.8, 0.4), (174.6, 0.25)):  # F with a minor second grinding against it
    drone += signal.sawtooth(2 * np.pi * freq * t + rng.uniform(0, 6.28)) * level
moving = np.zeros(len(t))
for k, cutoff in enumerate((220, 450, 900, 2000)):  # the filter opens as they come closer
    moving += lowpass(drone, cutoff) * np.clip(u * 4 - k + 0.6, 0, 1) / (k + 1)
add("music", 12.0, moving * u ** 1.5 * np.clip((4.0 - t) / 0.008, 0, 1), 0.34, 0.0)
air = highpass(noise(len(t)), 2500) * u ** 4
add("music", 12.0, air * np.clip((4.0 - t) / 0.008, 0, 1), 0.16, np.linspace(-0.6, 0.6, len(t)))
reverse_swell(SLAM_AT, src("gong"), 3.2, 0.5, curve=2.6)
t = clock(0.5)
low_stab = sum(signal.square(2 * np.pi * f * t) for f in (55, 55.7, 110.4)) * np.exp(-t / 0.16)
add("music", 15.0, lowpass(low_stab, 900), 0.16, 0.0)
add("hits", 15.0, faded(pitched(TOM_LOW, 0.7)[:int(0.8 * RATE)], 0.001, 0.3), 0.5, 0.0)
for k in range(12):  # snare roll into the slam
    snare(15.62 + k * 0.03125, 0.15 + 0.075 * k, which=k, clap=False, pan=-0.4 + 0.07 * k)

# ================================================================== 15-18 s  Title drop
# Lid slam, a held breath, then the title hits and the beat signs off.
add("hits", SLAM_AT, src("explosion_a"), 1.0, 0.0)
add("hits", SLAM_AT, METAL_HEAVY, 0.9, 0.0)
add("hits", SLAM_AT, pitched(PUNCH, 0.55), 0.6, 0.0)
add("sfx", SLAM_AT, pitched(case[1], 0.7), 0.7, 0.0)
kick(SLAM_AT, 1.2, 0.3, 220, 40)
thunder = src("thunder")
add("hits", TITLE_AT, faded(src("gong_hard")[:int(2.3 * RATE)], 0.0005, 1.0), 0.55, 0.0)
add("hits", TITLE_AT, faded(src("explosion_far")[:int(2.2 * RATE)], 0.0005, 0.8), 0.8, 0.0)
add("hits", TITLE_AT, faded(lowpass(thunder[int(1.0 * RATE):int(3.2 * RATE)], 500), 0.002, 1.0), 0.6, 0.0)
add("hits", TITLE_AT, pitched(METAL_HEAVY, 0.8), 0.45, -0.2)
crash(TITLE_AT, 1.2, 1, 2.2)
kick(TITLE_AT, 1.25, 0.5, 220, 38)
sub(TITLE_AT, "F2", 7, 1.3, "F1", 0.0)
# Sign-off bar from the title hit: kick, snare, double kick, and a scratch into the last hit.
tag = TITLE_AT
for s in range(2, 16):
    if s not in (13, 14, 15):
        hat(tag + s * STEP, 0.9 if s % 2 == 0 else 0.5, which=s % 2)
snare(tag + 8 * STEP, 1.0)
kick(tag + 10 * STEP, 0.95)
kick(tag + 11 * STEP, 0.9)
sub(tag + 10 * STEP, "Ab1", 3, 0.9, "F1")
stab(tag + 3 * STEP, 0.9, cutoff=2000)
scratch(tag + 13 * STEP, 1, 1.0, length=3 * STEP - 0.01)
end = tag + 16 * STEP  # 17.6 s
kick(end, 1.1, 0.5, 200, 38)
snare(end, 0.8, which=1)
sub(end, "F1", 6, 1.1)
stab(end, 0.8, cutoff=1800)
crash(end, 0.6, 0, 0.8)

# ================================================================== mix
music = STEMS["kick"] + STEMS["bass"] + room(STEMS["drums"], 0.6, 0.12, 500, 9000) + room(STEMS["music"], 1.1, 0.25, 400, 7000)
t = np.arange(N) / RATE

# 0-3 s: the beat is heard through a small radio that grows until the drop at 3.0.
radio_end = int(3.0 * RATE)
mono = music[:radio_end].mean(axis=1)
small = drive(bandpass(mono, 420, 2600, 3) * 3.0, 1.6)
crackle_bed = np.resize(highpass(src("vinyl_crackle"), 800), radio_end) * 0.35
radio_gain = np.clip((t[:radio_end] - 0.75) / 0.5, 0, 1) * (0.3 + 0.7 * (t[:radio_end] / 3.0) ** 1.5)
radio = (small + crackle_bed) * radio_gain * 0.42
music[:radio_end, 0] = radio * 0.85
music[:radio_end, 1] = radio * 1.0

# 6.0-7.5 s: sunk under the floor (only the low end survives).
a, b = int(6.0 * RATE), int(7.5 * RATE)
music[a:b] = lowpass(music[a - 2400:b], 420)[2400:]

# 9.75 s: the cut. A 90 ms tape stop, then nothing.
a = int(MUSIC_CUT * RATE)
stop = int(0.09 * RATE)
u = np.linspace(0, 1, stop)
position = a - stop + np.cumsum(1 - u * 0.95)  # replay the last 90 ms slowing to a halt
for channel in range(2):
    music[a:a + stop, channel] = np.interp(position, np.arange(N), music[:, channel]) * (1 - u) ** 1.5
quiet_until = int(12.0 * RATE)
music[a + stop:quiet_until] = 0.0

sfx = room(STEMS["sfx"], 0.7, 0.1, 300, 8000)
# The latch echo and the settling brass ring in an empty room.
a, b = int(9.4 * RATE), int(12.0 * RATE)
sfx[a:b] = room(STEMS["sfx"][a:b], 1.6, 0.22, 300, 6000)
hits = room(STEMS["hits"], 2.2, 0.3, 120, 5000)
amb = STEMS["amb"]

# Kick-keyed ducking keeps the low end punching through the ambience and the hook.
key = np.abs(STEMS["kick"]).max(axis=1)
key = signal.sosfilt(sos("low", 18, 2), key)
duck = 1.0 - 0.3 * np.clip(key / max(key.max(), 1e-9) * 2.0, 0, 1)
amb = amb * duck[:, None]

mix = music * 1.0 + sfx * 0.9 + hits * 0.85 + amb * 0.9
mix = highpass(mix, 28, 2)

# The 0.1 s freeze: pull everything down between the slam transient and the title.
gate = np.ones(N)
a, b, c = int(16.035 * RATE), int(16.095 * RATE), int(TITLE_AT * RATE)
gate[a:b] = np.linspace(1.0, 0.06, b - a)
gate[b:c] = np.linspace(0.06, 1.0, c - b)
mix *= gate[:, None]
tail = int(0.5 * RATE)
mix[-tail:] *= (np.linspace(1, 0, tail) ** 1.5)[:, None]

# Master: slow leveller so the quiet shot stays quiet, then a soft clipper for weight.
level = np.sqrt(signal.sosfilt(sos("low", 4, 2), np.mean(mix ** 2, axis=1)).clip(1e-9))
reference = np.percentile(level[int(3.0 * RATE):int(6.0 * RATE)], 70)
mix = mix / reference * 0.2
out = drive(mix, 1.35) * 0.94
peak = float(np.max(np.abs(out)))

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
    "tempo": {"bpm": 160, "feel": "half-time", "bar_seconds": BAR, "bars_per_shot": 2},
    "music": {"radio_in": [0.75, 3.0], "drop": 3.0, "sunk": [6.0, 7.5], "held_breath": [7.5, 8.0], "back_in": 8.25,
              "cut": MUSIC_CUT, "sign_off": [TITLE_AT, 17.6], "menu_track_returns": 17.0},
    "cues": [
        [0.0, "tram pass, street bed, radio tuning"], [0.75, "beat through the radio"], [3.0, "drop: full beat, crash"],
        [3.19, "ratchet run"], [3.56, "ratchet run"], [3.84, "impact wrench"], [4.125, "speaker static"], [4.5, "scratch"],
        [5.3, "straw"], [5.625, "scratch fill"], [6.56, "giant sole"], [6.98, "second step"], [7.5, "snare roll, riser"],
        [8.0, "case slam + sub drop"], [8.25, "beat back in"], [9.15, "latch 1"], [9.45, "latch 2"],
        [9.75, "tape stop, tubes only"], [10.08, "brass settles"], [11.25, "heartbeat"], [11.625, "heartbeat"],
        [11.9, "car in"], [12.34, "brake"], [13.1, "three doors"], [13.55, "shoes"], [13.85, "shoes"], [14.2, "glove"],
        [14.46, "glove snap"], [14.75, "pulse tightens, drone rises"], [15.0, "low stab"], [15.62, "snare roll"],
        [16.0, "lid slam"], [16.035, "held breath"], [16.1, "title hit"], [17.6, "sign-off hit"]],
    "sources": ["synthesis (seed 20261112)", "godot/audio/open Kenney CC0 impacts",
                "references/story-opening-audio BigSoundBank CC0 excerpts (provenance.json)"],
    "sha256": hashlib.sha256(pcm.tobytes()).hexdigest(),
}
(OUT / "cues.json").write_text(json.dumps(cues, indent=2) + "\n")
print(json.dumps({"bytes": (OUT / "score.wav").stat().st_size, "peak": peak, "sha256": cues["sha256"]}))
