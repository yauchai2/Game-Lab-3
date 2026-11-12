#!/usr/bin/env python3
"""Fetch and trim the CC0 field recordings used by the story opening score.

Every file comes from BigSoundBank (Joseph Sardin, https://bigsoundbank.com), released
under CC0 1.0 (https://bigsoundbank.com/licenses.html). Only short mono excerpts are kept
in references/story-opening-audio/ so the score can be rebuilt offline; they are outside
godot/ and are never imported or exported with the game.

Run: python3 tools/fetch_story_opening_sources.py   (needs network + ffmpeg)
"""
from pathlib import Path
import hashlib, json, subprocess, tempfile, urllib.request

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "references/story-opening-audio"
# name: (BigSoundBank id, title, start seconds, length seconds or None for whole file)
SOURCES = {
    "tram_pass": ("3374", "Tram Passing #4", 1.5, 8.0),
    "street_bus_stop": ("0909", "Bus stop in Japan", 30.0, 7.0),
    "ratchet": ("0794", "Small ratchet", 0.9, 2.2),
    "impact_wrench": ("0964", "Impact wrench #1", 0.0, 1.0),
    "straw": ("1244", "Straw, suction #1", 0.0, None),
    "straw_end": ("0508", "Straw, end of glass", 5.3, 1.6),
    "vinyl_crackle": ("2547", "Vinyl Disc", 3.0, 5.0),
    "scratch_a": ("2858", "Vinyl Scratch #1", 0.0, None),
    "scratch_b": ("2861", "Vinyl Scratch #4", 0.0, None),
    "scratch_c": ("2868", "Vinyl Scratch #11", 0.0, None),
    "scratch_d": ("2875", "Vinyl Scratch #18", 0.0, None),
    "radio_crackle": ("0312", "Crackling Radio #1", 0.0, None),
    "radio_sweep": ("2618", "Radio, Frequency Sweep #2", 0.5, 4.0),
    "neon": ("2118", "Neon or transformer #1", 1.0, 4.0),
    "briefcase": ("0803", "Briefcase", 0.0, 14.0),
    "suitcase": ("0802", "Suitcase", 0.0, 4.5),
    "cartridge": ("1355", "Cartridge case 9 mm on concrete #1", 0.0, None),
    "cocking": ("1984", "Pistol, cocking #1", 0.0, None),
    "loading": ("1988", "Gun, loading #1", 0.0, None),
    "car_arrival": ("0187", "Car (Arrival, Stop, Departure)", 12.0, 8.0),
    "tires": ("2371", "Screeching Tires #4", 1.4, 5.2),
    "car_door": ("0655", "Car door", 0.0, 8.0),
    "shoe_concrete": ("0514", "Footsteps, Shoe on Concrete", 0.0, 5.0),
    "marching": ("3023", "Marching in #1", 0.0, 5.0),
    "whoosh_a": ("1796", "Whoosh #4", 0.0, None),
    "whoosh_b": ("1801", "Whoosh #8", 0.0, None),
    "whoosh_c": ("1795", "Whoosh #3", 0.0, None),
    "whoosh_d": ("1798", "Whoosh #10", 0.0, None),
    "snare_a": ("2304", "Snare drum #1", 0.0, None),
    "snare_b": ("2308", "Snare drum #5", 0.0, None),
    "snare_c": ("2310", "Snare drum #7", 0.0, None),
    "hat_a": ("2292", "Hi-hat close #1", 0.0, 0.5),
    "hat_b": ("2293", "Hi-hat close #2", 0.0, 0.5),
    "hat_c": ("2301", "Hi-hat close #6", 0.0, None),
    "hat_open": ("2290", "Hi-hat open #1", 0.0, 2.5),
    "crash_a": ("2311", "Cymbale 16\" #1", 0.0, 5.0),
    "crash_b": ("2314", "Cymbale 16\" #4", 0.0, 5.0),
    "tom_low": ("2338", "Bass Tom, #1", 0.0, None),
    "tom_mid": ("2333", "Medium tom, #1", 0.0, 3.0),
    "drum_roll": ("2400", "Drum roll 1 S", 0.0, None),
    "explosion_a": ("1807", "Explosion #1", 0.0, None),
    "explosion_b": ("1808", "Explosion #2", 0.0, None),
    "explosion_far": ("1023", "Explosion far Away #1", 0.0, None),
    "thunder": ("3113", "Thunder #2", 0.0, None),
    "gong_hard": ("1485", "Gong, very strong", 0.0, 7.0),
    "gong": ("1483", "Gong, strong #1", 0.0, 8.0),
    "punch": ("2460", "Punch #5", 0.0, None),
    "dog": ("0682", "Barking of a Spitz", 0.0, None),
    "moto_start": ("0884", "Starting a motorcycle", 0.3, 3.2),
    "gate": ("0303", "Grinding Metal Gate #1", 0.0, None),
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    cache = Path(tempfile.gettempdir()) / "bsb"
    cache.mkdir(exist_ok=True)
    table = []
    for name, (ident, title, start, length) in SOURCES.items():
        raw = cache / f"{ident}.ogg"
        url = f"https://bigsoundbank.com/UPLOAD/ogg/{ident}.ogg"
        if not raw.exists() or raw.stat().st_size == 0:
            urllib.request.urlretrieve(url, raw)
        target = OUT / f"{name}.ogg"
        command = ["ffmpeg", "-v", "error", "-y", "-ss", str(start), "-i", str(raw)]
        if length:
            command += ["-t", str(length)]
        command += ["-ac", "1", "-ar", "48000", "-c:a", "libvorbis", "-q:a", "6", "-map_metadata", "-1", "-bitexact", str(target)]
        subprocess.run(command, check=True)
        table.append({"file": target.name, "bigsoundbank_id": ident, "title": title, "url": url, "excerpt_start": start,
                      "excerpt_length": length, "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
    (OUT / "provenance.json").write_text(json.dumps({
        "author": "Joseph Sardin / BigSoundBank", "license": "CC0 1.0 Universal",
        "license_url": "https://bigsoundbank.com/licenses.html", "retrieved": "2026-11-12", "files": table}, indent=2, ensure_ascii=False) + "\n")
    print(len(table), "excerpts", sum((OUT / row["file"]).stat().st_size for row in table))


if __name__ == "__main__":
    main()
