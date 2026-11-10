"""Standalone arithmetic checks for proposed values, not a Godot gameplay test."""
import json
from pathlib import Path


def jump(initial, selector):
    velocity = initial
    height = 0.0
    peak = 0.0
    peak_tick = 0
    for tick in range(1, 1001):
        velocity -= selector(velocity) / 60.0
        height += velocity / 60.0
        if height > peak:
            peak, peak_tick = height, tick
        if height <= 0.0 and velocity < 0:
            return {"peak_m": round(peak, 6), "peak_tick": peak_tick,
                    "air_ticks": tick, "air_seconds": round(tick / 60.0, 6)}
    raise AssertionError("Jump did not land")


def run():
    baseline = jump(10.3, lambda _: 26.0)
    reference = jump(22.0, lambda v: 45.0 if v > 4 else (12.0 if abs(v) <= 4 else 65.0))
    proposed = jump(12.5, lambda v: 36.0 if v > 2.4 else (14.0 if abs(v) <= 2.4 else 50.0))
    assert 1.9 < baseline["peak_m"] < 2.1
    assert reference["peak_m"] > 5.5
    assert 2.1 < proposed["peak_m"] < 2.5
    assert proposed["air_ticks"] < 65
    y = 1.48
    x = 1.0 / y ** 0.5
    assert abs(x * y * x - 1) < 1e-9
    result = {
        "method": "Standalone semi-implicit Euler at 60 Hz, gravity selected before each integration; no Godot execution, collision, buffering or animation validation.",
        "baseline": baseline, "supplied_reference": reference, "proposed": proposed,
        "continuous_peak_m": {"baseline": 10.3**2 / 52,
                              "reference": (22**2 - 4**2) / 90 + 4**2 / 24,
                              "proposed": (12.5**2 - 2.4**2) / 72 + 2.4**2 / 28},
        "scale_reference_volume": .68 * 1.48 * .68,
        "volume_preserving_y_1_48_xz": x,
        "proposed_jump_squat_ticks_not_in_airtime": 3,
    }
    Path(__file__).with_name("parameter-sanity.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    run()
