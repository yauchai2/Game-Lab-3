#!/usr/bin/env python3
"""Run focused Godot regressions without overwriting historical evidence.

Import first: godot --headless --editor --path godot --import --quit
Native mode needs an available DISPLAY and Compatibility rendering.
"""
from __future__ import annotations

import argparse
import hashlib
import datetime as dt
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
# UI replica replaces old dropdown/Chinese-menu and pause-silence harnesses.
# Their source and historical evidence remain; verify_reference_ui covers the new contract.
CASES = [
    ("verify_victory_exits", "victory-exits/verification.json", "native"),
    ("verify_city_breaker_fx", "city-breaker-fx/verification.json", "native"),
    ("verify_city_breaker", "city-breaker/verification.json", "native"),
    ("verify_double_jump", "double-jump/rules.json", "headless"),
    ("verify_double_jump_input", "double-jump/input.json", "native"),
    ("verify_ink_ui", "ink-ui/page-checks.json", "native"),
    ("verify_material_lifecycle", "readable-ui/material-lifecycle.json", "native"),
    ("verify_reference_ui", "ui-replica/checks.json", "native"),
    ("verify_cannon_input", "charged-cannon/input.json", "native"),
    ("verify_charged_cannon", "charged-cannon/rules.json", "headless"),
    ("verify_combat_rhythm", "combat-rhythm/verification.json", "native"),
    ("verify_red_theatre", "rush-rework/red-theatre.json", "native"),
    ("verify_rush_arcade", "rush-rework/arcade-rules.json", "headless"),
    ("verify_friendly_input", "friendly-defense/input.json", "native"),
    ("verify_friendly_defense", "friendly-defense/rules.json", "headless"),
    ("verify_demo", "rush-rework/live-rules.json", "headless"),
    ("verify_demo_input", "rush-rework/input.json", "native"),
    ("verify_air_counter", "air-reversal/rules.json", "headless"),
    ("verify_air_counter_input", "air-reversal/input.json", "native"),
    ("verify_aerial_street", "aerial-street/rules.json", "headless"),
    ("verify_aerial_input", "aerial-street/input.json", "native"),
    ("verify_kinetic_rally", "kinetic-overdrive/rules.json", "headless"),
    ("verify_kinetic_presentation", "kinetic-overdrive/presentation/verification.json", "native"),
    ("verify_result_presentation", "extended-polish/result-presentation.json", "headless"),
    ("verify_combat", "combat/verification.json", "headless"),
    ("verify_combat_polish", "combat-polish/verification.json", "headless"),
    ("verify_scene_audio_vfx", "scene-audio-vfx/verification.json", "headless"),
    ("verify_street_backdrop", "playtest-fixes/verification.json", "headless"),
    ("verify_corner_density", "corner-density/verification.json", "headless"),
    ("verify_dressing", "dressing/verification.json", "headless"),
    ("verify_sky_motion", "scene-composition/verification.json", "headless"),
    ("verify_impact_staging", "impact-staging/verification.json", "headless"),
    ("verify_pressure_exchange", "pressure-exchange/verification.json", "headless"),
    ("verify_flyby", "flyby/verification.json", "headless"),
    ("verify_close_combat", "extended-polish/close-combat.json", "headless"),
    ("verify_combat_framing", "extended-polish/framing/verification.json", "headless"),
    ("verify_street_ui", "extended-polish/street-ui/verification.json", "native"),
    ("verify_combat_input", "combat/input-verification.json", "native"),
    ("verify_pressure_input", "pressure-exchange/input-verification.json", "native"),
    ("verify_static_batches", "extended-polish/static-batches/verification.json", "native"),
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=["headless", "native"], default="headless")
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--only", help="Comma-separated case names for a focused recheck")
    args = parser.parse_args()
    if args.mode == "native" and sys.platform.startswith("linux") and not (os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY")):
        parser.error("Native Linux mode requires DISPLAY or WAYLAND_DISPLAY; headless mode cannot validate rendered MultiMesh transforms.")
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = (args.output or ROOT / "docs/evidence/local-runs" / stamp / args.mode).resolve()
    selected=set(args.only.split(",")) if args.only else None
    available={name for name,_,mode in CASES if mode==args.mode}
    if selected is not None and not selected<=available:
        parser.error("Unavailable cases for this mode: "+", ".join(sorted(selected-available)))
    out.mkdir(parents=True, exist_ok=True)
    results = []
    for name, report_name, mode in CASES:
        if mode != args.mode or (selected is not None and name not in selected):
            continue
        report = ROOT / "docs/evidence" / report_name
        previous = report.read_bytes() if report.exists() else None
        previous_mtime = report.stat().st_mtime_ns if report.exists() else None
        command = [args.godot, "--path", "godot", "--audio-driver", "Dummy"]
        if mode == "headless":
            command += ["--headless"]
        else:
            command += ["--rendering-method", "gl_compatibility", "--resolution", "1280x720"]
        if name == "verify_flyby":
            command += ["--fixed-fps", "60"]
        command += ["--script", f"res://tools/{name}.gd"]
        case_sha=hashlib.sha256((ROOT/"godot/tools"/(name+".gd")).read_bytes()).hexdigest()
        started = time.monotonic()
        try:
            try:
                run = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, text=True, timeout=180)
                code, log = run.returncode, run.stdout
            except subprocess.TimeoutExpired as exc:
                code = 124
                log = (exc.stdout or b"").decode(errors="replace") + "\nHARNESS TIMEOUT\n"
            log = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", log)
            (out / f"{name}.log").write_text(log)
            written = report.exists() and report.stat().st_mtime_ns != previous_mtime
            data = json.loads(report.read_text()) if written else {}
            checks = data.get("checks", [])
            failed = sum(not c.get("passed", False) for c in checks)
            if written:
                target = out / "reports" / report_name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(report.read_bytes())
            result = {"name": name, "mode": mode, "exit_code": code,
                      "harness_sha256": case_sha,
                      "seconds": round(time.monotonic() - started, 3),
                      "command": command, "report_written": written,
                      "passed": len(checks) - failed, "failed": failed,
                      "skipped": data.get("skipped", []),
                      "diagnostics": re.findall(r"^(?:ERROR|WARNING|SCRIPT ERROR):.*", log, re.M)}
            # A state-only report can pass while the renderer emits invalid-RID
            # errors. Those errors must fail the suite rather than disappear
            # inside a diagnostic list (warnings remain visible but nonfatal).
            result["engine_errors"] = re.findall(r"^(?:ERROR|SCRIPT ERROR):.*", log, re.M)
            result["success"] = code == 0 and written and bool(checks) and failed == 0 and not result["engine_errors"]
            results.append(result)
            print(f"{name}: {result['passed']}/{len(checks)}; exit {code}", flush=True)
        finally:
            if previous is None:
                report.unlink(missing_ok=True)
            else:
                report.write_bytes(previous)
    summary = {"created_utc": stamp, "source_commit": subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "tracked_runtime_changes": subprocess.check_output(["git","diff","HEAD","--name-only","--","godot/scripts","godot/scenes","godot/assets","godot/audio","godot/shaders","godot/project.godot"],cwd=ROOT,text=True).splitlines(),
        "mode": args.mode, "all_assertions_passed": bool(results) and all(r["success"] for r in results),
        "passed": sum(r["passed"] for r in results), "failed": sum(r["failed"] for r in results),
        "cases": results,
        "scope": "Automated Godot checks. Native input is injected, not a physical human playtest; inspect diagnostics separately."}
    (out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    return 0 if summary["all_assertions_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
