#!/usr/bin/env python3
"""Combat SFX built from real CC0 recordings (BigSoundBank, Joseph Sardin / LaSonotheque) plus a synthetic low layer.

Downloads the source OGGs into a cache dir (NOT committed), cuts the strongest onsets, layers them, and writes
godot/audio/sfx/*.ogg. Anything not built from a recording keeps the procedural version from build_combat_sfx.py.
Usage: python3 tools/build_real_sfx.py [cache_dir]      (needs numpy, scipy, ffmpeg, network to bigsoundbank.com)
Source/licence list: godot/audio/sfx/SOURCES.md (written by this script).
"""
import sys, subprocess, pathlib, numpy as np
from scipy import signal
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_combat_sfx as syn

SR = syn.SR; OUT = syn.OUT
CACHE = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/bsb_cache"); CACHE.mkdir(parents=True, exist_ok=True)
TITLES = {}

def fetch(i):
    p = CACHE / f"{i}.ogg"
    if not p.exists() or p.stat().st_size < 500:
        subprocess.run(["curl", "-sSL", "-m", "60", "-o", str(p), f"https://bigsoundbank.com/UPLOAD/ogg/{i}.ogg"], check=True)
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(p), "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)

def onsets(x, n=1, gap=0.25, thresh=0.2):
    """Start indices of the n strongest onsets (peak-sorted, separated by `gap` s)."""
    a = np.abs(x); sm = np.convolve(a, np.ones(int(.002 * SR)) / int(.002 * SR), "same")
    pk = []; order = np.argsort(-sm)
    for i in order:
        if sm[i] < thresh * sm.max(): break
        if all(abs(i - j) > gap * SR for j in pk): pk.append(i)
        if len(pk) >= n: break
    out = []
    for i in pk:   # walk back to where the hit starts rising
        j = i
        while j > 0 and sm[j] > 0.08 * sm[i] and i - j < .15 * SR: j -= 1
        out.append(max(0, j - int(.002 * SR)))
    return out

def cut(x, start, dur, fade=.02):
    seg = x[start:start + int(dur * SR)].copy(); seg = np.pad(seg, (0, max(0, int(dur * SR) - len(seg))))
    f = int(fade * SR); seg[-f:] *= np.linspace(1, 0, f); return seg

def hit_of(i, k=0, dur=.4, which="strong"):
    x = fetch(i); st = onsets(x, k + 1)[k]; return cut(x, st, dur)

def speed(x, r):  # r>1 faster / higher
    from fractions import Fraction
    fr = Fraction(r).limit_denominator(40); return signal.resample_poly(x, fr.denominator, fr.numerator)

def norm(x, peak=.9):
    return x / (np.abs(x).max() + 1e-9) * peak

def punchy(x, hi=2500, g=1.0):   # restore transient bite; real punches are soft-ish in the 2-6k range
    return x + g * 0.35 * syn.band(x, hi, 12000)

def low(n, f0, f1, ms, g=1.0):
    return g * syn.sweep(n, f0, f1, 45.0) * syn.env(n, .0004, ms / 1000)

def layer(n, *parts):
    y = np.zeros(n)
    for g, x in parts: y += g * syn.pad(x, n)
    return y

def build():
    S = {}
    # ---- punches: real recordings + thump
    for k, (pid, f0) in enumerate([(2460, 150), (2461, 120), (2468, 140), (2463, 110), (2464, 130)]):
        n = int(.4 * SR); r = norm(punchy(hit_of(pid, 0, .4)), .9)
        S[f"hit_{k}"] = syn.tail(syn.sat(layer(n, (1.0, r), (.2, low(n, f0 * 1.6, f0 * .6, 70)), (.5, syn.click(n, 1.0))), 1.9), .15, .06)
    # heavy: punch + real explosion body + sub
    for k, (pid, ex, f0) in enumerate([(2465, 1808, 70), (2466, 1807, 62), (2459, 1806, 56)]):
        n = int(.6 * SR); r = norm(punchy(hit_of(pid, 0, .45), g=1.6), .9); e = norm(syn.filt(hit_of(ex, 0, .5, "strong"), "low", 4000), .9)
        S[f"heavy_{k}"] = syn.tail(syn.sat(layer(n, (1.5, r), (.28, syn.filt(e, 'high', 70, 2)), (.25, low(n, f0 * 2.4, f0, 160)), (.6, syn.band(r, 1800, 9000)), (.5, syn.click(n, 1.0))), 2.6), .22, .12)
    # ---- defence
    for k, ai in enumerate((3589, 3590)):
        x = fetch(ai); st = onsets(x, 3, .5)[k]; n = int(.5 * SR)
        S[f"block_{k}"] = syn.sat(layer(n, (1.0, norm(cut(x, st, .45, .1), .9)), (.7, norm(punchy(hit_of(2467, 0, .3), 4000), .9)), (.6, low(n, 300, 120, 50))), 1.8)
    n = int(1.0 * SR); b = fetch(2531); st = onsets(b, 1)[0]
    S["parry_0"] = syn.sat(layer(n, (.9, norm(cut(fetch(129), onsets(fetch(129), 1)[0], .8, .3), .9)), (.9, norm(cut(b, st, 1.0, .35), .9)), (.5, syn.click(n, 1.4))), 1.6)
    n = int(.9 * SR)
    S["guard_break_0"] = syn.tail(syn.sat(layer(n, (1.0, norm(cut(fetch(148), onsets(fetch(148), 1)[0], .7, .25), .9)), (.7, norm(cut(fetch(387), onsets(fetch(387), 1)[0], .6, .2), .9)),
                         (.9, norm(punchy(hit_of(2465, 0, .4)), .9)), (.9, low(n, 260, 60, 160))), 2.0), .25, .1)
    # ---- movement: real whooshes, brightened & shortened
    for k, (wid, r, dur) in enumerate([(127, 1.15, .32), (128, 1.3, .3), (1796, 1.6, .26)]):
        x = fetch(wid); st = onsets(x, 1)[0]; seg = cut(x, max(0, st - int(.06 * SR)), dur * (r if r > 1 else 1) + .06, .06); seg = speed(seg, r)
        n = int(.3 * SR); seg = norm(seg + .4 * syn.band(seg, 1500, 9000), .85)
        S[f"swing_{k}"] = syn.pad(seg, n) * 1.0
    x = fetch(1795); n = int(.38 * SR); S["dash_0"] = norm(cut(x, max(0, onsets(x, 1)[0] - int(.1 * SR)), .38, .1), .85)
    x = fetch(1802); S["jump_0"] = norm(syn.pad(speed(cut(x, max(0, onsets(x, 1)[0] - 1000), .25, .08), 1.2), int(.22 * SR)), .6)
    fs = fetch(514); sts = onsets(fs, 2, .5, .3)
    for k in range(2):
        n = int(.2 * SR); S[f"step_{k}"] = syn.sat(layer(n, (1.0, norm(cut(fs, sts[k], .18, .05), .9)), (.15, low(n, 150, 80, 40))), 1.6)
    n = int(.4 * SR); S["land_0"] = syn.sat(layer(n, (1.0, norm(cut(fetch(2454), onsets(fetch(2454), 1)[0], .35, .1), .9)), (.6, norm(cut(fs, sts[0], .15, .05), .9)), (.4, low(n, 130, 55, 80))), 2.0)
    # ---- big hits
    n = int(.8 * SR); S["slam_0"] = syn.tail(syn.sat(layer(n, (1.0, norm(syn.filt(hit_of(1806, 0, .6), "low", 5000), .9)), (.8, norm(cut(fetch(2452), onsets(fetch(2452), 1)[0], .5, .15), .9)),
                    (.8, norm(punchy(hit_of(2465, 0, .4)), .9)), (1.0, low(n, 150, 36, 220))), 2.8), .25, .12)
    n = int(1.6 * SR); gong = fetch(1483); cym = fetch(2314)
    S["ko_0"] = syn.tail(syn.sat(layer(n, (1.0, norm(syn.filt(hit_of(1023, 0, 1.2, "strong"), "low", 6000), .9)), (.6, norm(cut(cym, onsets(cym, 1)[0], 1.1, .5), .9)),
                  (.5, norm(cut(gong, onsets(gong, 1)[0], 1.5, .6), .9)), (.7, norm(punchy(hit_of(2465, 0, .4)), .9)), (1.2, low(n, 130, 32, 380))), 2.4), .3, .25)
    return S

def main():
    syn.main()
    S = build()
    for name, x in S.items():
        peak = .8
        st = syn.finish(x, peak)
        raw = (st * 32767).astype("<i2").tobytes()
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-", "-c:a", "libvorbis", "-q:a", "6",
                        "-map_metadata", "-1", str(OUT / f"{name}.ogg")], input=raw, check=True)
        print("real", name, f"{len(x)/SR:.2f}s")

if __name__ == "__main__":
    main()
