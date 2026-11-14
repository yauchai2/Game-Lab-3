# Continuous combat slow motion

- [Comparison](comparison.mp4), [after](after.mp4), [before](before.mp4): same legal session input, four reset training fixtures / three seconds each. 100 initial meter; LOOP places its node normally. Baseline `c1b3101`.
- `before/capture.json`, `after/capture.json`: true contact events, native stop, presentation rate, actor and pose-frame samples. `comparison.json`: per-hero counter/stop comparison, not GPU performance measurement.
- `verification.json`: 79 new clock, interpolation, all-four skill/overdrive and lifecycle checks. Public `verify_combat_rhythm.gd` now delegates to this current contract.
- `service-rules.json`: 46; `arena.json`: 65; `squad.json`: 35; `squad-native.json`: 10; `defense.json`: 25; `zip.json`: 44; `express.json`: 23; `street.json`: 90.
- `core.log`: 34; `gun.log`: 21; `compile.json`: 13. Total 485 passing checks, no duplicated alias count.
- `strict/`: 19 fatal-warning compile checks passed. `public-runner.json`: public rhythm entry end-to-end 79/79, counted once above.
- Accepted logs contain no ERROR / SCRIPT ERROR. The retired ZIP arena fixture failed when it set only the old flurry flag; the current fixture sets its actual final-stage field and preserves the opt-in assertion.

Native Movie Writer 1280×720 / 30fps, Linux Godot4.6.3 Compatibility / llvmpipe / Dummy mixer. Fixed recording time is not hardware FPS or human/Mac validation. [Implementation and limits](../../CONTINUOUS_SLOW_MOTION.zh-TW.md).
