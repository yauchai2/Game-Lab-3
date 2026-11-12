#!/usr/bin/env python3
"""Original combat SFX for Afterhours (procedural, no external samples).

Replaces the muffled Kenney punches (spectral centroid ~100 Hz, 20-40 ms attack, nothing above 6 kHz)
with transient-first hits: a 1-2 ms click, a 2-6 kHz crack, a mid slap and a short low body.
Needs Python + NumPy + SciPy and ffmpeg/libvorbis. Output: godot/audio/sfx/*.ogg (44.1 kHz stereo).
Run: python3 tools/build_combat_sfx.py
"""
import subprocess, sys, pathlib, numpy as np
from scipy import signal

SR = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "godot" / "audio" / "sfx"
rng = np.random.default_rng(20261112)

def t_(d): return np.arange(int(d * SR)) / SR
def env(n, attack=0.0005, decay=0.05, curve=1.0):
    t = np.arange(n) / SR
    a = np.minimum(1.0, t / max(attack, 1e-5))
    return a * np.exp(-t / decay) ** curve
def noise(n): return rng.standard_normal(n)
def filt(x, kind, f, order=4):
    sos = signal.butter(order, f, kind, fs=SR, output="sos")
    return signal.sosfilt(sos, x)
def band(x, lo, hi): return filt(filt(x, "high", lo), "low", hi)
def sweep(n, f0, f1, curve=3.0):
    t = np.linspace(0, 1, n)
    f = f1 + (f0 - f1) * np.exp(-curve * t)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)
def pad(x, n):
    y = np.zeros(n); y[:min(n, len(x))] = x[:n]; return y
def mix(n, *layers):
    y = np.zeros(n)
    for g, x in layers: y += g * pad(x, n)
    return y
def click(n, g=1.0):
    x = np.zeros(n); x[0] = g; x[1] = -g * 0.6; return filt(x, "high", 1200, 2)
def sat(x, drive): return np.tanh(x * drive) / np.tanh(drive)
def finish(x, peak=0.89, fade=0.004):
    f = int(fade * SR); x = x.copy(); x[-f:] *= np.linspace(1, 0, f)
    x = filt(x, 'high', 38, 2); x = x / (np.abs(x).max() + 1e-9) * peak
    # tiny pseudo-stereo: micro delay on right channel, keeps mono compatibility at the transient
    d = int(0.0006 * SR); r = np.concatenate([np.zeros(d), x[:-d]])
    return np.stack([x, 0.8 * x + 0.2 * r], axis=1)
def tail(x, wet=0.18, t=0.08):
    n = int(t * SR); ir = noise(n) * np.exp(-np.arange(n) / (n * 0.25)); ir[0] = 0
    ir = filt(ir, "low", 5000, 2)
    return x + wet * signal.fftconvolve(x, ir)[:len(x)] * 0.3

def hit(dur, body_hz, body_ms, crack_hz, slap_hz, crack_g=2.0, body_g=0.55, drive=2.2):
    n = int(dur * SR)
    crack = band(noise(n), crack_hz, 11000) * env(n, 0.0002, 0.012) * crack_g
    slap = band(noise(n), slap_hz * 0.6, slap_hz * 1.8) * env(n, 0.0003, 0.035)
    body = sweep(n, body_hz * 2.4, body_hz, 55.0) * env(n, 0.0004, body_ms / 1000) * body_g
    thud = filt(noise(n), "low", 400) * env(n, 0.0005, 0.05) * 0.8
    return sat(mix(n, (1.0, click(n, 1.4)), (1.0, crack), (1.5, slap), (1.1, body), (0.35, thud)), drive)

def whoosh(dur, f0, f1, peak_at=0.4, q=1.8, g=1.0):
    n = int(dur * SR); x = noise(n); out = np.zeros(n); blocks = 24
    for i in range(blocks):
        a, b = int(i / blocks * n), int((i + 1) / blocks * n)
        u = (i + .5) / blocks; f = f0 * (f1 / f0) ** u
        out[a:b] = signal.sosfilt(signal.butter(2, [f / q, min(f * q, 20000)], "band", fs=SR, output="sos"), x[a:b])
    t = np.linspace(0, 1, n)
    e = np.where(t < peak_at, (t / peak_at) ** 1.5, ((1 - t) / (1 - peak_at)) ** 1.2)
    return out * e * g

def metal(dur, partials, decay, g=1.0):
    n = int(dur * SR); t = t_(dur)[:n]
    y = sum(a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t / (decay * s)) for f, a, s in partials)
    return y * g

def build():
    S = {}
    # ---- impacts ----
    S["hit_0"] = tail(hit(.28, 95, 90, 3200, 1400))
    S["hit_1"] = tail(hit(.28, 110, 80, 4200, 1800, crack_g=2.4))
    S["hit_2"] = tail(hit(.30, 85, 100, 2600, 1100, body_g=0.7))
    S["heavy_0"] = tail(hit(.5, 62, 170, 2400, 900, body_g=1.0, crack_g=2.4, drive=3.0) + 0.5 * pad(sweep(int(.5*SR), 90, 38, 8) * env(int(.5*SR), .001, .22), int(.5*SR)), .25, .14)
    S["heavy_1"] = tail(hit(.55, 55, 190, 3000, 1000, crack_g=2.6, body_g=1.1, drive=3.2), .25, .16)
    # ---- defence ----
    n = int(.4 * SR)
    S["block_0"] = sat(mix(n, (1, click(n, 1.5)), (.8, band(noise(n), 2500, 9000) * env(n, .0002, .02)),
                       (1, metal(.4, [(1180, 1, 1), (2650, .7, .8), (4130, .5, .6), (5900, .3, .4)], .09)),
                       (.8, sweep(n, 330, 130, 40) * env(n, .0004, .05))), 2.0)
    n = int(.9 * SR)
    S["parry_0"] = sat(mix(n, (1, click(n, 1.5)), (.7, band(noise(n), 4000, 12000) * env(n, .0002, .03)),
                       (1, metal(.9, [(1760, 1, 1.4), (2349, .9, 1.1), (3520, .6, .9), (5287, .4, .6), (7040, .2, .4)], .22)),
                       (.7, sweep(n, 600, 200, 30) * env(n, .0004, .06))), 1.8)
    n = int(.6 * SR); gl = np.zeros(n)
    for k in range(18):
        p = int(rng.uniform(0, .18) * SR); L = n - p
        gl[p:] += band(noise(L), 3000, 12000) * env(L, .0002, rng.uniform(.01, .04)) * rng.uniform(.3, 1)
    S["guard_break_0"] = tail(sat(mix(n, (1, click(n, 1.6)), (1, gl),
                         (.9, metal(.6, [(1500, 1, 1), (2230, .8, .8), (3700, .6, .6), (5100, .4, .5)], .1)),
                         (1.2, sweep(n, 260, 60, 30) * env(n, .0004, .16))), 2.2), .3, .12)
    # ---- movement ----
    S["swing_0"] = whoosh(.2, 700, 4200, .45, 2.0, 1.0) + 0.0
    S["swing_1"] = whoosh(.22, 600, 3600, .4, 2.0, 1.0)
    S["dash_0"] = whoosh(.28, 350, 2400, .35, 1.6, 1.0)
    n = int(.14 * SR)
    for i, f in enumerate((900, 1200)):
        S[f"step_{i}"] = sat(mix(n, (1, click(n, .8)), (.9, band(noise(n), 250, f) * env(n, .0005, .025)),
                                 (1.0, sweep(n, 160, 70, 40) * env(n, .0005, .04))), 1.8)
    n = int(.22 * SR)
    S["land_0"] = sat(mix(n, (1, click(n, 1.0)), (1, band(noise(n), 200, 1800) * env(n, .0005, .04)),
                          (1.2, sweep(n, 140, 52, 40) * env(n, .0005, .08))), 2.0)
    S["jump_0"] = mix(int(.2 * SR), (1, whoosh(.2, 500, 1800, .3, 1.5, .6)), (.8, pad(sweep(int(.06*SR), 180, 90, 30) * env(int(.06*SR), .0005, .03), int(.2*SR))))
    # ---- abilities ----
    n = int(.35 * SR)
    S["release_0"] = tail(sat(mix(n, (1, click(n, 1.2)), (1, band(noise(n), 1500, 9000) * env(n, .0003, .05)),
                              (1.2, metal(.35, [(900, 1, 1), (1350, .8, .9), (2700, .5, .7)], .08)),
                              (1.0, sweep(n, 260, 90, 25) * env(n, .0005, .07))), 2.0), .2, .1)
    n = int(1.3 * SR)
    ko = mix(n, (1, click(n, 1.8)), (1.0, band(noise(n), 1200, 12000) * env(n, .0003, .22)),
             (1.4, sweep(n, 160, 34, 6) * env(n, .001, .42)),
             (.9, metal(1.3, [(310, 1, 1), (770, .7, .9), (1540, .5, .7), (2900, .35, .5)], .35)))
    S["ko_0"] = tail(sat(ko, 2.6), .35, .3)
    n = int(.5 * SR); t = np.linspace(0, 1, n)
    ch = sum(a * sweep(n, f * .55, f, -3.0 if False else 0.01) for a, f in ((1, 140), (.5, 280), (.3, 420)))
    ch = ch * (0.3 + 0.7 * t) * np.minimum(1, t * 30) * np.where(t > .92, (1 - t) / .08, 1)
    S["charge_0"] = sat(ch + 0.3 * band(noise(n), 1500, 8000) * t ** 2 * .5, 1.8)
    n = int(.6 * SR)
    S["slam_0"] = tail(sat(mix(n, (1, click(n, 1.6)), (1, band(noise(n), 1500, 10000) * env(n, .0003, .03)),
                          (1.5, sweep(n, 150, 36, 18) * env(n, .001, .2)), (.7, filt(noise(n), "low", 600) * env(n, .001, .12))), 3.0), .3, .15)
    n = int(.3 * SR)
    S["launch_0"] = sat(mix(n, (1, click(n, 1.2)), (1, whoosh(.3, 600, 5000, .6, 1.8, 1.1)),
                            (1, pad(sweep(int(.09*SR), 220, 80, 40) * env(int(.09*SR), .0005, .05), n))), 2.0)
    S["chase_0"] = whoosh(.22, 900, 6000, .55, 1.8, 1.0) * 1.0
    n = int(.3 * SR); t = t_(.3)[:n]
    rl = sum(a * np.sin(2 * np.pi * f * t) * np.exp(-(t - d).clip(0) / .09) * (t >= d) for a, f, d in ((1, 880, 0), (.8, 1318, .05), (.7, 1760, .1)))
    S["rally_0"] = sat(rl + 0.5 * pad(click(n, 1), n), 1.6)
    n = int(.4 * SR)
    S["sub_0"] = sat(sweep(n, 95, 28, 9) * env(n, .003, .18) * 1.2, 1.8)
    # ---- UI (menus, buttons): short, dry, arcade-snappy; no musical pitch clash with the music decks
    n = int(.06 * SR); S["ui_move_0"] = sat(mix(n, (1, click(n, .8)), (.6, sweep(n, 2600, 1800, 30) * env(n, .0004, .016)), (.3, band(noise(n), 3000, 9000) * env(n, .0003, .01))), 1.5)
    n = int(.2 * SR); S["ui_confirm_0"] = sat(mix(n, (1, click(n, 1.2)), (.7, sweep(n, 520, 1250, 14) * env(n, .001, .05)), (.5, sweep(n, 1040, 2500, 14) * env(n, .001, .03)),
                                                 (.8, sweep(n, 190, 85, 40) * env(n, .0005, .05)), (.4, band(noise(n), 1500, 8000) * env(n, .0003, .02))), 2.0)
    n = int(.16 * SR); S["ui_back_0"] = sat(mix(n, (1, click(n, 1.0)), (.7, sweep(n, 1000, 420, 12) * env(n, .001, .045)), (.6, sweep(n, 160, 80, 40) * env(n, .0005, .05))), 1.8)
    n = int(.08 * SR); S["ui_toggle_0"] = sat(mix(n, (1, click(n, 1.2)), (.5, sweep(n, 1600, 1100, 40) * env(n, .0005, .02)), (.5, sweep(n, 220, 110, 40) * env(n, .0005, .03))), 1.6)
    n = int(.25 * SR); S["ui_pause_0"] = sat(mix(n, (1, click(n, .9)), (1, sweep(n, 220, 70, 20) * env(n, .001, .07)), (.4, band(noise(n), 400, 3000) * env(n, .001, .05))), 1.8)
    return S

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, x in build().items():
        peak = 0.5 if name.startswith("ui_") else (0.8 if not name.startswith(("sub", "step", "jump", "swing", "dash", "chase", "charge")) else 0.7)
        st = finish(x, peak)
        raw = (st * 32767).astype("<i2").tobytes()
        dst = OUT / f"{name}.ogg"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                        "-c:a", "libvorbis", "-q:a", "6", "-map_metadata", "-1", str(dst)], input=raw, check=True)
        print(name, f"{len(x)/SR:.2f}s")

if __name__ == "__main__":
    sys.exit(main())
