# Combat SFX sources

Built by `tools/build_real_sfx.py` (cuts, layers, EQ, saturation) on top of `tools/build_combat_sfx.py` (procedural low end and ability sounds).
All recordings are **CC0** from BigSoundBank (Joseph Sardin / LaSonotheque, https://bigsoundbank.com); each sound page states "CC0 (public domain)". Source files are not in the repo; the script downloads them by id.
The game is bare-handed street fighting, so no blades, anvils, bells, gongs or glass are used (removed 2026-11-12 on Alan's feedback).

| Used for | BigSoundBank id | Title |
|---|---|---|
| hit_0..4 | 2460, 2461, 2468, 2463, 2464 | Punch |
| heavy_0..2 | 2465, 2466, 2459 (+ 1808, 1807, 1806 low body, 2461/2468 mids) | Punch, Explosion |
| block_0..1 | 597, 2467, 2454, 2463 | Slaps, Punch, Body fall |
| parry_0 | 1152, 597, 2460 | Spanking, Slaps, Punch (sharp hand-slap crack) |
| guard_break_0 | 2465, 1808, 2455, 597, 2466 | Punch, Explosion, Body fall, Slaps |
| swing_0..2, dash_0, jump_0 | 1797, 1801, 1796, 1795, 1802 | Whoosh |
| step_0..1, land_0 | 514, 2454 | Footsteps Shoe on Concrete, Body fall |
| slam_0 | 1806, 2452, 2465, 2464 | Explosion far away, Body Fall, Punch |
| ko_0 | 1023, 2452, 1806, 2465 | Explosion far Away, Body Fall, Punch |

Procedural only (no recording): charge, launch, chase, rally, release, sub, and the low-end layers of every impact.

Reference check: the Lethal League Blaze footage Alan supplied was used only to measure the spectrum of hit moments (median band profile 0-150/150-500/500-2k/2-6k/6k+ Hz of -2/-10/-9/-11/-18 dB, centroid ~725 Hz). Nothing from it is sampled or included.
