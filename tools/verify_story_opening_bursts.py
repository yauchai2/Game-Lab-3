#!/usr/bin/env python3
"""Render opening burst boundary sizes and fail on engine errors, even with exit 0."""
import argparse
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path,
                        default=ROOT / "docs/evidence/opening-bugfix/bursts.log")
    args = parser.parse_args()
    result = subprocess.run(
        [args.godot, "--rendering-driver", "opengl3", "--audio-driver", "Dummy",
         "--path", str(ROOT / "godot"), "--script",
         "res://tools/verify_story_opening_bursts.gd"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=90)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(result.stdout)
    errors = re.findall(r"^(?:ERROR|SCRIPT ERROR):.*", result.stdout, re.M)
    success = (result.returncode == 0 and not errors and
               "BURST_RENDER_RESULT 12 radii, 24 ray/spin combinations each" in result.stdout)
    print(result.stdout, end="")
    print("BURST_RENDER_CHECK:", "PASS" if success else "FAIL")
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
