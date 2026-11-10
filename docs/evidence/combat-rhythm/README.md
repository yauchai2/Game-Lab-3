# Combat rhythm evidence — 2026-11-09

Current [specification](../../COMBAT_RHYTHM.md) and [validation](../../VALIDATION.md).

- `headless/`: 494/494 rule/UI/framing regressions.
- `final-native/`: 135/135, including 27 new timing/model/camera checks.
- `visual-final/`: last echo/label cleanup, focused 73/73. No duplicate counting; 629 distinct checks in this round.
- `native-soak/`: actual 120.007 sec, 177 hits / 28 chases / 24 BREAK, no reset/result. Per-phase render samples are not durations.
- `capture.json`, `rhythm-demo.mp4`, `rhythm-demo.gif`: same continuous 30-second fixed wall-step fight, 450 frames / 15fps / silent; 1,675 actual simulation ticks. Events counted from signals, not stale sim.events during holds.
- `extended-ko.mp4`: actual held-J KO, 1.6 seconds / 30fps / silent, includes 1.2-second red cut and result return.
- `captures/`: final native images; `roster-captures/`: model-regression snapshots. Older roster screenshots restored in place.
- `source-manifest.json`: all 49 baseline GLB/image/audio hashes preserved, candidate source and artifact hashes.

Earlier failures are retained: `native/` old 1800-calls=1800-ticks expectation; `first-headless/` old ten-call launcher-release expectation; `first-rhythm-native/` actually caught the missed swing/special event hookup; `ko-capture-first.log` did not await native input delivery before fast-stepping. Corrected checks and hookup pass above. No source-video artwork is used.

Godot 4.6.3 Compatibility / software GL / Dummy audio. Automated input and captures do not prove human fun, comfort, balance, audio mix or target-GPU performance. Public Web unchanged.
