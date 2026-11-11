# JSR runtime evidence

Native Godot 4.6.3 Compatibility / Mesa llvmpipe / Dummy audio. This verifies engine behavior, not human feel, listening, target GPU speed or the user's PC.

- [114/114 new profile/UI/audio/sprite checks](final-ui/reports/jsr-runtime/checks.json), [final log](final-ui/verify_jsr_runtime.log). Each of 4×13 attacks produces one true contact; profile speed and special damage, native roster callback, both locales at 3 sizes, all 8 signature slices, pixel option and song transitions are checked. Six extra checks ensure the roster Fight action is actually inside its scroll viewport.
- Existing headless rules: [results](regression/results.json), 263 checks across combat 34, air 54, rally 60, pressure 59, Rush 21, cannon10, forgiving defense25. The nonexistent `verify_air_reversal` filename was reported as missing, not counted or claimed; existing air coverage and new profile air attacks are explicitly listed.
- [Final native UI/pointer checks](final-ui/summary.json): UI36/36, actual pointer/keyboard17/17, rhythm29/29, red theatre18/18: sibling `.log` files and relocated JSON receipts in native-regression. The old UI tests assumed StyleBoxFlat, so their contrast assertion was adapted to real outlined text on the new image styles. Height expectation was changed to the user's new1.98/2.1 contract; timing assertions remain.
- [512-cycle UI lifecycle](native-regression/extended-polish/ui-lifecycle.json):3/3 headless, stable3125 objects /543 nodes after warmup. An expensive native attempt was stopped and retained in first-pass; the final lifecycle run uses its intended headless method. This is bounded lifecycle evidence, not a universal no-leak guarantee.
- [Source integrity](source-integrity.json): all49 original GLB/image/audio/bin assets unchanged. Font and animation subset derivatives intentionally regenerated. [Static premium audit](premium-audit.json)0errors/warnings; Web-oriented scanning is not Godot accessibility proof.

First-pass retains the2 mistaken physical/logical-boundary assertions, old flat-style accesses and superseded height expectation. Runtime and native tests were corrected; we do not hide the failed attempts.

- [Four-character retarget/playability regression](roster-final/summary.json):30/30, all three supplied characters complete actual aerial strings through KO under the same600-step test. An initial29/30 showed the heavy profile losing its route; adjusted cross push/startup and aerial reach, retaining the original test horizon and requirement. Failed final-focused / roster-diagnosis receipts are kept. Historical capture files inadvertently touched by the old tool were restored byte-for-byte, and the tool now writes only the new folder.
- [User music playback regression](final-focused/summary.json):20/20, including pause playhead, wrap, mute, duck and20 navigation cycles on one player. Dummy capture does not count as human listening.
- [39 runtime scripts compile](compile.log),0failed. The user's screenshot names10 editor warnings; the relevant ternary, initialized variable, shadowing and mesh-type expressions were corrected, but validation runs4.6.3, not4.7.2.

## Captures

- [Title Chinese](title-zh.png), [Title English960](title-en-960.png)
- [Roster Chinese](roster-zh.png), [Roster English960](roster-en-960.png)
- [Settings](settings-zh.png), [lower settings / retro toggle](settings-bottom-zh.png), [Pause](pause-en-960.png)
- [Demo HUD](demo-en-960.png)
- Character0 [stance](fighter-0.png), [special](fighter-0-special.png), [overdrive](fighter-0-overdrive.png)
- Character1 [stance](fighter-1.png), [special](fighter-1-special.png), [overdrive](fighter-1-overdrive.png)
- Character3 [stance](fighter-2.png), [special](fighter-2-special.png), [overdrive](fighter-2-overdrive.png)
- Goggles4 [stance](fighter-3.png), [special](fighter-3-special.png), [overdrive](fighter-3-overdrive.png)
- [8-second continuous Demo](demo.mp4), [capture facts](capture.json):120native captures at15fps,480 fixed wall steps; no soundtrack, no edits or human-input claim. Not a measured frame-rate benchmark.

Capture tools only inject legal commands and observe actual release events; the scene is frozen only while saving each screenshot. No fake hit/HP/energy event is added by the art renderer.
