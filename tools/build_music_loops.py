#!/usr/bin/env python3
"""Cut seamless bar-aligned loops from the Starjunk 95 tracks Alan supplied (permission: free editing/cutting).

Usage: python3 tools/build_music_loops.py <dir with the three source mp3 files>
Sources are NOT in the repo; cut points and tempo come from analysis (see docs/AUDIO_OVERHAUL.zh-TW.md).
Loop seam: last SEAM seconds are cross-faded (equal power) with the material just before the loop start,
so the loop point is continuous in the waveform. Output: godot/audio/music/*.ogg + provenance.json.
"""
import sys, glob, json, pathlib, subprocess, numpy as np

SR = 44100; SEAM = 0.012
OUT = pathlib.Path(__file__).resolve().parent.parent / "godot" / "audio" / "music"
# name, source glob, start s (downbeat), bpm, bars, role
CUTS = [
    ("fight_a_drop", "*Beat_Keep_Rockin*", 61.531, 140.0, 16, "fight deck 1: first drop of Beat Keep Rockin, ends on its own fill"),
    ("fight_b_groove", "*State_Your_Name*", 15.642, 125.0, 16, "fight deck 2: main groove of State Your Name"),
    ("result_breakdown", "REPO:godot/audio/user-tracks/groove_district.ogg", 46.162, 125.0, 8, "result screen: calm breakdown bars 24-31 of Groove District"),
]

def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "2", "-ar", str(SR), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2)

def loop(x, start, bpm, bars):
    beat = 60 / bpm; a = int(round(start * SR)); n = int(round(bars * 4 * beat * SR)); s = int(SEAM * SR)
    seg = x[a:a + n].copy()
    pre = x[a - s:a]; fo = np.cos(np.linspace(0, np.pi / 2, s))[:, None]; fi = np.sin(np.linspace(0, np.pi / 2, s))[:, None]
    seg[-s:] = seg[-s:] * fo + pre * fi
    return seg

def find_breakdown(x, bpm, bars):
    """Quietest low-band 8-bar stretch that still has a pulse, on the 8-bar grid of the track."""
    from scipy import signal
    lo = signal.sosfilt(signal.butter(4, 150, "low", fs=SR, output="sos"), x.mean(1))
    n = int(bars * 4 * 60 / bpm * SR); best = None
    for i in range(int(0.1 * SR), len(lo) - n, int(4 * 60 / bpm * SR)):
        r = 20 * np.log10(np.sqrt((lo[i:i + n] ** 2).mean()) + 1e-9); full = 20 * np.log10(np.sqrt((x[i:i + n] ** 2).mean()) + 1e-9)
        if full > -26 and r < -18 and (best is None or r < best[0]) and i > 20 * SR: best = (r, i / SR)
    return best[1]

def main():
    src = pathlib.Path(sys.argv[1]); OUT.mkdir(parents=True, exist_ok=True); prov = []
    for name, pat, start, bpm, bars, role in CUTS:
        f = [str(OUT.parent.parent.parent / pat[5:])] if pat.startswith('REPO:') else glob.glob(str(src / pat)); assert f, pat
        x = decode(f[0])
        if start is None: start = find_breakdown(x, bpm, bars)
        seg = loop(x, start, bpm, bars)
        wav = OUT / f"{name}.wav"
        import soundfile as sf; sf.write(wav, seg, SR, subtype="FLOAT")
        dst = OUT / f"{name}.ogg"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-af", "loudnorm=I=-17:TP=-2:LRA=9", "-ar", "44100",
                        "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", str(dst)], check=True)
        wav.unlink()
        prov.append({"file": f"godot/audio/music/{name}.ogg", "source": pathlib.Path(f[0]).name.split("-", 1)[-1] if "Starjunk" in f[0] else pathlib.Path(f[0]).name, "artist": "Starjunk 95",
                     "start_s": round(start, 3), "bpm": bpm, "bars": bars, "length_s": round(len(seg) / SR, 3), "role": role,
                     "admission": "User supplied; Alan allowed free editing/cutting for this game. No CC0 claim."})
        print(name, round(start, 3), round(len(seg) / SR, 2))
    (OUT / "provenance.json").write_text(json.dumps(prov, indent=2, ensure_ascii=False) + "\n")

if __name__ == "__main__": main()
