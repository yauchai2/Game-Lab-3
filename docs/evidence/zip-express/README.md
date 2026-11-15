# ZIP Express Receipt evidence

- [8-second rendered gameplay](zip-express.mp4): two four-second training fixtures, opposing facings, actual session input and production Rhythm clock, four real contacts. Godot 4.6.3 Compatibility / llvmpipe / Dummy mixer, 1280×720 / 30fps Movie Writer. Not hardware performance or human play.
- `capture.json`: event receipts and camera/actor snapshots. `frame-*.png`: full gameplay screenshots from the same capture.
- `verification.json` / `.log`: 23 new contact, interruption, rendering, pause, reduced-effects and lifecycle checks.
- `street-motion.json` / `.log`: 90 existing rig/motion checks.
- `service-rules.json` / `.log`: 46 existing four-hero resource checks.
- `combat.log`: 34 existing core combat checks.
- `compile.json`: 13 changed/new GDScript compile checks.
- `legacy-rhythm-comparison.json` and two logs: seven identical historical failures on clean main610411d and this branch; not counted as passing.

Accepted capture and native verification logs have no ERROR / SCRIPT ERROR. Source analysis, implementation scope, timing changes and remaining fidelity limitations: [implementation note](../../ZIP_EXPRESS_REFERENCE.zh-TW.md).
