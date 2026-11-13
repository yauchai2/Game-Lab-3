# ZIP real running correction

The overdrive approach now moves the simulation root, caps travel at 2.2 units, brakes 1.15 units before the opponent, and respects arena bounds. Running pose phase and foot dust follow actual displacement; a blocked approach uses a planted guard instead of running in place. Airborne momentum, 75-energy payment, damage and hit-confirm rules are preserved.

- `zip-run.mp4`: six-second native game recording, one normal overdrive command, 100 initial energy, stationary RIVET fixture starting 3.4 units away. Three true contacts.
- `displacement.json`: measured simulation-root travel, about 2.07 units before the first kick, excluding camera motion and visual offsets.
- `run.json` / `.log`: 22 new checks, both facings, actual travel, close stopping, wall bounds, no free invulnerability, hitstop, displacement-sampled gait and airborne momentum.
- `delivery.json`, `express.json`, `street.json`: 44 / 23 / 90 existing checks.
- `service-rules.json`: 46 existing checks; `combat.log`: 34; `compile.json`: seven changed/new scripts. Total 266 passing checks.
- Accepted logs have no ERROR / SCRIPT ERROR. Movie Writer, Godot 4.6.3 Compatibility / llvmpipe / Dummy audio, not hardware FPS or Mac/human validation.
