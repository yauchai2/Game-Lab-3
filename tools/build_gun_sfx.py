#!/usr/bin/env python3
"""Black Suit pistol SFX (procedural, original; no external samples).

Builds only gun_aim_0, gun_shot_0, gun_hit_0, gun_ricochet_0 into godot/audio/sfx/ so the rest of the
combat SFX set (real recordings) is untouched. Reuses the synth helpers of build_combat_sfx.py.
Needs NumPy + SciPy + ffmpeg/libvorbis. Run: python3 tools/build_gun_sfx.py
"""
import subprocess, sys, pathlib
import numpy as np
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import build_combat_sfx as syn

SR = syn.SR
OUT = syn.OUT

def build():
    S = {}
    # Telegraph: draw/rack clicks plus a quiet rising electric whine (reads as "charging", no bells or blades).
    n = int(.55 * SR); t = np.linspace(0, 1, n)
    whine = syn.sweep(n, 520, 2100, 0.01) * (0.15 + 0.85 * t ** 2) * np.minimum(1, t * 25) * np.where(t > .94, (1 - t) / .06, 1)
    base = np.zeros(n)
    for at, g in ((0.0, 1.2), (.17, 1.0), (.50, 1.4)):
        m = int(.06 * SR)
        c = syn.sat(syn.mix(m, (1, syn.click(m, g)), (.8, syn.band(syn.noise(m), 2500, 8500) * syn.env(m, .0002, .014)),
                            (.9, syn.sweep(m, 280, 110, 40) * syn.env(m, .0004, .022))), 1.8)
        i = int(at * SR); base[i:i + m] += c[:n - i]
    S["gun_aim_0"] = syn.sat(base + 0.32 * whine, 1.5)
    # Shot: sharp crack, broadband blast, low thump, short room tail.
    n = int(.5 * SR)
    shot = syn.mix(n, (1.2, syn.click(n, 2.0)), (1.1, syn.band(syn.noise(n), 1200, 12000) * syn.env(n, .0002, .05)),
                   (1.0, syn.filt(syn.noise(n), "low", 900) * syn.env(n, .0004, .09)),
                   (1.5, syn.sweep(n, 210, 48, 14) * syn.env(n, .0006, .12)))
    S["gun_shot_0"] = syn.tail(syn.sat(shot, 3.0), .3, .16)
    # Bullet hitting the hero: tight thwack, sharper and shorter than a punch.
    S["gun_hit_0"] = syn.tail(syn.hit(.22, 140, 55, 5200, 2200, crack_g=2.6, body_g=.6, drive=2.8), .2, .08)
    # Ricochet/block: fast descending ping plus gritty scrape.
    n = int(.45 * SR)
    ping = syn.metal(.45, [(2300, 1, 1), (3400, .6, .8), (5200, .4, .6)], .10)
    S["gun_ricochet_0"] = syn.sat(syn.mix(n, (1, syn.click(n, 1.4)), (.9, ping),
                                          (.7, syn.band(syn.noise(n), 3500, 11000) * syn.env(n, .0003, .05)),
                                          (.6, syn.sweep(n, 700, 250, 30) * syn.env(n, .0004, .04))), 2.0)
    return S

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, x in build().items():
        st = syn.finish(x, 0.8 if name != "gun_aim_0" else 0.7)
        raw = (st * 32767).astype("<i2").tobytes()
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                        "-c:a", "libvorbis", "-q:a", "6", "-map_metadata", "-1", str(OUT / f"{name}.ogg")], input=raw, check=True)
        print(name, f"{len(x)/SR:.2f}s")

if __name__ == "__main__":
    sys.exit(main())
