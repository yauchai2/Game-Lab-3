# Combat VFX sprite sources

All source art is **CC0 (public domain)**; the license field on each OpenGameArt page was checked on 2026-11-12. Sources are not committed. `tools/build_vfx_sheets.py` bakes the sheets in this folder from them (recolour to white+alpha so the game tints per fighter, harden the alpha edge, crop around a shared pivot).

| File here | Source | Author | License |
|---|---|---|---|
| `hit_spark_tint.png`, `hit_spark_core.png` | [Hit Animation \| Frame by frame](https://opengameart.org/content/hit-animation-frame-by-frame) (`hit - yellow.png`, 4x4 sheet of 1024px cells) | Sinestesia | CC0 |
| `puffs.png` | [Smoke particle assets](https://opengameart.org/content/smoke-particle-assets) (`White puff` 00, 03, 06, 09, 14, 18) | Kenney (kenney.nl) | CC0 |

Notes
- Only frames 7-13 of the hit sheet are played; frames 0-6 contain a smooth shockwave ring the art direction does not want.
- Nothing is sampled from other games. The earlier reference footage (SEPAK / Lethal League Blaze) was only observed, never copied.
- Soft ground shadow is generated in code (`fight_session.gd::_soft_shadow_material`), no asset.
