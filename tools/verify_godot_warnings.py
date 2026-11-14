#!/usr/bin/env python3
"""Compile the reported scripts with fatal warnings set before engine startup.

Use an isolated project configuration so user/editor warning preferences and
the checked-in project configuration stay unchanged.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = ("static_called_on_instance", "incompatible_ternary",
              "shadowed_variable_base_class", "integer_division",
              "confusable_local_declaration", "unused_parameter", "standalone_ternary")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path, default=ROOT / "docs/evidence/godot-warnings")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    report = output / "strict.json"
    report.unlink(missing_ok=True)
    with tempfile.TemporaryDirectory(prefix="game-lab-warnings-") as temporary:
        project = Path(temporary) / "godot"
        project.mkdir()
        for item in (ROOT / "godot").iterdir():
            if item.name not in ("project.godot", "override.cfg"):
                (project / item.name).symlink_to(item, target_is_directory=item.is_dir())
        (project / "project.godot").write_bytes((ROOT / "godot/project.godot").read_bytes())
        (project / "override.cfg").write_text(
            "[debug]\ngdscript/warnings/enable=true\n" +
            "".join(f"gdscript/warnings/{name}=2\n" for name in CATEGORIES))
        command = [args.godot, "--headless", "--path", str(project), "--script",
                   "res://tools/verify_godot_warnings.gd", "--", str(report)]
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, timeout=90)
    log = result.stdout
    (output / "strict.log").write_text(log)
    errors = re.findall(r"^(?:ERROR|SCRIPT ERROR):.*", log, re.M)
    data = json.loads(report.read_text()) if report.exists() else {}
    success = (result.returncode == 0 and data.get("passed") == 23
               and data.get("failed") == 0 and not errors)
    print(log, end="")
    print("FATAL_WARNING_CHECK:", "PASS" if success else "FAIL")
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
