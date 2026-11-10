# Rush rework evidence — 2026-11-09

Read [current validation](../../VALIDATION.md) and [feature contract](../../RUSH_REWORK.md). Final records:

- `final-headless/`: 494/494; `red-native/`: full 221/221.
- `final-native/`: cosmetic refinements, focused 45/45.
- `final-native-timeout/`: final nonlethal-timeout fix, 46/46 (one new check; repeated 45 counted once). Total distinct checks: 716.
- `native-soak/`: final red-enabled real-time 120.14 sec / 169 hits / no reset.
- `captures/take.json`, `endless-demo.mp4`: one continuous 900-tick live duel, 15 sec / 15fps / silent.
- `red-ko.mp4`: actual main-game KO, one second / 30fps / silent.
- `source-manifest.json`: original asset preservation and candidate source hashes.
- `artifact-manifest.json`: capture hashes.

Other directories are earlier successful snapshots, not extra assertions to sum. `spacing-first.*` and `red-theatre-first.*` retain failed expectations and logs. The old 23-chapter show and its original images remain under `../ai-demo/`; this runtime no longer uses it. Native rendering and input are automated in Godot 4.6.3 / Compatibility / software GL / Dummy audio, not a human fun/balance/audio review or target-GPU benchmark.
