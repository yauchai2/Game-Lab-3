# Combat SFX sources

Built by `tools/build_real_sfx.py` (cuts, layers, EQ, saturation) on top of `tools/build_combat_sfx.py` (procedural low end and ability sounds).
All recordings are **CC0** from BigSoundBank (Joseph Sardin / LaSonotheque, https://bigsoundbank.com), license shown on each sound page: "CC0 (public domain)". Source files are not in the repo; the script downloads them by id.

| Used for | BigSoundBank id | Title |
|---|---|---|
| hit_0..4 | 2460, 2461, 2468, 2463, 2464 | Punch #5 / #6 / #14 / #8 / #9 |
| heavy_0..2 | 2465, 2466, 2459 (+ 1808, 1807, 1806 low body) | Punch, Explosion |
| block_0..1 | 3589, 3590 (+ 2467) | Anvil, Punch |
| parry_0 | 129, 2531 | Sword, Counter Bell |
| guard_break_0 | 148, 387, 2465 | Glass Burst, A Mirror Explodes |
| swing_0..2, dash_0, jump_0 | 127, 128, 1796, 1795, 1802 | Sword That Cuts, Sword Through the Air, Whoosh |
| step_0..1, land_0 | 514, 2454 | Footsteps Shoe on Concrete, Body fall |
| slam_0 | 1806, 2452, 2465 | Explosion far away, Body Fall |
| ko_0 | 1023, 2314, 1483, 2465 | Explosion far Away, Cymbale 16", Gong sweet |

Procedural only (no recording): charge, launch, chase, rally, release, sub, and the low-end layers of every impact.
