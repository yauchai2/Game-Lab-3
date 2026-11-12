#!/usr/bin/env python3
"""Combat SFX built from real CC0 recordings (BigSoundBank, Joseph Sardin / LaSonotheque) plus a synthetic low layer.

Downloads the source OGGs into a cache dir (NOT committed), cuts the strongest onsets (bare-handed fight: no blade/metal/bell sources), layers them, and writes
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

def mid(g=1.0, pid=2461):
    """150 Hz-3.5 kHz body of a real punch: the reference footage has much more energy here than a bass-heavy impact."""
    return g * norm(syn.band(hit_of(pid, 0, .35), 150, 3500), .9)

def layer(n, *parts):
    y = np.zeros(n)
    for g, x in parts: y += g * syn.pad(x, n)
    return y

def build():
    S = {}
    # ---- punches: real recordings + thump
    for k, (pid, f0) in enumerate([(2460, 150), (2461, 120), (2468, 140), (2463, 110), (2464, 130)]):
        n = int(.4 * SR); r = norm(punchy(hit_of(pid, 0, .4)), .9)
        S[f"hit_{k}"] = syn.tail(syn.sat(layer(n, (1.0, r), (.25, low(n, 190, 110, 120)), (.55, mid(1.0, [2461, 2468, 2463, 2464, 2460][k])), (.5, syn.click(n, 1.0))), 1.9), .15, .06)
    # heavy: punch + real explosion body + sub
    for k, (pid, ex, f0) in enumerate([(2465, 1808, 70), (2466, 1807, 62), (2459, 1806, 56)]):
        n = int(.6 * SR); r = norm(punchy(hit_of(pid, 0, .45), g=1.6), .9); e = norm(syn.filt(hit_of(ex, 0, .5, "strong"), "low", 4000), .9)
        S[f"heavy_{k}"] = syn.tail(syn.sat(layer(n, (1.5, r), (.28, syn.filt(e, 'high', 70, 2)), (.25, low(n, f0 * 2.4, f0, 160)), (.6, syn.band(r, 1800, 9000)), (1.6, mid(1.0, 2461 if k != 1 else 2468)), (.5, syn.click(n, 1.0))), 2.6), .22, .12)
    # ---- defence: bare-handed fight, so forearm/slap/body sounds only (no blades, anvils, bells)
    for k in range(2):
        x = fetch(597); st = onsets(x, 4, .4)[k]; n = int(.4 * SR)
        S[f"block_{k}"] = syn.sat(layer(n, (1.0, norm(cut(x, st, .3, .08), .9)), (.6, norm(punchy(hit_of(2467, 0, .3), 3000), .9)),
                         (.7, norm(cut(fetch(2454), onsets(fetch(2454), 1)[0], .25, .08), .9)), (.12, low(n, 220, 90, 60)), (.8, mid(1.0, 2463))), 1.9)
    n = int(.45 * SR); x = fetch(1152); st = onsets(x, 3, .4)
    S["parry_0"] = syn.sat(layer(n, (1.0, norm(speed(cut(x, st[0], .3, .08), 1.12), .9)), (.9, norm(cut(fetch(597), onsets(fetch(597), 4, .4)[2], .3, .08), .9)),
                         (.6, syn.click(n, 1.5)), (.5, norm(punchy(hit_of(2460, 0, .3), 4500, 1.6), .9))), 1.8)
    n = int(.8 * SR)
    S["guard_break_0"] = syn.tail(syn.sat(layer(n, (1.2, norm(punchy(hit_of(2465, 0, .4), g=1.6), .9)), (.7, norm(syn.filt(hit_of(1808, 0, .4), "low", 4000), .9)),
                         (.8, norm(cut(fetch(2455), onsets(fetch(2455), 1)[0], .5, .15), .9)), (.8, norm(cut(fetch(597), onsets(fetch(597), 4, .4)[0], .3, .08), .9)),
                         (.4, low(n, 240, 55, 170)), (1.0, mid(1.0, 2466))), 2.4), .25, .1)
    # ---- movement: real whooshes, brightened & shortened
    for k, (wid, r, dur) in enumerate([(1797, 1.0, .3), (1801, 1.25, .3), (1796, 1.6, .26)]):
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
                    (.8, norm(punchy(hit_of(2465, 0, .4)), .9)), (.8, low(n, 150, 36, 220)), (.9, mid(1.0, 2464))), 2.8), .25, .12)
    n = int(1.4 * SR)
    S["ko_0"] = syn.tail(syn.sat(layer(n, (1.0, norm(syn.filt(hit_of(1023, 0, 1.2, "strong"), "low", 6000), .9)), (.9, norm(cut(fetch(2452), onsets(fetch(2452), 1)[0], .9, .3), .9)),
                  (.8, norm(cut(fetch(1806), onsets(fetch(1806), 1)[0], .6, .2), .9)), (.8, norm(punchy(hit_of(2465, 0, .4)), .9)), (1.2, low(n, 130, 32, 380))), 2.4), .3, .25)
    # ---- violent, exaggerated finishers: stacked real impacts + explosion body + long sub drop + shockwave tail
    def boom(n, f0, f1, ms, g=1.0): return g * syn.sweep(n, f0, f1, 7.0) * syn.env(n, .002, ms / 1000)
    def shock(n, g=1.0):   # filtered noise burst that darkens fast: the "air pressure" of a big hit
        x = syn.noise(n) * syn.env(n, .0005, .09); return g * syn.filt(x, "low", 3500, 2)
    def stack(pids, gap=.022, dur=.45, g=1.6):
        out = np.zeros(int(.7 * SR))
        for i, pid in enumerate(pids):
            r = norm(punchy(hit_of(pid, 0, dur), g=g), .9); o = int(i * gap * SR); out[o:o + len(r)] += r[:len(out) - o]
        return out
    for k, (pids, ex, f0, pitch) in enumerate([((2465, 2466), 1808, 62, 1.0), ((2466, 2459, 2465), 1807, 54, .9), ((2459, 2465), 1806, 48, .85)]):
        n = int(.95 * SR); e = norm(syn.filt(speed(hit_of(ex, 0, .5), pitch), "high", 50, 2), .9)
        S[f"heavy_{k}"] = syn.tail(syn.sat(layer(n, (2.1, stack(pids)), (.55, e), (1.1, mid(1.0, 2461)), (.7, shock(n)), (.7, boom(n, f0 * 3, f0, 300)),
                                               (.5, syn.click(n, 1.6))), 3.0), .32, .2)
    n = int(1.2 * SR)
    for k, (ex, f0) in enumerate([(1806, 40), (1807, 46)]):
        S[f"slam_{k}"] = syn.tail(syn.sat(layer(n, (1.0, norm(syn.filt(hit_of(ex, 0, .8), "high", 40, 2), .9)), (.9, norm(cut(fetch(2452), onsets(fetch(2452), 1)[0], .6, .2), .9)),
                         (1.8, stack((2465, 2466, 2464), .03)), (.9, boom(n, 170, f0, 420)), (.8, shock(n)), (.9, mid(1.0, 2464))), 3.2), .38, .3)
    n = int(.5 * SR)   # launcher / uppercut: crack, rising whoosh, hit
    wh = fetch(1795); wh = norm(speed(cut(wh, max(0, onsets(wh, 1)[0] - 2000), .4, .15), 1.5), .9)
    S["launch_0"] = syn.sat(layer(n, (1.4, norm(punchy(hit_of(2466, 0, .35), g=1.8), .9)), (.9, wh[::-1] * np.linspace(.2, 1, len(wh)) * 0 + wh), (.6, mid(1.0, 2461)), (.5, boom(n, 200, 70, 120))), 2.4)
    n = int(.9 * SR)   # special/overdrive release: explosion + reversed air-suck leading into the blast
    ex = norm(syn.filt(hit_of(1808, 0, .5), "high", 50, 2), .9); suck = norm(syn.filt(cut(fetch(1796), onsets(fetch(1796), 1)[0], .35, .1)[::-1], "high", 400), .8)
    pre = int(.2 * SR); y = np.zeros(n + pre); y[:len(suck)] += .8 * suck
    y[pre:pre + n] += layer(n, (1.0, ex), (1.2, stack((2465, 2468), .02)), (1.1, boom(n, 200, 44, 330)), (.7, shock(n)), (.6, syn.click(n, 1.5)))
    S["release_0"] = syn.tail(syn.sat(y, 2.8), .3, .25)
    n = int(.7 * SR)   # charge: crackling energy swell (electric arc) + rising tone + sub rise
    arc = fetch(134); arc = norm(syn.band(cut(arc, onsets(arc, 1)[0], .7, .1), 800, 9000), .9) * np.linspace(.15, 1, n)
    ch = sum(a * syn.sweep(n, f * .5, f, .01) for a, f in ((1, 110), (.6, 220), (.4, 330))) * np.linspace(.15, 1, n)
    S["charge_0"] = syn.sat(layer(n, (.8, arc), (.9, ch), (.6, shock(n) * np.linspace(.1, 1, n))), 2.2)
    n = int(2.0 * SR)   # KO: three stacked blasts, body falls, long sub, rumble tail
    d = np.zeros(n)
    for o, ex, g in ((0, 1023, 1.0), (.09, 1806, .9), (.2, 1808, .8)):
        r = norm(syn.filt(hit_of(ex, 0, 1.0), "high", 40, 2), .9); i = int(o * SR); d[i:i + len(r)] += g * r[:n - i]
    S["ko_0"] = syn.tail(syn.sat(layer(n, (1.0, d), (2.0, stack((2465, 2466, 2459), .04)), (.9, norm(cut(fetch(2452), onsets(fetch(2452), 1)[0], 1.0, .3), .9)),
                  (.9, boom(n, 150, 30, 700)), (.8, shock(n))), 3.0), .4, .4)
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
