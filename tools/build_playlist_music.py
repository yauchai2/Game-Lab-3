#!/usr/bin/env python3
"""Cut the game's music loops from the playlist mp3 Alan supplied ("High-Energy Hip Hop Breakbeat Playlist ... Jet Set Radio").

Usage: python3 tools/build_playlist_music.py "<playlist.mp3>"        (needs numpy, scipy, soundfile, ffmpeg)
The playlist is ~80 min: the first ~40 min repeat once, so only 0-2430 s is used. Tempo/grid/section analysis (16 s windows,
beat-grid fit at 0.01 BPM, per-bar mel similarity to find sections that repeat after N bars) produced the cut table below.
Each file = optional intro + a bar-aligned loop; Godot loops from `loop_offset` (intro length), so the intro plays only once.
Loop seam: 12 ms equal-power blend with the audio just before the loop start. Output: godot/audio/music/*.ogg + music.json.
"""
import sys, json, subprocess, pathlib, numpy as np, soundfile as sf
from scipy import signal

SR = 44100; SEAM = .012
OUT = pathlib.Path(__file__).resolve().parent.parent / "godot" / "audio" / "music"
# name: (bpm, loop_start_s, loop_bars, intro_start_s or None, intro_bars, role)
CUTS = {
    "menu":    (116.00, 39.375, 16, 0.06, 4, "main menu: track 1 build-up (4 bars, plays once) then its first full groove"),
    "fight_a": (130.01, 1989.916, 16, None, 0, "fight deck: 130 BPM track, strongest sustained section"),
    "fight_b": (131.51, 1912.055, 16, None, 0, "fight deck: 131.5 BPM track"),
    "fight_c": (112.99, 661.966, 16, None, 0, "fight deck: 113 BPM track, loudest stable section"),
    "result":  (110.01, 857.013, 16, None, 0, "result screen: steadier, lower-energy 110 BPM section"),
}

def region(src, t0, t1):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", f"{t0:.4f}", "-t", f"{t1 - t0:.4f}", "-i", src, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2).astype(np.float64)

def snap(x, t_rel, win=.04):
    """Snap t (seconds into x) to the strongest low-band rising edge within +-win s (the kick)."""
    lo = signal.sosfilt(signal.butter(4, 220, "low", fs=SR, output="sos"), x.mean(1))
    e = np.convolve(np.abs(lo), np.ones(int(.002 * SR)) / int(.002 * SR), "same"); d = np.gradient(e)
    a, b = int((t_rel - win) * SR), int((t_rel + win) * SR)
    return (a + int(np.argmax(d[a:b]))) / SR

def build_one(src, name, bpm, start, bars, istart, ibars):
    bar = 240 / bpm; M = 1.0
    seg0 = start - M
    x = region(src, seg0, start + bars * bar + M)
    s = snap(x, M)                                  # snapped loop start (s into x)
    a = int(round(s * SR)); n = int(round(bars * bar * SR)); k = int(SEAM * SR)
    loop = x[a:a + n].copy()
    fo = np.cos(np.linspace(0, np.pi / 2, k))[:, None]; fi = np.sin(np.linspace(0, np.pi / 2, k))[:, None]
    loop[-k:] = loop[-k:] * fo + x[a - k:a] * fi
    intro = np.zeros((0, 2))
    if ibars:
        xi = region(src, max(0, istart - .05), istart + ibars * bar + .1)
        o = int(round(snap(xi, .05 if istart > .05 else .0 + .05) * SR)); intro = xi[o:o + int(round(ibars * bar * SR))].copy()
        f = int(.006 * SR); intro[-f:] *= np.linspace(1, 0, f)[:, None]
        loop[:f] *= np.linspace(0, 1, f)[:, None] * 0 + 1
    return intro, loop, s - M

def encode(path, audio):
    wav = path.with_suffix(".tmp.wav"); sf.write(wav, audio, SR, subtype="FLOAT")
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", str(wav), "-af", "loudnorm=I=-17:TP=-2:LRA=9:print_format=json", "-f", "null", "-"], capture_output=True, text=True).stderr
    m = json.loads(r[r.rindex("{"):r.rindex("}") + 1])
    flt = (f"loudnorm=I=-17:TP=-2:LRA=9:measured_I={m['input_i']}:measured_TP={m['input_tp']}:measured_LRA={m['input_lra']}:"
           f"measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-af", flt, "-ar", str(SR), "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", str(path)], check=True)
    wav.unlink()

def main():
    src = sys.argv[1]; OUT.mkdir(parents=True, exist_ok=True); meta = {}
    for name, (bpm, start, bars, istart, ibars, role) in CUTS.items():
        intro, loop, snapped = build_one(src, name, bpm, start, bars, istart, ibars)
        audio = np.concatenate([intro, loop]) if len(intro) else loop
        encode(OUT / f"{name}.ogg", audio)
        meta[name] = {"file": f"{name}.ogg", "bpm": bpm, "bar_seconds": round(240 / bpm, 5), "intro_seconds": round(len(intro) / SR, 5),
                      "loop_seconds": round(len(loop) / SR, 5), "source_loop_start_s": round(start + snapped, 3), "role": role}
        print(name, meta[name])
    (OUT / "music.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n")

if __name__ == "__main__":
    main()
