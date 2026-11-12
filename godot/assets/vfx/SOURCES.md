# Combat VFX sprite sources

All source art is **CC0 (public domain)**; the license field on each OpenGameArt page was checked on 2026-11-12. Sources are not committed. `tools/build_vfx_sheets.py` bakes the sheets in this folder from them into the game's Jet Set Radio-like pixel cel look: 1-bit alpha, flat tones, baked ink outline layer, low resolution drawn with nearest filtering, white+alpha so the game tints per fighter.

| File here | Source | Author | License |
|---|---|---|---|
| `hit_spark_{tint,core,ink}.png` | [Hit Animation \| Frame by frame](https://opengameart.org/content/hit-animation-frame-by-frame) (`hit - yellow.png`, 4x4 sheet of 1024px cells) | Sinestesia | CC0 |
| `slash_{tint,core,ink}.png` | [Pixel art sword slash effect](https://opengameart.org/content/pixel-art-sword-slash-effect) (`pixel_art_sword_slash_sprites.png`, 3x3 of 64x47) | tbbk | CC0 |
| `puffs.png` | [Smoke particle assets](https://opengameart.org/content/smoke-particle-assets) (`White puff` 00, 03, 06, 09, 14, 18) | Kenney (kenney.nl) | CC0 |

Notes
- Only frames 7-13 of the hit sheet are played, with no alpha fade (cel style: shrink away); frames 0-6 contain a smooth shockwave ring the art direction does not want.
- Nothing is sampled from other games. The earlier reference footage (SEPAK / Lethal League Blaze) was only observed, never copied.
- Ground shadow (three flat bands) is generated in code (`fight_session.gd::_soft_shadow_material`); ambient smoke is the existing `street_smoke.gdshader`, now 3 flat bands.
