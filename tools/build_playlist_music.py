#!/usr/bin/env python3
"""Cut the game's music loops from the playlist mp3 Alan supplied ("High-Energy Hip Hop Breakbeat Playlist ... Jet Set Radio").

Usage: python3 tools/build_playlist_music.py "<playlist.mp3>"        (needs numpy, scipy, ffmpeg)
The playlist is ~80 min: the first ~40 min repeat once, so the cuts use the first pass.
Each file = optional intro + a bar-aligned loop; Godot loops from `loop_offset` (intro length), so the intro plays only once.
Loop seam: 12 ms equal-power blend with the audio just before the loop start. Output: godot/audio/music/*.ogg + music.json.
"""
import argparse, hashlib, json, pathlib, subprocess
import numpy as np
from scipy import signal

SR = 44100; SEAM = .012
OUT = pathlib.Path(__file__).resolve().parent.parent / "godot" / "audio" / "music"
# BPM, source start, bars, intro start, intro bars, LUFS-I, low-pass Hz, role
CUTS = {
    "menu":      (110.01, 878.829, 16, 870.102, 4, -24, 8200, "restrained menu groove"),
    "city":      (100.00, 2207.700, 16, None, 0, -28, 4700, "night workshop"),
    "training":  (103.00, 1586.440, 16, None, 0, -26, 6600, "light rehearsal pulse"),
    "fight_low": (100.00, 2316.900, 16, None, 0, -24, 7200, "room between exchanges"),
    "fight_a":   (112.99, 780.910, 16, None, 0, -21, 11000, "active fight 1"),
    "fight_b":   (120.00, 290.480, 16, None, 0, -21, 9500, "active fight 2"),
    "fight_c":   (130.01, 2080.372, 16, None, 0, -20, 11000, "active fight 3"),
    "result":    (112.99, 752.350, 8, None, 0, -29, 3300, "sparse result bed"),
    "draw":      (107.00, 1480.540, 8, None, 0, -28, 4800, "Dealer intermission"),
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
    return intro, loop, s - M

def encode(path, audio, loudness, cutoff):
    audio = signal.sosfiltfilt(signal.butter(2, cutoff, fs=SR, output="sos"), audio, axis=0)
    pcm = audio.astype("<f4").tobytes()
    input_args = ["-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "pipe:0"]
    result = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", *input_args,
                             "-af", f"loudnorm=I={loudness}:TP=-4:LRA=9:print_format=json", "-f", "null", "-"],
                            input=pcm, capture_output=True, check=True)
    report = result.stderr.decode()
    measured = json.loads(report[report.rindex("{"):report.rindex("}") + 1])
    normalize = (f"loudnorm=I={loudness}:TP=-4:LRA=9:measured_I={measured['input_i']}:"
                 f"measured_TP={measured['input_tp']}:measured_LRA={measured['input_lra']}:"
                 f"measured_thresh={measured['input_thresh']}:offset={measured['target_offset']}:linear=true")
    encoders = subprocess.check_output(["ffmpeg", "-hide_banner", "-encoders"], text=True)
    codec = ["-c:a", "libvorbis"] if " libvorbis " in encoders else ["-c:a", "vorbis", "-strict", "-2"]
    pending = path.with_suffix(".tmp.ogg")
    filters = f"{normalize},aresample={SR},atrim=end_sample={len(audio)}"
    subprocess.run(["ffmpeg", "-v", "error", "-y", *input_args, "-af", filters,
                    "-ar", str(SR), *codec, "-q:a", "5", "-map_metadata", "-1", str(pending)],
                   input=pcm, check=True)
    pending.replace(path)


def cue(src, total, edits):
    score = np.zeros((round(total * SR), 2))
    for at, start, length, gain, fade_in, fade_out in edits:
        clip = region(src, start, start + length)
        n = min(len(clip), len(score) - round(at * SR))
        clip = clip[:n].copy()
        front, back = min(n, round(fade_in * SR)), min(n, round(fade_out * SR))
        if front:
            clip[:front] *= np.linspace(0, 1, front)[:, None]
        if back:
            clip[-back:] *= np.linspace(1, 0, back)[:, None]
        offset = round(at * SR)
        score[offset:offset+n] += clip * gain
    return score


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("playlist", type=pathlib.Path)
    src = str(parser.parse_args().playlist)
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    for name, (bpm, start, bars, istart, ibars, level, cutoff, role) in CUTS.items():
        intro, loop, snapped = build_one(src, name, bpm, start, bars, istart, ibars)
        encode(OUT / f"{name}.ogg", np.concatenate([intro, loop]), level, cutoff)
        meta[name] = {"file": f"{name}.ogg", "bpm": bpm, "bar_seconds": round(240 / bpm, 5),
                      "intro_seconds": round(len(intro) / SR, 5), "loop_seconds": round(len(loop) / SR, 5),
                      "source_loop_start_s": round(start + snapped, 3), "target_lufs": level, "role": role}
    # Timed openings leave holes for the case, footsteps, impacts and reveal.
    cues = {
        "opening": (16.12, -26, 6300, [(0.70, 752.35, 6.6, .58, .9, .8),
                    (8.0, 878.829, 1.95, .47, .08, .55),
                    (10.7, 761.1, 4.5, .52, .55, .85),
                    (15.85, 780.91, .27, .64, .04, .21)]),
        "ko": (8.2, -25, 7600, [(0.0, 781.2, 4.45, .70, .45, .75),
               (5.0, 753.5, 3.2, .78, .35, .9)]),
    }
    for name, (length, level, cutoff, edits) in cues.items():
        encode(OUT / f"{name}.ogg", cue(src, length, edits), level, cutoff)
        meta[name] = {"file": f"{name}.ogg", "duration": length, "target_lufs": level,
                      "edits": [{"at_s": e[0], "source_s": e[1], "length_s": e[2]} for e in edits]}
    digest = hashlib.sha256()
    with open(src, "rb") as original:
        for chunk in iter(lambda: original.read(1024 * 1024), b""):
            digest.update(chunk)
    meta["source"] = {"title": "High-Energy Hip Hop Breakbeat Playlist — Music Inspired by Jet Set Radio",
                      "sha256": digest.hexdigest(), "source": "Owner-supplied MP3"}
    (OUT / "music.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
