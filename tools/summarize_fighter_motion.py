"""Summarize bone-socket fixture excursions; not a terrain foot-slip metric.
Usage: python tools/summarize_fighter_motion.py docs/evidence/fighter-motion
"""
import gzip
import json
import math
from pathlib import Path
import sys

root = Path(sys.argv[1])
variants = {}
summary = {"scope": "Fixed-root pose fixtures, bone sockets after tick 10; excursion includes intentional steps/kicks. Does not measure shoe geometry or floor IK.", "measurements": []}
for variant in ("before", "after"):
    folder = root / variant
    raw = folder / "samples.json"
    packed = folder / "samples.json.gz"
    data = json.loads(raw.read_text() if raw.exists() else gzip.decompress(packed.read_bytes()))
    variants[variant] = data
    for action in data["actions"]:
        for character in range(4):
            rows = [r for r in action["samples"] if r["character"] == character and r["tick"] >= 10]
            summary["measurements"].append({
                "variant": variant, "action": action["action"], "character": character,
                "clips": sorted({r["clip"] for r in rows}),
                "foot_bone_excursion": {side: max(math.dist(r[side], rows[0][side]) for r in rows) for side in ("left_foot", "right_foot")}})
    if raw.exists():
        with gzip.GzipFile(filename=str(packed), mode="wb", mtime=0) as stream:
            stream.write(raw.read_bytes())
        raw.unlink()
unchanged = []
for character in (0, 2, 3):
    def samples(variant):
        return [[r for r in a["samples"] if r["character"] == character] for a in variants[variant]["actions"]]
    unchanged.append({"character": character, "same_samples": samples("before") == samples("after")})
summary["unmodified_hero_samples"] = unchanged
summary["trajectory_equal"] = json.loads((root / "trajectory-before.json").read_text()) == json.loads((root / "trajectory-after.json").read_text())
(root / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps({"unmodified_heroes": unchanged, "trajectory_equal": summary["trajectory_equal"]}))
